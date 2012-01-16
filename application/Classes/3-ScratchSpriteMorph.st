ScriptableScratchMorph subclass: #ScratchSpriteMorph
	instanceVariableNames: 'scalePoint rotationDegrees rotationStyle rotatedForm offsetWhenRotated draggable penDown penSize penColor penHue penShade penGhosting fillColor fillHue fillShade fillGhosting subsprites ownerSprite offset virtualScale rotateWithOwner refPos prototype pointsList moving fontName fontSize fontColor fontHue fontShade fontGhosting '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Scratch-Objects'!
!ScratchSpriteMorph commentStamp: '<historical>' prior: 0!
I represent a programmable Scratch object.

I have a costume, a bitmapped image that can be rotated, scaled, and image-filtered.

The raw Form before any rotation or scaling is stored in originalForm. rotatedForm is a cache of the rotated and scaled version of originalForm.

rotationStyle has three possible values:
	normal		continuous rotation with direction
	leftRight	for directions with x component < 0, flip the bitmap around the y-axis, otherwise no rotation
	none		don't rotate with direction

The leftRight style is useful for side-views of things such as cars, horses, etc.
!


!ScratchSpriteMorph methodsFor: 'initialization' stamp: 'JM 1/16/2012 15:09'!
initialize

	super initialize.
	subsprites _ OrderedCollection new.
	scalePoint _ 1.0@1.0.
	rotationDegrees _ 0.0.				"clockwise angle of rotation"
	rotationStyle _ #normal.				"#normal, #leftRight, or #none"
	rotatedForm _ self costumeForm.		"cached rotated/scaled copy of costume form"
	offsetWhenRotated _ 0@0.			"offset for rotated form needed to keep rotation center invariant"
	draggable _ false.
	penDown _ false.
	penSize _ 2.
	"penHue _ 133.3.
	penShade _ 50."
	penGhosting _ 0.
	"fillHue _ 133.3.
	fillShade _ 50."
	fillGhosting _ 0.
	fontGhosting _ 0.

	self penColor: Color black.
	self fillColor:  (Color r: 0.188 g: 0.435 b: 0.69).
	self fontColor: Color black.
	self fontName: #Aardvark.
	self setFontSize: 12.

	pointsList _ nil.		
	self extent: rotatedForm extent.

	moving _ false.
! !


!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 8/7/2008 13:16'!
defaultImageMedia

	^ ImageMedia new
		form: (Form extent: 8@8 depth: 8) fillWhite;
		mediaName: ('costume' localized, '1')
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 10/19/2007 11:35'!
draggable

	draggable ifNil: [draggable _ true].
	^ draggable
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 2/14/2011 20:07'!
draggable: aBoolean

	self undeleteAttribute: #isDraggable.
	self passiveSetDraggable: aBoolean
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 2/4/2011 00:40'!
heading
	"Answer my heading in degrees, a number between -180 and 180."

	| result att |
	att _ #heading.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	result _ rotationDegrees + 90.
	result > 180 ifTrue: [result _ result - 360].
	^ result

! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 2/4/2011 02:19'!
heading: headingDegrees
	"Set my heading in degrees, where 0 degrees is facing up and the heading increases clockwise."
	"Note: Our convention is that artwork is drawing facing to the right. Thus, a heading of 90 corresponds to a rotationDegrees of zero."

	self turn: headingDegrees asNumberNoError - self heading
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 5/10/2004 19:37'!
isClone: aBoolean

	isClone _ aBoolean.
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 4/30/2004 19:05'!
isPaintable
	"Answer true if my image can be repainted."

	^ true
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 5/6/2004 19:49'!
isRotatable
	"Answer true if my image can be rotated."

	^ true
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 7/3/2008 15:14'!
isSprite

	^ true
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 11/18/2008 17:35'!
position: aPoint

"	self halt."
	super position: aPoint.! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 5/8/2009 12:11'!
referencePosition

	| p s |
	p _ (bounds origin + offsetWhenRotated) - ScratchOrigin.

	"adjust when in Hand in quartersize mode:"
	((owner isKindOf: HandMorph) and:
	 [((s _ owner formerOwner) isKindOf: ScratchStageMorph) and:
	 [s isQuarterSize]]) ifTrue: [
		"Note: this is not quite right when rotation center is offset"
		p _ (p * 2) + (240@180)].

	^ p x @ p y negated
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'JM 11/17/2011 10:19'!
referencePosition: aPoint
	"Set my reference position. Avoid infinite or NaN coordinates. Keep on screen."

	| newX newY p |
	newX _ aPoint x.
	newX isNaN ifTrue: [newX _ 0].
	newX isInf ifTrue: [newX _ newX sign * 10000].
	newY _ aPoint y.
	newY isNaN ifTrue: [newY _ 0].
	newY isInf ifTrue: [newY _ newY sign * 10000].

	p _ newX @ newY negated.
	self position: ScratchOrigin + (p - offsetWhenRotated).
	self keepOnScreen.

	moving ifFalse: [ self updatePointsList ].! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 6/2/2004 19:17'!
rotatedForm
	"Answer my rotated and scaled form."

	rotatedForm ifNil: [self costumeChanged].
	^ rotatedForm
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 5/3/2004 20:21'!
rotationCenter

	^ costume rotationCenter
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 4/30/2004 19:05'!
rotationDegrees

	^ rotationDegrees
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 12/1/2006 11:27'!
rotationDegrees: newRotationDegrees

	rotationDegrees ~= newRotationDegrees ifTrue: [
		rotationDegrees _ newRotationDegrees asFloat \\ 360.0.
		(rotationStyle = #none) ifFalse: [
			self positionTalkBubble.
			self costumeChanged]].
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 4/30/2004 19:05'!
rotationStyle

	^ rotationStyle
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 12/1/2006 11:30'!
rotationStyle: aSymbol
	"Set my rotation style to #normal, #leftRight, or #none. Styles mean:
		#normal	-- smooth 360 degree rotation
		#leftRight	-- flip about the vertical axis
		#none		-- do not rotate"

	rotationStyle _ aSymbol.
	self costumeChanged.
	self positionTalkBubble.
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 2/8/2011 23:09'!
scale

	| att |
	att _ #size.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^self virtualScale rounded! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 1/4/2006 14:36'!
scalePoint

	^ scalePoint
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jm 12/1/2006 11:28'!
scalePoint: aPoint

	scalePoint _ aPoint.
	self costumeChanged.
	self positionTalkBubble.
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 7/16/2009 23:39'!
touchingColor: soughtColor
	"Answer true if any of my non-transparent pixels touch pixels of the given color in the world."

	| r myImage sensitivePixelsMask map imageBelowMe result |
	r _ self bounds intersect: owner bounds.
	r area = 0 ifTrue: [^ false].

	"make a mask with 0 where transparent, 1 elsewhere"
	myImage _ self imageForm asFormOfDepth: 16.
	sensitivePixelsMask _ Form extent: myImage extent depth: 1.
	map _ Bitmap new: (1 bitShift: (myImage depth min: 15)).
	map atAllPut: 1.
	map at: (Color transparent indexInMap: map) put: 0.
	sensitivePixelsMask
		copyBits: ((r origin - self position) extent: r extent)
		from: myImage form
		at: 0@0
		colorMap: map.

	"grab an image of the world below me"
	imageBelowMe _ owner patchAt: r withoutWatchersAnd: self andNothingAbove: false.

	"intersect world pixels of the color we're looking for with sensitive pixels mask"
	map atAllPut: 0.  "clear map and reuse it"
	map at: (soughtColor indexInMap: map) put: 1.
	sensitivePixelsMask
		copyBits: imageBelowMe boundingBox
		from: imageBelowMe at: 0@0 clippingBox: imageBelowMe boundingBox
		rule: Form and
		fillColor: nil
		map: map.

	result _ (sensitivePixelsMask tallyPixelValues at: 2) > 0.  "true if any pixels are 1"
	result ifTrue: [^true].
	^(subsprites collect: [:sub | sub touchingColor: soughtColor ]) includes: true.

! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 2/4/2011 02:58'!
xpos

	| att |
	att _ #xPosition.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ self referencePosition x
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 2/8/2011 21:13'!
xpos: aNumber 

	self undeleteAttribute: #xPosition.
	self passiveXpos: aNumber! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 2/4/2011 02:58'!
ypos

	| att |
	att _ #yPosition.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ self referencePosition y
! !

!ScratchSpriteMorph methodsFor: 'accessing' stamp: 'jens 2/8/2011 21:31'!
ypos: aNumber 

	self undeleteAttribute: #yPosition.
	self passiveYpos: aNumber! !


!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:46'!
changeFillGhostingBy: aNumber

	self setFillGhostingTo: fillGhosting + aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:47'!
changeFillHueBy: aNumber
	"Change the fill hue by given number."

	self setFillHueTo: fillHue + aNumber.

! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:48'!
changeFillShadeBy: aNumber
	"Change the fill shade (lightness) by given number"

	self setFillShadeTo: fillShade + aNumber.
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:45'!
changePenGhostingBy: aNumber

	self setPenGhostingTo: penGhosting + aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 4/1/2005 13:31'!
changePenHueBy: aNumber
	"Change the pen hue by given number."

	self setPenHueTo: penHue + aNumber.

! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 4/1/2005 13:33'!
changePenShadeBy: aNumber
	"Change the pen shade (lightness) by given number"

	self setPenShadeTo: penShade + aNumber.
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 3/16/2005 11:31'!
changePenSizeBy: aNumber
	"Change my pen width."

	self penSize: penSize + aNumber.
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 8/2/2005 18:52'!
clearPenTrails
	"Clear the pen trails layer."

	| m |
	(m _ self ownerThatIsA: ScratchStageMorph)
		ifNotNil: [m clearPenTrails].
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/14/2011 11:50'!
drawCircle: aRadius

	| stage |

	(stage _	self ownerThatIsA: ScratchStageMorph) ifNil: [ ^ self ].
	^ stage drawCircleFor: self radius: aRadius! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/23/2011 14:53'!
drawOvalWidth: w height: h

	| stage |

	(stage _	self ownerThatIsA: ScratchStageMorph) ifNil: [ ^ self ].
	^ stage drawOvalFor: self width: w height: h! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/16/2011 10:21'!
drawRectangle: aWidth by: aHeight

	| stage |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [ ^ self ].
	stage drawRectangleFor: self width: aWidth height: aHeight.! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 14:05'!
fillColor

	^ fillColor! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:14'!
fillColor: aColor

	"Set my fill color."

	self undeleteAttribute: #fillColor.
	self passiveFillColor: aColor! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jens 2/10/2011 00:22'!
penColor

	^ penColor
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jens 2/9/2011 23:30'!
penColor: aColor
	"Set my pen color."

	self undeleteAttribute: #penColor.
	self passivePenColor: aColor! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jens 2/9/2011 00:30'!
penDown

	| att |
	att _ #penDown.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ penDown
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jens 2/9/2011 01:07'!
penDown: aBoolean

	self undeleteAttribute: #penDown.
	self passivePenDown: aBoolean! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 2/5/2005 10:39'!
