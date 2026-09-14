"""Run or resume only the new isolated study; all source and outputs are local."""
import argparse
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'


def save_status(status):
    status['updated_utc']=datetime.now(timezone.utc).isoformat()
    temporary=STUDY/'Status.json.tmp'
    temporary.write_text(json.dumps(status,indent=2)+'\n')
    temporary.replace(STUDY/'Status.json')


def check_source():
    protocol=json.loads((STUDY/'Protocol.json').read_text())
    for name,digest in protocol['frozen_computation'].items():
        assert hashlib.sha256((STUDY/name).read_bytes()).hexdigest()==digest, name
    assert not protocol['historical_data_imported'] and protocol['initial_cached_files']==0
    assert hashlib.sha256((STUDY/'Manifest.csv').read_bytes()).hexdigest()==protocol['manifest_sha256']


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only',help='run one named phase')
    args=parser.parse_args()
    check_source()
    threads=os.environ.get('MARKET_ABM_THREADS','12')
    julia=['julia','--project='+str(STUDY/'code'),'--startup-file=no',
           '--threads='+threads,'--gcthreads='+os.environ.get('MARKET_ABM_GC_THREADS','1')]
    def jl(file,*argv):return julia+[str(STUDY/'code'/file),*argv]
    phases=[
        ('reserve-tests',jl('repaired/Test-ReserveClearing.jl')),
        ('rebuild-tests',jl('rebuild/Test-Rebuild.jl',str(STUDY))),
        ('rule',jl('model-b/Compute-ModelB-RuleQuench.jl','--full')),
        ('dealer',jl('model-b/Compute-ModelB-ReservoirQuench.jl','--full')),
        ('size',jl('model-b/Compute-ModelB-FiniteSizeQuench.jl','--full')),
        ('balance',jl('model-b/Compute-ModelB-BalanceSheetQuench.jl','--full')),
        ('controls',jl('revision/Compute-Controls.jl')),
        ('refinement',jl('revision/Compute-Refinement.jl')),
        ('horizons',jl('revision/Compute-Horizons.jl')),
        ('extended',jl('revision/Compute-MarketPanel-Horizons.jl')),
        ('analysis',[sys.executable,str(STUDY/'code/revision/Analyze-Revision.py')]),
        ('tables',jl('model-b/Tables-ModelB-Supplement.jl')),
        ('figure2',jl('model-b/Figs-ModelB-ReservoirQuench.jl')),
        ('figure3',jl('model-b/Figs-ModelB-FiniteSizeQuench.jl')),
        ('figures4and5',jl('model-b/Figs-ModelB-MarketPanels.jl')),
        ('figure6',jl('model-b/Figs-ModelB-BalanceSheetQuench.jl')),
    ]
    if args.only:
        phases=[p for p in phases if p[0]==args.only]
        if not phases:parser.error('unknown phase')
    lock=STUDY/'.writer-lock';lock.mkdir()
    (lock/'owner.json').write_text(json.dumps({'pid':os.getpid(),'started_utc':datetime.now(timezone.utc).isoformat()}))
    status_path=STUDY/'Status.json'
    status=json.loads(status_path.read_text()) if status_path.exists() else {'version':'manuscript-reserve-v1','completed_phases':[]}
    env=os.environ.copy();env.update(GKSwstype='100',MPLCONFIGDIR='/tmp/wolfram-rebuild-mpl',XDG_CACHE_HOME='/tmp/wolfram-rebuild-cache')
    try:
        for name,command in phases:
            if name in status['completed_phases']:
                print('Already completed within this clean run:',name,flush=True)
                continue
            check_source()
            status.update(state='running',active_phase=name)
            save_status(status)
            print(datetime.now(timezone.utc).isoformat(),name,flush=True)
            env['REBUILD_PHASE']=name
            with (STUDY/'logs'/f'{name}.log').open('a') as log:
                result=subprocess.run(command,cwd=STUDY,env=env,stdout=log,stderr=subprocess.STDOUT)
            if result.returncode:
                status.update(state='failed',failed_phase=name,exit_code=result.returncode)
                save_status(status)
                raise RuntimeError(f'{name} failed; see {STUDY}/logs/{name}.log')
            check_source()
            status['completed_phases'].append(name)
            status.pop('failed_phase',None);status.pop('exit_code',None)
            save_status(status)
        status.update(state='computation_complete',active_phase=None)
        save_status(status)
    finally:
        (lock/'owner.json').unlink();lock.rmdir()


if __name__=='__main__':main()
