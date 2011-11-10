Object subclass: #BitBlt
	instanceVariableNames: 'destForm sourceForm halftoneForm combinationRule destX destY width height sourceX sourceY clipX clipY clipWidth clipHeight colorMap '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Primitives'!
!BitBlt commentStamp: 'jm 8/1/2008 20:22' prior: 0!
I represent a block transfer (BLT) of pixels into a rectangle (destX, destY, width, height) of the destinationForm.  The source of pixels may be a similar rectangle (at sourceX, sourceY) in the sourceForm, or a constant color, currently called halftoneForm.  If both are specified, their pixel values are combined with a logical AND function prior to transfer.  In any case, the pixels from the source are combined with those of the destination by as specified by the combinationRule.

The combination rule whose value is 0 through 15 programs the transfer to produce 1 or 0 according to its 4-bit representation as follows:
	8:	if source is 0 and destination is 0
	4:	if source is 0 and destination is 1
	2:	if source is 1 and destination is 0
	1:	if source is 1 and destination is 1.
At each pixel the corresponding bits of the source and destination pixel values determine one of these conditions;  if the combination rule has a 1 in the corresponding bit position, then the new destination value will be 1, otherwise it will be zero.  Forms may be of different depths, see the comment in class Form.

In addition to the original 16 combination rules, this BitBlt supports
	16	fails (to simulate paint bits)
	17	fails (to simulate erase bits)
	18	sourceWord + destinationWord
	19	sourceWord - destinationWord
	20	rgbAdd: sourceWord with: destinationWord.  Sum of color components
	21	rgbSub: sourceWord with: destinationWord.  Difference of color components
	22	OLDrgbDiff: sourceWord with: destinationWord.  Sum of abs of differences in components
	23	OLDtallyIntoMap: destinationWord.  Tallies pixValues into a colorMap
			these old versions don't do bitwise dest clipping.  Use 32 and 33 now.
	24	alphaBlend: sourceWord with: destinationWord.  32-bit source and dest only
	25	pixPaint: sourceWord with: destinationWord.  Wherever the sourceForm is non-zero, it replaces the destination.  Can be used with a 1-bit source color mapped to (0, FFFFFFFF), and a fillColor to fill the dest with that color wherever the source is 1.
	26	pixMask: sourceWord with: destinationWord.  Like pixPaint, but fills with 0.
	27	rgbMax: sourceWord with: destinationWord.  Max of each color component.
	28	rgbMin: sourceWord with: destinationWord.  Min of each color component.
	29	rgbMin: sourceWord bitInvert32 with: destinationWord.  Min with (max-source)
	30	alphaBlendConst: sourceWord with: destinationWord.  alpha is an arg. works in 16 bits.
	31	alphaPaintConst: sourceWord with: destinationWord.  alpha is an arg. works in 16 bits.
	32	rgbDiff: sourceWord with: destinationWord.  Sum of abs of differences in components
	33	tallyIntoMap: destinationWord.  Tallies pixValues into a colorMap
	34	alphaBlendScaled: srcWord with: dstWord. Alpha blend of scaled srcWord and destWord.

The color specified by halftoneForm may be either a Color or a Pattern.   A Color is converted to a pixelValue for the depth of the destinationForm.  If a Pattern, BitBlt will simply interpret its bitmap as an array of Color pixelValues.  BitBlt aligns the first element of this array with the top scanline of the destinationForm, the second with the second, and so on, cycling through the color array as necessary.  Within each scan line the 32-bit value is repeated from left to right across the form.  If the value repeats on pixels boudaries, the effect will be a constant color;  if not, it will produce a halftone that repeats on 32-bit boundaries.

Any transfer specified is further clipped by the specified rectangle (clipX, clipY, clipWidth, clipHeight), and also by the bounds of the source and destination forms.
	To make a small Form repeat and fill a big form, use an InfiniteForm as the source.
	To write on a form and leave with both transparent and opapue areas, use a MaskedForm as the source.

Pixels from a source to a destination whose pixels have a different depth are converted based on the optional colorMap.  If colorMap is nil, then conversion to more bits is done by filling the new high-order bits with zero, and conversion to fewer bits is done by truncating the lost high-order bits.  The colorMap, if specified, must be a word array (ie Bitmap) with 2^n elements, where n is the pixel depth of the source.  For every source pixel, BitBlt will then index this array, and select the corresponding pixelValue and mask it to the destination pixel size before storing.
	When blitting from a 32 or 16 bit deep Form to one 8 bits or less, the default is truncation.  This will produce very strange colors, since truncation of the high bits does not produce the nearest encoded color.  Supply a 512 long colorMap, and red, green, and blue will be shifted down to 3 bits each, and mapped.  The message copybits...stdColors will use the best map to the standard colors for destinations of depths 8, 4, 2 and 1.  Two other sized of colorMaps are allowed, 4096 (4 bits per color) and 32768 (five bits per color).
	Normal blits between 16 and 32 bit forms truncates or pads the colors automatically to provide the best preservation of colors.
	Colors can be remapped at the same depth.  Sometimes a Form is in terms of colors that are not the standard colors for this depth, for example in a GIF file.  Convert the Form to a MaskedForm and send colorMap: the list of colors that the picture is in terms of.  MaskedForm will use the colorMap when copying to the display or another Form. (Note also that a Form can be copied to itself, and transformed in the process, if a non-nil colorMap is supplied.)!


!BitBlt methodsFor: 'accessing' stamp: 'ar 5/17/2000 18:58'!
clipHeight
	^clipHeight! !