penPosition

	^ self referencePosition
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jens 2/9/2011 00:32'!
penSize

	| att |
	att _ #penSize.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ penSize
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jens 2/9/2011 01:12'!
penSize: aNumber
	"Set my pen width."

	self undeleteAttribute: #penSize.
	self passivePenSize: aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 2/5/2005 11:41'!
putPenDown
	"Put down my drawing pen (i.e. start drawing a pen trail)."

	self penDown: true.
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 2/5/2005 11:40'!
putPenUp
	"Put up my drawing pen (i.e. stop drawing a pen trail)."

	self penDown: false.
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:46'!
setFillGhostingTo: aNumber

	self undeleteAttribute: #fillGhosting.
	self passiveFillGhosting: aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:47'!
setFillHueTo: aNumber
	"Set the fill hue to given number between 0 and 200. (That makes 100 the 'maximum' distance away from the original color on the color wheel.)"

	self undeleteAttribute: #fillColor.
	self passiveSetFillHueTo: aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:48'!
setFillShadeTo: aNumber
	"Set the fill shade (lightness) to given number between 0 and 100. A shade of 0 is black, 100 is white, and 50 is fully saturated color."
	"Details: We don't want to get all the way to pure black or white, so we divide the range 0..50 by a number > 50 when computing the fraction of the original color to mix with black or white."

	self undeleteAttribute: #fillShade.
	self passiveSetFillShadeTo: aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 2/10/2008 22:20'!
setPenColorFromCostumedNamed: costumeNameOrIndex x: x y: y
	"Set my pen color from my costume of the given name at the given point. If the point is off the edge, set my color to black."

	| cName m f pixel |
	cName _ costumeNameOrIndex.
	cName isNumber ifTrue: [cName _ self costumeNameFromNumber: costumeNameOrIndex].
	m _ media
		detect: [:el | el isSound not and: [el mediaName caseInsensitiveEqual: cName]]
		ifNone: [^ self].

	f _ m form.
	f unhibernate.
	pixel _ ScratchPlugin
		primInterpolate: f bits
		width: f width
		x: (x * 1024) rounded
		y: ((f height - y) * 1024) rounded.

	pixel = 0
		ifTrue: [self penColor: Color black]
		ifFalse: [self penColor: (Color colorFromPixelValue: pixel depth: 24)].
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/15/2011 13:43'!
setPenGhostingTo: aNumber

	self undeleteAttribute: #penGhosting.
	self passivePenGhosting: aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jens 2/9/2011 01:10'!
setPenHueTo: aNumber
	"Set the pen hue to given number between 0 and 200. (That makes 100 the 'maximum' distance away from the original color on the color wheel.)"

	self undeleteAttribute: #penColor.
	self passiveSetPenHueTo: aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jens 2/9/2011 01:11'!
setPenShadeTo: aNumber
	"Set the pen shade (lightness) to given number between 0 and 100. A shade of 0 is black, 100 is white, and 50 is fully saturated color."
	"Details: We don't want to get all the way to pure black or white, so we divide the range 0..50 by a number > 50 when computing the fraction of the original color to mix with black or white."

	self undeleteAttribute: #penShade.
	self passiveSetPenShadeTo: aNumber! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/17/2011 11:15'!
shapeEnd

	"stop remembering the points visited and draw the polygon"
	| stage |

	pointsList ifNil: [ ^ self ].
	stage _ (self ownerThatIsA: ScratchStageMorph) ifNil: [ ^ self ].
	stage drawPolygonFor: self points: pointsList.
	pointsList _ nil.! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/16/2011 15:49'!
shapeStart

	"begin creating a list of points to construct a polygon"
	pointsList _ OrderedCollection with: self referencePosition.! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'jm 8/2/2005 18:52'!
stampCostume
	"Stamp a copy of my current costume on the pen trails layer."

	| m |
	self step.  "update costume if necessary"
	(m _ self ownerThatIsA: ScratchStageMorph)
		ifNotNil: [m stampCostume: self].
! !

!ScratchSpriteMorph methodsFor: 'pen ops' stamp: 'JM 11/16/2011 15:39'!
updatePointsList

	"add the current location to the points list if necessary"
	pointsList ifNotNil: [ pointsList add: self referencePosition ].
	! !


!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 2/8/2011 22:16'!
bounceOffEdge
	"Set my direction to bounce off the edge."

	| myBox edgeBox dirX dirY |
	owner ifNil: [^ self].
	ownerSprite ifNotNil: [^ self].
	myBox _ self allBounds.
	edgeBox _ owner bounds.
	(edgeBox containsRect: myBox) ifTrue: [^ self].

	dirX _ self rotationDegrees degreesToRadians cos.
	dirY _ self rotationDegrees degreesToRadians sin negated.
	myBox left < edgeBox left ifTrue: [dirX _ dirX abs].
	myBox right > edgeBox right ifTrue: [dirX _ dirX abs negated].
	myBox top < edgeBox top ifTrue: [dirY _ dirY abs negated].
	myBox bottom > edgeBox bottom ifTrue: [dirY _ dirY abs].
	self heading: "rotationDegrees:" (dirY negated asFloat arcTan: dirX) radiansToDegrees + 90.
	self holdSubsprites.
	self position: self position + (myBox amountToTranslateWithin: edgeBox).
	self releaseSubsprites.

	self xpos: self xpos.
	self ypos: self ypos 
! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'JM 11/17/2011 10:15'!
changeXposBy: aNumber
	"Move right by the given amount."

	self xpos: self xpos + aNumber.
"
	self referencePosition: self referencePosition + (aNumber@0).
	self spread
"! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'JM 11/17/2011 10:15'!
changeYposBy: aNumber
	"Move up by the given amount."

	self ypos: self ypos + aNumber.

"
	self referencePosition: self referencePosition + (0@aNumber).
	self spread
"! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 7/16/2009 23:40'!
color: sensitiveColor sees: soughtColor
	"Return true if any of my pixels of sensitiveColor intersect with pixels of soughtColor in the world."

	| r myImage sensitivePixelsMask map index imageBelowMe result |
	r _ self bounds intersect: owner bounds.
	r area = 0 ifTrue: [^ false].

	"make a mask with 1 where pixel = sensitiveColor, 0 elsewhere"
	myImage _ self imageForm asFormOfDepth: 16.
	sensitivePixelsMask _ Form extent: myImage extent depth: 1.
	map _ Bitmap new: (1 bitShift: (myImage depth min: 15)).
	map at: (index _ sensitiveColor indexInMap: map) put: 1.
	sensitivePixelsMask
		copyBits: ((r origin - self position) extent: r extent)
		from: myImage form
		at: 0@0
		colorMap: map.

	"grab an image of the world below me"
	imageBelowMe _ owner patchAt: r without: self andNothingAbove: false.

	"intersect world pixels of the color we're looking for with sensitive pixels mask"
	map at: index put: 0.  "clear map and reuse it"
	map at: (soughtColor indexInMap: map) put: 1.

	sensitivePixelsMask
		copyBits: imageBelowMe boundingBox
		from: imageBelowMe at: 0@0 clippingBox: imageBelowMe boundingBox
		rule: Form and
		fillColor: nil
		map: map.
	result _ (sensitivePixelsMask tallyPixelValues at: 2) > 0.
	result ifTrue: [^true].
	^(subsprites collect: [:sub | sub color: sensitiveColor sees: soughtColor ]) includes: true 

! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jm 6/8/2009 10:09'!
directionMenu
	"Provides a drop-down menu for setting the sprite direction."

	| menu |
	menu _ CustomMenu new.
	#(	('right' 90)
		('left' -90)
		('up' 0)
		('down' 180)
	) do: [:pair |
		menu
			add: '(' asUTF8, pair second printString, ') ', pair first localized
			action: pair second].
	^ menu
! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jm 3/28/2009 20:15'!
distanceTo: anObject
	"Answer the distance to the given sprite."

	| aSpriteOrSymbol |
	aSpriteOrSymbol _ self coerceSpriteArg: anObject.

	aSpriteOrSymbol = #mouse ifTrue: [
		^ ((self mouseX @ self mouseY)  - self referencePosition) r].

	(aSpriteOrSymbol isKindOf: self class) ifFalse: [^ 10000].
	^ (aSpriteOrSymbol referencePosition - self referencePosition) r
! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'JM 11/17/2011 10:15'!
forward: distance
	"Move the object forward (i.e., the direction of its heading) by the given distance.
	Avoid infinite or NaN coordinates"

	| radians deltaP newPos newX newY |
	radians _ rotationDegrees degreesToRadians.
	deltaP _ ((radians cos)@(radians sin)) * distance.
	newPos _ self position + deltaP.
	newX _ newPos x.
	newY _ newPos y.
	newX isNaN ifTrue: [newX _ 0].
	newX isInf ifTrue: [newX _ newX sign * 10000].
	newY isNaN ifTrue: [newY _ 0].
	newY isInf ifTrue: [newY _ newY sign * 10000].
	self holdSubsprites.
	self position: newX @ newY.
	self releaseSubsprites.
	self keepOnScreen.

	moving _ true.
	self xpos: self xpos.
	self ypos: self ypos.
	moving _ false.

	self updatePointsList.
! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 2/8/2011 22:05'!
glideSecs: duration toX: endX y: endY elapsed: elapsed from: startPoint
	"Interpolate my position from my current postion to the given x and y over the given duration. If startPoint is nil, just answer my current position; this sets the starting point for the interpolation."

	| fraction endPoint rPos |
	startPoint ifNil: [
		^ self referencePosition].
	endPoint _ endX@endY.
	duration < 0.001
		ifTrue: [fraction _ 1]
		ifFalse: [fraction _ elapsed asFloat / (1000.0 * duration)].
	fraction > 1.0 ifTrue: [fraction _ 1].
	fraction < 0.0 ifTrue: [fraction _ 0].
	rPos _ startPoint + (fraction * (endPoint - startPoint)) truncated.
	self gotoX: rPos x y: rPos y 


"
	| fraction endPoint |
	startPoint ifNil: [
		self holdSubsprites. 
		^ self referencePosition].
	endPoint _ endX@endY.
	duration < 0.001
		ifTrue: [fraction _ 1]
		ifFalse: [fraction _ elapsed asFloat / (1000.0 * duration)].
	fraction > 1.0 ifTrue: [fraction _ 1].
	fraction < 0.0 ifTrue: [fraction _ 0].
	self referencePosition: startPoint + (fraction * (endPoint - startPoint)) truncated.

	(self referencePosition = endPoint) ifTrue: [
		self releaseSubsprites]

"! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'JM 11/22/2011 13:47'!
gotoRandomLocation

	self gotoX: (self randomFrom: -240 to: 240) y: (self randomFrom: -180 to: 180)! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 4/28/2010 22:42'!
