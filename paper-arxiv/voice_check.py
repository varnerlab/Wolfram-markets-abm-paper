"""Measure prose rhythm and flag voice violations against VOICE_GUIDE.md.

Usage: python3 paper-arxiv/voice_check.py paper-arxiv/sections/results.tex [...]
Files are pooled in the order given, so a section and its \\input files can
be checked together. Methods may legitimately hold shorter paragraphs.
"""
import re
import statistics as st
import sys

BANNED = (r'\b(notably|importantly|interestingly|moreover|furthermore|additionally|indeed|'
          r'crucially|remarkabl\w*|striking\w*|dramatic\w*|clearly|very|powerful|novel|robust\w*|'
          r'significant\w*|note that|in summary|in conclusion|to our knowledge)\b')
VAGUE = r'\b(that price|this market|these results|this behavior|the former|the latter)\b'
SUBJECT = (r'^(Supplementary\s+)?(Fig\.|Figs\.|Figure|Table|Tables)\s*~?\\ref\{[^}]+\}[A-Z,\-]*\s+'
           r'(shows?|reports?|gives?|displays?|illustrates?|compares?|summari[sz]es?|presents?)\b')
ABBR = (r'(?<!\bFig\.)(?<!\bFigs\.)(?<!\bEq\.)(?<!\bEqs\.)(?<!\be\.g\.)(?<!\bi\.e\.)'
        r'(?<!\bal\.)(?<!\bvs\.)(?<!\bSec\.)(?<!\bRef\.)(?<!\bapprox\.)(?<!\bcf\.)')


def clean(tex):
    tex = re.sub(r'(?<!\\)%.*', '', tex)
    tex = re.sub(r'\\begin\{(equation|align|figure|table|tabular|itemize|enumerate|algorithm)\*?\}'
                 r'.*?\\end\{\1\*?\}', ' ', tex, flags=re.S)
    tex = re.sub(r'\\(section|subsection|paragraph|input)\*?\{[^}]*\}', '\n\n', tex)
    return tex


def plain(par):
    par = re.sub(r'\$[^$]*\$', 'X', par)
    par = re.sub(r'\\(cite\w*|label|ref|eqref)\*?(\[[^\]]*\])?\{[^}]*\}', 'R', par)
    par = re.sub(r'\\(textit|textbf|emph|texttt|text)\{([^}]*)\}', r'\2', par)
    par = par.replace('~', ' ').replace('{,}', ',')
    par = re.sub(r'\\[a-zA-Z]+\*?', '', par)
    return re.sub(r'\s+', ' ', par.replace('{', '').replace('}', '')).strip()


def sentences(text):
    return [s for s in re.split(ABBR + r'(?<=[.?!])\s+(?=[A-Z(\\])', text) if len(s.split()) >= 3]


def main(paths):
    raw = '\n\n'.join(clean(open(p, encoding='utf-8').read()) for p in paths)
    paras = [p for p in re.split(r'\n\s*\n', raw) if len(plain(p).split()) >= 12]
    lengths, commas, flags = [], [], []
    for i, par in enumerate(paras, 1):
        text = plain(par)
        sents = sentences(text)
        sl = [len(s.split()) for s in sents]
        lengths += sl
        commas += [s.count(',') for s in sents]
        words = len(text.split())
        med = st.median(sl) if sl else 0
        note = []
        if words < 150:
            note.append(f'short paragraph ({words}w)')
        if len(sl) >= 4 and med < 20:
            note.append(f'choppy: sentence median {med:.0f}w')
        note += [f'long sentence ({n}w): "{s[:70]}..."' for s, n in zip(sents, sl) if n > 60]
        note += [f'semicolon chain: "{s[:70]}..."' for s in sents if s.count(';') >= 2]
        note += [f'banned word "{m.group(0)}"' for m in re.finditer(BANNED, text, re.I)]
        note += [f'vague reference "{m.group(0)}"' for m in re.finditer(VAGUE, text, re.I)]
        if '---' in par or '\u2014' in par:
            note.append('em dash')
        for s in re.split(r'(?<=[.?!])\s+', re.sub(r'\s+', ' ', par)):
            if re.match(SUBJECT, s):
                note.append(f'figure/table as subject: "{s[:60]}..."')
        print(f'P{i:<2} {words:4d}w  {len(sl):2d} sentences  median {med:4.0f}w  '
              f'lengths {sl}')
        flags += [f'  P{i}: {n}' for n in note]
    if not lengths:
        return
    lengths.sort()
    n = len(lengths)
    print(f'\nALL  sentences {n}, median {st.median(lengths):.0f}w '
          f'(target 21-25), p90 {lengths[int(.9 * n) - 1]}w (target 35-46), '
          f'max {lengths[-1]}w, commas/sentence median {st.median(commas):.0f} (target 1)')
    print('\n'.join(['\nFLAGS'] + flags) if flags else '\nFLAGS none')


if __name__ == '__main__':
    main(sys.argv[1:])