!BitBlt methodsFor: 'accessing'!
clipHeight: anInteger 
	"Set the receiver's clipping area height to be the argument, anInteger."

	clipHeight _ anInteger! !

!BitBlt methodsFor: 'accessing'!
clipRect
	"Answer the receiver's clipping area rectangle."

	^clipX @ clipY extent: clipWidth @ clipHeight! !

!BitBlt methodsFor: 'accessing'!
clipRect: aRectangle 
	"Set the receiver's clipping area rectangle to be the argument, aRectangle."

	clipX _ aRectangle left.
	clipY _ aRectangle top.
	clipWidth _ aRectangle width.
	clipHeight _ aRectangle height! !

!BitBlt methodsFor: 'accessing' stamp: 'ar 5/17/2000 18:58'!
clipWidth
	^clipWidth! !

!BitBlt methodsFor: 'accessing'!
clipWidth: anInteger 
	"Set the receiver's clipping area width to be the argument, anInteger."

	clipWidth _ anInteger! !

!BitBlt methodsFor: 'accessing' stamp: 'ar 5/17/2000 18:58'!
clipX
	^clipX! !

!BitBlt methodsFor: 'accessing'!
clipX: anInteger 
	"Set the receiver's clipping area top left x coordinate to be the argument, 
	anInteger."

	clipX _ anInteger! !

!BitBlt methodsFor: 'accessing' stamp: 'ar 5/17/2000 18:58'!
clipY
	^clipY! !

!BitBlt methodsFor: 'accessing'!
clipY: anInteger 
	"Set the receiver's clipping area top left y coordinate to be the argument, 
	anInteger."

	clipY _ anInteger! !

!BitBlt methodsFor: 'accessing'!
colorMap
	^ colorMap! !

!BitBlt methodsFor: 'accessing' stamp: 'ar 5/25/2000 19:43'!
colorMap: map
	"See last part of BitBlt comment. 6/18/96 tk"
	(map notNil and:[map isColormap])
		ifTrue:[colorMap _ map colors]
		ifFalse:[colorMap _ map]! !

!BitBlt methodsFor: 'accessing'!
combinationRule: anInteger 
	"Set the receiver's combination rule to be the argument, anInteger, a 
	number in the range 0-15."

	combinationRule _ anInteger! !

!BitBlt methodsFor: 'accessing'!
destForm
	^ destForm! !

!BitBlt methodsFor: 'accessing'!
destOrigin: aPoint 
	"Set the receiver's destination top left coordinates to be those of the 
	argument, aPoint."

	destX _ aPoint x.
	destY _ aPoint y! !

!BitBlt methodsFor: 'accessing' stamp: 'tk 3/19/97'!
destRect
	"The rectangle we are about to blit to or just blitted to.  "

	^ destX @ destY extent: width @ height! !

!BitBlt methodsFor: 'accessing'!
destRect: aRectangle 
	"Set the receiver's destination form top left coordinates to be the origin of 
	the argument, aRectangle, and set the width and height of the receiver's 
	destination form to be the width and height of aRectangle."

	destX _ aRectangle left.
	destY _ aRectangle top.
	width _ aRectangle width.
	height _ aRectangle height! !

!BitBlt methodsFor: 'accessing'!
destX: anInteger 
	"Set the top left x coordinate of the receiver's destination form to be the 
	argument, anInteger."

	destX _ anInteger! !

!BitBlt methodsFor: 'accessing'!
destX: x destY: y width: w height: h
	"Combined init message saves 3 sends from DisplayScanner"
	destX _ x.
	destY _ y.
	width _ w.
	height _ h.! !

!BitBlt methodsFor: 'accessing'!
destY: anInteger 
	"Set the top left y coordinate of the receiver's destination form to be the 
	argument, anInteger."

	destY _ anInteger! !

!BitBlt methodsFor: 'accessing' stamp: 'JM 11/9/2011 16:40'!
drawFrom: startPoint to: stopPoint withFirstPoint: drawFirstPoint
	"Draw a line whose end points are startPoint and stopPoint.
	The line is formed by repeatedly calling copyBits at every
	point along the line.  If drawFirstPoint is false, then omit
	the first point so as not to overstrike at line junctions."
	| offset point1 point2 forwards |
	"Always draw down, or at least left-to-right"
	forwards _ (startPoint y = stopPoint y and: [startPoint x < stopPoint x])
				or: [startPoint y < stopPoint y].
	forwards
		ifTrue: [point1 _ startPoint. point2 _ stopPoint]
		ifFalse: [point1 _ stopPoint. point2 _ startPoint].
	sourceForm == nil ifTrue:
		[destX _ point1 x.
		destY _ point1 y]
		ifFalse:
		[width _ sourceForm width.
		height _ sourceForm height.
		offset _ sourceForm offset.
		destX _ (point1 x + offset x) rounded.
		destY _ (point1 y + offset y) rounded].

	"Note that if not forwards, then the first point is the last and vice versa.
	We agree to always paint stopPoint, and to optionally paint startPoint."
	(drawFirstPoint or: [forwards == false  "ie this is stopPoint"])
		ifTrue: [self copyBitsTranslucent: 100].
	self drawLoopX: (point2 x - point1 x) rounded 
				  Y: (point2 y - point1 y) rounded.
	(drawFirstPoint or: [forwards  "ie this is stopPoint"])
		ifTrue: [self copyBitsTranslucent: 100].
