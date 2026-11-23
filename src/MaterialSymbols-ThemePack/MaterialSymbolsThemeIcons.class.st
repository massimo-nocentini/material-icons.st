"
I am an icon pack of Pharo's UI (a ThemeIcons, the class of `Smalltalk ui icons`) drawn with Material Symbols Rounded, as MaterialThemeIcons is with Material Icons Rounded (MaterialAbstractThemeIcons holds the mechanism):

- the Pharo icon keys of `MaterialSymbolsThemeIconsArt entries` (scripts/symbols-mapping.tsv: `#add`, `#delete`, `#refresh`, `#smallSave`, `#testGreen`...) are Material Symbols, each in its own fill (outlined or filled) and grade (0, or 200 for heavier strokes of the same size, closer to the weight of the default pack), drawn at the sizes the default pack (svgPack) draws that key at the scales 1, 1.5 and 2, so that rows and menus keep their layout;
- every other key keeps the icon of the pack I replace, my `fallback`;
- `symbol_<name>`, for every icon of Material Symbols Rounded (`#symbol_home`, `#symbol_10k`), is that icon in its default variant, decoded on first use: `Smalltalk ui icons iconNamed: #symbol_cloud_sync`.

```
MaterialSymbolsThemeIcons install.		""Material Symbols in the UI: the windows opened from now on""
MaterialSymbolsThemeIcons uninstall.	""the previous pack again""
MaterialSymbolsThemeIcons isInstalled.
MaterialSymbolsThemeIcons installColor: Color gray.	""a fixed colour instead of that of the UI theme""
MaterialSymbolsThemeIcons installMonochrome.	""the status keys too in the colour of the UI theme""
MaterialSymbolsThemeIcons installColor: Color gray monochrome: true.	""every key in gray""
MaterialSymbolsThemeIcons exportToIconPacks.	""materialSymbolsRounded.zip, for the Settings""
```

The icons are in the colour of the UI theme, redrawn when the theme changes, except the status keys, of the fixed colours of the mapping (tests, errors, warnings, information...); a `monochrome` pack draws them in its colour too, so that only their shapes tell them apart. Installing me while MaterialThemeIcons is installed goes over its fallback, and the other way round: the two packs replace each other. Everything else (uninstall, stored settings, the zip for the Settings, with LICENSE-material-symbols and NOTICE) is as described in MaterialAbstractThemeIcons.

My pixels are those of MaterialSymbolsThemeIconsArt: I need the package MaterialSymbols-Rounded only for the keys `symbol_<name>` and the colour of the theme, and neither the masters nor the filled variant.
"
Class {
	#name : 'MaterialSymbolsThemeIcons',
	#superclass : 'MaterialAbstractThemeIcons',
	#category : 'MaterialSymbols-ThemePack',
	#package : 'MaterialSymbols-ThemePack'
}

{ #category : 'accessing' }
MaterialSymbolsThemeIcons class >> artClass [

	^ MaterialSymbolsThemeIconsArt
]

{ #category : 'installing' }
MaterialSymbolsThemeIcons class >> install [
	"Make a Material Symbols pack the icons of the UI, in the colour of the UI theme. Answer it"

	<script>
	^ super install
]

{ #category : 'accessing' }
MaterialSymbolsThemeIcons class >> licenseFileName [

	^ 'LICENSE-material-symbols'
]

{ #category : 'accessing' }
MaterialSymbolsThemeIcons class >> licenseText [

	^ MaterialSymbolsRoundedCategory licenseText
]

{ #category : 'accessing' }
MaterialSymbolsThemeIcons class >> materialPrefix [
	"The prefix of the keys of the Material Symbols by their own names"

	^ 'symbol_'
]

{ #category : 'accessing' }
MaterialSymbolsThemeIcons class >> packName [

	^ 'materialSymbolsRounded'
]

{ #category : 'accessing' }
MaterialSymbolsThemeIcons class >> providerStyle [

	^ #symbolsRounded
]

{ #category : 'installing' }
MaterialSymbolsThemeIcons class >> uninstall [
	"Make the pack that the installed one replaced the icons of the UI again, and empty the cache of the Material Symbols, which holds the Forms it was drawn with"

	<script>
	super uninstall
]

{ #category : 'class initialization' }
MaterialSymbolsThemeIcons class >> unload [
	"Before the class is removed (MaterialSymbols-ThemePack unloaded): give the UI back the pack that the installed one replaced, so that ThemeIcons current is never an obsolete class"

	self uninstall
]

{ #category : 'private' }
MaterialSymbolsThemeIcons >> addEntry: anEntry to: aDictionary [
	"anEntry: #( key symbolName fill grade colourOrNil artSelector ), from MaterialSymbolsThemeIconsArt entries: the art method answers the PNGs at the scales 1, 1.5 and 2"

	| pngs tint |
	pngs := MaterialSymbolsThemeIconsArt perform: anEntry sixth.
	tint := self colorOfEntry: anEntry fifth.
	MaterialIcons scales doWithIndex: [ :each :index |
		(aDictionary at: each asFloat)
			at: anEntry first
			put: (MaterialIcons
					 tint: (MaterialIcons formFromBase64PNG: (pngs at: index))
					 color: tint) ]
]

{ #category : 'accessing' }
MaterialSymbolsThemeIcons >> symbolIconNamed: aName [
	"The Material Symbol aName (its own name, as in MaterialIcons symbolsRounded), in the colour of the pack"

	^ self providerIconNamed: aName
]
