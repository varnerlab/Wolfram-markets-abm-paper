"""Build the corrected manuscript; optionally install it after visual review."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from datetime import datetime,timezone

ROOT=Path(__file__).resolve().parents[2]
STUDY=ROOT if (ROOT/'Protocol.json').exists() else ROOT/'output/rebuilt/manuscript-reserve-v1'
PAPER=STUDY/'paper-arxiv'
FIGURES=['Fig1-RuleQuench','Fig2-ReservoirQuench','Fig3-FiniteSizeQuench',
         'Fig4-DoseMarketPanels','Fig5-DealerMarketPanels','Fig6-BalanceSheetQuench']


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def build(directory,logpath):
    with logpath.open('w') as log:
        subprocess.run(['latexmk','-pdf','-interaction=nonstopmode','-halt-on-error','Paper_v1.tex'],
                       cwd=directory,stdout=log,stderr=subprocess.STDOUT,check=True)
    log=(directory/'Paper_v1.log').read_text()
    errors=[line for line in log.splitlines() if any(word in line for word in
        ('LaTeX Warning:','Package natbib Warning:','Overfull \\hbox','Overfull \\vbox'))]
    assert not errors,errors
    blg=directory/'Paper_v1.blg'
    if blg.exists():assert 'Warning--' not in blg.read_text()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--install',action='store_true',help='install the visually reviewed staged files into the repository manuscript')
    args=parser.parse_args()
    verification=json.loads((STUDY/'Verification.json').read_text());assert verification['state']=='verified'
    assert json.loads((STUDY/'Status.json').read_text())['state']=='computation_complete'
    for name,digest in verification['figure_sha256'].items():assert sha(PAPER/'figs'/f'{name}.pdf')==digest
    build(PAPER,STUDY/'logs/manuscript-build.log')
    tex_files=[PAPER/'Paper_v1.tex',PAPER/'References_v1.bib',*sorted((PAPER/'sections').glob('*.tex'))]
    support_files=sorted([*(PAPER.glob('*.sty')),*(PAPER.glob('*.cls'))])
    inputs={str(p.relative_to(STUDY)):sha(p) for p in tex_files}
    inputs.update({str(p.relative_to(STUDY)):sha(p) for p in support_files})
    inputs.update({f'paper-arxiv/figs/{name}.pdf':sha(PAPER/'figs'/f'{name}.pdf') for name in FIGURES})
    inputs.update({str(p.relative_to(STUDY)):sha(p) for p in sorted((STUDY/'code/data').glob('*.csv'))})
    report=dict(built_utc=datetime.now(timezone.utc).isoformat(),inputs=inputs,pdf_sha256=sha(PAPER/'Paper_v1.pdf'),
                latex_warnings=0,bibtex_warnings=0,overfull_boxes=0,installed=False)
    (STUDY/'Build.json').write_text(json.dumps(report,indent=2)+'\n')
    if args.install:
        assert ROOT!=STUDY,'Use the repository-root command for installation.'
        review=json.loads((STUDY/'Visual-Review.json').read_text())
        assert review['pdf_sha256']==report['pdf_sha256'] and review['all_pages_reviewed']
        destination=ROOT/'paper-arxiv'
        for p in support_files:assert sha(destination/p.relative_to(PAPER))==sha(p)
        for p in tex_files:shutil.copy2(p,destination/p.relative_to(PAPER))
        for name in FIGURES:
            shutil.copy2(PAPER/'figs'/f'{name}.pdf',destination/'figs'/f'{name}.pdf')
            shutil.copy2(PAPER/'figs'/f'{name}.pdf',ROOT/'code/figs'/f'{name}.pdf')
        build(destination,STUDY/'logs/installed-manuscript-build.log')
        def text(path):return subprocess.check_output(['pdftotext',str(path),'-'])
        assert text(PAPER/'Paper_v1.pdf')==text(destination/'Paper_v1.pdf')
        output=ROOT/'output/pdf';output.mkdir(exist_ok=True)
        shutil.copy2(destination/'Paper_v1.pdf',output/'Wolfram-markets-revised.pdf')
        with (STUDY/'logs/arxiv-package.log').open('w') as log:
            subprocess.run(['python3',str(destination/'package_arxiv.py'),'--verify'],cwd=ROOT,
                           stdout=log,stderr=subprocess.STDOUT,check=True)
        report.update(installed=True,installed_pdf_sha256=sha(destination/'Paper_v1.pdf'),arxiv_verified=True)
        (STUDY/'Build.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='inputs'},indent=2))


if __name__=='__main__':main()