gotoSpriteOrMouse: anObject
	"Go to the given sprite or mouse position."

	| x y len aSpriteOrSymbol p |
	(anObject isKindOf: ScratchListMorph) ifTrue: [ "try to go the coordinates specified in a list"
		x _ self xpos.
		y _ self ypos.
		len _ anObject lineCount.
		len > 0 ifTrue: [
			x _ (anObject lineAt: 1) asNumberNoError.
			len > 1 ifTrue: [
				y _ (anObject lineAt: 2) asNumberNoError]].
			self gotoX: x y: y].

	aSpriteOrSymbol _ self coerceSpriteArg: anObject.

	aSpriteOrSymbol = #mouse ifTrue: [^ self gotoX: self mouseX y: self mouseY].
	(aSpriteOrSymbol isKindOf: self class) ifFalse: [^ self].
	p _ aSpriteOrSymbol referencePosition.
	self gotoX: p x y: p y.

! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'JM 11/17/2011 10:22'!
gotoX: x y: y

	moving _ true.
	self xpos: x; ypos: y.
	moving _ false.
	self updatePointsList.

"
	self holdSubsprites.
	offset ifNotNil: [
		offset _ offset + (x@y - self referencePosition) ].
	self referencePosition: x@y.
	self releaseSubsprites.
"! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jm 10/12/2005 22:08'!
gotoX: endX y: endY duration: duration elapsed: elapsed from: startPoint
	"Interpolate my position from startPoint to endPoint over the given duration. If startPoint is nil, just answer my current position; this sets the starting point for the interpolation."

	| fraction endPoint |
	startPoint ifNil: [^ self referencePosition].
	endPoint _ endX@endY.
	duration < 0.001
		ifTrue: [fraction _ 1]
		ifFalse: [fraction _ elapsed asFloat / (1000.0 * duration)].
	fraction > 1.0 ifTrue: [fraction _ 1].
	fraction < 0.0 ifTrue: [fraction _ 0].
	self referencePosition: startPoint + (fraction * (endPoint - startPoint)) truncated.
! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jm 5/10/2004 19:40'!
isClone

	^ isClone
! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 7/15/2009 18:21'!
isOnEdge
	"Answer true if I'm touching the edge of my owner."

	| result |
	owner ifNil: [^ false].
	result _ (owner bounds containsRect: self bounds) not.
	result ifTrue: [^true]. 
	^(subsprites collect: [:sub | sub isOnEdge ]) includes: true

! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 7/21/2009 17:33'!
pointToX: x y: y
	"Set my heading to point at the given point."

	| delta angle |
	delta _ (x@y) - self referencePosition.
	angle _ (delta x abs < 0.001)
		ifTrue: [
			delta y < 0 ifTrue: [90] ifFalse: [270]]
		ifFalse: [
			((delta x >= 0 ifTrue: [0] ifFalse: [180])
				- ((delta y / delta x) arcTan * 57.2957795131)) rounded].

	self heading: angle + 90


"	self rotationDegrees: angle."

! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jm 3/28/2009 20:16'!
pointTowards: anObject
	"Point toward the given sprite."

	| aSpriteOrSymbol p |
	aSpriteOrSymbol _ self coerceSpriteArg: anObject.

	aSpriteOrSymbol = #mouse ifTrue: [^ self pointToX: self mouseX y: self mouseY].
	(aSpriteOrSymbol isKindOf: self class) ifFalse: [^ self].
	p _ aSpriteOrSymbol referencePosition.
	self pointToX: p x y: p y.

! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 7/15/2009 18:16'!
touching: anObject
	"Answer true if any visible part of me touches a visible part of the given sprite."
	"Details: Currently uses the bounding box; should follow this up with comparison of visible pixels."

	| aSpriteOrSymbol stage intersection f1 f2 map oldVis result |
	aSpriteOrSymbol _ self coerceSpriteArg: anObject.

	aSpriteOrSymbol = #mouse ifTrue: [
		(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ false].
		result _ self containsPoint: stage adjustedCursorPoint.
			result ifTrue: [^true].
	^(subsprites collect: [:sub | sub touching: anObject ]) includes: true ].

	aSpriteOrSymbol = #edge ifTrue: [^ self isOnEdge].

	(aSpriteOrSymbol isKindOf: self class) ifFalse: [^ false].

	(self isHidden not and: [aSpriteOrSymbol isHidden not]) ifFalse: [
		((subsprites collect: [:sub | sub touching: anObject ]) includes: true)
			ifFalse: [^ false]].

	intersection _ self bounds intersect: aSpriteOrSymbol bounds.
	(intersection width > 0 and: [intersection height > 0]) ifFalse: [
		((subsprites collect: [:sub | sub touching: anObject ]) includes: true)
			ifFalse: [^ false]].

	f1 _ Form extent: intersection extent depth: 2.
	f2 _ f1 deepCopy.
	oldVis _ self visibility. self visibility: 100.
	self drawOn: ((FormCanvas on: f1) copyOffset: intersection topLeft negated).
	self visibility: oldVis.

	oldVis _ aSpriteOrSymbol visibility. aSpriteOrSymbol visibility: 100.	
	aSpriteOrSymbol drawOn: ((FormCanvas on: f2) copyOffset: intersection topLeft negated).
	aSpriteOrSymbol visibility: oldVis.

	map _ Bitmap new: 4 withAll: 1.
	map at: 1 put: 0.  "transparent"
	f1 copyBits: f1 boundingBox from: f1 at: 0@0 colorMap: map.	"make mask with 0 where transparent, 1 elsewhere"
	f2 copyBits: f2 boundingBox from: f2 at: 0@0 colorMap: map.	"ditto for other sprite image"
	f2 displayOn: f1 at: 0@0 rule: Form and.						"and the masks together"

	result _ (f1 tallyPixelValues at: 1) < (f1 width * f1 height).
	result ifTrue: [^true].
	^(subsprites collect: [:sub | sub touching: anObject ]) includes: true 			"are any pixels of the result non-zero?"
! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 2/8/2011 20:29'!
turn: degrees
	"Turn clockwise the given number of degrees."

	self undeleteAttribute: #heading.
	self passiveTurn: degrees! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jm 12/2/2005 14:03'!
