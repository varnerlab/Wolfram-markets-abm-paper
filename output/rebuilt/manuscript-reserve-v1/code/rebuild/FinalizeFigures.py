"""Apply documented presentation changes without altering frozen simulations."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import subprocess
import pandas as pd

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'


def revise(name):
    source=STUDY/'code/model-b'/f'Figs-ModelB-{name}Quench.jl'
    changed=source.read_text().replace('include(joinpath(@__DIR__, "Include.jl"))',
        'include(joinpath(@__DIR__, "..", "code", "model-b", "Include.jl"))')
    if name=='BalanceSheet':
        changed=changed.replace('top_margin = 3Plots.mm', 'top_margin = 8Plots.mm')
        assert changed.count('ylims = (0.35, 1.06)')==2
        changed=changed.replace('ylims = (0.35, 1.06)','ylims = (-0.03, 1.06)')
        changed=changed.replace('ylims = (-0.03, 0.72)',
            'yscale = :log10, ylims = (1e-7, 0.03), yticks = [1e-7, 1e-5, 1e-3, 1e-2]')
        changed=changed.replace('_group_labels!(pC, 0.68)','_group_labels!(pC, 0.016)')
        changed=changed.replace('ylims = (5e-4, 300)', 'ylims = (0.7, 300)')
        changed=changed.replace('xlims = (5e-4, 300)', 'xlims = (0.7, 300)')
        changed=changed.replace('([1e-3, 1e-2, 1e-1, 1, 10, 100],\n                                          ["0", "0.01", "0.1", "1", "10", "100"])',
                                '([1, 10, 100], ["1", "10", "100"])')
        changed=changed.replace('([1e-3, 1e-2, 1e-1, 1, 10, 100], ["0", "0.01", "0.1", "1", "10", "100"])',
                                '([1, 10, 100], ["1", "10", "100"])')
        needle='for (p, letter) in zip((pA, pB, pC, pD), ("A", "B", "C", "D"))'
        assert changed.count(needle)==1
        changed=changed.replace(needle,'''@assert all(x -> 1e-7 < x < 0.01, endo.median_maker_rejection)
@assert all(x -> 1 < 100x <= 100, endo.median_drawdown)

'''+needle)
        reason='Show the full probability domain, positive rejection rates on a logarithmic axis, and positive drawdowns over their observed range. No zero medians occur and no observations are clipped.'
    elif name=='FiniteSize':
        changed=changed.replace('bottom_margin = 4Plots.mm)',
                                'bottom_margin = 4Plots.mm, top_margin = 5Plots.mm)')
        reason='Add breathing room above the panel letters; all curves, axes, and uncertainty intervals are unchanged.'
    else:
        changed=changed.replace('right_margin = 4Plots.mm)',
                                'right_margin = 4Plots.mm, top_margin = 6Plots.mm)')
        changed=changed.replace('"100.0"]','"100"]')
        changed=changed.replace('colorbar_title = "Δ probability"','colorbar_title = "", title = "Active − held probability"')
        needle='for (i, p) in enumerate((pA, pB, pC, pD))'
        assert changed.count(needle)==1
        changed=changed.replace(needle,'''@assert all(>(0), grouped[grouped.target_f .== f_plot, :rejection_q25])
plot!(pD; yscale=:log10, ylims=(1e-7,1), yticks=[1e-7,1e-5,1e-3,1e-1,1])

'''+needle)
        reason='Separate color-bar labels and expose positive-depth rejection rates on a logarithmic axis; all displayed lower quartiles are positive.'
    target=STUDY/'presentation-v2'/f'Figs-{name}.jl';target.parent.mkdir(exist_ok=True)
    target.write_text(changed)
    return target,dict(reason=reason,original_source=str(source.relative_to(STUDY)),
        original_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
        revised_source=str(target.relative_to(STUDY)),revised_sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
        simulation_changes=False,metric_changes=False)


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--preview-dealer',action='store_true')
    parser.add_argument('--preview-balance',action='store_true')
    args=parser.parse_args();status=json.loads((STUDY/'Status.json').read_text())
    assert not (args.preview_dealer and args.preview_balance)
    if args.preview_dealer:
        assert 'dealer' in status['completed_phases'] and status['active_phase'] not in ['figure2','figures4and5']
        names=['Reservoir']
    elif args.preview_balance:
        assert 'balance' in status['completed_phases'] and status['active_phase']!='figure6'
        names=['BalanceSheet']
    else:
        assert status['state']=='computation_complete' and not (STUDY/'.writer-lock').exists()
        names=['Reservoir','FiniteSize','BalanceSheet']
    manifest=[]
    env=os.environ.copy();env.update(GKSwstype='100',XDG_CACHE_HOME='/tmp/wolfram-rebuild-cache',REBUILD_PHASE='presentation-v2')
    for name in names:
        target,entry=revise(name);manifest.append(entry)
        with (STUDY/f'logs/presentation-v2-{name}.log').open('w') as log:
            subprocess.run(['julia','--project='+str(STUDY/'code'),'--startup-file=no','--threads=1',str(target)],
                           cwd=STUDY,env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
    (STUDY/'presentation-v2/Manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('Regenerated figures with documented presentation changes:',', '.join(names))


if __name__=='__main__':main()
