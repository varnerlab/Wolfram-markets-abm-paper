"""Archive reviewed source and results, omitting restart checkpoints."""
from pathlib import Path
import hashlib
import json
import tarfile
from datetime import datetime,timezone

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert not (STUDY/'.writer-lock').exists()
    assert json.loads((STUDY/'Status.json').read_text())['state']=='computation_complete'
    verification=json.loads((STUDY/'Verification.json').read_text())
    build=json.loads((STUDY/'Build.json').read_text())
    review=json.loads((STUDY/'Visual-Review.json').read_text())
    assert verification['state']=='verified'
    assert review['all_pages_reviewed']
    assert review['pdf_sha256']==build['pdf_sha256']==sha(STUDY/'paper-arxiv/Paper_v1.pdf')
    for name,digest in json.loads((STUDY/'Protocol.json').read_text())['frozen_computation'].items():
        assert sha(STUDY/name)==digest,name
    for name,digest in json.loads((STUDY/'Postprocessing-Sources.json').read_text())['files'].items():
        assert sha(STUDY/name)==digest,name
    files=[]
    for path in sorted(STUDY.rglob('*')):
        if not path.is_file():continue
        rel=path.relative_to(STUDY)
        if any(part.endswith('Checkpoints') or part in ['__pycache__','.writer-lock'] for part in rel.parts):continue
        if path.name in ['.DS_Store','Artifact-Manifest.json','Completion.json']:continue
        files.append(path)
    manifest={str(path.relative_to(STUDY)):sha(path) for path in files}
    manifest_path=STUDY/'Artifact-Manifest.json'
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
    files.append(manifest_path)
    archive=STUDY.parent/(STUDY.name+'-source-and-results.tar.gz')
    temporary=archive.with_suffix(archive.suffix+'.tmp')
    with tarfile.open(temporary,'w:gz',compresslevel=6) as bundle:
        for path in files:bundle.add(path,arcname=str(Path(STUDY.name)/path.relative_to(STUDY)),recursive=False)
    with tarfile.open(temporary,'r:gz') as bundle:
        members=bundle.getmembers();assert len(members)==len(files)
        for member in members:
            relative=str(Path(member.name).relative_to(STUDY.name))
            if relative in manifest:
                assert hashlib.sha256(bundle.extractfile(member).read()).hexdigest()==manifest[relative],relative
    temporary.replace(archive)
    completed=dict(state='complete',completed_utc=datetime.now(timezone.utc).isoformat(),
        ledger_simulations=verification['total_completed_simulations'],
        verification_sha256=sha(STUDY/'Verification.json'),build_sha256=sha(STUDY/'Build.json'),
        artifact_manifest_sha256=sha(manifest_path),staged_pdf_sha256=build['pdf_sha256'],
        installed=build.get('installed',False),archive=str(archive.relative_to(STUDY.parent)),
        archive_sha256=sha(archive),archive_bytes=archive.stat().st_size,archived_files=len(files),
        restart_checkpoints_in_archive=False)
    (STUDY/'Completion.json').write_text(json.dumps(completed,indent=2)+'\n')
    print(json.dumps(completed,indent=2))


if __name__=='__main__':main()
