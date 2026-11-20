#!/usr/bin/env python3
"""Generate the icon data of material-icons.st from the pinned Material Icons Rounded SVGs.

    python3 -I scripts/generate.py [--cache DIR]            fetch, rasterize, write the Tonel files
    python3 -I scripts/generate.py --check [--cache DIR]    the same, but only compare with the files in src/
    python3 -I scripts/generate.py pin [--cache DIR]        rebuild scripts/manifest.json (network, live metadata)

The default command reads scripts/manifest.json (the pin: the upstream commit, and the
name, category, codepoint, tags and SHA-256 of every icon), downloads each icon's 24px.svg
from raw.githubusercontent.com at that commit into the cache (build/cache by default),
checks its SHA-256, rasterizes it with CairoSVG at 16, 24 and 32 pixels (Pharo's scales
1, 1.5 and 2), and writes:

    src/MaterialIcons-Rounded/                  one class per Material category, one method per icon
    src/MaterialIcons-ThemePack/MaterialThemeIconsArt.class.st
                                                the Pharo icon keys mapped by scripts/pharo-mapping.tsv,
                                                and their pixels when svgPack draws them at another size

Each PNG holds only the shape: 8-bit grey (always 0) and alpha, so the image can paint it
in any colour. Rerunning on the same inputs (same CairoSVG, cairo and zlib) writes the same
bytes. CairoSVG and its Python dependencies are pinned in scripts/requirements.txt; it needs
libcairo (the generated data was made with cairo 1.18.6).

`pin` downloads the live Google Fonts metadata (the one of fonts.google.com/icons), keeps
the icons that the family "Material Icons Round" supports, downloads their SVGs at the
pinned commit and writes their SHA-256: run it only to move the pin.
"""

import argparse
import base64
import concurrent.futures
import datetime
import hashlib
import json
import os
import struct
import sys
import urllib.request
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
MANIFEST = os.path.join(HERE, 'manifest.json')
MAPPING = os.path.join(HERE, 'pharo-mapping.tsv')
ICON_LICENSE = os.path.join(ROOT, 'LICENSE-material-icons')

REPOSITORY = 'google/material-design-icons'
COMMIT = '3912baecc97388955ce39f5e26bfb786a70cbe48'
SVG_PATH = 'src/{category}/{name}/materialiconsround/24px.svg'
RAW_URL = 'https://raw.githubusercontent.com/{repository}/{commit}/{path}'
METADATA_URL = 'https://fonts.google.com/metadata/icons?key=material_symbols&incomplete=true'
FAMILY = 'Material Icons Round'
CAIRO_VERSION = '1.18.6'
SIZES = (16, 24, 32)
SCALES = ('1', '1.5', '2')
USER_AGENT = 'material-icons.st-generator'

PACKAGE = 'MaterialIcons-Rounded'
THEME_PACKAGE = 'MaterialIcons-ThemePack'
ROOT_CLASS = 'MaterialIconsRoundedCategory'
ART_CLASS = 'MaterialThemeIconsArt'
CATEGORY_CLASS_NAMES = {'av': 'AV'}


# ---------------------------------------------------------------- downloads

def fetch(url):
    last = None
    for _ in range(4):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except Exception as error:  # retried, then reported
            last = error
    raise RuntimeError(f'cannot download {url}: {last}')


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def svg_url(manifest, icon):
    upstream = manifest['upstream']
    path = upstream['path'].format(category=icon['category'], name=icon['name'])
    return RAW_URL.format(repository=upstream['repository'], commit=upstream['commit'], path=path)


def cached(cache, relative, url, expected):
    """The bytes of url, kept in cache/relative, checked against the SHA-256 expected."""
    path = os.path.join(cache, relative)
    if os.path.exists(path):
        with open(path, 'rb') as stream:
            data = stream.read()
        if sha256(data) == expected:
            return data
    data = fetch(url)
    if sha256(data) != expected:
        raise RuntimeError(f'{url}: SHA-256 {sha256(data)}, expected {expected}')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + '.part', 'wb') as stream:
        stream.write(data)
    os.replace(path + '.part', path)
    return data


def fetch_sources(manifest, cache):
    """name -> SVG bytes, every file checked against the manifest."""
    commit = manifest['upstream']['commit']
    icons = manifest['icons']
    with concurrent.futures.ThreadPoolExecutor(16) as pool:
        datas = pool.map(
            lambda icon: cached(cache, f'{commit}/{icon["name"]}.svg', svg_url(manifest, icon), icon['sha256']),
            icons)
        return {icon['name']: data for icon, data in zip(icons, datas)}


