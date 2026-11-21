"
I check the generated data of Material Symbols Rounded (packages MaterialSymbols-Rounded and MaterialSymbols-Rounded-192, and the filled variant when its packages are loaded): the count of the source (3929 icons: the 3944 that the family Material Symbols Rounded supports in the metadata of Google Fonts, but the 15 that the pinned commit does not have yet; scripts/manifest-symbols.json), unique names, one method and one master per icon, and that every PNG decodes to a Form of 16, 24, 32 and 192 pixels.
"
Class {
	#name : 'MaterialSymbolsRoundedDataTest',
	#superclass : 'TestCase',
	#category : 'MaterialSymbols-Tests',
	#package : 'MaterialSymbols-Tests'
}

{ #category : 'accessing' }
MaterialSymbolsRoundedDataTest >> allRows [

	^ (self categoryClassesOf: #symbolsRounded) flatCollect: [ :each | each iconTable ]
]

{ #category : 'accessing' }
MaterialSymbolsRoundedDataTest >> categoryClassesOf: aStyle [

	^ MaterialIconsCategory categoriesOfStyle: aStyle
]

{ #category : 'helpers' }
MaterialSymbolsRoundedDataTest >> checkEveryIconOfStyle: aStyle [
	"Every PNG, at every scale and the master, is a Form of depth 32 of its size, grey and alpha, and not empty"

	(self categoryClassesOf: aStyle) do: [ :class |
		class iconTable do: [ :row |
			| pngs |
			pngs := (class base64PNGsOf: row first) copyWith: (class base64MasterOf: row first).
			self assert: pngs size equals: 4.
			pngs with: #( 16 24 32 192 ) do: [ :png :side |
				| bytes form |
				bytes := png base64Decoded.
				self assert: (bytes at: 25) equals: 8.
				self assert: (bytes at: 26) equals: 4.
				form := MaterialIcons formFromBase64PNG: png.
				self assert: form extent equals: side @ side.
				self assert: form depth equals: 32.
				self assert: (form bits anySatisfy: [ :pixel | (pixel bitShift: -24) > 0 ]) ] ] ]
]

{ #category : 'helpers' }
MaterialSymbolsRoundedDataTest >> checkMethodsOfStyle: aStyle [
	"One method icon_<name> and one master_<name> per row of the tables, and no other"

	(self categoryClassesOf: aStyle) do: [ :class |
		#( 'icon_' 'master_' ) do: [ :prefix |
			| selectors |
			selectors := (class class selectors select: [ :each |
				              each beginsWith: prefix ]) asSet.
			self
				assert: selectors
				equals: (class iconTable collect: [ :row | (prefix , row first) asSymbol ]) asSet ] ]
]

{ #category : 'running' }
MaterialSymbolsRoundedDataTest >> defaultTimeLimit [

	^ 10 minutes
]

{ #category : 'accessing' }
MaterialSymbolsRoundedDataTest >> filledClass [

	^ Smalltalk globals at: #MaterialSymbolsRoundedFilledCategory ifAbsent: [ nil ]
]

{ #category : 'helpers' }
MaterialSymbolsRoundedDataTest >> skipUnlessFilled [

	self filledClass ifNil: [
		self skip: 'the group SymbolsRoundedFilled is not loaded' ]
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testCategories [

	self
		assert: ((self categoryClassesOf: #symbolsRounded) collect: [ :each | each materialCategory ])
		equals: #( 'Actions' 'Activities' 'Android' 'Audio&Video' 'Business' 'Communicate' 'Hardware' 'Home' 'Household' 'Images' 'Maps' 'Privacy' 'Social' 'Text' 'Transit' 'Travel' 'UI actions' ).
	self assert: (Smalltalk globals includesKey: #MaterialSymbolsRoundedUIActions).
	self assert: (Smalltalk globals includesKey: #MaterialSymbolsRoundedAudioVideo).
	(self categoryClassesOf: #symbolsRounded) do: [ :each |
		self
			assert: each iconTable size
			equals: (MaterialSymbolsRoundedCategory categoryCounts detect: [ :pair |
					 pair first = each materialCategory ]) second ]
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testCount [
	"The count of the source: the icons that the family Material Symbols Rounded supports in the metadata of fonts.google.com/icons, but those not in the repository yet at the pinned commit"

	self assert: MaterialSymbolsRoundedCategory iconCount equals: 3929.
	self assert: self allRows size equals: 3929.
	self
		assert: (MaterialSymbolsRoundedCategory categoryCounts
				 inject: 0
				 into: [ :sum :pair | sum + pair second ])
		equals: 3929.
	self assert: MaterialIcons symbolsRounded size equals: 3929.
	self assert: MaterialSymbolsRoundedCategory missingIcons size equals: 15.
	self deny: (MaterialSymbolsRoundedCategory missingIcons anySatisfy: [ :each |
			 MaterialIcons symbolsRounded includesIcon: each ])
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testEveryIconDecodes [

	self checkEveryIconOfStyle: #symbolsRounded
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testEveryIconHasItsMethods [

	self assert: MaterialSymbolsRoundedCategory masterSize equals: 192.
	self checkMethodsOfStyle: #symbolsRounded
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testFilledEveryIconDecodes [

	self skipUnlessFilled.
	self checkEveryIconOfStyle: #symbolsRoundedFilled
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testFilledVariant [
	"The filled variant has the same icons, categories and tables, and other pixels"

	| filled default |
	self skipUnlessFilled.
	self checkMethodsOfStyle: #symbolsRoundedFilled.
	self
		assert: ((self categoryClassesOf: #symbolsRoundedFilled) collect: [ :each | each materialCategory ])
		equals: ((self categoryClassesOf: #symbolsRounded) collect: [ :each | each materialCategory ]).
	filled := MaterialIcons symbolsRoundedFilled.
	default := MaterialIcons symbolsRounded.
	self assert: filled size equals: 3929.
	self assert: filled iconNames equals: default iconNames.
	self assert: (filled tagsOf: #home) equals: (default tagsOf: #home).
	self deny: (filled pngBytesNamed: #home scale: 1) equals: (default pngBytesNamed: #home scale: 1).
	self assert: filled masterSize equals: 192.
	self assert: (self filledClass variantDescription includesSubstring: 'FILL 1')
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testLicence [

	| commit |
	commit := MaterialSymbolsRoundedCategory upstreamCommit.
	self assert: commit equals: '10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7'.
	self assert: (MaterialSymbolsRoundedCategory upstreamDescription includesSubstring: commit).
	self assert: (MaterialSymbolsRoundedCategory upstreamDescription includesSubstring: 'materialsymbolsrounded').
	self assert: (MaterialSymbolsRoundedCategory masterDescription includesSubstring: '48px').
	self assert: (MaterialSymbolsRoundedCategory comment includesSubstring: commit).
	self assert: (MaterialSymbolsRoundedCategory licenseText includesSubstring: 'Apache License').
	self assert: (MaterialSymbolsRoundedCategory licenseText includesSubstring: 'Version 2.0').
	self assert: (MaterialSymbolsRoundedCategory variantDescription includesSubstring: 'FILL 0')
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testNames [
	"Unique, in the alphabet of the Material names, and the digit-led ones too"

	| names |
	names := self allRows collect: [ :row | row first ].
	self assert: names asSet size equals: names size.
	self assert: (names allSatisfy: [ :each |
			 each notEmpty and: [
				 each allSatisfy: [ :char |
					 char isDigit or: [ char = $_ or: [ char isLetter and: [ char isLowercase ] ] ] ] ] ]).
	self assert: (names includes: '10k').
	self assert: (names includes: 'home').
	self assert: (names includes: 'eco')
]

{ #category : 'tests' }
MaterialSymbolsRoundedDataTest >> testTables [
	"Each row: name, codepoint in a Private Use Area, tags as one String"

	self allRows do: [ :row |
		self assert: row size equals: 3.
		self assert: row first isString.
		self assert: ((row second between: 16rE000 and: 16rF8FF) or: [
				 row second between: 16rF0000 and: 16rFFFFD ]).
		self assert: row third isString ]
]
