# material-icons.st

Google's Material icons for Pharo 12 to 15, in the Rounded style, every icon of two sets, each at 16, 24 and 32 pixels and at 192 pixels:

- **[Material Icons Rounded](https://fonts.google.com/icons?icon.set=Material+Icons&icon.style=Rounded)**, all 2127 icons: **`MaterialIcons rounded`**;
- **[Material Symbols Rounded](https://fonts.google.com/icons?icon.set=Material+Symbols&icon.style=Rounded)**, all 3929 icons, outlined: **`MaterialIcons symbolsRounded`**. The filled ones are an optional extra, **`MaterialIcons symbolsRoundedFilled`**.

Every icon comes by its Material name, as a Form or a FormSet, at any size, in any colour, with its category, codepoint and tags. Two icon packs for Pharo's UI are drawn with these icons:

- **`MaterialThemeIcons`** uses Material Icons Rounded;
- **`MaterialSymbolsThemeIcons`** uses Material Symbols Rounded.

Each pack replaces the icons of the tools (`#add`, `#delete`, `#refresh`, `#smallSave`, `#testGreen`…) and keeps the rest of the current pack. Either one can be installed or removed at any time.

```smalltalk
Metacello new
	baseline: 'MaterialIcons';
	repository: 'github://massimo-nocentini/material-icons.st:master/src';
	load
```

`repository: 'tonel:///path/to/material-icons.st/src'` loads from a local clone. Loading changes nothing in the UI. `load:` takes a group, or an Array of groups, to load a part:

| group | packages | what | Tonel |
|---|---|---|---:|
| `Core` | `MaterialIcons-Core`, `MaterialIcons-Rounded` | `MaterialIcons rounded` at 16, 24 and 32 pixels | 2.9 MB |
| `IconsRounded` | `Core`, `MaterialIcons-Rounded-192` | and its masters at 192 pixels | +4.4 MB |
| `SymbolsRoundedSmall` | `MaterialIcons-Core`, `MaterialSymbols-Rounded` | `MaterialIcons symbolsRounded` at 16, 24 and 32 pixels | 6.6 MB |
| `SymbolsRounded` | `SymbolsRoundedSmall`, `MaterialSymbols-Rounded-192` | and its masters at 192 pixels | +11.0 MB |
| `SymbolsRoundedFilled` | `MaterialSymbols-Rounded-Filled`, `MaterialSymbols-Rounded-Filled-192` | `MaterialIcons symbolsRoundedFilled`, all sizes | 15.1 MB |
| `ThemePack` | `MaterialIcons-ThemePack` (with `Core`) | `MaterialThemeIcons` | 0.04 MB |
| `SymbolsThemePack` | `MaterialSymbols-ThemePack` (with `SymbolsRoundedSmall`) | `MaterialSymbolsThemeIcons` | 0.02 MB |
| `Tests` | `MaterialIcons-Tests`, `MaterialSymbols-Tests` (`IconsTests`, `SymbolsTests`) | the tests, with the masters | |
| `default` | all of the above but `SymbolsRoundedFilled` | | 25.1 MB |
| `Full` | all of them | | 40.2 MB |

For example, `load: #( 'SymbolsRounded' 'SymbolsThemePack' )` loads the symbols and their pack without Material Icons Rounded. `load: 'Core'` loads what the earlier versions loaded.

The icon data is generated: `scripts/generate.py` rasterizes the pinned SVGs of Google's repository, see [Regenerating](#regenerating).

## The icons

```smalltalk
MaterialIcons rounded iconNamed: #home.				"a 16x16 Form"
MaterialIcons rounded formNamed: #arrow_back scale: 2.		"32x32 (scales 1, 1.5 and 2: 16, 24 and 32 pixels)"
MaterialIcons rounded formNamed: #arrow_back size: 128.		"128x128, from the master"
MaterialIcons rounded masterFormNamed: #arrow_back.		"192x192, the master itself"
MaterialIcons rounded formSetNamed: #search.			"a FormSet of the three small sizes, for HiDPI"
MaterialIcons rounded formNamed: #delete scale: 1 color: Color red.
MaterialIcons rounded formNamed: #delete size: 48 color: Color red.
MaterialIcons rounded iconNamed: #'10k'.			"names that begin with a digit are quoted Symbols"
MaterialIcons rounded pngBytesNamed: #home scale: 1.		"the PNG itself"
MaterialIcons rounded masterPNGBytesNamed: #home.		"the master, Google's own PNG"

MaterialIcons rounded size.					"2127"
MaterialIcons rounded iconNames.				"#(#'10k' #'10mp' ... #zoom_out_map)"
MaterialIcons rounded categories.				"#('action' 'alert' 'av' ... 'toggle')"
MaterialIcons rounded iconNamesInCategory: 'navigation'.
MaterialIcons rounded search: 'trash'.				"by name and by tag: #(#auto_delete #delete ...)"
MaterialIcons rounded entryNamed: #home.			"a MaterialIcon(#home action)"
MaterialIcons rounded tagsOf: #home.
MaterialIcons rounded codepointOf: #home.			"16rE88A, the glyph in the Material Icons fonts"

MaterialIcons symbolsRounded iconNamed: #home.			"the same protocol, Material Symbols Rounded"
MaterialIcons symbolsRounded size.				"3929"
MaterialIcons symbolsRounded categories.			"#('Actions' 'Activities' ... 'UI actions')"
MaterialIcons symbolsRounded formNamed: #eco size: 64.
MaterialIcons symbolsRoundedFilled iconNamed: #home.		"group SymbolsRoundedFilled"
MaterialIcons styles.						"#(#rounded #symbolsRounded ...), those loaded"
```

- **Names** are Material's, in snake case (`arrow_back`, `content_copy`). Some begin with a digit (`10k`, `3d_rotation`): 57 in Material Icons Rounded and 67 in Material Symbols Rounded.
- **Two sets.** The two sets share 1837 names. 290 names are only in Material Icons Rounded, and 2092 only in Material Symbols Rounded. A shared name is often drawn differently in the two sets. Material Icons Rounded is filled (`home` is a solid house), and Material Symbols Rounded is outlined by default, with a thinner stroke (wght 400). Its filled variant (FILL 1) is in `symbolsRoundedFilled`.
- **Colour.** The PNGs hold only the shape, so an icon can be painted in any colour. The small sizes are 8-bit grey and alpha, and so are the Symbols masters; the masters of Material Icons Rounded are Google's own PNGs, black.
  - By default an icon takes the text colour of the current UI theme, so it reads on Pharo 15's dark theme and on Pharo 12's light one.
  - `MaterialIcons rounded color: Color gray` fixes the colour, and `color: nil` follows the theme again.
  - Each style answers one instance shared by all its clients, so `color:` changes the colour for every one of them. A client that wants its own colour should pass it to `formNamed:scale:color:`, `formNamed:size:color:` or `formSetNamed:color:` instead. `nil` there also means the colour of the theme.
- **Sizes.**
  - **16, 24 and 32 pixels** are drawn ahead from the vector icons, one PNG per size. They are the sizes of Pharo's own pack (svgPack) at the scales 1, 1.5 and 2. A FormSet holds all three, so a canvas scaled for HiDPI picks the sharp one (`asFormAtScale: 2` answers the 32-pixel Form). `formNamed:size:` answers them for 16, 24 and 32.
  - **The master** of each icon is its PNG at 192 pixels (`masterSize`; packages `…-192`).
  - **Any other size** comes from the master. `formNamed:size:` shrinks it by averaging the pixels under each pixel, weighted by area (a box filter). Above 192 it enlarges it by bilinear interpolation. The tests check that the master shrunk to 16, 24 and 32 pixels stays within 4/255 of mean alpha of the icons drawn ahead. Without the masters (`hasMasters` false), the other sizes come from the 32-pixel icon.
  - **Why the small sizes are drawn ahead:** a reduced master is close to a direct rendering but not the same, so the small sizes stay crisper when drawn ahead.
  - **Why two optical sizes for the Symbols:** the small Symbols are drawn from optical size 24 and their masters from optical size 48, the largest. Optical size 24 has the most ink and is the crispest at 16 pixels, and optical size 48 keeps the strokes in proportion at 192 pixels. So a Symbols master reduced to 16 pixels is close to the 16-pixel icon, not equal to it.
- **Cache.** An icon is decoded the first time it is asked for. Its Form is kept per name, size and colour (and so is a decoded master) until one of these:
  - `flushCache`;
  - the next save of the image (so a saved image does not carry the decoded Forms);
  - the next start.

  Nothing else empties the cache, so each new colour or size adds Forms to it. The theme packs flush it when the UI theme changes and on `uninstall`. `cacheSize` counts the Forms of the current session only.

## Pharo's UI with Material icons

```smalltalk
MaterialThemeIcons install.				"Material icons in the windows and menus opened from now on"
MaterialThemeIcons uninstall.				"the previous pack again"
MaterialThemeIcons isInstalled.
MaterialThemeIcons installColor: Color gray.		"a fixed colour instead of the theme's"

Smalltalk ui icons iconNamed: #add.			"Material, once installed"
Smalltalk ui icons iconNamed: #material_cloud_sync.	"any Material icon, by material_<name>"

MaterialSymbolsThemeIcons install.			"the same with Material Symbols Rounded"
MaterialSymbolsThemeIcons uninstall.
Smalltalk ui icons iconNamed: #symbol_cloud_sync.	"any Material Symbol, by symbol_<name>"
```

Everything below holds for both packs. Where they differ, the [Material Symbols pack](#the-material-symbols-pack) says how.

- **Install.** `install` makes a `MaterialThemeIcons` the current `ThemeIcons`, which is what `Smalltalk ui icons`, `iconNamed:`, Spec's icon providers and Commander use. 243 keys of the default pack are mapped to Material icons (`scripts/pharo-mapping.tsv`). They are drawn at the size the default pack uses for each key (14 pixels for `#accept`, 32 for `#info`), so rows and menus keep their layout.
- **Keys that stay as they were.** Every other key keeps the icon of the pack that was current before: check boxes, radio buttons, the small arrows, window buttons, halos, logos (Pharo, git, GitHub), the coloured circles and so on.
- **Colours.** The icons take the colour of the UI theme and are redrawn when the theme changes. The status keys keep fixed colours: tests (green, red, amber, and a filled grey circle for `testNotRun`, so that it does not look like a radio button), errors (red), warnings (amber), information (blue), `breakpoint` (red) and `confirm` (green).
- **Weight.** Material icons look lighter than svgPack's: they keep Material's padding of 2 units on the 24 grid, so their shapes are about 12% smaller and carry about two thirds of the ink. It shows most on `stop`, `downArrow`, `go`/`glamorousGo`/`smallDoIt` (a 7-pixel triangle in 13 pixels) and `leftSide`/`rightSide`. The padding is not trimmed: many icons draw into it.
- **Uninstall.** `uninstall` makes the previous pack current again and empties the cache of the icons it was drawn with.
  - Installing a second time keeps the first fallback, so `uninstall` always goes back to the pack you had before.
  - Installing one Material pack while the other is installed goes over the other's fallback: the two packs replace each other rather than piling up.
- **Open windows.** Pharo does not redraw open windows when the icon pack changes, so the new icons appear in windows opened afterwards.
- **Stored settings.** When the Settings of Pharo are saved while the Material pack is installed, they record the pack it replaced (svgPack, usually), not `materialRound`: a pack restored from stored settings is read from `<name>.zip` in `ThemeIcons destinationPath` or downloaded from pharo-icon-packs, where there is no `materialRound.zip`. To have the Material icons at every start, put `MaterialThemeIcons install` in a startup script.
- **Settings.** The Settings of Pharo only list the current pack and the zips in `ThemeIcons destinationPath` (`pharo-local/icon-packs`). That is "Appearance > Icon Set" in Pharo 12, and "Appearance > Icons Pack" (the Icons Pack Manager) in Pharo 15. `MaterialThemeIcons exportToIconPacks` writes the pack there as `materialRound.zip`, in the layout of [pharo-icon-packs](https://github.com/pharo-project/pharo-icon-packs) (`png-scale1.0`, `png-scale1.5`, `png-scale2.0`). It also writes the previous pack (`svgPack.zip`) if that file is missing, so both can be chosen there offline. A pack chosen in the Settings is a plain `ThemeIcons` read from the zip: a snapshot of the Material pack at export time, without the `material_` keys (the export leaves them out, even those already used) and without the redraw on theme changes. `install` and `exportToIconPacks` over such a snapshot go over the pack replaced before (or svgPack), not over the snapshot. The zip also holds the Apache License 2.0 of the icons (`LICENSE-material-icons`) and a `NOTICE` that says where they come from and how they were changed, next to the PNG directories; Pharo reads only the PNGs.

### The Material Symbols pack

`MaterialSymbolsThemeIcons` (group `SymbolsThemePack`) maps every Pharo icon key listed in `scripts/symbols-mapping.tsv` to a Material Symbol. svgPack has 377 keys in both Pharo 12 and Pharo 15, with their sizes in `scripts/pharo-icon-keys.tsv`; keys that are not mapped keep the previous pack's icon.

- **Variant.** Each mapped key chooses its own variant of the symbol:
  - outlined or filled (`fill`). The status keys are filled, so a test result or an error reads as a solid shape.
  - grade 0 or 200 (`grade`). Grade 200 has heavier strokes at the same size: 34% more ink at 16 pixels, on average over all the symbols, which brings them closer to the weight of svgPack.
- **Exact sizes.** Each key is drawn from optical size 24 at the sizes svgPack draws it at the scales 1, 1.5 and 2: 14, 21 and 28 pixels for `#accept`, 7×10 for `#play`. A key that is not square has the symbol centred, at the side of its shorter edge.
- **Colours.** Every key takes the colour of the UI theme, except the keys that the mapping gives a fixed colour (the status keys: tests, errors, warnings, information).
- **Pixels.** `MaterialSymbolsThemeIconsArt` holds the pixels of every mapped key. The pack therefore needs neither the masters nor the filled packages, only `MaterialSymbols-Rounded` for the `symbol_<name>` keys.
- **Export.** `exportToIconPacks` writes `materialSymbolsRounded.zip`, with `LICENSE-material-symbols` and a `NOTICE` of its own.

## What is in it

### Material Icons Rounded

The icons are the 2127 that the family Material Icons Round supports in the metadata of fonts.google.com/icons, the page linked above, as served by `https://fonts.google.com/metadata/icons?key=material_symbols&incomplete=true`. The pin uses that endpoint.

- **The count.** It is 2122 icons plus 5 legacy aliases still listed there. The older endpoint `https://fonts.google.com/metadata/icons`, which covers only the five Material Icons families, lists the 2122 without the aliases: `face_unlock`, `info_outline`, `label_important_outline`, `lightbulb_outline` and `lock_outline`.
- **Left out.** Ten more icons have a rounded SVG in Google's repository, but fonts.google.com does not list them for Material Icons Round: `amp_stories`, `eco`, `emoji_flags`, `facebook`, `flourescent`, `label_outline`, `outbond`, `phone_in_talk`, `whatsapp` and `wifi_tethering_error_rounded`.

| category | icons | category | icons | category | icons |
|---|---:|---|---:|---|---:|
| action | 458 | editor | 122 | navigation | 57 |
| alert | 7 | file | 44 | notification | 69 |
| av | 125 | hardware | 78 | places | 83 |
| communication | 99 | home | 27 | search | 29 |
| content | 80 | image | 246 | social | 187 |
| device | 194 | maps | 209 | toggle | 13 |

- **Where they live.** Each category is a class of `MaterialIcons-Rounded` (`MaterialIconsRoundedAction`…).
  - On its class side, `iconTable` lists the name, codepoint and tags of each icon.
  - One method per icon, `icon_<name>`, answers its three PNGs in Base64.
  - `MaterialIcons-Rounded-192` adds `master_<name>` to the same classes.
- **The masters** are Google's own largest raster of each icon, shipped byte for byte: `android/<category>/<name>/materialiconsround/black/res/drawable-xxxhdpi/round_<name>_black_48.png`, 192 pixels (48 dp at xxxhdpi), at the pinned commit. Its SHA-256 is in the manifest.
  - Google's iOS PNGs are only 144 pixels and the `png/` tree 96.
  - They have the same pixels as a CairoSVG rendering of the SVG at 192 pixels: 0.04/255 of mean alpha difference. They are also 17% smaller than that rendering.
  - They are 8-bit PNGs of three colour types (grey and alpha, RGBA, and a palette of 1 to 8 bits), all black, and every one decodes in Pharo 12 and 15.
- **Small sizes.** At 16 pixels, Material's 2-pixel strokes on a 24 grid become 1.33 pixels and look a little soft, and the icons made of small text (`10k`, `8mp`) cannot be read. A few icons are off-centre upstream and are kept as they are drawn there: `r_mobiledata` sits in the top-left corner of its box, and `signal_cellular_alt_1_bar`, `minimize` and `maximize` hug one edge.
- **Duplicates.** Some names share the same SVG upstream (`clear` and `close`, `create` and `edit`, `image` and `photo`…). Each name has its own method and its own copy of the PNGs.

### Material Symbols Rounded

The icons are those that the family Material Symbols Rounded supports in the same metadata: 3944 are listed, and 3929 are kept.

- **Left out.** The other 15 are the newest, with no SVG in Google's repository at the pinned commit yet: `contrast_auto`, `contrast_inverse`, `contrast_inverse_auto`, `devices_2`, `document_share_off`, `frame_person_2`, `input_search`, `mail_person`, `mirror_stack`, `print_landscape_long`, `print_landscape_short`, `print_portrait_long`, `print_portrait_short`, `pull_request` and `touch_double_2_hold`.
  - They come with a later pin; `MaterialSymbolsRoundedCategory missingIcons` lists them.
  - fonts.gstatic.com serves them, but unversioned, so a pin on them could not be reproduced.

| category | icons | category | icons | category | icons |
|---|---:|---|---:|---|---:|
| Actions | 271 | Hardware | 271 | Social | 384 |
| Activities | 127 | Home | 125 | Text | 522 |
| Android | 273 | Household | 189 | Transit | 127 |
| Audio&Video | 229 | Images | 296 | Travel | 94 |
| Business | 181 | Maps | 175 | UI actions | 448 |
| Communicate | 172 | Privacy | 45 | | |

- **Where they live.** Each category is a class of `MaterialSymbols-Rounded`. The category names are cleaned up for the class names: `UI actions` becomes `MaterialSymbolsRoundedUIActions`, `Audio&Video` becomes `MaterialSymbolsRoundedAudioVideo`.
  - `iconTable` holds the tags of an icon as one String, comma-separated, because single literals for the 138,000 tags would cost megabytes of image; `tagsOf:` answers an Array.
  - `MaterialSymbols-Rounded-192` adds `master_<name>`.
- **Variants.** Upstream draws each symbol in 168 variants: optical size 20, 24, 40 or 48, FILL 0 or 1, weight 100 to 700, grade −25, 0 or 200. The packages hold the default weight and grade (wght 400, GRAD 0):

  | | 16, 24, 32 pixels (optical size 24) | 192 pixels (optical size 48) |
  |---|---|---|
  | outlined (FILL 0) | `MaterialSymbols-Rounded` | `MaterialSymbols-Rounded-192` |
  | filled (FILL 1) | `MaterialSymbols-Rounded-Filled` | `MaterialSymbols-Rounded-Filled-192` |

  The theme pack also uses grade 200, at optical size 24, for the keys mapped to it.
- **Masters.** They are rendered by CairoSVG at 192 pixels from optical size 48, the largest optical size. At that size each pixel covers 5 units of the font, so the 60-unit strokes of optical size 48 are exactly 12 pixels wide. 256 pixels would cost 42% more for no visible gain.

### Sizes, load times, image growth

Measured on stock images: Pharo 15 build 117 and Pharo 12 build 1599. Each group was loaded with Metacello from a local clone into a fresh image, the 14 images loading at once. Before saving, the images ran `MCFileBasedRepository flushAllCaches` and a garbage collection. "Image" is the growth of the saved `.image`; the `.changes` file grows by about as much as the Tonel loaded.

| group | PNGs | Tonel | load, Pharo 15 | load, Pharo 12 | image, Pharo 15 | image, Pharo 12 |
|---|---:|---:|---:|---:|---:|---:|
| `Core` | 1.8 MB | 2.9 MB | 3.0 s | 6.9 s | +5.2 MB | +5.1 MB |
| `IconsRounded` | 4.9 MB | 7.3 MB | 6.4 s | 15.4 s | +9.8 MB | +12.0 MB |
| `SymbolsRoundedSmall` | 3.6 MB | 6.6 MB | 6.0 s | 24.6 s | +8.7 MB | +10.8 MB |
| `SymbolsRounded` | 11.5 MB | 17.6 MB | 13.5 s | 44.5 s | +20.0 MB | +22.4 MB |
| `default` | 16.5 MB | 25.1 MB | 19.5 s | 60.5 s | +28.3 MB | +31.0 MB |
| `Full` | 27.1 MB | 40.2 MB | 30.3 s | 90.8 s | +43.7 MB | +47.2 MB |

- **Files and methods.** The largest generated file is 1.4 MB (`MaterialSymbolsRoundedSocial.extension.st`, 384 masters). The largest method is 170 KB, the `iconTable` of the 522 symbols of `Text`. Neither Pharo 12 nor Pharo 15 hits a limit of Tonel, Monticello or the compiler.
- **Tests.** The 72 tests of `Tests` pass on both versions, the filled ones included. They take about 3 minutes, most of it decoding every PNG at every size, masters included.

## Regenerating

These files are generated by `scripts/generate.py`:

- the packages `MaterialIcons-Rounded`, `MaterialIcons-Rounded-192`, `MaterialSymbols-Rounded`, `MaterialSymbols-Rounded-192`, `MaterialSymbols-Rounded-Filled` and `MaterialSymbols-Rounded-Filled-192`;
- the classes `MaterialThemeIconsArt` and `MaterialSymbolsThemeIconsArt`.

Do not edit them. Change the generator or a mapping (`scripts/pharo-mapping.tsv`, `scripts/symbols-mapping.tsv`) and run it again.

```sh
python3 -m venv build/venv
build/venv/bin/pip install -r scripts/requirements.txt	# CairoSVG 2.9.1 and its dependencies, pinned
build/venv/bin/python -I scripts/generate.py			# writes src/
build/venv/bin/python -I scripts/generate.py --check		# compares instead: "up to date"
```

- **What it does.** It downloads the pinned files of [google/material-design-icons](https://github.com/google/material-design-icons) into `build/cache` and checks each file against its SHA-256 in the manifest. The cache's layout is `mir-svg/`, `mir-android-xxxhdpi-192/` and `msr-svg/`; `--cache DIR` puts it elsewhere. It then rasterizes the icons with CairoSVG and writes the Tonel files. The files it uses:
  - **Material Icons Rounded** (`scripts/manifest.json`), at commit `3912baecc97388955ce39f5e26bfb786a70cbe48`, the last commit that changed `src/`. The `android/` tree is the same there as at the later pin. It takes:
    - each icon's `src/<category>/<name>/materialiconsround/24px.svg`, rasterized at 16, 24 and 32 pixels;
    - its 192-pixel `android/…/drawable-xxxhdpi/round_<name>_black_48.png`, kept as it is.
  - **Material Symbols Rounded** (`scripts/manifest-symbols.json`), at commit `10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7`. It takes six SVGs per symbol from `symbols/web/<name>/materialsymbolsrounded/`:
    - `<name>_24px.svg` and `<name>_fill1_24px.svg`, rasterized at 16, 24 and 32 pixels;
    - `<name>_48px.svg` and `<name>_fill1_48px.svg`, rasterized at 192 pixels;
    - `<name>_grad200_24px.svg` and `<name>_grad200fill1_24px.svg`, for the theme pack.
- **Time.** The first run downloads 27,828 files: 4,254 for Material Icons Rounded and 23,574 for Material Symbols Rounded. raw.githubusercontent.com answers "429 Too Many Requests" to many quick downloads; the generator waits and retries, so a first run can take 10 to 15 minutes. With the cache filled, rasterizing the 32,127 PNGs takes about 1 minute in 32 processes (`--jobs N`; the default is the number of CPUs, at most 32). Each PNG depends only on its own SVG.
- **Reproducible.** It writes the PNGs itself (Python's zlib), so rerunning on the same inputs writes the same bytes, whatever the number of processes. The committed data was made with cairo 1.18.6.
- **libcairo.** CairoSVG needs `libcairo.so.2`. Where the system has none, point `LD_LIBRARY_PATH` at the `lib` directory of a Pharo VM that ships cairo. The generator warns when the cairo version differs, since the pixels may then differ slightly.
- **The pins.** Each manifest records:
  - the upstream commit;
  - the SHA-256 of the upstream `LICENSE` (the same file at both commits);
  - for each icon, its name, category, codepoint, version, tags and the SHA-256 of each of its files;
  - a hash of what the pin takes from the metadata: `round_subset_sha256` for Material Icons Rounded, `subset_sha256` for Material Symbols Rounded.

  The Symbols manifest also lists the icons that are left out (`missing_at_commit`). `generate.py pin [rounded|symbols]` rebuilds a manifest from the live metadata; it only needs to be run to move a pin, and it resumes from the files it already downloaded.

  The live metadata changes from one fetch to the next (its popularity counters), so the pin does not hash it as it comes. The subset hash covers only what the pin takes from it: the pinned icons sorted by name, each with its name, categories, codepoint, version and tags, as compact JSON with sorted keys. It can be recomputed from the manifest alone, and rerunning `pin` leaves the manifest as it is while Google changes none of those icons.
- **The UI mappings.**
  - `scripts/pharo-mapping.tsv` maps Pharo icon keys to Material Icons Rounded names. Each row gives the key's size in the default pack (svgPack) and an optional fixed colour.
  - `scripts/symbols-mapping.tsv` maps keys to Material Symbols. Its columns are named in its header: `pharoKey`, `symbolName`, `fill`, `grade` and `colour`, plus optional `size` and `note`. The sizes come from `scripts/pharo-icon-keys.tsv`: the 377 keys of svgPack and their sizes at the three scales, the same in Pharo 12 and 15 (the tests check them against the pack).
  - The generator stops on any unknown key or name, a symbol that the pin leaves out, a key mapped twice or a wrong value, and lists every wrong line.

## Licence

- **The code** of this repository is under the MIT licence (`LICENSE`).
- **The icons** are Material Icons and Material Symbols by Google. Both are under the Apache License 2.0: `LICENSE-material-icons` is the `LICENSE` of google/material-design-icons, the same file at both pinned commits.
- **What the packages hold.**
  - `MaterialIcons-Rounded-192` holds Google's PNGs unmodified, in Base64.
  - The other generated packages and the two Art classes hold PNG renderings of Google's SVGs, made as described above.
  - The class comments name the source and the licence, and `NOTICE` gives the attribution.
- **In the image.** The text of the licence is also in the image, with the icons it covers: `MaterialIconsRoundedCategory licenseText` and `MaterialSymbolsRoundedCategory licenseText` (generated).
- **In the exported zips.** The zips written by `exportToIconPacks` carry the licence (`LICENSE-material-icons` or `LICENSE-material-symbols`) and a NOTICE of their own (`MaterialThemeIconsArt noticeText`, `MaterialSymbolsThemeIconsArt noticeText`, generated).
- Google's README asks for no attribution but welcomes it.
