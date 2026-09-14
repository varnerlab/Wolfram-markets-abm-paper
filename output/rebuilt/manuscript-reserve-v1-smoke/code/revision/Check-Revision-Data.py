"""Check archived equivalence, paired designs, and bootstrap/grid completeness."""
from pathlib import Path
import numpy as np
import pandas as pd
D=Path(__file__).resolve().parents[1]/'data'
old=pd.read_csv(D/'ModelB-FiniteSizeQuench-Full-Summary.csv')
old=old[(old.boundary_mode=='hold')&old.gridn.isin([32,64,128])].copy()
old['fkey']=old.target_f.round(6)
new=pd.read_csv(D/'ModelB-Revision-Horizons.csv')
new=new[new.post==3000].copy(); new['fkey']=new.f.round(6)
p=old.merge(new,left_on=['gridn','fkey','seed'],right_on=['L','fkey','seed'],suffixes=('_old','_new'))
assert len(p)==1800
assert (p.transitioned_old==p.transitioned_new).all()
assert np.allclose(p.final_sell_mean_old,p.final_sell_mean_new,rtol=0,atol=1e-14)
for name,n in [('screen',2160),('pulse',600),('band',800),('impact',450),('long',20)]:
    x=pd.read_csv(D/f'ModelB-Revision-{name}.csv')
    assert len(x)==n
    assert not x.control_transitioned.any()
    assert ((x.onset40>0).astype(int)>=x.transitioned.astype(int)).all()
    assert (x.transitioned.astype(int)>=(x.onset60>0).astype(int)).all()
screen=pd.read_csv(D/'ModelB-Revision-screen.csv')
assert screen.rule.nunique()==18
for rule in screen.rule.unique():
    assert sum((int(rule)//3**c)%3 != (19280//3**c)%3 for c in range(9))==1
raw=pd.read_csv(D/'ModelB-Revision-FiniteSize-Summary.csv')
assert not raw.duplicated(['boundary_mode','market_maker_capacity','gridn','target_f','seed']).any()
assert raw.groupby(['boundary_mode','market_maker_capacity','gridn','target_f']).size().eq(50).all()
s=pd.read_csv(D/'ModelB-Revision-FiniteSize-Scaling.csv')
assert len(s)==15 and s.interior_points.ge(5).all()
assert s.bootstrap_crossing_valid.eq(1).all()
assert s.transition_width.gt(0).all() and s.logistic_width.gt(0).all()
h=pd.read_csv(D/'ModelB-Revision-Horizons-Scaling.csv')
assert len(h)==24 and h.valid.eq(1).all()
assert h.groupby(['L','post']).f50.apply(lambda x: np.all(np.diff(x)>0)).all()
print('Revision data checks passed; 1,800 archived outcomes match the held kernel.')
