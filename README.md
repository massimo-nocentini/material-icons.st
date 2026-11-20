# material-icons.st

The icons of [Material Icons Rounded](https://fonts.google.com/icons?icon.set=Material+Icons&icon.style=Rounded), all 2127 of them, for Pharo 12 to 15:

- **`MaterialIcons rounded`**: every icon by its Material name, as a Form or a FormSet at 16, 24 and 32 pixels, in any colour, with its category, codepoint and tags;
- **`MaterialThemeIcons`**: an icon pack for Pharo's UI drawn with them. It replaces the icons of the tools (`#add`, `#delete`, `#refresh`, `#smallSave`, `#testGreen`…) and keeps the rest of the current pack. It can be installed and removed at any time.

From a local clone (the repository is not published yet):

```smalltalk
Metacello new
	baseline: 'MaterialIcons';
	repository: 'tonel:///path/to/material-icons.st/src';
	load
```

Once it is pushed to GitHub, without a clone:

```smalltalk
Metacello new
	baseline: 'MaterialIcons';
	repository: 'github://massimo-nocentini/material-icons.st:master/src';
	load
```

The groups are `Core` (`MaterialIcons-Core` and the icons, `MaterialIcons-Rounded`), `ThemePack` (`MaterialIcons-ThemePack`), `Tests` (`MaterialIcons-Tests`) and `default` (all of them). `load: 'Core'` loads the icons alone. Loading changes nothing in the UI.

The icon data is generated: `scripts/generate.py` rasterizes the pinned SVGs of Google's repository (see [Regenerating](#regenerating)).

## The icons

```smalltalk
MaterialIcons rounded iconNamed: #home.				"a 16x16 Form"
MaterialIcons rounded formNamed: #arrow_back scale: 2.		"32x32 (scales 1, 1.5 and 2: 16, 24 and 32 pixels)"
MaterialIcons rounded formSetNamed: #search.			"a FormSet of the three, for HiDPI"
MaterialIcons rounded formNamed: #delete scale: 1 color: Color red.
MaterialIcons rounded iconNamed: #'10k'.			"names that begin with a digit are quoted Symbols"
MaterialIcons rounded pngBytesNamed: #home scale: 1.		"the PNG itself"

MaterialIcons rounded size.					"2127"
MaterialIcons rounded iconNames.				"#(#'10k' #'10mp' ... #zoom_out_map)"
MaterialIcons rounded categories.				"#('action' 'alert' 'av' ... 'toggle')"
MaterialIcons rounded iconNamesInCategory: 'navigation'.
MaterialIcons rounded search: 'trash'.				"by name and by tag: #(#auto_delete #delete ...)"
MaterialIcons rounded entryNamed: #home.			"a MaterialIcon(#home action)"
MaterialIcons rounded tagsOf: #home.
MaterialIcons rounded codepointOf: #home.			"16rE88A, the glyph in the Material Icons fonts"
```

- **Names** are Material's, in snake case (`arrow_back`, `content_copy`). 57 of them begin with a digit (`10k`, `3d_rotation`).
- **Colour.** The PNGs hold only the shape (8-bit grey and alpha), so the icons can be painted in any colour. By default they take the text colour of the current UI theme, so they read on Pharo 15's dark theme and on Pharo 12's light one. `MaterialIcons rounded color: Color gray` fixes the colour, and `color: nil` follows the theme again. `MaterialIcons rounded` is one instance shared by all its clients, so `color:` changes the colour for every one of them: a client that wants its own colour should pass it to `formNamed:scale:color:` or `formSetNamed:color:` instead (`nil` there also means the colour of the theme).
- **Sizes.** 16, 24 and 32 pixels are the sizes of Pharo's own pack (svgPack) at the scales 1, 1.5 and 2. A FormSet holds all three, so a canvas scaled for HiDPI picks the sharp one (`asFormAtScale: 2` answers the 32-pixel Form).
- **Cache.** An icon is decoded the first time it is asked for. Its Form is kept per name, scale and colour until `flushCache` or the next start of the image. Nothing else empties the cache, so each new colour adds Forms to it; `MaterialThemeIcons` flushes it when the UI theme changes.

## Pharo's UI with Material icons

```smalltalk
MaterialThemeIcons install.				"Material icons in the windows and menus opened from now on"
MaterialThemeIcons uninstall.				"the previous pack again"
MaterialThemeIcons isInstalled.
MaterialThemeIcons installColor: Color gray.		"a fixed colour instead of the theme's"

Smalltalk ui icons iconNamed: #add.			"Material, once installed"
Smalltalk ui icons iconNamed: #material_cloud_sync.	"any Material icon, by material_<name>"
```

- **Install.** `install` makes a `MaterialThemeIcons` the current `ThemeIcons`, which is what `Smalltalk ui icons`, `iconNamed:`, Spec's icon providers and Commander use. 243 keys of the default pack are mapped to Material icons (`scripts/pharo-mapping.tsv`). They are drawn at the size the default pack uses for each key (14 pixels for `#accept`, 32 for `#info`), so rows and menus keep their layout.
- **Keys that stay as they were.** Every other key keeps the icon of the pack that was current before: check boxes, radio buttons, the small arrows, window buttons, halos, logos (Pharo, git, GitHub), the coloured circles and so on.
- **Colours.** The icons take the colour of the UI theme and are redrawn when the theme changes. The status keys keep fixed colours: tests (green, red, amber), errors (red), warnings (amber), information (blue), `breakpoint` (red) and `confirm` (green).
- **Uninstall.** `uninstall` makes the previous pack current again. Installing a second time keeps the first fallback, so `uninstall` always goes back to the pack you had before.
- **Open windows.** Pharo does not redraw open windows when the icon pack changes, so the new icons appear in windows opened afterwards.
- **Stored settings.** When the Settings of Pharo are saved while the Material pack is installed, they record the pack it replaced (svgPack, usually), not `materialRound`: a pack restored from stored settings is read from `<name>.zip` in `ThemeIcons destinationPath` or downloaded from pharo-icon-packs, where there is no `materialRound.zip`. To have the Material icons at every start, put `MaterialThemeIcons install` in a startup script.
- **Settings.** The Settings of Pharo only list the current pack and the zips in `ThemeIcons destinationPath` (`pharo-local/icon-packs`). That is "Appearance > Icon Set" in Pharo 12, and "Appearance > Icons Pack" (the Icons Pack Manager) in Pharo 15. `MaterialThemeIcons exportToIconPacks` writes the pack there as `materialRound.zip`, in the layout of [pharo-icon-packs](https://github.com/pharo-project/pharo-icon-packs) (`png-scale1.0`, `png-scale1.5`, `png-scale2.0`). It also writes the previous pack (`svgPack.zip`) if that file is missing, so both can be chosen there offline. A pack chosen in the Settings is a plain `ThemeIcons` read from the zip: a snapshot of the Material pack at export time, without the `material_` keys and without the redraw on theme changes. `install` over such a snapshot goes over the pack replaced before (or svgPack), not over the snapshot. The zip also holds the Apache License 2.0 of the icons (`LICENSE-material-icons`) and a `NOTICE` that says where they come from and how they were changed, next to the PNG directories; Pharo reads only the PNGs.

## What is in it

The icons are the 2127 that the family Material Icons Round supports in the metadata of fonts.google.com/icons, the page linked above. That is 2122 icons plus 5 legacy aliases still listed there: `face_unlock`, `info_outline`, `label_important_outline`, `lightbulb_outline` and `lock_outline`. Ten more icons have a rounded SVG in Google's repository but are left out, because fonts.google.com does not list them for Material Icons Round: `amp_stories`, `eco`, `emoji_flags`, `facebook`, `flourescent`, `label_outline`, `outbond`, `phone_in_talk`, `whatsapp` and `wifi_tethering_error_rounded`.

| category | icons | category | icons | category | icons |
|---|---:|---|---:|---|---:|
| action | 458 | editor | 122 | navigation | 57 |
| alert | 7 | file | 44 | notification | 69 |
| av | 125 | hardware | 78 | places | 83 |
| communication | 99 | home | 27 | search | 29 |
| content | 80 | image | 246 | social | 187 |
| device | 194 | maps | 209 | toggle | 13 |

- **Where they live.** Each category is a class of `MaterialIcons-Rounded` (`MaterialIconsRoundedAction`…). On its class side, `iconTable` lists name, codepoint and tags, and one method per icon, `icon_<name>`, answers its three PNGs in Base64.
- **Size.** 1.8 MB of PNGs (Tonel: 2.9 MB).
- **Load time.** Loading with Metacello from a local clone takes 2.5 s on Pharo 15 and 6.2 s on Pharo 12.
- **Image growth.** The image grows by about 5 MB on Pharo 15 and 7 MB on Pharo 12, once Monticello's caches of the loaded versions are flushed (`MCFileBasedRepository flushAllCaches`). Before the flush the growth is 8.5 and 11 MB.
- **Small sizes.** At 16 pixels, Material's 2-pixel strokes on a 24 grid become 1.33 pixels and look a little soft, and the icons made of small text (`10k`, `8mp`) cannot be read.

## Regenerating

`MaterialIcons-Rounded` and `MaterialIcons-ThemePack/MaterialThemeIconsArt.class.st` are generated by `scripts/generate.py`. Do not edit them: change the generator or `scripts/pharo-mapping.tsv`, then run it again.

```sh
python3 -m venv build/venv
build/venv/bin/pip install -r scripts/requirements.txt	# CairoSVG 2.9.1 and its dependencies, pinned
build/venv/bin/python -I scripts/generate.py			# writes src/ (about 1 minute)
build/venv/bin/python -I scripts/generate.py --check		# compares instead: "up to date"
```

- **What it does.** It downloads each icon's `24px.svg` from [google/material-design-icons](https://github.com/google/material-design-icons) at commit `3912baecc97388955ce39f5e26bfb786a70cbe48` (the last commit that changed `src/`) into `build/cache`, and checks each file against the SHA-256 in `scripts/manifest.json`. It then rasterizes the icons with CairoSVG at 16, 24 and 32 pixels and writes the Tonel files.
- **Reproducible.** It writes the PNGs itself (Python's zlib), so rerunning on the same inputs writes the same bytes. The committed data was made with cairo 1.18.6.
- **libcairo.** CairoSVG needs `libcairo.so.2`. Where the system has none, point `LD_LIBRARY_PATH` at the `lib` directory of a Pharo VM that ships cairo. The generator warns when the cairo version differs, since the pixels may then differ slightly.
- **The pin.** `scripts/manifest.json` records the upstream commit, the SHA-256 of the upstream `LICENSE` and `round_subset_sha256`. For each icon it holds the name, category, codepoint, version, tags and the SHA-256 of the SVG. `generate.py pin` rebuilds it from the live metadata, and only needs to be run to move the pin. The live metadata changes from one fetch to the next (its popularity counters), so the pin does not hash it as it comes: `round_subset_sha256` is the SHA-256 of what the pin takes from it, the icons of Material Icons Round sorted by name with their name, categories, codepoint, version and tags, as compact JSON with sorted keys. It can be recomputed from the manifest alone, and rerunning `pin` leaves the manifest as it is while Google changes none of those icons.
- **The UI mapping.** `scripts/pharo-mapping.tsv` maps Pharo icon keys to Material names. Each row gives the key's size in the default pack (svgPack) and an optional fixed colour.

## Licence

- **The code** of this repository is under the MIT licence (`LICENSE`).
- **The icons** are Material Icons by Google, under the Apache License 2.0 (`LICENSE-material-icons`, the `LICENSE` of google/material-design-icons at the pinned commit). The packages `MaterialIcons-Rounded` and the class `MaterialThemeIconsArt` hold PNG renderings of them, generated from the SVGs as described above; their class comments name the source and the licence. `NOTICE` gives the attribution. The zip written by `exportToIconPacks` carries the licence and a NOTICE of its own (`MaterialThemeIconsArt licenseText` and `noticeText`, generated). Google's README asks for no attribution but welcomes it.
