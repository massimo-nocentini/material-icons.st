"
I have one method in each of a few protocols, for MaterialProtocolSymbolsCalypsoTest: mapped ones (accessing, printing, as yet unclassified), ones Calypso decorates itself (private, initialization) and one without a symbol (zork unmapped). My selectors are unique in the image, so that their implementors are mine alone.
"
Class {
	#name : 'MaterialProtocolSymbolsFixture',
	#superclass : 'Object',
	#category : 'MaterialSymbols-Protocols-Tests',
	#package : 'MaterialSymbols-Protocols-Tests'
}

{ #category : 'accessing' }
MaterialProtocolSymbolsFixture >> materialFixtureAccessing [

	^ 1
]

{ #category : 'initialization' }
MaterialProtocolSymbolsFixture >> materialFixtureInitialization [

	^ 4
]

{ #category : 'printing' }
MaterialProtocolSymbolsFixture >> materialFixturePrinting [

	^ 2
]

{ #category : 'private' }
MaterialProtocolSymbolsFixture >> materialFixturePrivate [

	^ 3
]

{ #category : 'as yet unclassified' }
MaterialProtocolSymbolsFixture >> materialFixtureUnclassified [

	^ 6
]

{ #category : 'zork unmapped' }
MaterialProtocolSymbolsFixture >> materialFixtureUnmapped [

	^ 5
]