# ---------------------------------------------------------------- pin

def pin(cache):
    raw = fetch(METADATA_URL)
    text = raw.decode('utf-8')
    if text.startswith(")]}'"):
        text = text.split('\n', 1)[1]
    metadata = json.loads(text)
    entries = [each for each in metadata['icons'] if FAMILY not in each.get('unsupported_families', [])]
    names = [each['name'] for each in entries]
    if len(names) != len(set(names)):
        raise RuntimeError('duplicate icon names in the metadata')
    upstream = {'repository': REPOSITORY, 'commit': COMMIT, 'path': SVG_PATH}
    license_url = RAW_URL.format(repository=REPOSITORY, commit=COMMIT, path='LICENSE')
    license = fetch(license_url)
    upstream['license'] = {'path': 'LICENSE', 'sha256': sha256(license)}
    manifest = {'upstream': upstream, 'icons': []}
    for each in sorted(entries, key=lambda e: e['name']):
        if len(each['categories']) != 1:
            raise RuntimeError(f'{each["name"]}: categories {each["categories"]}')
        manifest['icons'].append({
            'name': each['name'], 'category': each['categories'][0], 'codepoint': each['codepoint'],
            'version': each['version'], 'tags': each['tags'], 'sha256': None})

    def hash_of(icon):
        return sha256(fetch(svg_url(manifest, icon)))

    with concurrent.futures.ThreadPoolExecutor(16) as pool:
        for icon, digest in zip(manifest['icons'], pool.map(hash_of, manifest['icons'])):
            icon['sha256'] = digest
    manifest['metadata'] = {
        'url': METADATA_URL, 'family': FAMILY, 'round_subset_sha256': round_subset_sha256(entries),
        'retrieved': datetime.date.today().isoformat(), 'icons': len(manifest['icons'])}
    write_manifest(manifest)
    print(f'{len(manifest["icons"])} icons pinned at {COMMIT}')


def round_subset_sha256(entries):
    """The SHA-256 of what the pin takes from the metadata: the icons of FAMILY, sorted by name,
    with their name, categories, codepoint, version and tags, as compact JSON of sorted keys.
    The raw response cannot be hashed: its popularity counters change from one fetch to the next."""
    keys = ('name', 'categories', 'codepoint', 'version', 'tags')
    subset = [{key: each[key] for key in keys} for each in sorted(entries, key=lambda e: e['name'])]
    return sha256(json.dumps(subset, sort_keys=True, separators=(',', ':')).encode('utf-8'))


def write_manifest(manifest):
    lines = ['{']
    for key in ('upstream', 'metadata'):
        lines.append(f' {json.dumps(key)}: {json.dumps(manifest[key], sort_keys=True)},')
    lines.append(' "icons": [')
    icons = [f'  {json.dumps(icon, sort_keys=True)}' for icon in manifest['icons']]
    lines.append(',\n'.join(icons))
    lines.append(' ]')
    lines.append('}')
    with open(MANIFEST, 'w', encoding='utf-8') as stream:
        stream.write('\n'.join(lines) + '\n')


# ---------------------------------------------------------------- PNG

def png_chunks(data):
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('not a PNG')
    position = 8
    while position < len(data):
        length, kind = struct.unpack('>I4s', data[position:position + 8])
        yield kind, data[position + 8:position + 8 + length]
        position += 12 + length


def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    return b if pb <= pc else c


def unfilter(raw, width, height, bpp):
    stride = width * bpp
    rows, previous, position = [], bytearray(stride), 0
    for _ in range(height):
        kind = raw[position]
        line = bytearray(raw[position + 1:position + 1 + stride])
        position += 1 + stride
        for i in range(stride):
            left = line[i - bpp] if i >= bpp else 0
            up = previous[i]
            corner = previous[i - bpp] if i >= bpp else 0
            if kind == 1:
                line[i] = (line[i] + left) & 255
            elif kind == 2:
                line[i] = (line[i] + up) & 255
            elif kind == 3:
                line[i] = (line[i] + ((left + up) >> 1)) & 255
            elif kind == 4:
                line[i] = (line[i] + paeth(left, up, corner)) & 255
            elif kind != 0:
                raise ValueError(f'filter {kind}')
        rows.append(bytes(line))
        previous = line
    return rows


