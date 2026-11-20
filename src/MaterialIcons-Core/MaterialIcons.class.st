"
I give the Material icons of one style as Forms: `MaterialIcons rounded` answers those of Material Icons Rounded (fonts.google.com/icons, icon.set=Material+Icons, icon.style=Rounded), by their Material names.

```
MaterialIcons rounded iconNamed: #home.				""a 16x16 Form""
MaterialIcons rounded formNamed: #arrow_back scale: 2.		""32x32""
MaterialIcons rounded formSetNamed: #search.			""a FormSet for HiDPI: 16, 24 and 32 pixels""
MaterialIcons rounded formNamed: #delete scale: 1 color: Color red.
MaterialIcons rounded iconNamed: #'10k'.			""names that begin with a digit are quoted Symbols""

MaterialIcons rounded iconNames.			""the 2127 names, sorted""
MaterialIcons rounded categories.			""#('action' 'alert' 'av' ...)""
MaterialIcons rounded iconNamesInCategory: 'navigation'.
MaterialIcons rounded search: 'trash'.			""by name and by tag""
MaterialIcons rounded entryNamed: #home.		""a MaterialIcon: category, codepoint, tags""
```

The icons are drawn in my `color`: by default (nil) the text colour of the current UI theme, so that they read on a light and on a dark theme alike; `color: aColor` fixes it, `color: nil` follows the theme again.

The scales are 1, 1.5 and 2 (16, 24 and 32 pixels), those of the Pharo icon packs. A FormSet holds the three, so that a canvas scaled for HiDPI picks the sharp one.

I decode an icon the first time it is asked for, and keep its Form, per name, scale and colour, until `flushCache` or the next start of the image. My index of names is built at the first use and rebuilt by `MaterialIcons reset`.

My icons do not change the icons of Pharo's UI: `MaterialThemeIcons install` (package MaterialIcons-ThemePack) does.
"
Class {
	#name : 'MaterialIcons',
	#superclass : 'Object',
	#instVars : [
		'style',
		'entries',
		'cache',
		'cacheSession',
		'color'
	],
	#classVars : [
		'Instances'
	],
	#category : 'MaterialIcons-Core',
	#package : 'MaterialIcons-Core'
}

