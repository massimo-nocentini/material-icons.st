"
I test the facade `MaterialIcons` on Material Symbols Rounded (`MaterialIcons symbolsRounded`): the same protocol as on Material Icons Rounded, the tags held as one String, the other sizes from the masters or, without them (group `SymbolsRoundedSmall`), from the 32-pixel icon. The tests of the masters skip themselves when `MaterialSymbols-Rounded-192` is not loaded.
"
Class {
	#name : 'MaterialSymbolsIconsTest',
	#superclass : 'TestCase',
	#instVars : [
		'icons'
	],
	#category : 'MaterialSymbols-Tests',
	#package : 'MaterialSymbols-Tests'
}

{ #category : 'running' }
MaterialSymbolsIconsTest >> setUp [

	super setUp.
	icons := MaterialIcons new setStyle: #symbolsRounded
]

{ #category : 'running' }
MaterialSymbolsIconsTest >> skipUnlessMasters [

	icons hasMasters ifFalse: [
		self skip: 'the masters (MaterialSymbols-Rounded-192, group SymbolsRounded) are not loaded' ]
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testCategoriesAndTags [

	self assert: icons categories size equals: 17.
	self assert: (icons categories includes: 'UI actions').
	self assert: (icons categoryOf: #home) equals: 'UI actions'.
	self assert: (icons categoryOf: #'10k') equals: 'Audio&Video'.
	self assert: ((icons iconNamesInCategory: 'Social') includes: #eco).
	self assert: ((icons tagsOf: #delete) includes: 'bin').
	self assert: (icons tagsOf: #delete) isArray.
	self assert: ((icons tagsOf: #delete) allSatisfy: [ :each | each isString and: [ (each includes: $,) not ] ]).
	self assert: (icons codepointOf: #home) equals: 16rE88A.
	self assert: (icons entryNamed: #home) name equals: #home
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testColor [

	| form |
	form := icons formNamed: #home scale: 2 color: Color red.
	self assert: (form colorAt: 0 @ 0) alpha equals: 0.
	self assert: ((form bits reject: [ :pixel | (pixel bitShift: -24) = 0 ]) allSatisfy: [ :pixel |
			 (pixel bitAnd: 16rFFFFFF) = ((Color red pixelValueForDepth: 32) bitAnd: 16rFFFFFF) ])
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testFormNamedSize [

	MaterialIcons scales with: MaterialIcons pixelSizes do: [ :scale :side |
		self
			assert: (icons formNamed: #home size: side)
			identicalTo: (icons formNamed: #home scale: scale) ].
	#( 12 48 64 96 192 256 ) do: [ :side |
		self assert: (icons formNamed: #'10k' size: side) extent equals: side @ side ]
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testMasters [

	self skipUnlessMasters.
	self assert: icons hasMasters.
	self assert: icons masterSize equals: 192.
	self assert: (icons masterFormNamed: #eco) extent equals: 192 @ 192.
	self assert: ((icons masterPNGBytesNamed: #eco) first: 8) equals: #[ 137 80 78 71 13 10 26 10 ]
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testWithoutMasters [
	"Without MaterialSymbols-Rounded-192 the other sizes are the 32-pixel icon resampled"

	| derived |
	icons hasMasters ifTrue: [ self skip: 'the masters (MaterialSymbols-Rounded-192) are loaded' ].
	self assert: icons masterSize isNil.
	derived := icons formNamed: #home size: 64.
	self assert: derived extent equals: 64 @ 64.
	self assert: (derived bits anySatisfy: [ :pixel | (pixel bitShift: -24) > 0 ])
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testFormSet [

	| formSet |
	formSet := icons formSetNamed: #search.
	self assert: formSet extent equals: 16 @ 16.
	self
		assert: (formSet forms collect: [ :each | each extent ]) asArray
		equals: { 16 @ 16. 24 @ 24. 32 @ 32 }
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testIconNamesAndStyles [

	| names |
	names := icons iconNames.
	self assert: names size equals: 3944.
	self assert: names first equals: #'10k'.
	self assert: (MaterialIcons styles includes: #symbolsRounded).
	self assert: MaterialIcons symbolsRounded identicalTo: MaterialIcons symbolsRounded.
	self deny: MaterialIcons symbolsRounded identicalTo: MaterialIcons rounded.
	self assert: (icons iconNamed: #home) extent equals: 16 @ 16.
	self assert: (icons iconNamed: #'10k') extent equals: 16 @ 16
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testOpticalSizes [
	"The small sizes are drawn from the optical size 24 and the master from the optical size 48: both are the same symbol, so the master averaged down is close to the small icon, not equal"

	| derived drawn difference |
	self skipUnlessMasters.
	derived := MaterialIcons resample: (icons masterMaskNamed: #home) to: 32.
	drawn := icons maskNamed: #home scale: 2.
	difference := 0.
	derived bits with: drawn bits do: [ :a :b |
		difference := difference + ((a bitShift: -24) - (b bitShift: -24)) abs ].
	self assert: difference / (32 * 32) < 40.
	self deny: derived bits equals: drawn bits
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testSearch [

	self assert: ((icons search: 'home') includes: #home).
	self assert: ((icons search: 'TRASH') includes: #delete).
	self assert: ((icons search: 'application--house') includes: #home).
	self assert: (icons search: 'no icon has this tag') isEmpty
]

{ #category : 'tests' }
MaterialSymbolsIconsTest >> testUnknownIcon [

	self deny: (icons includesIcon: #noSuchIcon).
	self assert: (icons includesIcon: #pull_request).	"not at the pinned commit: from fonts.gstatic.com"
	self assert: (icons iconNamed: #pull_request) extent equals: 16 @ 16.
	self should: [ icons iconNamed: #noSuchIcon ] raise: KeyNotFound
]
