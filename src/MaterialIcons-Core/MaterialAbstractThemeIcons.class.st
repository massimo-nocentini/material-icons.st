"
I am the abstract root of the icon packs of Pharo's UI (`ThemeIcons`, the class of `Smalltalk ui icons`) drawn with Material icons: `MaterialThemeIcons` (package `MaterialIcons-ThemePack`, Material Icons Rounded) and `MaterialSymbolsThemeIcons` (package `MaterialSymbols-ThemePack`, Material Symbols Rounded). A pack of mine:

- maps the Pharo icon keys of the `entries` of its `artClass` (`#add`, `#delete`, `#refresh`, `#smallSave`, `#testGreen`...) to Material icons, at the size the default pack draws them;
- keeps the icon of the pack it replaces, its `fallback`, for every other key (check boxes, radio buttons, arrows, window buttons, halos, logos...);
- answers `<materialPrefix><name>` (`#material_arrow_back`, `#symbol_home`) with the icon of that name of its `provider`, decoded on first use.

```smalltalk
MaterialThemeIcons install.
	""Material icons in the UI: the windows opened from now on""
MaterialThemeIcons uninstall.
	""the previous pack again""
MaterialThemeIcons isInstalled.
MaterialThemeIcons installColor: Color gray.
	""a fixed colour instead of that of the UI theme""
MaterialThemeIcons installMonochrome.
	""the status keys too in the colour of the UI theme""
MaterialThemeIcons installColor: Color gray monochrome: true.
	""every key in gray""
MaterialThemeIcons exportToIconPacks.
	""list it in Settings > Appearance (see below)""
```

## Installing and uninstalling

Loading the packages changes nothing: only `install` does. `install` keeps the current pack as the fallback (installing again keeps the first one), and `uninstall` makes it current again; both go through `ThemeIcons current:`, so the tools of Pharo 12 and 15 (Morphic, Spec, Commander) pick the new icons in the windows they open next. Installing one Material pack while another is installed goes over the fallback of the other: the two replace each other, they do not pile up.

The icons are in the colour of the UI theme (`provider themeColor`), redrawn when the theme changes, except the status keys, of the fixed colours of the entries (tests, errors, warnings, information, the coloured dots, the buttons of inactive windows). A `monochrome` pack draws those in its colour too: the status keys keep their own shapes (a check, an X, a ! in a disc...), not their colours.

## The Settings of Pharo

Saving the Settings of Pharo while a pack of mine is installed records its fallback as the icon pack: a pack restored from stored settings is read from a zip named after it, which only `exportToIconPacks` writes, so a new image could not restore mine. To get it at every start, put its `install` in a startup script.

The Settings of Pharo (the Icon Set of Pharo 12, the Icons Pack Manager of Pharo 15) list the current pack and the zips of `ThemeIcons destinationPath`. `exportToIconPacks` writes the pack there as such a zip (`<packName>.zip`, the layout of `pharo-project/pharo-icon-packs`: `png-scale1.0`, `png-scale1.5`, `png-scale2.0`), and its fallback too when that zip is missing, so that both can be chosen there, offline.

A pack chosen there is a plain `ThemeIcons` read from the zip: a snapshot, without the keys of `materialPrefix` (the export leaves them out, even those already used) and without the redraw on theme changes. `install` and `exportToIconPacks` over such a snapshot take the pack replaced before (or the default pack, `svgPack`) as the fallback, not the snapshot.

The zip holds the Apache License 2.0 of the icons and a NOTICE (`licenseText` and `artClass noticeText`) next to the PNGs.

## The cache

`uninstall` also empties the cache of the provider, which holds the Forms the pack was drawn with.

## My subclasses

