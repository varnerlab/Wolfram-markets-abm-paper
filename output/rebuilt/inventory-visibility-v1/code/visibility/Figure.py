"""Plot the four prespecified outcomes in the primary visibility setting."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil

os.environ.setdefault('MPLCONFIGDIR','/tmp/wolfram-visibility-matplotlib')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import numpy as np
import pandas as pd

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('study',type=Path)
    parser.add_argument('--paper',type=Path,default=Path('paper-arxiv'))
    args=parser.parse_args();study=args.study.resolve();paper=args.paper.resolve()
    validation=json.loads((study/'Validation.json').read_text())
    for name,expected in validation['artifacts'].items():
        assert hashlib.sha256((study/name).read_bytes()).hexdigest()==expected,name
    data=pd.read_csv(study/'Branch-Summary.csv')
    data=data[(data.boundary=='hold')&(data.h==100)]
    colors={'original':'#000000','inventory':'#CC79A7'}
    plt.rcParams.update({'font.size':9,'axes.labelsize':9,'legend.fontsize':8,
        'axes.titlesize':10,'pdf.fonttype':42,'ps.fonttype':42})
    fig,axes=plt.subplots(2,2,figsize=(7.0,5.5),layout='constrained')
    settings=[('majority','Sell-majority probability',1),
        ('final_sell_mean','Mean late Sell fraction',1),
        ('max_drawdown','Mean maximum drawdown (%)',100),
        ('interior_sales_per_trader','Mean completed sales\nper interior trader',1)]
    for ax,(metric,label,scale),letter in zip(axes.flat,settings,'ABCD'):
        ax.set_facecolor('#F0F0F0');ax.grid(color='white',linewidth=0.8)
        ax.set_axisbelow(True)
        for mode in ['original','inventory']:
            switched=data[(data['mode']==mode)&(data.role=='switch')].sort_values('f')
            control=data[(data['mode']==mode)&(data.role=='control')].iloc[0]
            x=switched.f.to_numpy()
            y=switched[metric].to_numpy()*scale
            lo=switched[metric+'_lo'].to_numpy()*scale
            hi=switched[metric+'_hi'].to_numpy()*scale
            ax.fill_between(x,lo,hi,color=colors[mode],alpha=.12,linewidth=0)
            ax.plot(x,y,color=colors[mode],marker='o',markersize=3,linewidth=1.2)
            ax.axhspan(control[metric+'_lo']*scale,control[metric+'_hi']*scale,
                color=colors[mode],alpha=.08,linewidth=0)
            ax.axhline(control[metric]*scale,color=colors[mode],linestyle='--',linewidth=1)
        ax.set_xlabel('Fraction given the new rule, $f$');ax.set_ylabel(label)
        ax.set_title(letter,loc='left',fontweight='bold')
        ax.set_xlim(0,1.02 if x.max()>.25 else .26)
        if metric in ('majority','final_sell_mean'):
            ax.set_ylim(-.025,1.025)
        else:
            ax.set_ylim(bottom=0)
        ax.spines[['top','right']].set_visible(False)
    handles=[Line2D([0],[0],color=colors[mode],linestyle=style,marker=marker,
        label=f'{name}, {role}') for mode,name in [('original','Original signals'),
        ('inventory','Inventory-conditioned')] for role,style,marker in
        [('switch','-','o'),('no-switch control','--','')]]
    fig.legend(handles=handles,loc='outside lower center',ncol=2,frameon=False)
    destination=study/'FigS2-InventoryVisibility.pdf'
    fig.savefig(destination)
    fig.savefig(study/'FigS2-InventoryVisibility.png',dpi=150)
    for directory in (paper/'figs',paper.parent/'code/figs'):
        directory.mkdir(exist_ok=True,parents=True)
        shutil.copy2(destination,directory/destination.name)
    print(destination)

if __name__=='__main__':
    main()
