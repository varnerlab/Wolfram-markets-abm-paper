"""Create a source-only arXiv archive from the manuscript's local dependencies.

Build Paper_v1.pdf first. The archive contains neither the output PDF nor
LaTeX build state. It includes local styles, bibliography sources/output, and
only figures referenced by the reachable TeX inputs.
"""
from pathlib import Path
import re
import tarfile

ROOT=Path(__file__).resolve().parent
OUT=ROOT.parent/'output'/'arxiv'
OUT.mkdir(parents=True,exist_ok=True)
files=set()

def add(path):
    path=path.resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError(f'Dependency outside paper directory: {path}')
    if not path.is_file():
        raise FileNotFoundError(path)
    if path in files: return
    files.add(path)
    if path.suffix!='.tex': return
    source=re.sub(r'(?<!\\)%.*','',path.read_text())
    for name in re.findall(r'\\(?:input|include)\{([^}]+)\}',source):
        target=ROOT/name
        add(target if target.suffix else target.with_suffix('.tex'))
    for name in re.findall(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}',source):
        target=ROOT/name
        if not target.suffix:
            target=next(p for ext in ('.pdf','.png','.jpg') if (p:=target.with_suffix(ext)).exists())
        add(target)
    for group in re.findall(r'\\usepackage(?:\[[^\]]*\])?\{([^}]+)\}',source):
        for name in group.split(','):
            local=ROOT/(name.strip()+'.sty')
            if local.exists(): add(local)
    for group in re.findall(r'\\bibliography\{([^}]+)\}',source):
        for name in group.split(','): add(ROOT/(name+'.bib'))

add(ROOT/'Paper_v1.tex')
add(ROOT/'Paper_v1.bbl')
add(ROOT/'abstract.txt')
archive=OUT/'Wolfram-markets-arxiv-source.tar.gz'
with tarfile.open(archive,'w:gz') as tar:
    for path in sorted(files):
        info=tar.gettarinfo(str(path),arcname=str(path.relative_to(ROOT)))
        info.uid=info.gid=0
        info.uname=info.gname=''
        with path.open('rb') as f: tar.addfile(info,f)
(OUT/'source-manifest.txt').write_text('\n'.join(str(p.relative_to(ROOT)) for p in sorted(files))+'\n')
print(f'{archive}: {len(files)} source/dependency files')

# Optional clean build proves that no undeclared repository file is required.
if __name__=='__main__':
    import sys
    if '--verify' in sys.argv:
        import tempfile,subprocess,hashlib,json
        with tempfile.TemporaryDirectory(prefix='market-arxiv-check-') as temporary:
            clean=Path(temporary)
            with tarfile.open(archive) as tar: tar.extractall(clean,filter='data')
            with (OUT/'clean-build.log').open('w') as log:
                subprocess.run(['latexmk','-pdf','-interaction=nonstopmode',
                                '-halt-on-error','Paper_v1.tex'],cwd=clean,
                               stdout=log,stderr=subprocess.STDOUT,check=True)
            text=[]
            for directory in (ROOT,clean):
                result=subprocess.run(['pdftotext',str(directory/'Paper_v1.pdf'),'-'],
                                      stdout=subprocess.PIPE,check=True)
                text.append(result.stdout)
            if text[0]!=text[1]:
                raise RuntimeError('Clean archive PDF text differs from manuscript build')
            report=dict(archive=str(archive.relative_to(ROOT.parent)),
                        source_files=len(files),
                        source_sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),
                        manuscript_sha256=hashlib.sha256((ROOT/'Paper_v1.pdf').read_bytes()).hexdigest(),
                        clean_compile=True,pdf_text_identical=True)
            (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
            print('Clean archive compilation passed; extracted PDF text is identical.')