! !

!BitBlt methodsFor: 'accessing'!
fillColor
	^ halftoneForm! !

!BitBlt methodsFor: 'accessing'!
fillColor: aColorOrPattern 
	"The destForm will be filled with this color or pattern of colors.  May be an old Color, a new type Color, a Bitmap (see BitBlt comment), a Pattern, or a Form.  6/18/96 tk"

	aColorOrPattern == nil ifTrue: [halftoneForm _ nil. ^ self].
	destForm == nil ifTrue: [self error: 'Must set destForm first'].
	halftoneForm _ aColorOrPattern bitPatternForDepth: destForm depth! !

!BitBlt methodsFor: 'accessing' stamp: 'jm 12/2/2003 15:31'!
halftone: aColorOrPattern 
	"The destForm will be filled with this color or pattern of colors.  May be an old Color, a new type Color, a Bitmap (see BitBlt comment), a Pattern, or a Form.  6/18/96 tk"

	halftoneForm _ aColorOrPattern.
! !

!BitBlt methodsFor: 'accessing'!
height: anInteger 
	"Set the receiver's destination form height to be the argument, anInteger."

	height _ anInteger! !

!BitBlt methodsFor: 'accessing'!
sourceForm

	^ sourceForm! !

!BitBlt methodsFor: 'accessing'!
sourceForm: aForm 
	"Set the receiver's source form to be the argument, aForm."

	sourceForm _ aForm! !

!BitBlt methodsFor: 'accessing'!
sourceOrigin: aPoint 
	"Set the receiver's source form coordinates to be those of the argument, 
	aPoint."

	sourceX _ aPoint x.
	sourceY _ aPoint y! !

!BitBlt methodsFor: 'accessing'!
sourceRect: aRectangle 
	"Set the receiver's source form top left x and y, width and height to be 
	the top left coordinate and extent of the argument, aRectangle."

	sourceX _ aRectangle left.
	sourceY _ aRectangle top.
	width _ aRectangle width.
	height _ aRectangle height! !

!BitBlt methodsFor: 'accessing'!
sourceX: anInteger 
	"Set the receiver's source form top left x to be the argument, anInteger."

	sourceX _ anInteger! !

!BitBlt methodsFor: 'accessing'!
sourceY: anInteger 
	"Set the receiver's source form top left y to be the argument, anInteger."

	sourceY _ anInteger! !

!BitBlt methodsFor: 'accessing' stamp: 'ar 5/25/2000 19:39'!
tallyMap: aBitmap
	"Install the map used for tallying pixels"
	colorMap _ aBitmap! !

!BitBlt methodsFor: 'accessing'!
width: anInteger 
	"Set the receiver's destination form width to be the argument, anInteger."

	width _ anInteger! !


!BitBlt methodsFor: 'copying'!
copy: destRectangle from: sourcePt in: srcForm
	| destOrigin |
	sourceForm _ srcForm.
	halftoneForm _ nil.
	combinationRule _ 3.  "store"
	destOrigin _ destRectangle origin.
	destX _ destOrigin x.
	destY _ destOrigin y.
	sourceX _ sourcePt x.
	sourceY _ sourcePt y.
	width _ destRectangle width.
	height _ destRectangle height.
	self copyBits! !

!BitBlt methodsFor: 'copying' stamp: 'di 12/26/1998 15:04'!
copy: destRectangle from: sourcePt in: srcForm fillColor: hf rule: rule
	"Specify a Color to fill, not a Form. 6/18/96 tk"  
	| destOrigin |
	sourceForm _ srcForm.
	self fillColor: hf.	"sets halftoneForm"
	combinationRule _ rule.
	destOrigin _ destRectangle origin.
	destX _ destOrigin x.
	destY _ destOrigin y.
	sourceX _ sourcePt x.
	sourceY _ sourcePt y.
	width _ destRectangle width.
	height _ destRectangle height.
	srcForm == nil ifFalse:
		[colorMap _ srcForm colormapIfNeededForDepth: destForm depth].
	^ self copyBits! !

!BitBlt methodsFor: 'copying' stamp: 'di 12/31/1998 14:38'!
copyBits
	"Primitive. Perform the movement of bits from the source form to the 
	destination form. Fail if any variables are not of the right type (Integer, 
	Float, or Form) or if the combination rule is not implemented. 
	In addition to the original 16 combination rules, this BitBlt supports
	16	fail (to simulate paint)
	17	fail (to simulate mask)
	18	sourceWord + destinationWord
	19	sourceWord - destinationWord
	20	rgbAdd: sourceWord with: destinationWord
	21	rgbSub: sourceWord with: destinationWord
	22	rgbDiff: sourceWord with: destinationWord
	23	tallyIntoMap: destinationWord
	24	alphaBlend: sourceWord with: destinationWord
	25	pixPaint: sourceWord with: destinationWord
	26	pixMask: sourceWord with: destinationWord
	27	rgbMax: sourceWord with: destinationWord
	28	rgbMin: sourceWord with: destinationWord
	29	rgbMin: sourceWord bitInvert32 with: destinationWord
