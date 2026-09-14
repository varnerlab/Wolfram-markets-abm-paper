"""Enumerate the fixed simulation design before running the rebuilt study."""
import csv
import hashlib
import itertools
import json


def write_manifest(destination):
    rows=[]
    def add(family,role,**kw):
        row=dict(family=family,role=role,seed=1,L=64,h=100.,boundary='endogenous',
                 pre=1000,post=3000,f=.20,rule=19286,cash_factor=1.,share_factor=1.,
                 action='rule',band='adaptive')
        row.update(kw)
        row['sequence']=len(rows)+1
        row['job_id']=hashlib.sha256(json.dumps(row,sort_keys=True).encode()).hexdigest()[:20]
        rows.append(row)
    def pair(family,**kw):
        add(family,'treated',**kw)
        add(family,'control',**{**kw,'action':'none','band':'adaptive'})
    for f,seed in itertools.product((.10,.15,.20,.25),range(1,51)):
        pair('rule',f=f,seed=seed)
    fractions=(.10,.15,.175,.185,.19,.195,.20,.205,.21,.225,.25)
    for h,boundary,seed in itertools.product((100.,10.,5.,2.,1.,.5,.1,0.),('endogenous','hold'),range(1,51)):
        add('dealer','control',h=h,boundary=boundary,seed=seed,f=.25,action='none')
        for f in fractions:add('dealer','treated',h=h,boundary=boundary,seed=seed,f=f)
    size_f=(.14,.15,.16,.17,.175,.18,.185,.19,.20,.21,.225,.25)
    for L,(h,boundary),seed in itertools.product((32,48,64,96,128),((100.,'hold'),(100.,'endogenous'),(1.,'endogenous')),range(1,51)):
        add('size','control',L=L,h=h,boundary=boundary,seed=seed,f=.25,action='none')
        for f in size_f:add('size','treated',L=L,h=h,boundary=boundary,seed=seed,f=f)
    for h,boundary,seed,f,cash,shares in itertools.product((100.,1.,.1),('endogenous','hold'),range(1,51),(.17,.175,.18,.185),(1.,.1,10.),(1.,.1,10.)):
        add('balance','resource',h=h,boundary=boundary,seed=seed,f=f,cash_factor=cash,share_factor=shares)
    for total in range(9):
        original=(19280//3**total)%3
        for output in range(3):
            if output==original:continue
            rule=19280+(output-original)*3**total
            for f,seed,boundary in itertools.product((.15,.20,.25),range(1,21),('hold','endogenous')):
                pair('screen',rule=rule,f=f,seed=seed,boundary=boundary)
    for f,seed,boundary,action in itertools.product((.15,.20,.25),range(1,51),('hold','endogenous'),('rule','sell_pulse')):
        pair('pulse',f=f,seed=seed,boundary=boundary,action=action)
    for h,seed,band in itertools.product((0.,.1,.5,1.,2.,5.,10.,100.),range(1,51),('adaptive','frozen')):
        pair('band',h=h,seed=seed,band=band,f=.175)
    for h,seed in itertools.product((40.,100.,400.),range(1,51)):
        pair('depth',h=h,seed=seed)
    for seed,boundary in itertools.product(range(1,11),('hold','endogenous')):
        pair('long',seed=seed,boundary=boundary,action='none',post=100000)
    for L in (32,64,128):
        fractions=[round(.14+.005*i,3) for i in range(33 if L==32 else 23)]
        for f,seed in itertools.product(fractions,range(1,51)):
            pair('horizons',L=L,f=f,seed=seed,boundary='hold',post={32:3000,64:9000,128:12000}[L])
    with (destination/'Manifest.csv').open('w',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    counts={family:sum(r['family']==family for r in rows) for family in dict.fromkeys(r['family'] for r in rows)}
    (destination/'Campaign-counts.json').write_text(json.dumps({
        'fixed_simulations':len(rows),'by_family':counts,
        'additional':'Adaptive refinement, numerically selected extended trajectories, figure histories, and validation runs have separate manifests or execution records.'},indent=2)+'\n')
    assert counts==dict(rule=400,dealer=9600,size=9750,balance=10800,screen=4320,pulse=1200,band=1600,depth=300,long=40,horizons=7900)
    return counts
