DisplayObject subclass: #Form
	instanceVariableNames: 'bits width height depth offset '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Display Objects'!
!Form commentStamp: '<historical>' prior: 0!
A rectangular array of pixels, used for holding images.  All pictures, including character images are Forms.  The depth of a Form is how many bits are used to specify the color at each pixel.  The actual bits are held in a Bitmap, whose internal structure is different at each depth.  Class Color allows you to deal with colors without knowing how they are actually encoded inside a Bitmap.
	  The supported depths (in bits) are 1, 2, 4, 8, 16, and 32.  The number of actual colors at these depths are: 2, 4, 16, 256, 32768, and 16 million.
	Forms are combined using BitBlt.  See the comment in class BitBlt.  Forms that are have both transparent and opapue areas are MaskedForms.  Forms that repeat many times to fill a large destination are InfiniteForms.

	colorAt: x@y		Returns the abstract color at this location
	displayAt: x@y		shows this form on the screen
	displayOn: aMedium at: x@y	shows this form in a Window, a Form, or other DisplayMedium
	fillColor: aColor		Set all the pixels to the color.
	edit		launch an editor to change the bits of this form.
	pixelValueAt: x@y	The encoded color.  Depends on the depth.
!


!Form methodsFor: 'initialize-release' stamp: 'ar 5/28/2000 16:00'!
allocateForm: extentPoint
	"Allocate a new form which is similar to the receiver and can be used for accelerated blts"
	^Form extent: extentPoint depth: self depth! !

!Form methodsFor: 'initialize-release'!
fromDisplay: aRectangle 
	"Create a virtual bit map from a user specified rectangular area on the 
	display screen. Reallocates bitmap only if aRectangle ~= the receiver's 
	extent."

	(width = aRectangle width and: [height = aRectangle height])
		ifFalse: [self setExtent: aRectangle extent depth: depth].
	self
		copyBits: (aRectangle origin extent: self extent)
		from: Display
		at: 0 @ 0
		clippingBox: self boundingBox
		rule: Form over
		fillColor: nil! !


!Form methodsFor: 'accessing'!
bits
	"Answer the receiver's Bitmap containing its bits."

	^ bits! !

!Form methodsFor: 'accessing'!
bits: aBitmap 
	"Reset the Bitmap containing the receiver's bits."

	bits _ aBitmap! !

!Form methodsFor: 'accessing' stamp: 'jm 6/15/2003 18:26'!
boundingBox

	^ Rectangle origin: 0@0 corner: width@height
! !

!Form methodsFor: 'accessing' stamp: 'tk 3/9/97'!
center
	"Note that offset is ignored here.  Are we really going to embrace offset?  "
	^ (width @ height) // 2! !

!Form methodsFor: 'accessing' stamp: 'jm 6/15/2003 18:47'!
computeBoundingBox
	"Note: Clients usually send boundingBox rather than this message."

	^ Rectangle origin: 0@0 corner: width@height
! !

!Form methodsFor: 'accessing'!
depth
	^ depth! !

!Form methodsFor: 'accessing' stamp: 'jm 10/12/2007 21:39'!
equals: aForm
	"Answer true if the receiver is exactly the same as the given Form."

	self == aForm ifTrue: [^ true].

	self class = aForm class ifFalse: [^ false].
	self class = ColorForm ifTrue: [
		self colors = aForm colors  ifFalse: [^ false]].
	(width = aForm width) & (height = aForm height) ifFalse: [^ false].
	(depth = aForm depth) & (offset = aForm privateOffset) ifFalse: [^ false].

	bits class = aForm bits class ifFalse: [
		self hibernate.
		aForm hibernate].
	^ bits = aForm bits
! !

!Form methodsFor: 'accessing'!
extent
	^ width @ height! !

!Form methodsFor: 'accessing'!
form
	"Answer the receiver's form.  For vanilla Forms, this degenerates to self.  Makes several methods that operate on both Forms and MaskedForms much more straightforward.   6/1/96 sw"

	^ self! !

!Form methodsFor: 'accessing' stamp: 'jm 11/24/2002 10:48'!
getCanvas
	"Return a Canvas for drawing on the receiver."

	^ FormCanvas on: self
! !

!Form methodsFor: 'accessing'!
height
	^ height! !

!Form methodsFor: 'accessing' stamp: 'ar 2/16/2000 22:00'!
offset
	^offset ifNil:[0@0]! !

!Form methodsFor: 'accessing'!
offset: aPoint

	offset _ aPoint! !

!Form methodsFor: 'accessing'!
size
	"Should no longer be used -- use bitsSize instead.  length of variable part of instance."
	^ super size! !

!Form methodsFor: 'accessing'!
width
	^ width! !


!Form methodsFor: 'copying'!
copy: aRect
 	"Return a new form which derives from the portion of the original form delineated by aRect."
	| newForm |
	newForm _ self class extent: aRect extent depth: depth.
	^ newForm copyBits: aRect from: self at: 0@0
		clippingBox: newForm boundingBox rule: Form over fillColor: nil! !

!Form methodsFor: 'copying' stamp: 'jm 5/29/2003 17:58'!
copy: destRectangle from: sourcePt in: sourceForm rule: rule 
	"Make up a BitBlt table and copy the bits."

	(BitBlt toForm: self)
		copy: destRectangle
		from: sourcePt in: sourceForm
		fillColor: nil rule: rule! !

!Form methodsFor: 'copying'!
copy: sourceRectangle from: sourceForm to: destPt rule: rule
	^ self copy: (destPt extent: sourceRectangle extent)
		from: sourceRectangle topLeft in: sourceForm rule: rule! !

!Form methodsFor: 'copying' stamp: 'jm 2/27/98 09:35'!
deepCopy

	^ self shallowCopy
		bits: bits copy;
		offset: offset copy
! !


!Form methodsFor: 'displaying' stamp: 'di 7/1/97 14:06'!
colormapIfNeededForDepth: destDepth
	"Return a colormap for displaying the receiver at the given depth, or nil if no colormap is needed."

	depth = destDepth ifTrue: [^ nil].  "not needed if depths are the same"
	^ Color colorMapIfNeededFrom: depth to: destDepth
! !

!Form methodsFor: 'displaying' stamp: 'JM 11/9/2011 10:50'!
copyBits: sourceForm at: destOrigin translucent: factor
	"Make up a BitBlt table and copy the bits with the given colorMap."

	(BitBlt 
		destForm: self
		sourceForm: sourceForm
		halftoneForm: nil
		combinationRule: 31"30"
		destOrigin: destOrigin
		sourceOrigin: 0@0
		extent: sourceForm extent
		clipRect: self boundingBox)
		copyBitsTranslucent: ((0 max: (factor*255.0) asInteger) min: 255)
"
 | f f2 f3 | f _ Form fromUser. f2 _ Form fromDisplay: (0@0 extent: f extent). f3 _ f2 deepCopy.
0.0 to: 1.0 by: 1.0/32 do:
	[:t | f3 _ f2 deepCopy. f3 copyBits: f at: 0@0 translucent: t.
	f3 displayAt: 0@0. (Delay forMilliseconds: 50) wait].
"! !

!Form methodsFor: 'displaying' stamp: 'jm 5/25/2003 11:48'!
copyBits: sourceRect from: sourceForm at: destOrigin clippingBox: clipRect rule: rule fillColor: aColor 	"Copy the given rectangular area from sourceForm into myself at the given destination point using the given combination rule and fill color."

	(BitBlt 
		destForm: self
		sourceForm: sourceForm
		fillColor: aColor
		combinationRule: rule
		destOrigin: destOrigin
		sourceOrigin: sourceRect origin
		extent: sourceRect extent
		clipRect: clipRect) copyBits.
! !

!Form methodsFor: 'displaying' stamp: 'jm 5/29/2003 17:58'!
copyBits: sourceRect from: sourceForm at: destOrigin clippingBox: clipRect rule: rule fillColor: aForm map: map
	"Make up a BitBlt table and copy the bits.  Use a colorMap."

	((BitBlt 
		destForm: self
		sourceForm: sourceForm
		fillColor: aForm
		combinationRule: rule
		destOrigin: destOrigin
		sourceOrigin: sourceRect origin
		extent: sourceRect extent
		clipRect: clipRect) colorMap: map) copyBits! !

!Form methodsFor: 'displaying' stamp: 'jm 5/29/2003 17:58'!
copyBits: sourceRect from: sourceForm at: destOrigin colorMap: map 
	"Make up a BitBlt table and copy the bits with the given colorMap."

	((BitBlt 
		destForm: self
		sourceForm: sourceForm
		halftoneForm: nil
		combinationRule: Form over
		destOrigin: destOrigin
		sourceOrigin: sourceRect origin
		extent: sourceRect extent
		clipRect: self boundingBox) colorMap: map) copyBits! !

!Form methodsFor: 'displaying'!
displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: rule fillColor: aForm

	aDisplayMedium copyBits: self boundingBox
		from: self
		at: aDisplayPoint + self offset
		clippingBox: clipRectangle
		rule: rule
		fillColor: aForm
		map: (self colormapIfNeededForDepth: aDisplayMedium depth).
! !

!Form methodsFor: 'displaying'!
displayOn: aDisplayMedium transformation: displayTransformation clippingBox: clipRectangle align: alignmentPoint with: relativePoint rule: ruleInteger fillColor: aForm 
	"Graphically, it means nothing to scale a Form by floating point values.  
	Because scales and other display parameters are kept in floating point to 
	minimize round off errors, we are forced in this routine to round off to the 
	nearest integer."

	| absolutePoint scale magnifiedForm |
	absolutePoint _ displayTransformation applyTo: relativePoint.
	absolutePoint _ absolutePoint x asInteger @ absolutePoint y asInteger.
	displayTransformation noScale
		ifTrue: [magnifiedForm _ self]
		ifFalse: 
			[scale _ displayTransformation scale.
			scale _ scale x @ scale y.
			(1@1 = scale)
					ifTrue: [scale _ nil. magnifiedForm _ self]
					ifFalse: [magnifiedForm _ self magnify: self boundingBox by: scale]].
	magnifiedForm
		displayOn: aDisplayMedium
		at: absolutePoint - alignmentPoint
		clippingBox: clipRectangle
		rule: ruleInteger
		fillColor: aForm! !


!Form methodsFor: 'bordering'!
border: aRectangle width: borderWidth
	"Paint a border whose rectangular area is defined by aRectangle. The
	width of the border of each side is borderWidth. Uses black for
	drawing the border."

	self border: aRectangle width: borderWidth fillColor: Color black.
! !

!Form methodsFor: 'bordering'!
border: aRectangle width: borderWidth fillColor: aColor
	"Paint a border whose rectangular area is defined by aRectangle. The width of the border of each side is borderWidth. Uses aColor for drawing the border."

	self border: aRectangle
		widthRectangle:
			(Rectangle
				left: borderWidth
				right: borderWidth
				top: borderWidth
				bottom: borderWidth)
		rule: Form over
		fillColor: aColor.
! !

!Form methodsFor: 'bordering' stamp: 'jm 5/29/2003 17:58'!
border: rect width: borderWidth rule: rule fillColor: fillColor
        "Paint a fillColor colored border whose rectangular area is defined by rect. The width of the border of each side is borderWidth."

	| blt |
	blt _ (BitBlt toForm: self)
		combinationRule: rule;
		fillColor: fillColor;
		sourceOrigin: 0@0;
		destOrigin: rect origin.
	blt width: rect width; height: borderWidth; copyBits.
	blt destY: rect corner y - borderWidth; copyBits.
	blt
		destY: rect origin y + borderWidth;
		width: borderWidth;
		height: rect height - borderWidth - borderWidth;
		copyBits.
	blt destX: rect corner x - borderWidth; copyBits.
! !

!Form methodsFor: 'bordering'!
border: aRectangle widthRectangle: insets rule: combinationRule fillColor: aColor
	"Paint a border whose rectangular area is defined by aRectangle. The width of each edge of the border is determined by the four coordinates of insets. Uses aColor and combinationRule for drawing the border."

	(aRectangle areasOutside: (aRectangle insetBy: insets)) do:
		[:edgeStrip | self fill: edgeStrip rule: combinationRule fillColor: aColor].
! !

!Form methodsFor: 'bordering' stamp: 'jm 5/29/2003 18:06'!
borderFormOfWidth: borderWidth sharpCorners: sharpen
	"Smear this form around and then subtract the original to produce
	an outline.  If sharpen is true, then cause right angles to be outlined
	by right angles (takes an additional diagonal smears ANDed with both
	horizontal and vertical smears)."
	| smearForm bigForm smearPort all cornerForm cornerPort nbrs |
	depth > 1 ifTrue: [self halt]. "Only meaningful for B/W forms."
	bigForm _ self deepCopy.
	all _ bigForm boundingBox.
	smearForm _ Form extent: self extent.
	smearPort _ BitBlt toForm: smearForm.
	sharpen ifTrue:
		[cornerForm _ Form extent: self extent.
		cornerPort _ BitBlt toForm: cornerForm].
	nbrs _ (0@0) fourNeighbors.
	1 to: borderWidth do:
		[:i |  "Iterate to get several layers of 'skin'"
		nbrs do:
			[:d |  "Smear the self in 4 directions to grow each layer of skin"
			smearPort copyForm: bigForm to: d rule: Form under].
		sharpen ifTrue:
			["Special treatment to smear sharp corners"
			nbrs with: ((2 to: 5) collect: [:i2 | nbrs atWrap: i2]) do:
				[:d1 :d2 |
				"Copy corner points diagonally"
				cornerPort copyForm: bigForm to: d1+d2 rule: Form over.
				"But only preserve if there were dots on either side"
				cornerPort copyForm: bigForm to: d1+d1+d2 rule: Form and.
				cornerPort copyForm: bigForm to: d1+d2+d2 rule: Form and.
				smearPort copyForm: cornerForm to: 0@0 rule: Form under].
			].
		bigForm copy: all from: 0@0 in: smearForm rule: Form over.
		].
	"Now erase the original shape to obtain the outline"
	bigForm copy: all from: 0@0 in: self rule: Form erase.
	^ bigForm! !

!Form methodsFor: 'bordering'!
borderWidth: anInteger 
	"Set the width of the border for the receiver to be anInteger and paint it 
	using black as the border color."

	self border: self boundingBox width: anInteger fillColor: Color black! !

!Form methodsFor: 'bordering'!
shapeBorder: aColor width: borderWidth interiorPoint: interiorPoint
	sharpCorners: sharpen internal: internal
	"Identify the shape (region of identical color) at interiorPoint,
	and then add an outline of width=borderWidth and color=aColor.
	If sharpen is true, then cause right angles to be outlined by
	right angles.  If internal is true, then produce a border that lies
	within the identified shape.  Thus one can put an internal border
	around the whole background, thus effecting a normal border
	around every other foreground image."
	| shapeForm borderForm interiorColor |
	"First identify the shape in question as a B/W form"
	interiorColor _ self colorAt: interiorPoint.
	shapeForm _ (self makeBWForm: interiorColor) reverse
				findShapeAroundSeedBlock:
					[:form | form pixelValueAt: interiorPoint put: 1].
	"Reverse the image to grow the outline inward"
	internal ifTrue: [shapeForm reverse].
	"Now find the border fo that shape"
	borderForm _ shapeForm borderFormOfWidth: borderWidth sharpCorners: sharpen.
	"Finally use that shape as a mask to paint the border with color"
	self fillShape: borderForm fillColor: aColor! !


!Form methodsFor: 'filling' stamp: 'di 2/19/1999 07:07'!
anyShapeFill
	"Fill the interior of the outermost outlined region in the receiver, a 1-bit deep form.  Typically the resulting form is used with fillShape:fillColor: to paint a solid color.  See also convexShapeFill:"

	| shape |
	"Draw a seed line around the edge and fill inward from the outside."
	shape _ self findShapeAroundSeedBlock: [:f | f borderWidth: 1].
	"Reverse so that this becomes solid in the middle"
	shape _ shape reverse.
	"Finally erase any bits from the original so the fill is only elsewhere"
	shape copy: shape boundingBox from: self to: 0@0 rule: Form erase.
	^ shape! !

!Form methodsFor: 'filling'!
bitPatternForDepth: suspectedDepth
	"Only called when a Form is being used as a fillColor.  Use a Pattern or InfiniteForm instead for this purpose.
	Interpret me as an array of (32/depth) Color pixelValues.  BitBlt aligns the first element of this array with the top scanline of the destinationForm, the second with the second, and so on, cycling through the color array as necessary. 6/18/96 tk"

	^ self! !

!Form methodsFor: 'filling' stamp: 'tk 6/20/96'!
colorAt: aPoint
	"Return the color in the pixel at the given point.  "

	^ Color 
		colorFromPixelValue: (self pixelValueAt: aPoint)
		depth: depth
! !

!Form methodsFor: 'filling' stamp: 'tk 6/20/96'!
colorAt: aPoint put: aColor
	"Store a Color into the pixel at coordinate aPoint.  "

	self pixelValueAt: aPoint put: (aColor pixelValueForDepth: depth).

