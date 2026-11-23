"
I put a MaterialProtocolIconKeeper in the status bar of a method editor of Calypso (my browserTool, a ClyMethodCodeEditorToolMorph): it shows the icon of the protocol of the method before 'Edit protocol: ...' and keeps it there, since the editor builds its status bar again on every change of the browser without decorating it again.
"
Class {
	#name : 'MaterialProtocolToolDecorator',
	#superclass : 'ClyBrowserToolDecorator',
	#category : 'MaterialSymbols-Protocols-Calypso',
	#package : 'MaterialSymbols-Protocols-Calypso'
}

{ #category : 'detaching' }
MaterialProtocolToolDecorator class >> detachFromToolsOf: aBrowserOrNil [
	"Take my instances out of the method editors of aBrowserOrNil, of every browser when nil: they would put a keeper in the status bars those editors build next"

	self allInstances do: [ :each |
		each browserTool ifNotNil: [ :tool |
			(aBrowserOrNil isNil or: [ tool browser == aBrowserOrNil ]) ifTrue: [
				(tool instVarNamed: #decorators) remove: each ifAbsent: [  ] ] ] ]
]

{ #category : 'class initialization' }
MaterialProtocolToolDecorator class >> unload [

	self detachFromToolsOf: nil
]

{ #category : 'decoration' }
MaterialProtocolToolDecorator >> decorateTool [
	"The keeper is a submorph of the status bar itself, which ClyStatusBarMorph>>#clear (it empties only its two bars) leaves in place"

	| bar keeper |
	bar := browserTool statusBar ifNil: [ ^ self ].
	keeper := bar submorphs
		          detect: [ :each | each isKindOf: MaterialProtocolIconKeeper ]
		          ifNone: [
			          keeper := MaterialProtocolIconKeeper new tool: browserTool.
			          bar addMorphBack: keeper.
			          keeper ].
	keeper updateIcon
]
