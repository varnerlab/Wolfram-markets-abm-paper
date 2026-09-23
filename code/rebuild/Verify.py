"""Check corrected-run provenance, campaign completeness, and shared outcomes."""
from pathlib import Path
from collections import Counter
import argparse
import csv
import hashlib
import json
import re
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'
D=STUDY/'code/data'


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--partial',action='store_true')
    args=parser.parse_args();report={'checks':{},'incomplete':[]}
    p=json.loads((STUDY/'Protocol.json').read_text());status=json.loads((STUDY/'Status.json').read_text())
    assert p['initial_cached_files']==0 and not p['historical_data_imported']
    assert p['clearing']=='reserve' and p['held_financial_simulations']
    for name,digest in p['frozen_computation'].items():assert sha(STUDY/name)==digest,name
    assert sha(STUDY/'Manifest.csv')==p['manifest_sha256']
    for name,digest in p['original_engine'].items():assert sha(STUDY/name)==digest,name
    postprocessing=STUDY/'Postprocessing-Sources.json'
    if postprocessing.exists():
        files=json.loads(postprocessing.read_text())['files']
        for name,digest in files.items():assert sha(STUDY/name)==digest,name
        report['checks']['postprocessing_sources']=len(files)
    for amendment in p.get('amendments',[]):
        assert amendment['kind']=='scheduling_only'
        archive=STUDY/amendment['archived_versions']
        original=json.loads((archive/'Protocol-before.json').read_text())
        before=(archive/'Revision-Lib-before.jl').read_text()
        after=(archive/'Revision-Lib-after.jl').read_text()
        assert before.replace('Threads.@threads :dynamic for i in eachindex(jobs)',
            'Threads.@threads :greedy for i in eachindex(jobs)')==after
        name=amendment['affected_source']
        assert (STUDY/name).read_text()==after
        assert sha(archive/'Revision-Lib-before.jl')==amendment['before_sha256']
        assert sha(archive/'Revision-Lib-after.jl')==amendment['after_sha256']
        assert sha(archive/'validation.log')==amendment['validation_sha256']
        changed=[key for key,value in original['frozen_computation'].items()
                 if p['frozen_computation'][key]!=value]
        assert changed==[name]
        report['checks']['scheduling_equivalence']=amendment['validation_checks']
    report['checks']['frozen_sources']=len(p['frozen_computation'])
    report['checks']['historical_inputs']=0
    for phase,expected_checks in [('reserve-tests',6028),('rebuild-tests',79)]:
        if phase in status['completed_phases']:
            totals=re.findall(r'\|\s+(\d+)\s+(\d+)\s+[\d.]+s\s*$',
                              (STUDY/'logs'/f'{phase}.log').read_text(),re.MULTILINE)
            assert totals and all(a==b for a,b in totals)
            assert sum(int(a) for a,b in totals)==expected_checks
            report['checks'][phase]=expected_checks
    manifest=list(csv.DictReader((STUDY/'Manifest.csv').open()))
    ledger=list(csv.DictReader((D/'Rebuild-Execution-Ledger.csv').open()))
    phase_map={f:('controls' if f in ('screen','pulse','band','depth','long') else f)
               for f in set(x['family'] for x in manifest)}
    def expected(x):
        return (phase_map[x['family']],int(x['seed']),int(x['L']),int(x['pre'])+int(x['post']),
                float(x['h']),round(float(x['f']),9),int(x['rule']),x['boundary'],x['action'],
                x['band'],x['family']=='balance')
    def actual(x):
        action='none' if int(x['activation_step'])>int(x['steps']) else x['action']
        return (x['phase'],int(x['seed']),int(x['L']),int(x['steps']),float(x['h']),round(float(x['f']),9),
                int(x['rule']),x['boundary'],action,'adaptive' if x['fixed_band']=='nothing' else 'frozen',
                x['resource_intervention']=='true')
    expected_counts=Counter(expected(x) for x in manifest)
    for phase in sorted(set(phase_map.values())):
        expect=Counter({k:v for k,v in expected_counts.items() if k[0]==phase})
        observed=Counter(actual(x) for x in ledger if x['phase']==phase)
        if phase in status['completed_phases']:
            assert observed==expect,{'phase':phase,'missing':list((expect-observed).items())[:3],
                                    'extra':list((observed-expect).items())[:3]}
            report['checks'][phase+'_manifest_simulations']=sum(observed.values())
        else:report['incomplete'].append(phase)
    if 'refinement' in status['completed_phases']:
        refined_jobs=[]
        for path in sorted(D.glob('ModelB-Revision-Refinement-Round*-Manifest.csv')):
            for job in csv.DictReader(path.open()):
                for action in ('rule','none'):
                    refined_jobs.append(('refinement',int(job['seed']),int(job['gridn']),4000,
                        float(job['market_maker_capacity']),round(float(job['target_f']),9),19286,
                        job['boundary_mode'],action,'adaptive',False))
        observed=Counter(actual(x) for x in ledger if x['phase']=='refinement')
        assert observed==Counter(refined_jobs)
        report['checks']['refinement_manifest_simulations']=sum(observed.values())
    if 'extended' in status['completed_phases']:
        selections=pd.read_csv(D/'Figure4-Prespecified-Selection.csv')
        jobs=pd.read_csv(D/'ModelB-Revision-MarketPanel-Horizons-Manifest.csv')
        expected_extended=[]
        for j in jobs.itertuples():
            for action in ('rule','none'):
                expected_extended.append(('extended',int(j.seed),64,11000,100.,round(float(j.f),9),19286,
                    'endogenous',action,'adaptive',False))
        for j in selections.itertuples():
            expected_extended.append(('extended',int(j.seed),64,4000,100.,round(float(j.f),9),19286,
                'endogenous','rule','adaptive',False))
        observed=Counter(actual(x) for x in ledger if x['phase']=='extended')
        assert observed==Counter(expected_extended)
        report['checks']['extended_manifest_simulations']=sum(observed.values())
    def read(name,rows=None,keys=None):
        path=D/name
        if not path.exists():return None
        df=pd.read_csv(path)
        if rows is not None:assert len(df)==rows,(name,len(df),rows)
        if keys is not None:assert not df.duplicated(keys).any(),name
        report['checks'][name+'_rows']=len(df)
        return df
    dealer=read('ModelB-ReservoirQuench-Full-Summary.csv',8800,
                ['boundary_mode','market_maker_capacity','target_f','seed'])
    size=read('ModelB-FiniteSizeQuench-Full-Summary.csv',9000,
              ['gridn','boundary_mode','market_maker_capacity','target_f','seed'])
    balance=read('ModelB-BalanceSheetQuench-Full-Summary.csv',10800,
        ['boundary_mode','market_maker_capacity','target_f','seed','cash_factor','share_factor'])
    read('ModelB-RuleQuench-Full-Summary.csv',200,['target_f','seed'])
    for name,count in [('screen',2160),('pulse',600),('band',800),('impact',150),('long',20)]:
        raw=read(f'ModelB-Revision-{name}.csv',count)
        if raw is not None:
            jobs=pd.read_csv(D/f'ModelB-Revision-{name}-Manifest.csv')
            keys=list(jobs.columns)
            def tuples(frame):
                return Counter(tuple(round(float(v),9) if isinstance(v,(float,np.floating)) else v
                    for v in row) for row in frame[keys].itertuples(index=False,name=None))
            assert tuples(raw)==tuples(jobs),name
            report['checks'][name+'_job_combinations']=len(jobs)
            if 'onset60' in raw:
                assert ((raw.onset60==0)|(raw.onset>0)).all()
                assert ((raw.onset==0)|(raw.onset40>0)).all()
                event=raw.onset>0;assert (raw.loc[event,'onset40']<=raw.loc[event,'onset']).all()
                event=raw.onset60>0;assert (raw.loc[event,'onset']<=raw.loc[event,'onset60']).all()
    refined=read('ModelB-Revision-FiniteSize-Summary.csv',keys=['boundary_mode','market_maker_capacity','gridn','target_f','seed'])
    horizons=read('ModelB-Revision-Horizons.csv',10700,['L','f','seed','post'])
    extended=read('ModelB-Revision-MarketPanel-Horizons.csv',324,['f','seed','condition','post'])
    if dealer is not None:
        selected_examples=[]
        for f,event in [(.15,False),(.175,False),(.175,True),(.185,True),(.2,True)]:
            group=dealer[(dealer.boundary_mode=='endogenous')&(dealer.market_maker_capacity==100)&
                         np.isclose(dealer.target_f,f)&(dealer.transitioned==event)].copy()
            metric='treated_onset' if event else 'treated_final_sell_mean'
            group['distance']=(group[metric]-group[metric].median()).abs()
            selected_examples.append((f,int(group.sort_values(['distance','seed']).iloc[0].seed)))
        selection_file=D/'Figure4-Prespecified-Selection.csv'
        if selection_file.exists():
            selection=pd.read_csv(selection_file)
            assert list(zip(selection.f,selection.seed))==selected_examples
            report['checks']['figure4_selection']=selected_examples
        if 'figures4and5' in status['completed_phases']:
            plotted=pd.read_csv(D/'Figure4-Selection.csv')
            assert list(zip(plotted.target_f,plotted.seed))==selected_examples
            pool=dealer[(dealer.boundary_mode=='endogenous')&np.isclose(dealer.target_f,.2)&
                        dealer.transitioned&dealer.market_maker_capacity.isin([.1,1,100])]
            medians=pool.groupby('market_maker_capacity').treated_onset.median()
            scores=[(sum(abs(row.treated_onset-medians.loc[row.market_maker_capacity])
                         for row in sub.itertuples()),int(seed))
                    for seed,sub in pool.groupby('seed') if len(sub)==3]
            chosen_seed=min(scores)[1]
            figure_jobs=[('figures4and5',seed,64,11000,100.,f,19286,'endogenous','rule','adaptive',False)
                         for f,seed in selected_examples]
            figure_jobs += [('figures4and5',chosen_seed,64,4000,h,.2,19286,mode,'rule','adaptive',False)
                            for h,mode in [(.1,'endogenous'),(1.,'endogenous'),(100.,'endogenous'),(100.,'hold')]]
            assert Counter(actual(x) for x in ledger if x['phase']=='figures4and5')==Counter(figure_jobs)
            report['checks']['figure_history_simulations']=len(figure_jobs)
            report['checks']['figure5_seed']=chosen_seed
        held=dealer[dealer.boundary_mode=='hold']
        for _,group in held.groupby(['target_f','seed']):
            for col in ['treated_onset','treated_final_sell_mean','transitioned']:
                assert group[col].nunique()==1,col
        ledger_held=pd.DataFrame([x for x in ledger if x['phase']=='dealer' and x['boundary']=='hold'])
        for _,group in ledger_held.groupby(['seed','f','activation_step']):
            assert group.final_grid_sha256.nunique()==1
        zero=dealer[dealer.market_maker_capacity==0]
        for _,group in zero.groupby(['target_f','seed']):
            assert group.treated_onset.nunique()==1 and group.treated_final_sell_mean.nunique()==1
            assert (group.treated_maximum_drawdown==0).all()
        report['checks']['held_dealer_invariance']=len(held)//8
        report['checks']['zero_depth_invariance']=len(zero)//2
        report['checks']['dealer_max_cash_error']=float(dealer.system_cash_error.max())
        assert (dealer.system_share_error==0).all()
    if size is not None:
        report['checks']['size_max_cash_error']=float(size.cash_conservation_error.max())
        assert (size.share_conservation_error==0).all()
    if balance is not None:
        expected_resources=Counter((x['boundary'],float(x['h']),round(float(x['f']),9),int(x['seed']),
            float(x['cash_factor']),float(x['share_factor'])) for x in manifest if x['family']=='balance')
        observed_resources=Counter((x.boundary_mode,float(x.market_maker_capacity),round(float(x.target_f),9),
            int(x.seed),float(x.cash_factor),float(x.share_factor)) for x in balance.itertuples())
        assert observed_resources==expected_resources
        report['checks']['balance_resource_combinations']=len(observed_resources)
        held=balance[balance.boundary_mode=='hold']
        for _,group in held.groupby(['target_f','seed']):
            for col in ['transitioned','treated_onset','final_sell_mean']:
                assert group[col].nunique()==1,col
            # Driver checks full histories within each depth; ledger checks final grids across depths.
        bal_held=pd.DataFrame([x for x in ledger if x['phase']=='balance' and x['boundary']=='hold'])
        for _,group in bal_held.groupby(['seed','f']):assert group.final_grid_sha256.nunique()==1
        report['checks']['held_balance_invariance']=len(held)//27
        report['checks']['balance_max_cash_error']=float(balance[['pre_cash_conservation_error','post_cash_conservation_error']].max().max())
        assert (balance[['pre_share_conservation_error','post_share_conservation_error']]==0).all().all()
    if size is not None and horizons is not None:
        a=size[(size.boundary_mode=='hold')&size.gridn.isin([32,64,128])].copy()
        b=horizons[horizons.post==3000].copy()
        a['fraction']=a.target_f.round(9);b['fraction']=b.f.round(9)
        overlap=a.merge(b,left_on=['gridn','fraction','seed'],right_on=['L','fraction','seed'],suffixes=('_size','_horizon'))
        assert len(overlap)==1800
        assert (overlap.transitioned_size==overlap.transitioned_horizon).all()
        assert (overlap.treated_onset==overlap.onset).all()
        assert np.allclose(overlap.final_sell_mean_size,overlap.final_sell_mean_horizon,atol=1e-14,rtol=0)
        report['checks']['independently_recomputed_held_overlap']=len(overlap)
    if refined is not None:
        assert set(refined.groupby(['gridn','boundary_mode','market_maker_capacity','target_f']).seed.nunique())=={50}
    scaling=read('ModelB-Revision-FiniteSize-Scaling.csv',15)
    if scaling is not None:
        report['refinement']={'minimum_interior_points':int(scaling.interior_points.min()),
            'unbracketed_midpoints':int(scaling.f50.isna().sum()),
            'minimum_valid_bootstrap_fraction':float(scaling.bootstrap_crossing_valid.min())}
    report['total_completed_simulations']=len(ledger)
    report['phase_counts']=dict(Counter(x['phase'] for x in ledger))
    report['state']='partial' if args.partial or report['incomplete'] else 'verified'
    if not args.partial:
        assert not report['incomplete'],report['incomplete']
        assert status['state']=='computation_complete'
        assert set(status['completed_phases'])==set(['reserve-tests','rebuild-tests','rule','dealer',
            'size','balance','controls','refinement','horizons','extended','analysis','tables',
            'figure2','figure3','figures4and5','figure6'])
        assert len(scaling)==15 and extended is not None and horizons is not None
        figures=['Fig1-RuleQuench','Fig2-ReservoirQuench','Fig3-FiniteSizeQuench',
                 'Fig4-DoseMarketPanels','Fig5-DealerMarketPanels','Fig6-BalanceSheetQuench']
        for name in figures:assert (STUDY/'paper-arxiv/figs'/f'{name}.pdf').is_file(),name
        report['figure_sha256']={name:sha(STUDY/'paper-arxiv/figs'/f'{name}.pdf') for name in figures}
        (STUDY/'Verification.json').write_text(json.dumps(report,indent=2)+'\n')
        cash=max(report['checks'][name] for name in ['dealer_max_cash_error','size_max_cash_error','balance_max_cash_error'])
        mantissa,exponent=f'{cash:.2e}'.split('e')
        cash_tex=rf'${mantissa}\times10^{{{int(exponent)}}}$'
        (STUDY/'paper-arxiv/sections/rebuild-validation.tex').write_text(
            '\nThe completed rebuild was checked against its fixed parameter manifest and\\n'.replace('\\n','\n')+
            'its execution ledger. All fixed conditions were present, and the new size\\n'.replace('\\n','\n')+
            'and horizon campaigns with technical traders held agreed for 1,800 overlapping starting-market\\n'.replace('\\n','\n')+
            'and fraction combinations. Across the main dealer, size, and resource\\n'.replace('\\n','\n')+
            f'campaign summaries, the largest absolute cash discrepancy was {cash_tex},\\n'.replace('\\n','\n')+
            'and share discrepancies were zero. These numerical checks accompanied\\n'.replace('\\n','\n')+
            'the per-simulation reserve and conservation checks described above.\n')
    print(json.dumps(report,indent=2))


if __name__=='__main__':main()
