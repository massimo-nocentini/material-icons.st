"
I am an icon pack of Pharo's UI (a ThemeIcons, the class of `Smalltalk ui icons`) drawn with Material Icons Rounded:

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

Loading the package changes nothing: only `install` does. `install` keeps the current pack as my fallback (installing again keeps the first one), and `uninstall` makes it current again; both go through `ThemeIcons current:`, so the tools of Pharo 12 and 15 (Morphic, Spec, Commander) pick the new icons in the windows they open next. The icons are in the colour of the UI theme (`MaterialIcons rounded themeColor`), redrawn when the theme changes, except the status keys, of fixed colour: tests, errors, warnings, information, breakpoint and confirm (green, red, amber, blue, red and green; see `MaterialThemeIconsArt entries`).

Saving the Settings of Pharo while I am installed records my fallback as the icon pack, not me: a pack restored from stored settings is read from a zip named after it, which only `exportToIconPacks` writes, so a new image could not restore me. To get me at every start, put `MaterialThemeIcons install` in a startup script.

The Settings of Pharo (the Icon Set of Pharo 12, the Icons Pack Manager of Pharo 15) list the current pack and the zips of `ThemeIcons destinationPath`. `exportToIconPacks` writes me there as such a zip (`materialRound.zip`, the layout of pharo-project/pharo-icon-packs: png-scale1.0, png-scale1.5, png-scale2.0), and my fallback too when its zip is missing, so that both can be chosen there, offline. A pack chosen there is a plain ThemeIcons read from the zip: a snapshot of me, without the `material_` keys (the export leaves them out, even those already used) and without the redraw on theme changes. `install` and `exportToIconPacks` over such a snapshot take the pack that I replaced before (or the default pack, svgPack) as the fallback, not the snapshot. The zip holds the Apache License 2.0 of the icons and a NOTICE (`MaterialIconsRoundedCategory licenseText` and `MaterialThemeIconsArt noticeText`) next to the PNGs.

`uninstall` also empties the cache of `MaterialIcons rounded`, which holds the Forms I was drawn with.
"
Class {
	#name : 'MaterialThemeIcons',
	#superclass : 'ThemeIcons',
	#instVars : [
		'fallback',
		'color'
	],
	#classInstVars : [
		'lastFallback'
	],
	#category : 'MaterialIcons-ThemePack',
	#package : 'MaterialIcons-ThemePack'
}

{ #category : 'exporting' }
MaterialThemeIcons class >> exportPack: aThemeIcons to: aFileReference [
	"Write aThemeIcons as an icon pack zip that ThemeIcons loads: <name>/png-scale<scale>/<key>.png. A Material pack leaves out its keys material_<name>, added when they are used (so the zip does not depend on which were), and also gets <name>/LICENSE-material-icons and <name>/NOTICE, which ThemeIcons does not read (it reads the *.png files of the png-scale* directories), with LF line ends"

	| archive isMaterial |
	isMaterial := aThemeIcons isKindOf: self.
	archive := ZipArchive new.
	aThemeIcons iconsPerScale keys sorted do: [ :scale |
		| icons |
		icons := aThemeIcons iconsPerScale at: scale.
		icons keys sorted do: [ :key |
			(key = #notFound or: [
				 isMaterial and: [ key beginsWith: self materialPrefix ] ]) ifFalse: [
				archive
					addDeflateString: (self pngBytesOf: (icons at: key))
					as: aThemeIcons name , '/png-scale' , scale asFloat printString , '/' , key , '.png' ] ] ].
	isMaterial ifTrue: [
		archive
			addDeflateString: MaterialIconsRoundedCategory licenseText withUnixLineEndings
			as: aThemeIcons name , '/LICENSE-material-icons'.
		archive
			addDeflateString: MaterialThemeIconsArt noticeText withUnixLineEndings
			as: aThemeIcons name , '/NOTICE' ].
	aFileReference parent ensureCreateDirectory.
	aFileReference ensureDelete.
	aFileReference binaryWriteStreamDo: [ :stream | archive writeTo: stream ].
	archive close.
	^ aFileReference
]