def alpha_of_png(data):
    """The alpha rows of an 8-bit RGBA PNG whose colour is black wherever it is not transparent."""
    header, idat = None, b''
    for kind, body in png_chunks(data):
        if kind == b'IHDR':
            header = struct.unpack('>IIBBBBB', body)
        elif kind == b'IDAT':
            idat += body
    width, height, depth, colour, _, _, interlace = header
    if (depth, colour, interlace) != (8, 6, 0):
        raise ValueError(f'unexpected PNG {header}')
    rows = unfilter(zlib.decompress(idat), width, height, 4)
    alphas = []
    for row in rows:
        for i in range(0, len(row), 4):
            if row[i + 3] and max(row[i:i + 3]) > 0:
                raise ValueError('a coloured pixel: the icons are expected to be black')
        alphas.append(bytes(row[3::4]))
    return width, height, alphas


def filtered(kind, line, previous, bpp):
    out = bytearray(len(line))
    for i, value in enumerate(line):
        left = line[i - bpp] if i >= bpp else 0
        up = previous[i]
        corner = previous[i - bpp] if i >= bpp else 0
        predictor = (0, left, up, (left + up) >> 1, paeth(left, up, corner))[kind]
        out[i] = (value - predictor) & 255
    return out


def la_png(width, height, alphas):
    """An 8-bit grey+alpha PNG (colour type 4), grey 0: per row the filter of least sum of
    absolute values (as libpng's heuristic), then zlib at level 9."""
    previous, raw = bytes(width * 2), bytearray()
    for alpha in alphas:
        line = bytearray(width * 2)
        line[1::2] = alpha
        best = min(range(5), key=lambda k: (sum(min(b, 256 - b) for b in filtered(k, line, previous, 2)), k))
        raw.append(best)
        raw += filtered(best, line, previous, 2)
        previous = line

    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body))

    return (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 4, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(bytes(raw), 9))
            + chunk(b'IEND', b''))


class Rasterizer:
    def __init__(self):
        try:
            import cairocffi
            import cairosvg
        except (ImportError, OSError) as error:
            raise SystemExit(
                f'CairoSVG is not usable ({error}): pip install -r scripts/requirements.txt, '
                'and make libcairo.so.2 loadable (LD_LIBRARY_PATH)')
        self.cairosvg = cairosvg
        self.cairo = cairocffi.cairo_version_string()
        self.description = f'CairoSVG {cairosvg.__version__} on cairo {self.cairo}'
        if self.cairo != CAIRO_VERSION:
            print(f'warning: cairo {self.cairo}, the data was generated with cairo {CAIRO_VERSION}: '
                  'the pixels may differ', file=sys.stderr)

    def png(self, svg, size):
        rendered = self.cairosvg.svg2png(bytestring=svg, output_width=size, output_height=size)
        width, height, alphas = alpha_of_png(rendered)
        if (width, height) != (size, size):
            raise ValueError(f'rendered {width}x{height}, expected {size}')
        return la_png(width, height, alphas)


# ---------------------------------------------------------------- Tonel

def st_string(text):
    return "'" + text.replace("'", "''") + "'"


def st_symbol(text):
    simple = text[:1].isalpha() and all(c.isalnum() or c == '_' for c in text)
    return '#' + text if simple else '#' + st_string(text)


def class_name(category):
    return 'MaterialIconsRounded' + CATEGORY_CLASS_NAMES.get(category, category.capitalize())


def tonel_class(name, superclass, package, comment, methods):
    """methods: (class side?, selector, category, source lines after the selector line)"""
    out = ['"', comment.replace('"', '""'), '"', 'Class {',
           f"\t#name : '{name}',", f"\t#superclass : '{superclass}',",
           f"\t#category : '{package}',", f"\t#package : '{package}'", '}']
    for meta, selector, category, body in sorted(methods, key=lambda m: (not m[0], m[1])):
        out += ['', f"{{ #category : '{category}' }}",
                f'{name}{" class" if meta else ""} >> {selector} [', *body, ']']
    return '\n'.join(out) + '\n'


def png_array(pngs):
    return '\t^ #( ' + ' '.join(st_string(base64.b64encode(p).decode('ascii')) for p in pngs) + ' )'


def source_of(manifest):
    upstream = manifest['upstream']
    return f'https://github.com/{upstream["repository"]} at commit {upstream["commit"]}, {upstream["path"]}'


