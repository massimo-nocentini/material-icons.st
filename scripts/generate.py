#!/usr/bin/env python3
"""Generate the icon data of material-icons.st from the pinned Material Icons Rounded and
Material Symbols Rounded sources.

    python3 -I scripts/generate.py [--cache DIR] [--jobs N]          fetch, rasterize, write the Tonel files
    python3 -I scripts/generate.py --check [--cache DIR] [--jobs N]  the same, but only compare with src/
    python3 -I scripts/generate.py pin [rounded|symbols] [--cache DIR] rebuild the pins (network, live metadata)

Two icon sets, each pinned by a manifest (the upstream commit, and the name, category,
codepoint, tags and SHA-256 of every source file of every icon):

    Material Icons Rounded     scripts/manifest.json           google/material-design-icons at 3912bae
        small sizes            src/<category>/<name>/materialiconsround/24px.svg, rasterized at 16, 24, 32 px
        master, 192 px         android/<category>/<name>/materialiconsround/black/res/drawable-xxxhdpi/
                               round_<name>_black_48.png: Google's own PNG, the largest raster upstream,
                               shipped byte for byte
    Material Symbols Rounded   scripts/manifest-symbols.json   google/material-design-icons at 10ecc14
        small sizes            symbols/web/<name>/materialsymbolsrounded/<name>_24px.svg (optical size 24),
                               rasterized at 16, 24, 32 px
        master, 192 px         <name>_48px.svg (optical size 48, the largest), rasterized at 192 px
        Filled                 the same from <name>_fill1_24px.svg and <name>_fill1_48px.svg
        not at the commit      the few symbols that fonts.google.com lists but the repository does not
                               have yet: the same six SVGs from fonts.gstatic.com (unversioned), each
                               pinned by its SHA-256, so a change upstream stops the generator

The files are downloaded from raw.githubusercontent.com at the pinned commit into the cache
(build/cache by default; the layout is mir-svg/<commit>/<name>.svg,
mir-android-xxxhdpi-192/<commit>/<name>.png, msr-svg/<commit>/<name>/<name>_<variant>.svg and
msr-gstatic/<name>/<name>_<variant>.svg), and each is checked against its SHA-256 in the manifest.
The generator writes:

    src/MaterialIcons-Rounded/                  one class per category, icon_<name>: 16, 24, 32 px
    src/MaterialIcons-Rounded-192/              master_<name>, extensions of those classes
    src/MaterialSymbols-Rounded/                one class per category, icon_<name>: 16, 24, 32 px
    src/MaterialSymbols-Rounded-192/            master_<name>
    src/MaterialSymbols-Rounded-Filled/         FILL 1: icon_<name>
    src/MaterialSymbols-Rounded-Filled-192/     FILL 1: master_<name>
    src/MaterialIcons-ThemePack/MaterialThemeIconsArt.class.st
                                                the Pharo keys of scripts/pharo-mapping.tsv
    src/MaterialSymbols-ThemePack/MaterialSymbolsThemeIconsArt.class.st
                                                the Pharo keys of scripts/symbols-mapping.tsv, drawn
                                                at the sizes of scripts/pharo-icon-keys.tsv

The PNGs that the generator rasterizes hold only the shape: 8-bit grey (always 0) and alpha,
so the image can paint them in any colour. It writes them itself (Python's zlib), so rerunning
on the same inputs (same CairoSVG, cairo and zlib) writes the same bytes. CairoSVG and its
Python dependencies are pinned in scripts/requirements.txt; it needs libcairo (the generated
data was made with cairo 1.18.6). The rasterizing runs in --jobs processes; each icon's bytes
do not depend on the others.

`pin` downloads the live Google Fonts metadata (the one of fonts.google.com/icons), keeps the
icons that the family supports, downloads their files at the pinned commit and writes their
SHA-256: run it only to move a pin.
"""

import argparse
import base64
import concurrent.futures
import datetime
import hashlib
import json
import os
import re
import struct
import sys
import time
import urllib.error
import urllib.request
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
MANIFEST = os.path.join(HERE, 'manifest.json')
SYMBOLS_MANIFEST = os.path.join(HERE, 'manifest-symbols.json')
MAPPING = os.path.join(HERE, 'pharo-mapping.tsv')
SYMBOLS_MAPPING = os.path.join(HERE, 'symbols-mapping.tsv')
PHARO_KEYS = os.path.join(HERE, 'pharo-icon-keys.tsv')
ICON_LICENSE = os.path.join(ROOT, 'LICENSE-material-icons')

REPOSITORY = 'google/material-design-icons'
RAW_URL = 'https://raw.githubusercontent.com/{repository}/{commit}/{path}'
METADATA_URL = 'https://fonts.google.com/metadata/icons?key=material_symbols&incomplete=true'
CAIRO_VERSION = '1.18.6'
SIZES = (16, 24, 32)
SCALES = ('1', '1.5', '2')
MASTER_SIZE = 192
USER_AGENT = 'material-icons.st-generator'

# Material Icons Rounded
COMMIT = '3912baecc97388955ce39f5e26bfb786a70cbe48'
SVG_PATH = 'src/{category}/{name}/materialiconsround/24px.svg'
MASTER_PATH = 'android/{category}/{name}/materialiconsround/black/res/drawable-xxxhdpi/round_{name}_black_48.png'
FAMILY = 'Material Icons Round'
PACKAGE = 'MaterialIcons-Rounded'
MASTER_PACKAGE = 'MaterialIcons-Rounded-192'
THEME_PACKAGE = 'MaterialIcons-ThemePack'
ROOT_CLASS = 'MaterialIconsRoundedCategory'
ART_CLASS = 'MaterialThemeIconsArt'
CATEGORY_CLASS_NAMES = {'av': 'AV'}

# Material Symbols Rounded
SYMBOLS_COMMIT = '10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7'
SYMBOLS_PATH = 'symbols/web/{name}/materialsymbolsrounded/{name}_{variant}.svg'
SYMBOLS_FAMILY = 'Material Symbols Rounded'
SYMBOLS_VARIANTS = ('24px', '48px', 'fill1_24px', 'fill1_48px', 'grad200_24px', 'grad200fill1_24px')
# The symbols that the metadata lists but the repository lacks at the pinned commit: fonts.gstatic.com serves
# them, but only unversioned (short-term/release), so each file is pinned by its SHA-256 in the manifest
GSTATIC_URL = 'https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsrounded/{name}/{style}/{size}.svg'
SYMBOLS_THEME_PACKAGE = 'MaterialSymbols-ThemePack'
SYMBOLS_ART_CLASS = 'MaterialSymbolsThemeIconsArt'
# (fill, grade) of the theme pack -> the variant (optical size 24) its keys are drawn from
ART_VARIANTS = {(0, 0): '24px', (1, 0): 'fill1_24px', (0, 200): 'grad200_24px', (1, 200): 'grad200fill1_24px'}


