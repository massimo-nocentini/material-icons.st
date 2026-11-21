"
I test `MaterialThemeIcons`, the Material icon pack of the UI: install and uninstall restore the previous pack, mapped keys are Material at the size of the previous pack, the others are those of the previous pack, the keys material_<name>, HiDPI, the zip for the Settings. I leave the UI's pack as I found it: a Material pack (of Material Icons or of Material Symbols) installed before the tests is put aside and made current again after each of them.
"
Class {
	#name : 'MaterialThemeIconsTest',
	#superclass : 'TestCase',
	#instVars : [
		'previous',
		'exported',
		'installedBefore',
		'lastFallbackBefore'
	],
	#category : 'MaterialIcons-Tests',
	#package : 'MaterialIcons-Tests'
}

{ #category : 'running' }
MaterialThemeIconsTest >> defaultTimeLimit [

	^ 2 minutes
]

{ #category : 'running' }
MaterialThemeIconsTest >> setUp [

	| current |
	super setUp.
	current := ThemeIcons classVarNamed: #Current.
	installedBefore := (current isKindOf: MaterialAbstractThemeIcons)
		                   ifTrue: [ current ]
		                   ifFalse: [ nil ].
	lastFallbackBefore := MaterialThemeIcons instVarNamed: #lastFallback.
	installedBefore ifNotNil: [ installedBefore class uninstall ].
	previous := ThemeIcons current.
	exported := OrderedCollection new
]

{ #category : 'running' }
MaterialThemeIconsTest >> tearDown [

	MaterialThemeIcons unsubscribeFromThemeChanges.
	ThemeIcons current == previous ifFalse: [ previous beCurrent ].
	MaterialThemeIcons instVarNamed: #lastFallback put: lastFallbackBefore.
	installedBefore ifNotNil: [
		installedBefore beCurrent.
		installedBefore class subscribeToThemeChanges ].
	exported do: [ :each | each ensureDelete ].
	super tearDown
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testColors [

	| pack testGreen |
	pack := MaterialThemeIcons installColor: Color red.
	self deny: pack followsTheme.
	self
		assert: (pack iconNamed: #add) bits
		equals: (MaterialIcons rounded formNamed: #add scale: 1 color: Color red) bits.
	testGreen := pack iconNamed: #testGreen.
	self
		assert: testGreen bits
		equals: (MaterialIcons rounded
				 formNamed: #check_circle
				 scale: 1
				 color: (Color fromHexString: '43A047')) bits
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testEntries [
	"Mapped keys are unique Pharo keys of the default pack, mapped to Material icons"

	| keys |
	keys := MaterialThemeIconsArt entries collect: [ :each | each first ].
	self assert: keys asSet size equals: keys size.
	self assert: keys size equals: 243.
	MaterialThemeIconsArt entries do: [ :each |
		self assert: (MaterialIcons rounded includesIcon: each second) ]
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testExportZip [
	"The zip that the Settings list loads as a plain ThemeIcons, offline, with the same icons"

	| pack name file loaded |
	pack := MaterialThemeIcons new
		        fallback: previous;
		        build;
		        yourself.
	pack iconNamed: #material_cloud_sync.	"a key material_<name>, added on first use"
	self assert: ((pack iconsPerScale at: 1.0) includesKey: #material_cloud_sync).
	name := 'materialRoundTest' , Time millisecondClockValue printString.
	pack name: name.
	file := ThemeIcons destinationPath / (name , '.zip').
	exported add: file.
	MaterialThemeIcons exportPack: pack to: file.
	self assert: file exists.
	self assert: ((ThemeIcons availablePacks collect: [ :each | each name ]) includes: name).
	file binaryReadStreamDo: [ :stream |
		| archive |
		archive := ZipArchive new readFrom: stream.
		self
			assert: (archive memberNamed: name , '/LICENSE-material-icons') contents asString
			equals: MaterialIconsRoundedCategory licenseText withUnixLineEndings.
		self
			assert: (archive memberNamed: name , '/NOTICE') contents asString
			equals: MaterialThemeIconsArt noticeText withUnixLineEndings.
		self deny: ((archive memberNamed: name , '/NOTICE') contents asString includes: Character cr).
		self deny: (archive memberNames anySatisfy: [ :each |
				 each includesSubstring: '/' , MaterialThemeIcons materialPrefix ]).
		self assert: (archive memberNames includes: name , '/png-scale1.0/add.png') ].
	loaded := ThemeIcons named: name.
	loaded loadIconsFromUrl.
	self
		assert: loaded iconsPerScale keys asSet
		equals: (MaterialIcons scales collect: [ :each | each asFloat ]) asSet.
	#( #add #smallSave #accept #checkboxSelected ) do: [ :key |
		MaterialIcons scales do: [ :scale |
			| mine theirs |
			mine := (pack iconsPerScale at: scale) at: key.
			theirs := (loaded iconsPerScale at: scale) at: key.
			self assert: theirs extent equals: mine extent.
			self assert: (theirs colorAt: theirs extent // 2) equals: (mine colorAt: mine extent // 2) ] ]
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testExportOverSnapshot [
	"With a snapshot read from materialRound.zip current (chosen in the Settings), the pack to export goes over the pack replaced before, as install does, not over the snapshot"

	| first snapshot pack |
	first := MaterialThemeIcons install.
	snapshot := ThemeIcons named: MaterialThemeIcons packName.
	snapshot
		instVarNamed: #iconsPerScale put: first iconsPerScale copy;
		instVarNamed: #scale put: 1.
	ThemeIcons current: snapshot.
	self deny: MaterialThemeIcons isInstalled.
	pack := MaterialThemeIcons packToExport.
	self assert: pack fallback identicalTo: previous.
	self deny: ThemeIcons current identicalTo: pack.
	MaterialThemeIcons install.
	self assert: MaterialThemeIcons packToExport identicalTo: MaterialThemeIcons installed
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testFallbackKeys [
	"The keys of the previous pack that are not mapped are its own Forms"

	| pack mapped |
	pack := MaterialThemeIcons install.
	mapped := (MaterialThemeIconsArt entries collect: [ :each | each first ]) asSet.
	(previous iconsPerScale at: 1.0) keysAndValuesDo: [ :key :form |
		(mapped includes: key) ifFalse: [
			self assert: ((pack iconsPerScale at: 1.0) at: key) identicalTo: form ] ].
	self
		assert: (pack iconNamed: #checkboxSelected) extent
		equals: (previous iconNamed: #checkboxSelected) extent
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testHiDPI [

	| pack formSet |
	pack := MaterialThemeIcons install.
	formSet := pack iconFormSetNamed: #add.
	self assert: (formSet asFormAtScale: 2) extent equals: 32 @ 32.
	self assert: ((pack iconsPerScale at: 1.5) at: #add) extent equals: 24 @ 24
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testInstallAndUninstall [

	| pack |
	self deny: MaterialThemeIcons isInstalled.
	pack := MaterialThemeIcons install.
	self assert: MaterialThemeIcons isInstalled.
	self assert: Smalltalk ui icons identicalTo: pack.
	self assert: ThemeIcons current identicalTo: pack.
	self assert: pack fallback identicalTo: previous.
	self assert: pack name equals: 'materialRound'.
	self assert: pack hasIcons.
	MaterialThemeIcons uninstall.
	self deny: MaterialThemeIcons isInstalled.
	self assert: Smalltalk ui icons identicalTo: previous.
	self assert: ThemeIcons current identicalTo: previous
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testInstallTwice [
	"Installing over an installed pack keeps the first fallback: uninstall goes back to it"

	| first second |
	first := MaterialThemeIcons install.
	second := MaterialThemeIcons installColor: Color blue.
	self deny: second identicalTo: first.
	self assert: second fallback identicalTo: previous.
	MaterialThemeIcons uninstall.
	self assert: ThemeIcons current identicalTo: previous
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testInstallOverSnapshot [
	"A pack read from materialRound.zip (chosen in the Settings) is not taken as the fallback: install goes over the pack replaced before"

	| first snapshot second |
	first := MaterialThemeIcons install.
	snapshot := ThemeIcons named: MaterialThemeIcons packName.
	snapshot
		instVarNamed: #iconsPerScale put: first iconsPerScale copy;
		instVarNamed: #scale put: 1.
	ThemeIcons current: snapshot.
	self deny: MaterialThemeIcons isInstalled.
	second := MaterialThemeIcons install.
	self assert: second fallback identicalTo: previous.
	MaterialThemeIcons uninstall.
	self assert: ThemeIcons current identicalTo: previous
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testLicence [
	"The licence and the attribution exported in the zip, and the provenance of the generated classes"

	| commit |
	commit := MaterialIconsRoundedCategory upstreamCommit.
	self assert: commit size equals: 40.
	self assert: (MaterialIconsRoundedCategory upstreamDescription includesSubstring: commit).
	self assert: (MaterialIconsRoundedCategory comment includesSubstring: commit).
	self assert: (MaterialThemeIconsArt comment includesSubstring: commit).
	self assert: (MaterialThemeIconsArt noticeText includesSubstring: commit).
	self assert: (MaterialIconsRoundedCategory licenseText includesSubstring: 'Apache License').
	self assert: (MaterialIconsRoundedCategory licenseText includesSubstring: 'Version 2.0').
	self assert: (MaterialIconsRoundedCategory comment includesSubstring: 'licenseText')
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testMappedKeys [
	"Mapped keys are Material, at the size the previous pack draws them"

	| pack |
	pack := MaterialThemeIcons install.
	self
		assert: (pack iconNamed: #add) bits
		equals: (MaterialIcons rounded formNamed: #add scale: 1 color: pack effectiveColor) bits.
	self deny: (pack iconNamed: #add) bits equals: (previous iconNamed: #add) bits.
	MaterialThemeIconsArt entries do: [ :entry |
		MaterialIcons scales with: MaterialIcons pixelSizes do: [ :scale :side |
			| form expected |
			form := (pack iconsPerScale at: scale) at: entry first.
			expected := (entry third * scale) rounded.
			self assert: form extent equals: expected @ expected.
			((previous iconsPerScale at: scale) at: entry first ifAbsent: [ nil ])
				ifNotNil: [ :old | self assert: form extent equals: old extent ] ] ]
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testMaterialKeys [

	| pack |
	pack := MaterialThemeIcons install.
	self assert: (Smalltalk ui icons iconNamed: #material_10k) extent equals: 16 @ 16.
	self assert: (pack materialIconNamed: #cloud_sync) extent equals: 16 @ 16.
	self
		assert: (pack iconNamed: #material_home) bits
		equals: (MaterialIcons rounded formNamed: #home scale: 1 color: pack effectiveColor) bits.
	self assert: ((pack iconFormSetNamed: #material_home) asFormAtScale: 2) extent equals: 32 @ 32.
	self assert: (pack allIconNames includes: #material_arrow_back).
	self assert: (pack allIconNames includes: #add).
	self assert: (pack iconNamed: #material_no_such_icon ifNone: [ #none ]) equals: #none
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testNotRunIsNotAWidget [
	"testNotRun is a filled grey circle, not the empty circle of a radio button"

	| pack |
	pack := MaterialThemeIcons install.
	self
		assert: (MaterialThemeIconsArt entries detect: [ :each | each first = #testNotRun ]) allButFirst
		equals: #( 'circle' 16 '9E9E9E' ).
	self
		assert: (pack iconNamed: #testNotRun) bits
		equals: (MaterialIcons rounded
				 formNamed: #circle
				 scale: 1
				 color: (Color fromHexString: '9E9E9E')) bits.
	self deny: ((MaterialThemeIconsArt entries collect: [ :each | each second ]) includes:
			 'radio_button_unchecked')
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testSettings [
	"Stored settings record the fallback, a pack that a new image can restore, not materialRound, whose zip it could not download"

	| pack factory stored |
	pack := MaterialThemeIcons install.
	factory := StoredSettingsFactory new.
	pack acceptSettings: factory.
	stored := factory instVarNamed: #storedSetting.
	self assert: stored name equals: previous name.
	self assert: stored url equals: previous url.
	self deny: stored name equals: MaterialThemeIcons packName.
	self assert: stored realValue name equals: previous name
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testUninstallFlushesCache [
	"The Forms the pack was drawn with do not stay in the shared cache of the icons after uninstall"

	MaterialThemeIcons install.
	Smalltalk ui icons iconNamed: #material_cloud_sync.
	self assert: MaterialIcons rounded cacheSize > 0.
	MaterialThemeIcons uninstall.
	self assert: MaterialIcons rounded cacheSize equals: 0
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testThemeChange [
	"A pack in the colour of the theme is redrawn when the theme changes"

	| pack |
	pack := MaterialThemeIcons install.
	pack color: Color red.
	pack build.
	pack color: nil.
	MaterialThemeIcons themeChanged: nil.
	self
		assert: (pack iconNamed: #add) bits
		equals: (MaterialIcons rounded formNamed: #add scale: 1 color: MaterialIcons rounded themeColor) bits
]

{ #category : 'tests' }
MaterialThemeIconsTest >> testThemeChangeAfterAnotherPack [
	"When another pack has been made current, a theme change unsubscribes the class"

	MaterialThemeIcons install.
	self assert: (MaterialThemeIcons codeSupportAnnouncer hasSubscriber: MaterialThemeIcons).
	previous beCurrent.
	MaterialThemeIcons themeChanged: nil.
	self deny: (MaterialThemeIcons codeSupportAnnouncer hasSubscriber: MaterialThemeIcons).
	self assert: ThemeIcons current identicalTo: previous
]