"
	<primitive: 96>

	"Check for compressed source, destination or halftone forms"
	(combinationRule >= 30 and: [combinationRule <= 31]) ifTrue:
		["No alpha specified -- re-run with alpha = 1.0"
		^ self copyBitsTranslucent: 255].
	((sourceForm isKindOf: Form) and: [sourceForm unhibernate])
		ifTrue: [^ self copyBits].
	((destForm isKindOf: Form) and: [destForm unhibernate])
		ifTrue: [^ self copyBits].
	((halftoneForm isKindOf: Form) and: [halftoneForm unhibernate])
		ifTrue: [^ self copyBits].

	"Check for unimplmented rules"
	combinationRule = Form oldPaint ifTrue: [^ self paintBits].
	combinationRule = Form oldErase1bitShape ifTrue: [^ self eraseBits].

	self error: 'Bad BitBlt arg (Fraction?); proceed to convert.'.
	"Convert all numeric parameters to integers and try again."
	destX _ destX asInteger.
	destY _ destY asInteger.
	width _ width asInteger.
	height _ height asInteger.
	sourceX _ sourceX asInteger.
	sourceY _ sourceY asInteger.
	clipX _ clipX asInteger.
	clipY _ clipY asInteger.
	clipWidth _ clipWidth asInteger.
	clipHeight _ clipHeight asInteger.
	^ self copyBitsAgain! !

!BitBlt methodsFor: 'copying' stamp: 'di 1/4/1999 01:14'!
copyBitsTranslucent: factor
	"This entry point to BitBlt supplies an extra argument to specify translucency
	for operations 30 and 31.  The argument must be an integer between 0 and 255."

	<primitive: 96>

	"Check for compressed source, destination or halftone forms"
	((sourceForm isKindOf: Form) and: [sourceForm unhibernate])
		ifTrue: [^ self copyBitsTranslucent: factor].
	((destForm isKindOf: Form) and: [destForm unhibernate])
		ifTrue: [^ self copyBitsTranslucent: factor].
	((halftoneForm isKindOf: Form) and: [halftoneForm unhibernate])
		ifTrue: [^ self copyBitsTranslucent: factor].

	self primitiveFailed  "Later do nicer error recovery -- share copyBits recovery"! !

!BitBlt methodsFor: 'copying' stamp: 'di 7/17/97 10:04'!
copyForm: srcForm to: destPt rule: rule
	^ self copyForm: srcForm to: destPt rule: rule
		colorMap: (srcForm colormapIfNeededForDepth: destForm depth)! !

!BitBlt methodsFor: 'copying' stamp: 'di 7/17/97 10:04'!
copyForm: srcForm to: destPt rule: rule colorMap: map
	sourceForm _ srcForm.
	halftoneForm _ nil.
	combinationRule _ rule.
	destX _ destPt x + sourceForm offset x.
	destY _ destPt y + sourceForm offset y.
	sourceX _ 0.
	sourceY _ 0.
	width _ sourceForm width.
	height _ sourceForm height.
	colorMap _ map.
	self copyBits! !

!BitBlt methodsFor: 'copying'!
copyForm: srcForm to: destPt rule: rule fillColor: color
	sourceForm _ srcForm.
	self fillColor: color.	"sets halftoneForm"
	combinationRule _ rule.
	destX _ destPt x + sourceForm offset x.
	destY _ destPt y + sourceForm offset y.
	sourceX _ 0.
	sourceY _ 0.
	width _ sourceForm width.
	height _ sourceForm height.
	self copyBits! !

!BitBlt methodsFor: 'copying' stamp: 'di 7/1/97 14:09'!
copyFrom: sourceRectangle in: srcForm to: destPt
	| sourceOrigin |
	sourceForm _ srcForm.
	halftoneForm _ nil.
	combinationRule _ 3.  "store"
	destX _ destPt x.
	destY _ destPt y.
	sourceOrigin _ sourceRectangle origin.
	sourceX _ sourceOrigin x.
	sourceY _ sourceOrigin y.
	width _ sourceRectangle width.
	height _ sourceRectangle height.
	colorMap _ srcForm colormapIfNeededForDepth: destForm depth.
	self copyBits! !

!BitBlt methodsFor: 'copying' stamp: 'ar 5/19/2000 15:08'!
displayString: aString from: startIndex to: stopIndex at: aPoint strikeFont: font kern: kernDelta
	destY _ aPoint y.
	destX _ aPoint x.
	^self primDisplayString: aString from: startIndex to: stopIndex
			map: font characterToGlyphMap xTable: font xTable
			kern: kernDelta.! !

!BitBlt methodsFor: 'copying'!
fill: destRect fillColor: grayForm rule: rule
	"Fill with a Color, not a Form. 6/18/96 tk"
	sourceForm _ nil.
	self fillColor: grayForm.		"sets halftoneForm"
	combinationRule _ rule.
	destX _ destRect left.
	destY _ destRect top.
	sourceX _ 0.
	sourceY _ 0.
	width _ destRect width.
	height _ destRect height.
	self copyBits! !

!BitBlt methodsFor: 'copying'!
pixelAt: aPoint
	"Assumes this BitBlt has been set up specially (see the init message,
	BitBlt bitPeekerFromForm:.  Returns the pixel at aPoint."
	sourceX _ aPoint x.
	sourceY _ aPoint y.
	destForm bits at: 1 put: 0.  "Just to be sure"
	self copyBits.
	^ destForm bits at: 1! !

!BitBlt methodsFor: 'copying'!
pixelAt: aPoint put: pixelValue
	"Assumes this BitBlt has been set up specially (see the init message,
	BitBlt bitPokerToForm:.  Overwrites the pixel at aPoint."
	destX _ aPoint x.
	destY _ aPoint y.
	sourceForm bits at: 1 put: pixelValue.
	self copyBits
