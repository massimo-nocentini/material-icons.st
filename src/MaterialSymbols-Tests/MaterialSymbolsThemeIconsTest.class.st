"
I test `MaterialSymbolsThemeIcons`, the Material Symbols icon pack of the UI: install and uninstall restore the previous pack, every mapped key is a key of the previous pack drawn at its sizes, the status keys keep their colours, the buttons of inactive windows are grey, the small trimmed keys fill their key, the keys symbol_<name>, the zip for the Settings, and the swap with MaterialThemeIcons when both packages are loaded. I leave the UI's pack as I found it: a Material pack installed before the tests is put aside and made current again after each of them.
"
Class {
	#name : 'MaterialSymbolsThemeIconsTest',
	#superclass : 'TestCase',
	#instVars : [
		'previous',
		'exported',
		'installedBefore',
		'lastFallbackBefore'
	],
	#category : 'MaterialSymbols-Tests',
	#package : 'MaterialSymbols-Tests'
}

{ #category : 'running' }
MaterialSymbolsThemeIconsTest >> defaultTimeLimit [

	^ 2 minutes
]

{ #category : 'accessing' }
MaterialSymbolsThemeIconsTest >> entryOf: aKey [

	^ MaterialSymbolsThemeIconsArt entries detect: [ :each | each first = aKey ]
]

{ #category : 'running' }
MaterialSymbolsThemeIconsTest >> setUp [

	| current |
	super setUp.
	current := ThemeIcons classVarNamed: #Current.
	installedBefore := (current isKindOf: MaterialAbstractThemeIcons)
		                   ifTrue: [ current ]
		                   ifFalse: [ nil ].
	lastFallbackBefore := MaterialSymbolsThemeIcons instVarNamed: #lastFallback.
	installedBefore ifNotNil: [ installedBefore class uninstall ].
	previous := ThemeIcons current.
	exported := OrderedCollection new
]

{ #category : 'running' }
MaterialSymbolsThemeIconsTest >> tearDown [

	MaterialAbstractThemeIcons allSubclasses do: [ :each | each unsubscribeFromThemeChanges ].
	ThemeIcons current == previous ifFalse: [ previous beCurrent ].
	MaterialSymbolsThemeIcons instVarNamed: #lastFallback put: lastFallbackBefore.
	installedBefore ifNotNil: [
		installedBefore beCurrent.
		installedBefore class subscribeToThemeChanges ].
	exported do: [ :each | each ensureDelete ].
	super tearDown
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testColors [
	"A fixed colour for the status keys, the colour of the pack for the others"

	| pack |
	pack := MaterialSymbolsThemeIcons installColor: Color red.
	self deny: pack followsTheme.
	MaterialSymbolsThemeIconsArt entries do: [ :entry |
		| expected form |
		expected := entry fifth
			            ifNil: [ Color red ]
			            ifNotNil: [ :hex | Color fromHexString: hex ].
		form := pack iconNamed: entry first.
		form unhibernate.
		self assert: (form bits anySatisfy: [ :pixel | (pixel bitShift: -24) > 0 ]).
		self assert: ((form bits reject: [ :pixel | (pixel bitShift: -24) = 0 ]) allSatisfy: [ :pixel |
				 (pixel bitAnd: 16rFFFFFF) = ((expected pixelValueForDepth: 32) bitAnd: 16rFFFFFF) ]) ]
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testEntries [
	"Mapped keys are unique keys of the previous pack (svgPack), mapped to Material Symbols in a valid variant"

	| keys |
	keys := MaterialSymbolsThemeIconsArt entries collect: [ :each | each first ].
	self assert: keys notEmpty.
	self assert: keys asSet size equals: keys size.
	MaterialSymbolsThemeIconsArt entries do: [ :each |
		self assert: each size equals: 6.
		self assert: ((previous iconsPerScale at: 1.0) includesKey: each first).
		self assert: (MaterialIcons symbolsRounded includesIcon: each second).
		self assert: (#( 0 1 ) includes: each third).
		self assert: (#( 0 200 ) includes: each fourth).
		self assert: ((MaterialSymbolsThemeIconsArt perform: each sixth) size) equals: 3 ]
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testExportZip [
	"The zip that the Settings list loads as a plain ThemeIcons, offline, with the same icons, the licence and the notice"

	| pack name file loaded |
	pack := MaterialSymbolsThemeIcons new
		        fallback: previous;
		        build;
		        yourself.
	pack iconNamed: #symbol_cloud_sync.
	self assert: ((pack iconsPerScale at: 1.0) includesKey: #symbol_cloud_sync).
	name := 'materialSymbolsTest' , Time millisecondClockValue printString.
	pack name: name.
	file := ThemeIcons destinationPath / (name , '.zip').
	exported add: file.
	MaterialSymbolsThemeIcons exportPack: pack to: file.
	file binaryReadStreamDo: [ :stream |
		| archive |
		archive := ZipArchive new readFrom: stream.
		self
			assert: (archive memberNamed: name , '/LICENSE-material-symbols') contents asString
			equals: MaterialSymbolsRoundedCategory licenseText withUnixLineEndings.
		self
			assert: (archive memberNamed: name , '/NOTICE') contents asString
			equals: MaterialSymbolsThemeIconsArt noticeText withUnixLineEndings.
		self deny: (archive memberNames anySatisfy: [ :each | each includesSubstring: '/symbol_' ]).
		self assert: (archive memberNames includes: name , '/png-scale2.0/add.png') ].
	loaded := ThemeIcons named: name.
	loaded loadIconsFromUrl.
	(MaterialSymbolsThemeIconsArt entries collect: [ :each | each first ]) do: [ :key |
		MaterialIcons scales do: [ :scale |
			| mine theirs |
			mine := (pack iconsPerScale at: scale) at: key.
			theirs := (loaded iconsPerScale at: scale) at: key.
			self assert: theirs extent equals: mine extent ] ]
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testFallbackKeys [

	| pack mapped |
	pack := MaterialSymbolsThemeIcons install.
	mapped := (MaterialSymbolsThemeIconsArt entries collect: [ :each | each first ]) asSet.
	(previous iconsPerScale at: 1.0) keysAndValuesDo: [ :key :form |
		(mapped includes: key) ifFalse: [
			self assert: ((pack iconsPerScale at: 1.0) at: key) identicalTo: form ] ]
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testInactiveWindowButtons [
	"The buttons of inactive windows keep the passive look of svgPack: grey, not the colour of the theme"

	| inactive |
	inactive := MaterialSymbolsThemeIconsArt entries select: [ :each |
		            (each first beginsWith: 'window') and: [ each first includesSubstring: 'Inactive' ] ].
	self assert: inactive size equals: 8.
	inactive do: [ :each | self assert: each fifth equals: '9E9E9E' ]
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testInstallAndUninstall [

	| pack |
	self deny: MaterialSymbolsThemeIcons isInstalled.
	pack := MaterialSymbolsThemeIcons install.
	self assert: MaterialSymbolsThemeIcons isInstalled.
	self assert: Smalltalk ui icons identicalTo: pack.
	self assert: pack fallback identicalTo: previous.
	self assert: pack name equals: 'materialSymbolsRounded'.
	MaterialSymbolsThemeIcons uninstall.
	self deny: MaterialSymbolsThemeIcons isInstalled.
	self assert: ThemeIcons current identicalTo: previous
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testMappedKeysAtTheSizesOfThePreviousPack [
	"Every mapped key is drawn at the sizes the previous pack draws it, at every scale"

	| pack |
	pack := MaterialSymbolsThemeIcons install.
	MaterialSymbolsThemeIconsArt entries do: [ :entry |
		MaterialIcons scales do: [ :scale |
			| form |
			form := (pack iconsPerScale at: scale) at: entry first.
			((previous iconsPerScale at: scale) at: entry first ifAbsent: [ nil ])
				ifNotNil: [ :old | self assert: form extent equals: old extent ] ] ].
	self assert: (pack iconNamed: #add) extent equals: 16 @ 16.
	self assert: (pack iconNamed: #accept) extent equals: 14 @ 14.
	self deny: (pack iconNamed: #add) bits equals: (previous iconNamed: #add) bits
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testStatusKeys [
	"The status keys that are mapped have fixed colours; testNotRun is not the empty circle of a radio button"

	#( #testGreen #testRed #testYellow #testNotRun #error #smallError #warning #smallWarning )
		do: [ :key |
			(MaterialSymbolsThemeIconsArt entries
				 detect: [ :each | each first = key ]
				 ifNone: [ nil ]) ifNotNil: [ :entry | self assert: entry fifth notNil ] ].
	(MaterialSymbolsThemeIconsArt entries
		 detect: [ :each | each first = #testNotRun ]
		 ifNone: [ nil ]) ifNotNil: [ :entry |
		self deny: entry second equals: 'radio_button_unchecked' ]
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testSwapWithMaterialThemeIcons [
	"With both packs loaded, installing one over the other goes over the fallback of the other: they replace each other, and uninstall goes back to the pack of before"

	| other symbols |
	other := Smalltalk globals at: #MaterialThemeIcons ifAbsent: [
		         ^ self skip: 'MaterialIcons-ThemePack is not loaded' ].
	other install.
	symbols := MaterialSymbolsThemeIcons install.
	self assert: symbols fallback identicalTo: previous.
	self deny: other isInstalled.
	self assert: MaterialSymbolsThemeIcons isInstalled.
	self assert: (other install) fallback identicalTo: previous.
	self deny: MaterialSymbolsThemeIcons isInstalled.
	other uninstall.
	self assert: ThemeIcons current identicalTo: previous.
	other unsubscribeFromThemeChanges
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testSymbolKeys [

	| pack |
	pack := MaterialSymbolsThemeIcons install.
	self assert: (Smalltalk ui icons iconNamed: #symbol_10k) extent equals: 16 @ 16.
	self assert: (pack symbolIconNamed: #eco) extent equals: 16 @ 16.
	self
		assert: (pack iconNamed: #symbol_home) bits
		equals: (MaterialIcons symbolsRounded formNamed: #home scale: 1 color: pack effectiveColor) bits.
	self assert: ((pack iconFormSetNamed: #symbol_home) asFormAtScale: 2) extent equals: 32 @ 32.
	self assert: (pack allIconNames includes: #symbol_arrow_back).
	self assert: (pack iconNamed: #symbol_no_such_icon ifNone: [ #none ]) equals: #none
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testThemeChange [

	| pack |
	pack := MaterialSymbolsThemeIcons install.
	pack color: Color red.
	pack build.
	pack color: nil.
	MaterialSymbolsThemeIcons themeChanged: nil.
	self
		assert: (pack iconNamed: #add) bits
		equals: (MaterialIcons
				 tint: (MaterialIcons formFromBase64PNG: (MaterialSymbolsThemeIconsArt perform: (self entryOf: #add) sixth) first)
				 color: MaterialIcons symbolsRounded themeColor) bits
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testTrimmedKeys [
	"The small keys whose symbol would be a speck in Material's padding are trimmed (scripts/symbols-mapping.tsv, column trim): their ink spans the width of the key at every scale, as svgPack's does"

	| pack |
	pack := MaterialSymbolsThemeIcons install.
	#( #arrowDown #arrowUp #play #go #checkBoxOff #checkBoxOn ) do: [ :key |
		self assert: ((self entryOf: key) sixth includesSubstring: '_trim').
		MaterialIcons scales do: [ :scale |
			| form inked |
			form := (pack iconsPerScale at: scale) at: key.
			form unhibernate.
			inked := (0 to: form width - 1) select: [ :x |
				         (0 to: form height - 1) anySatisfy: [ :y |
					         ((form pixelValueAt: x @ y) bitShift: -24) > 8 ] ].
			self assert: inked size >= (form width * 0.65) ] ]
]

{ #category : 'tests' }
MaterialSymbolsThemeIconsTest >> testUninstallFlushesCache [

	MaterialSymbolsThemeIcons install.
	Smalltalk ui icons iconNamed: #symbol_cloud_sync.
	self assert: MaterialIcons symbolsRounded cacheSize > 0.
	MaterialSymbolsThemeIcons uninstall.
	self assert: MaterialIcons symbolsRounded cacheSize equals: 0
]