turnAwayFromEdge
	"Turn away from the nearest edge."

	| dirX dirY refP delta |
	dirX _ self rotationDegrees degreesToRadians cos.
	dirY _ self rotationDegrees degreesToRadians sin negated.
	refP _ self referencePosition.
	delta _ (ScratchFrameMorph workpaneExtent // 2) - refP abs.

	(delta x < delta y) | (delta x < 0) ifTrue: [  "point dirX towards center"
		dirX = 0.0 ifTrue: [dirX _ 0.1].
		refP x > 0
			ifTrue: [dirX _ dirX abs negated]
			ifFalse: [dirX _ dirX abs]].
	(delta y < delta x) | (delta y < 0) ifTrue: [  "point dirY towards center"
		dirY = 0.0 ifTrue: [dirY _ 0.1].
		refP y > 0
			ifTrue: [dirY _ dirY abs negated]
			ifFalse: [dirY _ dirY abs]].

	self rotationDegrees: (dirY negated asFloat arcTan: dirX) radiansToDegrees.
! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 7/23/2009 00:02'!
turnLeft: degrees
	"Turn counter-clockwise the given number of degrees."

	| newPos |
	self rotationDegrees: rotationDegrees - degrees.

	subsprites do: [:sub |
		newPos _ sub referencePosition rotateBy: degrees negated degreesToRadians about: self referencePosition.
		sub gotoX: newPos x y: newPos y ].
	self rotateWithOwner
		ifTrue: [ self spreadToFollowers ]

! !

!ScratchSpriteMorph methodsFor: 'motion ops' stamp: 'jens 7/23/2009 00:02'!
turnRight: degrees
	| newPos |
	"Turn clockwise the given number of degrees."

	self rotationDegrees: rotationDegrees + degrees.

	subsprites do: [:sub |
		newPos _ sub referencePosition rotateBy: degrees degreesToRadians about: self referencePosition.
		sub gotoX: newPos x y: newPos y ].
	self rotateWithOwner
		ifTrue: [ self spreadToFollowers ]

! !


!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jens 1/20/2011 21:51'!
bubble: obj thinkFlag: thinkFlag promptFlag: promptFlag
	"Make a talk bubble with the given string."

	| s talkBubble objToShow |
	self sayNothing.

	(obj respondsTo: #morphToShow)
		ifTrue: [objToShow _ obj morphToShow]
		ifFalse: [objToShow _ obj].

	obj isNumber
		ifTrue: [
			obj isInteger
				ifTrue: [s _ objToShow printString]
				ifFalse: [s _ (objToShow asFloat roundTo: 0.01) printString]]
		ifFalse: [(objToShow isKindOf: Boolean)
			ifTrue: [s _ objToShow asString localized]
			ifFalse: [ (objToShow isKindOf: Morph) ifFalse: [
				s _ objToShow asString]]].
	(s isKindOf: String)
		ifTrue: [
			(s skipDelimiters: ' 	' startingAt: 1) > s size ifTrue: [^ self].
			s size < 5 ifTrue: [s _ s, ' ']]
		ifFalse: [ (objToShow respondsTo: #thumbnailImageForm)
			ifTrue: [s _ ImageMorph new form: objToShow thumbnailImageForm]
			ifFalse: [s _ ImageMorph new form: objToShow imageForm ]].

	talkBubble _ ScratchTalkBubbleMorph new message: s.
	thinkFlag ifTrue: [talkBubble beThoughtBubble: true].
	promptFlag ifTrue: [talkBubble bePrompt: true].
	talkBubble lock; position: self position.
	self setProperty: #talkBubble toValue: talkBubble.
	self addMorphFront: talkBubble.
	self positionTalkBubble.
	World displayWorldSafely.
	^ talkBubble
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jens 7/16/2009 16:33'!
changeSizeBy: delta
	"Change my size by the given delta."

	self setSizeTo: (self virtualScale + delta).
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jm 12/1/2006 11:23'!
changeStretchBy: delta
	"Change my aspect ratio by the given amount."

	| currentStretch |
	currentStretch _ (100.0 * scalePoint x) / scalePoint y.
	self setStretchTo: (currentStretch + delta).
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jens 2/9/2011 16:36'!
goBackByLayers: aNumber
	"Decrease my layer by (i.e., move me towards the back by) the given number of layers."

	self setLayerTo: self layer + aNumber truncated

	"
	owner ifNil: [^ self spread].
	self layer: (owner submorphs indexOf: self) + aNumber truncated.
	self spread
	"! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jens 2/9/2011 16:16'!
hide
	"Make myself invisible."

	self setHideFlagTo: true

"
	self isHidden: true.
	self spread
"! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jm 5/10/2004 16:54'!
layer: aNumber

	| n submorphsMinusMe newSubmorphs |
	owner ifNil: [^ 1].
	n _ (aNumber rounded max: 1) min: owner submorphCount.
	submorphsMinusMe _ owner submorphs copyWithout: self.
	newSubmorphs _
		(submorphsMinusMe copyFrom: 1 to: (n - 1 min: submorphsMinusMe size)),
		(Array with: self),
		(submorphsMinusMe copyFrom: n to: submorphsMinusMe size).
	owner privateSubmorphs: newSubmorphs.
	self changed.
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jens 3/15/2011 00:01'!
lookLike: costumeName

	self undeleteAttribute: #costumeIndex.
	self passiveLookLike: costumeName.
	costumeName isNumber ifFalse: [
		self lookLike: self costumeIndex ].! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jm 12/1/2006 11:22'!
multiplySizeBy: factor
	"Used by the magnifying glass tool. Multiply my scale by the given factor."

	self setSizeTo: 100.0 * (self scalePoint x max: self scalePoint y) * factor.
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'nb 1/7/2008 13:00'!
recordScene: sceneName

	| state |
	self isHidden ifTrue: [
		sceneStates removeKey: sceneName ifAbsent: [].
		^ self ].

	state _ Dictionary new.
	state at: #referencePosition put: self referencePosition.
	state at: #size put: self scale.
	state at: #heading put: self heading.
	sceneStates at: sceneName put: state.
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'ee 3/1/2009 12:30'!
say: aValue
	"Present a talk bubble with the given string."

	self bubble: aValue thinkFlag: false promptFlag: false.
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jm 12/1/2006 19:21'!
say: stringOrNum duration: durationSecs elapsed: elapsedMSecs from: startPoint

	startPoint ifNil: [^ self say: stringOrNum].  "first call, show talk bubble"
	elapsedMSecs >= (1000 * durationSecs) ifTrue: [self sayNothing].  "clear bubble"
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jm 4/30/2004 19:05'!
sayNothing
	"Delete my talk bubble if I have one."

	| talkBubble |
	(talkBubble _ self valueOfProperty: #talkBubble) ifNil: [^ self].
	talkBubble delete.
	self setProperty: #talkBubble toValue: nil.
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'nb 1/7/2008 12:20'!
scenes

	^ sceneStates keys
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'nb 1/7/2008 14:07'!
setScene: sceneName

	| sceneState |
	sceneState _ sceneStates at: sceneName ifAbsent: [^ self hide].
	self show.
	self referencePosition: (sceneState at: #referencePosition).
	self setSizeTo: (sceneState at: #size).
	self heading: (sceneState at: #heading).
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jens 2/8/2011 23:17'!
setSizeTo: percent
	"Set my size to the given percent of the original size. Limit the range to avoid accidentally making me invisibly tiny or really huge. Retain my aspect ratio (i.e., my stretch)."

	self undeleteAttribute: #size.
	self passiveSetSizeTo: percent
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jm 12/1/2006 11:29'!
setStretchTo: percent
	"Set x stretch percent relative to y. For example, a stretch of 200 stretches x by a factor of two relative to y while a stretch of 50 compresses x by a factor of two. As my stretch is changed, my x scale changes but my y scale remains the same."

	| baseScale origExtent minStretch maxStretch newStretchFactor |
	baseScale _ scalePoint y.
	origExtent _ self costumeForm extent.
	minStretch _ 8.0 / (baseScale * origExtent x).  "min width 8 pixels"
	maxStretch _ 500.0 / (baseScale * origExtent x). "max width 500 pixels"
	newStretchFactor _ ((percent max: 0) / 100.0) within: minStretch and: maxStretch.
	self scalePoint: baseScale * (newStretchFactor @ 1.0).
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jens 2/9/2011 16:16'!
show
	"Make myself visible."

	self setHideFlagTo: false

"
	self isHidden: false.
	self spread
"! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'ee 3/1/2009 12:30'!
think: aValue
	"Present a thought bubble with the given string."

	self bubble: aValue thinkFlag: true promptFlag: false.
! !

!ScratchSpriteMorph methodsFor: 'looks ops' stamp: 'jm 12/1/2006 19:21'!
think: stringOrNum duration: durationSecs elapsed: elapsedMSecs from: startPoint

	startPoint ifNil: [^ self think: stringOrNum].  "first call, show think bubble"
	elapsedMSecs >= (1000 * durationSecs) ifTrue: [self sayNothing].  "clear bubble"
! !


!ScratchSpriteMorph methodsFor: 'movie ops' stamp: 'tis 3/2/2007 23:23'!
stopPlaying
	"Reset my transient state, such as pen down."

	super stopPlaying.
	self sayNothing.

! !


!ScratchSpriteMorph methodsFor: 'sensing ops' stamp: 'ee 11/9/2007 14:48'!
attributeNames

	^ #('x position' 'y position' 'direction' 'costume #' 'size' 'volume') collect: [:s | s]
! !

!ScratchSpriteMorph methodsFor: 'sensing ops' stamp: 'jens 1/20/2011 23:38'!
getAttribute: attr
	"Answer the value of my variable or built-in attribute with the given name. Answer zero if I have no attribute or variable with the given name."

	| a |
	(vars includesKey: attr) ifTrue: [^ vars at: attr].
	(self allLocalBlockIds includes: attr) ifTrue: [ ^self lambda: attr ].

	a _ attr localized.
	'x position' localized = a ifTrue: [^ self xpos].
	'y position' localized = a ifTrue: [^ self ypos].
	'direction' localized = a ifTrue: [^ self heading].
	'costume #' localized = a ifTrue: [^ self costumeIndex].
	'size' localized = a ifTrue: [^ self scale].
	'volume' localized = a ifTrue: [^ self volume].
	^ 0
! !

!ScratchSpriteMorph methodsFor: 'sensing ops' stamp: 'jm 2/11/2009 09:57'!
hideQuestion
	"Hide my question prompt."
! !

!ScratchSpriteMorph methodsFor: 'sensing ops' stamp: 'ee 3/1/2009 12:29'!
showQuestion: aString
	"Show the given question prompt."

	self bubble: aString thinkFlag: false promptFlag: true.
! !


!ScratchSpriteMorph methodsFor: 'clone ops' stamp: 'jm 6/6/2008 14:29'!
cloneAndSend: msgName
	"Clone this sprite and send the clone (and only the clone) the given message."

	| frame clone |
	(frame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self].

	clone _ self fullCopy.
	clone objName: objName, ' clone'.
	clone isClone: true.
	clone blocksBin allMorphsDo: [:m |
		(m isKindOf: BlockMorph) ifTrue: [m stop]].

	frame workPane addMorph: clone.
	clone eventReceived: (ScratchEvent new name: msgName asString argument: 0).
! !


!ScratchSpriteMorph methodsFor: 'drawing' stamp: 'jm 1/8/2006 18:42'!
drawOn: aCanvas
	"Draw myself if my visibility is > 0. If my visibility is 1, draw using the normal 'paint' mode. Otherwise, draw using 'alpha' resulting in a partially transparent rendering."

	| f alpha |
	f _ self filteredForm.
	visibility < 100 ifTrue: [
		visibility > 0 ifTrue: [
			alpha _ ((255.0 * visibility) / 100.0) truncated.
			aCanvas paintImage: f at: bounds origin sourceRect: f boundingBox alpha: alpha].
		^ self].

	aCanvas paintImage: f at: bounds origin.
! !

!ScratchSpriteMorph methodsFor: 'drawing' stamp: 'jm 7/9/2008 10:12'!
drawSubmorphsOn: aCanvas
	"Display submorphs back to front, but do not draw and talk/think bubble submorphs."

	submorphs reverseDo: [:m |
		(m isKindOf: ScratchTalkBubbleMorph) ifFalse: [
			aCanvas fullDrawMorph: m]].
! !

!ScratchSpriteMorph methodsFor: 'drawing' stamp: 'jm 7/9/2008 10:12'!
drawTalkBubbleOn: aCanvas
	"Draw and talk/think bubble submorphs."

	submorphs size = 0 ifTrue: [^ self].
	submorphs reverseDo: [:m |
		(m isKindOf: ScratchTalkBubbleMorph) ifTrue: [
			aCanvas fullDrawMorph: m]].
! !


!ScratchSpriteMorph methodsFor: 'geometry' stamp: 'jm 4/30/2004 19:05'!
containsPoint: aPoint

	^ (self bounds containsPoint: aPoint) and:
	  [(self rotatedForm isTransparentAt: aPoint - bounds origin) not]
! !


!ScratchSpriteMorph methodsFor: 'event handling' stamp: 'jens 2/8/2011 22:16'!
justDroppedInto: newOwner event: evt
	
	self releaseSubsprites.
	super justDroppedInto: newOwner event: evt.
	(newOwner isKindOf: ScratchStageMorph) ifTrue: [self positionTalkBubble].

	self xpos: self xpos.
	self ypos: self ypos 

! !

!ScratchSpriteMorph methodsFor: 'event handling' stamp: 'jens 7/17/2009 00:13'!
startDrag: evt
	"This is a drag gesture; pick me up."

	self holdSubsprites.
	super startDrag: evt.
! !


!ScratchSpriteMorph methodsFor: 'right button menu' stamp: 'jens 2/23/2011 22:05'!
grabFromScreen
	"Set my form to be a rectangular portion of the screen."

	| f el |
	(f _ self grabFormFromScreen) ifNil: [^ self].
	el _ ImageMedia new form: f.
	el mediaName: (self unusedMediaNameFromBaseName: 'costume1').
	media addLast: el.
	self lookLike: el mediaName.
	self updateMediaCategory.

	self undeleteAttribute: #costumes.
	self propagateCostumes
! !

!ScratchSpriteMorph methodsFor: 'right button menu' stamp: 'jens 2/22/2011 00:03'!
rightButtonMenu
	"Present the right button menu."

	| menu stage |
	menu _ CustomMenu new.
	menu add: 'grab screen region for new costume' action: #grabFromScreen.
	menu add: 'export this sprite' action: #exportObject.
	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNotNil: [
		(stage scratchServer notNil and: 
		[stage scratchServer sessionInProgress])
			ifTrue: [
				menu add: 'share this sprite' action: #shareObject ]].
	menu addLine.
	menu add: 'duplicate' action: #duplicate.
	menu add: 'clone' action: #spawn.
	menu add: 'delete' action: #undoableDeleteSprite.
	menu addLine.
	menu add: 'resize this sprite' action: #resizeHandle.
	menu add: 'rotate this sprite' action: #rotateHandle.
	self isNested ifTrue: [
		menu addLine ].
	self hasSubsprites ifTrue: [
		menu add: 'detach all subsprites' action: #unhingeAll ].
	ownerSprite ifNotNil: [
		menu add: 'detach from ', self ownerSprite objName action: #unhinge  ].
	menu localize; invokeOn: self.
! !


!ScratchSpriteMorph methodsFor: 'object i/o' stamp: 'JM 12/13/2011 14:30'!
fieldsVersion

	^ 8
! !

!ScratchSpriteMorph methodsFor: 'object i/o' stamp: 'JM 12/13/2011 16:22'!
initFieldsFrom: anObjStream version: classVersion

	super initFieldsFrom: anObjStream version: classVersion.

(customBlocks isKindOf: Boolean) ifTrue: [ self error: 'attempting to initialize a wrong class version']. 

	self initFieldsNamed: #(
		visibility
		scalePoint
		rotationDegrees
		rotationStyle
	) from: anObjStream.

	scalePoint ifNil: [scalePoint _ 1.0@1.0].
	offsetWhenRotated _ 0@0.
	draggable _ false.  "default for old sprites"
	self layoutChanged.

	classVersion = 1 ifTrue: [^ self].

	"fields added in version 2"
	self initFieldsNamed: #(
		volume
		tempoBPM
		draggable
	) from: anObjStream.
	classVersion = 2 ifTrue: [^ self].

	"fields added in version 3"
	self initFieldsNamed: #(
		sceneStates
		lists
	) from: anObjStream.
	lists ifNil: [lists _ Dictionary new].  "work around"
	classVersion = 3 ifTrue: [^ self].

	"fields added in version 4"
	self initFieldsNamed: #(
		virtualScale
		ownerSprite
		subsprites
		rotateWithOwner
		refPos
	) from: anObjStream.

	classVersion = 4 ifTrue: [^ self].
	"fields added in version 5"
	self initFieldsNamed: #(
		prototype
		deletedAttributes
	) from: anObjStream.

	classVersion = 5 ifTrue: [ ^ self ].
	"fields added in version 6"
	"self initFieldsNamed: #(
		penGhosting
	) from: anObjStream."

	classVersion = 6 ifTrue: [ ^ self ].
	"fields added in version 7"
	"self initFieldsNamed: #(
		fillGhosting
		pointsList
	) from: anObjStream."

	classVersion = 7 ifTrue: [ ^ self ].
	"fields added in version 8"
	"self initFieldsNamed: #(
		fillColor
		fontName
		fontSize
		fontColor
		fontGhosting
	) from: anObjStream"
! !

!ScratchSpriteMorph methodsFor: 'object i/o' stamp: 'JM 12/13/2011 16:21'!
storeFieldsOn: anObjStream

	| oldP |
	self sayNothing.  "delete talk bubble before saving"

	"for backward compatability, remove offsetWhenRotated and subtract costume rotationCenter when saving"
	oldP _ self position.
	self position: self position + offsetWhenRotated - costume rotationCenter.

	super storeFieldsOn: anObjStream.
	self storeFieldsNamed: #(
		visibility
		scalePoint
		rotationDegrees
		rotationStyle
		volume
		tempoBPM
		draggable
		sceneStates
		lists
		virtualScale
		ownerSprite
		subsprites
		rotateWithOwner
		refPos
		prototype
		deletedAttributes
		"penGhosting
		fillGhosting
		pointsList"
		"fontName
		fontSize"
	) on: anObjStream.

	self position: oldP.  "restore position"
! !


!ScratchSpriteMorph methodsFor: 'private' stamp: 'jm 10/16/2007 18:21'!
generateRotatedForm
	"Compute my rotatedForm and offsetWhenRotated."

	| adjustedAngle srcForm smoothPix pair |
	rotationStyle = #normal
		ifTrue: [adjustedAngle _ rotationDegrees]  "smooth rotation"
		ifFalse: [adjustedAngle _ 0.0].  "leftRight or none"

	srcForm _ self costumeForm.
	((srcForm width = 1) & (srcForm height = 1))
		ifTrue: [adjustedAngle _ 0.0].  "don't rotate a 1x1 costume"

	((adjustedAngle = 0.0) and: [1.0@1.0 = scalePoint])
		ifTrue: [  "no rotation or scaling; use original"
			rotatedForm _ srcForm.
			offsetWhenRotated _ costume rotationCenter]
		ifFalse: [  "generated rotated and/or scaled form"
			(((adjustedAngle rounded \\ 90) = 0) and:
			 [1.0@1.0 = scalePoint]) ifTrue: [
				^ self rotateByFlipping].
			((scalePoint x < 1.0) or: [scalePoint y < 1.0])
				ifTrue: [smoothPix _ 2]
				ifFalse: [smoothPix _ 1].
			pair _ WarpBlt
				rotate: srcForm
				degrees: adjustedAngle negated
				center: costume rotationCenter
				scaleBy: scalePoint
				smoothing: smoothPix.
			rotatedForm _ pair first.
			offsetWhenRotated _ (costume rotationCenter + pair last) rounded].

	((rotationStyle = #leftRight) and:
	 [(rotationDegrees > 90.0) and: [rotationDegrees < 270.0]]) ifTrue: [
		"headed left; use flipped"
		rotatedForm _ rotatedForm flipBy: #horizontal centerAt: 0@0.
		offsetWhenRotated _ (rotatedForm width - offsetWhenRotated x - 1) @ offsetWhenRotated y].
! !

!ScratchSpriteMorph methodsFor: 'private' stamp: 'jm 8/3/2008 13:13'!
grabFormFromScreen
	"Grab a rectangular portion of the screen selected by the user and trim white pixels from around edges (this assumes the stage is white). If the resulting form is empty, return nil."

	| f f2 |
	f _ Form fromUser.
	f2 _ (Form extent: (f extent + 2) depth: f depth) fillWhite.
	f displayOn: f2 at: 1@1 rule: Form over.
	f2 shapeFill: Color transparent interiorPoint: 0@0.
	f _ f2 trimBordersOfColor: Color transparent.
	(f width = 0) | (f height = 0) ifTrue: [^ nil].

	^ f
! !

!ScratchSpriteMorph methodsFor: 'private' stamp: 'jens 4/28/2010 04:08'!
layoutChanged
	"Update rotatedForm and offsetWhenRotated and compute new bounds."

	| refPoint |
	self changed.
	refPoint _ bounds origin + offsetWhenRotated.
	(rotationStyle == #none and: [scalePoint = (1.0@1.0)])
		ifTrue: [  "zero rotation and scale; use original Form"
			rotatedForm _ self costumeForm. 	
			offsetWhenRotated _ costume rotationCenter]
		ifFalse: [self generateRotatedForm].	"compute the new rotatedForm and offsetWhenRotated"

	bounds _ (refPoint - offsetWhenRotated) extent: rotatedForm extent.
	super layoutChanged.
	self changed.
! !

!ScratchSpriteMorph methodsFor: 'private' stamp: 'jm 11/29/2007 17:17'!
positionTalkBubble

	| bubble stage stageBounds y f r yInset strip x |
	(bubble _ self valueOfProperty: #talkBubble) ifNil: [^ self].
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ self].
	stageBounds _ stage bounds.

	f _ self imageForm.
	r _ f rectangleEnclosingPixelsNotOfColor: Color transparent.
	yInset _ 0.
	((r area = 0) or: [r height < 10])
		ifTrue: [r _ f boundingBox]
		ifFalse: [
			yInset _ (r top max: 0) min: (r height - 10).
			strip _ f copy: ((0@r top) extent: (f width@(10 min: f height))).
			r _ strip rectangleEnclosingPixelsNotOfColor: Color transparent].

	x _ self right - ((f width - r right) min: f width // 2).
	bubble pointLeft: true.
	((x + bubble width) <= stageBounds right) ifFalse: [
		x _ (self left - bubble width) + (r left min: (f width // 2)).
		bubble pointLeft: false].

	y _ (self top + yInset + 10 - bubble height) within: stageBounds top and: (stageBounds bottom - bubble height).
	bubble position: x@y.
	self layoutChanged.
! !

!ScratchSpriteMorph methodsFor: 'private' stamp: 'jm 10/16/2007 19:06'!
rotateByFlipping
	"Compute my rotatedForm and offsetWhenRotated for unscaled rotation by a multiple of 90 degrees."

	| a center srcForm |
	a _ rotationDegrees rounded \\ 360.
	a < 0 ifTrue: [a _ a + 360].
	srcForm _ self costumeForm.
	center _ costume rotationCenter.
	0 = a ifTrue: [
		rotatedForm _ srcForm.
		offsetWhenRotated _ center].
	90 = a ifTrue: [
		rotatedForm _ srcForm rotateBy: #right centerAt: 0@0.
		offsetWhenRotated _ (srcForm height - 1 - center y) @ center x].
	180 = a ifTrue: [
		rotatedForm _ srcForm rotateBy: #pi centerAt: 0@0.
		offsetWhenRotated _ srcForm extent - 1 - center].
	270 = a ifTrue: [
		rotatedForm _ srcForm rotateBy: #left centerAt: 0@0.
		offsetWhenRotated _ center y @ (srcForm width - 1 - center x)].

! !

!ScratchSpriteMorph methodsFor: 'private' stamp: 'jm 6/2/2004 19:17'!
rotationDegrees: newRotationDegrees scalePoint: newScalePoint

	((newRotationDegrees ~= rotationDegrees) or:
	 [scalePoint ~= newScalePoint]) ifTrue: [
		rotationDegrees _ newRotationDegrees asFloat \\ 360.0.
		scalePoint _ newScalePoint.
		self costumeChanged].
! !


!ScratchSpriteMorph methodsFor: 'handle ops' stamp: 'jens 10/27/2008 10:58'!
resizeHandle

	SpriteHandleMorph resize: self! !

!ScratchSpriteMorph methodsFor: 'handle ops' stamp: 'jens 10/27/2008 12:53'!
rotateHandle

	SpriteHandleMorph rotate: self! !


!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/13/2009 22:16'!
addSubsprite: aSprite
	"private"

	subsprites add: aSprite
	! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 4/28/2010 05:01'!
allBounds

	| l t r b |
	l _ ((self allSubsprites add: self; yourself) collect: [:s | s fullBounds left]) min.
	t _ ((self allSubsprites add: self; yourself) collect: [:s | s fullBounds top]) min.
	r _ ((self allSubsprites add: self; yourself) collect: [:s | s fullBounds right]) max.
	b _ ((self allSubsprites add: self; yourself) collect: [:s | s fullBounds bottom]) max.

	^l@t corner: r@b

! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/28/2009 23:56'!
allSubsprites

	| all |
	all _ subsprites copy.
	subsprites do: [: sub |
		all addAll: sub allSubsprites ].
	^ all! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/10/2009 15:39'!
cacheRefPos
	refPos _ self referencePosition.
	self spread! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 3/18/2010 23:16'!
copyForExport
	"Answer a copy of me for exporting."
	"Note: Sprites are always exported in the context of an empty background."

	| objToExport |
	objToExport _ ScratchStageMorph new clearMediaAndCostume.
	objToExport position: owner position.
	customBlocks ifNotNil: [
		customBlocks do: [:eachDef | 
			eachDef isGlobal ifTrue: [
				objToExport
					updateCustomBlockDefinitionId: eachDef id with: eachDef;
					updateLocalId: eachDef id withSpec: eachDef userSpec]]].
	objToExport convertStacksToTuples.
	objToExport addMorph: super copyForExport.
	^ objToExport
! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 9/28/2009 12:34'!
feedbackMorph

	|outline1 outline2 rf stage realPos|
	rf _ self rotatedForm.
	outline1 _ Form extent: (rf extent + (4@4)) depth: 8.
	outline2 _ Form extent: (rf extent + (6@6)) depth: 8.

	(WarpBlt toForm: outline1)
		sourceForm: rf;
		cellSize: 2; 
		combinationRule: Form over;
		copyQuad: rf boundingBox innerCorners toRect: (outline1 boundingBox insetBy: 2).

	outline1 _ outline1
		outlineWidth: 2
		color: (Color yellow mixed: 0.5 with: Color white)
		depth: 8.

	(WarpBlt toForm: outline2)
		sourceForm: rf;
		cellSize: 2; 
		combinationRule: Form over;
		copyQuad: rf boundingBox innerCorners toRect: (outline2 boundingBox insetBy: 3).

	outline2 _ outline2
		outlineWidth: 3
		color: ("Color gray "Color yellow mixed: 0.2 with: Color white)
		depth: 8.

	(WarpBlt toForm: outline2)
		sourceForm: outline1;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: outline1 boundingBox innerCorners toRect: (outline2 boundingBox insetBy: 3).

	stage _ self ownerThatIsA: ScratchStageMorph.
	(stage notNil and: [stage isQuarterSize]) ifTrue: [
		outline2 _ outline2 magnifyBy: 0.5.
		realPos _ stage position + (self position - stage position / 2).
		^ImageMorph new form:  outline2;
			position: realPos - (3 @ 3);
			yourself ].
		

	^ImageMorph new form:  outline2;
		position: self position - (6 @ 6);
		yourself

! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/15/2009 20:55'!
follow
	offset ifNil: [
		offset _ self referencePosition - ownerSprite referencePosition].
	self spread! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/20/2009 00:02'!
followNow
	self step.
	self spread.
! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/15/2009 00:43'!
hasSubsprites
	^subsprites size > 0! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/19/2009 23:33'!
holdSubsprites
	"private"

	subsprites do: [:each | each follow].! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/28/2009 00:04'!
initializeNodes
	ownerSprite _ nil.
	subsprites _ OrderedCollection new.! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/3/2009 21:21'!
isNested
	^self hasSubsprites or: [ownerSprite notNil]! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/17/2009 01:38'!
isOrContains: aSprite

	self == aSprite
		ifTrue: [^ true].
	^ (subsprites collect: [:sub |
		sub isOrContains: aSprite ])
			includes: true! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 2/9/2011 11:06'!
keepOnScreen
	"Make me stick to edge of my owner."

	| edgeBox allBounds |

	self class keepOnStage ifFalse: [^self].

	ownerSprite ifNotNil: [^self].
	owner ifNil: [^ self].
	allBounds _ self allBounds.
	(owner bounds containsRect: allBounds) ifTrue: [^ self].  "entirely on screen"
	edgeBox _ owner bounds insetBy: (18 min: (allBounds width min: allBounds height) // 2).
	(allBounds intersects: edgeBox) ifTrue: [^ self].

	self holdSubsprites.
	allBounds right < edgeBox left ifTrue: [
		self right: edgeBox left - (allBounds right - self right); followNow].
	allBounds left > edgeBox right ifTrue: [
		self left: edgeBox right + (self left - allBounds left); followNow].
	allBounds bottom < edgeBox top ifTrue: [
		self bottom: edgeBox top - (allBounds bottom - self bottom); followNow].
	allBounds top > edgeBox bottom ifTrue: [
		self top: edgeBox bottom + (self top - allBounds top); followNow].
	self releaseSubsprites.

	self passiveXpos: self xpos.
	self passiveYpos: self ypos 

! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 2/10/2011 00:49'!
ownerSprite

	| att |
	att _ #anchor.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ownerSprite! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 2/22/2011 23:14'!
passiveSetRotateWithOwner: aBoolean
	rotateWithOwner _ aBoolean.
	self costumeChanged
! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 3/21/2011 22:02'!
passiveStickTo: aSprite

	(aSprite isKindOf: ScratchSpriteMorph) ifFalse: [
		^ self unhinge].

	(self isOrContains: aSprite) ifTrue: [^self].
	ownerSprite ifNotNil: [
		ownerSprite removeSubsprite: self].
	ownerSprite _ aSprite.
	aSprite addSubsprite: self.
	rotateWithOwner _ true.

	LibraryItemMorph allInstances do: [:each| each updateThumbnail]. "this needs to be changed to something better -jens"

	self propagate: #anchor! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/3/2009 22:54'!
privateOwnerSprite: aSprite

	ownerSprite _ aSprite! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/3/2009 22:53'!
privateSubsprites: anOrderedCollection

	subsprites _ anOrderedCollection! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/16/2009 15:40'!
realScale
	^(100 * scalePoint x)! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/9/2009 23:32'!
refPos
	^refPos! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/9/2009 23:45'!
refPos: aPoint
	refPos _ aPoint! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/17/2009 00:11'!
releaseSubsprites

	self followNow.
	subsprites do: [:each | each stopFollowing].! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/28/2009 23:35'!
removeSubsprite: aSprite
	"private"

	subsprites remove: aSprite ifAbsent: [].
	self makeVisible! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/3/2009 21:37'!
rootSprite

	| current |
	current _ self.
	[current ownerSprite isNil] whileFalse: [
		current _ current ownerSprite].
	^ current! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 2/22/2011 22:51'!
rotateWithOwner

	| att |
	att _ #rotateWithOwner.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^rotateWithOwner ifNil: [
		rotateWithOwner _ true ]! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 2/22/2011 23:08'!
rotateWithOwner: aBoolean

	self undeleteAttribute: #rotateWithOwner.
	self passiveSetRotateWithOwner: aBoolean
! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 2/8/2011 22:17'!
slideBackToFormerSituation: evt

	self holdSubsprites.
	super slideBackToFormerSituation: evt.
	self releaseSubsprites.

	self xpos: self xpos.
	self ypos: self ypos 

! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/6/2009 07:38'!
spread
	"private - apply the method calling me to all subsprites"

	| sel args |
	subsprites isEmpty ifTrue: [^self].
	sel _ thisContext sender method selector.
	args _ OrderedCollection new.
	1 to: thisContext sender method numArgs do: [:idx |
		args add: (thisContext sender tempAt: idx) ].
	subsprites do: [:eachPart |
		args isEmpty
			ifTrue: [ eachPart perform: sel]
			ifFalse: [ eachPart perform: sel withArguments: args asArray]]! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/23/2009 00:01'!
spreadToFollowers
	"private - apply the method calling me to all subsprites who follow my rotation"

	| followers sel args |
	subsprites isEmpty ifTrue: [^self].
	followers _ subsprites select: [:each |
		each rotateWithOwner ].
	followers isEmpty ifTrue: [ ^self ].
	sel _ thisContext sender method selector.
	args _ OrderedCollection new.
	1 to: thisContext sender method numArgs do: [:idx |
		args add: (thisContext sender tempAt: idx) ].
	followers do: [:eachPart |
		args isEmpty
			ifTrue: [ eachPart perform: sel]
			ifFalse: [ eachPart perform: sel withArguments: args asArray]]! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 2/10/2011 00:51'!
stickTo: aSprite

	self undeleteAttribute: #anchor.
	self passiveStickTo: aSprite! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/17/2009 00:13'!
stopFollowing

	offset _ nil.
	self spread! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/15/2009 01:17'!
subsprites
	^subsprites! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/28/2009 23:10'!
toggleRotationRule

	rotateWithOwner _ self rotateWithOwner not! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 3/21/2011 22:04'!
unhinge

	(ownerSprite isKindOf: ScratchSpriteMorph)
		ifFalse: [ownerSprite _ nil].
	ownerSprite ifNil: [^self].
	ownerSprite removeSubsprite: self.
	ownerSprite _ nil. 
	self makeVisible.

	LibraryItemMorph allInstances do: [:each| each updateThumbnail]! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/15/2009 01:50'!
unhingeAll

	subsprites copy do: [:each |
		each unhinge ].

	LibraryItemMorph allInstances do: [:each| each updateThumbnail]! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 7/17/2009 00:13'!
virtualScale

	^virtualScale ifNil: [
		virtualScale _ self realScale]! !

!ScratchSpriteMorph methodsFor: 'nesting' stamp: 'jens 8/5/2009 23:22'!
virtualScale: aPoint
	virtualScale _ aPoint! !


!ScratchSpriteMorph methodsFor: 'stepping' stamp: 'jens 7/20/2009 00:26'!
step

	offset notNil & ownerSprite notNil ifTrue: [
		self referencePosition: ownerSprite referencePosition + offset ].
	super step.
! !


!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 1/27/2011 00:21'!
asReferenceTuple

	" answer an array describing the receiver in an abstract way
	format conventions:"

	^ Array 
		with: #sprite
		with: self objName
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/14/2011 22:20'!
attribute: attr
	"Answer the value of my variable or built-in attribute with the given name. Answer zero if I have no attribute or variable with the given name."

	| a |
	
	(attr isKindOf: CommandBlockMorph)
		ifTrue: [^ attr fullCopy newScriptOwner: self; yourself] 		"self blockLike: attr body]".

	a _ attr asString.
	(vars includesKey: a) ifTrue: [^ vars at: a].
	(self allLocalBlockIds includes: a) ifTrue: [ ^self lambda: a ].

	a _ a localized.
	'x position' localized = a ifTrue: [^ self xpos].
	'y position' localized = a ifTrue: [^ self ypos].
	'direction' localized = a ifTrue: [^ self heading].
	'costume #' localized = a ifTrue: [^ self costumeIndex].
	'size' localized = a ifTrue: [^ self scale].
	'volume' localized = a ifTrue: [^ self volume].

	'name' localized = a ifTrue: [^ self objName].
	'prototype' localized = a ifTrue: [^ self prototype].
	'owner' localized = a ifTrue: [^ self ownerSprite].
	'parts' localized = a ifTrue: [^ ScratchListMorph on: self subsprites].

	^ 0
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/11/2011 01:22'!
children
	^ ScratchListMorph on: self instances! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 1/10/2011 22:59'!
choosePrototype
	| stage choice |
	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNil: [^ self].
	choice _ stage userSelectSpriteDefault: prototype butNotAnyOf: {self. prototype}.
	choice ifNil: [^ self].
	choice = #null ifTrue: [
		choice _ nil].
	self prototype: choice! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/14/2011 20:02'!
getIsDraggable

	| att |
	att _ #isDraggable.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^self draggable! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/22/2011 22:21'!
getRotationStyle
	"Set my rotation style to #normal, #leftRight, or #none. Styles mean:
		#normal	-- smooth 360 degree rotation
		#leftRight	-- flip about the vertical axis
		#none		-- do not rotate"

	| att |
	att _ #rotationStyle.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	#none = rotationStyle ifTrue: [^ 0].
	#normal = rotationStyle ifTrue: [^ 1].
	#leftRight = rotationStyle ifTrue: [^ 2].

	^ 1! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/10/2011 22:02'!
parts
	^ ScratchListMorph on: self subsprites! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/15/2011 14:10'!
passiveFillColor: aColor
	"Set my fill color."

	| b |
	fillColor _ aColor.
	fillHue _ (fillColor hue * 200.0) / 360.0.
	b _ fillColor brightness.
	b = 1.0
		ifTrue: [fillShade _ 50.0 + (50.0 * (1.0 - fillColor saturation))]
		ifFalse: [fillShade _ 50.0 * b].

	fillGhosting > 0 
		ifTrue: [fillColor _ fillColor alpha: 1 - (fillGhosting / 100)].

	self propagate: #fillColor
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/15/2011 14:07'!
passiveFillGhosting: aNumber

	fillGhosting _ (0 max: aNumber) min: 100.
	fillGhosting > 0 
		ifTrue: [ fillColor _ fillColor alpha: 1 - (fillGhosting / 100) ]
		ifFalse: [ fillColor _ fillColor asNontranslucentColor ].

	self propagate: #fillGhosting.
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 12/13/2011 16:25'!
passiveFontColor: aColor
	"Set my font color."

	| b |
	fontColor _ aColor.
	fontHue _ (fontColor hue * 200.0) / 360.0.
	b _ fontColor brightness.
	b = 1.0
		ifTrue: [fontShade _ 50.0 + (50.0 * (1.0 - fontColor saturation))]
		ifFalse: [fontShade _ 50.0 * b].

	fontGhosting > 0 
		ifTrue: [fontColor _ fontColor alpha: 1 - (fontGhosting / 100)].

	self propagate: #fontColor
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 12/13/2011 16:27'!
passiveFontGhosting: aNumber

	fontGhosting _ (0 max: aNumber) min: 100.
	fontGhosting > 0 
		ifTrue: [ fontColor _ fontColor alpha: 1 - (fontGhosting / 100) ]
		ifFalse: [ fontColor _ fontColor asNontranslucentColor ].

	self propagate: #fontGhosting.
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 1/13/2012 14:36'!
passiveFontName: aString

	(StrikeFont fontNames includes: aString) ifFalse: [ ^ self ].	
	fontName _ aString.

	self propagate: #fontName.! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 22:42'!
passiveLookLike: costumeName

	super lookLike: costumeName.
	self positionTalkBubble.

	self propagate: #costumeIndex

! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/15/2011 14:11'!
passivePenColor: aColor
	"Set my pen color."

	| b |
	penColor _ aColor.
	penHue _ (penColor hue * 200.0) / 360.0.
	b _ penColor brightness.
	b = 1.0
		ifTrue: [penShade _ 50.0 + (50.0 * (1.0 - penColor saturation))]
		ifFalse: [penShade _ 50.0 * b].

	penGhosting > 0 
		ifTrue: [penColor _ penColor alpha: 1 - (penGhosting / 100)].

	self propagate: #penColor
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/15/2011 13:19'!
passivePenDown: aBoolean

	| m |
	(aBoolean isKindOf: Boolean)
		ifFalse: [^ self error: 'expecting a boolean'].
	penDown _ aBoolean.
	penColor ifNil: [penColor _ Color black].  "initialize if necessary"
	penSize ifNil: [penSize _ 1].  "initialize if necessary"
	penGhosting ifNil: [penGhosting _ 0].

	(m _ self ownerThatIsA: ScratchStageMorph)
		ifNotNil: [m penUpOrDownChangeFor: self].

	self propagate: #penDown
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/15/2011 14:09'!
passivePenGhosting: aNumber

	penGhosting _ (0 max: aNumber) min: 100.
	penGhosting > 0 
		ifTrue:	[ penColor _ penColor alpha: 1 - (penGhosting / 100) ]
		ifFalse: [ penColor _ penColor asNontranslucentColor ].
	self propagate: #penGhosting.
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/15/2011 15:42'!
passivePenSize: aNumber
	"Set my pen width."

	penSize _ aNumber asNumberNoError rounded min: (ScratchFrameMorph workpaneExtent x * 2) max: 0.

	self propagate: #penSize
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/24/2011 12:28'!
passiveRotationStyle: aNumber
	"Set my rotation style to #normal, #leftRight, or #none. Styles mean:
		#normal	-- smooth 360 degree rotation
		#leftRight	-- flip about the vertical axis
		#none		-- do not rotate"

	| se |
	rotationStyle _ #(none normal leftRight) at: aNumber asNumberNoError rounded + 1 ifAbsent: [#normal].
	self costumeChanged.
	self positionTalkBubble.
	se _ blocksBin ownerThatIsA: ScratchScriptEditorMorph.
	se ifNil: [^ self].
	se updateRotationButtonHighlight.
	se animateRotationStyle.

	self propagate: #rotationStyle
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/14/2011 20:40'!
passiveSetDraggable: aBoolean

	| se |
	draggable _ aBoolean.
	se _ blocksBin ownerThatIsA: ScratchScriptEditorMorph.
	se ifNil: [^ self].
	se updateLockButton
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/15/2011 13:09'!
passiveSetFillHueTo: aNumber
	"Set the fill hue to given number between 0 and 200. (That makes 100 the 'maximum' distance away from the original color on the color wheel.)"

	fillHue _ aNumber asNumberNoError \\ 200.
	self setFillShadeTo:  fillShade.  "compute and set fillColor"

	self propagate: #fillColor
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 12/6/2011 16:44'!
passiveSetFillShadeTo: aNumber
	"Set the fill shade (lightness) to given number between 0 and 100. A shade of 0 is black, 100 is white, and 50 is fully saturated color."
	"Details: We don't want to get all the way to pure black or white, so we divide the range 0..50 by a number > 50 when computing the fraction of the original color to mix with black or white."

	| normalizeShade scale k |
	fillShade _ aNumber asNumberNoError asFloat \\ 200.0.
	fillColor _ Color h: (360.0 * fillHue) / 200.0 s: 1.0 v: 1.0.
	normalizeShade _ fillShade > 100.0 ifTrue: [200.0 - fillShade] ifFalse: [fillShade].

	"normalizeShade = 50.0 ifTrue: [^ self]."  "pure color"

	scale _ 1.0 / 60.0.
	k _ 1.0 - (50.0 * scale).
	normalizeShade < 50.0 ifTrue: [
		fillColor _ fillColor mixed: (scale * normalizeShade) + k with: Color black].
	normalizeShade > 50.0 ifTrue: [
		fillColor _ fillColor mixed: 1.0 - (scale * (normalizeShade - 50.0)) with: Color white].

	fillGhosting > 0 
		ifTrue: [fillColor _ fillColor alpha: 1 - (fillGhosting / 100)].

	self propagate: #fillShade
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 12/13/2011 16:28'!
passiveSetFontHueTo: aNumber
	"Set the font hue to given number between 0 and 200. (That makes 100 the 'maximum' distance away from the original color on the color wheel.)"

	fontHue _ aNumber asNumberNoError \\ 200.
	self setFontShadeTo:  fontShade.  "compute and set penColor"

	self propagate: #fontColor
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 12/13/2011 16:30'!
passiveSetFontShadeTo: aNumber
	"Set the fill shade (lightness) to given number between 0 and 100. A shade of 0 is black, 100 is white, and 50 is fully saturated color."
	"Details: We don't want to get all the way to pure black or white, so we divide the range 0..50 by a number > 50 when computing the fraction of the original color to mix with black or white."

	| normalizeShade scale k |
	fontShade _ aNumber asNumberNoError asFloat \\ 200.0.
	fontColor _ Color h: (360.0 * fontHue) / 200.0 s: 1.0 v: 1.0.
	normalizeShade _ fontShade > 100.0 ifTrue: [200.0 - fontShade] ifFalse: [fontShade].

	"normalizeShade = 50.0 ifTrue: [^ self]."  "pure color"

	scale _ 1.0 / 60.0.
	k _ 1.0 - (50.0 * scale).
	normalizeShade < 50.0 ifTrue: [
		fontColor _ fontColor mixed: (scale * normalizeShade) + k with: Color black].
	normalizeShade > 50.0 ifTrue: [
		fontColor _ fontColor mixed: 1.0 - (scale * (normalizeShade - 50.0)) with: Color white].

	fontGhosting > 0 
		ifTrue: [fontColor _ fontColor alpha: 1 - (fontGhosting / 100)].

	self propagate: #fontShade
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 12/13/2011 16:34'!
passiveSetFontSize: aNumber

	fontSize _ (aNumber min: 48) max: 1.
	self propagate: #fontSize.! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/9/2011 00:51'!
passiveSetPenHueTo: aNumber
	"Set the pen hue to given number between 0 and 200. (That makes 100 the 'maximum' distance away from the original color on the color wheel.)"

	penHue _ aNumber asNumberNoError \\ 200.
	self setPenShadeTo:  penShade.  "compute and set penColor"

	self propagate: #penColor
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/15/2011 14:12'!
passiveSetPenShadeTo: aNumber
	"Set the pen shade (lightness) to given number between 0 and 100. A shade of 0 is black, 100 is white, and 50 is fully saturated color."
	"Details: We don't want to get all the way to pure black or white, so we divide the range 0..50 by a number > 50 when computing the fraction of the original color to mix with black or white."

	| normalizeShade scale k |
	penShade _ aNumber asNumberNoError asFloat \\ 200.0.
	penColor _ Color h: (360.0 * penHue) / 200.0 s: 1.0 v: 1.0.
	normalizeShade _ penShade > 100.0 ifTrue: [200.0 - penShade] ifFalse: [penShade].

	normalizeShade = 50.0 ifTrue: [^ self].  "pure color"

	scale _ 1.0 / 60.0.
	k _ 1.0 - (50.0 * scale).
	normalizeShade < 50.0 ifTrue: [
		penColor _ penColor mixed: (scale * normalizeShade) + k with: Color black].
	normalizeShade > 50.0 ifTrue: [
		penColor _ penColor mixed: 1.0 - (scale * (normalizeShade - 50.0)) with: Color white].

	penGhosting > 0 
		ifTrue: [penColor _ penColor alpha: 1 - (penGhosting / 100)].

	self propagate: #penShade
! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 23:14'!
passiveSetSizeTo: percent
	"Set my size to the given percent of the original size. Limit the range to avoid accidentally 
	making me invisibly tiny or really huge. Retain my aspect ratio (i.e., my stretch)."

	| pc origExtent minExtent maxExtent minScale maxScale curDist oldPercent unit newDist factor|
	pc _ percent asNumberNoError.
	oldPercent _ self virtualScale.
	oldPercent = 0 ifTrue: [oldPercent _ 1/100000].

	origExtent _ self costumeForm extent asFloatPoint.
	minExtent _ (origExtent min: 5@5) asFloatPoint.
	maxExtent _ ScratchFrameMorph workpaneExtent asFloatPoint * 1.5.
	minScale _ ((minExtent x / origExtent x) max: (minExtent y / origExtent y)) min: 1.0.
	maxScale _ (maxExtent x / origExtent x) min: (maxExtent y / origExtent y).

	virtualScale _ pc.
	self scalePoint: ((pc / 100.0) within: minScale and: maxScale) asPoint.

	subsprites do: [:sub |
			curDist _ sub referencePosition - self referencePosition.
			unit _ curDist / oldPercent.
			newDist _ unit * percent.
			sub holdSubsprites.
			sub referencePosition: self referencePosition + newDist.
			sub releaseSubsprites.
			factor _ sub virtualScale / oldPercent.
			sub changeSizeBy: (self virtualScale * factor) - sub virtualScale].

	self propagate: #size

! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 20:25'!
passiveTurn: degrees
	| newPos |
	"Turn clockwise the given number of degrees."

	self rotationDegrees: rotationDegrees + degrees.
	subsprites do: [:sub |
		newPos _ sub referencePosition rotateBy: degrees degreesToRadians about: self referencePosition.
		sub gotoX: newPos x y: newPos y ].

	self rotateWithOwner
		ifTrue: [ self spreadToFollowers ].

	self propagate: #heading

! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'JM 11/17/2011 10:18'!
passiveXpos: aNumber 

	| num newX |
	num _ aNumber asNumberNoError.
	newX _ (num isInteger ifTrue: [num] ifFalse: [num asFloat] ) .
	self holdSubsprites.
	self referencePosition: newX @ self ypos.
	self releaseSubsprites.

	self propagate: #xPosition

! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 23:13'!
passiveYpos: aNumber

	| num newY |
	num _ aNumber asNumberNoError.
	newY _ num isInteger ifTrue: [num] ifFalse: [num asFloat].
	self holdSubsprites.
	self referencePosition: (self xpos @ newY).
	self releaseSubsprites.

	self propagate: #yPosition

! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 1/10/2011 22:06'!
prototype
	^ prototype! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 5/19/2011 13:41'!
prototype: aSprite

	| sFrame |
	prototype _ aSprite.
	prototype = false ifTrue: [
		prototype _ nil].
	self
		undeleteAllAttributes;
		undeleteAllVariables;
		undeleteAllBlocks.
	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self].
	sFrame viewerPane categoryChanged: sFrame viewerPane currentCategory.
	self inheritCostumesNow.
	self inheritSoundsNow! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 3/4/2011 01:05'!
removeLocalBlockDefinitions
	customBlocks ifNil: [^ self].
	customBlocks _ customBlocks select: [:def |
		def isGlobal]! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 2/22/2011 22:26'!
setRotationStyle: aNumber
	"Set my rotation style to #normal, #leftRight, or #none. Styles mean:
		#normal	-- smooth 360 degree rotation
		#leftRight	-- flip about the vertical axis
		#none		-- do not rotate"

	self undeleteAttribute: #rotationStyle.
	self passiveRotationStyle: aNumber! !

!ScratchSpriteMorph methodsFor: 'byob OOP' stamp: 'jens 5/19/2011 13:46'!
spawn

	| stage child |
"
	(frame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ nil].
"
	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNil: [^ self].
	child _ self fullCopy.
	child blocksBin allMorphsDo: [:m |
		(m isKindOf: BlockMorph) ifTrue: [m stop]].
	child unhinge; unhingeAll; initializeNodes.
	child prototype: self.
	child initializeVarsAndLists.
	child removeLocalBlockDefinitions.
	"frame workPane" stage addMorphFront: child.
	stage sprites addLast: child.
	child deleteAttributes: self deletedAttributes.
	child deleteAttribute: #costumes.
	child deleteAttribute: #sounds.

	^ child	! !


!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 12/13/2011 16:37'!
fillGhosting

	| att |
	att _ #fillGhosting.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fillGhosting! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 11/15/2011 13:11'!
fillHue

	| att |
	att _ #fillColor.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fillHue! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 11/15/2011 13:12'!
fillShade

	| att |
	att _ #fillShade.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fillShade! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 12/13/2011 16:36'!
fontColor

	| att |
	att _ #fontColor.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fontColor! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 12/13/2011 16:37'!
fontGhosting

	| att |
	att _ #fontGhosting.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fontGhosting! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 12/13/2011 16:36'!
fontHue

	| att |
	att _ #fontHue.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fontHue! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 12/13/2011 16:36'!
fontName

	| att |
	att _ #fontName.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fontName! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 12/13/2011 16:37'!
fontShade

	| att |
	att _ #fontShade.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fontShade! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 1/13/2012 14:27'!
fontSize

	| att |
	att _ #fontSize.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ fontSize! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'JM 12/13/2011 16:37'!
penGhosting

	| att |
	att _ #penGhosting.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ penGhosting! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/10/2011 00:03'!
penHue

	| att |
	att _ #penColor.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ penHue! !

!ScratchSpriteMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:31'!
penShade

	| att |
	att _ #penShade.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ penShade! !


!ScratchSpriteMorph methodsFor: 'text' stamp: 'JM 12/13/2011 16:50'!
fontColor: aColor

	self undeleteAttribute: #fontColor.
	self passiveFontColor: aColor.! !

!ScratchSpriteMorph methodsFor: 'text' stamp: 'JM 1/13/2012 14:29'!
fontName: aString

	self undeleteAttribute: #fontName.
	self passiveFontName: aString.! !

!ScratchSpriteMorph methodsFor: 'text' stamp: 'JM 12/13/2011 16:33'!
setFontSize: aNumber

	self undeleteAttribute: #fontSize.
	self passiveSetFontSize: aNumber.! !

!ScratchSpriteMorph methodsFor: 'text' stamp: 'JM 12/13/2011 11:22'!
writeText: aString

	| stage |
	stage _ (self ownerThatIsA: ScratchStageMorph) ifNil: [^ self].

	stage drawTextFor: self s: aString.! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScratchSpriteMorph class
	instanceVariableNames: ''!

!ScratchSpriteMorph class methodsFor: 'block specs' stamp: 'JM 12/13/2011 16:54'!
blockSpecs

	| blocks |
	blocks _ #(
		'motion'
			('move %n steps'				-	forward:)
			('turn %n degrees'				-	turnRight: 15)	"icon shows turn direction"
			('turn %n degrees'				-	turnLeft: 15)	"icon shows turn direction"
			-
			('point in direction %d'			-	heading: 90)
			('point towards %m'				-	pointTowards:)
			-
			('go to x:%n y:%n'				-	gotoX:y: 0 0)
			('go to %m'						-	gotoSpriteOrMouse:)
			('go to random location'			-	gotoRandomLocation)
			('glide %n secs to x:%n y:%n'	t	glideSecs:toX:y:elapsed:from: 1 50 50)
			-
			('change x by %n'				-	changeXposBy: 10)
			('set x to %n'					-	xpos: 0)
			('change y by %n'				-	changeYposBy: 10)
			('set y to %n'					-	ypos: 0)
			-
			('if on edge, bounce'			-	bounceOffEdge)
			-
			('x position'						r	xpos)
			('y position'						r	ypos)
			('direction'						r	heading)
		'pen'
			('clear'							-	clearPenTrails)
			-
			('pen down'						-	putPenDown)
			('pen up'						-	putPenUp)
			('pen down?'					b	penDown)
			-
			('set pen color to %c'			-	penColor:)
			('change pen color by %n'		-	changePenHueBy:)
			('set pen color to %n'			-	setPenHueTo: 0)
			-
			('change pen shade by %n'		-	changePenShadeBy:)
			('set pen shade to %n'			-	setPenShadeTo: 50)
			-
			('change pen ghosting by %n'	-	changePenGhostingBy:)
			('set pen ghosting to %n'		-	setPenGhostingTo: 50)
			-
			('change pen size by %n'		-	changePenSizeBy: 1)
			('set pen size to %n'				-	penSize: 1)
		'shapes'
			('circle radius %n'				-	drawCircle: 50)
			('oval radius %n by %n'				-	drawOvalWidth:height: 80 50)
			('rectangle %n by %n'			-	drawRectangle:by: 50 50)
			-
			('start shape'					-	shapeStart)
			('end shape'						- 	shapeEnd)
			-
			('change fill color by: %n'		-	changeFillHueBy:)
			('set fill color to %c'				-	fillColor:)
			-
			('change fill shade by %n'		-	changeFillShadeBy:)
			('set fill shade to %n'			-	setFillShadeTo: 50)
			-
			('change fill ghosting by: %n'	-	changeFillGhostingBy:)
			('set fill ghosting to: %n'		-	setFillGhostingTo: 50)
			('stamp'							-	stampCostume)
		'text'
			('clear'							-	clearPenTrails)
			-
			('write %s'						-	writeText:)
			-
			('set font to %3'					-	fontName:)
			('set font size to %n'				-	setFontSize: 12)
			-
			('change font color by %n'		-	changeFontColorBy:)
			('set font color to %c'			-	setFontColor: )
			-
			('change font shade by %n'		-	changeFontShadeBy: )
			('set font shade to %n'			-	setFontShadeTo: 50 )
			-
			('change font ghosting by %n'	-	changeFontGhostingBy: )
			('set font ghosting to: %n'		-	setFontGhostingTo: 50 )

	).

	blocks _ blocks, #(
		'looks'
			('switch to costume %l'			-	lookLike:)
			('next costume'					-	nextCostume)
			('costume #'						r	costumeIndex)
			-
			('say %s for %n secs'			t	say:duration:elapsed:from: 'Hello!!' 2)
			('say %s'						-	say: 'Hello!!')
			('think %s for %n secs'			t	think:duration:elapsed:from: 'Hmm...' 2)
			('think %s'						-	think: 'Hmm...')
			-
			('change %g effect by %n'		-	changeGraphicEffect:by: 'color' 25)
			('set %g effect to %n'			-	setGraphicEffect:to: 'color' 0)
			('clear graphic effects'			-	filterReset)
			-
			('change size by %n'			-	changeSizeBy:)
			('set size to %n%'				-	setSizeTo: 100)
			('size'							r	scale)
			-
			('show'							-	show)
			('hide'							-	hide)
			-
			('go to front'					-	comeToFront)
			('go back %n layers'			-	goBackByLayers: 1)
		'sensing'
			('touching %m?' 				b	touching:)
			('touching color %C?' 			b	touchingColor:)
			('color %C is touching %C?'		b	color:sees:)
			-
			('ask %s and wait'				s	doAsk 'What''s your name?')
			('answer'						r	answer)
			-
			('mouse x'						r	mouseX)
			('mouse y'						r	mouseY)
			('mouse down?'					b	mousePressed)
			-
			('key %k pressed?'				b	keyPressed: 'space')
			-
			('distance to %m'				r	distanceTo:)
			-
			('reset timer'					-	timerReset)
			('timer'							r	timer)
			-
			('%a of %m'						r	getAttribute:of:)
"			('get %a of %m'					r	attribute:of:)"
			-
			('loudness'						r	soundLevel)
			('loud?'							b	isLoud)
			~
			('%H sensor value'				r	sensor: 'slider')
			('sensor %h?'					b	sensorPressed: 'button pressed')
			=
			('object %m'						r	getObject:)
			('attribute %a'					r	get:)

		).

	^ blocks, super blockSpecs
! !