{ #category : 'exporting' }
MaterialThemeIcons class >> exportToIconPacks [
	"Write the installed pack (or a new one, over the pack that install would take) as <ThemeIcons destinationPath>/materialRound.zip, and its fallback as <its name>.zip when that file is missing: the Settings of Pharo list them. Answer the zip of the pack"

	| pack file |
	pack := self packToExport.
	file := self exportPack: pack to: ThemeIcons destinationPath / (pack name , '.zip').
	pack fallback ifNotNil: [ :previous |
		previous name ifNotNil: [ :previousName |
			| previousFile |
			previousFile := ThemeIcons destinationPath / (previousName , '.zip').
			previousFile exists ifFalse: [ self exportPack: previous to: previousFile ] ] ].
	^ file
]

{ #category : 'exporting' }
MaterialThemeIcons class >> packToExport [
	"The installed pack, else a new one over the pack that install would go over (fallbackForInstall), so that the export of a snapshot chosen in the Settings is not built over that snapshot"

	^ self installed ifNil: [
		  self new
			  fallback: self fallbackForInstall;
			  build;
			  yourself ]
]

{ #category : 'installing' }
MaterialThemeIcons class >> install [
	"Make a Material pack the icons of the UI, in the colour of the UI theme. Answer it"

	<script>
	^ self installColor: nil
]

{ #category : 'installing' }
MaterialThemeIcons class >> installColor: aColorOrNil [
	"Make a Material pack the icons of the UI, in aColorOrNil (nil: the colour of the UI theme), over the current pack, or over the fallback of the installed one. Answer it"

	| previous pack |
	previous := self fallbackForInstall.
	lastFallback := previous.
	pack := self new
		        fallback: previous;
		        color: aColorOrNil;
		        build;
		        yourself.
	pack beCurrent.
	self subscribeToThemeChanges.
	^ pack
]

{ #category : 'accessing' }
MaterialThemeIcons class >> defaultPackName [
	"The name of Pharo's default icon pack"

	^ (ThemeIcons respondsTo: #defaultIconsPack)
		  ifTrue: [ ThemeIcons defaultIconsPack ]
		  ifFalse: [ 'svgPack' ]
]

{ #category : 'installing' }
MaterialThemeIcons class >> fallbackForInstall [
	"The pack that a new Material pack goes over: the fallback of the installed one; else the current pack, unless it is a snapshot of a Material pack read from materialRound.zip (chosen in the Settings): then the pack replaced by the last install, or the default pack"

	| current |
	self installed ifNotNil: [ :installed | ^ installed fallback ].
	current := ThemeIcons current.
	current name = self packName ifFalse: [ ^ current ].
	^ lastFallback ifNil: [
		  (ThemeIcons named: self defaultPackName)
			  loadIconsFromUrl;
			  yourself ]
]

{ #category : 'accessing' }
MaterialThemeIcons class >> installed [
	"The installed pack, or nil. ThemeIcons current is not used here: when no pack is current yet, it loads the default one (ThemeIcons class >> loadDefault, which may download svgPack.zip) as a side effect"

	| current |
	current := ThemeIcons classVarNamed: #Current.
	^ (current isKindOf: self)
		  ifTrue: [ current ]
		  ifFalse: [ nil ]
]

{ #category : 'testing' }
MaterialThemeIcons class >> isInstalled [

	^ self installed notNil
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

{ #category : 'exporting' }
MaterialThemeIcons class >> pngBytesOf: aForm [
	"The PNG of aForm, through a plain Form of depth 32"

	| plain |
	aForm unhibernate.
	plain := Form extent: aForm extent depth: 32.
	plain
		copyBits: aForm boundingBox
		from: aForm
		at: 0 @ 0
		clippingBox: plain boundingBox
		rule: Form over
		fillColor: nil.
	^ ByteArray streamContents: [ :stream |
		  PNGReadWriter putForm: plain onStream: stream ]
]

{ #category : 'event handling' }
MaterialThemeIcons class >> subscribeToThemeChanges [

	self unsubscribeFromThemeChanges.
	self codeSupportAnnouncer
		when: UIThemeChanged
		send: #themeChanged:
		to: self
]

{ #category : 'event handling' }
MaterialThemeIcons class >> themeChanged: anAnnouncement [
	"Redraw the installed pack in the colours of the new UI theme, dropping the Forms of the old colours from the cache of the icons. When another pack has been made current (in the Settings), stop listening"

	| pack |
	pack := self installed ifNil: [ ^ self unsubscribeFromThemeChanges ].
	pack followsTheme ifTrue: [
		pack provider flushCache.
		pack build.
		pack beCurrent ]
]

{ #category : 'installing' }
MaterialThemeIcons class >> uninstall [
	"Make the pack that the installed one replaced the icons of the UI again, and empty the cache of the Material icons, which holds the Forms it was drawn with"

	<script>
	self unsubscribeFromThemeChanges.
	self installed ifNotNil: [ :pack |
		pack fallback ifNotNil: [ :previous | previous beCurrent ].
		pack provider flushCache ]
]

{ #category : 'class initialization' }
MaterialThemeIcons class >> unload [
	"Before the class is removed (MaterialIcons-ThemePack unloaded): give the UI back the pack that the installed one replaced, so that ThemeIcons current is never an obsolete class"

	self uninstall
]

{ #category : 'event handling' }
MaterialThemeIcons class >> unsubscribeFromThemeChanges [

	self codeSupportAnnouncer unsubscribe: self
]

{ #category : 'settings' }
MaterialThemeIcons >> acceptSettings: aVisitor [
	"The stored settings record my fallback: a pack is restored from them as a plain ThemeIcons of that name, read from <name>.zip (ThemeIcons destinationPath) or downloaded from its url, and there is no materialRound.zip to download"

	^ (fallback ifNil: [ ThemeIcons named: self class defaultPackName ])
		  acceptSettings: aVisitor
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
MaterialThemeIcons >> addMaterialIcon: aSymbol [
	"Add material_<name> at every scale, if aSymbol is such a key of a Material icon. Answer whether it is"

	| prefix name tint |
	prefix := self class materialPrefix.
	(aSymbol isString and: [ aSymbol beginsWith: prefix ]) ifFalse: [ ^ false ].
	name := aSymbol allButFirst: prefix size.
	(self provider includesIcon: name) ifFalse: [ ^ false ].
	tint := self effectiveColor.
	MaterialIcons scales do: [ :each |
		(self iconsPerScale at: each asFloat ifAbsentPut: [ IdentityDictionary new ])
			at: aSymbol asSymbol
			put: (self provider formNamed: name scale: each color: tint) ].
	^ true
]

{ #category : 'accessing' }
MaterialThemeIcons >> allIconNames [
	"The keys of the pack, and material_<name> for every Material icon"

	| names |
	names := super allIconNames asSet.
	self provider iconNames do: [ :each |
		names add: (self class materialPrefix , each) asSymbol ].
	^ names asArray
]

{ #category : 'building' }
MaterialThemeIcons >> build [
	"Fill the pack: the icons of the fallback, the Material ones over the mapped keys"

	| newIconsPerScale |
	newIconsPerScale := Dictionary new.
	fallback ifNotNil: [
		fallback iconsPerScale keysAndValuesDo: [ :each :icons |
			newIconsPerScale at: each asFloat put: icons copy ] ].
	MaterialIcons scales do: [ :each |
		newIconsPerScale at: each asFloat ifAbsentPut: [ IdentityDictionary new ] ].
	MaterialThemeIconsArt entries do: [ :each |
		self addEntry: each to: newIconsPerScale ].
	iconsPerScale := newIconsPerScale.
	scale := 1.
	self flushFormSets
]

{ #category : 'accessing' }
MaterialThemeIcons >> color [
	"The colour of the icons, nil for that of the UI theme"

	^ color
]

{ #category : 'accessing' }
MaterialThemeIcons >> color: aColorOrNil [
	"Draw the icons (at the next build) in aColorOrNil, nil for that of the UI theme"

	color := aColorOrNil
]

{ #category : 'accessing' }
MaterialThemeIcons >> effectiveColor [

	^ color ifNil: [ self provider themeColor ]
]

{ #category : 'accessing' }
MaterialThemeIcons >> fallback [
	"The pack I replace: its icons are mine where I map no Material one"

	^ fallback
]

{ #category : 'accessing' }
MaterialThemeIcons >> fallback: aThemeIcons [

	fallback := aThemeIcons
]

{ #category : 'building' }
MaterialThemeIcons >> flushFormSets [
	"ThemeIcons keeps the FormSets it built, per key: forget them"

	formSetsCache := nil
]

{ #category : 'testing' }
MaterialThemeIcons >> followsTheme [

	^ color isNil
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
MaterialThemeIcons >> iconFormSetNamed: aSymbol ifNone: aBlock [
	"The keys material_<name> are added on first use"

	^ super iconFormSetNamed: aSymbol ifNone: [
		  (self addMaterialIcon: aSymbol)
			  ifTrue: [ super iconFormSetNamed: aSymbol ifNone: aBlock ]
			  ifFalse: [ aBlock value ] ]
]

{ #category : 'initialization' }
MaterialThemeIcons >> initialize [
	"The scale is set here: on Pharo 12 ThemeIcons>>icons reads the variable, nil in a new pack"

	super initialize.
	name := self class packName.
	scale := 1
]

{ #category : 'loading' }
MaterialThemeIcons >> loadIconsFromUrl [
	"My icons are in the image: build them"

	self build
]

{ #category : 'loading' }
MaterialThemeIcons >> loadIconsFromUrlUsingScale: aNumber [
	"My icons are in the image, at every scale: build them, whatever aNumber"

	self build
]

{ #category : 'accessing' }
MaterialThemeIcons >> materialIconNamed: aName [
	"The Material icon aName (its own name, as in MaterialIcons), in the colour of the pack"

	^ self iconNamed: (self class materialPrefix , aName) asSymbol
]

{ #category : 'accessing' }
MaterialThemeIcons >> provider [

	^ MaterialIcons rounded
]
