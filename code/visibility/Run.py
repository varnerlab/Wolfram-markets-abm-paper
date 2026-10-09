"""Test and execute the frozen visibility study, its prescribed extension, and analysis."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import pandas as pd
from Analyze import check_frozen,load_runs

def extend(study,protocol):
    if protocol['mode']!='main' or (study/'Extension.json').exists():
        return
    manifest=pd.read_csv(study/'Manifest.csv')
    runs=load_runs(study,manifest)
    rows=[];decisions=[]
    for (boundary,h),group in runs.groupby(['boundary','h']):
        inventory=group[(group['mode']=='inventory')&(group.role=='switch')]
        low=inventory[inventory.f==.10].majority.mean()
        high=inventory[inventory.f==.25].majority.mean()
        fractions=(protocol['extension']['low'] if low>.25 else [])+(
            protocol['extension']['high'] if high<.75 else [])
        decisions.append(dict(boundary=boundary,h=h,p_at_010=low,p_at_025=high,fractions=fractions))
        templates=manifest[(manifest.boundary==boundary)&(manifest.h==h)&
                           (manifest.role=='switch')&(manifest.f==.20)]
        for f in fractions:
            for template in templates.to_dict('records'):
                template.update(f=f,save_history=False)
                template['id']=f"{template['group']}-{template['mode']}-switch-f{f:g}"
                rows.append(template)
    extension=pd.DataFrame(rows,columns=manifest.columns)
    extension.to_csv(study/'Extension.csv',index=False)
    report=dict(created_utc=datetime.now(timezone.utc).isoformat(),decisions=decisions,
        simulations=len(rows),manifest_sha256=hashlib.sha256((study/'Extension.csv').read_bytes()).hexdigest())
    (study/'Extension.json').write_text(json.dumps(report,indent=2)+'\n')
    print(f'Prespecified extension: {len(rows)} simulations',flush=True)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('study',type=Path);parser.add_argument('--threads',type=int,default=12)
    args=parser.parse_args();study=args.study.resolve()
    protocol=json.loads((study/'Protocol.json').read_text());check_frozen(study,protocol)
    lock=study/'.writer-lock';lock.mkdir()
    (lock/'owner.json').write_text(json.dumps(dict(pid=os.getpid())))
    env=os.environ.copy();env['JULIA_PKG_OFFLINE']='true'
    command=['julia','--project='+str(study/'code'),'--startup-file=no',
             '--threads='+str(args.threads),'--gcthreads=1']
    status=dict(version=protocol['version'],mode=protocol['mode'],pid=os.getpid())
    def save(state,**extra):
        status.update(state=state,updated_utc=datetime.now(timezone.utc).isoformat(),**extra)
        (study/'Status.json').write_text(json.dumps(status,indent=2)+'\n')
    def run(phase,script,arguments):
        save(phase);check_frozen(study,protocol)
        with (study/'logs'/f'{phase}.log').open('a') as log:
            subprocess.run(command+[str(study/'code/visibility'/script)]+arguments,
                cwd=study,env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
        check_frozen(study,protocol)
    try:
        run('testing','Test.jl',[])
        run('main','Run.jl',[str(study),'Manifest.csv'])
        extend(study,protocol)
        if (study/'Extension.csv').exists() and len(pd.read_csv(study/'Extension.csv')):
            run('extension','Run.jl',[str(study),'Extension.csv'])
        save('analyzing')
        subprocess.run([sys.executable,str(study/'code/visibility/Analyze.py'),str(study)],check=True)
        check_frozen(study,protocol);save('complete')
    except BaseException as error:
        save('failed',error=str(error));raise
    finally:
        (lock/'owner.json').unlink();lock.rmdir()

if __name__=='__main__':
    main()