My subclasses define, on the class side, `packName`, `materialPrefix`, `providerStyle`, `artClass`, `licenseText`, `licenseFileName` and `unload` (Monticello sends it to the class it removes), and on the instance side `addEntry:to:`.
"
Class {
	#name : 'MaterialAbstractThemeIcons',
	#superclass : 'ThemeIcons',
	#instVars : [
		'fallback',
		'color',
		'monochrome'
	],
	#classInstVars : [
		'lastFallback'
	],
	#category : 'MaterialIcons-Core',
	#package : 'MaterialIcons-Core'
}

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> artClass [
	"The generated class whose `entries` map the Pharo keys, and whose `noticeText` goes into the exported zip"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> defaultPackName [
	"The name of Pharo's default icon pack"

	^ (ThemeIcons respondsTo: #defaultIconsPack)
		  ifTrue: [ ThemeIcons defaultIconsPack ]
		  ifFalse: [ 'svgPack' ]
]

{ #category : 'exporting' }
MaterialAbstractThemeIcons class >> exportPack: aThemeIcons to: aFileReference [
	"Write aThemeIcons as an icon pack zip that ThemeIcons loads: <name>/png-scale<scale>/<key>.png. A Material pack leaves out its keys <materialPrefix><name>, added when they are used (so the zip does not depend on which were), and also gets <name>/<licenseFileName> and <name>/NOTICE, which ThemeIcons does not read (it reads the *.png files of the png-scale* directories), with LF line ends"

	| archive material |
	material := (aThemeIcons isKindOf: MaterialAbstractThemeIcons)
		            ifTrue: [ aThemeIcons class ]
		            ifFalse: [ nil ].
	archive := ZipArchive new.
	aThemeIcons iconsPerScale keys sorted do: [ :scale |
		| icons |
		icons := aThemeIcons iconsPerScale at: scale.
		icons keys sorted do: [ :key |
			(key = #notFound or: [
				 material notNil and: [ key beginsWith: material materialPrefix ] ]) ifFalse: [
				archive
					addDeflateString: (self pngBytesOf: (icons at: key))
					as: aThemeIcons name , '/png-scale' , scale asFloat printString , '/' , key , '.png' ] ] ].
	material ifNotNil: [
		archive
			addDeflateString: material licenseText withUnixLineEndings
			as: aThemeIcons name , '/' , material licenseFileName.
		archive
			addDeflateString: material artClass noticeText withUnixLineEndings
			as: aThemeIcons name , '/NOTICE' ].
	aFileReference parent ensureCreateDirectory.
	aFileReference ensureDelete.
	aFileReference binaryWriteStreamDo: [ :stream | archive writeTo: stream ].
	archive close.
	^ aFileReference
]

{ #category : 'exporting' }
MaterialAbstractThemeIcons class >> exportToIconPacks [
	"Write the installed pack (or a new one, over the pack that install would take) as <ThemeIcons destinationPath>/<packName>.zip, and its fallback as <its name>.zip when that file is missing: the Settings of Pharo list them. Answer the zip of the pack"

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

{ #category : 'installing' }
MaterialAbstractThemeIcons class >> fallbackForInstall [
	"The pack that a new pack of mine goes over: the fallback of the installed one, or of another installed Material pack; else the current pack, unless it is a snapshot of a Material pack read from its zip (chosen in the Settings): then the pack replaced by the last install, or the default pack"

	| current |
	self installed ifNotNil: [ :installed | ^ installed fallback ].
	current := ThemeIcons current.
	((current isKindOf: MaterialAbstractThemeIcons) and: [
		 current fallback notNil ]) ifTrue: [ ^ current fallback ].
	(self materialPackNames includes: current name) ifFalse: [ ^ current ].
	^ lastFallback ifNil: [
		  (ThemeIcons named: self defaultPackName)
			  loadIconsFromUrl;
			  yourself ]
]

{ #category : 'installing' }
MaterialAbstractThemeIcons class >> install [
	"Make a pack of mine the icons of the UI, in the colour of the UI theme. Answer it"

	^ self installColor: nil
]

{ #category : 'installing' }
MaterialAbstractThemeIcons class >> installColor: aColorOrNil [
	"Make a pack of mine the icons of the UI, in aColorOrNil (nil: the colour of the UI theme), the status keys in their fixed colours, over the current pack, or over the fallback of the installed Material pack. Answer it"

	^ self installColor: aColorOrNil monochrome: false
]

{ #category : 'installing' }
MaterialAbstractThemeIcons class >> installColor: aColorOrNil monochrome: aBoolean [
	"Make a pack of mine the icons of the UI, in aColorOrNil (nil: the colour of the UI theme), over the current pack, or over the fallback of the installed Material pack; when aBoolean is true the status keys too are in that colour, instead of their fixed colours. Answer it"

	| previous pack |
	previous := self fallbackForInstall.
	lastFallback := previous.
	pack := self new
		        fallback: previous;
		        color: aColorOrNil;
		        monochrome: aBoolean;
		        build;
		        yourself.
	pack beCurrent.
	self subscribeToThemeChanges.
	^ pack
]

{ #category : 'installing' }
MaterialAbstractThemeIcons class >> installMonochrome [
	"Make a pack of mine the icons of the UI, every key in the colour of the UI theme, the status keys too. Answer it"

	^ self installColor: nil monochrome: true
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> installed [
	"The installed pack of mine, or nil. ThemeIcons current is not used here: when no pack is current yet, it loads the default one (ThemeIcons class >> loadDefault, which may download svgPack.zip) as a side effect"

	| current |
	current := ThemeIcons classVarNamed: #Current.
	^ (current isKindOf: self)
		  ifTrue: [ current ]
		  ifFalse: [ nil ]
]

{ #category : 'testing' }
MaterialAbstractThemeIcons class >> isInstalled [

	^ self installed notNil
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> licenseFileName [
	"The name of the file of the licence of the icons in the exported zip"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> licenseText [
	"The licence of the icons, the Apache License 2.0, as the generated data holds it"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> materialPackNames [
	"The names of the Material packs in the image: a current pack of such a name that is not one of mine is a snapshot read from a zip"

	^ (MaterialAbstractThemeIcons allSubclasses collect: [ :each | each packName ]) asSet
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> materialPrefix [
	"The prefix of the keys of the Material icons by their own names"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> packName [

	^ self subclassResponsibility
]

{ #category : 'exporting' }
MaterialAbstractThemeIcons class >> packToExport [
	"The installed pack, else a new one over the pack that install would go over (fallbackForInstall), so that the export of a snapshot chosen in the Settings is not built over that snapshot"

	^ self installed ifNil: [
		  self new
			  fallback: self fallbackForInstall;
			  build;
			  yourself ]
]

{ #category : 'exporting' }
MaterialAbstractThemeIcons class >> pngBytesOf: aForm [
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

{ #category : 'accessing' }
MaterialAbstractThemeIcons class >> providerStyle [
	"The style of the MaterialIcons my packs are drawn with"

	^ self subclassResponsibility
]

{ #category : 'event handling' }
MaterialAbstractThemeIcons class >> subscribeToThemeChanges [

	self unsubscribeFromThemeChanges.
	self codeSupportAnnouncer
		when: UIThemeChanged
		send: #themeChanged:
		to: self
]

{ #category : 'event handling' }
MaterialAbstractThemeIcons class >> themeChanged: anAnnouncement [
	"Redraw the installed pack in the colours of the new UI theme, dropping the Forms of the old colours from the cache of the icons. When another pack has been made current (in the Settings), stop listening"

	| pack |
	pack := self installed ifNil: [ ^ self unsubscribeFromThemeChanges ].
	pack followsTheme ifTrue: [
		pack provider flushCache.
		pack build.
		pack beCurrent ]
]

{ #category : 'installing' }
MaterialAbstractThemeIcons class >> uninstall [
	"Make the pack that the installed one replaced the icons of the UI again, and empty the cache of the Material icons, which holds the Forms it was drawn with"

	self unsubscribeFromThemeChanges.
	self installed ifNotNil: [ :pack |
		pack fallback ifNotNil: [ :previous | previous beCurrent ].
		pack provider flushCache ]
]

{ #category : 'event handling' }
MaterialAbstractThemeIcons class >> unsubscribeFromThemeChanges [

	self codeSupportAnnouncer unsubscribe: self
]

{ #category : 'settings' }
MaterialAbstractThemeIcons >> acceptSettings: aVisitor [
	"The stored settings record my fallback: a pack is restored from them as a plain ThemeIcons of that name, read from <name>.zip (ThemeIcons destinationPath) or downloaded from its url, and there is no zip of mine to download"

	^ (fallback ifNil: [ ThemeIcons named: self class defaultPackName ])
		  acceptSettings: aVisitor
]

{ #category : 'private' }
MaterialAbstractThemeIcons >> addEntry: anEntry to: aDictionary [
	"Put the Forms of anEntry, one of the entries of my artClass, at its key in aDictionary, for every scale"

	self subclassResponsibility
]

{ #category : 'private' }
MaterialAbstractThemeIcons >> addMaterialIcon: aSymbol [
	"Add <materialPrefix><name> at every scale, if aSymbol is such a key of an icon of my provider. Answer whether it is"

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
MaterialAbstractThemeIcons >> allIconNames [
	"The keys of the pack, and <materialPrefix><name> for every icon of my provider"

	| names |
	names := super allIconNames asSet.
	self provider iconNames do: [ :each |
		names add: (self class materialPrefix , each) asSymbol ].
	^ names asArray
]

{ #category : 'building' }
MaterialAbstractThemeIcons >> build [
	"Fill the pack: the icons of the fallback, the Material ones over the mapped keys"

	| newIconsPerScale |
	newIconsPerScale := Dictionary new.
	fallback ifNotNil: [
		fallback iconsPerScale keysAndValuesDo: [ :each :icons |
			newIconsPerScale at: each asFloat put: icons copy ] ].
	MaterialIcons scales do: [ :each |
		newIconsPerScale at: each asFloat ifAbsentPut: [ IdentityDictionary new ] ].
	self class artClass entries do: [ :each |
		self addEntry: each to: newIconsPerScale ].
	iconsPerScale := newIconsPerScale.
	scale := 1.
	self flushFormSets
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> color [
	"The colour of the icons, nil for that of the UI theme"

	^ color
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> color: aColorOrNil [
	"Draw the icons (at the next build) in aColorOrNil, nil for that of the UI theme"

	color := aColorOrNil
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> colorOfEntry: aHexStringOrNil [
	"The colour of an entry of my artClass whose fixed colour is aHexStringOrNil (RRGGBB, nil for none): that colour, unless I am monochrome or it has none, and then mine"

	^ (monochrome or: [ aHexStringOrNil isNil ])
		  ifTrue: [ self effectiveColor ]
		  ifFalse: [ Color fromHexString: aHexStringOrNil ]
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> effectiveColor [

	^ color ifNil: [ self provider themeColor ]
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> fallback [
	"The pack I replace: its icons are mine where I map no Material one"

	^ fallback
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> fallback: aThemeIcons [

	fallback := aThemeIcons
]

{ #category : 'building' }
MaterialAbstractThemeIcons >> flushFormSets [
	"ThemeIcons keeps the FormSets it built, per key: forget them"

	formSetsCache := nil
]

{ #category : 'testing' }
MaterialAbstractThemeIcons >> followsTheme [

	^ color isNil
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> iconFormSetNamed: aSymbol ifNone: aBlock [
	"The keys <materialPrefix><name> are added on first use"

	^ super iconFormSetNamed: aSymbol ifNone: [
		  (self addMaterialIcon: aSymbol)
			  ifTrue: [ super iconFormSetNamed: aSymbol ifNone: aBlock ]
			  ifFalse: [ aBlock value ] ]
]

{ #category : 'initialization' }
MaterialAbstractThemeIcons >> initialize [
	"The scale is set here: on Pharo 12 ThemeIcons>>icons reads the variable, nil in a new pack"

	super initialize.
	name := self class packName.
	scale := 1.
	monochrome := false
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> monochrome [
	"Whether the status keys are in my colour too, instead of their fixed colours"

	^ monochrome
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> monochrome: aBoolean [
	"Draw the status keys (at the next build) in my colour too when aBoolean is true, in their fixed colours when false"

	monochrome := aBoolean
]

{ #category : 'loading' }
MaterialAbstractThemeIcons >> loadIconsFromUrl [
	"My icons are in the image: build them"

	self build
]

{ #category : 'loading' }
MaterialAbstractThemeIcons >> loadIconsFromUrlUsingScale: aNumber [
	"My icons are in the image, at every scale: build them, whatever aNumber"

	self build
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> provider [
	"The Material icons I am drawn with"

	^ MaterialIcons style: self class providerStyle
]

{ #category : 'accessing' }
MaterialAbstractThemeIcons >> providerIconNamed: aName [
	"The icon aName of my provider (its own name, as in MaterialIcons), in the colour of the pack"

	^ self iconNamed: (self class materialPrefix , aName) asSymbol
]
