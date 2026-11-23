"
I give the method editors of Calypso (ClyMethodCodeEditorToolMorph, in the system browser and in the query browsers) a MaterialProtocolToolDecorator, which shows the icon of the protocol of the method next to 'Edit protocol: ...' in the status bar.

Calypso adds an instance of every subclass of ClyBrowserPlugin to every browser it opens (`isAutoActivated`): the browsers opened before I was loaded get the icon in their status bar when they are opened again. `MaterialProtocolBrowserPlugin disable` turns me off for the browsers opened next, `MaterialProtocolSymbols enabled: false` turns every icon off.
"
Class {
	#name : 'MaterialProtocolBrowserPlugin',
	#superclass : 'ClyBrowserPlugin',
	#category : 'MaterialSymbols-Protocols-Calypso',
	#package : 'MaterialSymbols-Protocols-Calypso'
}

{ #category : 'decoration' }
MaterialProtocolBrowserPlugin >> decorateTool: aBrowserTool [

	(aBrowserTool isKindOf: ClyMethodCodeEditorToolMorph) ifTrue: [
		aBrowserTool addDecorator: MaterialProtocolToolDecorator new ]
]