{ #category : 'converting' }
MaterialIcons class >> formFromBase64PNG: aString [
	"Answer the Form of a PNG in Base64, of depth 32"

	| form |
	form := PNGReadWriter formFromStream: aString base64Decoded readStream.
	^ form depth = 32
		  ifTrue: [ form ]
		  ifFalse: [ form asFormOfDepth: 32 ]
]

{ #category : 'accessing' }
MaterialIcons class >> pixelSizes [
	"The sides of the icons, in pixels, at my scales"

	^ #( 16 24 32 )
]

{ #category : 'class initialization' }
MaterialIcons class >> reset [
	"Forget the instances, their caches and their indexes (after loading other icons)"

	<script>
	Instances := nil
]

{ #category : 'accessing' }
MaterialIcons class >> rounded [
	"The icons of Material Icons Rounded"

	^ self style: #rounded
]

{ #category : 'accessing' }
MaterialIcons class >> scales [
	"The scales at which the icons are drawn: 16, 24 and 32 pixels"

	^ #( 1 1.5 2 )
]

{ #category : 'accessing' }
MaterialIcons class >> style: aSymbol [
	"The icons of the style aSymbol, one instance per style"

	^ (Instances ifNil: [ Instances := Dictionary new ])
		  at: aSymbol
		  ifAbsentPut: [ self new setStyle: aSymbol ]
]

{ #category : 'accessing' }
MaterialIcons class >> styles [
	"The styles of the icons in the image"

	^ MaterialIconsCategory styles
]

{ #category : 'converting' }
MaterialIcons class >> tint: aForm color: aColor [
	"Answer a new Form of the shape of aForm (its alpha, aForm being of depth 32) in aColor. The pixels of a Form of depth 32 are ARGB, not premultiplied"

	| result source target rgb alpha |
	aForm unhibernate.
	result := Form extent: aForm extent depth: 32.
	rgb := (aColor pixelValueForDepth: 32) bitAnd: 16rFFFFFF.
	alpha := aColor alpha.
	source := aForm bits.
	target := result bits.
	1 to: source size do: [ :index |
		| a |
		a := (source at: index) bitShift: -24.
		alpha < 1 ifTrue: [ a := (a * alpha) rounded ].
		a = 0 ifFalse: [ target at: index put: ((a bitShift: 24) bitOr: rgb) ] ].
	^ result
]

{ #category : 'private' }
MaterialIcons >> buildEntries [

	| dictionary |
	dictionary := IdentityDictionary new.
	self categoryClasses do: [ :class |
		class iconTable do: [ :row |
			dictionary
				at: row first asSymbol
				put: (MaterialIcon
						 name: row first asSymbol
						 category: class materialCategory
						 codepoint: row second
						 tags: row third
						 source: class) ] ].
	^ dictionary
]

{ #category : 'caching' }
MaterialIcons >> cacheSize [
	"The number of Forms in my cache"

	^ cache ifNil: [ 0 ] ifNotNil: [ cache size ]
]

{ #category : 'private' }
MaterialIcons >> cached: aKey ifAbsentPut: aBlock [
	"The cache is that of the current session of the image: Forms are rebuilt after a restart"

	cacheSession == Smalltalk session ifFalse: [
		cache := Dictionary new.
		cacheSession := Smalltalk session ].
	^ cache at: aKey ifAbsentPut: aBlock
]

{ #category : 'accessing' }
MaterialIcons >> categories [
	"The names of the Material categories, sorted"

	^ self categoryClasses collect: [ :each | each materialCategory ]
]

{ #category : 'accessing' }
MaterialIcons >> categoryClasses [
	"The classes that hold my icons, one per category"

	^ MaterialIconsCategory categoriesOfStyle: style
]

{ #category : 'accessing' }
MaterialIcons >> categoryOf: aName [

	^ (self entryNamed: aName) category
]

{ #category : 'accessing' }
MaterialIcons >> codepointOf: aName [
	"The codepoint of the glyph of the icon in the Material Icons fonts"

	^ (self entryNamed: aName) codepoint
]

{ #category : 'accessing' }
MaterialIcons >> color [
	"The colour of my icons: the one set by color:, else the text colour of the current UI theme"

	^ color ifNil: [ self themeColor ]
]

{ #category : 'accessing' }
MaterialIcons >> color: aColorOrNil [
	"Draw my icons in aColorOrNil, or, if nil, in the text colour of the current UI theme"

	color := aColorOrNil
]

{ #category : 'accessing' }
MaterialIcons >> entries [
	"A Dictionary from the name of each icon (a Symbol) to its MaterialIcon"

	^ entries ifNil: [ entries := self buildEntries ]
]

{ #category : 'accessing' }
MaterialIcons >> entryNamed: aName [

	^ self
		  entryNamed: aName
		  ifAbsent: [ KeyNotFound signalFor: aName asSymbol ]
]

{ #category : 'accessing' }
MaterialIcons >> entryNamed: aName ifAbsent: aBlock [

	^ self entries at: aName asSymbol ifAbsent: aBlock
]

{ #category : 'caching' }
MaterialIcons >> flushCache [
	"Forget the Forms decoded so far"

	cache := nil.
	cacheSession := nil
]

{ #category : 'testing' }
MaterialIcons >> followsTheme [
	"Whether my icons take the text colour of the UI theme"

	^ color isNil
]

{ #category : 'forms' }
MaterialIcons >> formNamed: aName scale: aScale [
	"The icon aName at aScale (1, 1.5 or 2: 16, 24 or 32 pixels) in my colour"

	^ self formNamed: aName scale: aScale color: self color
]

{ #category : 'forms' }
MaterialIcons >> formNamed: aName scale: aScale color: aColor [
	"The icon aName at aScale (1, 1.5 or 2: 16, 24 or 32 pixels) in aColor"

	| mask |
	mask := self maskNamed: aName scale: aScale.
	^ self
		  cached: {
				  aName asSymbol.
				  aScale asFloat.
				  aColor }
		  ifAbsentPut: [ self class tint: mask color: aColor ]
]

{ #category : 'forms' }
MaterialIcons >> formSetNamed: aName [
	"A FormSet of the icon aName in my colour, 16x16 with the Forms of the three scales, for HiDPI"

	^ self formSetNamed: aName color: self color
]

{ #category : 'forms' }
MaterialIcons >> formSetNamed: aName color: aColor [
	"A FormSet of the icon aName in aColor, 16x16 with the Forms of the three scales, for HiDPI"

	^ FormSet
		  extent: self class pixelSizes first asPoint
		  depth: 32
		  forms: (self class scales collect: [ :each |
				   self formNamed: aName scale: each color: aColor ])
]

{ #category : 'forms' }
MaterialIcons >> iconNamed: aName [
	"The icon aName, 16x16, in my colour"

	^ self formNamed: aName scale: 1
]

{ #category : 'forms' }
MaterialIcons >> iconNamed: aName ifNone: aBlock [

	^ (self includesIcon: aName)
		  ifTrue: [ self iconNamed: aName ]
		  ifFalse: aBlock
]

{ #category : 'accessing' }
MaterialIcons >> iconNames [
	"The names of all my icons, Symbols, sorted"

	^ self entries keys asArray sort
]

{ #category : 'accessing' }
MaterialIcons >> iconNamesInCategory: aString [

	^ ((self entries select: [ :each | each category = aString ]) keys)
		  asArray sort
]

{ #category : 'testing' }
MaterialIcons >> includesIcon: aName [

	^ (aName isString or: [ aName isSymbol ]) and: [
		  self entries includesKey: aName asSymbol ]
]

{ #category : 'private' }
MaterialIcons >> indexOfScale: aNumber [

	^ self class scales
		  indexOf: aNumber
		  ifAbsent: [
			  self error:
				  'The Material icons have the scales 1, 1.5 and 2, not '
				  , aNumber printString ]
]

{ #category : 'forms' }
MaterialIcons >> maskNamed: aName scale: aScale [
	"The shape of the icon aName at aScale: black, with the alpha of the icon"

	| entry index |
	entry := self entryNamed: aName.
	index := self indexOfScale: aScale.
	^ self
		  cached: {
				  entry name.
				  aScale asFloat.
				  nil }
		  ifAbsentPut: [
		  self class formFromBase64PNG: (entry base64PNGAt: index) ]
]

{ #category : 'accessing' }
MaterialIcons >> pngBytesNamed: aName scale: aScale [
	"The PNG of the icon aName at aScale: 8-bit grey (0) and alpha"

	^ ((self entryNamed: aName) base64PNGAt: (self indexOfScale: aScale))
		  base64Decoded
]

{ #category : 'printing' }
MaterialIcons >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: style;
		nextPut: $)
]

{ #category : 'accessing' }
MaterialIcons >> search: aString [
	"The names of the icons whose name or one of whose tags includes aString, ignoring the case, sorted"

	^ ((self entries select: [ :each | each matches: aString ]) keys)
		  asArray sort
]

{ #category : 'initialization' }
MaterialIcons >> setStyle: aSymbol [

	style := aSymbol
]

{ #category : 'accessing' }
MaterialIcons >> size [
	"The number of my icons"

	^ self entries size
]

{ #category : 'accessing' }
MaterialIcons >> style [

	^ style
]

{ #category : 'accessing' }
MaterialIcons >> tagsOf: aName [

	^ (self entryNamed: aName) tags
]

{ #category : 'accessing' }
MaterialIcons >> themeColor [
	"The text colour of the current UI theme"

	^ [ Smalltalk ui theme textColor ]
		  on: Error
		  do: [ :error | error return: Color black ]
]
