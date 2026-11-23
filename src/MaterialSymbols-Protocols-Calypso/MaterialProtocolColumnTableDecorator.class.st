"
I put the icon of a protocol (`MaterialProtocolSymbols browserFormSetForProtocol:`) before the text of the protocol column of Calypso's query browsers (ClyQueryBrowserMorph: senders, implementors, references... of Pharo 12 to 15), whose columns are the class, the selector, the package and the protocol.

Calypso does not tell a decorator which column it decorates: I recognise the cell of the protocol by its text, the protocol of the method of its row (`printDefiningProtocol`), and leave the main column alone (the class in a query browser, the selector in the method pane of the system browser). The icon is the one the protocol pane shows for that protocol: Calypso's own for private..., initial... and extension protocols, else its Material Symbol; none for a protocol without a symbol, nor while `MaterialProtocolSymbols enabled` is false. Pharo puts no icon in that column.
"
Class {
	#name : 'MaterialProtocolColumnTableDecorator',
	#superclass : 'ClyTableDecorator',
	#category : 'MaterialSymbols-Protocols-Calypso',
	#package : 'MaterialSymbols-Protocols-Calypso'
}

{ #category : 'decoration' }
MaterialProtocolColumnTableDecorator class >> decorateMainTableCell: anItemCellMorph of: aDataSourceItem [
	"The main column is the class (query browser) or the selector (method pane): not a protocol"
]

{ #category : 'decoration' }
MaterialProtocolColumnTableDecorator class >> decorateTableCell: anItemCellMorph of: aDataSourceItem [

	| protocol formSet |
	protocol := [
	            aDataSourceItem browserItem systemDefinition
		            printDefiningProtocol asString ]
		            on: Error
		            do: [ :error | error return: nil ].
	protocol ifNil: [ ^ self ].
	(anItemCellMorph label notNil and: [
		 anItemCellMorph label contents asString = protocol ]) ifFalse: [
		^ self ].
	protocol = aDataSourceItem name asString ifTrue: [ ^ self ].
	formSet := (MaterialProtocolSymbols browserFormSetForProtocol: protocol)
		           ifNil: [ ^ self ].
	anItemCellMorph addMorphBack: (formSet asMorph
			 setProperty: #materialProtocolSymbol toValue: protocol;
			 setProperty: #materialProtocolFormSet toValue: formSet;
			 yourself)
]

{ #category : 'registration' }
MaterialProtocolColumnTableDecorator class >> methodDecorationStrategy [

	<classAnnotation>
	^ ClyTableDecorationStrategyAnnotation for: ClyMethod asCalypsoItemContext
]

{ #category : 'decoration' }
MaterialProtocolColumnTableDecorator class >> priority [

	^ -10
]

{ #category : 'decoration' }
MaterialProtocolColumnTableDecorator class >> wantsDecorateTableCellOf: aDataSourceItem [

	^ MaterialProtocolSymbols enabled
]
