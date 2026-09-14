"""Create an empty-data replica directly from a frozen corrected study."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
from datetime import datetime,timezone

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination',type=Path)
    args=parser.parse_args();destination=args.destination.expanduser().resolve()
    assert not destination.exists(),'Destination must not exist.'
    source_protocol=json.loads((STUDY/'Protocol.json').read_text())
    for name,digest in source_protocol['frozen_computation'].items():
        assert hashlib.sha256((STUDY/name).read_bytes()).hexdigest()==digest,name
    postprocessing=STUDY/'Postprocessing-Sources.json'
    if postprocessing.exists():
        for name,digest in json.loads(postprocessing.read_text())['files'].items():
            assert hashlib.sha256((STUDY/name).read_bytes()).hexdigest()==digest,name
    destination.mkdir(parents=True)
    for relative in ['code','paper-arxiv','docs']:
        for source in (STUDY/relative).rglob('*'):
            if not source.is_file():continue
            path=source.relative_to(STUDY)
            if any(part in ['data','figs','__pycache__'] for part in path.parts):continue
            if source.suffix not in ['.jl','.py','.sh','.toml','.txt','.tex','.bib','.sty','.cls','.md'] and source.name!='Makefile':continue
            target=destination/path;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    for name in ['Manifest.csv','Campaign-counts.json','Protocol.md']:
        shutil.copy2(STUDY/name,destination/name)
    for name in ['Postprocessing-Sources.json','Runtime-Environment.json','Analysis-Notes.md']:
        if (STUDY/name).exists():shutil.copy2(STUDY/name,destination/name)
    # Version history documents code provenance, not production outcomes.
    if (STUDY/'source-versions').exists():shutil.copytree(STUDY/'source-versions',destination/'source-versions')
    for relative in ['code/data','code/figs','paper-arxiv/figs','logs']:(destination/relative).mkdir(parents=True,exist_ok=True)
    protocol=dict(source_protocol)
    protocol.update(created_utc=datetime.now(timezone.utc).isoformat(),initial_cached_files=0,
        historical_data_imported=False,replicated_from_protocol_sha256=hashlib.sha256((STUDY/'Protocol.json').read_bytes()).hexdigest())
    (destination/'Protocol.json').write_text(json.dumps(protocol,indent=2)+'\n')
    assert not list((destination/'code/data').iterdir())
    assert not list((destination/'paper-arxiv/figs').iterdir())
    for name,digest in protocol['frozen_computation'].items():
        assert hashlib.sha256((destination/name).read_bytes()).hexdigest()==digest,name
    print('Prepared an empty-data replica:',destination)
    print('Run:',destination/'code/rebuild/Run.py')


if __name__=='__main__':main()
