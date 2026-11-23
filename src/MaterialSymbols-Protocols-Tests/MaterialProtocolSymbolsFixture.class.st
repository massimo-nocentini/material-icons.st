"
I have one method in each of a few protocols, for MaterialProtocolSymbolsCalypsoTest: mapped ones (accessing, printing, as yet unclassified), ones Calypso decorates itself (private, initialization, releasing), one where the browsers show Pharo's icon of its meaning (instance initialization) and one without a symbol (zork unmapped). In zork unmapped, an abstract method and a deprecated one give me Calypso's virtual groups 'abstract' and 'deprecated' (their names are mapped, and they must keep Pharo's look); MaterialProtocolSymbols>>#materialFixtureExtension is my extension method. My selectors are unique in the image, so that their implementors are mine alone.
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

{ #category : 'zork unmapped' }
MaterialProtocolSymbolsFixture >> materialFixtureAbstract [
	"Calypso lists me in its virtual group 'abstract'"

	^ self subclassResponsibility
]

{ #category : 'zork unmapped' }
MaterialProtocolSymbolsFixture >> materialFixtureDeprecated [
	"Calypso lists me in its virtual group 'deprecated' (Pharo 13 and later)"

	self deprecated: 'a fixture of MaterialProtocolSymbolsCalypsoTest, never sent'.
	^ 9
]

{ #category : 'instance initialization' }
MaterialProtocolSymbolsFixture >> materialFixtureInstanceInitialization [

	^ 8
]

{ #category : 'releasing' }
MaterialProtocolSymbolsFixture >> materialFixtureRelease [

	^ 7
]