class SymbolsSet:
    """One pair of packages of Material Symbols Rounded: FILL 0 or FILL 1."""

    def __init__(self, filled):
        self.filled = filled
        suffix = 'Filled' if filled else ''
        self.package = 'MaterialSymbols-Rounded' + ('-Filled' if filled else '')
        self.master_package = self.package + '-192'
        self.prefix = 'MaterialSymbolsRounded' + suffix
        self.root = self.prefix + 'Category'
        self.style = 'symbolsRounded' + suffix
        self.small_variant = 'fill1_24px' if filled else '24px'
        self.master_variant = 'fill1_48px' if filled else '48px'
        self.axes = f'FILL {1 if filled else 0}, wght 400, GRAD 0'


SYMBOLS_SETS = (SymbolsSet(False), SymbolsSet(True))


# ---------------------------------------------------------------- downloads

class NotFound(Exception):
    pass


def fetch(url, missing_ok=False):
    """The bytes at url. Errors are retried, waiting longer each time (raw.githubusercontent.com
    answers 429, Too Many Requests, to many quick downloads); a 404 raises NotFound if missing_ok."""
    last = None
    for attempt in range(8):
        try:
            request = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            if error.code == 404 and missing_ok:
                raise NotFound(url)
            last = error
        except Exception as error:  # retried, then reported
            last = error
        time.sleep(min(60, 2 ** attempt))
    raise RuntimeError(f'cannot download {url}: {last}')


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def raw_url(commit, path):
    return RAW_URL.format(repository=REPOSITORY, commit=commit, path=path)


def store(cache, relative, data):
    path = os.path.join(cache, relative)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + '.part', 'wb') as stream:
        stream.write(data)
    os.replace(path + '.part', path)


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
    store(cache, relative, data)
    return data


def rounded_files(manifest):
    """(key, cache path, url, sha256) of every source file of Material Icons Rounded."""
    upstream = manifest['upstream']
    commit = upstream['commit']
    for icon in manifest['icons']:
        name, category = icon['name'], icon['category']
        yield ((name, 'svg'), f'mir-svg/{commit}/{name}.svg',
               raw_url(commit, upstream['path'].format(category=category, name=name)), icon['sha256'])
        yield ((name, 'png192'), f'mir-android-xxxhdpi-192/{commit}/{name}.png',
               raw_url(commit, upstream['master_path'].format(category=category, name=name)), icon['sha256_192'])


def symbols_relative(commit, name, variant):
    return f'msr-svg/{commit}/{name}/{name}_{variant}.svg'


def gstatic_relative(name, variant):
    return f'msr-gstatic/{name}/{name}_{variant}.svg'


def gstatic_style(variant):
    """(style, size) of a variant of the repository on fonts.gstatic.com: fill1_24px is fill1/24px, 24px default/24px"""
    style, _, size = variant.rpartition('_')
    return style or 'default', size


def gstatic_url(name, variant):
    style, size = gstatic_style(variant)
    return GSTATIC_URL.format(name=name, style=style, size=size)


def symbols_files(manifest):
    """(key, cache path, url, sha256) of every source file of Material Symbols Rounded."""
    upstream = manifest['upstream']
    commit = upstream['commit']
    for icon in manifest['icons']:
        name = icon['name']
        for variant in upstream['variants']:
            if icon.get('source') == 'gstatic':
                yield ((name, variant), gstatic_relative(name, variant), gstatic_url(name, variant),
                       icon['sha256'][variant])
            else:
                yield ((name, variant), symbols_relative(commit, name, variant),
                       raw_url(commit, upstream['path'].format(name=name, variant=variant)), icon['sha256'][variant])


def fetch_all(files, cache):
    """key -> bytes, every file checked against its SHA-256."""
    files = list(files)
    with concurrent.futures.ThreadPoolExecutor(32) as pool:
        datas = pool.map(lambda f: cached(cache, f[1], f[2], f[3]), files)
        return {f[0]: data for f, data in zip(files, datas)}


# ---------------------------------------------------------------- pin

def live_metadata():
    text = fetch(METADATA_URL).decode('utf-8')
    if text.startswith(")]}'"):
        text = text.split('\n', 1)[1]
    return json.loads(text)


def family_entries(metadata, family):
    entries = [each for each in metadata['icons'] if family not in each.get('unsupported_families', [])]
    names = [each['name'] for each in entries]
    if len(names) != len(set(names)):
        raise RuntimeError(f'duplicate icon names in the metadata of {family}')
    for each in entries:
        if len(each['categories']) != 1:
            raise RuntimeError(f'{each["name"]}: categories {each["categories"]}')
        if not re.fullmatch(r'[a-z0-9_]+', each['name']):
            raise RuntimeError(f'{each["name"]}: not a Material name')
    return sorted(entries, key=lambda e: e['name'])


def subset_sha256(entries):
    """The SHA-256 of what a pin takes from the metadata: the icons of the family, sorted by name,
    with their name, categories, codepoint, version and tags, as compact JSON of sorted keys.
    The raw response cannot be hashed: its popularity counters change from one fetch to the next."""
    keys = ('name', 'categories', 'codepoint', 'version', 'tags')
    subset = [{key: each[key] for key in keys} for each in sorted(entries, key=lambda e: e['name'])]
    return sha256(json.dumps(subset, sort_keys=True, separators=(',', ':')).encode('utf-8'))


def license_pin(commit):
    return {'path': 'LICENSE', 'sha256': sha256(fetch(raw_url(commit, 'LICENSE')))}


def download_and_hash(cache, relative, url, missing_ok=False):
    """The SHA-256 of the file at url, downloaded into cache/relative. The files at a commit do not
    change, so a file that a previous pin already put there (the path names the commit) is reused:
    an interrupted pin goes on where it stopped"""
    path = os.path.join(cache, relative)
    if os.path.exists(path):
        with open(path, 'rb') as stream:
            return sha256(stream.read())
    data = fetch(url, missing_ok=missing_ok)
    store(cache, relative, data)
    return sha256(data)