"
| bb |
bb _ (BitBlt bitPokerToForm: Display).
[Sensor anyButtonPressed] whileFalse:
	[bb pixelAt: Sensor cursorPoint put: 55]
"! !


!BitBlt methodsFor: 'line drawing'!
drawFrom: startPoint to: stopPoint 
	
	 ^ self drawFrom: startPoint to: stopPoint withFirstPoint: true! !

!BitBlt methodsFor: 'line drawing'!
drawLoopX: xDelta Y: yDelta 
	"Primitive. Implements the Bresenham plotting algorithm (IBM Systems
	Journal, Vol. 4 No. 1, 1965). It chooses a principal direction, and
	maintains a potential, P. When P's sign changes, it is time to move in
	the minor direction as well. This particular version does not write the
	first and last points, so that these can be called for as needed in client code.
	Optional. See Object documentation whatIsAPrimitive."
	| dx dy px py P |
	<primitive: 104>
	dx _ xDelta sign.
	dy _ yDelta sign.
	px _ yDelta abs.
	py _ xDelta abs.
	"self copyBits."
	py > px
		ifTrue: 
			["more horizontal"
			P _ py // 2.
			1 to: py do: 
				[:i |
				destX _ destX + dx.
				(P _ P - px) < 0 ifTrue: 
						[destY _ destY + dy.
						P _ P + py].
				i < py ifTrue: [self copyBits]]]
		ifFalse: 
			["more vertical"
			P _ px // 2.
			1 to: px do:
				[:i |
				destY _ destY + dy.
				(P _ P - py) < 0 ifTrue: 
						[destX _ destX + dx.
						P _ P + px].
				i < px ifTrue: [self copyBits]]]! !


!BitBlt methodsFor: 'private'!
copyBitsAgain
	"Primitive. See BitBlt|copyBits, also a Primitive. Essential. See Object
	documentation whatIsAPrimitive."

	<primitive: 96>
	self primitiveFailed! !

!BitBlt methodsFor: 'private'!
eraseBits
	"Perform the erase operation, which puts 0's in the destination
	wherever the source (which is assumed to be just 1 bit deep)
	has a 1.  This requires the colorMap to be set in order to AND
	all 1's into the destFrom pixels regardless of their size."
	| oldMask oldMap |
	oldMask _ halftoneForm.
	halftoneForm _ nil.
	oldMap _ colorMap.
	self colorMap: (Bitmap with: 0 with: 16rFFFFFFFF).
	combinationRule _ Form erase.
	self copyBits. 		"Erase the dest wherever the source is 1"
	halftoneForm _ oldMask.	"already converted to a Bitmap"
	colorMap _ oldMap! !

!BitBlt methodsFor: 'private' stamp: 'ar 5/23/2000 15:27'!
installStrikeFont: aStrikeFont foregroundColor: foregroundColor backgroundColor: backgroundColor
	| lastSourceDepth |
	sourceForm ifNotNil:[lastSourceDepth _ sourceForm depth].
	sourceForm _ aStrikeFont glyphs.
	(colorMap notNil and:[lastSourceDepth = sourceForm depth]) ifFalse:
		["Set up color map for a different source depth (color font)"
		"Note this may need some caching for reasonable efficiency"
		colorMap _ (Color cachedColormapFrom: sourceForm depth to: destForm depth) copy.
		colorMap at: 1 put: (backgroundColor pixelValueForDepth: destForm depth)].
	sourceForm depth = 1 ifTrue:
		[colorMap at: 2 put: (foregroundColor pixelValueForDepth: destForm depth).
		"Ignore any halftone pattern since we use a color map approach here"
		halftoneForm _ nil].
	sourceY _ 0.
	height _ aStrikeFont height.
! !

!BitBlt methodsFor: 'private'!
paintBits
	"Perform the paint operation, which requires two calls to BitBlt."
	| color oldMap saveRule |
	sourceForm depth = 1 ifFalse: 
		[^ self halt: 'paint operation is only defined for 1-bit deep sourceForms'].
	saveRule _ combinationRule.
	color _ halftoneForm.  halftoneForm _ nil.
	oldMap _ colorMap.
	"Map 1's to ALL ones, not just one"
	self colorMap: (Bitmap with: 0 with: 16rFFFFFFFF).
	combinationRule _ Form erase.
	self copyBits. 		"Erase the dest wherever the source is 1"
	halftoneForm _ color.
	combinationRule _ Form under.
	self copyBits.	"then OR, with whatever color, into the hole"
	colorMap _ oldMap.
	combinationRule _ saveRule

" | dot |
dot _ Form dotOfSize: 32.
((BitBlt destForm: Display
		sourceForm: dot
		fillColor: Color lightGray
		combinationRule: Form paint
		destOrigin: Sensor cursorPoint
		sourceOrigin: 0@0
		extent: dot extent
		clipRect: Display boundingBox)
		colorMap: (Bitmap with: 0 with: 16rFFFFFFFF)) copyBits"! !

!BitBlt methodsFor: 'private' stamp: 'ar 5/18/2000 21:49'!
primDisplayString: aString from: startIndex to: stopIndex map: glyphMap xTable: xTable kern: kernDelta
	| ascii glyph |
	<primitive:'primitiveDisplayString' module:'BitBltPlugin'>
	startIndex to: stopIndex do:[:charIndex|
		ascii _ (aString at: charIndex) asciiValue.
		glyph _ glyphMap at: ascii + 1.
		sourceX _ xTable at: glyph + 1.
		width _ (xTable at: glyph + 2) - sourceX.
		self copyBits.
		destX _ destX + width + kernDelta.
	].! !

