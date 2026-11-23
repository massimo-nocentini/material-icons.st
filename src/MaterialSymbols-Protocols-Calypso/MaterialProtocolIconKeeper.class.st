"
I am an invisible Morph (0x0) in the status bar of a method editor of Calypso (my tool). Every 300 ms I make sure that its protocol editor ('Edit protocol: accessing') shows the icon of the protocol of the method (`MaterialProtocolSymbols browserFormSetForProtocol:`) before its label, the icon of the current protocol in the current colours: the editor builds its status bar again whenever the browser changes, and the protocol, the colour of the icons or `MaterialProtocolSymbols enabled` may change at any time. There is no icon for an extension method (the label is its package then), for a protocol without a symbol, nor while `MaterialProtocolSymbols enabled` is false.
"
Class {
	#name : 'MaterialProtocolIconKeeper',
	#superclass : 'Morph',
	#instVars : [
		'tool'
	],
	#category : 'MaterialSymbols-Protocols-Calypso',
	#package : 'MaterialSymbols-Protocols-Calypso'
}

{ #category : 'accessing' }
MaterialProtocolIconKeeper >> formSet [
	"The icon the status bar of my tool should show, or nil"

	tool extendingPackage ifNotNil: [ ^ nil ].
	^ MaterialProtocolSymbols browserFormSetForProtocol:
		  (tool methodProtocol ifNil: [ ^ nil ])
]

{ #category : 'accessing' }
MaterialProtocolIconKeeper >> iconIn: aProtocolEditor [
	"The icon I put in aProtocolEditor, or nil"

	^ aProtocolEditor submorphs
		  detect: [ :each | each hasProperty: #materialProtocolSymbol ]
		  ifNone: [ nil ]
]

{ #category : 'initialization' }
MaterialProtocolIconKeeper >> initialize [

	super initialize.
	self
		extent: 0 @ 0;
		color: Color transparent;
		hResizing: #rigid;
		vResizing: #rigid
]

{ #category : 'accessing' }
MaterialProtocolIconKeeper >> protocolEditor [

	^ tool statusBar ifNotNil: [ :bar | bar findDeeplyA: ClyProtocolEditorMorph ]
]

{ #category : 'stepping' }
MaterialProtocolIconKeeper >> step [

	self updateIcon
]

{ #category : 'stepping' }
MaterialProtocolIconKeeper >> stepTime [

	^ 300
]

{ #category : 'accessing' }
MaterialProtocolIconKeeper >> tool [

	^ tool
]

{ #category : 'accessing' }
MaterialProtocolIconKeeper >> tool: aMethodEditor [

	tool := aMethodEditor
]

{ #category : 'updating' }
MaterialProtocolIconKeeper >> updateIcon [
	"Put the icon of the protocol before the label of the protocol editor, unless it is there already"

	| editor formSet current icon label |
	editor := self protocolEditor ifNil: [ ^ self ].
	formSet := self formSet.
	current := self iconIn: editor.
	(current notNil and: [
		 (current valueOfProperty: #materialProtocolSymbol) == formSet ])
		ifTrue: [ ^ self ].
	current ifNotNil: [ current delete ].
	formSet ifNil: [ ^ self ].
	icon := formSet asMorph.
	icon setProperty: #materialProtocolSymbol toValue: formSet.
	label := editor submorphs
		         detect: [ :each | each isKindOf: StringMorph ]
		         ifNone: [ nil ].
	label
		ifNil: [ editor addMorphBack: icon ]
		ifNotNil: [ editor addMorph: icon inFrontOf: label ]
]

{ #category : 'stepping' }
MaterialProtocolIconKeeper >> wantsSteps [

	^ true
]
