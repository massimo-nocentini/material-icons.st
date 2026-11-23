"
I give method protocols a Material Symbol: `accessing` the key, `testing` the question mark, `tests` the lab flask, `printing` the printer, `instance creation` a plus in a box... The table is data, scripts/protocol-symbols.tsv, written as MaterialProtocolSymbolsTable by scripts/protocol_symbols.py.

```
MaterialProtocolSymbols symbolNameForProtocol: 'accessing'.			""#key""
MaterialProtocolSymbols symbolNameForProtocol: 'Accessing-defaults'.	""#settings_backup_restore""
MaterialProtocolSymbols symbolNameForProtocol: 'tests - printing'.	""#labs, the family tests - ""
MaterialProtocolSymbols symbolNameForProtocol: '*Roassal-Examples'.	""#extension""
MaterialProtocolSymbols symbolNameForProtocol: 'zork'.				""nil: not mapped""
MaterialProtocolSymbols symbolNameForProtocol: (OrderedCollection protocolNamed: #accessing).
MaterialProtocolSymbols formSetForProtocol: 'printing'.	""a FormSet, 16x16 with its 24 and 32 pixel Forms""
MaterialProtocolSymbols formForProtocol: 'printing'.		""a Form, 16x16""
MaterialProtocolSymbols enabled: false.	""the browsers without these icons (Settings > Appearance)""
```

A name is normalised (`normalise:`: trimmed, lower case, one blank between words, ' - ' around every '-'), then it takes its exact row, else its longest prefix row (the pattern followed by a non-letter: `private` covers `private - accessing`, `test` does not cover `testing`); a protocol of an extension method (`*Package`) takes the extension rows. A name of no row has no symbol: nil, never a placeholder, and so has a symbol that the loaded Material Symbols lack.

The icons are in the colour of the installed Material pack of the UI (MaterialSymbolsThemeIcons or MaterialThemeIcons, its `effectiveColor`: grey after `installColor: Color gray`), else in that of `MaterialIcons symbolsRounded` (the text colour of the UI theme unless `color:` fixed it), and they follow theme changes. Never a fixed status colour.

The browsers show them through the package MaterialSymbols-Protocols-Calypso (the protocol pane of the system browser, the protocol of the method editor's status bar, the protocol column of the query browsers), where Pharo shows no icon of its own, while `enabled` (default true, in the Settings browser under Appearance). `browserFormSetForProtocol:` is the icon those places show: nil when I am disabled, the icon of Pharo where Pharo has one for the protocol (`browserPharoIconNameForProtocol:`: the one Calypso's protocol pane draws itself on the names it decorates, `pharoIconNameForProtocol:`, and the one of the meaning of the row, `pharoIconNameForSymbol:`: initialization, class initialization, finalization, protected, private, extensions), so that a protocol has one icon everywhere, else mine. The symbols of those rows are answered by the API only.
"
Class {
	#name : 'MaterialProtocolSymbols',
	#superclass : 'Object',
	#classVars : [
		'Enabled',
		'Exact',
		'Extensions',
		'FormSets',
		'FormSetsColor',
		'FormSetsSession',
		'IndexedRows',
		'Prefixes',
		'Resolved'
	],
	#category : 'MaterialSymbols-Protocols',
	#package : 'MaterialSymbols-Protocols'
}

