"""Seed-block bootstrap and monotone logistic sensitivity for revision data.

Run after Compute-Refinement.jl and Compute-Controls.jl. Bootstrap intervals
condition on the sampled (adaptively refined) grid; they do not estimate
interpolation bias or uncertainty about the chosen horizon.
"""
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit

DATA = Path(__file__).resolve().parents[1] / 'data'
B = 2000
RNG = np.random.default_rng(20260905)

def crossing(f, p, q):
    for i in range(len(f)-1):
        if p[i] == q:
            return f[i]
        if p[i] < q <= p[i+1]:
            return f[i] + (q-p[i])*(f[i+1]-f[i])/(p[i+1]-p[i])
    return f[-1] if p[-1] == q else np.nan

def logistic(f, counts, n, start=None):
    x=(f-0.18)/0.01
    def loss(beta):
        z=beta[0]+beta[1]*x
        residual=n*expit(z)-counts
        return (np.sum(n*np.logaddexp(0,z)-counts*z),
                np.array([residual.sum(), residual@x]))
    fit=minimize(loss, [0.,1.] if start is None else start, jac=True,
                 bounds=[(None,None),(1e-6,None)],method='L-BFGS-B',
                 options={'ftol':1e-12,'gtol':1e-7,'maxiter':300})
    if not fit.success and np.linalg.norm(fit.jac)>1e-3:
        raise RuntimeError(fit.message)
    a,b=fit.x
    return np.array([0.18-0.01*a/b, 0.02*np.log(3)/b]), fit.x

def interval(x):
    x=np.asarray(x)
    return np.nanquantile(x,[0.025,0.975]) if np.isfinite(x).any() else np.array([np.nan,np.nan])

def analyze_finite():
    raw=pd.read_csv(DATA/'ModelB-Revision-FiniteSize-Summary.csv')
    grouped=[]; scaling=[]
    keys=['boundary_mode','market_maker_capacity','gridn']
    for key, df in raw.groupby(keys):
        f=np.sort(df.target_f.unique())
        y=df.pivot(index='seed',columns='target_f',values='transitioned').reindex(columns=f).to_numpy(float)
        m=df.pivot(index='seed',columns='target_f',values='final_sell_mean').reindex(columns=f).to_numpy(float)
        assert y.shape[0]==50 and np.isfinite(y).all() and np.isfinite(m).all()
        n=len(y); p=y.mean(0); chi=(key[2]-2)**2*m.var(0)
        indices=RNG.integers(0,n,(B,n))
        pb=y[indices].mean(1); mb=m[indices]
        chib=(key[2]-2)**2*mb.var(1)
        cross=np.array([[crossing(f,row,q) for q in (.25,.5,.75)] for row in pb])
        est=np.array([crossing(f,p,q) for q in (.25,.5,.75)])
        width=cross[:,2]-cross[:,0]
        log_est,beta=logistic(f,y.sum(0),n)
        log_boot=np.array([logistic(f,row*n,n,beta)[0] for row in pb])
        row=dict(zip(keys,key), f25=est[0],f50=est[1],f75=est[2],
                 transition_width=est[2]-est[0],
                 susceptibility_peak_f=f[chi.argmax()],susceptibility_peak=chi.max(),
                 interior_points=int(((p>.05)&(p<.95)).sum()),
                 logistic_f50=log_est[0],logistic_width=log_est[1],
                 logistic_a=beta[0],logistic_b=beta[1],
                 logistic_f50_se=log_boot[:,0].std(ddof=1),
                 logistic_width_se=log_boot[:,1].std(ddof=1),
                 bootstrap_replicates=B,
                 bootstrap_crossing_valid=float(np.isfinite(cross).all(1).mean()))
        for name,values in [('f25',cross[:,0]),('f50',cross[:,1]),('f75',cross[:,2]),
                            ('transition_width',width),('susceptibility_peak',chib.max(1)),
                            ('susceptibility_peak_f',f[chib.argmax(1)]),
                            ('logistic_f50',log_boot[:,0]),('logistic_width',log_boot[:,1])]:
            row[name+'_lo'],row[name+'_hi']=interval(values)
        scaling.append(row)
        for i, frac in enumerate(f):
            lo,hi=interval(chib[:,i])
            grouped.append(dict(zip(keys,key),target_f=frac,transition_probability=p[i],
                                ensemble_susceptibility=chi[i],chi_lo=lo,chi_hi=hi,
                                logistic_probability=expit(beta[0]+beta[1]*(frac-.18)/.01)))
        print(key, 'interior points:',row['interior_points'],'midpoint:',round(est[1],3),flush=True)
    pd.DataFrame(grouped).to_csv(DATA/'ModelB-Revision-FiniteSize-Grouped.csv',index=False)
    pd.DataFrame(scaling).to_csv(DATA/'ModelB-Revision-FiniteSize-Scaling.csv',index=False)