def pin_rounded(cache, metadata):
    entries = family_entries(metadata, FAMILY)
    upstream = {'repository': REPOSITORY, 'commit': COMMIT, 'path': SVG_PATH, 'master_path': MASTER_PATH,
                'license': license_pin(COMMIT)}
    manifest = {'upstream': upstream, 'icons': []}
    for each in entries:
        manifest['icons'].append({
            'name': each['name'], 'category': each['categories'][0], 'codepoint': each['codepoint'],
            'version': each['version'], 'tags': each['tags'], 'sha256': None, 'sha256_192': None})

    def hashes_of(icon):
        name, category = icon['name'], icon['category']
        return (download_and_hash(cache, f'mir-svg/{COMMIT}/{name}.svg',
                                  raw_url(COMMIT, SVG_PATH.format(category=category, name=name))),
                download_and_hash(cache, f'mir-android-xxxhdpi-192/{COMMIT}/{name}.png',
                                  raw_url(COMMIT, MASTER_PATH.format(category=category, name=name))))

    with concurrent.futures.ThreadPoolExecutor(32) as pool:
        for icon, (svg, png) in zip(manifest['icons'], pool.map(hashes_of, manifest['icons'])):
            icon['sha256'], icon['sha256_192'] = svg, png
    manifest['metadata'] = {
        'url': METADATA_URL, 'family': FAMILY, 'round_subset_sha256': subset_sha256(entries),
        'retrieved': datetime.date.today().isoformat(), 'icons': len(manifest['icons'])}
    write_manifest(manifest, MANIFEST)
    print(f'Material Icons Rounded: {len(manifest["icons"])} icons pinned at {COMMIT}')


def pin_symbols(cache, metadata):
    entries = family_entries(metadata, SYMBOLS_FAMILY)
    upstream = {'repository': REPOSITORY, 'commit': SYMBOLS_COMMIT, 'path': SYMBOLS_PATH,
                'variants': list(SYMBOLS_VARIANTS), 'license': license_pin(SYMBOLS_COMMIT)}

    def hashes_of(entry):
        name, hashes = entry['name'], {}
        for variant in SYMBOLS_VARIANTS:
            try:
                hashes[variant] = download_and_hash(
                    cache, symbols_relative(SYMBOLS_COMMIT, name, variant),
                    raw_url(SYMBOLS_COMMIT, SYMBOLS_PATH.format(name=name, variant=variant)), missing_ok=True)
            except NotFound:
                hashes[variant] = None
        if len(set(v is None for v in hashes.values())) > 1:
            raise RuntimeError(f'{name}: some variants are missing at {SYMBOLS_COMMIT}: {hashes}')
        return None if hashes[SYMBOLS_VARIANTS[0]] is None else hashes

    def gstatic_hashes_of(name):
        """The SHA-256 of each variant on fonts.gstatic.com, always downloaded again (the URLs are
        unversioned), or None if one is not there"""
        hashes = {}
        for variant in SYMBOLS_VARIANTS:
            try:
                data = fetch(gstatic_url(name, variant), missing_ok=True)
            except NotFound:
                return None
            if not data.lstrip().startswith(b'<svg'):
                raise RuntimeError(f'{gstatic_url(name, variant)}: not an SVG')
            store(cache, gstatic_relative(name, variant), data)
            hashes[variant] = sha256(data)
        return hashes

    icons, missing, left_out = [], [], []
    with concurrent.futures.ThreadPoolExecutor(16) as pool:
        for each, hashes in zip(entries, pool.map(hashes_of, entries)):
            source = None
            if hashes is None:
                missing.append(each['name'])
                hashes, source = gstatic_hashes_of(each['name']), 'gstatic'
                if hashes is None:
                    left_out.append(each['name'])
                    continue
            if any(',' in tag for tag in each['tags']):
                raise RuntimeError(f'{each["name"]}: a tag with a comma, {each["tags"]}')
            icon = {'name': each['name'], 'category': each['categories'][0], 'codepoint': each['codepoint'],
                    'version': each['version'], 'tags': each['tags'], 'sha256': hashes}
            if source:
                icon['source'] = source
            icons.append(icon)
    upstream['fallback'] = {
        'url': GSTATIC_URL, 'for': 'the icons of missing_at_commit',
        'styles': {variant: '/'.join(gstatic_style(variant)) for variant in SYMBOLS_VARIANTS}}
    manifest = {'upstream': upstream, 'icons': icons, 'metadata': {
        'url': METADATA_URL, 'family': SYMBOLS_FAMILY,
        'subset_sha256': subset_sha256([each for each in entries if each['name'] not in left_out]),
        'retrieved': datetime.date.today().isoformat(), 'listed': len(entries), 'icons': len(icons),
        'missing_at_commit': missing, 'left_out': left_out}}
    write_manifest(manifest, SYMBOLS_MANIFEST)
    print(f'Material Symbols Rounded: {len(icons)} icons pinned, {len(icons) - len(missing) + len(left_out)} at '
          f'{SYMBOLS_COMMIT}, {len(missing) - len(left_out)} from fonts.gstatic.com '
          f'({" ".join(n for n in missing if n not in left_out)}), {len(left_out)} left out: {" ".join(left_out)}')


def pin(cache, which):
    metadata = live_metadata()
    if which in ('all', 'rounded'):
        pin_rounded(cache, metadata)
    if which in ('all', 'symbols'):
        pin_symbols(cache, metadata)


def write_manifest(manifest, path):
    lines = ['{']
    for key in ('upstream', 'metadata'):
        lines.append(f' {json.dumps(key)}: {json.dumps(manifest[key], sort_keys=True)},')
    lines.append(' "icons": [')
    icons = [f'  {json.dumps(icon, sort_keys=True)}' for icon in manifest['icons']]
    lines.append(',\n'.join(icons))
    lines.append(' ]')
    lines.append('}')
    with open(path, 'w', encoding='utf-8') as stream:
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


def png_header(data):
    """width, height, bit depth, colour type, compression, filter, interlace"""
    for kind, body in png_chunks(data):
        if kind == b'IHDR':
            return struct.unpack('>IIBBBBB', body)
    raise ValueError('no IHDR')


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


def load_cairosvg():
    try:
        import cairocffi
        import cairosvg
    except (ImportError, OSError) as error:
        raise SystemExit(
            f'CairoSVG is not usable ({error}): pip install -r scripts/requirements.txt, '
            'and make libcairo.so.2 loadable (LD_LIBRARY_PATH)')
    return cairosvg, cairocffi.cairo_version_string()


