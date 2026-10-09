"""Freeze the inventory-visibility computation, design, and environment."""
import argparse
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'output/rebuilt/manuscript-reserve-v1'
FRACTIONS = [0.10, 0.15, 0.175, 0.18, 0.20, 0.25]

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def make_rows(mode):
    seeds = range(730001,730051) if mode == 'main' else range(720001,720003)
    fractions = FRACTIONS if mode == 'main' else [0.175,0.20]
    pre,post,L = (20,80,12) if mode == 'smoke' else (1000,3000,64)
    rows=[]
    for boundary in ('hold','endogenous'):
        for h in (1.0,100.0):
            for seed in seeds:
                group=f'{boundary}-h{h:g}-s{seed}'
                for observation in ('original','inventory'):
                    for role,f in [('control',max(fractions))]+[('switch',f) for f in fractions]:
                        rows.append(dict(id=f'{group}-{observation}-{role}-f{f:g}',group=group,
                            mode=observation,role=role,seed=seed,L=L,boundary=boundary,h=h,
                            f=f,pre=pre,post=post,
                            save_history=seed==seeds.start and (role=='control' or f==0.20)))
    return rows

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination',type=Path)
    parser.add_argument('--mode',choices=['smoke','pilot','main'],default='main')
    args=parser.parse_args(); dest=args.destination.resolve()
    if dest.exists():
        raise SystemExit('Destination must not already exist')
    ref=json.loads((REFERENCE/'Protocol.json').read_text())
    for name,expected in ref['frozen_computation'].items():
        assert digest(REFERENCE/name)==expected,name
    sources=list((REFERENCE/'code/src').glob('*.jl'))
    sources += [REFERENCE/'code/Project.toml',REFERENCE/'code/Manifest.toml']
    for p in sources:
        target=dest/p.relative_to(REFERENCE)
        target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(p,target)
    for p in (ROOT/'code/visibility').iterdir():
        if p.is_file() and p.suffix in ('.jl','.py','.md'):
            target=dest/'code/visibility'/p.name
            target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(p,target)
    ledger=REFERENCE/'code/data/Rebuild-Execution-Ledger.csv'
    with ledger.open() as stream:
        records=list(csv.DictReader(stream))
    selected=[r for r in records if int(r['seed'])==1 and int(r['L'])==64 and
        int(r['steps'])==4000 and float(r['h'])==100 and float(r['f'])==.2 and
        int(r['rule'])==19286 and r['activation_step']=='1001' and r['boundary']=='hold' and
        r['action']=='rule' and r['resource_intervention']=='false']
    assert selected
    with (dest/'code/visibility/Reference.csv').open('w',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=selected[0]);writer.writeheader();writer.writerows(selected)
    for name in ('results','histories','logs'):
        (dest/name).mkdir()
    rows=make_rows(args.mode)
    with (dest/'Manifest.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=rows[0]);writer.writeheader();writer.writerows(rows)
    shutil.copy2(ROOT/'code/visibility/README.md',dest/'Protocol.md')
    environment=dict(python=sys.version,julia=subprocess.check_output(['julia','--version'],text=True).strip(),
                     reference_ledger_sha256=digest(ledger))
    (dest/'Runtime-Environment.json').write_text(json.dumps(environment,indent=2)+'\n')
    frozen={str(p.relative_to(dest)):digest(p) for p in sorted(dest.rglob('*')) if p.is_file()}
    protocol=dict(version='inventory-visibility-v1',mode=args.mode,
        created_utc=datetime.now(timezone.utc).isoformat(),simulations=len(rows),
        reference_protocol_sha256=digest(REFERENCE/'Protocol.json'),frozen_files=frozen,
        primary=dict(f=0.20,h=100.0,boundary='hold',outcome='final_sell_mean'),
        bootstrap_replicates=10000,bootstrap_seed=730099,
        extension=dict(high_trigger='inventory p(majority|f=.25)<.75',high=[.35,.5,.75,1.0],
                       low_trigger='inventory p(majority|f=.10)>.25',low=[.025,.05]))
    (dest/'Protocol.json').write_text(json.dumps(protocol,indent=2)+'\n')
    print(f'Prepared {dest}: {len(rows)} simulations ({args.mode})')

if __name__=='__main__':
    main()
