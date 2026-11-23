"
I test the icons of MaterialSymbols-Protocols-Calypso in real Calypso browsers, opened (headless too) and drawn: the protocol pane of the system browser (a symbol on the mapped protocols, in the colour of MaterialProtocolSymbols; Pharo's own icon on private and initialization; nothing on an unmapped protocol, on the groups of extensions and on the virtual groups), the status bar of the method editor, the protocol column of a query browser (Pharo's own icon on private), the switch `MaterialProtocolSymbols enabled`, which takes every icon away and gives it back, the layout of the status bar, which stays Pharo's, and `MaterialProtocolBrowserPlugin detachFrom:`, what unloading the package does to the open browsers.

The methods browsed are those of MaterialProtocolSymbolsFixture. I close the windows I open and leave the switch and the icon pack of the UI as I found them.
"
Class {
	#name : 'MaterialProtocolSymbolsCalypsoTest',
	#superclass : 'TestCase',
	#instVars : [
		'windows',
		'enabledBefore',
		'previousPack',
		'installedBefore',
		'themeBefore'
	],
	#category : 'MaterialSymbols-Protocols-Tests',
	#package : 'MaterialSymbols-Protocols-Tests'
}

{ #category : 'asserting' }
MaterialProtocolSymbolsCalypsoTest >> assertForm: aForm isInColor: aColor [
	"aForm has ink, and every pixel of it that is not transparent is aColor"

	aForm unhibernate.
	self assert: (aForm bits anySatisfy: [ :pixel | (pixel bitShift: -24) > 0 ]).
	self assert: ((aForm bits reject: [ :pixel | (pixel bitShift: -24) = 0 ]) allSatisfy: [ :pixel |
			 (pixel bitAnd: 16rFFFFFF) = ((aColor pixelValueForDepth: 32) bitAnd: 16rFFFFFF) ])
]

{ #category : 'accessing' }
MaterialProtocolSymbolsCalypsoTest >> cellNamed: aString in: aWindow [

	^ (self protocolCellsIn: aWindow)
		  detect: [ :each | each item name = aString ]
		  ifNone: [ self fail: 'no row ' , aString ]
]

{ #category : 'running' }
MaterialProtocolSymbolsCalypsoTest >> defaultTimeLimit [

	^ 2 minutes
]

{ #category : 'accessing' }
MaterialProtocolSymbolsCalypsoTest >> definitionMorphOf: aCell [
	"The icon in the slot of aCell, whoever put it there"

	^ aCell instVarNamed: #definitionMorph
]

{ #category : 'running' }
MaterialProtocolSymbolsCalypsoTest >> draw: aWindow [
	"Calypso builds the rows of its tables when it draws them, and the method editors step their status bars"

	aWindow imageForm.
	aWindow allMorphsDo: [ :each |
		(each isKindOf: MaterialProtocolIconKeeper) ifTrue: [ each step ] ].
	aWindow imageForm
]

{ #category : 'accessing' }
MaterialProtocolSymbolsCalypsoTest >> fixture [

	^ MaterialProtocolSymbolsFixture
]

{ #category : 'accessing' }
MaterialProtocolSymbolsCalypsoTest >> materialIconIn: aMorph [
	"The icon of MaterialSymbols-Protocols-Calypso in aMorph, or nil"

	^ aMorph allMorphs
		  detect: [ :each | each hasProperty: #materialProtocolSymbol ]
		  ifNone: [ nil ]
]

{ #category : 'running' }
MaterialProtocolSymbolsCalypsoTest >> open: aBrowser [
	"The window of aBrowser, drawn once its rows are there (Calypso may query in the background)"

	| window |
	window := aBrowser window.
	windows add: window.
	window extent: 1000 @ 600.
	1 to: 60 do: [ :each |
		self draw: window.
		(window allMorphs anySatisfy: [ :morph | morph isKindOf: ClyMainItemCellMorph ])
			ifTrue: [ ^ window ].
		(Delay forMilliseconds: 50) wait ].
	^ window
]

{ #category : 'running' }
MaterialProtocolSymbolsCalypsoTest >> openBrowserOn: aMethod [

	^ self open: (ClyFullBrowserMorph openOnMethod: aMethod)
]

{ #category : 'accessing' }
MaterialProtocolSymbolsCalypsoTest >> protocolCellsIn: aWindow [

	^ aWindow allMorphs select: [ :each |
		  (each isKindOf: ClyMainItemCellMorph) and: [
			  each item actualObject isKindOf: ClyMethodGroup ] ]
]

{ #category : 'accessing' }
MaterialProtocolSymbolsCalypsoTest >> protocolEditorIn: aWindow [

	^ aWindow allMorphs
		  detect: [ :each | each isKindOf: ClyProtocolEditorMorph ]
		  ifNone: [ self fail: 'no protocol editor' ]
]

{ #category : 'running' }
MaterialProtocolSymbolsCalypsoTest >> setUp [

	| current |
	super setUp.
	windows := OrderedCollection new.
	themeBefore := Smalltalk ui theme class.
	enabledBefore := MaterialProtocolSymbols classVarNamed: #Enabled.
	MaterialProtocolSymbols classVarNamed: #Enabled put: true.
	current := ThemeIcons classVarNamed: #Current.
	installedBefore := (current isKindOf: MaterialAbstractThemeIcons)
		                   ifTrue: [ current ]
		                   ifFalse: [ nil ].
	previousPack := installedBefore ifNil: [ current ]
]

{ #category : 'running' }
MaterialProtocolSymbolsCalypsoTest >> tearDown [

	windows do: [ :each | each delete ].
	Smalltalk ui theme class == themeBefore ifFalse: [ themeBefore beCurrent ].
	(ThemeIcons classVarNamed: #Current) == previousPack ifFalse: [
		MaterialAbstractThemeIcons allSubclasses do: [ :each |
			each unsubscribeFromThemeChanges ].
		previousPack beCurrent.
		installedBefore ifNotNil: [ installedBefore class subscribeToThemeChanges ] ].
	MaterialProtocolSymbols classVarNamed: #Enabled put: enabledBefore.
	MaterialProtocolSymbols flushCache.
	super tearDown
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testColourFollowsTheTheme [
	"An open browser draws its protocols again in the text colour of the new UI theme (no Material pack: the colour of the theme)"

	| other window |
	other := UITheme allSubclasses
		         detect: [ :each |
			         each ~~ Smalltalk ui theme class and: [
				         #( #PharoLightTheme #PharoDarkTheme ) includes: each name ] ]
		         ifNone: [ ^ self skip: 'one UI theme only' ].
	MaterialProtocolSymbols provider followsTheme ifFalse: [
		^ self skip: 'MaterialIcons symbolsRounded has a fixed colour' ].
	installedBefore ifNotNil: [ installedBefore class uninstall ].
	window := self openBrowserOn: self fixture >> #materialFixtureAccessing.
	other beCurrent.
	self draw: window.
	self
		assertForm: (self materialIconIn: (self cellNamed: 'accessing' in: window)) form
		isInColor: Smalltalk ui theme textColor.
	self
		assertForm: (self materialIconIn: (self protocolEditorIn: window)) form
		isInColor: Smalltalk ui theme textColor
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testExtensionAndVirtualGroupsKeepTheirLook [
	"Object has extension methods: the 'extensions' group, the '*Package' groups and the 'instance side' group get no icon of mine"

	| window others |
	window := self openBrowserOn: Object >> #printString.
	others := (self protocolCellsIn: window) reject: [ :each |
		          MaterialProtocolGroupTableDecorator isProtocolGroup: each item actualObject ].
	self assert: (others anySatisfy: [ :each | each item name = 'extensions' ]).
	others do: [ :each | self assert: (self materialIconIn: each) isNil ].
	self assert: (self definitionMorphOf: (self cellNamed: 'extensions' in: window)) notNil
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testPackColour [
	"Under a Material pack in a fixed colour the protocols are in that colour"

	| class window icon |
	class := Smalltalk globals at: #MaterialSymbolsThemeIcons ifAbsent: [
		         ^ self skip: 'MaterialSymbols-ThemePack is not loaded' ].
	class installColor: Color gray monochrome: true.
	window := self openBrowserOn: self fixture >> #materialFixtureAccessing.
	icon := self materialIconIn: (self cellNamed: 'accessing' in: window).
	self assertForm: icon form isInColor: Color gray.
	icon := self materialIconIn: (self protocolEditorIn: window).
	self assertForm: icon form isInColor: Color gray
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testProtocolPane [

	| window icon |
	window := self openBrowserOn: self fixture >> #materialFixtureAccessing.
	#( #( 'accessing' #key ) #( 'printing' #print ) #( 'as yet unclassified' #label_off ) ) do: [ :each |
		icon := self materialIconIn: (self cellNamed: each first in: window).
		self assert: icon notNil description: each first.
		self assert: (icon valueOfProperty: #materialProtocolSymbol) equals: each second.
		self assert: (self definitionMorphOf: (self cellNamed: each first in: window)) identicalTo: icon.
		self assertForm: icon form isInColor: MaterialProtocolSymbols color ].
	"Pharo's icon of its meaning, where Calypso draws none: as on initialization"
	icon := self materialIconIn: (self cellNamed: 'instance initialization' in: window).
	self assert: (icon valueOfProperty: #materialProtocolSymbol) equals: #protocolProtected.
	self
		assert: (icon valueOfProperty: #materialProtocolFormSet)
		identicalTo: (Smalltalk ui icons iconFormSetNamed: #protocolProtected).
	self
		assert: ((self materialIconIn: (self cellNamed: 'accessing' in: window)) valueOfProperty: #materialProtocolFormSet)
		identicalTo: (MaterialProtocolSymbols formSetForProtocol: 'accessing').
	"Calypso's own icons"
	#( 'private' 'initialization' 'releasing' ) do: [ :each |
		| cell |
		cell := self cellNamed: each in: window.
		self assert: (self materialIconIn: cell) isNil.
		self assert: (self definitionMorphOf: cell) notNil ].
	"no symbol, no icon"
	self assert: (self materialIconIn: (self cellNamed: 'zork unmapped' in: window)) isNil.
	self assert: (self definitionMorphOf: (self cellNamed: 'zork unmapped' in: window)) isNil
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testQueryBrowserColumn [

	| window icons |
	window := self open: (ClyQueryBrowserMorph openOn: (ClyMessageImplementorsQuery of: #materialFixturePrinting)).
	"the cell of the protocol column (the method editor of the browser has its own icon in its status bar)"
	icons := window allMorphs select: [ :each |
		         (each hasProperty: #materialProtocolSymbol) and: [ each owner isMemberOf: ClyItemCellMorph ] ].
	self assert: icons size equals: 1.
	self assert: (icons first valueOfProperty: #materialProtocolSymbol) equals: 'printing'.
	self assert: (icons first owner label contents asString) equals: 'printing'.
	self
		assert: (icons first valueOfProperty: #materialProtocolFormSet)
		identicalTo: (MaterialProtocolSymbols browserFormSetForProtocol: 'printing').
	"the icon of the protocol pane: Pharo's own on private"
	window := self open: (ClyQueryBrowserMorph openOn: (ClyMessageImplementorsQuery of: #materialFixturePrivate)).
	icons := window allMorphs select: [ :each |
		         (each hasProperty: #materialProtocolSymbol) and: [ each owner isMemberOf: ClyItemCellMorph ] ].
	self assert: icons size equals: 1.
	self assert: (icons first valueOfProperty: #materialProtocolSymbol) equals: 'private'.
	self
		assert: (icons first valueOfProperty: #materialProtocolFormSet)
		identicalTo: (Smalltalk ui icons iconFormSetNamed: #protocolPrivate).
	window := self open: (ClyQueryBrowserMorph openOn: (ClyMessageImplementorsQuery of: #materialFixtureUnmapped)).
	self assert: (window allMorphs select: [ :each | each hasProperty: #materialProtocolSymbol ]) isEmpty
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testStatusBar [

	| window browser icon |
	browser := ClyFullBrowserMorph openOnMethod: self fixture >> #materialFixtureAccessing.
	window := self open: browser.
	self assert: (window allMorphs anySatisfy: [ :each | each isKindOf: MaterialProtocolIconKeeper ]).
	icon := self materialIconIn: (self protocolEditorIn: window).
	self assert: icon notNil.
	self
		assert: (icon valueOfProperty: #materialProtocolSymbol)
		identicalTo: (MaterialProtocolSymbols browserFormSetForProtocol: 'accessing').
	browser selectMethod: self fixture >> #materialFixtureUnmapped.
	self draw: window.
	self assert: (self materialIconIn: (self protocolEditorIn: window)) isNil.
	browser selectMethod: self fixture >> #materialFixturePrivate.
	self draw: window.
	icon := self materialIconIn: (self protocolEditorIn: window).
	self
		assert: (icon valueOfProperty: #materialProtocolSymbol)
		identicalTo: (Smalltalk ui icons iconFormSetNamed: #protocolPrivate).
	#( #materialFixtureRelease #materialFixtureInstanceInitialization ) do: [ :each |
		browser selectMethod: self fixture >> each.
		self draw: window.
		icon := self materialIconIn: (self protocolEditorIn: window).
		self
			assert: (icon valueOfProperty: #materialProtocolSymbol)
			identicalTo: (Smalltalk ui icons iconFormSetNamed: #protocolProtected) ].
	browser selectMethod: self fixture >> #materialFixturePrinting.
	self draw: window.
	icon := self materialIconIn: (self protocolEditorIn: window).
	self
		assert: (icon valueOfProperty: #materialProtocolSymbol)
		identicalTo: (MaterialProtocolSymbols formSetForProtocol: 'printing')
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testStatusBarOfAnExtensionMethod [
	"The status bar of an extension method shows its package: no icon there"

	| window |
	window := self openBrowserOn: MaterialProtocolSymbols >> #materialFixtureExtension.
	self assert: (window allMorphs anySatisfy: [ :each | each isKindOf: MaterialProtocolIconKeeper ]).
	self draw: window.
	(window allMorphs select: [ :each | each isKindOf: ClyStatusBarMorph ]) do: [ :bar |
		self assert: (self materialIconIn: bar) isNil ]
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testStatusBarLayoutIsPharos [
	"The keeper is out of the table layout of the status bar: the bar lays its contents out where it does without the keeper"

	| window keeper bar before |
	MaterialProtocolSymbols classVarNamed: #Enabled put: false.
	window := self openBrowserOn: self fixture >> #materialFixtureAccessing.
	keeper := window allMorphs detect: [ :each | each isKindOf: MaterialProtocolIconKeeper ].
	self assert: keeper extent equals: 0 @ 0.
	self assert: keeper disableTableLayout.
	bar := keeper owner.
	bar fullBounds.
	before := (bar submorphs copyWithout: keeper) collect: [ :each | each bounds ].
	self assert: before notEmpty.
	keeper delete.
	bar layoutChanged.
	bar fullBounds.
	self assert: (bar submorphs collect: [ :each | each bounds ]) equals: before
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testDetachFromABrowser [
	"What unloading the package does to every open browser: detachFrom: takes the plugin, the decorators of the method editors, the keepers and their icons out of a browser for good; removeIconsFrom: takes every icon of the package out of a morph"

	| browser window |
	browser := ClyFullBrowserMorph openOnMethod: self fixture >> #materialFixtureAccessing.
	window := self open: browser.
	self assert: (self materialIconIn: (self protocolEditorIn: window)) notNil.
	MaterialProtocolBrowserPlugin detachFrom: browser.
	self deny: (browser plugins anySatisfy: [ :each | each isKindOf: MaterialProtocolBrowserPlugin ]).
	self deny: (MaterialProtocolToolDecorator allInstances anySatisfy: [ :each |
			 each browserTool notNil and: [
				 each browserTool browser == browser and: [
					 (each browserTool instVarNamed: #decorators) includes: each ] ] ]).
	self deny: (window allMorphs anySatisfy: [ :each | each isKindOf: MaterialProtocolIconKeeper ]).
	self assert: (self materialIconIn: (self protocolEditorIn: window)) isNil.
	browser selectMethod: self fixture >> #materialFixturePrinting.
	self draw: window.
	self deny: (window allMorphs anySatisfy: [ :each | each isKindOf: MaterialProtocolIconKeeper ]).
	self assert: (self materialIconIn: (self protocolEditorIn: window)) isNil.
	"the protocol pane keeps its icons while the package is loaded"
	self assert: (self materialIconIn: window) notNil.
	MaterialProtocolGroupTableDecorator removeIconsFrom: window.
	self assert: (self materialIconIn: window) isNil
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testVirtualGroupsKeepTheirLook [
	"Calypso's virtual groups are not protocols, even where the table maps their name: the fixture's 'abstract' group (and 'deprecated', where Calypso has that group) and 'instance side' get no icon of mine, and the decorator of the pane does not want them"

	| window virtual |
	window := self openBrowserOn: self fixture >> #materialFixtureAccessing.
	virtual := (self protocolCellsIn: window) reject: [ :each |
		           #( #ClyMethodsInProtocolGroup #ClyUnclassifiedMethodGroup ) includes:
			           each item actualObject class name ].
	self assert: (MaterialProtocolSymbols symbolNameForProtocol: 'abstract') notNil.
	self assert: (MaterialProtocolSymbols symbolNameForProtocol: 'deprecated') notNil.
	self assert: (virtual anySatisfy: [ :each | each item name = 'abstract' ]).
	self assert: (virtual anySatisfy: [ :each | each item actualObject isKindOf: ClyAllMethodGroup ]).
	virtual do: [ :each |
		self deny: (MaterialProtocolGroupTableDecorator wantsDecorateTableCellOf: each item).
		self assert: (self materialIconIn: each) isNil ].
	virtual
		detect: [ :each | each item name = 'abstract' ]
		ifFound: [ :cell | self assert: (self definitionMorphOf: cell) isNil ]
]

{ #category : 'tests' }
MaterialProtocolSymbolsCalypsoTest >> testSwitch [
	"enabled: false takes every icon of mine away from the open browsers, Pharo's stay; enabled: true gives them back"

	| window |
	window := self openBrowserOn: self fixture >> #materialFixtureAccessing.
	self assert: (self materialIconIn: (self cellNamed: 'accessing' in: window)) notNil.
	MaterialProtocolSymbols enabled: false.
	self draw: window.
	self assert: (self materialIconIn: window) isNil.
	self assert: (self definitionMorphOf: (self cellNamed: 'accessing' in: window)) isNil.
	self assert: (self definitionMorphOf: (self cellNamed: 'private' in: window)) notNil.
	MaterialProtocolSymbols enabled: true.
	self draw: window.
	self assert: (self materialIconIn: (self cellNamed: 'accessing' in: window)) notNil.
	self assert: (self materialIconIn: (self protocolEditorIn: window)) notNil
]