{ #category : 'icons' }
MaterialProtocolSymbols class >> browserFormSetForProtocol: aStringOrProtocol [
	"The icon a browser shows next to the protocol aStringOrProtocol: nil when I am disabled; Pharo's icon where Pharo has one for that protocol (browserPharoIconNameForProtocol:), so that the protocol has the same icon everywhere; else mine, or nil"

	| name |
	self enabled ifFalse: [ ^ nil ].
	name := self nameOf: aStringOrProtocol.
	(self browserPharoIconNameForProtocol: name) ifNotNil: [ :key |
		^ Smalltalk ui icons iconFormSetNamed: key ifNone: [ nil ] ].
	^ self formSetForProtocol: name
]

{ #category : 'icons' }
MaterialProtocolSymbols class >> browserPharoIconNameForProtocol: aStringOrProtocol [
	"The key of the icon of Pharo that the browsers show next to the protocol aStringOrProtocol instead of its Material Symbol, or nil: the icon Calypso's protocol pane draws itself on that name (pharoIconNameForProtocol:: private..., initial..., releas..., finali..., *Package), else the icon of Pharo for the meaning of its row (pharoIconNameForSymbol:), so that 'instance initialization' looks like 'initialization' and 'protected' like Calypso's protected protocols"

	^ (self pharoIconNameForProtocol: aStringOrProtocol) ifNil: [
		  (self symbolNameForProtocol: aStringOrProtocol) ifNotNil: [ :symbolName |
			  self pharoIconNameForSymbol: symbolName ] ]
]

{ #category : 'accessing' }
MaterialProtocolSymbols class >> color [
	"The colour of my icons: that of the installed Material pack of the UI, else that of the Material Symbols (the text colour of the UI theme unless fixed)"

	MaterialAbstractThemeIcons installed ifNotNil: [ :pack |
		^ pack effectiveColor ].
	^ self provider color
]

{ #category : 'settings' }
MaterialProtocolSymbols class >> enabled [
	"Whether the browsers show my icons"

	^ Enabled ifNil: [ true ]
]

{ #category : 'settings' }
MaterialProtocolSymbols class >> enabled: aBoolean [
	"Show my icons in the browsers or not; the open ones are redrawn"

	Enabled := aBoolean.
	self refreshBrowsers
]

{ #category : 'caching' }
MaterialProtocolSymbols class >> flushCache [
	"Forget the FormSets drawn so far and the names resolved so far"

	FormSets := nil.
	FormSetsColor := nil.
	FormSetsSession := nil.
	IndexedRows := nil
]

{ #category : 'icons' }
MaterialProtocolSymbols class >> formForProtocol: aStringOrProtocol [
	"The icon of the protocol aStringOrProtocol, 16x16 in my colour, or nil when it has none"

	^ (self symbolNameForProtocol: aStringOrProtocol) ifNotNil: [ :symbolName |
		  self provider formNamed: symbolName scale: 1 color: self color ]
]

{ #category : 'icons' }
MaterialProtocolSymbols class >> formSetForProtocol: aStringOrProtocol [
	"The icon of the protocol aStringOrProtocol, a FormSet (16x16, with its Forms of 24 and 32 pixels for HiDPI) in my colour, or nil when it has none"

	^ (self symbolNameForProtocol: aStringOrProtocol) ifNotNil: [ :symbolName |
		  self formSetNamed: symbolName ]
]

{ #category : 'icons' }
MaterialProtocolSymbols class >> formSetNamed: aSymbol [
	"The Material Symbol aSymbol as a FormSet in my colour, kept until the colour changes: the browsers ask for it on every row they draw"

	| color |
	color := self color.
	(FormSetsSession == Smalltalk session and: [ FormSetsColor = color ]) ifFalse: [
		FormSets := Dictionary new.
		FormSetsColor := color.
		FormSetsSession := Smalltalk session ].
	^ FormSets
		  at: aSymbol
		  ifAbsentPut: [ self provider formSetNamed: aSymbol color: color ]
]

{ #category : 'private' }
MaterialProtocolSymbols class >> index [
	"Build the index of the rows of the table when they changed (a new MaterialProtocolSymbolsTable)"

	| rows |
	rows := MaterialProtocolSymbolsTable rows.
	IndexedRows == rows ifTrue: [ ^ self ].
	Exact := Dictionary new.
	Prefixes := OrderedCollection new.
	Extensions := OrderedCollection new.
	rows do: [ :row |
		row second = #exact ifTrue: [ Exact at: row first put: row third ].
		row second = #prefix ifTrue: [ Prefixes add: row first -> row third ].
		row second = #extension ifTrue: [ Extensions add: row first allButFirst -> row third ] ].
	Prefixes := (Prefixes asArray sort: [ :a :b | a key size >= b key size ]).
	Extensions := (Extensions asArray sort: [ :a :b | a key size >= b key size ]).
	Resolved := Dictionary new.
	IndexedRows := rows
]

{ #category : 'class initialization' }
MaterialProtocolSymbols class >> initialize [
	"Redraw the icons when the UI theme changes; forget them when the image is saved"

	SessionManager default registerToolClassNamed: self name.
	self subscribeToThemeChanges
]

{ #category : 'private' }
MaterialProtocolSymbols class >> nameOf: aStringOrProtocol [
	"The name of a protocol given by its name or as an object that knows it (a Protocol, a Calypso method group)"

	aStringOrProtocol ifNil: [ ^ '' ].
	^ aStringOrProtocol isString
		  ifTrue: [ aStringOrProtocol ]
		  ifFalse: [ aStringOrProtocol name asString ]
]

{ #category : 'resolving' }
MaterialProtocolSymbols class >> normalise: aString [
	"The name of a protocol as the table compares it: trimmed, lower case, one blank between words, ' - ' around every '-' (not in the name of an extension protocol, '*Package-tag')"

	| name |
	name := ' ' join: aString asString asLowercase substrings.
	(name beginsWith: '*') ifTrue: [ ^ name ].
	^ ' ' join: (name copyReplaceAll: '-' with: ' - ') substrings
]

{ #category : 'icons' }
MaterialProtocolSymbols class >> pharoIconNameForProtocol: aStringOrProtocol [
	"The key of the icon that Calypso's protocol pane draws itself on the protocol aStringOrProtocol (ClyMethodsInProtocolGroup>>#decorateTableCell:of:, ClyExternalPackageMethodGroup), or nil. There my icons give way to Pharo's"

	| name |
	name := (self nameOf: aStringOrProtocol) asLowercase.
	(name beginsWith: '*') ifTrue: [ ^ #protocolExtension ].
	(name beginsWith: 'private') ifTrue: [ ^ #protocolPrivate ].
	(#( 'initial' 'class initial' 'releaz' 'releas' 'finali' ) anySatisfy: [ :each |
		 name beginsWith: each ]) ifTrue: [ ^ #protocolProtected ].
	^ nil
]

{ #category : 'icons' }
MaterialProtocolSymbols class >> pharoIconNameForSymbol: aSymbol [
	"The key of the icon of Pharo for the meaning of the rows of the Material Symbol aSymbol, where Calypso draws that icon on the protocols of that meaning, or nil: the rows of initialization, class initialization, finalization and protected (protocolProtected), of private (protocolPrivate) and of extensions (protocolExtension)"

	^ ({
		   (#power_settings_new -> #protocolProtected).
		   (#settings_power -> #protocolProtected).
		   (#recycling -> #protocolProtected).
		   (#shield -> #protocolProtected).
		   (#lock_person -> #protocolPrivate).
		   (#extension -> #protocolExtension) } asDictionary)
		  at: aSymbol
		  ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MaterialProtocolSymbols class >> provider [
	"The Material Symbols my icons are drawn from"

	^ MaterialIcons symbolsRounded
]

{ #category : 'refreshing' }
MaterialProtocolSymbols class >> refreshBrowsers [
	"Have the open browsers draw their protocols again: the class methods of the pragma <materialProtocolSymbolsRefresh> (package MaterialSymbols-Protocols-Calypso) know them"

	(Pragma allNamed: #materialProtocolSymbolsRefresh) do: [ :each |
		[ each methodClass instanceSide perform: each method selector ]
			on: Error
			do: [ :error | error return: nil ] ]
]

{ #category : 'resolving' }
MaterialProtocolSymbols class >> resolve: aNormalisedName [
	"The symbol name of the row aNormalisedName takes, or nil"

	| name |
	name := aNormalisedName.
	name isEmpty ifTrue: [ ^ nil ].
	name first = $* ifTrue: [
		^ (Extensions
			   detect: [ :each |
			   each key isEmpty or: [ name allButFirst includesSubstring: each key ] ]
			   ifNone: [ nil ]) ifNotNil: [ :row | row value ] ].
	Exact at: name ifPresent: [ :symbolName | ^ symbolName ].
	^ (Prefixes
		   detect: [ :each |
			   name = each key or: [
				   (name beginsWith: each key) and: [
					   (name at: each key size + 1) isLetter not ] ] ]
		   ifNone: [ nil ]) ifNotNil: [ :row | row value ]
]

{ #category : 'settings' }
MaterialProtocolSymbols class >> settingsOn: aBuilder [
	"A check box under Appearance. Pharo 15 names the parent with parentName: (its parent: takes a setting), Pharo 12 to 14 with parent:"

	<systemsettings>
	| setting |
	setting := aBuilder setting: #materialProtocolSymbols.
	(setting respondsTo: #parentName:)
		ifTrue: [ setting parentName: #appearance ]
		ifFalse: [ setting parent: #appearance ].
	setting
		target: self;
		selector: #enabled;
		label: 'Material Symbols of protocols';
		description:
			'Show a Material Symbol next to the common method protocols (accessing, testing, initialization, printing...) in the protocol pane of the system browser, in the status bar of the method editor and in the protocol column of the query browsers, where Pharo shows no icon of its own'
]

{ #category : 'system startup' }
MaterialProtocolSymbols class >> shutDown: isImageQuitting [
	"The image is about to be saved: do not save the FormSets with it"

	FormSets := nil.
	FormSetsSession := nil
]

{ #category : 'event handling' }
MaterialProtocolSymbols class >> subscribeToThemeChanges [

	self unsubscribeFromThemeChanges.
	self codeSupportAnnouncer
		when: UIThemeChanged
		send: #themeChanged:
		to: self
]

{ #category : 'resolving' }
MaterialProtocolSymbols class >> symbolNameForProtocol: aStringOrProtocol [
	"The name of the Material Symbol of the protocol aStringOrProtocol (a name, or a Protocol), or nil when the table maps none or the Material Symbols lack it"

	| name |
	self index.
	name := self normalise: (self nameOf: aStringOrProtocol).
	^ Resolved at: name ifAbsentPut: [
		  (self resolve: name) ifNotNil: [ :symbolName |
			  (self provider includesIcon: symbolName)
				  ifTrue: [ symbolName ]
				  ifFalse: [ nil ] ] ]
]

{ #category : 'accessing' }
MaterialProtocolSymbols class >> tsvFile [
	"scripts/protocol-symbols.tsv of the clone of material-icons.st that MaterialSymbols-Protocols was loaded from (a tonel:// or filetree:// repository, or an Iceberg repository), or nil"

	| workingCopy |
	workingCopy := [ MCWorkingCopy forPackageNamed: 'MaterialSymbols-Protocols' ]
		               on: Error
		               do: [ :error | error return: nil ].
	workingCopy ifNotNil: [
		workingCopy repositoryGroup repositories do: [ :each |
			(self tsvFileIn: [ each directory parent ]) ifNotNil: [ :file | ^ file ] ] ].
	(Smalltalk globals at: #IceRepository ifAbsent: [ nil ]) ifNotNil: [ :iceberg |
		([ iceberg registry ]
			 on: Error
			 do: [ :error | error return: #(  ) ]) do: [ :each |
			(self tsvFileIn: [
				 (each includesPackageNamed: 'MaterialSymbols-Protocols')
					 ifTrue: [ each location ]
					 ifFalse: [ nil ] ]) ifNotNil: [ :file | ^ file ] ] ].
	^ nil
]

{ #category : 'private' }
MaterialProtocolSymbols class >> tsvFileIn: aBlock [
	"scripts/protocol-symbols.tsv in the directory aBlock answers, if it exists there"

	^ [
	  aBlock value ifNotNil: [ :directory |
		  | file |
		  file := directory / 'scripts' / 'protocol-symbols.tsv'.
		  file exists
			  ifTrue: [ file ]
			  ifFalse: [ nil ] ] ]
		  on: Error
		  do: [ :error | error return: nil ]
]

{ #category : 'event handling' }
MaterialProtocolSymbols class >> themeChanged: anAnnouncement [
	"Draw the icons again in the colours of the new theme"

	FormSets := nil.
	FormSetsSession := nil.
	self refreshBrowsers
]

{ #category : 'class initialization' }
MaterialProtocolSymbols class >> unload [

	self unsubscribeFromThemeChanges.
	SessionManager default unregisterClassNamed: self name
]

{ #category : 'event handling' }
MaterialProtocolSymbols class >> unsubscribeFromThemeChanges [

	self codeSupportAnnouncer unsubscribe: self
]
