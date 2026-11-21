Extension { #name : 'MaterialIconsRoundedCategory' }

{ #category : '*MaterialIcons-Rounded-192' }
MaterialIconsRoundedCategory class >> masterDescription [
	"Where the PNGs of master_<name> come from: Google's own PNG of each icon at 48 dp, xxxhdpi,
	the largest raster of the upstream repository, byte for byte (8-bit, black, of various colour types)"

	^ 'https://github.com/google/material-design-icons at commit 3912baecc97388955ce39f5e26bfb786a70cbe48, android/{category}/{name}/materialiconsround/black/res/drawable-xxxhdpi/round_{name}_black_48.png'
]

{ #category : '*MaterialIcons-Rounded-192' }
MaterialIconsRoundedCategory class >> masterSize [
	"The side in pixels of the PNGs of master_<name>"

	^ 192
]
