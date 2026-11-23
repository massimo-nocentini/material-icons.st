"
I put the Material Symbol of a protocol (MaterialProtocolSymbols) in the icon slot of its row in the protocol pane of Calypso, the system browser of Pharo 12 to 15: `accessing`, `testing`, `printing`... get their symbol on the left of their name.

I decorate the real protocols only (ClyMethodsInProtocolGroup, and ClyUnclassifiedMethodGroup, the protocol 'as yet unclassified'), by their exact class: not the groups of extension methods ('*Package', which Calypso marks with protocolExtension), not 'instance side' / 'class side', not the virtual groups of queries (extensions, overrides, deprecated, breakpoints, flags...). My priority is below that of every decorator of Pharo, so Pharo's icons are drawn after mine and win: the protocols whose name begins with private, initial, releas or finali keep Calypso's protocolPrivate and protocolProtected (I do not even draw mine there). Nothing is drawn for a protocol without a symbol, nor while `MaterialProtocolSymbols enabled` is false.

I am a class annotation (`protocolGroupDecorationStrategy`): Calypso finds me as soon as I am loaded and forgets me when I am unloaded.
"
Class {
	#name : 'MaterialProtocolGroupTableDecorator',
	#superclass : 'ClyTableDecorator',
	#category : 'MaterialSymbols-Protocols-Calypso',
	#package : 'MaterialSymbols-Protocols-Calypso'
}

{ #category : 'decoration' }
MaterialProtocolGroupTableDecorator class >> decorateTableCell: anItemCellMorph of: aDataSourceItem [

	| name formSet |
	name := aDataSourceItem name.
	(MaterialProtocolSymbols pharoIconNameForProtocol: name) ifNotNil: [ ^ self ].
	formSet := (MaterialProtocolSymbols formSetForProtocol: name) ifNil: [ ^ self ].
	anItemCellMorph definitionMorph: (formSet asMorph
			 setProperty: #materialProtocolSymbol
			 toValue: (MaterialProtocolSymbols symbolNameForProtocol: name);
			 yourself)
]

{ #category : 'decoration' }
MaterialProtocolGroupTableDecorator class >> isProtocolGroup: anObject [
	"Whether anObject is a protocol in Calypso's protocol pane: a group of the methods of one protocol, by its exact class"

	^ anObject class == ClyMethodsInProtocolGroup or: [
		  anObject class == ClyUnclassifiedMethodGroup ]
]

{ #category : 'decoration' }
MaterialProtocolGroupTableDecorator class >> priority [
	"Below every decorator of Pharo (0 and above): Calypso applies them in increasing priority, so its own icons are drawn over mine"

	^ -10
]

{ #category : 'registration' }
MaterialProtocolGroupTableDecorator class >> protocolGroupDecorationStrategy [

	<classAnnotation>
	^ ClyTableDecorationStrategyAnnotation for: ClyMethodGroup asCalypsoItemContext
]

{ #category : 'refreshing' }
MaterialProtocolGroupTableDecorator class >> refreshBrowsers [
	"Have the tables of the open Calypso browsers build their rows again, with or without my icons (MaterialProtocolSymbols refreshBrowsers)"

	<materialProtocolSymbolsRefresh>
	| world |
	world := self currentWorld ifNil: [ ^ self ].
	world allMorphsDo: [ :each |
		(each isKindOf: ClyQueryViewMorph) ifTrue: [
			each table ifNotNil: [ :table |
				table container setNeedsRefreshExposedRows.
				table refresh ] ] ]
]

{ #category : 'decoration' }
MaterialProtocolGroupTableDecorator class >> wantsDecorateTableCellOf: aDataSourceItem [

	^ MaterialProtocolSymbols enabled and: [
		  self isProtocolGroup: aDataSourceItem actualObject ]
]