def render(svg, width, height, whole=False):
    """A grey+alpha PNG of width x height with svg drawn as a square of the shorter side, centred;
    whole: svg drawn over all of width x height (its viewBox has that aspect, see trimmed_svg)."""
    cairosvg, _ = load_cairosvg()
    if whole:
        rendered = cairosvg.svg2png(bytestring=svg, output_width=width, output_height=height)
        w, h, alphas = alpha_of_png(rendered)
        if (w, h) != (width, height):
            raise ValueError(f'rendered {w}x{h}, expected {width}x{height}')
        return la_png(width, height, alphas)
    side = min(width, height)
    rendered = cairosvg.svg2png(bytestring=svg, output_width=side, output_height=side)
    w, h, alphas = alpha_of_png(rendered)
    if (w, h) != (side, side):
        raise ValueError(f'rendered {w}x{h}, expected {side}')
    if (width, height) != (side, side):
        left, top = (width - side) // 2, (height - side) // 2
        canvas = [bytes(width)] * height
        for y, row in enumerate(alphas):
            canvas[top + y] = bytes(left) + row + bytes(width - side - left)
        alphas = canvas
    return la_png(width, height, alphas)


def render_job(job):
    svg, width, height, whole = job
    return render(svg, width, height, whole)


class Rasterizer:
    """Renders (svg, width, height, whole) jobs, each one once, in a pool of processes."""

    def __init__(self, jobs):
        cairosvg, self.cairo = load_cairosvg()
        self.description = f'CairoSVG {cairosvg.__version__} on cairo {self.cairo}'
        if self.cairo != CAIRO_VERSION:
            print(f'warning: cairo {self.cairo}, the data was generated with cairo {CAIRO_VERSION}: '
                  'the pixels may differ', file=sys.stderr)
        self.jobs = jobs
        self.wanted = {}
        self.done = {}

    def want(self, svg, width, height=None, whole=False):
        height = width if height is None else height
        key = (sha256(svg), width, height, whole)
        if key not in self.done:
            self.wanted[key] = (svg, width, height, whole)

    def run(self):
        keys = sorted(self.wanted)
        if keys:
            with concurrent.futures.ProcessPoolExecutor(self.jobs) as pool:
                for key, png in zip(keys, pool.map(render_job, [self.wanted[k] for k in keys], chunksize=16)):
                    self.done[key] = png
        self.wanted = {}

    def png(self, svg, width, height=None, whole=False):
        height = width if height is None else height
        return self.done[sha256(svg), width, height, whole]


# ---------------------------------------------------------------- Tonel

def st_string(text):
    return "'" + text.replace("'", "''") + "'"


def st_symbol(text):
    simple = text[:1].isalpha() and all(c.isalnum() or c == '_' for c in text)
    return '#' + text if simple else '#' + st_string(text)


def class_name(category):
    return 'MaterialIconsRounded' + CATEGORY_CLASS_NAMES.get(category, category.capitalize())


def symbols_class_name(prefix, category):
    """'UI actions' -> UIActions, 'Audio&Video' -> AudioVideo"""
    return prefix + ''.join(word[:1].upper() + word[1:] for word in re.split(r'[^A-Za-z0-9]+', category) if word)


def tonel_class(name, superclass, package, comment, methods):
    """methods: (class side?, selector, category, source lines after the selector line)"""
    out = ['"', comment.replace('"', '""'), '"', 'Class {',
           f"\t#name : '{name}',", f"\t#superclass : '{superclass}',",
           f"\t#category : '{package}',", f"\t#package : '{package}'", '}']
    for meta, selector, category, body in sorted(methods, key=lambda m: (not m[0], m[1])):
        out += ['', f"{{ #category : '{category}' }}",
                f'{name}{" class" if meta else ""} >> {selector} [', *body, ']']
    return '\n'.join(out) + '\n'


def tonel_extension(name, package, methods):
    """Class-side extension methods of the class name in package: (selector, source lines after the selector line)"""
    out = [f"Extension {{ #name : '{name}' }}"]
    for selector, body in sorted(methods):
        out += ['', f"{{ #category : '*{package}' }}", f'{name} class >> {selector} [', *body, ']']
    return '\n'.join(out) + '\n'


def b64(data):
    return st_string(base64.b64encode(data).decode('ascii'))


def png_array(pngs):
    return '\t^ #( ' + ' '.join(b64(p) for p in pngs) + ' )'


def package_file(package):
    return f"Package {{ #name : '{package}' }}\n"


def source_of(manifest):
    upstream = manifest['upstream']
    return f'https://github.com/{upstream["repository"]} at commit {upstream["commit"]}, {upstream["path"]}'


def master_source_of(manifest):
    upstream = manifest['upstream']
    return f'https://github.com/{upstream["repository"]} at commit {upstream["commit"]}, {upstream["master_path"]}'


def icon_license(manifest):
    """The text of LICENSE-material-icons, checked against the SHA-256 of the upstream LICENSE in the pin."""
    with open(ICON_LICENSE, 'rb') as stream:
        data = stream.read()
    expected = manifest['upstream']['license']['sha256']
    if sha256(data) != expected:
        raise RuntimeError(f'{ICON_LICENSE}: SHA-256 {sha256(data)}, expected {expected} (the pinned upstream LICENSE)')
    return data.decode('utf-8')


# ---------------------------------------------------------------- Material Icons Rounded

def want_rounded(manifest, sources, rasterizer):
    for icon in manifest['icons']:
        for size in SIZES:
            rasterizer.want(sources[icon['name'], 'svg'], size)


def check_master_png(name, data):
    width, height, depth, colour, _, _, interlace = png_header(data)
    if (width, height) != (MASTER_SIZE, MASTER_SIZE) or interlace:
        raise ValueError(f'{name}: the master PNG is {width}x{height}, interlace {interlace}')