!BitBlt methodsFor: 'private'!
setDestForm: df
	| bb |
	bb _ df boundingBox.
	destForm _ df.
	clipX _ bb left.
	clipY _ bb top.
	clipWidth _ bb width.
	clipHeight _ bb height! !

!BitBlt methodsFor: 'private' stamp: 'di 9/11/1998 13:07'!
setDestForm: df sourceForm: sf fillColor: hf combinationRule: cr destOrigin: destOrigin sourceOrigin: sourceOrigin extent: extent clipRect: clipRect

	| aPoint |
	destForm _ df.
	sourceForm _ sf.
	self fillColor: hf.	"sets halftoneForm"
	combinationRule _ cr.
	destX _ destOrigin x.
	destY _ destOrigin y.
	sourceX _ sourceOrigin x.
	sourceY _ sourceOrigin y.
	width _ extent x.
	height _ extent y.
	aPoint _ clipRect origin.
	clipX _ aPoint x.
	clipY _ aPoint y.
	aPoint _ clipRect corner.
	clipWidth _ aPoint x - clipX.
	clipHeight _ aPoint y - clipY.
	sourceForm == nil ifFalse:
		[colorMap _ sourceForm colormapIfNeededForDepth: destForm depth]! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BitBlt class
	instanceVariableNames: ''!

!BitBlt class methodsFor: 'instance creation' stamp: 'di 3/2/98 12:53'!
bitPeekerFromForm: sourceForm
	"Answer an instance to be used extract individual pixels from the given Form. The destination for a 1x1 copyBits will be the low order bits of (bits at: 1)."
	| pixPerWord |
	pixPerWord _ 32 // sourceForm depth.
	sourceForm unhibernate.
	^ self destForm: (Form extent: pixPerWord@1 depth: sourceForm depth)
	 	sourceForm: sourceForm
		halftoneForm: nil
		combinationRule: Form over
		destOrigin: (pixPerWord - 1)@0
		sourceOrigin: 0@0
		extent: 1@1
		clipRect: (0@0 extent: pixPerWord@1)
! !

!BitBlt class methodsFor: 'instance creation' stamp: 'di 3/2/98 12:53'!
bitPokerToForm: destForm
	"Answer an instance to be used for valueAt: aPoint put: pixValue.
	The source for a 1x1 copyBits will be the low order of (bits at: 1)"
	| pixPerWord |
	pixPerWord _ 32//destForm depth.
	destForm unhibernate.
	^ self destForm: destForm
	 	sourceForm: (Form extent: pixPerWord@1 depth: destForm depth)
		halftoneForm: nil combinationRule: Form over
		destOrigin: 0@0 sourceOrigin: (pixPerWord-1)@0
		extent: 1@1 clipRect: (0@0 extent: destForm extent)
! !

!BitBlt class methodsFor: 'instance creation'!
destForm: df sourceForm: sf fillColor: hf combinationRule: cr destOrigin: destOrigin sourceOrigin: sourceOrigin extent: extent clipRect: clipRect 
	"Answer an instance of me with values set according to the arguments."

	^ self new
		setDestForm: df
		sourceForm: sf
		fillColor: hf
		combinationRule: cr
		destOrigin: destOrigin
		sourceOrigin: sourceOrigin
		extent: extent
		clipRect: clipRect! !

!BitBlt class methodsFor: 'instance creation'!
destForm: df sourceForm: sf halftoneForm: hf combinationRule: cr destOrigin: destOrigin sourceOrigin: sourceOrigin extent: extent clipRect: clipRect 
	"Answer an instance of me with values set according to the arguments."

	^ self new
		setDestForm: df
		sourceForm: sf
		fillColor: hf
		combinationRule: cr
		destOrigin: destOrigin
		sourceOrigin: sourceOrigin
		extent: extent
		clipRect: clipRect! !

!BitBlt class methodsFor: 'instance creation'!
toForm: aForm
	^ self new setDestForm: aForm! !


