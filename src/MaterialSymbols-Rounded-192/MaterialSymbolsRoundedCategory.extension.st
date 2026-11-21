Extension { #name : 'MaterialSymbolsRoundedCategory' }

{ #category : '*MaterialSymbols-Rounded-192' }
MaterialSymbolsRoundedCategory class >> masterDescription [
	"Where the PNGs of master_<name> come from: rasterized at 192 pixels from the optical size 48,
	the largest, FILL 0, wght 400, GRAD 0"

	^ 'https://github.com/google/material-design-icons at commit 10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7, symbols/web/{name}/materialsymbolsrounded/{name}_48px.svg'
]

{ #category : '*MaterialSymbols-Rounded-192' }
MaterialSymbolsRoundedCategory class >> masterSize [
	"The side in pixels of the PNGs of master_<name>"

	^ 192
]