def generate_rounded(manifest, sources, rasterizer):
    """path relative to ROOT -> text of the files of Material Icons Rounded and of its masters."""
    files = {}
    pkg = f'src/{PACKAGE}'
    icons = manifest['icons']
    categories = sorted({icon['category'] for icon in icons})
    upstream = manifest['upstream']
    files[f'{pkg}/package.st'] = package_file(PACKAGE)
    source = source_of(manifest)
    counts = ' '.join(f'#( {st_string(c)} {sum(1 for i in icons if i["category"] == c)} )' for c in categories)
    files[f'{pkg}/{ROOT_CLASS}.class.st'] = tonel_class(
        ROOT_CLASS, 'MaterialIconsCategory', PACKAGE,
        'I am the root of the categories of Material Icons Rounded, the icons of the family Material Icons Round '
        '(fonts.google.com/icons, icon.set=Material+Icons, icon.style=Rounded). Each subclass holds the icons '
        'of one Material category: one class-side method per icon, `icon_<name>`, answering its PNGs at 16, 24 '
        'and 32 pixels (scales 1, 1.5 and 2) in Base64, and `iconTable`, the name, codepoint and tags of each. '
        f'The package {MASTER_PACKAGE} adds `master_<name>`, the icon at {MASTER_SIZE} pixels.\n\n'
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
    masters_pkg = f'src/{MASTER_PACKAGE}'
    files[f'{masters_pkg}/package.st'] = package_file(MASTER_PACKAGE)
    files[f'{masters_pkg}/{ROOT_CLASS}.extension.st'] = tonel_extension(ROOT_CLASS, MASTER_PACKAGE, [
        ('masterSize', ['\t"The side in pixels of the PNGs of master_<name>"', '', f'\t^ {MASTER_SIZE}']),
        ('masterDescription', [
            '\t"Where the PNGs of master_<name> come from: Google\'s own PNG of each icon at 48 dp, xxxhdpi,',
            '\tthe largest raster of the upstream repository, byte for byte (8-bit, black, of various colour types)"',
            '', f'\t^ {st_string(master_source_of(manifest))}'])])
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
        masters = []
        for icon in members:
            svg = sources[icon['name'], 'svg']
            pngs = [rasterizer.png(svg, size) for size in SIZES]
            methods.append((True, 'icon_' + icon['name'], 'icons', [png_array(pngs)]))
            master = sources[icon['name'], 'png192']
            check_master_png(icon['name'], master)
            masters.append(('master_' + icon['name'], ['\t^ ' + b64(master)]))
        files[f'{pkg}/{name}.class.st'] = tonel_class(
            name, ROOT_CLASS, PACKAGE,
            f'I hold the {len(members)} icons of the Material category {category} of Material Icons Rounded '
            f'(see {ROOT_CLASS}).\n\nGenerated by scripts/generate.py: do not edit, regenerate.',
            methods)
        files[f'{masters_pkg}/{name}.extension.st'] = tonel_extension(name, MASTER_PACKAGE, masters)
    return files


def read_mapping():
    rows = []
    with open(MAPPING, encoding='utf-8') as stream:
        for line in stream:
            if line.strip() and not line.startswith('#'):
                key, material, side, colour = line.rstrip('\n').split('\t')
                rows.append((key, material, int(side), None if colour == '-' else colour))
    return rows


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


def art_sizes(side):
    return [int(side * float(scale) + 0.5) for scale in SCALES]


def want_art(manifest, sources, rasterizer):
    for key, material, side, colour in read_mapping():
        if side != 16 and (material, 'svg') in sources:
            for size in art_sizes(side):
                rasterizer.want(sources[material, 'svg'], size)


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
            pngs = [rasterizer.png(sources[material, 'svg'], size) for size in art_sizes(side)]
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


# ---------------------------------------------------------------- Material Symbols Rounded

def symbols_source(manifest, variant):
    upstream = manifest['upstream']
    path = upstream['path'].replace('{variant}', variant)
    return f'https://github.com/{upstream["repository"]} at commit {upstream["commit"]}, {path}'


def want_symbols(manifest, sources, rasterizer):
    for icon in manifest['icons']:
        for each in SYMBOLS_SETS:
            for size in SIZES:
                rasterizer.want(sources[icon['name'], each.small_variant], size)
            rasterizer.want(sources[icon['name'], each.master_variant], MASTER_SIZE)


def generate_symbols(manifest, sources, rasterizer):
    """path relative to ROOT -> text of the files of Material Symbols Rounded, FILL 0 and FILL 1."""
    files = {}
    icons = manifest['icons']
    upstream = manifest['upstream']
    metadata = manifest['metadata']
    categories = sorted({icon['category'] for icon in icons})
    counts = ' '.join(f'#( {st_string(c)} {sum(1 for i in icons if i["category"] == c)} )' for c in categories)
    missing = ' '.join(st_string(name) for name in metadata.get('left_out', []))
    fallback_names = [icon['name'] for icon in icons if icon.get('source') == 'gstatic']
    fallback = ' '.join(st_string(name) for name in fallback_names)
    fallback_url = upstream.get('fallback', {}).get('url', '')
    base, filled = SYMBOLS_SETS
    for each in SYMBOLS_SETS:
        pkg, masters_pkg = f'src/{each.package}', f'src/{each.master_package}'
        files[f'{pkg}/package.st'] = package_file(each.package)
        files[f'{masters_pkg}/package.st'] = package_file(each.master_package)
        small_source = symbols_source(manifest, each.small_variant)
        master_source = symbols_source(manifest, each.master_variant)
        common = (
            f'Source: {small_source} (optical size 24, {each.axes}), Apache License 2.0 (Google), whose text is '
            f'`licenseText`. Rasterized by {rasterizer.description}.\n\n'
            'Generated by scripts/generate.py: do not edit, regenerate.')
        root_methods = [
            (True, 'materialStyle', 'accessing', ['', f'\t^ #{each.style}']),
            (True, 'upstreamDescription', 'accessing', ['', f'\t^ {st_string(small_source)}']),
            (True, 'variantDescription', 'accessing',
             ['\t"The axes of the variable font my icons are drawn at"', '', f"\t^ '{each.axes}, opsz 24'"])]
        if not each.filled:
            root_methods += [
                (True, 'iconCount', 'accessing',
                 ['\t"The number of icons of the style, over all its categories"', '', f'\t^ {len(icons)}']),
                (True, 'categoryCounts', 'accessing',
                 ['\t"The number of icons of each category"', '', f'\t^ #( {counts} )']),
                (True, 'missingIcons', 'accessing', [
                    '\t"The icons that fonts.google.com lists for Material Symbols Rounded but that are not here:',
                    '\tneither the upstream repository at the pinned commit nor fonts.gstatic.com has them"',
                    '', f'\t^ #( {missing} )' if missing else '\t^ #( )']),
                (True, 'fallbackIcons', 'accessing', [
                    '\t"The icons that the upstream repository does not have yet at the pinned commit: their SVGs',
                    '\tcome from fonts.gstatic.com instead (fallbackDescription), each pinned by its SHA-256"',
                    '', f'\t^ #( {fallback} )']),
                (True, 'fallbackDescription', 'accessing', [
                    '\t"Where the SVGs of fallbackIcons come from (unversioned URLs, pinned by SHA-256)"',
                    '', f'\t^ {st_string(fallback_url)}']),
                (True, 'upstreamCommit', 'accessing', ['', f"\t^ '{upstream['commit']}'"]),
                (True, 'licenseText', 'licence', [
                    '\t"The Apache License 2.0 of Material Symbols (LICENSE-material-icons, the LICENSE of the upstream',
                    '\trepository at the pinned commit), in the image with the icons it covers.',
                    '\tMaterialSymbolsThemeIcons class >> exportPack:to: puts it in the zip"',
                    '', '\t^ ' + st_string(icon_license(manifest))])]
            comment = (
                f'I am the root of the categories of Material Symbols Rounded, the icons of the family {SYMBOLS_FAMILY} '
                '(fonts.google.com/icons, icon.set=Material+Symbols, icon.style=Rounded), in their default variant '
                f'({each.axes}). Each subclass holds the icons of one category: one class-side method per icon, '
                '`icon_<name>`, answering its PNGs at 16, 24 and 32 pixels (scales 1, 1.5 and 2) in Base64, drawn '
                'from the optical size 24, and `iconTable`, the name, codepoint and tags (one String, '
                'comma-separated) of each. '
                f'The package {each.master_package} adds `master_<name>`, the icon at {MASTER_SIZE} pixels drawn from '
                f'the optical size 48; the packages {filled.package} and {filled.master_package} '
                f'hold the filled variant. The {len(fallback_names)} `fallbackIcons`, which the repository does not '
                'have yet at the pinned commit, are drawn from the same SVGs served by fonts.gstatic.com.\n\n'
                + common)
            superclass = 'MaterialIconsCategory'
        else:
            comment = (
                f'I am the root of the categories of the filled variant of Material Symbols Rounded ({each.axes}), '
                f'as {base.root} is of the default one: each subclass holds the icons of one category, '
                '`icon_<name>` at 16, 24 and 32 pixels, and answers the `iconTable` of the same category of '
                f'{base.package}. The package {each.master_package} adds `master_<name>`, at {MASTER_SIZE} pixels.\n\n'
                + common)
            superclass = base.root
        files[f'{pkg}/{each.root}.class.st'] = tonel_class(each.root, superclass, each.package, comment, root_methods)
        files[f'{masters_pkg}/{each.root}.extension.st'] = tonel_extension(each.root, each.master_package, [
            ('masterSize', ['\t"The side in pixels of the PNGs of master_<name>"', '', f'\t^ {MASTER_SIZE}']),
            ('masterDescription', [
                f'\t"Where the PNGs of master_<name> come from: rasterized at {MASTER_SIZE} pixels from the optical size 48,',
                f'\tthe largest, {each.axes}"', '', f'\t^ {st_string(master_source)}'])])
        for category in categories:
            members = [icon for icon in icons if icon['category'] == category]
            name = symbols_class_name(each.prefix, category)
            if each.filled:
                table = (True, 'iconTable', 'accessing', [
                    '\t"Name, codepoint and tags of each icon of my category: those of the default variant"',
                    '', f'\t^ {symbols_class_name(base.prefix, category)} iconTable'])
            else:
                rows = [f'\t\t#( {st_string(icon["name"])} 16r{icon["codepoint"]:X} {st_string(",".join(icon["tags"]))} )'
                        for icon in members]
                table = (True, 'iconTable', 'accessing', [
                    '\t"Name, codepoint and tags (one String, comma-separated) of each icon of my category"',
                    '', '\t^ #(', *rows, '\t)'])
            methods = [(True, 'materialCategory', 'accessing', ['', f'\t^ {st_string(category)}']), table]
            masters = []
            for icon in members:
                pngs = [rasterizer.png(sources[icon['name'], each.small_variant], size) for size in SIZES]
                methods.append((True, 'icon_' + icon['name'], 'icons', [png_array(pngs)]))
                master = rasterizer.png(sources[icon['name'], each.master_variant], MASTER_SIZE)
                masters.append(('master_' + icon['name'], ['\t^ ' + b64(master)]))
            files[f'{pkg}/{name}.class.st'] = tonel_class(
                name, each.root, each.package,
                f'I hold the {len(members)} icons of the category {category} of Material Symbols Rounded, '
                f'{each.axes} (see {each.root}).\n\nGenerated by scripts/generate.py: do not edit, regenerate.',
                methods)
            files[f'{masters_pkg}/{name}.extension.st'] = tonel_extension(name, each.master_package, masters)
    return files


# ---------------------------------------------------------------- Material Symbols theme pack

def parse_size(text, where):
    match = re.fullmatch(r'(\d+)x(\d+)', text)
    if not match:
        raise SystemExit(f'{where}: size {text!r}, expected WIDTHxHEIGHT')
    return int(match.group(1)), int(match.group(2))


def read_pharo_keys():
    """key -> ((w, h) at scale 1, at 1.5, at 2): the sizes of svgPack, the default pack of Pharo 12 to 15"""
    keys, header = {}, None
    with open(PHARO_KEYS, encoding='utf-8') as stream:
        for number, line in enumerate(stream, 1):
            if not line.strip() or line.startswith('#'):
                continue
            cells = line.rstrip('\n').split('\t')
            if header is None:
                header = cells
                continue
            row = dict(zip(header, cells))
            where = f'scripts/pharo-icon-keys.tsv:{number}'
            one = parse_size(row['size'], where)
            sizes = [one]
            for column, scale in (('size_1.5x', 1.5), ('size_2x', 2)):
                value = row.get(column, '-')
                sizes.append(parse_size(value, where) if value not in ('', '-')
                             else tuple(int(v * scale + 0.5) for v in one))
            keys[row['key']] = tuple(sizes)
    return keys


MAPPING_COLUMNS = ('pharoKey', 'symbolName', 'fill', 'grade', 'colour')


def read_symbols_mapping(manifest):
    """The rows of scripts/symbols-mapping.tsv, checked: (key, name, fill, grade, colour or None, sizes,
    trim or None).
    Every wrong row is reported, then the generator stops."""
    pharo_keys = read_pharo_keys()
    names = {icon['name'] for icon in manifest['icons']}
    missing = set(manifest['metadata'].get('left_out', []))
    rows, errors, seen, header = [], [], {}, None
    with open(SYMBOLS_MAPPING, encoding='utf-8') as stream:
        for number, line in enumerate(stream, 1):
            if not line.strip() or line.startswith('#'):
                continue
            cells = [cell.strip() for cell in line.rstrip('\n').split('\t')]
            where = f'scripts/symbols-mapping.tsv:{number}'
            if header is None:
                header = cells
                absent = [column for column in MAPPING_COLUMNS if column not in header]
                if absent:
                    raise SystemExit(f'{where}: the header lacks the columns {", ".join(absent)} '
                                     f'(expected at least: {" ".join(MAPPING_COLUMNS)})')
                continue
            row = dict(zip(header, cells))
            key, name = row.get('pharoKey', ''), row.get('symbolName', '')
            problems = []
            if key not in pharo_keys:
                problems.append(f'pharoKey {key!r} is not a key of svgPack (scripts/pharo-icon-keys.tsv)')
            elif key in seen:
                problems.append(f'pharoKey {key!r} is mapped twice (also line {seen[key]})')
            if name in missing:
                problems.append(f'symbolName {name!r} is listed by fonts.google.com but neither the repository at '
                                f'{SYMBOLS_COMMIT[:7]} nor fonts.gstatic.com has it (scripts/manifest-symbols.json, '
                                'left_out)')
            elif name not in names:
                problems.append(f'symbolName {name!r} is not a Material Symbols Rounded icon '
                                '(scripts/manifest-symbols.json)')
            fill, grade, colour = row.get('fill', ''), row.get('grade', ''), row.get('colour', '')
            if fill not in ('0', '1'):
                problems.append(f'fill {fill!r}, expected 0 or 1')
            if grade not in ('0', '200'):
                problems.append(f'grade {grade!r}, expected 0 or 200')
            if colour != '-' and not re.fullmatch(r'[0-9A-F]{6}', colour):
                problems.append(f'colour {colour!r}, expected RRGGBB (upper case) or -')
            trim = row.get('trim', '-')
            if trim not in ('', '-') and not (re.fullmatch(r'\d{1,3}', trim) and int(trim) <= MAX_TRIM):
                problems.append(f'trim {trim!r}, expected - or a margin of 0 to {MAX_TRIM} units of the 960 grid')
            if key in pharo_keys and row.get('size', '-') not in ('', '-'):
                actual = '{}x{}'.format(*pharo_keys[key][0])
                if row['size'] != actual:
                    problems.append(f'size {row["size"]}, but svgPack draws {key} at {actual}')
            if problems:
                errors += [f'{where}: {problem}' for problem in problems]
                continue
            seen[key] = number
            rows.append((key, name, int(fill), int(grade), None if colour == '-' else colour, pharo_keys[key],
                         None if trim in ('', '-') else int(trim)))
    if header is None:
        raise SystemExit('scripts/symbols-mapping.tsv: no header')
    if errors:
        raise SystemExit('scripts/symbols-mapping.tsv is wrong:\n  ' + '\n  '.join(errors))
    return rows


MAX_TRIM = 480
INK_GRID = 960
_ink_boxes = {}


def view_box(svg):
    match = re.search(rb'<svg\b[^>]*\bviewBox="([^"]*)"', svg)
    if not match:
        raise ValueError('an SVG without viewBox')
    return tuple(float(v) for v in match.group(1).split())


def ink_box(svg):
    """(x0, y0, x1, y1): the bounds of the ink of svg in the units of its viewBox, from a rendering at
    960 pixels (1 unit per pixel for Material Symbols), counting the pixels of alpha above 8"""
    key = sha256(svg)
    if key not in _ink_boxes:
        vx, vy, vw, vh = view_box(svg)
        if vw != vh:
            raise ValueError(f'a viewBox that is not square: {vw} x {vh}')
        cairosvg, _ = load_cairosvg()
        _, _, alphas = alpha_of_png(cairosvg.svg2png(bytestring=svg, output_width=INK_GRID, output_height=INK_GRID))
        rows = [y for y, row in enumerate(alphas) if max(row) > 8]
        columns = [x for x, top in enumerate(map(max, zip(*alphas))) if top > 8]
        if not rows:
            raise ValueError('an SVG without ink')
        unit = vw / INK_GRID
        _ink_boxes[key] = (vx + columns[0] * unit, vy + rows[0] * unit,
                           vx + (columns[-1] + 1) * unit, vy + (rows[-1] + 1) * unit)
    return _ink_boxes[key]


def trimmed_svg(svg, width, height, margin):
    """svg with its viewBox narrowed to its ink plus margin units on each side, then widened (or heightened)
    about its centre to the aspect width:height, so that the glyph fills a key of that size instead of keeping
    Material's padding"""
    x0, y0, x1, y1 = ink_box(svg)
    x0, y0, x1, y1 = x0 - margin, y0 - margin, x1 + margin, y1 + margin
    box_width, box_height = x1 - x0, y1 - y0
    if box_width * height < box_height * width:
        wider = box_height * width / height
        x0, box_width = x0 - (wider - box_width) / 2, wider
    else:
        taller = box_width * height / width
        y0, box_height = y0 - (taller - box_height) / 2, taller
    box = ' '.join(f'{round(v, 3):g}' for v in (x0, y0, box_width, box_height))
    tag = re.search(rb'<svg\b[^>]*>', svg)
    opening = tag.group(0)
    for attribute, value in ((b'viewBox', box), (b'width', str(width)), (b'height', str(height))):
        opening, count = re.subn(rb'\b' + attribute + rb'="[^"]*"', attribute + b'="' + value.encode() + b'"', opening)
        if count != 1:
            raise ValueError(f'an SVG whose <svg> has {count} {attribute.decode()} attributes')
    return svg[:tag.start()] + opening + svg[tag.end():]


def art_svg(sources, name, fill, grade, width, height, trim):
    """The SVG a key is drawn from at width x height, and whether it fills all of it (trimmed)"""
    svg = sources[name, ART_VARIANTS[fill, grade]]
    return (svg, False) if trim is None else (trimmed_svg(svg, width, height, trim), True)


def want_symbols_art(manifest, sources, rasterizer):
    for key, name, fill, grade, colour, sizes, trim in read_symbols_mapping(manifest):
        for width, height in sizes:
            svg, whole = art_svg(sources, name, fill, grade, width, height, trim)
            rasterizer.want(svg, width, height, whole)


def symbols_notice_text(manifest, rasterizer):
    upstream = manifest['upstream']
    return '\n'.join([
        'This icon pack includes Material Symbols by Google:',
        '',
        '  Material Symbols Rounded (the family "Material Symbols Rounded")',
        f'  https://github.com/{upstream["repository"]}',
        f'  commit {upstream["commit"]},',
        f'  {upstream["path"]}',
        '  (variants 24px, fill1_24px, grad200_24px and grad200fill1_24px)',
        '  Licensed under the Apache License, Version 2.0 (see LICENSE-material-icons).',
        '',
        'Its PNG files of the Material Symbols are modified forms of those SVG files:',
        f'rasterized by material-icons.st (scripts/generate.py, {rasterizer.description}),',
        'some of them cropped to the bounds of their drawing first (the column trim of',
        'scripts/symbols-mapping.tsv),',
        'then painted in one colour in Pharo by MaterialSymbolsThemeIcons.',
        'The other PNG files are those of the icon pack it was built over',
        '(by default svgPack, https://github.com/pharo-project/pharo-icon-packs),',
        'under the licence of that pack.',
        ''])


def generate_symbols_art(manifest, sources, rasterizer):
    rows = read_symbols_mapping(manifest)
    entries, methods, drawn = [], [], set()
    for key, name, fill, grade, colour, sizes, trim in rows:
        variant = ART_VARIANTS[fill, grade]
        selector = (f'art_{name}_{variant[:-5] or "default"}_' + '_'.join(f'{w}x{h}' for w, h in sizes)
                    + ('' if trim is None else f'_trim{trim}'))
        colour_literal = 'nil' if colour is None else st_string(colour)
        entries.append(f'\t\t#( {st_symbol(key)} {st_string(name)} {fill} {grade} {colour_literal} #{selector} )')
        if selector not in drawn:
            drawn.add(selector)
            pngs = []
            for w, h in sizes:
                svg, whole = art_svg(sources, name, fill, grade, w, h, trim)
                pngs.append(rasterizer.png(svg, w, h, whole))
            methods.append((True, selector, 'icons', [png_array(pngs)]))
    methods.append((True, 'entries', 'accessing', [
        '\t"Pharo icon key, Material Symbols name, fill (0 or 1), grade (0, or 200 for heavier strokes of the',
        '\tsame size), colour (RRGGBB, or nil for the colour of the UI theme), and the selector of the',
        '\tmethod that answers its PNGs at the scales 1, 1.5 and 2, at the sizes of svgPack, the default pack"',
        '', '\t^ #(', *entries, '\t)']))
    methods.append((True, 'noticeText', 'licence', [
        '\t"The attribution that MaterialSymbolsThemeIcons class >> exportPack:to: puts in the zip, as NOTICE"',
        '', '\t^ ' + st_string(symbols_notice_text(manifest, rasterizer))]))
    text = tonel_class(
        SYMBOLS_ART_CLASS, 'Object', SYMBOLS_THEME_PACKAGE,
        f'I hold the mapping of {len(rows)} Pharo icon keys to Material Symbols Rounded for MaterialSymbolsThemeIcons '
        '(scripts/symbols-mapping.tsv), and the pixels of each key, drawn from the optical size 24 in its fill and '
        'grade at the sizes that svgPack, the default pack, draws it at (scripts/pharo-icon-keys.tsv), so that the '
        'rows and menus keep their layout. A key that is not square has the symbol centred, at the side of its '
        'shorter edge. `noticeText` goes into the zip that MaterialSymbolsThemeIcons exports, with the licence '
        f'(`{SYMBOLS_SETS[0].root} licenseText`).\n\n'
        f'Source: {source_of(manifest)}, Apache License 2.0 (Google). Rasterized by {rasterizer.description}.\n\n'
        'Generated by scripts/generate.py: do not edit, regenerate.',
        methods)
    return {f'src/{SYMBOLS_THEME_PACKAGE}/{SYMBOLS_ART_CLASS}.class.st': text}


# ---------------------------------------------------------------- main

GENERATED_PACKAGES = (PACKAGE, MASTER_PACKAGE) + tuple(
    package for each in SYMBOLS_SETS for package in (each.package, each.master_package))


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('command', nargs='?', default='generate', choices=('generate', 'pin'))
    parser.add_argument('which', nargs='?', default='all', choices=('all', 'rounded', 'symbols'),
                        help='the pin to rebuild (pin only)')
    parser.add_argument('--cache', default=os.path.join(ROOT, 'build', 'cache'))
    parser.add_argument('--check', action='store_true', help='compare with src/ instead of writing')
    parser.add_argument('--jobs', type=int, default=min(32, os.cpu_count() or 1),
                        help='rasterizing processes (default: the CPUs, at most 32)')
    options = parser.parse_args()
    if options.command == 'pin':
        return pin(options.cache, options.which)
    with open(MANIFEST, encoding='utf-8') as stream:
        manifest = json.load(stream)
    with open(SYMBOLS_MANIFEST, encoding='utf-8') as stream:
        symbols = json.load(stream)
    read_symbols_mapping(symbols)  # stop early on a wrong mapping
    rasterizer = Rasterizer(options.jobs)
    sources = fetch_all(rounded_files(manifest), options.cache)
    symbol_sources = fetch_all(symbols_files(symbols), options.cache)
    print(f'{len(sources) + len(symbol_sources)} source files checked', file=sys.stderr)
    want_rounded(manifest, sources, rasterizer)
    want_art(manifest, sources, rasterizer)
    want_symbols(symbols, symbol_sources, rasterizer)
    want_symbols_art(symbols, symbol_sources, rasterizer)
    print(f'rasterizing {len(rasterizer.wanted)} PNGs in {options.jobs} processes', file=sys.stderr)
    rasterizer.run()
    files = generate_rounded(manifest, sources, rasterizer)
    files.update(generate_art(manifest, sources, rasterizer))
    files.update(generate_symbols(symbols, symbol_sources, rasterizer))
    files.update(generate_symbols_art(symbols, symbol_sources, rasterizer))
    stale = []
    expected = {os.path.join(ROOT, path) for path in files}
    for package in GENERATED_PACKAGES:
        generated_dir = os.path.join(ROOT, 'src', package)
        if os.path.isdir(generated_dir):
            stale += [os.path.join(generated_dir, f) for f in sorted(os.listdir(generated_dir))
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
    print(f'{len(files)} files written: {len(manifest["icons"])} Material Icons Rounded, '
          f'{len(symbols["icons"])} Material Symbols Rounded ({rasterizer.description})')
    return 0


if __name__ == '__main__':
    sys.exit(main())
