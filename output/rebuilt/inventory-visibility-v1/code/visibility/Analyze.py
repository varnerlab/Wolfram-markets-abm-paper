"""Validate complete matched branches and estimate planned seed-level contrasts."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import numpy as np
import pandas as pd

OUTCOMES=['final_sell_mean','majority','max_drawdown','interior_sales_per_trader']
DIAGNOSTICS=['unbacked_signal_fraction','unbacked_through_onset','baseline_unbacked_fraction',
             'raw_input_sell_mean','visible_input_sell_mean','suppressed_sale_fraction',
             'dealer_rejection_fraction']

def check_frozen(study,protocol):
    for name,expected in protocol['frozen_files'].items():
        assert hashlib.sha256((study/name).read_bytes()).hexdigest()==expected,name
    extension=study/'Extension.json'
    if extension.exists():
        expected=json.loads(extension.read_text())['manifest_sha256']
        assert hashlib.sha256((study/'Extension.csv').read_bytes()).hexdigest()==expected

def load_runs(study,manifest):
    frames=[pd.read_csv(study/'results'/f'{id}.csv') for id in manifest.id]
    runs=pd.concat(frames,ignore_index=True)
    assert not runs.id.duplicated().any()
    assert len(runs)==len(manifest)
    for key in ['id','group','mode','role','seed','L','boundary','h','f','pre','post']:
        left=manifest.sort_values('id')[key].reset_index(drop=True)
        right=runs.sort_values('id')[key].reset_index(drop=True)
        if key in ['h','f']:
            assert np.allclose(left,right,rtol=0,atol=1e-12),key
        else:
            assert left.equals(right),key
    for group,rows in runs.groupby('group'):
        for key in ['pre_state_sha256','first_execution_sha256','pre_grid_sha256','prehistory_sha256']:
            assert rows[key].nunique()==1,(group,key)
        controls=rows[rows.role=='control']
        assert len(controls)==2 and set(controls['mode'])=={'original','inventory'},group
        for f,switched in rows[rows.role=='switch'].groupby('f'):
            assert len(switched)==2 and set(switched['mode'])=={'original','inventory'},(group,f)
    assert np.isfinite(runs[OUTCOMES+DIAGNOSTICS].to_numpy(dtype=float)).all()
    assert (runs.minimum_cash>=-1e-9).all() and (runs.minimum_shares>=0).all()
    assert (runs.max_product_error<1e-9).all()
    # Original held decisions remain independent of depth; masked decisions need not.
    held=runs[(runs.boundary=='hold') & (runs['mode']=='original')]
    for _,rows in held.groupby(['seed','role','f']):
        assert rows.sell_history_sha256.nunique()==1
    return runs

def wilson(k,n):
    z=1.959963984540054;p=k/n;d=1+z*z/n
    c=(p+z*z/(2*n))/d
    w=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/d
    return c-w,c+w

def interval(values,indices):
    values=np.asarray(values,dtype=float)
    boot=values[indices].mean(axis=1)
    lo,hi=np.quantile(boot,[.025,.975])
    return float(values.mean()),float(lo),float(hi)

def analyze(study):
    protocol=json.loads((study/'Protocol.json').read_text())
    check_frozen(study,protocol)
    manifest=pd.read_csv(study/'Manifest.csv')
    if (study/'Extension.csv').exists():
        manifest=pd.concat([manifest,pd.read_csv(study/'Extension.csv')],ignore_index=True)
    runs=load_runs(study,manifest)
    runs.to_csv(study/'Run-Summary.csv',index=False)
    seeds=sorted(runs.seed.unique());n=len(seeds)
    indices=np.random.default_rng(protocol['bootstrap_seed']).integers(0,n,
        size=(protocol['bootstrap_replicates'],n))
    summaries=[]
    for (boundary,h,mode,role,f),rows in runs.groupby(['boundary','h','mode','role','f']):
        rows=rows.set_index('seed').loc[seeds]
        entry=dict(boundary=boundary,h=h,mode=mode,role=role,f=f,n=n)
        for metric in OUTCOMES+DIAGNOSTICS:
            mean,lo,hi=interval(rows[metric],indices)
            if metric=='majority':
                lo,hi=wilson(int(rows.majority.sum()),n)
            entry.update({metric:mean,metric+'_lo':lo,metric+'_hi':hi})
        summaries.append(entry)
    summary=pd.DataFrame(summaries)
    summary.to_csv(study/'Branch-Summary.csv',index=False)
    contrasts=[];paired=[]
    for (boundary,h,f),rows in runs[runs.role=='switch'].groupby(['boundary','h','f']):
        controls=runs[(runs.boundary==boundary)&(runs.h==h)&(runs.role=='control')]
        arms={}
        for mode in ['original','inventory']:
            arms[(mode,'switch')]=rows[rows['mode']==mode].set_index('seed').loc[seeds]
            arms[(mode,'control')]=controls[controls['mode']==mode].set_index('seed').loc[seeds]
        for metric in OUTCOMES:
            y={k:v[metric].to_numpy(dtype=float) for k,v in arms.items()}
            original=y['original','switch']-y['original','control']
            inventory=y['inventory','switch']-y['inventory','control']
            delta=inventory-original
            mean,lo,hi=interval(delta,indices)
            row=dict(boundary=boundary,h=h,f=f,outcome=metric,n=n,
                original_control=y['original','control'].mean(),
                original_switch=y['original','switch'].mean(),
                inventory_control=y['inventory','control'].mean(),
                inventory_switch=y['inventory','switch'].mean(),
                original_effect=original.mean(),inventory_effect=inventory.mean(),
                difference=mean,lower=lo,upper=hi,
                primary=boundary=='hold' and h==100 and f==.2 and metric=='final_sell_mean')
            contrasts.append(row)
            for seed,a,b,d in zip(seeds,original,inventory,delta):
                paired.append(dict(boundary=boundary,h=h,f=f,outcome=metric,seed=seed,
                    original_effect=a,inventory_effect=b,difference=d))
    contrasts=pd.DataFrame(contrasts)
    contrasts.to_csv(study/'Contrasts.csv',index=False)
    pd.DataFrame(paired).to_csv(study/'Paired-Effects.csv',index=False)
    primary=contrasts[contrasts.primary].iloc[0].to_dict()
    validation=dict(completed_utc=datetime.now(timezone.utc).isoformat(),
        mode=protocol['mode'],runs=len(runs),seeds=n,groups=runs.group.nunique(),
        frozen_files_unchanged=True,complete=True,paired_histories_identical=True,
        original_held_depth_invariance=True,
        max_cash_error=float(runs.max_cash_error.max()),
        max_product_error=float(runs.max_product_error.max()),
        primary=primary,
        artifacts={name:hashlib.sha256((study/name).read_bytes()).hexdigest() for name in
            ['Run-Summary.csv','Branch-Summary.csv','Contrasts.csv','Paired-Effects.csv']})
    (study/'Validation.json').write_text(json.dumps(validation,indent=2)+'\n')
    print(json.dumps(dict(runs=len(runs),primary=primary),indent=2))
    return validation

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('study',type=Path)
    analyze(parser.parse_args().study.resolve())