def generate(manifest, sources, rasterizer):
    """path relative to ROOT -> text of every generated file."""
    files = {}
    pkg = f'src/{PACKAGE}'
    icons = manifest['icons']
    categories = sorted({icon['category'] for icon in icons})
    upstream = manifest['upstream']
    files[f'{pkg}/package.st'] = f"Package {{ #name : '{PACKAGE}' }}\n"
    source = source_of(manifest)
    counts = ' '.join(f'#( {st_string(c)} {sum(1 for i in icons if i["category"] == c)} )' for c in categories)
    files[f'{pkg}/{ROOT_CLASS}.class.st'] = tonel_class(
        ROOT_CLASS, 'MaterialIconsCategory', PACKAGE,
        'I am the root of the categories of Material Icons Rounded, the icons of the family Material Icons Round '
        '(fonts.google.com/icons, icon.set=Material+Icons, icon.style=Rounded). Each subclass holds the icons '
        'of one Material category: one class-side method per icon, `icon_<name>`, answering its PNGs at 16, 24 '
        'and 32 pixels (scales 1, 1.5 and 2) in Base64, and `iconTable`, the name, codepoint and tags of each.\n\n'
        f'Source: {source}, Apache License 2.0 (Google), whose text is `licenseText`. '
        f'Rasterized by {rasterizer.description}.\n\n'
        'Generated by scripts/generate.py: do not edit, regenerate.',
        [(True, 'materialStyle', 'accessing', ['', '\t^ #rounded']),
         (True, 'iconCount', 'accessing',
          ['\t"The number of icons of the style, over all its categories"', '', f'\t^ {len(icons)}']),
         (True, 'categoryCounts', 'accessing',
          ['\t"The number of icons of each category"', '', f'\t^ #( {counts} )']),
         (True, 'upstreamCommit', 'accessing', ['', f"\t^ '{upstream['commit']}'"]),
         (True, 'upstreamDescription', 'accessing', ['', f'\t^ {st_string(source)}']),
         (True, 'licenseText', 'licence', [
             '\t"The Apache License 2.0 of Material Icons (LICENSE-material-icons, the LICENSE of the upstream',
             '\trepository at the pinned commit), in the image with the icons it covers.',
             '\tMaterialThemeIcons class >> exportPack:to: puts it in the zip"',
             '', '\t^ ' + st_string(icon_license(manifest))])])
    total = 0
    for category in categories:
        members = [icon for icon in icons if icon['category'] == category]
        name = class_name(category)
        rows = []
        for icon in members:
            tags = ' '.join(st_string(tag) for tag in icon['tags'])
            rows.append(f'\t\t#( {st_string(icon["name"])} 16r{icon["codepoint"]:X} #( {tags} ) )')
        methods = [
            (True, 'materialCategory', 'accessing', ['', f'\t^ {st_string(category)}']),
            (True, 'iconTable', 'accessing',
             ['\t"Name, codepoint and tags of each icon of my category"', '', '\t^ #(', *rows, '\t)'])]
        for icon in members:
            pngs = [rasterizer.png(sources[icon['name']], size) for size in SIZES]
            methods.append((True, 'icon_' + icon['name'], 'icons', [png_array(pngs)]))
            total += 1
        files[f'{pkg}/{name}.class.st'] = tonel_class(
            name, ROOT_CLASS, PACKAGE,
            f'I hold the {len(members)} icons of the Material category {category} of Material Icons Rounded '
            f'(see {ROOT_CLASS}).\n\nGenerated by scripts/generate.py: do not edit, regenerate.',
            methods)
        print(f'{category}: {len(members)}', file=sys.stderr)
    files.update(generate_art(manifest, sources, rasterizer))
    return files


def read_mapping():
    rows = []
    with open(MAPPING, encoding='utf-8') as stream:
        for line in stream:
            if line.strip() and not line.startswith('#'):
                key, material, side, colour = line.rstrip('\n').split('\t')
                rows.append((key, material, int(side), None if colour == '-' else colour))
    return rows


def icon_license(manifest):
    """The text of LICENSE-material-icons, checked against the SHA-256 of the upstream LICENSE in the pin."""
    with open(ICON_LICENSE, 'rb') as stream:
        data = stream.read()
    expected = manifest['upstream']['license']['sha256']
    if sha256(data) != expected:
        raise RuntimeError(f'{ICON_LICENSE}: SHA-256 {sha256(data)}, expected {expected} (the pinned upstream LICENSE)')
    return data.decode('utf-8')


def notice_text(manifest, rasterizer):
    upstream = manifest['upstream']
    return '\n'.join([
        'This icon pack includes Material Icons by Google:',
        '',
        '  Material Icons Rounded (the family "Material Icons Round")',
        f'  https://github.com/{upstream["repository"]}',
        f'  commit {upstream["commit"]},',
        f'  {upstream["path"]}',
        '  Licensed under the Apache License, Version 2.0 (see LICENSE-material-icons).',
        '',
        'Its PNG files of the Material icons are modified forms of those SVG files:',
        f'rasterized by material-icons.st (scripts/generate.py, {rasterizer.description}),',
        'then painted in one colour in Pharo by MaterialThemeIcons.',
        'The other PNG files are those of the icon pack it was built over',
        '(by default svgPack, https://github.com/pharo-project/pharo-icon-packs),',
        'under the licence of that pack.',
        ''])


