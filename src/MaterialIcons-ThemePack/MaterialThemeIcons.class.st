"
I am an icon pack of Pharo's UI (a ThemeIcons, the class of `Smalltalk ui icons`) drawn with Material Icons Rounded (MaterialAbstractThemeIcons holds the mechanism, shared with MaterialSymbolsThemeIcons):

- the 243 Pharo icon keys of `MaterialThemeIconsArt entries` (`#add`, `#delete`, `#refresh`, `#smallSave`, `#testGreen`...) are Material icons, at the size the default pack draws them;
- every other key (check boxes, radio buttons, arrows, window buttons, halos, logos...) keeps the icon of the pack I replace, my `fallback`;
- `material_<name>`, for every Material icon (`#material_arrow_back`, `#material_10k`), is that icon, decoded on first use: `Smalltalk ui icons iconNamed: #material_cloud_sync`.

```
MaterialThemeIcons install.		""Material icons in the UI: the windows opened from now on""
MaterialThemeIcons uninstall.	""the previous pack again""
MaterialThemeIcons isInstalled.
MaterialThemeIcons installColor: Color gray.	""a fixed colour instead of that of the UI theme""
MaterialThemeIcons exportToIconPacks.	""list me in Settings > Appearance (see below)""
```

Loading the package changes nothing: only `install` does. `install` keeps the current pack as my fallback (installing again keeps the first one, and installing over MaterialSymbolsThemeIcons takes its fallback), and `uninstall` makes it current again; both go through `ThemeIcons current:`, so the tools of Pharo 12 and 15 (Morphic, Spec, Commander) pick the new icons in the windows they open next. The icons are in the colour of the UI theme (`MaterialIcons rounded themeColor`), redrawn when the theme changes, except the status keys, of fixed colour: tests, errors, warnings, information, breakpoint and confirm (green, red, amber, blue, red and green; see `MaterialThemeIconsArt entries`).

Saving the Settings of Pharo while I am installed records my fallback as the icon pack, not me: a pack restored from stored settings is read from a zip named after it, which only `exportToIconPacks` writes, so a new image could not restore me. To get me at every start, put `MaterialThemeIcons install` in a startup script.

The Settings of Pharo (the Icon Set of Pharo 12, the Icons Pack Manager of Pharo 15) list the current pack and the zips of `ThemeIcons destinationPath`. `exportToIconPacks` writes me there as such a zip (`materialRound.zip`, the layout of pharo-project/pharo-icon-packs: png-scale1.0, png-scale1.5, png-scale2.0), and my fallback too when its zip is missing, so that both can be chosen there, offline. A pack chosen there is a plain ThemeIcons read from the zip: a snapshot of me, without the `material_` keys (the export leaves them out, even those already used) and without the redraw on theme changes. `install` and `exportToIconPacks` over such a snapshot take the pack that I replaced before (or the default pack, svgPack) as the fallback, not the snapshot. The zip holds the Apache License 2.0 of the icons and a NOTICE (`MaterialIconsRoundedCategory licenseText` and `MaterialThemeIconsArt noticeText`) next to the PNGs.

`uninstall` also empties the cache of `MaterialIcons rounded`, which holds the Forms I was drawn with.
"
Class {
	#name : 'MaterialThemeIcons',
	#superclass : 'MaterialAbstractThemeIcons',
	#category : 'MaterialIcons-ThemePack',
	#package : 'MaterialIcons-ThemePack'
}

{ #category : 'accessing' }
MaterialThemeIcons class >> artClass [

	^ MaterialThemeIconsArt
]

{ #category : 'installing' }
MaterialThemeIcons class >> install [
	"Make a Material pack the icons of the UI, in the colour of the UI theme. Answer it"

	<script>
	^ super install
]

{ #category : 'accessing' }
MaterialThemeIcons class >> licenseFileName [

	^ 'LICENSE-material-icons'
]

{ #category : 'accessing' }
MaterialThemeIcons class >> licenseText [

	^ MaterialIconsRoundedCategory licenseText
]

{ #category : 'accessing' }
MaterialThemeIcons class >> materialPrefix [
	"The prefix of the keys of the Material icons by their own names"

	^ 'material_'
]

{ #category : 'accessing' }
MaterialThemeIcons class >> packName [

	^ 'materialRound'
]

{ #category : 'accessing' }
MaterialThemeIcons class >> providerStyle [

	^ #rounded
]

{ #category : 'installing' }
MaterialThemeIcons class >> uninstall [
	"Make the pack that the installed one replaced the icons of the UI again, and empty the cache of the Material icons, which holds the Forms it was drawn with"

	<script>
	super uninstall
]

{ #category : 'class initialization' }
MaterialThemeIcons class >> unload [
	"Before the class is removed (MaterialIcons-ThemePack unloaded): give the UI back the pack that the installed one replaced, so that ThemeIcons current is never an obsolete class"

	self uninstall
]

{ #category : 'private' }
MaterialThemeIcons >> addEntry: anEntry to: aDictionary [
	"anEntry: #( key materialName side colourOrNil ), from MaterialThemeIconsArt entries"

	| key material side tint |
	key := anEntry first.
	material := anEntry second.
	side := anEntry third.
	tint := anEntry fourth
		        ifNil: [ self effectiveColor ]
		        ifNotNil: [ :hex | Color fromHexString: hex ].
	MaterialIcons scales doWithIndex: [ :each :index |
		(aDictionary at: each asFloat)
			at: key
			put: (self formOf: material side: side scaleIndex: index color: tint) ]
]

{ #category : 'private' }
MaterialThemeIcons >> formOf: aMaterialName side: anInteger scaleIndex: anIndex color: aColor [

	anInteger = MaterialIcons pixelSizes first ifTrue: [
		^ self provider
			  formNamed: aMaterialName
			  scale: (MaterialIcons scales at: anIndex)
			  color: aColor ].
	^ MaterialIcons
		  tint: (MaterialIcons formFromBase64PNG: ((MaterialThemeIconsArt perform:
					     ('art_' , aMaterialName , '_' , anInteger printString) asSymbol)
				    at: anIndex))
		  color: aColor
]

{ #category : 'accessing' }
MaterialThemeIcons >> materialIconNamed: aName [
	"The Material icon aName (its own name, as in MaterialIcons), in the colour of the pack"

	^ self providerIconNamed: aName
]
