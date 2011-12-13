Object subclass: #Canvas
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Morphic-Support'!
!Canvas commentStamp: 'jm 2/1/2005 12:18' prior: 0!
A canvas is a two-dimensional medium on which morphs are drawn in a device-independent manner. Canvases keep track of the origin and clipping rectangle, as well as the underlying drawing medium.

Subclasses must implement (at least) the following methods:
	* Drawing:
		#fillOval:color:borderWidth:borderColor:
		#frameAndFillRectangle:fillColor:borderWidth:borderColor:
		#image:at:sourceRect:rule:
		#stencil:at:sourceRect:color:
		#line:to:width:color:
		#paragraph:bounds:color:
		#text:bounds:font:color:
	* Support
		#translateBy:during:
		#translateBy:clippingTo:during:
		#transformBy:clippingTo:during:smoothing:

!


!Canvas methodsFor: 'initialization' stamp: 'jm 10/30/2002 20:55'!
reset
	"Reset the canvas. This default implementation does nothing."
! !


!Canvas methodsFor: 'copying' stamp: 'jm 11/24/2002 10:40'!
copy

	^ self clone
! !


!Canvas methodsFor: 'accessing' stamp: 'ar 6/22/1999 14:07'!
clipRect
	"Return the currently active clipping rectangle"
	^self subclassResponsibility! !

!Canvas methodsFor: 'accessing'!
depth

	^ Display depth
! !

!Canvas methodsFor: 'accessing' stamp: 'ar 6/22/1999 14:15'!
extent
	"Return the physical extent of the output device"
	^self subclassResponsibility! !

!Canvas methodsFor: 'accessing' stamp: 'jm 6/2/1998 06:39'!
form

	^ Display
! !

!Canvas methodsFor: 'accessing' stamp: 'ar 6/22/1999 14:11'!
origin
	"Return the current origin for drawing operations"
	^self subclassResponsibility! !

!Canvas methodsFor: 'accessing' stamp: 'jm 11/24/2002 11:16'!
shadowColor
	"Return the current override color or nil if not drawing shadows."

	^ nil
! !

!Canvas methodsFor: 'accessing' stamp: 'ar 2/17/2000 01:46'!
shadowColor: aColor
	"Set a shadow color. If set this color overrides any client-supplied color."! !


!Canvas methodsFor: 'testing' stamp: 'ar 6/22/1999 19:03'!
isShadowDrawing
	^false! !

!Canvas methodsFor: 'testing' stamp: 'ar 6/22/1999 14:10'!
isVisible: aRectangle
	"Return true if the given rectangle is (partially) visible"
	^self clipRect intersects: aRectangle
! !


!Canvas methodsFor: 'converting' stamp: 'jm 3/29/2008 10:14'!
asShadowDrawingCanvas
	"Answer a canvas like me for drawing translucent shadows."

	^ self asShadowDrawingCanvas: (Color black alpha: 0.3)
! !

!Canvas methodsFor: 'converting' stamp: 'jm 1/8/2003 11:01'!
asShadowDrawingCanvas: aColor
	"Answer a copy of me for drawing drop-shadows."

	^ self copy shadowColor: aColor
! !


!Canvas methodsFor: 'transforms' stamp: 'di 10/16/1999 15:56'!
transformBy: aDisplayTransform clippingTo: aClipRect during: aBlock smoothing: cellSize
	"Transform the receiver by the given display transformation during the execution of aBlock. The given clip rectangle defines the *global* (e.g., outer) rectangle against which the receiver should clip (which would be equivalent to 'self clipRect: aClipRect; transformBy: aDisplayTransform')."
	^ self subclassResponsibility! !

!Canvas methodsFor: 'transforms'!
translateBy:aPoint clippingTo:aRect during:aBlock
	^aBlock value:(self copyOffset:aPoint clipRect:aRect).! !

!Canvas methodsFor: 'transforms' stamp: 'ar 6/17/1999 03:00'!
translateBy: delta during: aBlock
	"Set a translation only during the execution of aBlock."
	^self subclassResponsibility! !

!Canvas methodsFor: 'transforms' stamp: 'ar 6/22/1999 14:08'!
translateTo: newOrigin clippingTo: aRectangle during: aBlock
	"Set a new origin and clipping rectangle only during the execution of aBlock."
	self translateBy: newOrigin - self origin 
		clippingTo: (aRectangle translateBy: self origin negated) 
		during: aBlock! !


!Canvas methodsFor: 'drawing-morphs' stamp: 'jm 11/24/2002 11:51'!
drawMorph: aMorph

	(self isVisible: aMorph bounds) ifTrue: [aMorph drawOn: self].
! !

!Canvas methodsFor: 'drawing-morphs' stamp: 'jm 11/24/2002 11:50'!
fullDrawMorph: aMorph

	(self isVisible: aMorph fullBounds) ifTrue: [aMorph fullDrawOn: self].