"[Sensor anyButtonPressed] whileFalse:
	[Display colorAt: Sensor cursorPoint put: Color red]"
! !

!Form methodsFor: 'filling' stamp: 'jm 11/15/2005 19:21'!
colorNoAlphaAt: aPoint
	"Answer the color in the pixel at the given point, ignoring alpha."

	^ Color colorFromPixelValue: (self pixelValueNoAlphaAt: aPoint) depth: depth
! !

!Form methodsFor: 'filling' stamp: 'di 9/11/1998 16:25'!
convexShapeFill: aMask 
	"Fill the interior of the outtermost outlined region in the receiver.  The outlined region must not be concave by more than 90 degrees.  Typically aMask is Color black, to produce a solid fill. then the resulting form is used with fillShape: to paint a solid color.  See also anyShapeFill"
	| destForm tempForm |
	destForm _ Form extent: self extent.  destForm fillBlack.
	tempForm _ Form extent: self extent.
	(0@0) fourNeighbors do:
		[:dir |  "Smear self in all 4 directions, and AND the result"
		self displayOn: tempForm at: (0@0) - self offset.
		tempForm smear: dir distance: (dir dotProduct: tempForm extent) abs.
		tempForm displayOn: destForm at: 0@0
			clippingBox: destForm boundingBox
			rule: Form and fillColor: nil].
	destForm displayOn: self at: 0@0
		clippingBox: self boundingBox
		rule: Form over fillColor: aMask! !

!Form methodsFor: 'filling'!
fill: aRectangle fillColor: aColor
	"Fill the given rectangular area of the receiver with the given color."

	self fill: aRectangle rule: Form over fillColor: aColor.
! !

!Form methodsFor: 'filling' stamp: 'jm 5/25/2003 11:47'!
fill: aRectangle rule: anInteger fillColor: aForm 
	"Fill a rectangular area of the receiver with the given color and combination rule."

	(BitBlt toForm: self)
		copy: aRectangle
		from: 0@0 in: nil
		fillColor: aForm rule: anInteger.
! !

!Form methodsFor: 'filling'!
fillBlack
	"Fill the entire receiver with black."

	self fill: self boundingBox rule: Form over fillColor: Color black.
! !

!Form methodsFor: 'filling'!
fillBlack: aRectangle
	"Fill the given rectangular area of the receiver with black."

	self fill: aRectangle rule: Form over fillColor: Color black.
! !

!Form methodsFor: 'filling'!
fillColor: aColor
	"Fill the entire receiver with the given color."

	self fill: self boundingBox rule: Form over fillColor: aColor.
! !

!Form methodsFor: 'filling' stamp: 'jm 12/20/2005 17:29'!
fillFromXColorBlock: colorBlock
	"Horizontal Gradient Fill. Supply relative x in [0.0 ... 1.0] to colorBlock, and paint each pixel with the color that comes back"
	"((Form extent: 100@100 depth: Display depth)
		fillFromXColorBlock: [:x | Color r: x g: 0.0 b: 0.5]) display"

	| div |
	width < 2 ifTrue: [^ self fillColor: (colorBlock value: 0)].
	div _ (width - 1) asFloat.
	0 to: (width - 1) do: [:x |
		self fill: (x@0 extent: 1@height) 
			fillColor: (colorBlock value: x asFloat / div)].
! !

!Form methodsFor: 'filling' stamp: 'jm 12/20/2005 17:29'!
fillFromYColorBlock: colorBlock
	"Vertical Gradient Fill. Supply relative y in [0.0 ... 1.0] to colorBlock, and paint each pixel with the color that comes back."
	"((Form extent: 100@100 depth: Display depth)
		fillFromYColorBlock: [:y | Color r: y g: 0.0 b: 0.5]) display"

	| div |
	height < 2 ifTrue: [^ self fillColor: (colorBlock value: 0)].
	div _ (height - 1) asFloat.
	0 to: (height - 1) do: [:y |
		self fill: (0@y extent: width@1) 
			fillColor: (colorBlock value: y asFloat / div)].
! !

!Form methodsFor: 'filling' stamp: 'jm 12/20/2005 16:09'!
fillRadialFromXColorBlock: colorBlock center: aPoint
	"Horizontal Gradient Fill. Supply relative x in [0.0 ... 1.0] to colorBlock, and paint each pixel with the color that comes back."

	| canvas m div t |
	canvas _ self getCanvas.
	self fill: self boundingBox fillColor: (colorBlock value: 1).
	m _ width max: height.
	m > 1 ifFalse: [^ self].

	div _ (m - 1) asFloat.
	(m - 1) negated to: 0 do: [:x |
		t _ x abs.  
		canvas
			frameOval: (Rectangle center: aPoint extent: t@t)
			color: (colorBlock value: t asFloat / div)].
! !

!Form methodsFor: 'filling'!
fillShape: aShapeForm fillColor: aColor
	"Fill a region corresponding to 1 bits in aShapeForm with the given color."

	^ self fillShape: aShapeForm fillColor: aColor at: 0@0.
! !

!Form methodsFor: 'filling' stamp: 'jm 5/29/2003 17:59'!
fillShape: aShapeForm fillColor: aColor at: location
	"Fill a region corresponding to 1 bits in aShapeForm with the given color."

	((BitBlt destForm: self sourceForm: aShapeForm fillColor: aColor
		combinationRule: Form paint
		destOrigin: location + aShapeForm offset sourceOrigin: 0@0
		extent: self extent clipRect: self boundingBox)
		colorMap: (Bitmap with: 0 with: 16rFFFFFFFF))
		copyBits.
! !

!Form methodsFor: 'filling'!
fillWhite
	"Fill the entire receiver with white."

	self fill: self boundingBox fillColor: Color white.
! !

!Form methodsFor: 'filling'!
fillWhite: aRectangle
	"Fill the given rectangular area of the receiver with white."

	self fill: aRectangle rule: Form over fillColor: Color white.
! !

!Form methodsFor: 'filling' stamp: 'jm 5/29/2003 17:59'!
findShapeAroundSeedBlock: seedBlock
	"Build a shape that is black in any region marked by seedBlock. 
	SeedBlock will be supplied a form, in which to blacken various
	pixels as 'seeds'.  Then the seeds are smeared until 
	there is no change in the smear when it fills the region, ie,
	when smearing hits a black border and thus goes no further."

	| smearForm previousSmear all count smearPort |
	depth > 1 ifTrue: [self halt]. "Only meaningful for B/W forms."
	all _ self boundingBox.
	smearForm _ Form extent: self extent.
	smearPort _ BitBlt toForm: smearForm.
	seedBlock value: smearForm.		"Blacken seeds to be smeared"
	smearPort copyForm: self to: 0@0 rule: Form erase.  "Clear any in black"
	previousSmear _ smearForm deepCopy.
	count _ 1.
	[count = 10 and:   "check for no change every 10 smears"
		[count _ 1.
		previousSmear copy: all from: 0@0 in: smearForm rule: Form reverse.
		previousSmear isAllWhite]]
		whileFalse: 
			[smearPort copyForm: smearForm to: 1@0 rule: Form under.
			smearPort copyForm: smearForm to: -1@0 rule: Form under.
			"After horiz smear, trim around the region border"
			smearPort copyForm: self to: 0@0 rule: Form erase.
			smearPort copyForm: smearForm to: 0@1 rule: Form under.
			smearPort copyForm: smearForm to: 0@-1 rule: Form under.
			"After vert smear, trim around the region border"
			smearPort copyForm: self to: 0@0 rule: Form erase.
			count _ count+1.
			count = 9 ifTrue: "Save penultimate smear for comparison"
				[previousSmear copy: all from: 0@0 in: smearForm rule: Form over]].
	"Now paint the filled region in me with aHalftone"
	^ smearForm! !

!Form methodsFor: 'filling' stamp: 'di 3/2/98 12:42'!
isAllWhite
	"Answer whether all bits in the receiver are white (=0)."

	self unhibernate.
	1 to: bits size do: [:i | (bits at: i) = 0 ifFalse: [^ false]].
	^ true! !

!Form methodsFor: 'filling'!
isTransparentAt: aPoint 
	"Return true if the receiver is transparent at the given point."

	depth = 1 ifTrue: [^ false].  "no transparency at depth 1"
	^ (self pixelValueAt: aPoint) = (Color transparent pixelValueForDepth: depth)
! !

!Form methodsFor: 'filling'!
makeBWForm: foregroundColor
	"Map this form into a B/W form with 1's in the foreground regions."
	| bwForm map |
	bwForm _ Form extent: self extent.
	map _ self newColorMap.  "All non-foreground go to 0's"
	map at: (foregroundColor indexInMap: map) put: 1.
	bwForm copyBits: self boundingBox from: self at: 0@0 colorMap: map.
	^ bwForm! !

!Form methodsFor: 'filling' stamp: 'jm 11/18/2005 19:56'!
oneBitShapeFill: aColor interiorPoint: aPoint

	depth > 1 ifTrue: [self error: 'This call only meaningful for 1-bit forms'].

	(self findShapeAroundSeedBlock: [:f | f pixelValueAt: aPoint put: 1])
		displayOn: self
		at: 0@0
		clippingBox: self boundingBox
		rule: Form under
		fillColor: aColor.
! !

!Form methodsFor: 'filling' stamp: 'jm 5/29/2003 18:00'!
pixelValueAt: aPoint 
	"Return the raw pixel value at the given point. This pixel value depends on the receiver's depth. Typical clients use colorAt: to get a Color.  "

	^ (BitBlt bitPeekerFromForm: self) pixelAt: aPoint
! !

!Form methodsFor: 'filling' stamp: 'jm 5/29/2003 18:00'!
pixelValueAt: aPoint put: pixelValue
	"Store the given raw pixel value at the given point. Typical clients use colorAt:put: to store a color. "

	(BitBlt bitPokerToForm: self) pixelAt: aPoint put: pixelValue.
! !

!Form methodsFor: 'filling' stamp: 'jm 11/15/2005 19:19'!
pixelValueNoAlphaAt: aPoint 
	"Answer the raw pixel value at the given point. The pixel value depends on the receiver's depth. If the depth is 32 and the pixel is not transparent, ignore alpha."

	| pixel |
	depth < 32 ifTrue: [^ self pixelValueAt: aPoint].
	pixel _ (BitBlt bitPeekerFromForm: self) pixelAt: aPoint.
	pixel > 0 ifTrue: [pixel _ pixel bitOr: 16rFF000000].  "treat as opaque"
	^ pixel
! !

!Form methodsFor: 'filling' stamp: 'jm 6/18/1999 19:01'!
reverse
	"Invert the colors of the receiver."

	self fill: self boundingBox rule: Form reverse fillColor: (Color quickHighLight: self depth).
! !

!Form methodsFor: 'filling' stamp: 'jm 6/18/1999 19:00'!
reverse: aRectangle
	"Invert the colors of the receiver in the given rectangular area."

	self fill: aRectangle rule: Form reverse fillColor: (Color quickHighLight: self depth).
! !

!Form methodsFor: 'filling' stamp: 'jm 11/18/2005 19:57'!
shapeFill: aColor interiorPoint: aPoint
	"Fill the area of similar colors around the given point with the given solid color."

	| mapDepth maskForm map c bb |
	mapDepth _ 9.  "can be 9 or 12"
	depth = 1 ifTrue: [^ self oneBitShapeFill: aColor interiorPoint: aPoint].

	"map this form into a B/W mask form with 0's in areas of matching color"
	maskForm _ Form extent: self extent depth: 1.
	map _ Bitmap new: (1 bitShift: (depth min: mapDepth)) withAll: 1.
	depth <= 8
		ifTrue: [
			map at: (self pixelValueAt: aPoint) + 1 put: 0]
		ifFalse: [
			c _ self colorNoAlphaAt: aPoint.
			map at: (c pixelValueForDepth: mapDepth) + 1 put: 0].
	maskForm copyBits: self boundingBox from: self at: 0@0 colorMap: map.

	"now fill the shape in the mask"
	maskForm _ maskForm findShapeAroundSeedBlock: [:f | f pixelValueAt: aPoint put: 1].

	"use mask to fill with solid color"
	bb _ (BitBlt toForm: self)
		destOrigin: 0@0;
		sourceForm: maskForm;
		sourceRect: maskForm boundingBox;
		colorMap: (Bitmap with: 0 with: 16rFFFFFFFF).

	aColor isTransparent
		ifTrue: [bb combinationRule: Form erase1bitShape; copyBits]
		ifFalse: [bb fillColor: aColor; combinationRule: Form paint; copyBits].

	^ maskForm
! !

!Form methodsFor: 'filling' stamp: 'jm 12/20/2005 17:20'!
shapeFillGradientFrom: fromColor to: toColor at: aPoint type: aSymbol
	"Fill the area of similar colors around the given point with a gradient of the given type."

	| mapDepth maskForm map r newForm c |
	mapDepth _ 9.  "can be 9 or 12"
	depth = 1 ifTrue: [^ self oneBitShapeFill: fromColor interiorPoint: aPoint].

	"map this form into a B/W mask form with 0's in areas of matching color"
	maskForm _ Form extent: self extent depth: 1.
	map _ Bitmap new: (1 bitShift: (depth min: mapDepth)) withAll: 1.
	depth <= 8
		ifTrue: [
			map at: (self pixelValueAt: aPoint) + 1 put: 0]
		ifFalse: [
			c _ self colorNoAlphaAt: aPoint.
			map at: (c pixelValueForDepth: mapDepth) + 1 put: 0].
	maskForm copyBits: self boundingBox from: self at: 0@0 colorMap: map.

	"now fill the shape"
	maskForm _ maskForm findShapeAroundSeedBlock:
		[:form | form pixelValueAt: aPoint put: 1].

	r _ maskForm rectangleEnclosingPixelsNotOfColor: Color white.
	r area = 0 ifTrue:[^ self].  "zero width or height"

	newForm _ Form extent: r extent depth: 32.
	aSymbol = #radial
		ifTrue: [
			newForm
				fillRadialFromXColorBlock: [:m | toColor mixed: m with: fromColor]
				center: aPoint - r origin]
		ifFalse: [
			aSymbol = #horizontal
				ifTrue: [newForm fillFromXColorBlock: [:m | toColor mixed: m with: fromColor]]
				ifFalse: [newForm fillFromYColorBlock: [:m | toColor mixed: m with: fromColor]]].

	"use the mask to cut out the shape"
	((BitBlt destForm: newForm sourceForm: maskForm
		fillColor: nil
		combinationRule: Form erase1bitShape	"Cut a hole in the picture with my mask"
		destOrigin: maskForm offset 
		sourceOrigin: r origin
		extent: self extent clipRect: self boundingBox)
			colorMap: (Bitmap with: 16rFFFFFFFF with: 0))
			copyBits.

	"copy the masked gradient shape into myself"
	self copy: newForm boundingBox
		from: newForm
		to: r origin
		rule: Form paint.
! !


