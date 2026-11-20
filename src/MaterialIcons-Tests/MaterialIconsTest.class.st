"
I test the facade `MaterialIcons`: Forms and FormSets by name, scales, colours, the cache, the index (categories, tags, search, codepoints).
"
Class {
	#name : 'MaterialIconsTest',
	#superclass : 'TestCase',
	#instVars : [
		'icons'
	],
	#category : 'MaterialIcons-Tests',
	#package : 'MaterialIcons-Tests'
}

{ #category : 'helpers' }
MaterialIconsTest >> opaquePixelsOf: aForm [
	"The colours of the pixels of aForm of alpha 1"

	| colors |
	colors := Set new.
	0 to: aForm height - 1 do: [ :y |
		0 to: aForm width - 1 do: [ :x |
			| color |
			color := aForm colorAt: x @ y.
			color alpha = 1 ifTrue: [ colors add: color ] ] ].
	^ colors
]

{ #category : 'running' }
MaterialIconsTest >> setUp [

	super setUp.
	icons := MaterialIcons new setStyle: #rounded
]

{ #category : 'tests' }
MaterialIconsTest >> testCache [

	| form |
	form := icons iconNamed: #home.
	self assert: (icons iconNamed: #home) identicalTo: form.
	self assert: (icons formNamed: 'home' scale: 1.0) identicalTo: form.
	self assert: icons cacheSize equals: 2.	"the shape and the Form in the colour"
	icons flushCache.
	self assert: icons cacheSize equals: 0.
	self deny: (icons iconNamed: #home) identicalTo: form.
	self assert: (icons iconNamed: #home) bits equals: form bits
]

{ #category : 'tests' }
MaterialIconsTest >> testCategoriesAndTags [

	self assert: icons categories size equals: 18.
	self assert: (icons categoryOf: #home) equals: 'action'.
	self assert: (icons categoryOf: #'10k') equals: 'av'.
	self assert: ((icons iconNamesInCategory: 'toggle') includes: #star).
	self assert: ((icons iconNamesInCategory: 'navigation') allSatisfy: [ :each |
			 (icons categoryOf: each) = 'navigation' ]).
	self assert: ((icons tagsOf: #delete) includes: 'trash').
	self assert: (icons codepointOf: #home) equals: 16rE88A.
	self assert: (icons entryNamed: #home) name equals: #home
]

{ #category : 'tests' }
MaterialIconsTest >> testColor [

	| red blue |
	icons color: Color red.
	self deny: icons followsTheme.
	red := icons iconNamed: #home.
	self assert: (self opaquePixelsOf: red) asArray equals: { Color red }.
	blue := icons formNamed: #home scale: 1 color: Color blue.
	self assert: (self opaquePixelsOf: blue) asArray equals: { Color blue }.
	self deny: red identicalTo: blue.
	icons color: nil.
	self assert: icons followsTheme.
	self assert: icons color equals: icons themeColor
]

{ #category : 'tests' }
MaterialIconsTest >> testColorNil [
	"nil as the colour of a call means my colour, as elsewhere, and never the black shape (the mask)"

	| form |
	form := icons formNamed: #home scale: 2 color: nil.	"before the shape is in the cache"
	self assert: form bits equals: (icons formNamed: #home scale: 2) bits.
	icons color: Color red.
	form := icons formNamed: #home scale: 1 color: nil.
	self deny: form identicalTo: (icons maskNamed: #home scale: 1).
	self assert: (self opaquePixelsOf: form) asArray equals: { Color red }.
	self
		assert: ((icons formSetNamed: #home color: nil) asFormAtScale: 2) bits
		equals: (icons formNamed: #home scale: 2 color: Color red) bits.
	icons color: nil.
	self
		assert: (icons formNamed: #home scale: 1.5 color: nil) bits
		equals: (icons formNamed: #home scale: 1.5 color: icons themeColor) bits
]

{ #category : 'tests' }
MaterialIconsTest >> testDigitLedNames [

	self assert: (icons includesIcon: #'10k').
	self assert: (icons includesIcon: '3d_rotation').
	self assert: (icons iconNamed: #'10k') extent equals: 16 @ 16
]

{ #category : 'tests' }
MaterialIconsTest >> testFormSet [

	| formSet |
	formSet := icons formSetNamed: #search.
	self assert: formSet extent equals: 16 @ 16.
	self
		assert: (formSet forms collect: [ :each | each extent ]) asArray
		equals: { 16 @ 16. 24 @ 24. 32 @ 32 }.
	self assert: (formSet asFormAtScale: 2) extent equals: 32 @ 32.
	self assert: (formSet asFormAtScale: 1.5) extent equals: 24 @ 24.
	self assert: formSet asForm extent equals: 16 @ 16
]

{ #category : 'tests' }
MaterialIconsTest >> testIconNamesAndStyles [

	| names |
	names := icons iconNames.
	self assert: names size equals: icons size.
	self assert: names first equals: #'10k'.
	self assert: (names allSatisfy: [ :each | each isSymbol ]).
	self assert: (MaterialIcons styles includes: #rounded).
	self assert: MaterialIcons rounded identicalTo: MaterialIcons rounded
]

{ #category : 'tests' }
MaterialIconsTest >> testScales [

	MaterialIcons scales with: MaterialIcons pixelSizes do: [ :scale :side |
		self assert: (icons formNamed: #arrow_back scale: scale) extent equals: side @ side ].
	self should: [ icons formNamed: #arrow_back scale: 3 ] raise: Error
]

{ #category : 'tests' }
MaterialIconsTest >> testSearch [

	self assert: ((icons search: 'arrow_back') includes: #arrow_back).
	self assert: ((icons search: 'ARROW') includes: #arrow_forward).
	self assert: ((icons search: 'trash') includes: #delete).
	self assert: (icons search: 'no icon has this tag') isEmpty
]

{ #category : 'tests' }
MaterialIconsTest >> testShape [
	"The shape is the alpha of the Material icon: transparent corners, an opaque centre in #stop"

	| form |
	form := icons formNamed: #stop scale: 2 color: Color black.
	self assert: (form colorAt: 0 @ 0) alpha equals: 0.
	self assert: (form colorAt: 16 @ 16) alpha equals: 1.
	self assert: (icons maskNamed: #stop scale: 2) extent equals: 32 @ 32
]

{ #category : 'tests' }
MaterialIconsTest >> testUnknownIcon [

	self deny: (icons includesIcon: #noSuchIcon).
	self deny: (icons includesIcon: nil).
	self should: [ icons iconNamed: #noSuchIcon ] raise: KeyNotFound.
	self assert: (icons iconNamed: #noSuchIcon ifNone: [ #none ]) equals: #none
]