def safe_median(x):
    return x.median() if x.notna().any() else np.nan

def summarize_controls():
    groups=[]
    for name in ('screen','pulse','band','impact','long'):
        path=DATA/f'ModelB-Revision-{name}.csv'
        if not path.exists():
            continue
        raw=pd.read_csv(path)
        keys=['campaign','L','f','post','h','impact','rule','boundary','action','band']
        for key,df in raw.groupby(keys):
            p=df.transitioned.mean(); n=len(df); z=1.959963984540054
            center=(p+z*z/(2*n))/(1+z*z/n)
            half=z*np.sqrt(p*(1-p)/n+z*z/(4*n*n))/(1+z*z/n)
            groups.append(dict(zip(keys,key),seeds=n,p=p,p_lo=center-half,p_hi=center+half,
                p40=(df.onset40>0).mean(),p60=(df.onset60>0).mean(),
                control_p=df.control_transitioned.mean(),
                median_drawdown=safe_median(df.maximum_drawdown),
                median_rejection=safe_median(df.rejection_fraction),
                mean_edge_sell=df.edge_sell_fraction.mean(),
                mean_edge_hold=df.edge_hold_fraction.mean(),
                median_pre_deviation=safe_median(df.pre_deviation),
                median_post_deviation=safe_median(df.post_deviation),
                mean_pre_sell_early=df.pre_sell_early.mean(),
                mean_pre_sell_late=df.pre_sell_late.mean(),
                median_pre_return_std=safe_median(df.pre_return_std),
                median_pre_return_mean=safe_median(df.pre_return_mean),
                median_pre_return_q01=safe_median(df.pre_return_q01),
                median_pre_return_q99=safe_median(df.pre_return_q99),
                mean_pre_zero_returns=df.pre_zero_returns.mean()))
    pd.DataFrame(groups).to_csv(DATA/'ModelB-Revision-Controls-Grouped.csv',index=False)

def summarize_horizons():
    path=DATA/'ModelB-Revision-Horizons.csv'
    if not path.exists(): return
    raw=pd.read_csv(path); rows=[]
    for (L,post),df in raw.groupby(['L','post']):
        f=np.sort(df.f.unique())
        for threshold,column in ((.4,'onset40'),(.5,'onset'),(.6,'onset60')):
            y=(df.pivot(index='seed',columns='f',values=column).reindex(columns=f).to_numpy()>0).astype(float)
            p=y.mean(0); n=len(y)
            indices=RNG.integers(0,n,(B,n))
            pb=y[indices].mean(1)
            boot=np.array([crossing(f,row,.5) for row in pb])
            lo,hi=interval(boot)
            rows.append(dict(L=L,post=post,threshold=threshold,f50=crossing(f,p,.5),
                             f50_lo=lo,f50_hi=hi,valid=np.isfinite(boot).mean(),
                             control_p=df.control_transitioned.mean()))
    pd.DataFrame(rows).to_csv(DATA/'ModelB-Revision-Horizons-Scaling.csv',index=False)

if __name__=='__main__':
    import sys
    if '--summaries-only' not in sys.argv: analyze_finite()
    summarize_controls()
    summarize_horizons()
