"
I am the abstract root of the classes that hold the Material icons, one class per style and category (the generated package `MaterialIcons-Rounded` holds the style `#rounded`).

The data is on the class side of my concrete subclasses:

- `materialStyle`: the style, a Symbol (`#rounded`);
- `materialCategory`: the Material category, a String (`'action'`, `'av'`, `'navigation'`...);
- `iconTable`: an Array of `#( name codepoint tags )`, one per icon of the category;
- one method per icon, `icon_<name>` (so that the names that begin with a digit, `10k` or `3d_rotation`, are selectors too), answering its PNGs at 16, 24 and 32 pixels (the scales 1, 1.5 and 2 of `MaterialIcons scales`) in Base64. Each PNG holds the shape only: grey 0 and alpha.

`MaterialIcons` reads them; nothing else needs to.
"
Class {
	#name : 'MaterialIconsCategory',
	#superclass : 'Object',
	#category : 'MaterialIcons-Core',
	#package : 'MaterialIcons-Core'
}

{ #category : 'accessing' }
MaterialIconsCategory class >> base64PNGsOf: aName [
	"Answer the PNGs of the icon aName at the scales 1, 1.5 and 2, in Base64"

	^ self perform: (self selectorOf: aName)
]

{ #category : 'accessing' }
MaterialIconsCategory class >> categoriesOfStyle: aSymbol [
	"Answer my concrete subclasses of the style aSymbol, by the name of their category"

	^ (self allSubclasses select: [ :each |
		   each isMaterialCategory and: [ each materialStyle = aSymbol ] ])
		  asArray sort: [ :a :b | a materialCategory <= b materialCategory ]
]

{ #category : 'accessing' }
MaterialIconsCategory class >> iconTable [
	"An Array of #( name codepoint tags ), one per icon of my category"

	^ #(  )
]

{ #category : 'testing' }
MaterialIconsCategory class >> isMaterialCategory [
	"Whether I hold icons: my abstract classes have no category"

	^ self materialCategory notNil and: [ self materialStyle notNil ]
]

{ #category : 'accessing' }
MaterialIconsCategory class >> materialCategory [
	"The name of my Material category, nil in an abstract class"

	^ nil
]

{ #category : 'accessing' }
MaterialIconsCategory class >> materialStyle [
	"The style of my icons, a Symbol, nil in an abstract class"

	^ nil
]

{ #category : 'accessing' }
MaterialIconsCategory class >> selectorOf: aName [
	"The selector of the method of the icon aName"

	^ ('icon_' , aName) asSymbol
]

{ #category : 'accessing' }
MaterialIconsCategory class >> styles [
	"The styles of the icons in the image"

	^ ((self allSubclasses select: [ :each | each isMaterialCategory ])
		   collect: [ :each | each materialStyle ]) asSet asArray sort
]
