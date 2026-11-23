"
I describe one Material icon:

- its name (a Symbol, the Material one: `#arrow_back`, `#'10k'`),
- its category,
- the codepoint of its glyph in the fonts of its style (Material Icons or Material Symbols),
- its tags (the search words of fonts.google.com/icons)
- and the class that holds its pixels.

```smalltalk
MaterialIcons rounded entryNamed: #home.
	""a MaterialIcon(#home action)""
(MaterialIcons rounded entryNamed: #home) tags.
(MaterialIcons symbolsRounded entryNamed: #home) tags.
```

The tables of Material Symbols hold the tags of an icon as one String, comma-separated (one literal instead of dozens); `tags` answers them as an Array in both cases.
"
Class {
	#name : 'MaterialIcon',
	#superclass : 'Object',
	#instVars : [
		'name',
		'category',
		'codepoint',
		'tags',
		'source'
	],
	#category : 'MaterialIcons-Core',
	#package : 'MaterialIcons-Core'
}

{ #category : 'instance creation' }
MaterialIcon class >> name: aSymbol category: aString codepoint: anInteger tags: anArray source: aClass [

	^ self new
		  setName: aSymbol
		  category: aString
		  codepoint: anInteger
		  tags: anArray
		  source: aClass
]

{ #category : 'accessing' }
MaterialIcon >> base64PNGAt: anIndex [
	"The PNG at the scale of index anIndex in MaterialIcons scales, in Base64"

	^ self base64PNGs at: anIndex
]

{ #category : 'accessing' }
MaterialIcon >> base64PNGs [
	"My PNGs at the scales 1, 1.5 and 2, in Base64"

	^ source base64PNGsOf: name
]

{ #category : 'accessing' }
MaterialIcon >> base64Master [
	"My PNG at the side of the masters of my style (192 pixels), in Base64, or nil when the package of the masters is not loaded"

	^ source base64MasterOf: name
]

{ #category : 'accessing' }
MaterialIcon >> category [

	^ category
]

{ #category : 'accessing' }
MaterialIcon >> codepoint [
	"The codepoint of my glyph in the Material Icons fonts"

	^ codepoint
]

{ #category : 'testing' }
MaterialIcon >> matches: aString [
	"Whether aString is part of my name or of one of my tags, ignoring the case"

	| lowercase |
	lowercase := aString asLowercase.
	(name includesSubstring: lowercase) ifTrue: [ ^ true ].
	^ tags isString
		  ifTrue: [ tags asLowercase includesSubstring: lowercase ]
		  ifFalse: [
			  tags anySatisfy: [ :each |
				  each asLowercase includesSubstring: lowercase ] ]
]

{ #category : 'accessing' }
MaterialIcon >> name [

	^ name
]

{ #category : 'printing' }
MaterialIcon >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: name;
		space;
		nextPutAll: category;
		nextPut: $)
]

{ #category : 'initialization' }
MaterialIcon >> setName: aSymbol category: aString codepoint: anInteger tags: anArray source: aClass [

	name := aSymbol.
	category := aString.
	codepoint := anInteger.
	tags := anArray.
	source := aClass
]

{ #category : 'accessing' }
MaterialIcon >> source [
	"The class that holds my pixels"

	^ source
]

{ #category : 'accessing' }
MaterialIcon >> tags [
	"An Array of Strings"

	^ tags isString
		  ifTrue: [ (tags substrings: ',') asArray ]
		  ifFalse: [ tags ]
]