! !


!Canvas methodsFor: 'drawing-rectangles' stamp: 'ar 6/18/1999 07:32'!
fillRectangle: r color: c
	"Fill the rectangle using the given color"
	^self 
		frameAndFillRectangle: r
		fillColor: c
		borderWidth: 0
		borderColor: Color transparent! !

!Canvas methodsFor: 'drawing-rectangles' stamp: 'ar 6/18/1999 07:32'!
frameAndFillRectangle: r fillColor: fillColor borderWidth: borderWidth borderColor: borderColor
	"Draw the rectangle using the given attributes"
	^self subclassResponsibility! !

!Canvas methodsFor: 'drawing-rectangles' stamp: 'ar 6/18/1999 07:32'!
frameAndFillRectangle: r fillColor: fillColor borderWidth: borderWidth topLeftColor: topLeftColor bottomRightColor: bottomRightColor
	"Draw the rectangle using the given attributes.
	Note: This is a *very* simple implementation"
	| bw pt |
	self frameAndFillRectangle: r
		fillColor: fillColor
		borderWidth: borderWidth
		borderColor: bottomRightColor.
	bw _ borderWidth asPoint.
	pt _ r topLeft + (bw // 2).
	self line: pt to: pt + ((r extent x - bw x)@0) width: borderWidth color: topLeftColor.
	self line: pt to: pt + (0@(r extent y - bw y)) width: borderWidth color: topLeftColor.! !

!Canvas methodsFor: 'drawing-rectangles' stamp: 'ar 6/18/1999 07:33'!
frameRectangle: r color: c

	self frameRectangle: r width: 1 color: c.
! !

!Canvas methodsFor: 'drawing-rectangles' stamp: 'ar 6/18/1999 07:33'!
frameRectangle: r width: w color: c
	^self frameAndFillRectangle: r fillColor: Color transparent borderWidth: w borderColor: c.! !


!Canvas methodsFor: 'drawing-ovals' stamp: 'jm 11/24/2002 11:05'!
fillOval: r color: c

	self fillOval: r color: c borderWidth: 0 borderColor: Color black.
! !

!Canvas methodsFor: 'drawing-ovals' stamp: 'jm 11/24/2002 11:05'!
fillOval: r color: c borderWidth: borderWidth borderColor: borderColor
	"Fill the given oval."

	^ self subclassResponsibility
! !

!Canvas methodsFor: 'drawing-ovals' stamp: 'ar 6/18/1999 08:45'!
frameOval: r color: c

	self fillOval: r color: Color transparent borderWidth: 1 borderColor: c.
! !

!Canvas methodsFor: 'drawing-ovals' stamp: 'ar 6/18/1999 08:45'!
frameOval: r width: w color: c

	self fillOval: r color: Color transparent borderWidth: w borderColor: c.
! !


!Canvas methodsFor: 'drawing-lines and fills' stamp: 'ar 6/17/1999 01:18'!
fillColor: aColor
	"Fill the receiver with the given color.
	Note: This method should be named differently since it is intended to fill the background and thus fills even if the color is transparent"
	^self fillRectangle: self clipRect color: (aColor alpha: 1.0).! !

!Canvas methodsFor: 'drawing-lines and fills' stamp: 'ar 6/17/1999 01:30'!
line: pt1 to: pt2 brushForm: brush
	"Obsolete - will be removed in the future"! !

!Canvas methodsFor: 'drawing-lines and fills' stamp: 'jm 8/2/97 13:54'!
line: pt1 to: pt2 color: c

	self line: pt1 to: pt2 width: 1 color: c.
! !

!Canvas methodsFor: 'drawing-lines and fills' stamp: 'ar 6/17/1999 01:31'!
line: pt1 to: pt2 width: w color: c
	"Draw a line using the given width and color"
	^self subclassResponsibility! !


!Canvas methodsFor: 'drawing-images' stamp: 'ar 2/16/2000 23:45'!
drawImage: aForm at: aPoint
	"Draw the given Form, which is assumed to be a Form or ColorForm"

	self drawImage: aForm
		at: aPoint
		sourceRect: aForm boundingBox! !

!Canvas methodsFor: 'drawing-images' stamp: 'ar 2/17/2000 01:47'!
drawImage: aForm at: aPoint sourceRect: sourceRect
	"Draw the given form."
	self shadowColor ifNotNil:[
		^self fillRectangle: ((aForm boundingBox intersect: sourceRect) translateBy: aPoint)
				color: self shadowColor].
	^self image: aForm
		at: aPoint
		sourceRect: sourceRect
		rule: Form over! !

!Canvas methodsFor: 'drawing-images' stamp: 'ar 2/16/2000 23:48'!
paintImage: aForm at: aPoint
	"Draw the given Form, which is assumed to be a Form or ColorForm following the convention that zero is the transparent pixel value."

	self paintImage: aForm
		at: aPoint
		sourceRect: aForm boundingBox
! !

!Canvas methodsFor: 'drawing-images' stamp: 'ar 2/17/2000 01:48'!
paintImage: aForm at: aPoint sourceRect: sourceRect
	"Draw the given Form, which is assumed to be a Form or ColorForm following the convention that zero is the transparent pixel value."
	self shadowColor ifNotNil:[
		^self stencil: aForm at: aPoint sourceRect: sourceRect color: self shadowColor].
	^self image: aForm
		at: aPoint
		sourceRect: sourceRect
		rule: Form paint! !

!Canvas methodsFor: 'drawing-images' stamp: 'jm 3/18/2003 11:19'!
paintImage: aForm at: aPoint sourceRect: sourceRect alpha: alpha
	"Draw the given Form, which is assumed to be a Form or ColorForm following the convention that zero is the transparent pixel value."

	self shadowColor ifNotNil:[
		^ self stencil: aForm at: aPoint sourceRect: sourceRect color: self shadowColor].

	^ self image: aForm
		at: aPoint
		sourceRect: sourceRect
		rule: 31
		alpha: alpha
! !

!Canvas methodsFor: 'drawing-images' stamp: 'ar 6/25/1999 12:17'!
stencil: stencilForm at: aPoint color: aColor
	"Flood this canvas with aColor wherever stencilForm has non-zero pixels"
	^self stencil: stencilForm
		at: aPoint
		sourceRect: stencilForm boundingBox
		color: aColor! !

!Canvas methodsFor: 'drawing-images' stamp: 'ar 6/25/1999 12:17'!
stencil: stencilForm at: aPoint sourceRect: sourceRect color: aColor
	"Flood this canvas with aColor wherever stencilForm has non-zero pixels"
	^self subclassResponsibility! !

!Canvas methodsFor: 'drawing-images' stamp: 'ar 2/17/2000 14:05'!
translucentImage: aForm at: aPoint
	"Draw a translucent image using the best available way of representing translucency."
	self translucentImage: aForm
		at: aPoint
		sourceRect: aForm boundingBox! !

!Canvas methodsFor: 'drawing-images' stamp: 'JM 12/6/2011 16:19'!
translucentImage: aForm at: aPoint sourceRect: sourceRect
	"Draw a translucent image using the best available way of representing translucency.
	Note: This will be fixed in the future."
	self shadowColor ifNotNil:[
		^self stencil: aForm at: aPoint sourceRect: sourceRect color: self shadowColor].
	(self depth < 32 or:[aForm depth < 32]) 
		ifTrue:[^self paintImage: aForm at: aPoint sourceRect: sourceRect].
	self image: aForm
		at: aPoint
		sourceRect: sourceRect
		rule: Form blend! !


!Canvas methodsFor: 'drawing-text' stamp: 'ar 6/17/1999 01:31'!
paragraph: paragraph bounds: bounds color: c
	"Draw the given paragraph"
	^self subclassResponsibility! !

!Canvas methodsFor: 'drawing-text' stamp: 'jm 9/16/2005 11:02'!
strings: stringList lineHeight: lineHeight bounds: boundsRect font: fontOrNil color: c
	"Draw the given list of strings with lineHeight spacing in the given font and color clipped to the given rectangle. If the font is nil, the default font is used."

	self subclassResponsibility.
! !

!Canvas methodsFor: 'drawing-text' stamp: 'jm 6/3/2008 16:12'!
text: s at: pt font: fontOrNil color: c

	^ self text: s bounds: (pt extent: 10000@10000) font: fontOrNil kern: 0 color: c
! !

!Canvas methodsFor: 'drawing-text' stamp: 'jm 3/30/2005 07:06'!
text: s bounds: boundsRect font: fontOrNil kern: kern color: c
	"Draw the given string in the given font and color clipped to the given rectangle. If the font is nil, the default font is used."

	^ self subclassResponsibility
! !


!Canvas methodsFor: 'other' stamp: 'jm 6/15/2003 18:40'!
contentsOfArea: aRectangle
	"Return the contents of the given area"

	^ self
		contentsOfArea: aRectangle
		into: (Form extent: aRectangle extent depth: self depth)
! !

!Canvas methodsFor: 'other' stamp: 'jm 6/15/2003 18:40'!
contentsOfArea: aRectangle into: aForm
	"Return a Form containing the contents of the given area."

	^ self subclassResponsibility
! !


!Canvas methodsFor: 'private' stamp: 'ar 2/12/2000 18:12'!
image: aForm at: aPoint sourceRect: sourceRect rule: rule
	"Note: The public use of this protocol is deprecated. It will become private. Nobody in the outside world must assume that a thing like a combination rule has any specific effect."
	^self subclassResponsibility! !