!BitBlt class methodsFor: 'examples' stamp: 'di 12/1/97 12:08'!
alphaBlendDemo
	"To run this demo, use...
		Display restoreAfter: [BitBlt alphaBlendDemo]	
	Displays 10 alphas, then lets you paint.  Option-Click to stop painting."

	"This code exhibits alpha blending in any display depth by performing
	the blend in an off-screen buffer with 32-bit pixels, and then copying
	the result back onto the screen with an appropriate color map. - tk 3/10/97"
	
	"This version uses a sliding buffer for painting that keeps pixels in 32 bits
	as long as they are in the buffer, so as not to lose info by converting down
	to display resolution and back up to 32 bits at each operation. - di 3/15/97"

	| brush buff dispToBuff buffToDisplay mapDto32 map32toD prevP p brushToBuff theta buffRect buffSize buffToBuff brushRect delta newBuffRect updateRect |  

	"compute color maps if needed"
	Display depth <= 8 ifTrue: [
		mapDto32 _ Color cachedColormapFrom: Display depth to: 32.
		map32toD _ Color cachedColormapFrom: 32 to: Display depth].

	"display 10 different alphas, across top of screen"
	buff _ Form extent: 500@50 depth: 32.
	dispToBuff _ BitBlt toForm: buff.
	dispToBuff colorMap: mapDto32.
	dispToBuff copyFrom: (50@10 extent: 500@50) in: Display to: 0@0.
	1 to: 10 do: [:i | dispToBuff fill: (50*(i-1)@0 extent: 50@50)
						fillColor: (Color red alpha: i/10)
						rule: Form blend].
	buffToDisplay _ BitBlt toForm: Display.
	buffToDisplay colorMap: map32toD.
	buffToDisplay copyFrom: buff boundingBox in: buff to: 50@10.

	"Create a brush with radially varying alpha"
	brush _ Form extent: 30@30 depth: 32.
	1 to: 5 do: 
		[:i | brush fillShape: (Form dotOfSize: brush width*(6-i)//5)
				fillColor: (Color red alpha: 0.02 * i - 0.01)
				at: brush extent // 2].

	"Now paint with the brush using alpha blending."
	buffSize _ 100.
	buff _ Form extent: brush extent + buffSize depth: 32.  "Travelling 32-bit buffer"
	dispToBuff _ BitBlt toForm: buff.  "This is from Display to buff"
	dispToBuff colorMap: mapDto32.
	brushToBuff _ BitBlt toForm: buff.  "This is from brush to buff"
	brushToBuff sourceForm: brush; sourceOrigin: 0@0.
	brushToBuff combinationRule: Form blend.
	buffToBuff _ BitBlt toForm: buff.  "This is for slewing the buffer"

	[Sensor yellowButtonPressed] whileFalse:
		[prevP _ nil.
		buffRect _ Sensor cursorPoint - (buffSize // 2) extent: buff extent.
		dispToBuff copyFrom: buffRect in: Display to: 0@0.
		[Sensor redButtonPressed] whileTrue:
			["Here is the painting loop"
			p _ Sensor cursorPoint - (brush extent // 2).
			(prevP == nil or: [prevP ~= p]) ifTrue:
				[prevP == nil ifTrue: [prevP _ p].
				(p dist: prevP) > buffSize ifTrue:
					["Stroke too long to fit in buffer -- clip to buffer,
						and next time through will do more of it"
					theta _ (p-prevP) theta.
					p _ ((theta cos@theta sin) * buffSize asFloat + prevP) truncated].
				brushRect _ p extent: brush extent.
				(buffRect containsRect: brushRect) ifFalse:
					["Brush is out of buffer region.  Scroll the buffer,
						and fill vacated regions from the display"
					delta _ brushRect amountToTranslateWithin: buffRect.
					buffToBuff copyFrom: buff boundingBox in: buff to: delta.
					newBuffRect _ buffRect translateBy: delta negated.
					(newBuffRect areasOutside: buffRect) do:
						[:r | dispToBuff copyFrom: r in: Display to: r origin - newBuffRect origin].
					buffRect _ newBuffRect].

				"Interpolate from prevP to p..."
				brushToBuff drawFrom: prevP - buffRect origin
									to: p - buffRect origin
									withFirstPoint: false.

				"Update (only) the altered pixels of the destination"
				updateRect _ (p min: prevP) corner: (p max: prevP) + brush extent.
				buffToDisplay copy: updateRect from: updateRect origin - buffRect origin in: buff.
				prevP _ p]]]! !

!BitBlt class methodsFor: 'examples' stamp: 'di 12/1/97 12:09'!
antiAliasDemo 
	"To run this demo, use...
		Display restoreAfter: [BitBlt antiAliasDemo]
	Goes immediately into on-screen paint mode.  Option-Click to stop painting."

	"This code exhibits alpha blending in any display depth by performing
	the blend in an off-screen buffer with 32-bit pixels, and then copying
	the result back onto the screen with an appropriate color map. - tk 3/10/97"
	
	"This version uses a sliding buffer for painting that keeps pixels in 32 bits
	as long as they are in the buffer, so as not to lose info by converting down
	to display resolution and back up to 32 bits at each operation. - di 3/15/97"
	
	"This version also uses WarpBlt to paint into twice as large a buffer,
	and then use smoothing when reducing back down to the display.
	In fact this same routine will now work for 3x3 soothing as well.
	Remove the statements 'buff displayAt: 0@0' to hide the buffer. - di 3/19/97"

	| brush buff dispToBuff buffToDisplay mapDto32 map32toD prevP p brushToBuff theta buffRect buffSize buffToBuff brushRect delta newBuffRect updateRect scale p0 |  
	"compute color maps if needed"
	Display depth <= 8 ifTrue: [
		mapDto32 _ Color cachedColormapFrom: Display depth to: 32.
		map32toD _ Color cachedColormapFrom: 32 to: Display depth].

	"Create a brush with radially varying alpha"
	brush _ Form extent: 3@3 depth: 32.
	brush fill: brush boundingBox fillColor: (Color red alpha: 0.05).
	brush fill: (1@1 extent: 1@1) fillColor: (Color red alpha: 0.2).

	scale _ 2.  "Actual drawing happens at this magnification"
	"Scale brush up for painting in magnified buffer"
	brush _ brush magnify: brush boundingBox by: scale.

	"Now paint with the brush using alpha blending."
	buffSize _ 100.
	buff _ Form extent: (brush extent + buffSize) * scale depth: 32.  "Travelling 32-bit buffer"
	dispToBuff _ (WarpBlt toForm: buff)  "From Display to buff - magnify by 2"
		sourceForm: Display;
		colorMap: mapDto32;
		combinationRule: Form over.
	brushToBuff _ (BitBlt toForm: buff)  "From brush to buff"
		sourceForm: brush;
		sourceOrigin: 0@0;
		combinationRule: Form blend.
	buffToDisplay _ (WarpBlt toForm: Display)  "From buff to Display - shrink by 2"
		sourceForm: buff;
		colorMap: map32toD;
		cellSize: scale;  "...and use smoothing"
		combinationRule: Form over.
	buffToBuff _ BitBlt toForm: buff.  "This is for slewing the buffer"

	[Sensor yellowButtonPressed] whileFalse:
		[prevP _ nil.
		buffRect _ Sensor cursorPoint - (buff extent // scale // 2) extent: buff extent // scale.
		p0 _ (buff extent // 2) - (buffRect extent // 2).
		dispToBuff copyQuad: buffRect innerCorners toRect: buff boundingBox.
buff displayAt: 0@0.  "** remove to hide sliding buffer **"
		[Sensor redButtonPressed] whileTrue:
			["Here is the painting loop"
			p _ Sensor cursorPoint - buffRect origin + p0.  "p, prevP are rel to buff origin"
			(prevP == nil or: [prevP ~= p]) ifTrue:
				[prevP == nil ifTrue: [prevP _ p].
				(p dist: prevP) > (buffSize-1) ifTrue:
					["Stroke too long to fit in buffer -- clip to buffer,
						and next time through will do more of it"
					theta _ (p-prevP) theta.
					p _ ((theta cos@theta sin) * (buffSize-2) asFloat + prevP) truncated].
				brushRect _ p extent: brush extent.
				((buff boundingBox insetBy: scale) containsRect: brushRect) ifFalse:
					["Brush is out of buffer region.  Scroll the buffer,
						and fill vacated regions from the display"
					delta _ (brushRect amountToTranslateWithin: (buff boundingBox insetBy: scale)) // scale.
					buffToBuff copyFrom: buff boundingBox in: buff to: delta*scale.
					newBuffRect _ buffRect translateBy: delta negated.
					p _ p translateBy: delta*scale.
					prevP _ prevP translateBy: delta*scale.
					(newBuffRect areasOutside: buffRect) do:
						[:r | dispToBuff copyQuad: r innerCorners toRect: (r origin - newBuffRect origin*scale extent: r extent*scale)].
					buffRect _ newBuffRect].

				"Interpolate from prevP to p..."
				brushToBuff drawFrom: prevP to: p withFirstPoint: false.
buff displayAt: 0@0.  "** remove to hide sliding buffer **"

				"Update (only) the altered pixels of the destination"
				updateRect _ (p min: prevP) corner: (p max: prevP) + brush extent.
				updateRect _ updateRect origin // scale * scale
						corner: updateRect corner + scale // scale * scale.
				buffToDisplay copyQuad: updateRect innerCorners
							toRect: (updateRect origin // scale + buffRect origin
										extent: updateRect extent // scale).
				prevP _ p]]]! !


!BitBlt class methodsFor: 'benchmarks' stamp: 'jm 2/4/2005 12:28'!
benchmark		"BitBlt benchmark"
	"Run a benchmark on different combinations rules, source/destination depths and BitBlt modes. Note: This benchmark doesn't give you any 'absolute' value - it is intended only for benchmarking improvements in the bitblt code and nothing else.
	Attention: *this*may*take*a*while*"
	| bb source dest destRect log t |
	log _ WriteStream on: String new.
	destRect _ 0@0 extent: 600@600.
	"Form paint/Form over - the most common rules"
	#( 25 3 ) do:[:rule|
		Transcript cr; show:'---- Combination rule: ', rule printString,' ----'.
		log cr; nextPutAll:'---- Combination rule: ', rule printString,' ----'.
		#(1 2 4 8 16 32) do:[:destDepth|
			dest _ nil.
			dest _ Form extent: destRect extent depth: destDepth.
			Transcript cr.
			log cr.
			#(1 2 4 8 16 32) do:[:sourceDepth|
				Transcript cr; show: sourceDepth printString, ' => ', destDepth printString.
				log cr; nextPutAll: sourceDepth printString, ' => ', destDepth printString.
				source _ nil. bb _ nil.
				source _ Form extent: destRect extent depth: sourceDepth.
				(source getCanvas) fillOval: dest boundingBox color: Color yellow borderWidth: 30 borderColor: Color black.
				bb _ WarpBlt toForm: dest.
				bb sourceForm: source.
				bb sourceRect: source boundingBox.
				bb destRect: dest boundingBox.
				bb colorMap: (source colormapIfNeededForDepth: dest depth).
				bb combinationRule: rule.

				"Measure speed of copyBits"
				t _ Time millisecondsToRun:[bb copyBits].
				Transcript tab; show: t printString.
				log tab; nextPutAll: t printString.

				bb sourceForm: source.
				bb sourceQuad: source boundingBox innerCorners destRect: source boundingBox.

				"Measure speed of 1x1 warpBits"
				bb cellSize: 1.
				t _ Time millisecondsToRun:[bb warpBits].
				Transcript tab; show: t printString.
				log tab; nextPutAll: t printString.

				"Measure speed of 2x2 warpBits"
				bb cellSize: 2.
				t _ Time millisecondsToRun:[bb warpBits].
				Transcript tab; show: t printString.
				log tab; nextPutAll: t printString.

				"Measure speed of 3x3 warpBits"
				bb cellSize: 3.
				t _ Time millisecondsToRun:[bb warpBits].
				Transcript tab; show: t printString.
				log tab; nextPutAll: t printString.
			].
		].
	].
	^log contents! !
