"
I test `MaterialProtocolSymbols`: the normalisation of protocol names, the exact, prefix (longest first, followed by a non-letter) and extension rows, the names of the survey's top list and their symbols, that every symbol exists and that distinct meanings have distinct symbols, that the table agrees with scripts/protocol-symbols.tsv (when the clone it was loaded from is on disk), the colour (a Material pack installed in a fixed colour, monochrome or not, in the colour of the theme, none installed, a change of the UI theme), the icons a browser shows (Pharo's own for the names Calypso decorates) and the switch `enabled`.

I leave the UI as I found it: its icon pack, its theme and the switch.
"
Class {
	#name : 'MaterialProtocolSymbolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'enabledBefore',
		'installedBefore',
		'lastFallbackBefore',
		'previousPack',
		'themeBefore'
	],
	#category : 'MaterialSymbols-Protocols-Tests',
	#package : 'MaterialSymbols-Protocols-Tests'
}

{ #category : 'asserting' }
MaterialProtocolSymbolsTest >> assertForm: aForm isInColor: aColor [
	"aForm has ink, and every pixel of it that is not transparent is aColor"

	aForm unhibernate.
	self assert: (aForm bits anySatisfy: [ :pixel | (pixel bitShift: -24) > 0 ]).
	self assert: ((aForm bits reject: [ :pixel | (pixel bitShift: -24) = 0 ]) allSatisfy: [ :pixel |
			 (pixel bitAnd: 16rFFFFFF) = ((aColor pixelValueForDepth: 32) bitAnd: 16rFFFFFF) ])
]

{ #category : 'running' }
MaterialProtocolSymbolsTest >> defaultTimeLimit [

	^ 2 minutes
]

{ #category : 'accessing' }
MaterialProtocolSymbolsTest >> otherThemeClass [
	"The other of Pharo's light and dark UI themes, whose text colours differ, or nil"

	^ UITheme allSubclasses
		  detect: [ :each |
			  each ~~ Smalltalk ui theme class and: [
				  #( #PharoLightTheme #PharoDarkTheme ) includes: each name ] ]
		  ifNone: [ nil ]
]

{ #category : 'running' }
MaterialProtocolSymbolsTest >> setUp [

	| current |
	super setUp.
	enabledBefore := MaterialProtocolSymbols classVarNamed: #Enabled.
	themeBefore := Smalltalk ui theme class.
	current := ThemeIcons classVarNamed: #Current.
	installedBefore := (current isKindOf: MaterialAbstractThemeIcons)
		                   ifTrue: [ current ]
		                   ifFalse: [ nil ].
	(Smalltalk globals at: #MaterialSymbolsThemeIcons ifAbsent: [ nil ]) ifNotNil: [ :class |
		lastFallbackBefore := class instVarNamed: #lastFallback ].
	installedBefore ifNotNil: [ installedBefore class uninstall ].
	previousPack := ThemeIcons current
]

{ #category : 'accessing' }
MaterialProtocolSymbolsTest >> symbolsThemeIcons [
	"MaterialSymbolsThemeIcons, or nil (MaterialSymbols-Protocols does not need it)"

	^ Smalltalk globals at: #MaterialSymbolsThemeIcons ifAbsent: [ nil ]
]

{ #category : 'running' }
MaterialProtocolSymbolsTest >> tearDown [

	Smalltalk ui theme class == themeBefore ifFalse: [ themeBefore beCurrent ].
	MaterialAbstractThemeIcons allSubclasses do: [ :each |
		each unsubscribeFromThemeChanges ].
	ThemeIcons current == previousPack ifFalse: [ previousPack beCurrent ].
	self symbolsThemeIcons ifNotNil: [ :class |
		class instVarNamed: #lastFallback put: lastFallbackBefore ].
	installedBefore ifNotNil: [
		installedBefore beCurrent.
		installedBefore class subscribeToThemeChanges ].
	MaterialProtocolSymbols classVarNamed: #Enabled put: enabledBefore.
	MaterialProtocolSymbols flushCache.
	super tearDown
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testBrowserIconsArePharosWhereCalypsoDecorates [
	"Where Calypso's protocol pane draws its own icon the browsers show that one, so that a protocol has one icon everywhere"

	#( #( 'private' #protocolPrivate ) #( 'private - accessing' #protocolPrivate )
	   #( 'initialization' #protocolProtected ) #( 'class initialization' #protocolProtected )
	   #( 'initialize-release' #protocolProtected ) #( 'finalization' #protocolProtected )
	   #( '*Roassal-Examples' #protocolExtension ) ) do: [ :each |
		self
			assert: (MaterialProtocolSymbols pharoIconNameForProtocol: each first)
			equals: each second.
		self
			assert: (MaterialProtocolSymbols browserFormSetForProtocol: each first)
			identicalTo: (Smalltalk ui icons iconFormSetNamed: each second) ].
	#( 'accessing' 'printing' 'tests' 'instance creation' ) do: [ :each |
		self assert: (MaterialProtocolSymbols pharoIconNameForProtocol: each) isNil.
		self
			assert: (MaterialProtocolSymbols browserFormSetForProtocol: each)
			identicalTo: (MaterialProtocolSymbols formSetForProtocol: each) ].
	self assert: (MaterialProtocolSymbols browserFormSetForProtocol: 'zork') isNil
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testColorOfAPackInAFixedColor [
	"The colour of the installed Material pack, monochrome or not (the status colours of the pack are not those of protocols)"

	self symbolsThemeIcons ifNil: [ ^ self skip: 'MaterialSymbols-ThemePack is not loaded' ].
	#( true false ) do: [ :monochrome |
		| pack |
		pack := self symbolsThemeIcons installColor: Color gray monochrome: monochrome.
		self assert: MaterialProtocolSymbols color equals: Color gray.
		self assert: MaterialProtocolSymbols color equals: pack effectiveColor.
		self
			assertForm: (MaterialProtocolSymbols formForProtocol: 'accessing')
			isInColor: Color gray.
		(MaterialProtocolSymbols formSetForProtocol: 'printing') forms do: [ :each |
			self assertForm: each isInColor: Color gray ].
		self
			assertForm: (MaterialProtocolSymbols browserFormSetForProtocol: 'tests') asForm
			isInColor: Color gray ]
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testColorOfAPackOfTheTheme [

	| pack |
	self symbolsThemeIcons ifNil: [ ^ self skip: 'MaterialSymbols-ThemePack is not loaded' ].
	pack := self symbolsThemeIcons install.
	self assert: MaterialProtocolSymbols color equals: pack effectiveColor.
	self assert: MaterialProtocolSymbols color equals: Smalltalk ui theme textColor.
	self
		assertForm: (MaterialProtocolSymbols formForProtocol: 'accessing')
		isInColor: Smalltalk ui theme textColor
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testColorWithoutAPack [
	"No Material pack: the colour of the Material Symbols, that of the text of the UI theme"

	self deny: MaterialAbstractThemeIcons isInstalled.
	self
		assert: MaterialProtocolSymbols color
		equals: MaterialProtocolSymbols provider color.
	MaterialProtocolSymbols provider followsTheme ifTrue: [
		self
			assert: MaterialProtocolSymbols color
			equals: Smalltalk ui theme textColor ].
	self
		assertForm: (MaterialProtocolSymbols formForProtocol: 'accessing')
		isInColor: MaterialProtocolSymbols color.
	self
		assert: (MaterialProtocolSymbols formSetForProtocol: 'accessing')
		identicalTo: (MaterialProtocolSymbols formSetForProtocol: 'Accessing')
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testDistinctMeaningsHaveDistinctSymbols [

	| names symbols |
	names := #( 'accessing' 'testing' 'tests' 'running' 'initialization'
	            'class initialization' 'instance creation' 'private' 'public' 'api'
	            'printing' 'converting' 'comparing' 'copying' 'enumerating'
	            'adding' 'removing' 'visiting' 'actions' 'examples' 'deprecated'
	            'debugging' 'settings' 'utilities' 'hooks' 'drawing' 'rendering'
	            'events' 'as yet unclassified' '*Foo' 'updating' 'querying'
	            'layout' 'factory' 'helpers' 'asserting' 'tests - fixture' ).
	symbols := names collect: [ :each |
		           MaterialProtocolSymbols symbolNameForProtocol: each ].
	self deny: (symbols includes: nil).
	self assert: symbols asSet size equals: names size
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testEnabled [

	MaterialProtocolSymbols classVarNamed: #Enabled put: nil.
	self assert: MaterialProtocolSymbols enabled.
	MaterialProtocolSymbols enabled: false.
	self deny: MaterialProtocolSymbols enabled.
	self assert: (MaterialProtocolSymbols browserFormSetForProtocol: 'accessing') isNil.
	self assert: (MaterialProtocolSymbols browserFormSetForProtocol: 'private') isNil.
	"the API itself still answers"
	self assert: (MaterialProtocolSymbols symbolNameForProtocol: 'accessing') equals: #key.
	MaterialProtocolSymbols enabled: true.
	self assert: MaterialProtocolSymbols enabled.
	self assert: (MaterialProtocolSymbols browserFormSetForProtocol: 'accessing') notNil
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testEverySymbolExists [

	| rows |
	rows := MaterialProtocolSymbolsTable rows.
	self assert: rows size > 200.
	rows do: [ :row |
		self assert: row size equals: 3.
		self assert: (#( #exact #prefix #extension ) includes: row second).
		self assert: (MaterialProtocolSymbols normalise: row first) equals: row first.
		self assert: (MaterialProtocolSymbols provider includesIcon: row third) description: row third.
		self
			assert: (MaterialProtocolSymbols formSetForProtocol: (row second = #extension
						  ifTrue: [ row first , 'Some-Package' ]
						  ifFalse: [ row first ])) notNil ]
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testExactRows [

	#( #( 'printing' #print ) #( 'Printing' #print ) #( '  printing ' #print )
	   #( 'testing' #question_mark ) #( 'tests' #labs ) #( 'class initialization' #settings_power )
	   #( 'instance creation' #fiber_new ) #( 'Instance   Creation' #fiber_new )
	   #( 'as yet unclassified' #label_off ) #( 'utilities' #handyman ) #( 'utils' #handyman )
	   #( 'conversion' #swap_horiz ) #( 'trait protocol conflict' #swords ) ) do: [ :each |
		self
			assert: (MaterialProtocolSymbols symbolNameForProtocol: each first)
			equals: each second ]
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testExtensionRows [

	#( '*Roassal-Examples' '*NewTools-Inspector-Extensions' '*Deprecated14' '*Foo' '*' ) do: [ :each |
		self
			assert: (MaterialProtocolSymbols symbolNameForProtocol: each)
			equals: #extension ]
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testNormalise [

	#( #( 'accessing' 'accessing' ) #( '  Accessing  ' 'accessing' )
	   #( 'accessing-defaults' 'accessing - defaults' ) #( 'accessing -defaults' 'accessing - defaults' )
	   #( 'Accessing - Defaults' 'accessing - defaults' ) #( 'tests   -  printing' 'tests - printing' )
	   #( 'instance  creation' 'instance creation' ) #( 'initialize-release' 'initialize - release' )
	   #( '*Roassal-Examples' '*roassal-examples' ) #( '' '' ) ) do: [ :each |
		self assert: (MaterialProtocolSymbols normalise: each first) equals: each second ]
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testPrefixRows [
	"The longest prefix wins, and a prefix covers the names where a non-letter follows it"

	#( #( 'accessing - foo' #key ) #( 'accessing-ui' #key ) #( 'accessing - defaults' #settings_backup_restore )
	   #( 'accessing - defaults - colors' #settings_backup_restore ) #( 'private - accessing' #lock_person )
	   #( 'private-testing' #lock_person ) #( 'tests - printing' #labs ) #( 'tests - fixture' #home_repair_service )
	   #( 'testing - interest' #question_mark ) #( 'test - help' #labs ) #( 'initialize-release' #power_settings_new )
	   #( 'api - events' #api ) #( 'printing/displaying' #print ) ) do: [ :each |
		self
			assert: (MaterialProtocolSymbols symbolNameForProtocol: each first)
			equals: each second ].
	"testing is not test followed by more letters, and accessingfoo is no accessing"
	self assert: (MaterialProtocolSymbols symbolNameForProtocol: 'testing') equals: #question_mark.
	self assert: (MaterialProtocolSymbols symbolNameForProtocol: 'accessingfoo') isNil.
	self assert: (MaterialProtocolSymbols symbolNameForProtocol: 'privately') isNil
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testProtocolObjects [

	| protocol |
	protocol := OrderedCollection protocols detect: [ :each | each name = #accessing ].
	self assert: (MaterialProtocolSymbols symbolNameForProtocol: protocol) equals: #key.
	self
		assert: (MaterialProtocolSymbols formSetForProtocol: protocol)
		identicalTo: (MaterialProtocolSymbols formSetForProtocol: 'accessing')
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testSetting [
	"A check box under Appearance in the Settings browser that reads and writes enabled. Pharo 15 builds its settings with SettingsBuilder, Pharo 12 to 14 with SettingTree: the messages to the one of the other versions are performed, so that each version knows every message sent"

	| setting |
	(Smalltalk globals at: #SettingsBuilder ifAbsent: [ nil ]) ifNotNil: [ :builder |
		setting := (builder perform: #forPragmaNamed: with: #systemsettings) settings
			           detect: [ :each | each name = #materialProtocolSymbols ]
			           ifNone: [ nil ].
		self assert: setting notNil.
		self assert: setting parentName equals: #appearance ].
	setting ifNil: [
		setting := ((Smalltalk globals at: #SettingTree) new
			            perform: #acceptableKeywords:
			            with: #( #systemsettings );
			            nodeList)
			           detect: [ :each | each settingDeclaration name = #materialProtocolSymbols ]
			           ifNone: [ nil ].
		self assert: setting notNil.
		self assert: setting parentName equals: #appearance.
		setting := setting settingDeclaration ].
	MaterialProtocolSymbols enabled: true.
	self assert: setting realValue.
	setting realValue: false.
	self deny: MaterialProtocolSymbols enabled.
	setting realValue: true.
	self assert: MaterialProtocolSymbols enabled
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testTableAgreesWithTheTsv [
	"MaterialProtocolSymbolsTable is scripts/protocol-symbols.tsv, read from the clone the package was loaded from"

	| file lines header rows |
	file := MaterialProtocolSymbols tsvFile.
	file ifNil: [ ^ self skip: 'scripts/protocol-symbols.tsv is not on disk' ].
	lines := file contents lines reject: [ :each |
		         each isEmpty or: [ each first = $# ] ].
	header := lines first substrings: (String with: Character tab).
	rows := lines allButFirst collect: [ :each |
		        | fields |
		        fields := each substrings: (String with: Character tab).
		        {
			        (fields at: (header indexOf: 'protocol')).
			        (fields at: (header indexOf: 'match')) asSymbol.
			        (fields at: (header indexOf: 'symbolName')) asSymbol } ].
	self assert: rows asArray equals: MaterialProtocolSymbolsTable rows
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testThemeChange [
	"Without a Material pack in a fixed colour the icons are in the text colour of the UI theme, and follow it when it changes"

	| other before |
	other := self otherThemeClass ifNil: [ ^ self skip: 'one UI theme only' ].
	MaterialProtocolSymbols provider followsTheme ifFalse: [
		^ self skip: 'MaterialIcons symbolsRounded has a fixed colour' ].
	self deny: MaterialAbstractThemeIcons isInstalled.
	before := MaterialProtocolSymbols formSetForProtocol: 'accessing'.
	other beCurrent.
	self assert: MaterialProtocolSymbols color equals: Smalltalk ui theme textColor.
	self deny: (MaterialProtocolSymbols formSetForProtocol: 'accessing') == before.
	self
		assertForm: (MaterialProtocolSymbols formSetForProtocol: 'accessing') asForm
		isInColor: Smalltalk ui theme textColor
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testThemeChangeWithAPack [
	"A pack in the colour of the theme follows it, and so do the protocols"

	| other |
	self symbolsThemeIcons ifNil: [ ^ self skip: 'MaterialSymbols-ThemePack is not loaded' ].
	other := self otherThemeClass ifNil: [ ^ self skip: 'one UI theme only' ].
	self symbolsThemeIcons install.
	other beCurrent.
	self assert: MaterialProtocolSymbols color equals: Smalltalk ui theme textColor.
	self
		assertForm: (MaterialProtocolSymbols formForProtocol: 'testing')
		isInColor: Smalltalk ui theme textColor
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testTopProtocols [
	"The most used protocols of Pharo 15 with its usual packages (the survey of the batteries image), and their symbols"

	#( #( 'accessing' #key ) #( 'testing' #question_mark ) #( 'initialization' #power_settings_new )
	   #( '*Some-Package' #extension ) #( 'tests' #labs ) #( 'instance creation' #fiber_new )
	   #( 'private' #lock_person ) #( 'running' #sprint ) #( 'printing' #print ) #( 'removing' #remove )
	   #( 'visiting' #tour ) #( 'comparing' #compare_arrows ) #( 'converting' #swap_horiz )
	   #( 'querying' #manage_search ) #( 'organization' #folder_open )
	   #( 'accessing - method dictionary' #dictionary ) #( 'trait composition' #layers )
	   #( 'categories' #category ) #( 'recompilation' #build_circle ) #( 'execution' #play_arrow )
	   #( 'class initialization' #settings_power ) #( 'layout' #dashboard ) #( 'executing' #play_arrow )
	   #( 'actions' #bolt ) #( 'api' #api ) #( 'helpers' #support ) #( 'examples' #lightbulb )
	   #( 'adding' #add ) #( 'utilities' #handyman ) #( 'copying' #content_copy ) #( 'public' #public )
	   #( 'hooks' #phishing ) #( 'enumerating' #repeat ) #( 'updating' #sync )
	   #( 'accessing - defaults' #settings_backup_restore ) #( 'drawing' #draw )
	   #( 'operations' #precision_manufacturing ) #( 'default' #settings_backup_restore )
	   #( 'factory' #factory ) #( 'visitor' #tour ) #( 'rendering' #brush ) #( 'event handling' #touch_app )
	   #( 'building' #construction ) #( 'displaying' #monitor ) #( 'preconditions' #rule )
	   #( 'settings' #settings ) #( 'events' #touch_app ) #( 'baselines' #schema ) #( 'specs' #view_quilt )
	   #( 'transforming' #transform ) #( 'activation' #toggle_on ) #( 'defaults' #settings_backup_restore )
	   #( 'configuration' #tune ) #( 'evaluating' #function ) #( 'asserting' #verified )
	   #( 'writing' #output ) #( 'requirements' #line_end_circle ) #( 'tests - fixture' #home_repair_service )
	   #( 'documentation' #menu_book ) #( 'parsing' #data_object ) #( 'storing' #save )
	   #( 'reading' #input ) #( 'menu' #menu ) #( 'system startup' #rocket_launch ) #( 'deprecated' #auto_delete )
	   #( 'debugging' #bug_report ) #( 'as yet unclassified' #label_off ) ) do: [ :each |
		self
			assert: (MaterialProtocolSymbols symbolNameForProtocol: each first)
			equals: each second ]
]

{ #category : 'tests' }
MaterialProtocolSymbolsTest >> testUnmapped [
	"No symbol, never a placeholder"

	#( 'zork' 'splitjoin' 'protocol' '' 'accessingfoo' ) do: [ :each |
		self assert: (MaterialProtocolSymbols symbolNameForProtocol: each) isNil.
		self assert: (MaterialProtocolSymbols formSetForProtocol: each) isNil.
		self assert: (MaterialProtocolSymbols formForProtocol: each) isNil.
		self assert: (MaterialProtocolSymbols browserFormSetForProtocol: each) isNil ].
	self assert: (MaterialProtocolSymbols symbolNameForProtocol: nil) isNil
]
