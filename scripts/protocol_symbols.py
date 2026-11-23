#!/usr/bin/env python3
"""Check scripts/protocol-symbols.tsv and write it as the class MaterialProtocolSymbolsTable.

The table of method protocols -> Material Symbols Rounded (package MaterialSymbols-Protocols) is data: this
script reads the TSV, stops on any wrong line (listing every one), and writes
src/MaterialSymbols-Protocols/MaterialProtocolSymbolsTable.class.st, whose class method `rows` answers the
rows as literal arrays #( pattern match symbolName ). Only the Python standard library is used.

    python3 scripts/protocol_symbols.py            # check and write
    python3 scripts/protocol_symbols.py --check    # check only, and fail if the class is not up to date
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TSV = ROOT / 'scripts' / 'protocol-symbols.tsv'
MANIFEST = ROOT / 'scripts' / 'manifest-symbols.json'
OUT = ROOT / 'src' / 'MaterialSymbols-Protocols' / 'MaterialProtocolSymbolsTable.class.st'
MATCHES = ('exact', 'prefix', 'extension')


def normalise(name):
    """The normalised protocol name, as MaterialProtocolSymbols class>>normalise: computes it"""
    s = ' '.join(name.lower().split())
    if s.startswith('*'):
        return s
    return ' '.join(s.replace('-', ' - ').split())


def read_rows():
    lines = [line.rstrip('\n') for line in TSV.read_text(encoding='utf-8').split('\n')]
    lines = [line for line in lines if line.strip() and not line.startswith('#')]
    header = lines[0].split('\t')
    for column in ('protocol', 'match', 'symbolName'):
        if column not in header:
            sys.exit(f'{TSV.name}: no column {column}')
    rows = []
    for number, line in enumerate(lines[1:], start=2):
        fields = line.split('\t')
        rows.append((number, dict(zip(header, fields))))
    return rows


def check(rows):
    names = {icon['name'] for icon in json.loads(MANIFEST.read_text(encoding='utf-8'))['icons']}
    errors = []
    seen = set()
    for number, row in rows:
        pattern, match, symbol = row.get('protocol', ''), row.get('match', ''), row.get('symbolName', '')
        where = f'row {number} ({pattern!r})'
        if match not in MATCHES:
            errors.append(f'{where}: match {match!r} is not one of {MATCHES}')
        if symbol not in names:
            errors.append(f'{where}: {symbol!r} is not a Material Symbols Rounded icon')
        if not pattern or normalise(pattern) != pattern:
            errors.append(f'{where}: the pattern is not normalised ({normalise(pattern)!r})')
        if (match == 'extension') != pattern.startswith('*'):
            errors.append(f'{where}: extension patterns, and only they, begin with *')
        if "'" in pattern:
            errors.append(f'{where}: a quote in the pattern')
        if (pattern, match) in seen:
            errors.append(f'{where}: given twice')
        seen.add((pattern, match))
    if errors:
        sys.exit('\n'.join([f'{TSV.name}: {len(errors)} wrong rows'] + errors))


def smalltalk(rows):
    count = {m: sum(1 for _, r in rows if r['match'] == m) for m in MATCHES}
    symbols = len({r['symbolName'] for _, r in rows})
    body = '\n'.join(
        f"\t\t#( '{r['protocol']}' #{r['match']} #'{r['symbolName']}' )" for _, r in rows)
    return f'''"
I am the table of `MaterialProtocolSymbols`: method protocols to Material Symbols Rounded. `scripts/protocol_symbols.py` writes me from `scripts/protocol-symbols.tsv` (where every row has its reason): edit that file and run the script, not me.

{len(rows)} rows ({count['exact']} exact, {count['prefix']} prefix, {count['extension']} extension), {symbols} symbols.
"
Class {{
	#name : 'MaterialProtocolSymbolsTable',
	#superclass : 'Object',
	#category : 'MaterialSymbols-Protocols',
	#package : 'MaterialSymbols-Protocols'
}}

{{ #category : 'accessing' }}
MaterialProtocolSymbolsTable class >> rows [
	"#( pattern match symbolName ), in the order of scripts/protocol-symbols.tsv. The pattern is a normalised protocol name (MaterialProtocolSymbols class>>#normalise:); match is #exact, #prefix (the name, or the name followed by a non-letter) or #extension ('*' or '*word': an extension protocol whose package contains word)"

	^ #(
{body} )
]
'''


def main():
    rows = read_rows()
    check(rows)
    text = smalltalk(rows)
    if '--check' in sys.argv[1:]:
        if not OUT.exists() or OUT.read_text(encoding='utf-8') != text:
            sys.exit(f'{OUT.relative_to(ROOT)} is not up to date: run scripts/protocol_symbols.py')
        print(f'{TSV.name}: {len(rows)} rows, all fine; {OUT.name} up to date')
        return
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding='utf-8')
    print(f'{TSV.name}: {len(rows)} rows, all fine; wrote {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