def generate_art(manifest, sources, rasterizer):
    names = {icon['name'] for icon in manifest['icons']}
    rows = read_mapping()
    entries, methods, drawn = [], [], set()
    for key, material, side, colour in rows:
        if material not in names:
            raise ValueError(f'{key}: no Material icon {material}')
        colour_literal = 'nil' if colour is None else st_string(colour)
        entries.append(f'\t\t#( {st_symbol(key)} {st_string(material)} {side} {colour_literal} )')
        if side != 16 and (material, side) not in drawn:
            drawn.add((material, side))
            sizes = [int(side * float(scale) + 0.5) for scale in SCALES]
            pngs = [rasterizer.png(sources[material], size) for size in sizes]
            methods.append((True, f'art_{material}_{side}', 'icons', [png_array(pngs)]))
    methods.append((True, 'entries', 'accessing', [
        '\t"Pharo icon key, Material name, side in pixels at scale 1, colour (RRGGBB, or nil for the',
        '\tcolour of the UI theme). The keys of side 16 use the Material icons themselves; the others',
        '\thave their own pixels, art_<name>_<side>, at that side times 1, 1.5 and 2 (rounded)"',
        '', '\t^ #(', *entries, '\t)']))
    source = source_of(manifest)
    methods.append((True, 'noticeText', 'licence', [
        '\t"The attribution that MaterialThemeIcons class >> exportPack:to: puts in the zip, as NOTICE"',
        '', '\t^ ' + st_string(notice_text(manifest, rasterizer))]))
    text = tonel_class(
        ART_CLASS, 'Object', THEME_PACKAGE,
        f'I hold the mapping of {len(rows)} Pharo icon keys to Material Icons Rounded for MaterialThemeIcons '
        '(scripts/pharo-mapping.tsv), and the pixels of the keys that svgPack, the default pack, does not draw '
        'at 16 pixels, rendered at their own size so that the rows and menus keep their layout. '
        '`noticeText` goes into the zip that MaterialThemeIcons exports, with the licence '
        f'(`{ROOT_CLASS} licenseText`).\n\n'
        f'Source: {source}, Apache License 2.0 (Google). Rasterized by {rasterizer.description}.\n\n'
        'Generated by scripts/generate.py: do not edit, regenerate.',
        methods)
    return {f'src/{THEME_PACKAGE}/{ART_CLASS}.class.st': text}


# ---------------------------------------------------------------- main

def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('command', nargs='?', default='generate', choices=('generate', 'pin'))
    parser.add_argument('--cache', default=os.path.join(ROOT, 'build', 'cache'))
    parser.add_argument('--check', action='store_true', help='compare with src/ instead of writing')
    options = parser.parse_args()
    if options.command == 'pin':
        return pin(options.cache)
    with open(MANIFEST, encoding='utf-8') as stream:
        manifest = json.load(stream)
    rasterizer = Rasterizer()
    sources = fetch_sources(manifest, options.cache)
    files = generate(manifest, sources, rasterizer)
    stale = []
    generated_dir = os.path.join(ROOT, 'src', PACKAGE)
    if os.path.isdir(generated_dir):
        expected = {os.path.join(ROOT, path) for path in files}
        stale = [os.path.join(generated_dir, f) for f in os.listdir(generated_dir)
                 if os.path.join(generated_dir, f) not in expected]
    if options.check:
        different = []
        for path, text in sorted(files.items()):
            full = os.path.join(ROOT, path)
            if not os.path.exists(full) or open(full, encoding='utf-8').read() != text:
                different.append(path)
        different += [os.path.relpath(path, ROOT) for path in stale]
        for path in different:
            print(f'differs: {path}')
        print('up to date' if not different else f'{len(different)} files differ')
        return 1 if different else 0
    for path in stale:
        os.remove(path)
    for path, text in sorted(files.items()):
        full = os.path.join(ROOT, path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full + '.part', 'w', encoding='utf-8', newline='\n') as stream:
            stream.write(text)
        os.replace(full + '.part', full)
    print(f'{len(files)} files written, {len(manifest["icons"])} icons ({rasterizer.description})')
    return 0


if __name__ == '__main__':
    sys.exit(main())
