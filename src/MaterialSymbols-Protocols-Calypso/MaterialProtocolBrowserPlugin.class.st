"
I give the method editors of Calypso (ClyMethodCodeEditorToolMorph, in the system browser and in the query browsers) a MaterialProtocolToolDecorator, which shows the icon of the protocol of the method next to 'Edit protocol: ...' in the status bar.

Calypso adds an instance of every subclass of ClyBrowserPlugin to every browser it opens (`isAutoActivated`): the browsers opened before I was loaded get the icon in their status bar when they are opened again. `MaterialProtocolBrowserPlugin disable` turns me off for the browsers opened next, `MaterialProtocolSymbols enabled: false` turns every icon off. `detachFrom: aBrowser` takes the status-bar icon out of an open browser for good, and my package's `unload` does so for every open browser.
"
Class {
	#name : 'MaterialProtocolBrowserPlugin',
	#superclass : 'ClyBrowserPlugin',
	#category : 'MaterialSymbols-Protocols-Calypso',
	#package : 'MaterialSymbols-Protocols-Calypso'
}

{ #category : 'detaching' }
MaterialProtocolBrowserPlugin class >> detachFrom: aBrowser [
	"Take the status-bar icons out of the open browser aBrowser: my instance, the decorators of its method editors, their keepers and icons. Its method editors then show their protocol as Pharo does"

	aBrowser plugins removeAllSuchThat: [ :each | each class == self ].
	MaterialProtocolToolDecorator detachFromToolsOf: aBrowser.
	MaterialProtocolIconKeeper detachFromToolsOf: aBrowser
]

{ #category : 'class initialization' }
MaterialProtocolBrowserPlugin class >> unload [
	"The open browsers keep their plugins, and mine would decorate their next method editors again: take the status-bar icons out of every open browser"

	(self allInstances collect: [ :each | each browser ]) asIdentitySet do: [ :each |
		each ifNotNil: [ self detachFrom: each ] ]
]

{ #category : 'decoration' }
MaterialProtocolBrowserPlugin >> decorateTool: aBrowserTool [

	(aBrowserTool isKindOf: ClyMethodCodeEditorToolMorph) ifTrue: [
		aBrowserTool addDecorator: MaterialProtocolToolDecorator new ]
]
