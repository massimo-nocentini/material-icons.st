"
I check the generated data of Material Icons Rounded (packages `MaterialIcons-Rounded` and `MaterialIcons-Rounded-192`):

- the count of the source (2127 icons, the family Material Icons Round of the Google Fonts metadata, `scripts/manifest.json`),
- unique names,
- one method per icon and one master per icon,
- and that every PNG decodes to a Form of 16, 24 and 32 pixels, and every master to one of 192.
"
Class {
	#name : 'MaterialIconsRoundedDataTest',
	#superclass : 'TestCase',
	#category : 'MaterialIcons-Tests',
	#package : 'MaterialIcons-Tests'
}

{ #category : 'accessing' }
MaterialIconsRoundedDataTest >> allRows [

	^ self categoryClasses flatCollect: [ :each | each iconTable ]
]

{ #category : 'accessing' }
MaterialIconsRoundedDataTest >> categoryClasses [

	^ MaterialIconsCategory categoriesOfStyle: #rounded
]

{ #category : 'running' }
MaterialIconsRoundedDataTest >> defaultTimeLimit [

	^ 5 minutes
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testCategories [

	self
		assert: (self categoryClasses collect: [ :each | each materialCategory ])
		equals: #( 'action' 'alert' 'av' 'communication' 'content' 'device' 'editor' 'file' 'hardware' 'home' 'image' 'maps' 'navigation' 'notification' 'places' 'search' 'social' 'toggle' ).
	self categoryClasses do: [ :each |
		self
			assert: each iconTable size
			equals: (MaterialIconsRoundedCategory categoryCounts detect: [ :pair |
					 pair first = each materialCategory ]) second ]
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testCount [
	"The count of the source: the icons that the family Material Icons Round supports in the metadata of fonts.google.com/icons"

	self assert: MaterialIconsRoundedCategory iconCount equals: 2127.
	self assert: self allRows size equals: 2127.
	self
		assert: (MaterialIconsRoundedCategory categoryCounts
				 inject: 0
				 into: [ :sum :pair | sum + pair second ])
		equals: 2127.
	self assert: MaterialIcons rounded size equals: 2127
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testEveryIconDecodes [
	"Every PNG, at every scale, is a Form of depth 32 of the size of its scale, and not empty"

	self categoryClasses do: [ :class |
		class iconTable do: [ :row |
			| pngs |
			pngs := class base64PNGsOf: row first.
			self assert: pngs size equals: 3.
			pngs with: MaterialIcons pixelSizes do: [ :png :side |
				| form |
				form := MaterialIcons formFromBase64PNG: png.
				self assert: form extent equals: side @ side.
				self assert: form depth equals: 32.
				self assert: (form bits anySatisfy: [ :pixel | (pixel bitShift: -24) > 0 ]) ] ] ]
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testEveryMasterDecodes [
	"Every master, Google's own PNG of 192 pixels (grey and alpha, RGBA or a palette of 1 to 8 bits), is a Form of depth 32 of 192 pixels, black, and not empty"

	self categoryClasses do: [ :class |
		class iconTable do: [ :row |
			| png form |
			png := class base64MasterOf: row first.
			form := MaterialIcons formFromBase64PNG: png.
			self assert: form extent equals: 192 @ 192.
			self assert: form depth equals: 32.
			self assert: (form bits anySatisfy: [ :pixel | (pixel bitShift: -24) > 0 ]).
			self assert: (form bits allSatisfy: [ :pixel |
					 (pixel bitShift: -24) = 0 or: [ (pixel bitAnd: 16rFFFFFF) = 0 ] ]) ] ]
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testEveryIconHasItsMaster [
	"One method master_<name> per row of the tables, and no other"

	self assert: MaterialIconsRoundedCategory masterSize equals: 192.
	self categoryClasses do: [ :class |
		| selectors |
		self assert: class hasMasters.
		selectors := (class class selectors select: [ :each |
			              each beginsWith: 'master_' ]) asSet.
		self
			assert: selectors
			equals: (class iconTable collect: [ :row | class masterSelectorOf: row first ]) asSet ]
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testEveryIconHasItsMethod [
	"One method icon_<name> per row of the tables, and no other"

	self categoryClasses do: [ :class |
		| selectors |
		selectors := (class class selectors select: [ :each |
			              each beginsWith: 'icon_' ]) asSet.
		self
			assert: selectors
			equals: (class iconTable collect: [ :row | class selectorOf: row first ]) asSet ]
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testNames [
	"Unique, in the alphabet of the Material names, and the digit-led ones too"

	| names |
	names := self allRows collect: [ :row | row first ].
	self assert: names asSet size equals: names size.
	self assert: (names allSatisfy: [ :each |
			 each notEmpty and: [
				 each allSatisfy: [ :char |
					 char isDigit or: [ char = $_ or: [ char isLetter and: [ char isLowercase ] ] ] ] ] ]).
	self assert: (names includes: '10k').
	self assert: (names includes: '3d_rotation').
	self assert: (names includes: 'home')
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testMastersAreGooglePNGs [
	"The masters are the PNGs of the android tree upstream, byte for byte: 192 pixels, 8 bits, of several colour types"

	| types |
	types := Set new.
	self categoryClasses do: [ :class |
		class iconTable do: [ :row |
			| bytes |
			bytes := (class base64MasterOf: row first) base64Decoded.
			self assert: (bytes first: 8) equals: #[ 137 80 78 71 13 10 26 10 ].
			self assert: ((bytes copyFrom: 17 to: 24) asArray) equals: #( 0 0 0 192 0 0 0 192 ).
			types add: (bytes at: 26) ] ].
	self assert: types equals: #( 3 4 6 ) asSet.
	self assert: (MaterialIconsRoundedCategory masterDescription includesSubstring: 'drawable-xxxhdpi')
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testPNGsAreGreyAndAlpha [
	"8-bit grey and alpha (colour type 4), grey 0: the image paints them"

	| bytes |
	#( 'home' '10k' 'delete' ) do: [ :name |
		MaterialIcons scales do: [ :scale |
			bytes := MaterialIcons rounded pngBytesNamed: name scale: scale.
			self assert: (bytes first: 8) equals: #[ 137 80 78 71 13 10 26 10 ].
			self assert: (bytes at: 25) equals: 8.
			self assert: (bytes at: 26) equals: 4 ] ]
]

{ #category : 'tests' }
MaterialIconsRoundedDataTest >> testTables [
	"Each row: name, codepoint in the Private Use Area, tags"

	self allRows do: [ :row |
		self assert: row size equals: 3.
		self assert: row first isString.
		self assert: (row second between: 16rE000 and: 16rF8FF).
		self assert: (row third allSatisfy: [ :each | each isString ]) ]
]
