"""Keep the submission-form abstract synchronized with the LaTeX manuscript."""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parent

def plain_abstract():
    source=(ROOT/'Paper_v1.tex').read_text()
    abstract=re.search(r'\\begin\{abstract\}(.*?)\\end\{abstract\}',source,re.S).group(1)
    abstract=re.sub(r'(?<!\\)%[^\n]*','',abstract)
    abstract=abstract.replace(r'\%','%').replace(r'\&','&').replace('~',' ')
    if re.search(r'[\\${}]',abstract):
        raise ValueError('Abstract contains notation requiring an explicit plain-text rendering')
    text=' '.join(abstract.split())
    # arXiv metadata requirements, checked 2026-10-07:
    # https://info.arxiv.org/help/prep.html#abstract-required
    if not text.isascii() or len(text)>1920:
        raise ValueError('The arXiv abstract must be ASCII and at most 1920 characters')
    return text+'\n'

if __name__=='__main__':
    text=plain_abstract()
    (ROOT/'abstract.txt').write_text(text)
    print(f'abstract.txt synchronized: {len(text.split())} words, {len(text.strip())} characters')
