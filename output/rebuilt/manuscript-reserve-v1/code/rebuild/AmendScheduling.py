"""Record a scheduling-only revision before supplementary campaigns start."""
from pathlib import Path
import hashlib
import json
import shutil
import difflib
from datetime import datetime,timezone

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT/'output/rebuilt/manuscript-reserve-v1'


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    status=json.loads((STUDY/'Status.json').read_text())
    assert status['active_phase'] in ('size','balance')
    assert not set(status['completed_phases']) & {'controls','refinement','horizons','extended'}
    log=STUDY/'logs/scheduling-validation.log'
    assert '480    480' in log.read_text()
    inventory=STUDY/'Protocol.json';protocol=json.loads(inventory.read_text())
    assert not protocol.get('amendments')
    relative='code/revision/Revision-Lib.jl';source=STUDY/relative
    assert sha(source)==protocol['frozen_computation'][relative]
    before=source.read_text();needle='Threads.@threads :dynamic for i in eachindex(jobs)'
    assert before.count(needle)==1
    after=before.replace(needle,'Threads.@threads :greedy for i in eachindex(jobs)')
    archive=STUDY/'source-versions/scheduling-amendment';archive.mkdir(parents=True)
    shutil.copy2(inventory,archive/'Protocol-before.json')
    (archive/'Revision-Lib-before.jl').write_text(before)
    (archive/'Revision-Lib-after.jl').write_text(after)
    shutil.copy2(ROOT/'code/rebuild/Test-Scheduling.jl',archive/'Test-Scheduling.jl')
    shutil.copy2(log,archive/'validation.log')
    (archive/'change.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),
        fromfile=relative+' (before)',tofile=relative+' (after)')))
    amendment=dict(timestamp_utc=datetime.now(timezone.utc).isoformat(),kind='scheduling_only',
        affected_source=relative,before_sha256=sha(source),after_sha256=hashlib.sha256(after.encode()).hexdigest(),
        active_phase_unchanged=status['active_phase'],effective_phases=['controls','refinement','horizons','extended'],
        numerical_simulator_unchanged=True,parameters_unchanged=True,job_manifest_unchanged=True,
        analysis_unchanged=True,validation_checks=480,validation_sha256=sha(archive/'validation.log'),
        archived_versions=str(archive.relative_to(STUDY)),
        reason='Large-grid jobs have unequal cost; workers now take the next complete job instead of retaining contiguous job blocks.')
    source.write_text(after)
    protocol['frozen_computation'][relative]=amendment['after_sha256']
    protocol['amendments']=[amendment]
    temporary=inventory.with_suffix('.json.tmp');temporary.write_text(json.dumps(protocol,indent=2)+'\n');temporary.replace(inventory)
    (archive/'Amendment.json').write_text(json.dumps(amendment,indent=2)+'\n')
    print(json.dumps(amendment,indent=2))


if __name__=='__main__':main()
