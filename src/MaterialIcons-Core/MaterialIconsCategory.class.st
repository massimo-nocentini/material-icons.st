"
I am the abstract root of the classes that hold the Material icons, one class per style and category. The generated packages hold the styles:

- `#rounded` (`MaterialIcons-Rounded`, Material Icons Rounded),
- `#symbolsRounded` (`MaterialSymbols-Rounded`, Material Symbols Rounded) and
- `#symbolsRoundedFilled` (`MaterialSymbols-Rounded-Filled`, its filled variant).

The data is on the class side of my concrete subclasses:

- `materialStyle`: the style, a Symbol (`#rounded`);
- `materialCategory`: the category, a String (`'action'`, `'av'`, `'navigation'`; `'Actions'`, `'UI actions'` for the symbols...);
- `iconTable`: an Array of `#( name codepoint tags )`, one per icon of the category; tags is an Array of Strings, or one String with the tags separated by commas;
- one method per icon, `icon_<name>` (so that the names that begin with a digit, `10k` or `3d_rotation`, are selectors too), answering its PNGs at 16, 24 and 32 pixels (the scales 1, 1.5 and 2 of `MaterialIcons scales`) in Base64. Each PNG holds the shape only: grey 0 and alpha;
- when the package of the masters of the style is loaded (`MaterialIcons-Rounded-192`, `MaterialSymbols-Rounded-192`...), one more method per icon, `master_<name>`, answering its PNG at `masterSize` pixels (192) in Base64, the source of the other sizes of `MaterialIcons >> formNamed:size:`.

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
MaterialIconsCategory class >> base64MasterOf: aName [
	"Answer the PNG of the icon aName at masterSize pixels, in Base64, or nil when the masters are not loaded"

	| selector |
	selector := self masterSelectorOf: aName.
	^ (self respondsTo: selector)
		  ifTrue: [ self perform: selector ]
		  ifFalse: [ nil ]
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

{ #category : 'testing' }
MaterialIconsCategory class >> hasMasters [
	"Whether the package of my masters (master_<name>) is loaded"

	^ self masterSize notNil
]

{ #category : 'accessing' }
MaterialIconsCategory class >> masterSelectorOf: aName [
	"The selector of the method of the master of the icon aName"

	^ ('master_' , aName) asSymbol
]

{ #category : 'accessing' }
MaterialIconsCategory class >> masterSize [
	"The side in pixels of my masters, nil when they are not loaded (the packages of the masters redefine it in the root class of their style)"

	^ nil
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
