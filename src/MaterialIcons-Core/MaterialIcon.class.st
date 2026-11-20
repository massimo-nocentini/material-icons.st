"
I describe one Material icon: its name (a Symbol, the Material one: `#arrow_back`, `#'10k'`), its Material category, the codepoint of its glyph in the Material Icons fonts, its tags (the search words of fonts.google.com/icons) and the class that holds its pixels.

```
MaterialIcons rounded entryNamed: #home.		""a MaterialIcon(#home action)""
(MaterialIcons rounded entryNamed: #home) tags.
```
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
	^ (name includesSubstring: lowercase) or: [
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

	^ tags
]