!Form methodsFor: 'scaling, rotation' stamp: 'jm 5/29/2003 17:59'!
flipBy: direction centerAt: aPoint
	"Return a copy of the receiver flipped either #vertical or #horizontal."

	| newForm quad |
	newForm _ self class extent: self extent depth: depth.
	quad _ self boundingBox innerCorners.
	quad _ (direction = #vertical ifTrue: [#(2 1 4 3)] ifFalse: [#(4 3 2 1)])
		collect: [:i | quad at: i].
	(WarpBlt toForm: newForm)
		sourceForm: self;
		colorMap: (self colormapIfNeededForDepth: depth);
		combinationRule: 3;
		copyQuad: quad toRect: newForm boundingBox.
	newForm offset: (self offset flipBy: direction centerAt: aPoint).
	^ newForm
"
[Sensor anyButtonPressed] whileFalse:
	[((Form fromDisplay: (Sensor cursorPoint extent: 130@66))
			flipBy: #vertical centerAt: 0@0) display]
"
"Consistency test...
 | f f2 p | [Sensor anyButtonPressed] whileFalse:
	[f _ Form fromDisplay: ((p _ Sensor cursorPoint) extent: 31@41).
	Display fillBlack: (p extent: 31@41).
	f2 _ f flipBy: #vertical centerAt: 0@0.
	(f2 flipBy: #vertical centerAt: 0@0) displayAt: p]
"
! !

!Form methodsFor: 'scaling, rotation' stamp: 'jm 6/15/2003 19:00'!
magnify: aRectangle by: scale 
	"Answer a Form created as a scaling of the receiver. Scale may be a Float, and may be greater or less than 1.0."

	^ self magnify: aRectangle by: scale smoothing: 1

"Dynamic test...
[Sensor anyButtonPressed] whileFalse:
	[(Display magnify: (Sensor cursorPoint extent: 31@41) by: 5@3) display]
"
"Scaling test...
| f cp | f _ Form fromDisplay: (Rectangle originFromUser: 100@100).
Display restoreAfter: [Sensor waitNoButton.
[Sensor anyButtonPressed] whileFalse:
	[cp _ Sensor cursorPoint.
	(f magnify: f boundingBox by: (cp x asFloat@cp y asFloat)/f extent) display]]
"
"Consistency test...
| f f2 |
f _ Form fromDisplay: (Rectangle originFromUser: 100@100).
f2 _ f magnify: f boundingBox by: 5@3.
(f2 magnify: f2 boundingBox by: 5 reciprocal @ 3 reciprocal) display
"
! !

!Form methodsFor: 'scaling, rotation' stamp: 'jm 9/8/2006 10:18'!
magnify: aRectangle by: scale smoothing: smoothing
	"Answer a Form created as a scaling of the receiver. Scale may be a Float, and may be greater or less than 1.0."

	| newForm cm cellSize |
	newForm _ self class extent: (aRectangle extent * scale) truncated depth: depth.
	cm _ self colormapIfNeededForDepth: depth.
	cellSize _ smoothing.
	(self isKindOf: ColorForm) ifTrue: [
		newForm colors: self colors.
		cm _ nil.
		cellSize _ 1].

	(WarpBlt toForm: newForm)
		sourceForm: self;
		colorMap: cm;
		cellSize: cellSize;  "installs a new colormap if cellSize > 1"
		combinationRule: Form over;
		copyQuad: aRectangle innerCorners toRect: newForm boundingBox.
	^ newForm

"Dynamic test...
[Sensor anyButtonPressed] whileFalse:
        [(Display magnify: (Sensor cursorPoint extent: 131@81) by: 0.5 smoothing: 2) display]
"
"Scaling test...
| f cp | f _ Form fromDisplay: (Rectangle originFromUser: 100@100).
Display restoreAfter: [Sensor waitNoButton.
[Sensor anyButtonPressed] whileFalse:
        [cp _ Sensor cursorPoint.
        (f magnify: f boundingBox by: (cp x asFloat@cp y asFloat)/f extent smoothing: 2) display]]
"! !

!Form methodsFor: 'scaling, rotation' stamp: 'jm 6/15/2003 18:52'!
magnifyBy: scale 
	"Answer a Form created as a scaling of the receiver. Scale may be a Float, and it may be greater or less than 1.0."

	^ self
		magnify: self boundingBox
		by: scale
		smoothing: (scale < 1 ifTrue: [2] ifFalse: [1])  "smooth if scale < 1"
! !

!Form methodsFor: 'scaling, rotation'!
rotateBy: deg
	"Rotate the receiver by the indicated number of degrees."
	"rot is the destination form, bit enough for any angle."

	^ self rotateBy: deg smoothing: 1
"
 | a f |  f _ Form fromDisplay: (0@0 extent: 200@200).  a _ 0.
[Sensor anyButtonPressed] whileFalse:
	[((Form fromDisplay: (Sensor cursorPoint extent: 130@66))
		rotateBy: (a _ a+5)) display].
f display
"! !

!Form methodsFor: 'scaling, rotation' stamp: 'jm 10/16/2007 18:44'!
rotateBy: direction centerAt: aPoint
	"Return a rotated copy of the receiver. 
	direction = #none, #right, #left, or #pi"

	| newForm quad rot cm |
	direction == #none ifTrue: [^ self].
	newForm _ self class extent: (direction = #pi ifTrue: [width@height]
											ifFalse: [height@width]) depth: depth.
	quad _ self boundingBox innerCorners.
	rot _ #(right pi left) indexOf: direction.
	(self isKindOf: ColorForm)
		ifTrue: [cm _ nil. newForm colors: self colors]
		ifFalse: [cm _ self colormapIfNeededForDepth: depth].

	(WarpBlt toForm: newForm)
		sourceForm: self;
		colorMap: cm;
		combinationRule: 3;
		copyQuad: ((1+rot to: 4+rot) collect: [:i | quad atWrap: i])
			 toRect: newForm boundingBox.
	newForm offset: (self offset rotateBy: direction centerAt: aPoint).

	^ newForm
"
[Sensor anyButtonPressed] whileFalse:
	[((Form fromDisplay: (Sensor cursorPoint extent: 130@66))
		rotateBy: #left centerAt: 0@0) display]
"
"Consistency test...
 | f f2 p | [Sensor anyButtonPressed] whileFalse:
	[f _ Form fromDisplay: ((p _ Sensor cursorPoint) extent: 31@41).
	Display fillBlack: (p extent: 31@41).
	f2 _ f rotateBy: #left centerAt: 0@0.
	(f2 rotateBy: #right centerAt: 0@0) displayAt: p]
"
! !

!Form methodsFor: 'scaling, rotation' stamp: 'jm 5/29/2003 18:00'!
rotateBy: deg magnify: scale smoothing: cellSize
	"Rotate the receiver by the indicated number of degrees and magnify.  "
	"rot is the destination form, big enough for any angle."

	| side rot warp r1 pts p bigSide |
	side _ 1 + ((width*width) + (height*height)) asFloat sqrt asInteger.
	bigSide _ (side * scale) rounded.
	rot _ Form extent: bigSide@bigSide depth: self depth.
	warp _ (WarpBlt toForm: rot)
		sourceForm: self;
		colorMap: (self colormapIfNeededForDepth: depth);
		cellSize: cellSize;  "installs a new colormap if cellSize > 1"
		combinationRule: Form paint.
	r1 _ (0@0 extent: side@side) align: (side@side)//2 with: self boundingBox center.

	"Rotate the corners of the source rectangle." 
	pts _ r1 innerCorners collect:
		[:pt | p _ pt - r1 center.
		(r1 center x asFloat + (p x asFloat*deg degreeCos) + (p y asFloat*deg degreeSin)) @
		(r1 center y asFloat - (p x asFloat*deg degreeSin) + (p y asFloat*deg degreeCos))].
	warp copyQuad: pts toRect: rot boundingBox.
	^ rot
"
 | a f |  f _ Form fromDisplay: (0@0 extent: 200@200).  a _ 0.
[Sensor anyButtonPressed] whileFalse:
	[((Form fromDisplay: (Sensor cursorPoint extent: 130@66))
		rotateBy: (a _ a+5) magnify: 0.75 smoothing: 2) display].
f display
"! !

!Form methodsFor: 'scaling, rotation' stamp: 'sw 8/9/96'!
rotateBy: deg rotationCenter: aPoint
	"Rotate the receiver by the indicated number of degrees.  This variant gets a rotation center, but in fact ignores the thing -- awaiting someone's doing the right thing.   
	Note that rotationCenter should now be easy to include in the offset of the resulting form -- see <Point> rotateBy: angle about: center.  Could be even faster by sharing the sin, cos inside rotateBy:.  This should really be reversed so that this becomes the workhorse, and rotateBy: calls this with rotationCenter: self boundingBox center.  And while we're at it, why not include scaling?   "

	^ self rotateBy: deg smoothing: 1! !

!Form methodsFor: 'scaling, rotation' stamp: 'jm 5/29/2003 18:00'!
rotateBy: deg smoothing: cellSize
	"Rotate the receiver by the indicated number of degrees."
	"rot is the destination form, bit enough for any angle."

	| side rot warp r1 pts p center |
	side _ 1 + ((width*width) + (height*height)) asFloat sqrt asInteger.
	rot _ Form extent: side@side depth: self depth.
	center _ rot extent // 2.

	"Now compute the sin and cos constants for the rotation angle." 
	warp _ (WarpBlt toForm: rot)
		sourceForm: self;
		colorMap: (self colormapIfNeededForDepth: depth);
		cellSize: cellSize;  "installs a new colormap if cellSize > 1"
		combinationRule: Form over.
	r1 _ rot boundingBox align: center with: self boundingBox center.

	pts _ r1 innerCorners collect:
		[:pt | p _ pt - r1 center.
		(r1 center x asFloat + (p x asFloat*deg degreeCos) + (p y asFloat*deg degreeSin)) @
		(r1 center y asFloat - (p x asFloat*deg degreeSin) + (p y asFloat*deg degreeCos))].
	warp copyQuad: pts toRect: rot boundingBox.
	^ rot
"
 | a f |  f _ Form fromDisplay: (0@0 extent: 200@200).  a _ 0.
[Sensor anyButtonPressed] whileFalse:
	[((Form fromDisplay: (Sensor cursorPoint extent: 130@66))
		rotateBy: (a _ a+5) smoothing: 2) display].
f display
"! !

!Form methodsFor: 'scaling, rotation' stamp: 'jm 6/28/2004 13:41'!
toThumbnail: extent borderWidth: borderWidth borderColor: backgroundColor
	"Answer a thumbnail with the specified extent, border width, and background color."

	| result e r p |
	result _ Form extent: extent depth: 16.
	result fillColor: backgroundColor.
	result border: result boundingBox width: borderWidth.

	"calculate the rectangle to be used by the thumbnail image"
	self width > self height
		ifTrue: [e _ result width @ ((self height * result width) // self width)]
		ifFalse: [e _ ((self width * result height) // self height) @ result height].
	p _ (result extent - e) // 2.
	r _ p extent: e.

	(WarpBlt toForm: result)
		sourceForm: self;
		cellSize: 2;  "do smoothing; this also installs a colormap"
		combinationRule: Form over;
		copyQuad: self boundingBox innerCorners toRect: (r insetBy: (borderWidth + 1)).

	^ result

! !


!Form methodsFor: 'editing' stamp: 'jm 6/1/2003 06:07'!
bitEdit
	"Create and schedule an editor on me located in an area designated by the user."

	BitEditor openOnForm: self.
! !

!Form methodsFor: 'editing'!
bitEditAt: magnifiedFormLocation scale: scaleFactor 
	"Create and schedule a view whose top left corner is magnifiedLocation 
	and that contains a view of the receiver magnified by scaleFactor that 
	can be modified using the Bit Editor. It also contains a view of the 
	original form."

	BitEditor openOnForm: self at: magnifiedFormLocation scale: scaleFactor ! !


!Form methodsFor: 'image manipulation'!
cgForPixelValue: pv orNot: not
	"Return the center of gravity for all pixels of value pv.
	Note:  If orNot is true, then produce the center of gravity for all pixels
	that are DIFFERENT from the supplied (background) value"
	| pixCount weighted xAndY |
	xAndY _ (Array with: (self xTallyPixelValue: pv orNot: not)
					with: (self yTallyPixelValue: pv orNot: not)) collect:
		[:profile |	"For both x and y profiles..."
		pixCount _ 0.  weighted _ 0.
		profile doWithIndex:
			[:t :i | pixCount _ pixCount + t.
			weighted _ weighted + (t*i)].
		pixCount = 0  "Produce average of nPixels weighted by coordinate"
			ifTrue: [0.0]
			ifFalse: [weighted asFloat / pixCount asFloat - 1.0]].

	^ xAndY first @ xAndY last
"
| f cg |
[Sensor anyButtonPressed] whileFalse:
	[f _ Form fromDisplay: (Sensor cursorPoint extent: 50@50).
	cg _ f cgForPixelValue: (Color black pixelValueForDepth: f depth) orNot: false.
	f displayAt: 0@0.
	Display fill: (cg extent: 2@2) fillColor: Color red].
	ScheduledControllers restore
"! !

!Form methodsFor: 'image manipulation' stamp: 'bf 10/12/1999 18:07'!
dominantColor
	| tally max maxi |
	depth > 16 ifTrue:
		[^(self asFormOfDepth: 16) dominantColor].
	tally _ self tallyPixelValues.
	max _ maxi _ 0.
	tally withIndexDo: [:n :i | n > max ifTrue: [max _ n. maxi _ i]].
	^ Color colorFromPixelValue: maxi - 1 depth: depth! !

!Form methodsFor: 'image manipulation' stamp: 'ar 7/23/1999 17:04'!
orderedDither32To16
	"Do an ordered dithering for converting from 32 to 16 bit depth."
	| ditherMatrix ii out inBits outBits index pv dmv r di dmi dmo g b pvOut outIndex |
	self depth = 32 ifFalse:[^self error:'Must be 32bit for this'].
	ditherMatrix _ #(	0	8	2	10
						12	4	14	6
						3	11	1	9
						15	7	13	5).
	ii _ (0 to: 31) collect:[:i| i].
	out _ Form extent: self extent depth: 16.
	inBits _ self bits.
	outBits _ out bits.
	index _ outIndex _ 0.
	pvOut _ 0.
	0 to: self height-1 do:[:y|
		0 to: self width-1 do:[:x|
			pv _ inBits at: (index _ index + 1).
			dmv _ ditherMatrix at: (y bitAnd: 3) * 4 + (x bitAnd: 3) + 1.
			r _ pv bitAnd: 255.	di _ r * 496 bitShift: -8.
			dmi _ di bitAnd: 15.	dmo _ di bitShift: -4.
			r _ dmv < dmi ifTrue:[ii at: 2+dmo] ifFalse:[ii at: 1+dmo].
			g _ (pv bitShift: -8) bitAnd: 255.	di _ g * 496 bitShift: -8.
			dmi _ di bitAnd: 15.	dmo _ di bitShift: -4.
			g _ dmv < dmi ifTrue:[ii at: 2+dmo] ifFalse:[ii at: 1+dmo].
			b _ (pv bitShift: -16) bitAnd: 255.	di _ b * 496 bitShift: -8.
			dmi _ di bitAnd: 15.	dmo _ di bitShift: -4.
			b _ dmv < dmi ifTrue:[ii at: 2+dmo] ifFalse:[ii at: 1+dmo].
			pvOut _ (pvOut bitShift: 16) + 
						(b bitShift: 10) + (g bitShift: 5) + r.
			(x bitAnd: 1) = 1 ifTrue:[
				outBits at: (outIndex _ outIndex+1) put: pvOut.
				pvOut _ 0].
		].
		(self width bitAnd: 1) = 1 ifTrue:[
			outBits at: (outIndex _ outIndex+1) put: (pvOut bitShift: -16).
			pvOut _ 0].
	].
	^out! !

!Form methodsFor: 'image manipulation' stamp: 'jm 3/14/2004 09:52'!
outlineWidth: w color: outlineColor depth: resultDepth
	"Answer a Form containing the outline of this Form."

	| mask cm outline neg result |
	"make a mask form with black for all non-transparent pixels"
	mask _ Form extent: (self extent + w + w) depth: 2.
	cm _ self newColorMap.
	cm atAllPut: (Color black pixelValueForDepth: mask depth).
	cm at: 1 put: 0.
	mask copyBits: self boundingBox from: self at: w@w colorMap: cm.

	"stamp the mask form onto a new form at various offsets"
	outline _ Form extent: mask extent depth: mask depth.
	1 to: w do: [:pos |
		neg _ pos negated.
		mask displayOn: outline at: pos@0 rule: Form paint.
		mask displayOn: outline at: neg@0 rule: Form paint.
		mask displayOn: outline at: 0@pos rule: Form paint.
		mask displayOn: outline at: 0@neg rule: Form paint.
		mask displayOn: outline at: pos@pos rule: Form paint.
		mask displayOn: outline at: pos@neg rule: Form paint.
		mask displayOn: outline at: neg@pos rule: Form paint.
		mask displayOn: outline at: neg@neg rule: Form paint].

	"cut out a hole with the original form"
	mask displayOn: outline at: 0@0 rule: Form erase.

	"copy the outline in the desired color onto the result form"
	result _ Form extent: mask extent depth: resultDepth.
	cm _ outline newColorMap.
	cm
		at: (Color black pixelValueForDepth: outline depth) + 1
		put: (outlineColor pixelValueForDepth: result depth).
	result copyBits: outline boundingBox from: outline at: 0@0 colorMap: cm.
	^ result
! !

!Form methodsFor: 'image manipulation' stamp: 'jm 5/29/2003 18:06'!
pixelCompare: aRect with: otherForm at: otherLoc
	"Compare the selected bits of this form (those within aRect) against
	those in a similar rectangle of otherFrom.  Return the sum of the
	absolute value of the differences of the color values of every pixel.
	Obviously, this is most useful for rgb (16- or 32-bit) pixels but,
	in the case of 8-bits or less, this will return the sum of the differing
	bits of the corresponding pixel values (somewhat less useful)"

	| pixPerWord temp |
	pixPerWord _ 32//depth.
	(aRect left\\pixPerWord = 0 and: [aRect right\\pixPerWord = 0]) ifTrue:
		["If word-aligned, use on-the-fly difference"
		^ (BitBlt toForm: self) copy: aRect from: otherLoc in: otherForm
				fillColor: nil rule: 32].
	"Otherwise, combine in a word-sized form and then compute difference"
	temp _ self copy: aRect.
	temp copy: aRect from: otherLoc in: otherForm rule: 21.
	^ (BitBlt toForm: temp) copy: aRect from: otherLoc in: nil
				fillColor: (Bitmap with: 0) rule: 32
"  Dumb example prints zero only when you move over the original rectangle...
 | f diff | f _ Form fromUser.
[Sensor anyButtonPressed] whileFalse:
	[diff _ f pixelCompare: f boundingBox
		with: Display at: Sensor cursorPoint.
	diff printString , '        ' displayAt: 0@0]
"! !

!Form methodsFor: 'image manipulation' stamp: 'jm 5/29/2003 18:00'!
primCountBits
	"Count the non-zero pixels of this form."

	depth > 8 ifTrue:
		[^(self asFormOfDepth: 8) primCountBits].
	^ (BitBlt toForm: self)
		fillColor: (Bitmap with: 0);
		destRect: (0@0 extent: width@height);
		combinationRule: 32;
		copyBits! !

!Form methodsFor: 'image manipulation' stamp: 'jm 5/29/2003 18:10'!
rectangleEnclosingPixelsNotOfColor: aColor
	"Answer the smallest rectangle enclosing all the pixels of me that are different from the given color. Useful for extracting a foreground graphic from its background."

	| cm slice copyBlt countBlt top bottom newH left right |
	"map the specified color to 1 and all others to 0"
	cm _ Bitmap new: (1 bitShift: (depth min: 15)).
	cm primFill: 1.
	cm at: (aColor indexInMap: cm) put: 0.
	cm _ ColorMap colors: cm.

	"build a 1-pixel high horizontal slice and BitBlts for counting pixels of interest"
	slice _ Form extent: width@1 depth: 1.
	copyBlt _ (BitBlt toForm: slice)
		sourceForm: self;
		combinationRule: Form over;
		destX: 0 destY: 0 width: width height: 1;
		colorMap: cm.
	countBlt _ (BitBlt toForm: slice)
		fillColor: (Bitmap with: 0);
		destRect: (0@0 extent: slice extent);
		combinationRule: 32.

	"scan in from top and bottom"
	top _ (0 to: height)
		detect: [:y |
			copyBlt sourceOrigin: 0@y; copyBits.
			countBlt copyBits > 0]
		ifNone: [^ 0@0 extent: 0@0].
	bottom _ (height - 1 to: top by: -1)
		detect: [:y |
			copyBlt sourceOrigin: 0@y; copyBits.
			countBlt copyBits > 0].

	"build a 1-pixel wide vertical slice and BitBlts for counting pixels of interest"
	newH _ bottom - top + 1.
	slice _ Form extent: 1@newH depth: 1.
	copyBlt _ (BitBlt toForm: slice)
		sourceForm: self;
		combinationRule: Form over;
		destX: 0 destY: 0 width: 1 height: newH;
		colorMap: cm.
	countBlt _ (BitBlt toForm: slice)
		fillColor: (Bitmap with: 0);
		destRect: (0@0 extent: slice extent);
		combinationRule: 32.

	"scan in from left and right"
	left _ (0 to: width)
		detect: [:x |
			copyBlt sourceOrigin: x@top; copyBits.
			countBlt copyBits > 0].
	right _ (width - 1 to: left by: -1)
		detect: [:x |
			copyBlt sourceOrigin: x@top; copyBits.
			countBlt copyBits > 0].

	^ left@top corner: (right + 1)@(bottom + 1)
! !

!Form methodsFor: 'image manipulation' stamp: 'jm 5/29/2003 18:00'!
replaceColor: oldColor withColor: newColor
	"Replace one color with another everywhere is this form"

	| cm newInd target ff |
	depth = 32
		ifTrue: [cm _ (Color  cachedColormapFrom: 16 to: 32) copy]
		ifFalse: [cm _ Bitmap new: (1 bitShift: (depth min: 15)).
				1 to: cm size do: [:i | cm at: i put: i - 1]].
	newInd _ newColor pixelValueForDepth: depth.
	cm at: (oldColor pixelValueForDepth: (depth min: 16))+1 put: newInd.
	target _ newColor isTransparent 
		ifTrue: [ff _ Form extent: self extent depth: depth.
			ff fillColor: newColor.  ff]
		ifFalse: [self].
	(BitBlt toForm: target)
		sourceForm: self;
		sourceOrigin: 0@0;
		combinationRule: Form paint;
		destX: 0 destY: 0 width: width height: height;
		colorMap: cm;
		copyBits.
	newColor = Color transparent 
		ifTrue: [target displayOn: self].! !

!Form methodsFor: 'image manipulation' stamp: 'jm 5/29/2003 18:00'!
smear: dir distance: dist
	"Smear any black pixels in this form in the direction dir in Log N steps"

	| skew bb |
	bb _ BitBlt destForm: self sourceForm: self fillColor: nil
		combinationRule: Form under destOrigin: 0@0 sourceOrigin: 0@0
		extent: self extent clipRect: self boundingBox.
	skew _ 1.
	[skew < dist] whileTrue:
		[bb destOrigin: dir*skew; copyBits.
		skew _ skew+skew]! !

!Form methodsFor: 'image manipulation' stamp: 'jm 6/18/1999 18:41'!
tallyPixelValues
	"Answer a Bitmap whose elements contain the number of pixels in this Form with the pixel value corresponding to their index. Note that the pixels of multiple Forms can be tallied together using tallyPixelValuesInRect:into:."

	^ self tallyPixelValuesInRect: self boundingBox
		into: (Bitmap new: (1 bitShift: (self depth min: 15)))
"
Move a little rectangle around the screen and print its tallies...
 | r tallies nonZero |
Cursor blank showWhile: [
[Sensor anyButtonPressed] whileFalse:
	[r _ Sensor cursorPoint extent: 10@10.
	Display border: (r expandBy: 2) width: 2 rule: Form reverse fillColor: nil.
	tallies _ (Display copy: r) tallyPixelValues.
	nonZero _ (1 to: tallies size) select: [:i | (tallies at: i) > 0]
			thenCollect: [:i | (tallies at: i) -> (i-1)].
	nonZero printString , '          ' displayAt: 0@0.
	Display border: (r expandBy: 2) width: 2 rule: Form reverse fillColor: nil]]
"
! !

!Form methodsFor: 'image manipulation' stamp: 'jm 5/29/2003 18:00'!
tallyPixelValuesInRect: aRectangle into: valueTable
	"Tally the selected pixels of this Form into valueTable, a Bitmap of depth 2^depth similar to a color map. Answer valueTable."

	(BitBlt toForm: self)
		sourceForm: self;  "src must be given for color map ops"
		sourceOrigin: 0@0;
		tallyMap: valueTable;
		combinationRule: 33;
		destRect: aRectangle;
		sourceRect: aRectangle;
		copyBits.

	^ valueTable

"
Move a little rectangle around the screen and print its tallies...
 | r tallies nonZero |
Cursor blank showWhile: [
[Sensor anyButtonPressed] whileFalse:
	[r _ Sensor cursorPoint extent: 10@10.
	Display border: (r expandBy: 2) width: 2 rule: Form reverse fillColor: nil.
	tallies _ (Display copy: r) tallyPixelValues.
	nonZero _ (1 to: tallies size) select: [:i | (tallies at: i) > 0]
			thenCollect: [:i | (tallies at: i) -> (i-1)].
	nonZero printString , '          ' displayAt: 0@0.
	Display border: (r expandBy: 2) width: 2 rule: Form reverse fillColor: nil]]
"! !

!Form methodsFor: 'image manipulation' stamp: 'jm 6/30/1999 15:36'!
trimBordersOfColor: aColor
	"Answer a copy of this Form with each edge trimmed in to the first pixel that is not of the given color. (That is, border strips of the given color are removed)."

	| r |
	r _ self rectangleEnclosingPixelsNotOfColor: aColor.
	^ self copy: r
! !

!Form methodsFor: 'image manipulation' stamp: 'jm 5/29/2003 18:00'!
xTallyPixelValue: pv orNot: not
	"Return an array of the number of pixels with value pv by x-value.
	Note that if not is true, then this will tally those different from pv."

	| cm slice countBlt copyBlt |
	cm _ self newColorMap.		"Map all colors but pv to zero"
	not ifTrue: [cm atAllPut: 1].		"... or all but pv to one"
	cm at: pv+1 put: 1 - (cm at: pv+1).
	slice _ Form extent: 1@height.
	copyBlt _ (BitBlt destForm: slice sourceForm: self
				halftoneForm: nil combinationRule: Form over
				destOrigin: 0@0 sourceOrigin: 0@0 extent: 1 @ slice height
				clipRect: slice boundingBox) colorMap: cm.
	countBlt _ (BitBlt toForm: slice)
				fillColor: (Bitmap with: 0);
				destRect: (0@0 extent: slice extent);
				combinationRule: 32.
	^ (0 to: width-1) collect:
		[:x |
		copyBlt sourceOrigin: x@0; copyBits.
		countBlt copyBits]! !

!Form methodsFor: 'image manipulation' stamp: 'jm 5/29/2003 18:06'!
yTallyPixelValue: pv orNot: not
	"Return an array of the number of pixels with value pv by y-value.
	Note that if not is true, then this will tally those different from pv."

	| cm slice copyBlt countBlt |
	cm _ self newColorMap.		"Map all colors but pv to zero"
	not ifTrue: [cm atAllPut: 1].		"... or all but pv to one"
	cm at: pv+1 put: 1 - (cm at: pv+1).
	slice _ Form extent: width@1.
	copyBlt _ (BitBlt destForm: slice sourceForm: self
				halftoneForm: nil combinationRule: Form over
				destOrigin: 0@0 sourceOrigin: 0@0 extent: slice width @ 1
				clipRect: slice boundingBox) colorMap: cm.
	countBlt _ (BitBlt toForm: slice)
				fillColor: (Bitmap with: 0);
				destRect: (0@0 extent: slice extent);
				combinationRule: 32.
	^ (0 to: height-1) collect:
		[:y |
		copyBlt sourceOrigin: 0@y; copyBits.
		countBlt copyBits]! !


!Form methodsFor: 'fileIn/Out' stamp: 'di 8/5/1998 11:37'!
hibernate
	"Replace my bitmap with a compactly encoded representation (a ByteArray).  It is vital that BitBlt and any other access to the bitmap (such as writing to a file) not be used when in this state.  Since BitBlt will fail if the bitmap size is wrong (not = bitsSize), we do not allow replacement by a byteArray of the same (or larger) size."

	"NOTE: This method copies code from Bitmap compressToByteArray so that it can
	nil out the old bits during the copy, thus avoiding 2x need for extra storage."
	| compactBits lastByte |
	(bits isMemberOf: Bitmap) ifFalse: [^ self  "already hibernated or weird state"].
	compactBits _ ByteArray new: (bits size*4) + 7 + (bits size//1984*3).
	lastByte _ bits compress: bits toByteArray: compactBits.
	lastByte < (bits size*4) ifTrue:
		[bits _ nil.  "Let GC reclaim the old bits before the copy if necessary"
		bits _ compactBits copyFrom: 1 to: lastByte]! !

!Form methodsFor: 'fileIn/Out' stamp: 'di 3/15/1999 14:50'!
printOn: aStream
    aStream
        nextPutAll: self class name;
        nextPut: $(; print: width;
        nextPut: $x; print: height;
        nextPut: $x; print: depth;
        nextPut: $).
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 1/1/2004 19:04'!
readFrom: aBinaryStream
	"Reads the receiver from the given binary stream with the format:
		depth, extent, offset, bits."

	| offsetX offsetY |
	depth _ aBinaryStream next.
	(depth isPowerOfTwo and: [depth between: 1 and: 32])
		ifFalse: [self error: 'invalid depth; bad Form file?'].
	width _ aBinaryStream uint16.
	height _ aBinaryStream uint16.
	offsetX  _ aBinaryStream int16.
	offsetY _ aBinaryStream int16.
	offset _ offsetX@offsetY.
	bits _ Bitmap newFromStream: aBinaryStream.
	bits size = self bitsSize ifFalse: [self error: 'wrong bitmap size; bad Form file?'].
	^ self
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 1/1/2004 19:02'!
readFromOldFormat: aBinaryStream
	"Read a Form in the original ST-80 format."

	| w h offsetX offsetY newForm theBits pos |
	self error: 'this method must be updated to read into 32-bit word bitmaps'.
	w _ aBinaryStream uint16.
	h _ aBinaryStream uint16.
	offsetX  _ aBinaryStream int16.
	offsetY _ aBinaryStream int16.
	newForm _ (Form extent: w @ h) offset: offsetX @ offsetY.
	theBits _ newForm bits.
	pos _ 0.
	1 to: ((w + 15) // 16) do: [:j |
		1 to: h do: [:i | theBits at: (pos _ pos + 1) put: aBinaryStream uint16]].
	newForm bits: theBits.
	^ newForm
! !

!Form methodsFor: 'fileIn/Out'!
storeBitsOn:aStream base:anInteger
	bits do: [:word | 
		anInteger = 10
			ifTrue: [aStream space]
			ifFalse: [aStream crtab: 2].
		word printOn: aStream base: anInteger].
! !

!Form methodsFor: 'fileIn/Out'!
storeOn: aStream

	self storeOn: aStream base: 10! !

!Form methodsFor: 'fileIn/Out'!
storeOn: aStream base: anInteger 
	"Store the receiver out as an expression that can be evaluated to recreate a Form with the same contents as the original."

	self unhibernate.
	aStream nextPut: $(.
	aStream nextPutAll: self species name.
	aStream crtab: 1.
	aStream nextPutAll: 'extent: '.
	self extent printOn: aStream.
	aStream crtab: 1.
	aStream nextPutAll: 'depth: '.
	self depth printOn: aStream.
	aStream crtab: 1.
	aStream nextPutAll: 'fromArray: #('.
	self storeBitsOn:aStream base:anInteger.
	aStream nextPut: $).
	aStream crtab: 1.
	aStream nextPutAll: 'offset: '.
	self offset printOn: aStream.
	aStream nextPut: $).
! !

!Form methodsFor: 'fileIn/Out' stamp: 'ar 5/28/2000 00:52'!
unhibernate
	"If my bitmap has been compressed into a ByteArray,
	then expand it now, and return true."
	bits == nil ifTrue:[bits _ Bitmap new: self bitsSize. ^true].
	(bits isMemberOf: ByteArray)
		ifTrue: [bits _ Bitmap decompressFromByteArray: bits. ^ true].
	^ false! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 5/12/2006 12:40'!
writeBMPFileNamed: fName
	"Display writeBMPfileNamed: 'display.bmp'"

	| fileName bhSize biSize biClrUsed bfOffBits rowBytes biSizeImage f colorValues rgb data |
	self unhibernate.
	depth = 2 ifTrue: [(self asFormOfDepth: 4) writeBMPFileNamed: fName. ^ self].
	depth = 16 ifTrue: [(self asFormOfDepth: 32) writeBMPFileNamed: fName. ^ self].

	(#(1 4 8 32) includes: depth) ifFalse: [self error: 'BMP file depth must be 1, 4, 8, or 32'].
	((fileName _ fName) asUppercase endsWith: '.BMP')
		ifFalse: [fileName _ fName , '.BMP'].
	bhSize _ 14.		"# bytes in file header"
	biSize _ 40.		"info header size in bytes"
	biClrUsed _ depth = 32 ifTrue: [0] ifFalse: [1 << depth].	"number of color table entries"
	bfOffBits _ biSize + bhSize + (4*biClrUsed).
	rowBytes _ ((depth min: 24) * width + 31 // 32) * 4.
	biSizeImage _ height * rowBytes.

 	f _ StandardFileStream newScratchFileNamed: fileName.
	f ifNil: [^ self].
	f binary.

	"write the file header"
	f position: 0.
	f littleEndianUint16: 19778.			"bfType = BM"
	f littleEndianUint32: bfOffBits + biSizeImage.	"total file size in bytes"
	f littleEndianUint32: 0.				"bfReserved"
	f littleEndianUint32: bfOffBits.		"offset of bitmap data from start of hdr (and file)"

	"write the bitmap info header"
	f position: bhSize.
	f littleEndianUint32: biSize.			"info header size in bytes"
	f littleEndianUint32: width.			"biWidth"
	f littleEndianUint32: height.			"biHeight"
	f littleEndianUint16: 1.				"biPlanes"
	f littleEndianUint16: (depth min: 24).	"biBitCount"
	f littleEndianUint32: 0.				"biCompression"
	f littleEndianUint32: biSizeImage.		"size of image section in bytes"
	f littleEndianUint32: 2800.			"biXPelsPerMeter"
	f littleEndianUint32: 2800.			"biYPelsPerMeter"
	f littleEndianUint32: biClrUsed.
	f littleEndianUint32: 0.				"biClrImportant"

	biClrUsed > 0 ifTrue: [
		"write color map; this works for ColorForms, too"
		colorValues _ self colormapIfNeededForDepth: 32.
		1 to: biClrUsed do: [:i |
			rgb _ colorValues at: i.
			0 to: 24 by: 8 do: [:j | f nextPut: (rgb >> j bitAnd: 16rFF)]]].

	'Writing image data' displayProgressAt: Sensor cursorPoint
		from: 1 to: height during: [:bar |
			1 to: height do: [:i |
				bar value: i.
				data _ (self copy: (0@(height-i) extent: width@1)) bits.
				depth = 32
				ifTrue: [
					1 to: data size do: [:j | f littleEndianUint24: ((data at: j) bitAnd: 16rFFFFFF)].
					1 to: (data size*3)+3//4*4-(data size*3) do: [:j | f nextPut: 0 "pad to 32-bits"]]
				ifFalse: [
					1 to: data size do: [:j | f int32: (data at: j)]]]].
	f position = (bfOffBits + biSizeImage) ifFalse: [self halt].
	f close.
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 2/11/2004 10:38'!
writeGIFFileNamed: fName

	GIFReadWriter putForm: self onFileNamed: fName.
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 2/11/2004 10:48'!
writeJPGFileNamed: fName quality: quality

	| bytes f |
	depth < 16 ifTrue: [
		(self asFormOfDepth: 32) writeJPGFileNamed: fName quality: quality.
		^ self].

	bytes _ FastJPEG compress: self quality: quality asNumber.
	f _ (FileStream newFileNamed: fName) binary.
	f nextPutAll: bytes; close.
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 1/1/2004 18:57'!
writeOn: file
	"Write the receiver on the file in the format
		depth, extent, offset, bits."

	self unhibernate.
	file nextPut: depth.
	file uint16: width.
	file uint16: height.
	file int16: self offset x.
	file int16: self offset y.
	bits writeOn: file.
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 5/25/2003 11:41'!
writeOnFileNamed: fileName 
	"Saves the receiver on the file fileName in the format:
		fileCode=2, depth, extent, offset, bits."

	| file |
	file _ FileStream newFileNamed: fileName.
	file binary.
	file nextPut: 2.
	self writeOn: file.
	file close.

"
 | f |
[(f _ Form fromUser) boundingBox area>25] whileTrue:
	[f writeOnFileNamed: 'test.form'.
	(Form newFromFileNamed: 'test.form') display].
"! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 2/11/2004 10:43'!
writePNGFileNamed: fName

	PNGReadWriter putForm: self onFileNamed: fName.
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 2/22/2006 15:28'!
writeRGBFileNamed: fileName
	"Write this form to a file with the following simple, uncompressed RGB format:
		<width (2 bytes)><height (2 bytes)><r1><g1><b1><r2><g2><b2>..."

	| f c |
	f _ (FileStream newFileNamed: fileName) binary.
	f int16: width.
	f int16: height.
	1 to: height do: [:y |
		1 to: width do: [:x |
			c _ self colorAt: x@y.
			f nextPut: (c privateRed bitShift: -2).
			f nextPut: (c privateGreen bitShift: -2).
			f nextPut: (c privateBlue bitShift: -2)]].
	f close.
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 1/1/2004 18:58'!
writeUncompressedOn: file
	"Write the receiver on the file in the format depth, extent, offset, bits. The sender must write the header byte; see writeUncompressedOnFileNamed:."

	self unhibernate.
	file binary.
	file nextPut: depth.
	file uint16: width.
	file uint16: height.
	file int16: self offset x.
	file int16: self offset y.
	bits writeUncompressedOn: file.
! !

!Form methodsFor: 'fileIn/Out' stamp: 'jm 5/25/2003 11:40'!
writeUncompressedOnFileNamed: fileName 
	"Saves the receiver on the file fileName in the format:
		fileCode=2, depth, extent, offset, bits."

	| file |
	file _ FileStream newFileNamed: fileName.
	file binary.
	file nextPut: 2.
	self writeUncompressedOn: file.
	file close.

"
| f |
[(f _ Form fromUser) boundingBox area>25] whileTrue:
	[f writeUncompressedOnFileNamed: 'test.form'.
	(Form fromBinaryStream: (FileStream oldFileNamed: 'test.form')) display].
"! !


!Form methodsFor: 'other' stamp: 'jm 11/12/97 19:28'!
as8BitColorForm
	"Simple conversion of zero pixels to transparent.  Force it to 8 bits."

	| f map |
	f _ ColorForm extent: self extent depth: 8.
	self displayOn: f at: self offset negated.
	map _ Color indexedColors copy.
	map at: 1 put: Color transparent.
	f colors: map.
	f offset: self offset.
	^ f
! !

!Form methodsFor: 'other' stamp: 'jm 5/29/2003 17:58'!
asFormOfDepth: d

	| newForm |
	d = depth ifTrue:[^self].
	newForm _ Form extent: self extent depth: d.
	(BitBlt toForm: newForm)
		colorMap: (self colormapIfNeededForDepth: d);
		copy: (self boundingBox)
		from: 0@0 in: self
		fillColor: nil rule: Form over.
	^newForm! !

!Form methodsFor: 'other' stamp: 'jm 5/29/2003 18:06'!
asGrayScale
	"Assume the receiver is a grayscale image. Return a grayscale ColorForm computed by extracting the brightness levels of one color component. This technique allows a 32-bit Form to be converted to an 8-bit ColorForm to save space while retaining a full 255 levels of gray. (The usual colormapping technique quantizes to 8, 16, or 32 levels, which loses information.)"
	| f32 srcForm result map bb grays |
	depth = 32 ifFalse: [
		f32 _ Form extent: width@height depth: 32.
		self displayOn: f32.
		^ f32 asGrayScale].
	self unhibernate.
	srcForm _ Form extent: (width * 4)@height depth: 8.
	srcForm bits: bits.
	result _ ColorForm extent: width@height depth: 8.
	map _ Bitmap new: 256.
	2 to: 256 do: [:i | map at: i put: i - 1].
	map at: 1 put: 1.  "map zero pixel values to near-black"
	bb _ (BitBlt toForm: result)
		sourceForm: srcForm;
		combinationRule: Form over;
		colorMap: map.
	0 to: width - 1 do: [:dstX |
		bb  sourceRect: (((dstX * 4) + 2)@0 extent: 1@height);
			destOrigin: dstX@0;
			copyBits].

	"final BitBlt to zero-out pixels that were truely transparent in the original"
	map _ Bitmap new: 512.
	map at: 1 put: 16rFF.
	(BitBlt toForm: result)
		sourceForm: self;
		sourceRect: self boundingBox;
		destOrigin: 0@0;
		combinationRule: Form erase;
		colorMap: map;
		copyBits.
	
	grays _ (0 to: 255) collect: [:brightness | Color gray: brightness asFloat / 255.0].
	grays at: 1 put: Color transparent.
	result colors: grays.
	^ result
! !

!Form methodsFor: 'other'!
bitsSize
	| pixPerWord |
	depth == nil ifTrue: [depth _ 1].
	pixPerWord _ 32 // depth.
	^ width + pixPerWord - 1 // pixPerWord * height! !

!Form methodsFor: 'other' stamp: 'jm 12/2/2007 13:49'!
colorReduced
	"Return a color-reduced ColorForm version of the receiver, if possible, or the receiver itself if not."

	| tally tallyDepth colorCount newForm cm oldPixelValues newFormColors nextColorIndex c |
	depth = 1 ifTrue: [  "special case for 1-bit forms"
		(self isKindOf: ColorForm) ifTrue: [^ self].  "already reduced"
		newForm _ ColorForm extent: self extent depth: 1.
		newForm
			bits: bits copy;
			colors: {Color white. Color black}.
		^ newForm].

	tally _ self tallyPixelValues asArray.
	tallyDepth _ (tally size log: 2) asInteger.
	colorCount _ 0.
	tally do: [:n | n > 0 ifTrue: [colorCount _ colorCount + 1]].
	(tally at: 1) = 0 ifTrue: [colorCount _ colorCount + 1].  "include transparent"
	colorCount > 256 ifTrue: [^ self].  "cannot reduce"
	newForm _ self formForColorCount: colorCount.

	"build an array of just the colors used, and a color map to translate
	 old pixel values to their indices into this color array"
	cm _ Bitmap new: tally size.
	oldPixelValues _ self colormapIfNeededForDepth: 32.
	newFormColors _ Array new: colorCount.
	newFormColors at: 1 put: Color transparent.
	nextColorIndex _ 2.
	2 to: cm size do: [:i |
		(tally at: i) > 0 ifTrue: [
			oldPixelValues = nil
				ifTrue: [c _ Color colorFromPixelValue: i - 1 depth: tallyDepth]
				ifFalse: [c _ Color colorFromPixelValue: (oldPixelValues at: i) depth: 32].
			newFormColors at: nextColorIndex put: c.
			cm at: i put: nextColorIndex - 1.  "pixel values are zero-based indices"
			nextColorIndex _ nextColorIndex + 1]].

	"copy pixels into new ColorForm, mapping to new pixel values"
	newForm copyBits: self boundingBox
		from: self
		at: 0@0
		clippingBox: self boundingBox
		rule: Form over
		fillColor: nil
		map: cm.
	newForm colors: newFormColors.
	newForm offset: offset.
	^ newForm
! !

!Form methodsFor: 'other' stamp: 'jm 10/14/2003 20:16'!
colorReduced8Bit
	"Return an 8-bit ColorForm version of the receiver."

	| tally tallyDepth colorCount newForm cm oldPixelValues newFormColors nextColorIndex c |
	tally _ self tallyPixelValues asArray.
	tallyDepth _ (tally size log: 2) asInteger.
	colorCount _ 0.
	tally do: [:n | n > 0 ifTrue: [colorCount _ colorCount + 1]].
	(tally at: 1) = 0 ifTrue: [colorCount _ colorCount + 1].  "include transparent even if it's not used"
	colorCount > 256 ifTrue: [^ self].  "cannot reduce"
	newForm _ ColorForm extent: self extent depth: 8.

	"build an array of just the colors used, and a color map to translate
	 old pixel values to their indices into this color array"
	cm _ Bitmap new: tally size.
	oldPixelValues _ self colormapIfNeededForDepth: 32.
	newFormColors _ Array new: colorCount.
	newFormColors at: 1 put: Color transparent.
	nextColorIndex _ 2.
	2 to: cm size do: [:i |
		(tally at: i) > 0 ifTrue: [
			oldPixelValues = nil
				ifTrue: [c _ Color colorFromPixelValue: i - 1 depth: tallyDepth]
				ifFalse: [c _ Color colorFromPixelValue: (oldPixelValues at: i) depth: 32].
			newFormColors at: nextColorIndex put: c.
			cm at: i put: nextColorIndex - 1.  "pixel values are zero-based indices"
			nextColorIndex _ nextColorIndex + 1]].

	"copy pixels into new ColorForm, mapping to new pixel values"
	newForm copyBits: self boundingBox
		from: self
		at: 0@0
		clippingBox: self boundingBox
		rule: Form over
		fillColor: nil
		map: cm.
	newForm colors: newFormColors.
	newForm offset: offset.
	^ newForm
! !

!Form methodsFor: 'other' stamp: 'jm 8/1/2008 20:28'!
colorsUsed
	"Return a list of the Colors this form uses."
	"Note: For 32-bit forms, colors are truncated to 15-bits (i.e. dropping 3-bits per color component). This can lead to undercounting, especially when applied to gradients or photographic images."

	| tallies tallyDepth usedColors |
	tallies _ self tallyPixelValues.
	tallyDepth _ (tallies size log: 2) asInteger.
	usedColors _ OrderedCollection new.
	tallies doWithIndex: [:count :i |
		count > 0 ifTrue: [
			usedColors add: (Color colorFromPixelValue: i - 1 depth: tallyDepth)]].
	^ usedColors asArray
! !

!Form methodsFor: 'other' stamp: 'jm 8/4/2008 07:30'!
couldBeColorReduced
	"Answer true if this Form has few enough colors to be converted to a ColorForm, but answer false if quantizing it's colors in the process of creating the ColorForm would result in fewer colors than the original. (Note: Converting to a ColorForm may still result in small color shifts due to color quantization, buf if all the colors remain unique these shifts should not be too noticable.)"

	| colors pixel |
	self depth < 32 ifTrue: [^ false].
	self unhibernate.
	colors _ Set new: 1000.
	1 to: bits size do: [:i |
		pixel _ (bits at: i) bitAnd: 16rFFFFFF.
		pixel = 0 ifFalse: [
			colors add: pixel.
			colors size > 255 ifTrue: [^ false]]].

	^ colors size <= self colorsUsed size
! !

!Form methodsFor: 'other' stamp: 'ar 12/12/2003 18:24'!
fixAlpha
	"Fix the alpha channel if the receiver is 32-bit, otherwise do nothing. All non-zero pixel values get an alpha of 255 (opaque). Needs a VM that support combination rule 40."

	| bb |
	self depth = 32 ifFalse:[^ self].
	bb _ BitBlt toForm: self.
	bb combinationRule: 40  "fixAlpha:with:".
	bb copyBits.
! !

!Form methodsFor: 'other' stamp: 'jm 9/27/97 21:02'!
formForColorCount: colorCount
	"Return a ColorForm of sufficient depth to represent the given number of colors. The maximum number of colors is 256."

	colorCount > 256 ifTrue: [^ self error: 'too many colors'].

	colorCount > 16 ifTrue: [^ ColorForm extent: self extent depth: 8].
	colorCount > 4 ifTrue: [^ ColorForm extent: self extent depth: 4].
	colorCount > 2 ifTrue: [^ ColorForm extent: self extent depth: 2].
	^ ColorForm extent: self extent depth: 1
! !

!Form methodsFor: 'other' stamp: 'jm 5/29/2003 17:59'!
mapColor: oldColor to: newColor
	"Make all pixels of the given color in this Form to the given new color."
	"Warnings: This method modifies the receiver. It may lose some color accuracy on 32-bit Forms, since the transformation uses a color map with only 15-bit resolution."

	| map |
	map _ (Color cachedColormapFrom: depth to: depth) copy.
	map at: (oldColor indexInMap: map) put: (newColor pixelWordForDepth: depth).
	(BitBlt toForm: self)
		sourceForm: self;
		sourceOrigin: 0@0;
		combinationRule: Form over;
		destX: 0 destY: 0 width: width height: height;
		colorMap: map;
		copyBits.
! !

!Form methodsFor: 'other' stamp: 'jm 5/29/2003 17:59'!
mapColors: oldColorBitsCollection to: newColorBits
	"Make all pixels of the given color in this Form to the given new color."
	"Warnings: This method modifies the receiver. It may lose some color accuracy on 32-bit Forms, since the transformation uses a color map with only 15-bit resolution."

	| map |
	depth < 16
		ifTrue: [map _ (Color cachedColormapFrom: depth to: depth) copy]
		ifFalse: [
			"use maximum resolution color map"
			"source is 16-bit or 32-bit RGB; use colormap with 5 bits per color component"
			map _ Color computeRGBColormapFor: depth bitsPerColor: 5].
	oldColorBitsCollection do:[ :oldColor | map at: oldColor put: newColorBits].

	(BitBlt toForm: self)
		sourceForm: self;
		sourceOrigin: 0@0;
		combinationRule: Form over;
		destX: 0 destY: 0 width: width height: height;
		colorMap: map;
		copyBits.
! !

!Form methodsFor: 'other' stamp: 'jm 12/1/97 19:58'!
newColorMap 
	"Return an uninitialized color map array appropriate to this Form's depth."

	^ Bitmap new: (1 bitShift: (depth min: 15))
! !

!Form methodsFor: 'other' stamp: 'jm 1/6/98 10:37'!
primPrintHScale: hScale vScale: vScale landscape: aBoolean
	"On platforms that support it, this primitive prints the receiver, assumed to be a Form, to the default printer."
	"(Form extent: 10@10) primPrintHScale: 1.0 vScale: 1.0 landscape: true"

	<primitive: 232>
	self primitiveFailed
! !

!Form methodsFor: 'other' stamp: 'jm 8/6/2008 10:33'!
removeNoisyAlpha
	"Some programs (e.g. TurtleArt) encode data in the low bit of each color channel. This 'noise' in the alpha channel can interfere with Squeak's interpretation of transparency. This method forces pixels with small alpha values to be treated as transparent."

	| alpha |
	depth = 32 ifFalse: [^ self].
	self unhibernate.
	1 to: bits size do: [:i |
		alpha _ ((bits at: i) bitShift: -24) bitAnd: 255.
		alpha < 2 ifTrue: [bits at: i put: 0]].
! !


!Form methodsFor: 'transitions' stamp: 'jm 5/21/1998 23:46'!
fadeImage: otherImage at: topLeft
	indexAndMaskDo: indexAndMaskBlock
	"This fade uses halftones as a blending hack.
	Zeros in the halftone produce the original image (self), and 
	ones in the halftone produce the 'otherImage'.
	IndexAndMaskBlock gets evaluated prior to each cycle,
	and the resulting boolean determines whether to continue cycling."
	| index imageRect maskForm resultForm |
	imageRect _ otherImage boundingBox.
	resultForm _ self copy: (topLeft extent: imageRect extent).
	maskForm _ Form extent: 32@32.
	index _ 0.
	[indexAndMaskBlock value: (index _ index+1) value: maskForm]
	whileTrue:
		[maskForm reverse.
		resultForm copyBits: imageRect from: resultForm at: 0@0
			clippingBox: imageRect rule: Form over fillColor: maskForm.
		maskForm reverse.
		resultForm copyBits: imageRect from: otherImage at: 0@0
			clippingBox: imageRect rule: Form under fillColor: maskForm.
		self copyBits: imageRect from: resultForm at: topLeft
				clippingBox: self boundingBox rule: Form over fillColor: nil.
		Display forceDisplayUpdate]! !

!Form methodsFor: 'transitions'!
fadeImageCoarse: otherImage at: topLeft
	"Display fadeImageCoarse: (Form fromDisplay: (40@40 extent: 300@300)) reverse at: 40@40"
	| pix j |
	^ self fadeImage: otherImage at: topLeft indexAndMaskDo:
		[:i :mask |
		i=1 ifTrue: [pix _ (1 bitShift: depth) - 1.
					1 to: 8//depth-1 do: [:q | pix _ pix bitOr: (pix bitShift: depth*4)]].
		i <= 16 ifTrue:
		[j _ i-1//4+1.
		(0 to: 28 by: 4) do: [:k |
			mask bits at: j+k
				put: ((mask bits at: j+k) bitOr: (pix bitShift: i-1\\4*depth))].
		"mask display." true]
		ifFalse: [false]]! !

!Form methodsFor: 'transitions'!
fadeImageFine: otherImage at: topLeft
	"Display fadeImageFine: (Form fromDisplay: (40@40 extent: 300@300)) reverse at: 40@40"
	| pix j ii |
	^ self fadeImage: otherImage at: topLeft indexAndMaskDo:
		[:i :mask |
		i=1 ifTrue: [pix _ (1 bitShift: depth) - 1.
					1 to: 8//depth-1 do:
						[:q | pix _ pix bitOr: (pix bitShift: depth*4)]].
		i <= 16 ifTrue:
		[ii _ #(0 10 2 8 7 13 5 15 1 11 3 9 6 12 4 14) at: i.
		j _ ii//4+1.
		(0 to: 28 by: 4) do:
			[:k | mask bits at: j+k put:
				((mask bits at: j+k) bitOr: (pix bitShift: ii\\4*depth))].
		true]
		ifFalse: [false]]! !

!Form methodsFor: 'transitions'!
fadeImageHor: otherImage at: topLeft
	"Display fadeImageHor: (Form fromDisplay: (10@10 extent: 300@300)) reverse at: 10@10"
	^ self fadeImage: otherImage at: topLeft indexAndMaskDo:
		[:i :mask |
		mask fill: (0@(mask height//2-i) extent: mask width@(i*2)) fillColor: Color black.
		(i*2) <= mask width]! !

!Form methodsFor: 'transitions'!
fadeImageHorFine: otherImage at: topLeft
	"Display fadeImageHorFine: (Form fromDisplay: (10@10 extent: 300@300)) reverse at: 10@10"
	^ self fadeImage: otherImage at: topLeft indexAndMaskDo:
		[:i :mask |
		mask fill: (0@(i-1) extent: mask width@1) fillColor: Color black.
		mask fill: (0@(i-1+16) extent: mask width@1) fillColor: Color black.
		(i*2) <= mask width]! !

!Form methodsFor: 'transitions'!
fadeImageSquares: otherImage at: topLeft 
	"Display fadeImageSquares: (Form fromDisplay: (40@40 extent: 300@300)) reverse at: 40@40"
	^ self fadeImage: otherImage at: topLeft indexAndMaskDo:
		[:i :mask |
		mask fill: ((16-i) asPoint extent: (i*2) asPoint) fillColor: Color black.
		i <= 16]! !

!Form methodsFor: 'transitions'!
fadeImageVert: otherImage at: topLeft
	"Display fadeImageVert: (Form fromDisplay: (10@10 extent: 300@300)) reverse at: 10@10"
	^ self fadeImage: otherImage at: topLeft indexAndMaskDo:
		[:i :mask |
		mask fill: ((mask width//2//depth-i*depth)@0 extent: i*2*depth@mask height) fillColor: Color black.
		i <= (mask width//depth)]! !

!Form methodsFor: 'transitions' stamp: 'jm 10/14/2002 19:02'!
pageImage: otherImage at: topLeft corner: corner
	"Produce a page-turning illusion that gradually reveals otherImage
	located at topLeft in this form.  Corner specifies which corner, as
		1=topLeft, 2=topRight, 3=bottomRight, 4=bottomLeft."
	| bb maskForm resultForm delta maskLoc maskRect stepSize cornerSel smallRect p |
	stepSize _ 10.
	bb _ otherImage boundingBox.
	resultForm _ self copy: (topLeft extent: bb extent).
	maskForm _ Form extent: ((otherImage width min: otherImage height) + stepSize) asPoint.

	"maskLoc _ starting loc rel to topLeft"
	otherImage width > otherImage height
		ifTrue: ["wide image; motion is horizontal."
				(corner between: 2 and: 3) not ifTrue:
					["motion is to the right"
					delta _ 1@0.
					maskLoc _ bb topLeft - (corner = 1
						ifTrue: [maskForm width@0]
						ifFalse: [maskForm width@stepSize])]
					ifFalse:
					["motion is to the left"
					delta _ -1@0.
					maskLoc _ bb topRight - (corner = 2
						ifTrue: [0@0]
						ifFalse: [0@stepSize])]]
		ifFalse: ["tall image; motion is vertical."
				corner <= 2 ifTrue:
					["motion is downward"
					delta _ 0@1.
					maskLoc _ bb topLeft - (corner = 1
						ifTrue: [0@maskForm height]
						ifFalse: [stepSize@maskForm height])]
					ifFalse:
					["motion is upward"
					delta _ 0@-1.
					maskLoc _ bb bottomLeft - (corner = 3
						ifTrue: [stepSize@0]
						ifFalse: [0@0])]].

	"Build a solid triangle in the mask form"
	p _ Pen newOnForm: maskForm.
	corner even  "Draw 45-degree line"
		ifTrue: [p place: 0@0; turn: 135; go: maskForm width*3//2]
		ifFalse: [p place: 0@(maskForm height-1); turn: 45; go: maskForm width*3//2].
	maskForm smear: delta negated distance: maskForm width.
	"Copy the mask to full resolution for speed.  Make it be the reversed
	so that it can be used for ORing in the page-corner color"
	maskForm _ (Form extent: maskForm extent depth: otherImage depth)
		copyBits: maskForm boundingBox from: maskForm at: 0@0
		colorMap: (Bitmap with: 16rFFFFFFFF with: 0).

	"Now move the triangle maskForm across the resultForm selecting the
	triangular part of otherImage to display, and across the resultForm,
	selecting the part of the original image to erase."
	cornerSel _ #(topLeft topRight bottomRight bottomLeft) at: corner.
	1 to: (otherImage width + otherImage height // stepSize)+1 do:
		[:i |		"Determine the affected square"
		maskRect _ (maskLoc extent: maskForm extent) intersect: bb.
		((maskLoc x*delta x) + (maskLoc y*delta y)) < 0 ifTrue:
			[smallRect _ 0@0 extent: (maskRect width min: maskRect height) asPoint.
			maskRect _ smallRect align: (smallRect perform: cornerSel)
								with: (maskRect perform: cornerSel)].

		"AND otherForm with triangle mask, and OR into result"
		resultForm copyBits: bb from: otherImage at: 0@0
				clippingBox: maskRect rule: Form over fillColor: nil.
		resultForm copyBits: maskForm boundingBox from: maskForm at: maskLoc
				clippingBox: maskRect rule: Form erase fillColor: nil.
		resultForm copyBits: maskForm boundingBox from: maskForm at: maskLoc
				clippingBox: maskRect rule: Form under fillColor: Color lightBrown.

		"Now update Display in a single BLT."
		self copyBits: maskRect from: resultForm at: topLeft + maskRect topLeft
				clippingBox: self boundingBox rule: Form over fillColor: nil.
		Display forceDisplayUpdate.
		maskLoc _ maskLoc + (delta*stepSize)]
"
1 to: 4 do: [:corner | Display pageImage:
				(Form fromDisplay: (10@10 extent: 200@300)) reverse
			at: 10@10 corner: corner]
"
! !

!Form methodsFor: 'transitions' stamp: 'jm 5/29/2003 17:59'!
pageWarp: otherImage at: topLeft forward: forward
	"Produce a page-turning illusion that gradually reveals otherImage
	located at topLeft in this form.
	forward == true means turn pages toward you, else away. [ignored for now]"

	| pageRect oldPage nSteps buffer p leafRect sourceQuad warp oldBottom d |
	pageRect _ otherImage boundingBox.
	oldPage _ self copy: (pageRect translateBy: topLeft).
	(forward ifTrue: [oldPage] ifFalse: [otherImage])
		border: pageRect
		widthRectangle: (Rectangle
				left: 0
				right: 2
				top: 1
				bottom: 1)
		rule: Form over
		fillColor: Color black.
	oldBottom _ self copy: ((pageRect bottomLeft + topLeft) extent: (pageRect width@(pageRect height//4))).
	nSteps _ 8.
	buffer _ Form extent: otherImage extent + (0@(pageRect height//4)) depth: self depth.
	d _ pageRect topLeft + (0@(pageRect height//4)) - pageRect topRight.
	1 to: nSteps-1 do:
		[:i | forward
			ifTrue: [buffer copy: pageRect from: otherImage to: 0@0 rule: Form over.
					p _ pageRect topRight + (d * i // nSteps)]
			ifFalse: [buffer copy: pageRect from: oldPage to: 0@0 rule: Form over.
					p _ pageRect topRight + (d * (nSteps-i) // nSteps)].
		buffer copy: oldBottom boundingBox from: oldBottom to: pageRect bottomLeft rule: Form over.
		leafRect _ pageRect topLeft corner: p x @ (pageRect bottom + p y).
		sourceQuad _ Array with: pageRect topLeft
			with: pageRect bottomLeft + (0@p y)
			with: pageRect bottomRight
			with: pageRect topRight - (0@p y).
		warp _ (WarpBlt toForm: buffer)
				clipRect: leafRect;
				sourceForm: (forward ifTrue: [oldPage] ifFalse: [otherImage]);
				combinationRule: Form paint.
		warp copyQuad: sourceQuad toRect: leafRect.
		self copy: buffer boundingBox from: buffer to: topLeft rule: Form over.
		Display forceDisplayUpdate].

	buffer copy: pageRect from: otherImage to: 0@0 rule: Form over.
	buffer copy: oldBottom boundingBox from: oldBottom to: pageRect bottomLeft rule: Form over.
	self copy: buffer boundingBox from: buffer to: topLeft rule: Form over.
	Display forceDisplayUpdate.
"
1 to: 4 do: [:corner | Display pageWarp:
				(Form fromDisplay: (10@10 extent: 200@300)) reverse
			at: 10@10 forward: false]
"
! !

!Form methodsFor: 'transitions' stamp: 'jm 5/21/1998 23:46'!
slideImage: otherImage at: topLeft delta: delta
	"Display slideImage: (Form fromDisplay: (40@40 extent: 300@300)) reverse
		at: 40@40 delta: 3@-4"
	| bb nSteps clipRect |
	bb _ otherImage boundingBox.
	clipRect _ topLeft extent: otherImage extent.
	nSteps _ 1.
	delta x = 0 ifFalse: [nSteps _ nSteps max: (bb width//delta x abs) + 1].
	delta y = 0 ifFalse: [nSteps _ nSteps max: (bb height//delta y abs) + 1].
	1 to: nSteps do:
			[:i | self copyBits: bb from: otherImage
				at: delta*(i-nSteps) + topLeft
				clippingBox: clipRect rule: Form paint fillColor: nil.
			Display forceDisplayUpdate]! !

!Form methodsFor: 'transitions' stamp: 'jm 6/18/1998 12:57'!
wipeImage: otherImage at: topLeft clippingBox: clipBox rectForIndex: rectForIndexBlock

	| i clipRect t rectOrList waitTime |
	i _ 0.
	clipRect _ topLeft extent: otherImage extent.
	clipBox ifNotNil: [clipRect _ clipRect intersect: clipBox].
	[rectOrList _ rectForIndexBlock value: (i _ i + 1).
	 rectOrList == nil]
		whileFalse: [
			t _ Time millisecondClockValue.
			rectOrList asOrderedCollection do: [:r |
				self copyBits: r from: otherImage at: topLeft + r topLeft
					clippingBox: clipRect rule: Form over fillColor: nil].
			Display forceDisplayUpdate.
			waitTime _ 3 - (Time millisecondClockValue - t).
			waitTime > 0 ifTrue:
				["(Delay forMilliseconds: waitTime) wait"]].
! !

!Form methodsFor: 'transitions' stamp: 'jm 10/16/97 15:21'!
wipeImage: otherImage at: topLeft delta: delta
	"Display wipeImage: (Form fromDisplay: (40@40 extent: 300@300)) reverse
		at: 40@40 delta: 0@-2"

	self wipeImage: otherImage at: topLeft delta: delta clippingBox: nil.
! !

!Form methodsFor: 'transitions' stamp: 'jm 10/16/97 15:17'!
wipeImage: otherImage at: topLeft delta: delta clippingBox: clipBox

	| wipeRect bb nSteps |
	bb _ otherImage boundingBox.
	wipeRect _ delta x = 0
		ifTrue:
		[delta y = 0 ifTrue: [nSteps _ 1. bb "allow 0@0"] ifFalse: [
		nSteps _ bb height//delta y abs + 1.  "Vertical movement"
		delta y > 0
			ifTrue: [bb topLeft extent: bb width@delta y]
			ifFalse: [bb bottomLeft+delta extent: bb width@delta y negated]]]
		ifFalse:
		[nSteps _ bb width//delta x abs + 1.  "Horizontal movement"
		delta x > 0
			ifTrue: [bb topLeft extent: delta x@bb height]
			ifFalse: [bb topRight+delta extent: delta x negated@bb height]].
	^ self wipeImage: otherImage at: topLeft clippingBox: clipBox rectForIndex:
		[:i | i <= nSteps
			ifTrue: [wipeRect translateBy: (delta* (i-1))]
			ifFalse: [nil]]! !

!Form methodsFor: 'transitions' stamp: 'di 1/28/1999 09:20'!
zoomIn: goingIn orOutTo: otherImage at: topLeft vanishingPoint: vp 
	"Display zoomInTo: (Form fromDisplay: (40@40 extent: 300@300)) reverse at: 40@40.
	Display zoomOutTo: (Form fromDisplay: (40@40 extent: 300@300)) reverse at: 40@40."
	| nSteps j bigR lilR minTime startTime lead |
	nSteps _ 16.
	minTime _ 500.  "milliseconds"
	startTime _ Time millisecondClockValue.
	^ self wipeImage: otherImage at: topLeft clippingBox: nil rectForIndex:
		[:i | "i runs from 1 to nsteps"
		i > nSteps
			ifTrue: [nil "indicates all done"]
			ifFalse:
			["If we are going too fast, delay for a bit"
			lead _ startTime + (i-1*minTime//nSteps) - Time millisecondClockValue.
			lead > 10 ifTrue: [(Delay forMilliseconds: lead) wait].

			"Return an array with the difference rectangles for this step."
			j _ goingIn ifTrue: [i] ifFalse: [nSteps+1-i].
			bigR _ vp - (vp*(j)//nSteps) corner:
				vp + (otherImage extent-vp*(j)//nSteps).
			lilR _ vp - (vp*(j-1)//nSteps) corner:
				vp + (otherImage extent-vp*(j-1)//nSteps).
			bigR areasOutside: lilR]]! !

!Form methodsFor: 'transitions' stamp: 'di 3/2/98 09:14'!
zoomInTo: otherImage at: topLeft
	"Display zoomInTo: (Form fromDisplay: (40@40 extent: 300@300)) reverse at: 40@40"
	^ self zoomIn: true orOutTo: otherImage at: topLeft
		vanishingPoint: otherImage extent//2+topLeft! !

!Form methodsFor: 'transitions' stamp: 'di 3/2/98 09:15'!
zoomOutTo: otherImage at: topLeft
	"Display zoomOutTo: (Form fromDisplay: (40@40 extent: 300@300)) reverse at: 40@40"
	^ self zoomIn: false orOutTo: otherImage at: topLeft
		vanishingPoint: otherImage extent//2+topLeft! !


!Form methodsFor: 'XO cursor' stamp: 'jm 3/24/2008 16:12'!
primBeXOCursor
	"Primitive. Tell the interpreter to use the receiver as the current cursor. The XO can accept a 32x32x32 Form as a cursor, The cursor can use the full RGB color space and it supports alpha, so it's pixels can be translucent as well as fully transparent or opaque. The offset instance variable gives the cursor's hot point; it must not be nil and it's x and y must be integers in the range [-32..0]."

	<primitive: 101>
	(self bits isKindOf: Bitmap) ifFalse: [self unhibernate. ^ self primBeXOCursor].
	self depth = 32 ifFalse: [^ (self asFormOfDepth: 32) primBeXOCursor].
	offset ifNil: [^ (self copy offset: -16 @ -16) primBeXOCursor].

	self primitiveFailed.
! !


!Form methodsFor: 'private' stamp: 'tk 3/13/2000 15:21'!
hackBits: bitThing
	"This method provides an initialization so that BitBlt may be used, eg, to 
	copy ByteArrays and other non-pointer objects efficiently.
	The resulting form looks 4 wide, 8 deep, and bitThing-size-in-words high."
	width _ 4.
	depth _ 8.
	bitThing class isBits ifFalse: [self error: 'bitThing must be a non-pointer object'].
	bitThing class isBytes
		ifTrue: [height _ bitThing basicSize // 4]
		ifFalse: [height _ bitThing basicSize].
	bits _ bitThing! !

!Form methodsFor: 'private'!
initFromArray: array
	"Fill the bitmap from array.  If the array is shorter,
	then cycle around in its contents until the bitmap is filled."
	| ax aSize array32 i j word16 |
	ax _ 0.
	aSize _ array size.
	aSize > bits size ifTrue:
		["backward compatibility with old 16-bit bitmaps and their forms"
		array32 _ Array new: height * (width + 31 // 32).
		i _ j _ 0.
		1 to: height do:
			[:y | 1 to: width+15//16 do:
				[:x16 | word16 _ array at: (i _ i + 1).
				x16 odd ifTrue: [array32 at: (j _ j+1) put: (word16 bitShift: 16)]
						ifFalse: [array32 at: j put: ((array32 at: j) bitOr: word16)]]].
		^ self initFromArray: array32].
	1 to: bits size do:
		[:index |
		(ax _ ax + 1) > aSize ifTrue: [ax _ 1].
		bits at: index put: (array at: ax)]! !

!Form methodsFor: 'private' stamp: 'jm 9/24/2003 12:15'!
privateOffset

	^ offset
! !

!Form methodsFor: 'private' stamp: 'di 6/9/97 16:10'!
setExtent: extent depth: bitsPerPixel
	"Create a virtual bit map with the given extent and bitsPerPixel."

	width _ extent x asInteger.
	width < 0 ifTrue: [width _ 0].
	height _ extent y asInteger.
	height < 0 ifTrue: [height _ 0].
	depth _ bitsPerPixel.
	bits _ Bitmap new: self bitsSize! !

!Form methodsFor: 'private' stamp: 'ar 5/28/2000 15:49'!
setExtent: extent depth: bitsPerPixel bits: bitmap
	"Create a virtual bit map with the given extent and bitsPerPixel."

	width _ extent x asInteger.
	width < 0 ifTrue: [width _ 0].
	height _ extent y asInteger.
	height < 0 ifTrue: [height _ 0].
	depth _ bitsPerPixel.
	(bits isNil or:[self bitsSize = bitmap size]) ifFalse:[^self error:'Bad dimensions'].
	bits _ bitmap! !


!Form methodsFor: 'BYOB' stamp: 'jens 1/20/2010 23:55'!
outlineEmbeddedAdjustedColor: color

	| outline outTop outBottom w |

	w _ 1.
	outline _ self
		outlineWidth: w
		color: color
		depth: 8.

	outTop _ outline copy: (0@0 extent: (outline extent x @ (outline extent y / 3))).
	outBottom _ outline copy: (0@(outline extent y * 2 / 3 - 1) corner: outline extent + 1).

	outTop replaceColor: color withColor: color darker slightlyDarker.
	outBottom replaceColor: color withColor: color twiceLighter lighter slightlyLighter.

	(WarpBlt toForm: outline)
		sourceForm: outTop;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outTop boundingBox corners toRect: outTop boundingBox.

	(WarpBlt toForm: outline)
		sourceForm: outBottom;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outBottom boundingBox corners toRect: (0@(outline extent y * 2 / 3)  extent: outBottom extent).

	^ outline


! !

!Form methodsFor: 'BYOB' stamp: 'jens 1/20/2010 23:43'!
outlineEmbeddedColor: color width: w

	| outline outTop outBottom |

	outline _ self
		outlineWidth: w
		color: color
		depth: 8.

	outTop _ outline copy: (0@0 extent: (outline extent x @ (outline extent y / 3))).
	outBottom _ outline copy: (0@(outline extent y * 2 / 3 "- 1") corner: outline extent "+ 1").

	outTop replaceColor: color withColor: color darker slightlyDarker.
	outBottom replaceColor: color withColor: color twiceLighter lighter slightlyLighter.

	(WarpBlt toForm: outline)
		sourceForm: outTop;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outTop boundingBox corners toRect: outTop boundingBox.

	(WarpBlt toForm: outline)
		sourceForm: outBottom;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outBottom boundingBox corners toRect: (0@(outline extent y * 2 / 3)  extent: outBottom extent).

	^ outline


! !

!Form methodsFor: 'BYOB' stamp: 'jens 3/30/2010 23:25'!
outlineHalfEmbeddedAdjustedColor: color

	| outline outTop outBottom w |

	w _ 1.
	outline _ self
		outlineWidth: w
		color: color
		depth: 8.

	outTop _ outline copy: (0@0 extent: (outline extent x @ (outline extent y / 2))).
	outBottom _ outline copy: (0@(outline extent y * 1 / 2 - 1) corner: outline extent + 1).

	outTop replaceColor: color withColor: color darker slightlyDarker.
	outBottom replaceColor: color withColor: color twiceLighter lighter slightlyLighter.

	(WarpBlt toForm: outline)
		sourceForm: outTop;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outTop boundingBox corners toRect: outTop boundingBox.

	(WarpBlt toForm: outline)
		sourceForm: outBottom;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outBottom boundingBox corners toRect: (0@(outline extent y * 1 / 2)  extent: outBottom extent).

	^ outline


! !

!Form methodsFor: 'BYOB' stamp: 'jens 1/20/2010 23:27'!
outlineRaisedColor: color width: w

	| outline outTop outBottom |

	outline _ self
		outlineWidth: w
		color: color
		depth: 8.

	outTop _ outline copy: (0@0 extent: (outline extent x @ (outline extent y / 3))).
	outBottom _ outline copy: (0@(outline extent y * 2 / 3 - 1) corner: outline extent + 1).

	outTop replaceColor: color withColor: color twiceLighter lighter slightlyLighter.
	outBottom replaceColor: color withColor: color darker slightlyDarker.

	(WarpBlt toForm: outline)
		sourceForm: outTop;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outTop boundingBox corners toRect: outTop boundingBox.

	(WarpBlt toForm: outline)
		sourceForm: outBottom;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outBottom boundingBox corners toRect: (0@(outline extent y * 2 / 3)  extent: outBottom extent).

	^ outline


! !

!Form methodsFor: 'BYOB' stamp: 'jens 1/20/2010 23:23'!
withEmbeddedOutlineColor: color width: w

	| outline |
	outline _ self outlineEmbeddedColor: color width: w.
	(WarpBlt toForm: outline)
		sourceForm: self;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outline boundingBox innerCorners toRect: (outline boundingBox translateBy: w).
	^outline! !

!Form methodsFor: 'BYOB' stamp: 'jens 4/6/2010 18:58'!
withHalfEmbeddedOutlineColor: color 

	| outline |
	outline _ self outlineHalfEmbeddedAdjustedColor: color.
	(WarpBlt toForm: outline)
		sourceForm: self;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outline boundingBox innerCorners toRect: (outline boundingBox translateBy: 1).
	^outline! !

!Form methodsFor: 'BYOB' stamp: 'jens 1/19/2010 02:37'!
withOutlineColor: aColor width: anInteger

	| outline |
	outline _ self
		outlineWidth: anInteger
		color: aColor
		depth: 8.
	(WarpBlt toForm: outline)
		sourceForm: self;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outline boundingBox innerCorners toRect: (outline boundingBox translateBy: anInteger).
	^outline
! !

!Form methodsFor: 'BYOB' stamp: 'jens 1/20/2010 23:22'!
withRaisedOutlineColor: color width: w

	| outline |
	outline _ self outlineRaisedColor: color width: w.
	(WarpBlt toForm: outline)
		sourceForm: self;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outline boundingBox innerCorners toRect: (outline boundingBox translateBy: w).
	^outline! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Form class
	instanceVariableNames: ''!

!Form class methodsFor: 'instance creation' stamp: 'jm 9/19/2006 08:36'!
dotOfSize: diameter
	"Create a form which contains a round black dot."

	| radius form bb rect centerX centerY centerYBias centerXBias radiusSquared xOverY maxy dx |
	radius _ diameter // 2.
	form _ (self extent: diameter@diameter) offset: (radius@radius) negated.	
	bb _ (BitBlt toForm: form)
		sourceOrigin: 0@0;
		combinationRule: Form over;
		fillColor: Color black.

	"special case: sizes 1-6"
	diameter <= 6 ifTrue: [
		bb destRect: form boundingBox; copyBits.  "fill w/ black"
		diameter > 3 ifTrue: [  "clear corners"
			bb fillColor: Color white.
			form boundingBox innerCorners do: [:p |
				bb destRect: (p extent: 1); copyBits]].
		^ form].

	"sizes 7 and 8"
	diameter <= 8 ifTrue: [
		rect _ form boundingBox insetBy: 1.
		bb destRect: rect; copyBits.  "fill w/ black"
		bb destRect: (2 @ 0 extent: (diameter - 4) @ diameter); copyBits.
		bb destRect: (0 @ 2 extent: diameter @ (diameter - 4)); copyBits.		
		^ form].

	rect _ form boundingBox.
	centerX _ rect center x.
	centerY _ rect center y.
	centerYBias _ rect height odd ifTrue: [0] ifFalse: [1].
	centerXBias _ rect width odd ifTrue: [0] ifFalse: [1].
	radiusSquared _ (rect height asFloat / 2.0) squared - 0.01.
	xOverY _ rect width asFloat / rect height asFloat.
	maxy _ rect height - 1 // 2.

	"First do the inner fill, and collect x values"
	0 to: maxy do:
		[:dy |
		dx _ ((radiusSquared - (dy * dy) asFloat) sqrt * xOverY) truncated.
		bb	destX: centerX - centerXBias - dx
			destY: centerY - centerYBias - dy
			width: dx + dx + centerXBias + 1
			height: 1;
			copyBits.
		bb	destY: centerY + dy;
			copyBits].
	^ form
"
Time millisecondsToRun:
	[1 to: 20 do: [:i | (Form dotOfSize: i) displayAt: (i*20)@(i*20)]]
"! !

!Form class methodsFor: 'instance creation' stamp: 'jm 3/27/98 16:27'!
extent: extentPoint
	"Answer an instance of me with a blank bitmap of depth 1."

	^ self extent: extentPoint depth: 1
! !

!Form class methodsFor: 'instance creation' stamp: 'jm 3/27/98 16:36'!
extent: extentPoint depth: bitsPerPixel
	"Answer an instance of me with blank bitmap of the given dimensions and depth."

	^ self basicNew setExtent: extentPoint depth: bitsPerPixel
! !

!Form class methodsFor: 'instance creation' stamp: 'ar 10/9/1998 23:44'!
extent: extentPoint depth: bitsPerPixel bits: aBitmap
	"Answer an instance of me with blank bitmap of the given dimensions and depth."

	^ self basicNew setExtent: extentPoint depth: bitsPerPixel bits: aBitmap! !

!Form class methodsFor: 'instance creation' stamp: 'jm 3/27/98 16:35'!
extent: extentPoint depth: bitsPerPixel fromArray: anArray offset: offsetPoint 
	"Answer an instance of me with a pixmap of the given depth initialized from anArray."

	^ (self extent: extentPoint depth: bitsPerPixel)
		offset: offsetPoint;
		initFromArray: anArray
! !

!Form class methodsFor: 'instance creation' stamp: 'jm 3/27/98 16:33'!
extent: extentPoint fromArray: anArray offset: offsetPoint 
	"Answer an instance of me of depth 1 with bitmap initialized from anArray."

	^ (self extent: extentPoint depth: 1)
		offset: offsetPoint;
		initFromArray: anArray
! !

!Form class methodsFor: 'instance creation' stamp: 'jm 3/27/98 16:28'!
extent: extentPoint fromStipple: fourNibbles
	"Answer an instance of me with bitmap initialized from
	a repeating 4x4 bit stipple encoded in a 16-bit constant."
	| nibble |
	^ (self extent: extentPoint depth: 1)
		initFromArray: ((1 to: 4) collect:
				[:i | nibble _ (fourNibbles bitShift: -4*(4-i)) bitAnd: 16rF.
				16r11111111 * nibble])  "fill 32 bits with each 4-bit nibble"
! !

!Form class methodsFor: 'instance creation' stamp: 'jm 8/6/2008 10:39'!
fromBinaryStream: aBinaryStream
	"Read a Form or ColorForm from given file, using the first byte of the file to guess its format. Currently handles: GIF, uncompressed BMP, and both old and new DisplayObject writeOn: formats, JPEG, and PCX. Return nil if the file could not be read or was of an unrecognized format."

	| firstByte secondByte readerClass form |
	aBinaryStream binary.
	firstByte _ aBinaryStream next.
	firstByte = 1 ifTrue: [
		"old Squeakform format"
		^ self new readFromOldFormat: aBinaryStream].
	firstByte = 2 ifTrue: [
		"new Squeak form format"
		^ self new readFrom: aBinaryStream].
	firstByte = $B asciiValue ifTrue: [
		"BMP format"
		aBinaryStream skip: - 1.
		^ self fromBMPStream: aBinaryStream].
	firstByte = 16rFF ifTrue: [
		secondByte _ aBinaryStream next.
		aBinaryStream skip: - 2.
		secondByte = 16rD8 ifTrue: [
			^ FastJPEG uncompress: aBinaryStream upToEnd doDithering: false]].

	"Try for GIF, PNG, or other formats understood by subclasses of ImageReadWriter..."
	(readerClass _ self imageReaderClass) ifNil: [self error: 'unknown image format'].
	"Note: The following call closes the stream."
	form _ readerClass formFromStream: aBinaryStream.

	^ form removeNoisyAlpha
! !

!Form class methodsFor: 'instance creation'!
fromDisplay: aRectangle 
	"Answer an instance of me with bitmap initialized from the area of the 
	display screen defined by aRectangle."

	^ (self extent: aRectangle extent depth: Display depth)
		fromDisplay: aRectangle! !

!Form class methodsFor: 'instance creation'!
fromDisplay: aRectangle using: oldForm
	"Like fromDisplay: only if oldForm is the right size, copy into it and answer it instead."

	((oldForm ~~ nil) and: [oldForm extent = aRectangle extent])
		ifTrue:
			[oldForm fromDisplay: aRectangle.
			 ^ oldForm]
		ifFalse:
			[^ self fromDisplay: aRectangle]! !

!Form class methodsFor: 'instance creation' stamp: 'jm 1/11/1999 10:42'!
fromFileNamed: fileName
	"Read a Form or ColorForm from the given file."

	| file form |
	file _ (FileStream readOnlyFileNamed: fileName) binary.
	form _ self fromBinaryStream: file.
	file close.
	^ form
! !

!Form class methodsFor: 'instance creation' stamp: 'jm 2/22/2006 15:27'!
fromRGBFileNamed: fileName
	"Read a form from a file with the following simple, uncompressed RGB format:
		<width (2 bytes)><height (2 bytes)><r1><g1><b1><r2><g2><b2>..."

	| f w h bits r g b |
	f _ (FileStream oldFileNamed: fileName) binary.
	w _ f int16.
	h _ f int16.
	bits _ Bitmap new: w * h.
	1 to: bits size do: [:i |
		r _ f next.
		g _ f next.
		b _ f next.
		bits at: i put: (r bitShift: 16) + (g bitShift: 8) + b].
	f close.
	^ (Form extent: w@h depth: 32) bits: bits
! !

!Form class methodsFor: 'instance creation' stamp: 'jm 6/15/2003 17:54'!
fromUser
	"Answer an instance of me with bitmap initialized from the rectangle of the display screen designated by the user."

	^ self fromDisplay: (Rectangle fromUser)
! !


!Form class methodsFor: 'mode constants'!
and
	"Answer the integer denoting the logical 'and' combination rule."

	^1! !

!Form class methodsFor: 'mode constants'!
blend
	"Answer the integer denoting BitBlt's alpha blend combination rule."
	^24! !

!Form class methodsFor: 'mode constants' stamp: 'di 12/31/1998 14:02'!
blendAlpha
	"Answer the integer denoting BitBlt's blend-with-constant-alpha rule."

	^ 30! !

!Form class methodsFor: 'mode constants'!
erase
	"Answer the integer denoting mode erase."

	^4! !

!Form class methodsFor: 'mode constants'!
erase1bitShape
	"Answer the integer denoting mode erase."

	^ 26! !

!Form class methodsFor: 'mode constants'!
oldErase1bitShape
	"Answer the integer denoting mode erase."

	^ 17! !

!Form class methodsFor: 'mode constants'!
oldPaint
	"Answer the integer denoting the 'paint' combination rule."

	^16! !

!Form class methodsFor: 'mode constants'!
over
	"Answer the integer denoting mode over."

	^3! !

!Form class methodsFor: 'mode constants'!
paint
	"Answer the integer denoting the 'paint' combination rule."

	^25! !

!Form class methodsFor: 'mode constants' stamp: 'di 12/31/1998 14:02'!
paintAlpha
	"Answer the integer denoting BitBlt's paint-with-constant-alpha rule."

	^ 31! !

!Form class methodsFor: 'mode constants'!
reverse
	"Answer the integer denoting mode reverse."

	^6! !

!Form class methodsFor: 'mode constants'!
under
	"Answer the integer denoting mode under."

	^7! !


!Form class methodsFor: 'examples'!
exampleBorder    "Form exampleBorder"
	"This example demonstrates the border finding algorithm. Start
	by having the user sketch on the screen (end with option-click) and then select a rectangular
	area of the screen which includes all of the area to be filled. Finally,
	(with crosshair cursor), the user points at the interior of the region to be
	outlined, and the region begins with that place as its seed."
	| f r interiorPoint |
	Form exampleSketch.		"sketch a little area with an enclosed region"
	r _ Rectangle fromUser.
	f _ Form fromDisplay: r.
	Cursor crossHair showWhile:
		[interiorPoint _ Sensor waitButton - r origin].
	Cursor execute showWhile:
		[f shapeBorder: Color blue width: 2 interiorPoint: interiorPoint
			sharpCorners: false internal: false].
	f displayOn: Display at: r origin	! !

!Form class methodsFor: 'examples' stamp: 'jm 2/27/2004 18:34'!
exampleBorder2    "Form exampleBorder2"
	"This example demonstrates the border finding algorithm. Start
	by having the user sketch on the screen (end with option-click) and then select a rectangular
	area of the screen which includes all of the area to be filled. Finally,
	(with crosshair cursor), the user points at the interior of the region to be
	outlined, and the region begins with that place as its seed."
	| f r interiorPoint |
	Form exampleSketch.		"sketch a little area with an enclosed region"
	r _ Rectangle fromUser.
	f _ Form fromDisplay: r.
	Cursor crossHair showWhile:
		[interiorPoint _ Sensor waitButton - r origin].
	Cursor execute showWhile:
		[f shapeBorder: Color blue width: 4 interiorPoint: interiorPoint
			sharpCorners: false internal: false].
	f displayOn: Display at: r origin	! !

!Form class methodsFor: 'examples'!
exampleEdits
	"In Form category editing are messages edit and bitEdit that make it possible to 
	create editors on instances of Form. 
	 
	This is the general form editor:
	| f | 
	f _ Form fromUser. 
	f edit. 
	 
	This is the general bit editor:
	| f | 
	f _ Form fromUser. 
	f bitEdit."! !

!Form class methodsFor: 'examples' stamp: 'jm 6/15/2003 18:50'!
exampleMagnify
	"Form exampleMagnify"

	| f m |
	f _ Form fromUser.
	m _ f magnify: f boundingBox by: 3.
	m displayOn: Display.

! !

!Form class methodsFor: 'examples'!
exampleSketch
	"This is a simple drawing algorithm to get a sketch on the display screen.
	Draws whenever mouse button down.  Ends with option-click."
	| aPen color |
	aPen _ Pen new.
	color _ 0.
	[Sensor yellowButtonPressed]
		whileFalse:
		[aPen place: Sensor cursorPoint; color: (color _ color + 1).
		[Sensor redButtonPressed]
			whileTrue: [aPen goto: Sensor cursorPoint]].
	Sensor waitNoButton.

	"Form exampleSketch"! !

!Form class methodsFor: 'examples'!
exampleSpaceFill    "Form exampleSpaceFill"
	"This example demonstrates the area filling algorithm. Starts by having
	the user sketch on the screen (ended by option-click) and then select a rectangular
	area of the screen which includes all of the area to be filled. Finally,
	(with crosshair cursor), the user points at the interior of some region to be
	filled, and the filling begins with that place as its seed."
	| f r interiorPoint |
	Form exampleSketch.		"sketch a little area with an enclosed region"
	r _ Rectangle fromUser.
	f _ Form fromDisplay: r.
	Cursor crossHair showWhile:
		[interiorPoint _ Sensor waitButton - r origin].
	Cursor execute showWhile:
		[f shapeFill: Color gray interiorPoint: interiorPoint].
	f displayOn: Display at: r origin	! !

!Form class methodsFor: 'examples'!
makeStar  "See the similar example in OpaqueForm"
	| sampleForm pen |
	sampleForm _ Form extent: 50@50.  "Make a form"
	pen _ Pen newOnForm: sampleForm.
	pen place: 24@50; turn: 18.		"Draw a 5-pointed star on it."
	1 to: 5 do: [:i | pen go: 19; turn: 72; go: 19; turn: -144].
	^ sampleForm
"
Form makeStar follow: [Sensor cursorPoint]
				while: [Sensor noButtonPressed]
"! !

!Form class methodsFor: 'examples' stamp: 'jm 6/15/2003 17:58'!
toothpaste: diam		"Display restoreAfter: [Form toothpaste: 30]"
	"Draws wormlike lines by laying down images of spheres.
	See Ken Knowlton, Computer Graphics, vol. 15 no. 4 p352.
	Draw with mouse button down; terminate by option-click."
	| facade ball filter point queue port color q colors colr colr2 |
	colors _ Display depth = 1
		ifTrue: [Array with: Color black]
		ifFalse: [Color red wheel: 12].
	facade _ (Form extent: diam@diam) offset: (diam//-2) asPoint.
	(Form dotOfSize: diam) displayOn: facade
			at: (diam//2) asPoint clippingBox: facade boundingBox
			rule: Form under fillColor: Color white.
	#(1 2 3) do:
		[:x |  "simulate facade by circles of gray"
		(Form dotOfSize: x*diam//5) displayOn: facade
			at: (diam*2//5) asPoint clippingBox: facade boundingBox
			rule: Form under
			fillColor: (Color perform: 
					(#(black gray lightGray) at: x)).
		"facade displayAt: 50*x@50"].
	ball _ Form dotOfSize: diam.
	color _ 8.
	[ true ] whileTrue:
		[port _ BitBlt toForm: Display.
		"Expand 1-bit forms to any pixel depth"
		port colorMap: (Bitmap with: 0 with: 16rFFFFFFFF).
		queue _ OrderedCollection new: 32.
		16 timesRepeat: [queue addLast: -20@-20].
		Sensor waitButton.
		Sensor yellowButtonPressed ifTrue: [^ self].
		filter _ Sensor cursorPoint.
		colr _ colors atWrap: (color _ color + 5).  "choose increment relatively prime to colors size"
		colr2 _ colr mixed: 0.3 with: Color white.
		[Sensor redButtonPressed or: [queue size > 0]] whileTrue:
			[filter _ filter * 4 + Sensor cursorPoint // 5.
			point _ Sensor redButtonPressed
				ifTrue: [filter] ifFalse: [-20@-20].
			port copyForm: ball to: point rule: Form paint fillColor: colr.
			(q _ queue removeFirst) == nil ifTrue: [^ self].	"exit"
			Display depth = 1
				ifTrue: [port copyForm: facade to: q rule: Form erase]
				ifFalse: [port copyForm: facade to: q rule: Form paint fillColor: colr2].
			Sensor redButtonPressed ifTrue: [queue addLast: point]]].
! !

!Form class methodsFor: 'examples'!
xorHack: size  "Display restoreAfter: [Form xorHack: 256]"
	"Draw a smiley face or stick figure, and end with option-click.
	Thereafter image gets 'processed' as long as you have button down.
	If you stop at just the right time, you'll see you figure upside down,
	and at the end of a full cycle, you'll see it perfectly restored.
	Dude -- this works in color too!!"
	| rect form i bb |
	rect _ 5@5 extent: size@size.
	Display fillWhite: rect; border: (rect expandBy: 2) width: 2.
	Display border: (rect topRight - (0@2) extent: rect extent*2 + 4) width: 2.
	Form exampleSketch.
	form _ Form fromDisplay: rect.
	bb _ form boundingBox.
	i _ 0.
	[Sensor yellowButtonPressed] whileFalse:
		[[Sensor redButtonPressed] whileTrue:
			[i _ i + 1.
			(Array with: 0@1 with: 0@-1 with: 1@0 with: -1@0) do:
				[:d | form copyBits: bb from: form at: d
					clippingBox: bb rule: Form reverse fillColor: nil].
			form displayAt: rect topLeft.
			i+2\\size < 4 ifTrue: [(Delay forMilliseconds: 300) wait]].
		(form magnify: form boundingBox by: 2@2) displayAt: rect topRight + (2@0).
		Sensor waitButton].! !


!Form class methodsFor: 'shut down' stamp: 'jm 1/1/2004 11:10'!
shutDown
	"Compress all instances of Form and it's subclasses in the image to save space in snapshots. They will decompress on demand."
	"Form shutDown"

	Form allInstancesDo: [:f | f hibernate].
	ColorForm allInstancesDo: [:f | f hibernate].
! !


!Form class methodsFor: 'private' stamp: 'jm 9/3/2008 09:09'!
bmp24BitPixelDataFrom: aBinaryStream width: w height: h
	"Read 24-bit pixel data from the given a BMP stream."

	| form rowBytes line blackPixelValue opaqueAlpha pixelLine pixIndex rgb |
	form _ Form extent: w@h depth: 32.
	rowBytes _ (((24 * w) + 31) // 32) * 4.
	line _ Form extent: w@1 depth: 32.
	blackPixelValue _ Color black pixelValueForDepth: 32.
	opaqueAlpha _ 255 bitShift: 24.
	1 to: h do: [:i |
		pixelLine _ aBinaryStream next: rowBytes.
		pixIndex _ 1.
		1 to: w do: [:j |
			rgb _ (pixelLine at: pixIndex) +
				   ((pixelLine at: pixIndex + 1) bitShift: 8) +
				   ((pixelLine at: pixIndex + 2) bitShift: 16).
			"BMP's don't support transparency, so map zero pixels to black"
			rgb = 0 ifTrue: [rgb _ blackPixelValue].
			line bits at: j put: (opaqueAlpha bitOr: rgb).
			pixIndex _ pixIndex + 3].
		form copy: line boundingBox from: line to: 0@(h - i) rule: Form over].
	^ form
! !

!Form class methodsFor: 'private'!
bmp32BitPixelDataFrom: aBinaryStream width: w height: h
	"Read 32-bit pixel data from the given a BMP stream."

	| form line blackPixelValue opaqueAlpha pixelLine pixIndex rgb |
	form _ Form extent: w@h depth: 32.
	line _ Form extent: w@1 depth: 32.
	blackPixelValue _ Color black pixelValueForDepth: 32.
	opaqueAlpha _ 255 bitShift: 24.
	1 to: h do: [:i |
		pixelLine _ aBinaryStream next: (4 * w).
		pixIndex _ 1.
		1 to: w do: [:j |
			rgb _ (pixelLine at: pixIndex) +
				   ((pixelLine at: pixIndex + 1) bitShift: 8) +
				   ((pixelLine at: pixIndex + 2) bitShift: 16).
			"alpha _ pixelLine at: pixIndex + 3."  "ignore--BMP's do not support alpha"
			"BMP's don't support transparency, so map zero pixels to black"
			rgb = 0 ifTrue: [rgb _ blackPixelValue].
			line bits at: j put: (opaqueAlpha bitOr: rgb).
			pixIndex _ pixIndex + 4].
		form copy: line boundingBox from: line to: 0@(h - i) rule: Form over].
	^ form
! !

!Form class methodsFor: 'private' stamp: 'di 2/3/1999 07:44'!
bmpColorsFrom: aBinaryStream count: colorCount depth: depth
	"Read colorCount BMP color map entries from the given binary stream. Answer an array of Colors."

	| maxLevel colors b g r |
	colorCount = 0 ifTrue: [  "this BMP file does not have a color map"
		"default monochrome color map"
		depth = 1 ifTrue: [^ Array with: Color white with: Color black].
		"default gray-scale color map"
		maxLevel _ (2 raisedTo: depth) - 1.
		^ (0 to: maxLevel) collect: [:level | Color gray: (level asFloat / maxLevel)]].

	colors _ Array new: colorCount.
	1 to: colorCount do: [:i |
		b _ aBinaryStream next.
		g _ aBinaryStream next.
		r _ aBinaryStream next.
		aBinaryStream skip: 1.
		colors at: i put: (Color r: r g: g b: b range: 255)].
	^ colors
! !

!Form class methodsFor: 'private' stamp: 'jm 4/18/98 20:03'!
bmpPixelDataFrom: aBinaryStream width: w height: h depth: d
	"Read uncompressed pixel data of depth d from the given BMP stream, where d is 1, 4, or 8."

	| form bytesPerRow pixelData pixelLine startIndex |
	form _ ColorForm extent: w@h depth: d.  "color map filled in by caller"
	bytesPerRow _ (((d* w) + 31) // 32) * 4.
	pixelData _ ByteArray new: bytesPerRow * h.
	h to: 1 by: -1 do: [:y |
		pixelLine _ aBinaryStream next: bytesPerRow.
		startIndex _ ((y - 1) * bytesPerRow) + 1.
		pixelData
			replaceFrom: startIndex
			to: startIndex + bytesPerRow - 1
			with: pixelLine
			startingAt: 1].
	form bits copyFromByteArray: pixelData.
	^ form
! !

!Form class methodsFor: 'private' stamp: 'jm 3/22/2007 14:25'!
fromBMPStream: aBinaryStream
	"Read a BMP format image from the given binary stream."
	"Form fromBMPFile:
		(HTTPSocket
			httpGet: 'http://anHTTPServer/squeak/squeakers.bmp'
			accept: 'image/bmp')"

	| fType fSize reserved pixDataStart hdrSize w h planes d
      compressed colorCount colors colorForm |
	(aBinaryStream isMemberOf: String) ifTrue: [^ nil].  "a network error message"
	aBinaryStream binary.
	fType _ aBinaryStream littleEndianUint16.
	fSize _ aBinaryStream littleEndianUint32.
	reserved _ aBinaryStream littleEndianUint32.
	pixDataStart _ aBinaryStream littleEndianUint32.
	hdrSize _ aBinaryStream littleEndianUint32.
	w _ aBinaryStream littleEndianUint32.
	h _ aBinaryStream littleEndianUint32.
	planes _ aBinaryStream littleEndianUint16.
	d _ aBinaryStream littleEndianUint16.
	compressed _ aBinaryStream littleEndianUint32.
	aBinaryStream littleEndianUint32.  "biSizeImage"
	aBinaryStream littleEndianUint32.  "biXPelsPerMeter"
	aBinaryStream littleEndianUint32.  "biYPelsPerMeter"
	colorCount _ aBinaryStream littleEndianUint32.
	aBinaryStream littleEndianUint32.  "biClrImportant"

	((fType = 19778) & (reserved = 0) & (planes = 1) &
	 (hdrSize = 40) & (fSize <= aBinaryStream size))
		ifFalse: [self error: 'Bad BMP file header'].
	compressed = 0
		ifFalse: [self error: 'Can only read uncompressed BMP files'].

	d = 32 ifTrue: [
		aBinaryStream position: pixDataStart.
		^ self bmp32BitPixelDataFrom: aBinaryStream width: w height: h].

	d = 24 ifTrue: [
		aBinaryStream position: pixDataStart.
		^ self bmp24BitPixelDataFrom: aBinaryStream width: w height: h].

	d <= 8 ifFalse: [self error: 'unknown BMP format, depth: ', d printString].

	"read the color map"
	"Note: some programs (e.g. Photoshop 4.0) apparently do not set colorCount; assume that any data between the end of the header and the start of the pixel data is the color map"
	colorCount _ (pixDataStart - 54) // 4.
	colorCount = 0 ifTrue: [self error: 'BMP file has no color map'].
	colors _ self bmpColorsFrom: aBinaryStream count: colorCount depth: d.

	"read the pixel data"
	aBinaryStream position: pixDataStart.
	colorForm _ self bmpPixelDataFrom: aBinaryStream width: w height: h depth: d.
	colorForm colors: colors.
	^ colorForm
! !

!Form class methodsFor: 'private' stamp: 'jm 6/20/2003 09:08'!
imageReaderClass
	"If present, answer the class for importing various graphic image files from disk. Otherwise return nil."

	| aClass |
	^ ((aClass _ Smalltalk at: #ImageReadWriter ifAbsent: [nil]) isKindOf: Class)
		ifTrue: [aClass]
		ifFalse: [nil]
! !
