Morph subclass: #HandMorph
	instanceVariableNames: 'keyboardFocus unclaimedKeystrokes mouseDownMorph mouseOverMorphs mouseOverTimes dragOverMorphs clickClient clickState firstClickEvent userInitials lastEvent eventTransform argument targetOffset damageRecorder cacheCanvas cachedCanvasHasHoles temporaryCursor temporaryCursorOffset grid gridOffset menuTargetOffset hasChanged savedPatch formerOwner formerPosition toolType drawHalfSize '
	classVariableNames: 'DoubleClickTime HoldTime NormalCursor PasteBuffer TranslucencyWhenDragging TranslucentWhenDragging '
	poolDictionaries: ''
	category: 'Morphic-Kernel'!
!HandMorph commentStamp: '<historical>' prior: 0!
The cursor may be thought of as the HandMorph. The hand's submorphs hold anything being carried by dragging. There can be multiple hands in the same world, in which case the user initials are displayed for each remote hand.
!


!HandMorph methodsFor: 'initialization' stamp: 'jm 8/11/2003 20:53'!
initForEvents

	mouseDownMorph _ nil.
	lastEvent _ MorphicEvent new.
	eventTransform _ MorphicTransform identity.
	self resetClickState.
	mouseOverTimes _ Dictionary new.
! !

!HandMorph methodsFor: 'initialization' stamp: 'jm 2/1/2005 19:57'!
initialize

	super initialize.
	self initForEvents.
	keyboardFocus _ nil.
	mouseOverMorphs _ OrderedCollection new.
	dragOverMorphs _ OrderedCollection new.
	bounds _ 0@0 extent: Cursor normal extent.
	userInitials _ ''.
	damageRecorder _ DamageRecorder new.
	cachedCanvasHasHoles _ false.
	grid _ gridOffset _ nil.
	temporaryCursor _ temporaryCursorOffset _ nil.
	toolType _ nil.
! !


!HandMorph methodsFor: 'classification' stamp: 'jm 10/14/2002 07:51'!
isHandMorph

	^ true
! !


!HandMorph methodsFor: 'accessing' stamp: 'sw 4/19/1998 01:41'!
argument
	^ argument! !

!HandMorph methodsFor: 'accessing' stamp: 'jm 5/8/2009 12:01'!
drawHalfSize

	^ drawHalfSize
! !

!HandMorph methodsFor: 'accessing' stamp: 'jm 5/7/2009 15:05'!
drawHalfSize: aBoolean

	drawHalfSize _ aBoolean.
! !

!HandMorph methodsFor: 'accessing' stamp: 'jm 7/1/2004 23:11'!
firstClickEvent

	^ firstClickEvent
! !

!HandMorph methodsFor: 'accessing' stamp: 'sw 4/15/1998 12:33'!
formerOwner
	^ formerOwner! !

!HandMorph methodsFor: 'accessing' stamp: 'jm 6/14/2004 14:42'!
formerOwner: aMorph position: aPoint
	"Set my former owner and postion. These are used when rejecting a drop."

	formerOwner _ aMorph.
	formerPosition _ aPoint.
! !

!HandMorph methodsFor: 'accessing' stamp: 'sw 4/15/1998 12:34'!
formerPosition
	^ formerPosition! !

!HandMorph methodsFor: 'accessing' stamp: 'jm 9/11/2006 17:03'!
hasMouseFocus: aMorph

	^ mouseDownMorph == aMorph
! !

!HandMorph methodsFor: 'accessing' stamp: 'jm 12/7/2005 16:42'!
lastEvent

	^ lastEvent
! !

!HandMorph methodsFor: 'accessing' stamp: 'jm 1/23/98 16:13'!
setArgument: aMorph

	targetOffset _ menuTargetOffset _ self position.
	argument _ aMorph.
! !

!HandMorph methodsFor: 'accessing'!
targetOffset
	"Return the offset of the last mouseDown location relative to the origin of the recipient morph. During menu interactions, this is the absolute location of the mouse down event that invoked the menu."

	^ targetOffset
! !

!HandMorph methodsFor: 'accessing' stamp: 'MD 2/12/2004 13:13'!
toolType
	^ toolType! !

!HandMorph methodsFor: 'accessing' stamp: 'jm 2/24/2004 18:59'!
toolType: aStringOrNil

	toolType _ aStringOrNil.
	aStringOrNil ifNil: [self showTemporaryCursor: nil].
! !

!HandMorph methodsFor: 'accessing'!
userInitials

	^ userInitials! !


!HandMorph methodsFor: 'cursor' stamp: 'MD 1/29/2004 10:25'!
cursor

	temporaryCursor 
		ifNil: [^ NormalCursor]
		ifNotNil: [^ temporaryCursor]! !

!HandMorph methodsFor: 'cursor' stamp: 'jwh 6/5/2000 07:38'!
cursorBounds

	^temporaryCursor 
		ifNil: [self position extent: NormalCursor extent]
		ifNotNil: [self position + temporaryCursorOffset extent: temporaryCursor extent]! !

!HandMorph methodsFor: 'cursor' stamp: 'di 3/6/1999 23:52'!
showTemporaryCursor: cursorOrNil
	"Set the temporary cursor to the given Form. If the argument is nil, revert to the normal cursor."

	self showTemporaryCursor: cursorOrNil hotSpotOffset: 0@0
! !

!HandMorph methodsFor: 'cursor' stamp: 'jm 3/26/2008 11:56'!
showTemporaryCursor: cursorOrNil hotSpotOffset: hotSpotOffset
	"Set the temporary cursor to the given Form, using the given hotSpotOffset if it's not nil. If the argument is nil, revert to the normal hardware cursor."

	| oldP |
	self changed.
	oldP _ self position.
	cursorOrNil
		ifNil: [
			temporaryCursor _ temporaryCursorOffset _ nil.
			Cursor normal show]
		ifNotNil: [
			temporaryCursor _ cursorOrNil.
			(cursorOrNil isKindOf: Cursor) ifTrue: [
				temporaryCursor _ cursorOrNil withMask.
				temporaryCursor _ ScratchFrameMorph isXO
					ifTrue: [temporaryCursor asXOCursorForm]
					ifFalse: [temporaryCursor asCursorForm]].

			temporaryCursorOffset _ (temporaryCursor offset - hotSpotOffset) truncated.
			Cursor blank show].

	bounds _ self cursorBounds.
	self position: oldP.
	self 
		userInitials: userInitials;
		layoutChanged;
		changed.

! !


!HandMorph methodsFor: 'geometry' stamp: 'jm 2/20/98 19:54'!
changed

	hasChanged _ true.
! !

!HandMorph methodsFor: 'geometry' stamp: 'jm 2/20/98 18:55'!
fullBounds
	"Extend my bounds by the shadow offset when carrying morphs."

	| bnds |
	bnds _ super fullBounds.
	submorphs isEmpty
		ifTrue: [^ bnds ]
		ifFalse: [^ bnds topLeft corner: bnds bottomRight + self shadowOffset].
! !

!HandMorph methodsFor: 'geometry' stamp: 'jm 2/20/98 19:37'!
invalidRect: damageRect
	"Note that a change has occurred and record the given damage rectangle relative to the origin this hand's cache."

	hasChanged _ true.
	fullBounds == nil
		ifTrue: [damageRecorder recordInvalidRect: damageRect]
		ifFalse: [damageRecorder recordInvalidRect: (damageRect translateBy: fullBounds origin negated)].
! !

!HandMorph methodsFor: 'geometry' stamp: 'jwh 6/5/2000 08:11'!
position

	^temporaryCursor
		ifNil: [bounds topLeft]
		ifNotNil: [bounds topLeft - temporaryCursorOffset]! !

!HandMorph methodsFor: 'geometry' stamp: 'jm 2/1/2005 20:37'!
position: aPoint
	"Overridden to align submorph origins to the grid if gridding is on."

	| adjustedPosition |
	adjustedPosition _ self griddedPoint: aPoint.
	temporaryCursor ifNotNil: [adjustedPosition _ adjustedPosition + temporaryCursorOffset].
	^ super position: adjustedPosition
! !

!HandMorph methodsFor: 'geometry' stamp: 'ar 5/18/2000 18:35'!
userInitials: aString

	| qp cb |
	userInitials _ aString.
	userInitials isEmpty ifFalse:
		[qp _ DisplayScanner quickPrintOn: Display.
		cb _ self cursorBounds.
		self bounds: (cb merge: (cb topRight + (0@4)
					extent: (qp stringWidth: userInitials)@(qp lineHeight)))]
! !


!HandMorph methodsFor: 'gridding' stamp: 'jm 2/1/2005 20:45'!
gridTo: gridSpacingPoint origin: originPoint
	"Turn on gridding. This causes the hand an any morphs carried by it to be aligned to a grid point. Both the grid spacing and the grid offset (starting point) can be set. For example, in a painting tool, it may be useful to make the origin be the top-left corner of the paint window. This grids to exact multiples of the grid spacing relative to the paint window's origin, even if that window is not positioned on a grid point relative the origin of the Display."

	grid _ gridSpacingPoint.
	gridOffset _ originPoint \\ gridSpacingPoint.
! !

!HandMorph methodsFor: 'gridding' stamp: 'jm 2/1/2005 20:37'!
griddedPoint: aPoint
	"Answer the given point snapped to a nearby grid point. Answer the original point if gridding is off."

	grid ifNil: [^ aPoint].
	gridOffset ifNil: [gridOffset _ 0@0].
	^ gridOffset + ((aPoint + (grid // 2) - gridOffset) truncateTo: grid)
! !

!HandMorph methodsFor: 'gridding' stamp: 'jm 2/1/2005 20:37'!
turnOffGridding
	"Turn off gridding."

	grid _ gridOffset _ nil.
! !


!HandMorph methodsFor: 'drawing' stamp: 'sw 2/11/98 18:00'!
colorForInsets
	"Morphs being dragged by the hand use the world's color"
	^ owner colorForInsets! !

!HandMorph methodsFor: 'drawing' stamp: 'ar 2/12/2000 18:05'!
drawOn: aCanvas
	"Draw the hand itself (i.e., the cursor)."

	temporaryCursor == nil
		ifTrue: [aCanvas paintImage: NormalCursor at: bounds topLeft]
		ifFalse: [aCanvas paintImage: temporaryCursor at: bounds topLeft].
	userInitials size > 0 ifTrue:
		[aCanvas text: userInitials
					at: (self cursorBounds topRight + (0@4))
					font: nil color: color].
! !

!HandMorph methodsFor: 'drawing' stamp: 'jens 7/13/2010 23:02'!
fullDrawOn: aCanvas
	"A HandMorph has unusual drawing requirements:
		1. the hand itself (i.e., the cursor) appears in front of its submorphs
		2. morphs being held by the hand cast a shadow on the world/morphs below
	The illusion is that the hand plucks up morphs and carries them above the world."
	"Note: This version caches an image of the morphs being held by the hand for
	 better performance. This cache is invalidated if one of those morphs changes."

	| disableCaching subBnds cached alpha |
	disableCaching _ false.
	disableCaching ifTrue: [self nonCachingFullDrawOn: aCanvas. ^ self].

	submorphs isEmpty ifTrue:
		[cacheCanvas _ nil.
		^ self drawOn: aCanvas].  "just draw the hand itself"

	subBnds _ Rectangle merging: (submorphs collect: [:m | m fullBounds]).
	self updateCacheCanvas: aCanvas.
	(cacheCanvas == nil or: [cachedCanvasHasHoles and: [cacheCanvas depth = 1]])
		ifTrue:
		["could not use caching due to translucency; do full draw"
		self nonCachingFullDrawOn: aCanvas. ^ self].

	drawHalfSize ifNil: [drawHalfSize _ false].
	drawHalfSize
		ifTrue: [
			cached _ cacheCanvas form magnifyBy: 0.5.
			subBnds _ (self position + ((subBnds origin - self position) // 2)) extent: subBnds extent // 2]
		ifFalse: [cached _ cacheCanvas form].

	"draw the shadow"
	aCanvas asShadowDrawingCanvas
		translateBy: self shadowOffset during:[:shadowCanvas|
		cachedCanvasHasHoles
			ifTrue: ["Have to draw the real shadow of the form"
					shadowCanvas paintImage: cached at: subBnds origin]
			ifFalse: ["Much faster if only have to shade the edge of a solid rectangle"
					(subBnds areasOutside: (subBnds translateBy: self shadowOffset negated)) do:
						[:r | shadowCanvas fillRectangle: r color: Color black]]].

	"draw morphs in front of the shadow using the cached Form"
	alpha _ self class translucencyWhenDragging.
	cachedCanvasHasHoles
		ifTrue: [aCanvas paintImage: cached at: subBnds origin sourceRect: cached boundingBox alpha: alpha]
		ifFalse: [aCanvas paintImage: cached at: subBnds origin
					sourceRect: cached boundingBox alpha: alpha].

	self drawOn: aCanvas.  "draw the hand itself in front of morphs"
! !

!HandMorph methodsFor: 'drawing' stamp: 'jm 2/20/98 14:28'!
hasChanged
	"Return true if this hand has changed, either because it has moved or because some morph it is holding has changed."

	^ hasChanged
! !

!HandMorph methodsFor: 'drawing' stamp: 'jm 11/8/2005 12:30'!
needsToBeDrawn
	"Return true if this hand must be drawn explicitely instead of being drawn via the hardware cursor. This is the case if it (a) it is a remote hand, (b) it is showing a temporary cursor, or (c) it is not empty. If using the software cursor, ensure that the hardware cursor is hidden."
	"Details:  Return true if this hand has a saved patch to ensure that is is processed by the world. This saved patch will be deleted after one final display pass when it becomes possible to start using the hardware cursor again. This trick gives us one last display cycle to allow us to remove the software cursor and shadow from the display."

	savedPatch ifNotNil: [^ true].  "always process if this hand has a saved patch"
	userInitials size > 0 ifTrue: [^ true].
	((submorphs size > 0) or:
	 [temporaryCursor ~~ nil])
		ifTrue: [
			"using the software cursor; hide the hardware one"
			Cursor currentCursor == Cursor blank ifFalse: [Cursor blank show].
			^ true].

	^ false
! !

!HandMorph methodsFor: 'drawing' stamp: 'ar 2/18/2000 15:19'!
nonCachingFullDrawOn: aCanvas
	| shadowForm |
	"A HandMorph has unusual drawing requirements:
		1. the hand itself (i.e., the cursor) appears in front of its submorphs
		2. morphs being held by the hand cast a shadow on the world/morphs below
	The illusion is that the hand plucks up morphs and carries them above the world."
	"Note: This version does not cache an image of the morphs being held by the hand.
	 Thus, it is slower for complex morphs, but consumes less space."

	submorphs isEmpty ifTrue: [^ self drawOn: aCanvas].  "just draw the hand itself"
	aCanvas asShadowDrawingCanvas
		translateBy: self shadowOffset during:[:shadowCanvas|
		"Note: We use a shadow form here to prevent drawing
		overlapping morphs multiple times using the transparent
		shadow color."
		shadowForm _ self shadowForm.
"
shadowForm displayAt: shadowForm offset negated. Display forceToScreen: (0@0 extent: shadowForm extent).
"
		shadowCanvas paintImage: shadowForm at: shadowForm offset.  "draw shadows"
	].
	"draw morphs in front of shadows"
	self drawSubmorphsOn: aCanvas.
	self drawOn: aCanvas.  "draw the hand itself in front of morphs"
! !

!HandMorph methodsFor: 'drawing' stamp: 'jm 11/8/2005 12:30'!
restoreSavedPatchOn: aCanvas
	"Clear the changed flag and restore the part of the given canvas under this hand from the previously saved patch. If necessary, handle the transition to using the hardware cursor."

	hasChanged _ false.
	savedPatch ifNotNil:
		[aCanvas drawImage: savedPatch at: savedPatch offset.
		((userInitials size = 0) and:
		 [(submorphs size = 0) and:
		 [temporaryCursor == nil]]) ifTrue: [
			"Make the transition to using hardware cursor. Clear savedPatch and
			 report one final damage rectangle to erase the image of the software cursor."
			super invalidRect: (savedPatch offset extent: savedPatch extent + self shadowOffset).
			Cursor currentCursor == Cursor normal ifFalse: [Cursor normal show].  "show hardware cursor"
			savedPatch _ nil]].
! !

!HandMorph methodsFor: 'drawing' stamp: 'ar 5/28/2000 16:01'!
savePatchFrom: aCanvas
	"Save the part of the given canvas under this hand as a Form and return its bounding rectangle."
	"Details: The previously used patch Form is recycled when possible to reduce the burden on storage management."

	| damageRect myBnds |
	damageRect _ myBnds _ self fullBounds.
	savedPatch ifNotNil: [
		damageRect _ myBnds merge: (savedPatch offset extent: savedPatch extent)].
	(savedPatch == nil or: [savedPatch extent ~= myBnds extent])
		ifTrue: [  "allocate new patch form if needed"
			savedPatch _ aCanvas form allocateForm: myBnds extent].
	aCanvas
		contentsOfArea: (myBnds translateBy: aCanvas origin)
		into: savedPatch.
	savedPatch offset: myBnds topLeft.
	^ damageRect
! !

!HandMorph methodsFor: 'drawing' stamp: 'jm 11/24/2002 10:48'!
shadowForm
	"Return a 1-bit shadow of my submorphs.  Assumes submorphs is not empty"
	| bnds canvas |
	bnds _ Rectangle merging: (submorphs collect: [:m | m bounds]).
	canvas _ (FormCanvas extent: bnds extent depth: 1) 
		asShadowDrawingCanvas: Color black.
	canvas translateBy: bnds topLeft negated
		during:[:tempCanvas| self drawSubmorphsOn: tempCanvas].
	^ canvas form offset: bnds topLeft! !

!HandMorph methodsFor: 'drawing' stamp: 'jm 3/29/2008 10:19'!
shadowOffset

	^ 4@5! !

!HandMorph methodsFor: 'drawing' stamp: 'ar 5/28/2000 17:12'!
updateCacheCanvas: aCanvas
	"Update the cached image of the morphs being held by this hand."
	| subBnds rectList |
	"Always check for real translucency -- can't be cached in a form"
	self allMorphsDo: [:m |
		m hasTranslucentColor ifTrue: [
			cacheCanvas _ nil.
			cachedCanvasHasHoles _ true.
			^ self]].

	subBnds _ Rectangle merging: (submorphs collect: [:m | m fullBounds]).
	(cacheCanvas == nil or: [cacheCanvas extent ~= subBnds extent]) ifTrue: [
		cacheCanvas _ (aCanvas allocateForm: subBnds extent) getCanvas.
		cacheCanvas translateBy: subBnds origin negated
			during:[:tempCanvas| self drawSubmorphsOn: tempCanvas].
		self submorphsDo:
			[:m | (m areasRemainingToFill: subBnds) isEmpty
				ifTrue: [^ cachedCanvasHasHoles _ false]].
		cachedCanvasHasHoles _ (cacheCanvas form tallyPixelValues at: 1) > 0.
		^ self].

	"incrementally update the cache canvas"
	rectList _ damageRecorder invalidRectsFullBounds: (0@0 extent: subBnds extent).
	damageRecorder reset.
	rectList do: [:r |
		cacheCanvas translateTo: subBnds origin negated clippingTo: r during:[:c|
			c fillColor: Color transparent.  "clear to transparent"
			self drawSubmorphsOn: c]].! !


!HandMorph methodsFor: 'event handling' stamp: 'jm 6/10/2004 09:53'!
clearUnclaimedKeystrokes

	unclaimedKeystrokes _ OrderedCollection new.
! !

!HandMorph methodsFor: 'event handling' stamp: 'jens 4/17/2010 23:39'!
dragOverList: evt
	| p roots mList mm root |
	p _ evt cursorPoint.
	roots _ self world rootMorphsAt: p.  "root morphs in world"
	roots isEmpty
		ifTrue: [^ Array empty]
		ifFalse: [root _ roots first].
	mList _ root morphsAt: p.
	mList size > 0 ifTrue:
		["NOTE: We really only want the top morph and all its owners"
		mm _ mList first.
		mList _ OrderedCollection new.
		[mm == root] whileFalse:
			[mList addLast: mm.
			mm _ mm owner].
		mList add: root].
	^ mList! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 2/1/2005 20:04'!
gridPointRaw
	"Private!! Returns the nearest grid point to the cursor to be used as the coordinate for the current event. Do not include a cursor offset."

	grid
		ifNil: [^ Sensor cursorPoint]
		ifNotNil: [^ self griddedPoint: Sensor cursorPoint].
! !

!HandMorph methodsFor: 'event handling' stamp: 'jens 8/20/2008 10:31'!
handleDragOver: evt
	| mList allMouseOvers leftMorphs enteredMorphs |
	owner ifNil: [^ self].  "this hand is not in a world"
	"Start with a list consisting of the topmost unlocked morph in the
	innermost frame (pasteUp), and all of its containers in that frame."
	mList _ self dragOverList: evt.

	"Make a list of all potential drag-overs..."
	allMouseOvers _ mList select:
		[:m | m handlesMouseOverDragging: (evt transformedBy: (m transformFrom: self))].
	leftMorphs _ dragOverMorphs select: [:m | (allMouseOvers includes: m) not].
	enteredMorphs _ allMouseOvers select: [:m | (dragOverMorphs includes: m) not].

	"Check for morphs that want to know about anything dragged over them"
	mList do: [:m | (m respondsTo: #mouseMoveDragging:) ifTrue: [
		m mouseMoveDragging: (evt transformedBy: (m transformFrom: self))]].

	"Notify and remove any morphs that have just been left..."
	leftMorphs do: [:m |
		dragOverMorphs remove: m.
		m mouseLeaveDragging: (evt transformedBy: (m transformFrom: self))].


	"Add any new mouse-overs and send mouseEnter:"
	enteredMorphs do: [:m |
		dragOverMorphs add: m.
		mouseOverMorphs remove: m ifAbsent: [].  "Cant be in two places at once"
		m mouseEnterDragging: (evt transformedBy: (m transformFrom: self))].! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 11/29/2007 12:56'!
handleEvent: evt

"xxx disable the control menu
	(evt anyButtonPressed and:
	 [evt controlKeyPressed and:
	 [lastEvent anyButtonPressed not]]) ifTrue: [
		eventTransform _ MorphicTransform identity.
		lastEvent _ evt.
		^ self invokeMetaMenu: evt].
xxx"

	(evt blueButtonPressed and: [Preferences noviceMode not]) ifTrue: [
		lastEvent blueButtonPressed ifFalse: [
			eventTransform _ MorphicTransform identity.
			lastEvent _ evt.
			^ self specialGesture: evt]].

	lastEvent _ evt.
	self position ~= evt cursorPoint ifTrue: [
		self position: evt cursorPoint].

	evt isMouse ifTrue: [
		evt isMouseMove ifTrue: [^ self handleMouseMove: evt].
		evt isMouseDown ifTrue: [^ self handleMouseDown: evt].
		evt isMouseUp ifTrue: [^ self handleMouseUp: evt]].

	evt isKeystroke ifTrue: [
		keyboardFocus ifNotNil: [
			((keyboardFocus isKindOf: Morph) and:
			 [keyboardFocus world isNil])
				ifTrue: [keyboardFocus _ nil]].
		keyboardFocus
			ifNil: [self recordUnclaimedKeystroke: evt]
			ifNotNil: [keyboardFocus keyStroke: evt].
		^ self].
! !

!HandMorph methodsFor: 'event handling' stamp: 'jens 4/19/2010 01:34'!
handleMouseDown: evt
	"Dispatch a mouseDown event."

	| p m localEvt rootForGrab aHalo |
	"if carrying morphs, just drop them"
	self hasSubmorphs ifTrue: [^ self dropMorphsEvent: evt].

	clickState ~~ #idle ifTrue: [^ self checkForDoubleClick: evt].

	(keyboardFocus notNil and: [Preferences noviceMode]) ifTrue: [
		"clear keyboard focus if click is outside the focus morph (needed for Scratch)"
		p _ (keyboardFocus transformFromWorld) transform: evt cursorPoint.
		(keyboardFocus bounds containsPoint: p) ifFalse: [
			self newKeyboardFocus: nil]].

	m _ self recipientForMouseDown:
		(grid  "Don't grid when determining recipient"
			ifNil: [evt]
			ifNotNil: [  "Should really use original cursorPoint, but this will do"
				evt copy setCursorPoint: Sensor cursorPoint]).

	m ifNotNil: [
		(m isKindOf: SpriteHandleMorph) ifFalse: [SpriteHandleMorph vanish]. "needed for Scratch"
		(ScratchMenuTitleMorph menuBarIsActive) ifTrue: [
			(m isKindOf: MenuItemMorph)
				ifTrue: [ScratchMenuTitleMorph deactivateMenuBar ]
				ifFalse: [ScratchMenuTitleMorph closeAllMenus ]].

		aHalo _ self world haloMorphOrNil.
		(aHalo isNil or: [aHalo staysUpWhenMouseIsDownIn: m])
			ifFalse: [self world abandonAllHalos].
		m deleteBalloon.
		(m handlesMouseDown: evt)
			ifTrue:
				["start a mouse transaction on m"
				(self newMouseFocus: m) ifNil: [^ self].
				localEvt _ self transformEvent: evt.
				targetOffset _ localEvt cursorPoint - m position.
				m mouseDown: localEvt.
				clickState == #firstClickDown ifFalse: [
					"ensure that at least one mouseMove: is reported for each mouse transaction:"
					(mouseDownMorph == m) ifTrue: [
						m mouseMove: (localEvt copy setType: #mouseMove)].
					(m handlesMouseOverDragging: localEvt) ifTrue:
						["If m also handles dragOver, enter it in the list"
						dragOverMorphs add: m.
						mouseOverMorphs remove: m ifAbsent: []]]]
			ifFalse:
				["grab m by the appropriate root"
				menuTargetOffset _ targetOffset _ evt cursorPoint.
				rootForGrab _ m rootForGrabOf: m.
				rootForGrab ifNotNil: [self grabMorph: rootForGrab]].
		mouseOverTimes removeKey: m ifAbsent: []].
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 9/19/2006 16:31'!
handleMouseMove: evt
	"Dispatch a mouseMove event."

	| ungriddedEvt |
	clickState ~~ #idle ifTrue: [self checkForDoubleClick: evt].

	mouseDownMorph ifNotNil:
		[mouseDownMorph mouseMove: (self transformEvent: evt)].

	ungriddedEvt _ evt copy setCursorPoint: Sensor cursorPoint.
	submorphs isEmpty
		ifTrue: [
			evt anyButtonPressed
				ifTrue: [self handleDragOver: ungriddedEvt]
				ifFalse: [self handleMouseOver: ungriddedEvt]]
		ifFalse: [self handleDragOver: ungriddedEvt].
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 4/11/2007 10:33'!
handleMouseOver: evt

	| mList allMouseOvers leftMorphs enteredMorphs now t balloonHelpEnabled |
	owner ifNil: [^ self].
	balloonHelpEnabled _ Preferences balloonHelpEnabled.

	"Start with a list consisting of the topmost unlocked morph in the
	innermost frame (pasteUp), and all of its containers in that frame."
	mList _ self mouseOverList: evt.

	now _ Time millisecondClockValue.

	"Make a list of all potential mouse-overs..."
	allMouseOvers _ mList select: [:m |
		(balloonHelpEnabled and: [m wantsBalloon]) or: "to start a timer"
		 [m handlesMouseOver: (evt transformedBy: (m transformFrom: self))]].  "to send mouseEnter:"
	leftMorphs _ mouseOverMorphs select: [:m | (allMouseOvers includes: m) not].
	enteredMorphs _ allMouseOvers select: [:m | (mouseOverMorphs includes: m) not].

	"Notify and remove any mouse-overs that have just been left..."
	leftMorphs do: [:m |
		mouseOverMorphs remove: m.
		m wantsBalloon ifTrue: [m deleteBalloon].
		m mouseLeave: (evt transformedBy: (m transformFrom: self)).
		mouseOverTimes removeKey: m ifAbsent: [] ].

	"Add any new mouse-overs and send mouseEnter: and/or start timers..."
	enteredMorphs do: [:m |
		mouseOverMorphs add: m.
		dragOverMorphs remove: m ifAbsent: [].  "Cant be in two places at once"
		(m handlesMouseOver: evt) ifTrue:
			[m mouseEnter: (evt transformedBy: (m transformFrom: self))].
		m wantsBalloon ifTrue: [mouseOverTimes at: m put: now]].

	mouseOverTimes keys do: [:m |  "check pending timers for lingering"
		t _ mouseOverTimes at: m.
		(now < t "clock wrap" or: [now > (t + 400)]) ifTrue: [  "lingered for 0.4 seconds"
			mouseOverTimes removeKey: m.
			m owner ifNotNil:  "Not deleted during linger (--it happens ;--)"
				[(balloonHelpEnabled and: [m wantsBalloon])
							ifTrue: [m showBalloon: m balloonText]]]].
! !

!HandMorph methodsFor: 'event handling' stamp: 'di 9/14/1998 08:47'!
handleMouseUp: evt
	"Dispatch a mouseUp event."
	| oldFocus |
	clickState ~~ #idle ifTrue: [self checkForDoubleClick: evt].

	"drop morphs being carried, if any"
	self hasSubmorphs ifTrue: [self dropMorphsEvent: evt].
	mouseDownMorph = nil ifTrue: [^ self].

	oldFocus := mouseDownMorph.	"make sure that focus becomes nil."
	mouseDownMorph _ nil.  "mouse focus transaction ends when mouse goes up"
	oldFocus mouseUp: (self transformEvent: evt).

	dragOverMorphs copy do: [:m |
		dragOverMorphs remove: m.
		m mouseLeaveDragging: (evt transformedBy: (m transformFrom: self))].
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 2/25/2009 09:34'!
handleQutEvent
	"Dispatch a closeWindow event."

	self showTemporaryCursor: nil.

	Preferences noviceMode
		ifTrue: [ScratchFrameMorph quitFromMenu]
		ifFalse: [self quitSession].
! !

!HandMorph methodsFor: 'event handling' stamp: 'di 9/29/97 14:24'!
keyboardFocus 
	^ keyboardFocus! !

!HandMorph methodsFor: 'event handling' stamp: 'di 1/4/1999 22:27'!
mouseOverList: evt
	"Returns a list consisting of the topmost unlocked morph in the
	innermost frame (pasteUp), and all of its containers in that frame."

	"This new version treats halos as independent so as not to mask
	mouseovers of morphs beneath an active halo."

	| top |
	top _ self mouseOverList: evt rank: 1.
	(top isEmpty or: [(top last isKindOf: HaloMorph) not])
		ifTrue: [^ top]
		ifFalse: [^ top , (self mouseOverList: evt rank: 2)]! !

!HandMorph methodsFor: 'event handling' stamp: 'jens 4/17/2010 23:39'!
mouseOverList: evt rank: rank 
	"With rank = 1, returns a list consisting of the topmost unlocked morph in the
	innermost frame (pasteUp), and all of its containers in that frame.
	With rank = 2, returns the smae kind of list, but rooted in the next lower
	rootmorph.  This can be useful to get mouseOvers below an active halo."
	| p roots mList mm r |
	p _ evt cursorPoint.
	roots _ self world rootMorphsAt: p.  "root morphs in world"
	roots size >= rank
		ifTrue: [mList _ (roots at: rank) unlockedMorphsAt: p.
				mList size > 0 ifTrue:
					["NOTE: We really only want the top morph and all its owners"
					mm _ mList first.  r _ roots at: rank.
					mList _ OrderedCollection new.
					[mm == r] whileFalse:
						[mList addLast: mm.
						mm _ mm owner].
					mList add: r]]
		ifFalse: [mList _ Array empty].
	^ mList! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 1/8/2006 16:40'!
newKeyboardFocus: aMorphOrNil
	"Make the given morph the new keyboard focus, canceling the previous keyboard focus if any. If the argument is nil, just cance the current keyboard focus."

	| oldFocus |
	aMorphOrNil == keyboardFocus ifTrue: [^ self].  "no change"

	oldFocus _ keyboardFocus.
	keyboardFocus _ aMorphOrNil.
	oldFocus ifNotNil: [oldFocus keyboardFocusChange: false].
	keyboardFocus ifNotNil: [keyboardFocus keyboardFocusChange: true].
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 5/4/2009 09:12'!
newMouseFocus: aMorphOrNil

	((mouseDownMorph isKindOf: MenuItemMorph)
		and: [(aMorphOrNil isKindOf: MenuItemMorph) not])
		ifTrue: [(mouseDownMorph owner isKindOf: MenuMorph)
				ifTrue: ["Crock: If a menu is proffered with the mouse up
						and the user clicks down outside it (as is normal in MVC),
						then the menu goes away and nothing else happens."
						mouseDownMorph owner deleteIfPopUp.
						mouseDownMorph _ nil.
						^ nil]].

	mouseDownMorph _ aMorphOrNil.
	self updateMouseDownTransform.
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 6/1/2004 18:24'!
nextUnclaimedKeystrokeOrNil
	"Answer the next unclaimed keystroke from the buffer or nil if there isn't one."

	(unclaimedKeystrokes isNil or: [unclaimedKeystrokes size = 0])
		ifTrue: [^ nil]
		ifFalse: [^ unclaimedKeystrokes removeFirst]
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 2/24/2009 19:40'!
processEvents
	"Process user input events from the local input devices."

	| evt |
	Sensor quitReceived ifTrue: [self handleQutEvent].

	self handleEvent: (Sensor mouseEventFor: self).
	[Sensor hasQueuedMouseTransitions] whileTrue: [
		self handleEvent: (Sensor mouseEventFor: self)].

	[(evt _ Sensor keyEventOrNilFor: self) notNil]
		whileTrue: [self handleEvent: evt].
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 12/21/2004 21:08'!
recipientForMouseDown: evt
	"Answer the morph that should handle the given mouseDown: event."
	"Details: To get mouse events, a morph must
		a. contain the point at which the mouse went down, and
		b. respond true to handlesMouseDown:, and
		c. be in front of all other submorphs that respond true to handlesMouseDown: and
		d. not be owned by a morph that responds true to preemptsMouseDown:.
If no morph handles the mouse down, the front-most submorph is grabbed. The complexity in this description arises from the need to resolve conflicts when several nested submorphs all want to handle mouse events. The preemptsMouseDown: mechanism allows a morph to intercept mouse events before its submorphs. It is needed only in unusual situations, such as parts bins containing mouse-sensitive objects."

	| p roots coreSample |
	owner ifNil: [^ nil].  "this hand is not in a world"

	p _ evt cursorPoint.
	roots _ owner rootMorphsAt: p.  "root morphs in the world"
	roots size = 0 ifTrue: [
		"no morphs at the given point, so world gets it"
		^ owner].

	"coreSample is submorphs of the front-most root morph in front-to-back order"
	coreSample _ roots first unlockedMorphsAt: p.
	coreSample size = 0 ifTrue: [  "no unlocked morphs at the given point, let world (my owner) handle the event"
		^ owner].

	coreSample do: [:m |
		(m handlesMouseDown: evt) ifTrue: [
			"make sure no enclosing owner prempts mouse down event"
			m _ m allOwners detect: [:o | o preemptsMouseDown: evt] ifNone: [m].
			^ m]].

	"no other morph wants to handle event, so front-most submorph gets event"
	^ coreSample first
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 8/11/2003 21:38'!
recordUnclaimedKeystroke: evt

	unclaimedKeystrokes ifNil: [unclaimedKeystrokes _ OrderedCollection new].
	unclaimedKeystrokes addLast: evt.
	[unclaimedKeystrokes size > 10] whileTrue: [unclaimedKeystrokes removeFirst].  "keep only most recent N keystrokes"
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 7/3/2004 17:46'!
specialGesture: evt
	"A special gesture (cmd-mouse on the Macintosh) supports different ways to bring up halos on a morph."

	Preferences noviceMode ifTrue: [^ self].

	self newMouseFocus: nil.

	"if carrying morphs, just drop them"
	self hasSubmorphs ifTrue: [^ self dropMorphsEvent: evt].

	targetOffset _ menuTargetOffset _ self position.
	argument _ self argumentOrNil.
	self popUpHaloFromClick: evt.
! !

!HandMorph methodsFor: 'event handling'!
transformEvent: evt
	"Transform the given event by the transform recorded when the mouse went down."

	^ evt transformedBy: eventTransform
! !

!HandMorph methodsFor: 'event handling' stamp: 'jm 6/17/1998 08:57'!
updateMouseDownTransform
	"To help with, eg, autoscrolling"

	mouseDownMorph
		ifNil: [eventTransform _ MorphicTransform identity]
		ifNotNil: [eventTransform _ mouseDownMorph transformFrom: self].

! !


!HandMorph methodsFor: 'double click support' stamp: 'jm 5/2/2009 17:52'!
checkForDoubleClick: evt
	"Process the given mouse event to detect a click, double-click, or drag."

	| t |
	t _ evt timestamp - firstClickEvent timestamp.
	clickState = #firstClickDown ifTrue: [
		t > HoldTime ifTrue: [
			clickState _ #idle.
			clickClient mouseHold: firstClickEvent.
			^ self resetClickState].
		(((self transformEvent: evt) cursorPoint - firstClickEvent cursorPoint) r > 0) ifTrue: [
			"consider it a drag if hand moves"
			clickState _ #idle.
			clickClient startDrag: firstClickEvent.
			^ self resetClickState].
		evt isMouseUp ifTrue: [
			clickState _ #firstClickUp.
			^ self]].

	clickState = #firstClickUp ifTrue: [
		evt isMouseDown ifTrue: [
			clickState _ #idle.
			clickClient doubleClick: firstClickEvent.
			^ self resetClickState].
		t > DoubleClickTime ifTrue: [
			clickState _ #idle.
			clickClient click: firstClickEvent.
			^ self resetClickState]].
! !

!HandMorph methodsFor: 'double click support' stamp: 'jm 11/18/2008 19:27'!
resetClickState
	"Reset the double-click detection state to normal (i.e., not waiting for a double-click)."

	clickClient _ nil.
	clickState _ #idle.
	firstClickEvent _ nil.
"	eventTransform _ MorphicTransform identity."
! !

!HandMorph methodsFor: 'double click support' stamp: 'jm 12/4/2005 11:21'!
waitForClicksOrDrag: aMorph event: evt
	"Wait until the difference between click, double-click, or drag gesture is known, then inform the given morph what transpired. This message is sent when the given morph first receives a mouse-down event. If the mouse button goes up, then down again within DoubleClickTime, then 'doubleClick: evt' is sent to the morph. If the mouse button goes up but not down again within DoubleClickTime, then the message 'click: evt' is sent to the morph. Finally, if the button does not go up within DoubleClickTime, then 'startDrag: evt' is sent to the morph. In all cases, the event supplied is the original mouseDown event that initiated the gesture. mouseMove: and mouseUp: events are not sent to the morph until it becomes the mouse focus, which is typically done by the client in its click:, doubleClick:, or startDrag: methods." 

	clickClient _ aMorph.
	clickState _ #firstClickDown.
	firstClickEvent _ evt.
! !

!HandMorph methodsFor: 'double click support' stamp: 'jm 3/10/2005 22:16'!
waitingForDoubleClick
	"Answer true if I am waiting to resolve a possible double-click."

	^ clickState ~~ #idle
! !


!HandMorph methodsFor: 'grabbing/dropping' stamp: 'jm 2/1/2005 20:14'!
attachMorph: m
	"Position the center of the given morph under this hand, then grab it. This method is used to grab far away or newly created morphs."

	| p |
	formerPosition _ m position.
	p _ self griddedPoint: (self position - (m extent // 2)).
	m position: p.
	self addMorphBack: m.
! !

!HandMorph methodsFor: 'grabbing/dropping' stamp: 'jens 12/14/2009 04:53'!
dropMorphsEvent: evt
	"Drop all the morphs this hand is currently holding in response to the given event."
	"Details: All submorphs of the front-most composite morph under the hand are given an opportunity to accept the dropping morph. If none of these accepts it, or if there is no morph under the hand, then the morph drops into the world."

	| morphToDrop newOwner |
	owner ifNil: [^ self].
	self changed.
	self submorphs reverseDo: [:m |
		"drop in reverse order to maintain back-to-front ordering"
		morphToDrop _ m.
		newOwner _ self dropTargetFor: morphToDrop event: evt.
		newOwner ifNil: [  "drop not allowed"
			self rejectDropMorph: morphToDrop event: evt.
			^ self].

		newOwner acceptDroppingMorph: morphToDrop event: evt.
		morphToDrop justDroppedInto: newOwner event: evt.
"		morphToDrop owner = self ifTrue: [self world addMorphFront: m]"].

	self layoutChanged.
	formerOwner _ nil.
	formerPosition _ nil.
	drawHalfSize _ false.
! !

!HandMorph methodsFor: 'grabbing/dropping' stamp: 'jm 10/11/2002 06:45'!
dropTargetFor: aMorph event: evt
	"Return the morph that the given morph is to be dropped onto.  Return nil if we must repel the morph.  Return the world, if no other morph wants the dropping morph."

	| root coreSample |
	aMorph willingToBeEmbeddedUponLanding ifFalse: [^ self world].
	root _ nil.
	owner submorphs reverseDo: [:m |
		((m fullContainsPoint: evt cursorPoint) and:
		 [(m isKindOf: HaloMorph) not]) ifTrue: [root _ m]].
	root == nil ifTrue: [^ self world].
	coreSample _ root morphsAt: evt cursorPoint.
	coreSample do:
		[:m |
			(m repelsMorph: aMorph event: evt) ifTrue:
				[^ nil]].

	coreSample do:
		[:m |
			(m wantsDroppedMorph: aMorph event: evt) ifTrue: [^ m]].
	^ self world
! !

!HandMorph methodsFor: 'grabbing/dropping' stamp: 'jens 9/25/2009 11:18'!
grabMorph: aMorph
	"Grab the given morph (i.e., add it to this hand and remove it from its current owner) without changing its position. This is used to pick up a morph under the hand's current position, versus attachMorph: which is used to pick up a morph that may not be near this hand."

	| localPt morphToGrab p sm offset |
	formerOwner _ aMorph owner.
	localPt _ aMorph pointFromWorld: self position.

	"retain the former position relative to the former owner,
	in case the former owner gets scrolled or moved while dragging"
	formerOwner isNil
		ifTrue: [ formerPosition _ aMorph position ]
		ifFalse: [ formerPosition _ aMorph position - formerOwner position ].

	"if aMorph is currently within a ScratchScriptsMorph, retain
	the former position relative to it, so it can be reattached to its
	former script"
	sm _ aMorph ownerThatIsA: ScratchScriptsMorph.
	sm ifNotNil: [formerPosition _ aMorph position - sm position].


	morphToGrab _ aMorph aboutToBeGrabbedBy: self.
	morphToGrab ifNil: [^ self].

	offset _ morphToGrab position - localPt.
	((formerOwner isKindOf: ScratchStageMorph) and:
	 [formerOwner isQuarterSize])
		ifTrue: [
			drawHalfSize _ true.
			offset _ (aMorph extent // 2) negated]
		ifFalse: [
			drawHalfSize _ false].

	p _ self griddedPoint: (self position + offset).
	morphToGrab position: p.

	self addMorphBack: morphToGrab.! !

!HandMorph methodsFor: 'grabbing/dropping' stamp: 'jm 2/1/2005 20:36'!
grabMorphFromMenu: aMorph
	"Grab the given morph (i.e., add it to this hand and remove it from its current owner) without changing its position. This is used to pick up a morph under the hand's current position, versus attachMorph: which is used to pick up a morph that may not be near this hand."

	| morphToGrab p |
	morphToGrab _ aMorph aboutToBeGrabbedBy: self.
	p _ self position + morphToGrab positionInWorld - menuTargetOffset.
	morphToGrab position: (self griddedPoint: p).
	self addMorphBack: morphToGrab.
! !

!HandMorph methodsFor: 'grabbing/dropping' stamp: 'jm 10/11/2002 16:55'!
rejectDropMorph: aMorph event: evt
	"aMorph has been rejected, and must be put back somewhere.  There are three cases:
	(1)  It remembers its former owner and position, and goes right back there
	(2)  It remembers its former position only, in which case it was torn off from a parts bin, and the UI is that it floats back to its donor position and then vanishes.
	(3)  Neither former owner nor position is remembered, in which case it is just deleted"

	(formerOwner notNil and: [formerOwner isPartsBin not]) ifTrue:
		[^ aMorph slideBackToFormerSituation: evt].

	formerPosition ifNotNil:  "Position but no owner -- can just make it vanish"
		[^ aMorph vanishAfterSlidingTo: formerPosition event: evt].
		
	aMorph delete.
! !


!HandMorph methodsFor: 'world menu' stamp: 'sma 6/5/2000 13:51'!
appearanceDo
	"Build and show the appearance menu for the world."

	self appearanceMenu popUpForHand: self! !

!HandMorph methodsFor: 'world menu' stamp: 'jm 6/14/2004 14:12'!
appearanceMenu
	"Build the appearance menu for the world."

	| screenCtrl menu |
	screenCtrl _ ScreenController new.
	menu _ (MenuMorph entitled: 'appearance...') defaultTarget: self.
	menu addStayUpItem.

	menu add: 'set display depth...' action: #setDisplayDepth.
	menu balloonTextForLastItem: 'set the number of bits per pixel for the display'.
	menu add: 'set desktop color...' action: #changeBackgroundColor.
	menu balloonTextForLastItem: 'set a color to use as desktop background'.
	menu addLine.

	menu add: 'full screen on' target: screenCtrl action: #fullScreenOn.
	menu balloonTextForLastItem: 'puts you in full-screen mode, if not already there'.
	menu add: 'full screen off' target: screenCtrl action: #fullScreenOff.
	menu balloonTextForLastItem: 'if in full-screen mode, takes you out of it'.
	menu addLine.

	menu add: 'window colors...' target: Preferences action: #windowSpecificationPanel.
	menu balloonTextForLastItem: 'Lets you specify colors for standard system windows'.
	menu add: 'system fonts...' target: self action: #standardFontDo.
	menu balloonTextForLastItem: 'Choose the standard fonts to use for code, lists, menus, window titles, etc'.
	menu add: 'text highlight color...' target: Preferences action: #chooseTextHighlightColor.
	menu balloonTextForLastItem: 'Choose which color should be used for text highlighting in Morphic'.
	menu add: 'insertion point color...' target: Preferences action: #chooseInsertionPointColor.
	menu balloonTextForLastItem: 'Choose which color to use for the text insertion point in Morphic'.
	menu addLine.

	menu addUpdating: #menuColorString target: Preferences action: #toggleMenuColorPolicy.
	menu balloonTextForLastItem: 'Governs whether menu colors should be derived from the desktop color'.
	menu addUpdating: #roundedCornersString target: Preferences action: #toggleRoundedCorners.
	menu balloonTextForLastItem: 'Governs whether morphic windows and menus should have rounded corners'.
	menu addLine.

	menu add: 'clear turtle trails from desktop' target: self world action: #clearTurtleTrails.
	menu balloonTextForLastItem: 'remove trails left by objects moving with their pens down'.

	menu add: 'unhide hidden objects' action: #showHiders.
	menu balloonTextForLastItem: 'If any items on the world desktop are currently hidden, make them visible'.

	^ menu! !

!HandMorph methodsFor: 'world menu' stamp: 'jm 5/31/2003 16:37'!
buildWorldMenu
	"Build the meta menu for the world."

	| menu |
	menu _ MenuMorph new defaultTarget: self.
	menu addStayUpItem.

	menu add: 'previous project' target: owner action: #goBack.
	menu add: 'jump to project...' target: owner action: #jumpToProject.
	menu addLine.

	menu add: 'restore display' target: self world action: #restoreDisplay.
	menu addLine.

	menu add: 'open...' action: #openWindow.
	menu add: 'windows...' action: #windowsDo.
	menu add: 'changes...' action: #changesDo.
	menu add: 'help...' action: #helpDo.
	menu add: 'appearance...' action: #appearanceDo.

	menu addLine.
	menu add: 'new morph...' action: #newMorph.
	menu add: 'debug...' action: #debugDo.
	menu addLine.

	menu add: 'save' action: #saveSession.
	menu add: 'save as...' action: #saveAs.
	menu add: 'save and quit' action: #saveAndQuit.
	menu add: 'quit' action: #quitSession.

	^ menu
! !

!HandMorph methodsFor: 'world menu' stamp: 'sma 6/5/2000 13:52'!
changesDo
	"Build and show the changes menu for the world."

	self changesMenu popUpForHand: self! !

!HandMorph methodsFor: 'world menu' stamp: 'jm 12/2/2003 20:49'!
changesMenu
	"Build the changes menu for the world."

	| menu |
	menu _ (MenuMorph entitled: 'changes...') defaultTarget: self.
	menu addStayUpItem.

	menu add: 'create new change set...' target: ChangeSorter action: #newChangeSet.
	menu balloonTextForLastItem: 'Create a new change set and make it the current one.'.

	menu add: 'check change set for slips' target: Smalltalk changes action: #lookForSlips.
	menu balloonTextForLastItem: 'Check the current change set for halts, references to the Transcript, etc., and if any such thing is found, open up a message-list browser detailing all possible slips.'.

	menu addLine.
	menu add: 'simple change sorter' selector: #openChangeSorter: argument: 1.
	menu balloonTextForLastItem: 'Open a 3-paned changed-set viewing tool'.

	menu add: 'dual change sorter' selector: #openChangeSorter: argument: 2.
	menu balloonTextForLastItem: 'Open a change sorter that shows you two change sets at a time, making it easy to copy and move methods and classes between them.'.
	menu addLine.

	menu add: 'recover recent changes...' action: #openChangesLog.
	menu balloonTextForLastItem: 'Open a browser on the changes log. Useful for recovering work after a crash.'.

	^ menu
! !

!HandMorph methodsFor: 'world menu' stamp: 'sma 6/5/2000 13:52'!
debugDo
	"Build and show the debug menu for the world."

	self debugMenu popUpForHand: self! !

!HandMorph methodsFor: 'world menu' stamp: 'jm 12/9/2003 09:11'!
debugMenu
	"Build the scripting menu for the world."

	| menu |
	menu _ (MenuMorph entitled: 'debug...') defaultTarget: self.
	menu addStayUpItem.
	menu add: 'inspect world' target: owner action: #inspect.
	menu add: 'start MessageTally' action: #startMessageTally.
	menu addLine.

	"(self hasProperty: #errorOnDraw) ... Later make following come up only when needed:"
		menu add: 'start drawing again' target: owner action: #resumeAfterDrawError.
		menu add: 'start stepping again' target: owner action: #resumeAfterStepError.

	^ menu
! !

!HandMorph methodsFor: 'world menu' stamp: 'sma 6/5/2000 13:52'!
helpDo
	"Build and show the help menu for the world."

	self helpMenu popUpForHand: self! !

!HandMorph methodsFor: 'world menu' stamp: 'jm 5/31/2003 17:12'!
helpMenu
	"Build the help menu for the world."

	| screenCtrl menu |
	screenCtrl _ ScreenController new.
	menu _ (MenuMorph entitled: 'help...') defaultTarget: self.
	menu addStayUpItem.
	menu add: 'about this system...' target: Smalltalk action: #aboutThisSystem.
	menu balloonTextForLastItem: 'current version information'.
	menu add: 'command-key help' target: Utilities action: #openCommandKeyHelp.
	menu balloonTextForLastItem: 'summary of keyboard shortcuts'.
	menu add: 'preferences...' target: Preferences action: #openPreferencesInspector.
	menu balloonTextForLastItem: 'view and change various options'.
	menu addLine.

	menu add: 'set author initials...' target: screenCtrl action: #setAuthorInitials.
	menu balloonTextForLastItem: 'set initials used to identify method editors'.
	menu add: 'memory statistics' target: screenCtrl action: #vmStatistics.
	menu balloonTextForLastItem: 'memory and garbage collection statistics'.
	menu add: 'space left' target: screenCtrl action: #garbageCollect.
	menu balloonTextForLastItem: 'do a full garbage collect and report space left'.

	^ menu
! !

!HandMorph methodsFor: 'world menu' stamp: 'jm 8/11/2003 21:09'!
newMorph

	| menu catDict cat subMenu |
	menu _ (MenuMorph entitled: 'Add a new morph') defaultTarget: self.
	menu addStayUpItem.
	menu add: 'grab patch from screen' action: #grabDrawingFromScreen.
	menu addLine.

	menu add: 'from paste buffer' action: #pasteMorph.
	menu add: 'from alphabetical list' subMenu: self alphabeticalMorphMenu.
	menu addLine.

	catDict _ Dictionary new.
	self morphClassesForNewMorphMenu do: [:c |
		cat _ c category.
		(cat beginsWith: 'Morphic-')
			ifTrue: [cat _ cat copyFrom: ('Morphic-' size + 1) to: cat size].
		(catDict includesKey: cat) 
			ifTrue: [(catDict at: cat) addLast: c]
			ifFalse: [catDict at: cat put: (OrderedCollection with: c)]].

	catDict keys asArray sort do: [:k |
		subMenu _ MenuMorph new.
		((catDict at: k) asArray sort: [:c1 :c2 | c1 name < c2 name]) do: [:c |
			subMenu
				add: c name
				target: self
				selector: #newMorphOfClass:event:
				argument: c].
		menu add: k subMenu: subMenu].

	menu popUpForHand: self.
! !

!HandMorph methodsFor: 'world menu' stamp: 'JM 11/10/2011 10:54'!
openMenu
	"Build the open window menu for the world."

	| menu |
	menu _ (MenuMorph entitled: 'open...') defaultTarget: self.
	menu addStayUpItem.
	menu add: 'browser' action: #openBrowser.
	menu add: 'workspace' action: #openWorkspace.
	menu add: 'file list' action: #openFileList.
	menu add: 'transcript' action: #openTranscript.
	menu addLine.
	menu add: 'simple change sorter' selector: #openChangeSorter: argument: 1.
	menu add: 'dual change sorter' selector: #openChangeSorter: argument: 2.
	menu addLine.
	menu add: 'mvc project' action: #openMVCProject.
	menu add: 'morphic project' action: #openMorphicProject.
	menu addLine.
	menu add: 'Generator' action: #openScratchFrame.
	menu add: 'Elements' action: #openElementsBrowser.
	^ menu
! !

!HandMorph methodsFor: 'world menu' stamp: 'sma 6/5/2000 13:53'!
openWindow
	"Build and show the open menu for the world."

	self openMenu popUpForHand: self! !

!HandMorph methodsFor: 'world menu' stamp: 'sma 6/5/2000 13:57'!
standardFontDo
	"Build and show the standard font menu"

	Preferences fontConfigurationMenu popUpForHand: self! !

!HandMorph methodsFor: 'world menu' stamp: 'sma 6/5/2000 13:57'!
windowsDo
	"Build the windows menu for the world."

	self windowsMenu popUpForHand: self! !

!HandMorph methodsFor: 'world menu' stamp: 'jm 7/6/2008 17:40'!
windowsMenu
	"Build the windows menu for the world."

	| menu |
	menu _ (MenuMorph entitled: 'windows...') defaultTarget: self.
	menu addStayUpItem.
	menu add: 'find window' action: #findWindow.
	menu balloonTextForLastItem: 'Presents a list of all windows; if you choose one from the list, it becomes the active window.'.

	menu add: 'find changed browsers...' action: #findDirtyBrowsers.
	menu balloonTextForLastItem: 'Presents a list of browsers that have unsubmitted changes; if you choose one from the list, it becomes the active window.'.

	menu add: 'find changed windows...' action: #findDirtyWindows.
	menu balloonTextForLastItem: 'Presents a list of all windows that have unsubmitted changes; if you choose one from the list, it becomes the active window.'.

	menu addLine.
	menu add: 'collapse all windows' action: #collapseAll.
	menu balloonTextForLastItem: 'Reduce all open windows to collapsed forms that only show titles.'.

	menu add: 'expand all windows' action: #expandAll.
	menu balloonTextForLastItem: 'Expand all collapsed windows back to their expanded forms.'.

	menu addLine.
	menu add: 'delete unchanged windows' action: #closeUnchangedWindows.
	menu balloonTextForLastItem: 'Deletes all windows that do not have unsaved text edits.'.

	menu add: 'delete all debug windows' action: #closeDebugWindows.
	menu balloonTextForLastItem: 'Deletes all debug windows.'.

	menu addLine.
	menu addUpdating: #staggerPolicyString target: Preferences action: #toggleWindowPolicy.
	menu balloonTextForLastItem: 'stagger: new windows positioned so you can see a portion of each one.
tile: new windows positioned so that they do not overlap others, if possible.'.

	^ menu! !


!HandMorph methodsFor: 'world menu commands' stamp: 'jm 6/14/2004 14:15'!
argumentOrNil
	"Answer the root of the front-most morph under the cursor. If the cursor is not over any morph, answer nil."

	owner submorphsDo: [:m |
		((m fullContainsPoint: targetOffset) and: [m isLocked not]) ifTrue: [^ m]].
	^ nil
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 8/19/1998 11:54'!
buildDebugHandleMenuFor: argMorph
	"Build the menu for the given morph's halo's debug handle."
	argument _ argMorph.
	^ argMorph debuggingMenuFor: self! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 1/24/2004 19:03'!
buildMorphHandleMenuFor: argMorph
	"Build the morph menu for the given morph's halo's menu handle. This menu has two sections. The first section contains commands that are interpreted by the hand; the second contains commands provided by the target morph. This method allows the morph to decide which items should be included in the hand's section of the menu."

	| menu |
	argMorph == owner "i.e., the world" ifTrue:
		[^ self buildWorldMenu].

	argument _ argMorph.
	menu _ MenuMorph new defaultTarget: self.
	menu addStayUpItem.
	argMorph addAddHandMenuItemsForHalo: menu hand: self.
	menu defaultTarget: argMorph.
	argMorph addCustomMenuItems: menu hand: self.
	menu defaultTarget: self.
	menu addLine.

	^ menu
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 1/24/2004 19:09'!
buildMorphMenuFor: argMorph
	"Build the morph menu. This menu has two sections. The first section contains commands that are handled by the hand; the second contains commands handled by the argument morph."

	| menu |
	argument _ argMorph.
	menu _ MenuMorph new defaultTarget: self.
	menu addStayUpItem.

	menu add: 'grab' action: #grabMorph.
	menu add: 'delete' action: #dismissMorph.
	menu add: 'duplicate' action: #duplicateMorph.
	menu add: 'resize' action: #resizeMorph.
	menu add: 'change color...' target: argMorph action: #changeColor.
	menu add: 'center in owner' target: argMorph action: #centerInOwner.
	menu addLine.

	menu add: 'go behind' action: #goBehind.
	menu add: 'add halo' action: #addHalo.
	menu add: 'copy to paste buffer' action: #copyToPasteBuffer.
	menu addLine.

	self potentialEmbeddingTargets size > 1 ifTrue:
		[menu add: 'embed...' action: #placeArgumentIn].

	(argMorph morphsAt: targetOffset) size > 1 ifTrue: [
		menu add: 'submorphs...'
			target: self
			selector: #selectSubmorphToOperateOn:sending:event:
			argumentList: (Array with: argMorph with: #operateOnSubmorph:event:)].
	menu addLine.

	Smalltalk isMorphic
		ifTrue: [menu add: 'inspect' action: #inspectMorph]
		ifFalse: [menu add: 'inspect (in MVC)' action: #inspectMorph.
				menu add: 'inspect' action: #inspectMorphInMorphic].
	menu add: 'browse' target: argument action: #browseHierarchy.
	menu add: 'make own subclass' action: #subclassMorph.
	menu addLine.

	"add commands supplied by the morph itself"
	menu defaultTarget: argMorph.
	argMorph addCustomMenuItems: menu hand: self.

	^ menu
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 9/3/1999 09:28'!
changeBackgroundColor

	self changeColorTarget: self world selector: #color: originalColor: self world color.

! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 6/17/1999 14:03'!
changeColor
	argument changeColor! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 9/3/1999 09:15'!
changeColorTarget: aMorph selector: aSymbol

	^ self changeColorTarget: aMorph selector: aSymbol originalColor: Color white! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 11/28/1999 23:17'!
changeColorTarget: aMorph selector: aSymbol originalColor: aColor

	^ ColorPickerMorph new
		sourceHand: self;
		target: aMorph;
		selector: aSymbol;
		originalColor: aColor;
		addToWorld: self world
			near: (aMorph
					ifNil: [Rectangle center: self position extent: 20]
					ifNotNil: [aMorph == self world
								ifTrue: [aMorph viewBox bottomLeft + (20@-20) extent: 200]
								ifFalse: [aMorph fullBounds]]);
		yourself! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 5/13/1998 15:12'!
chooseColor
	"Wait for the user to select a color and return that color."
	"Details: Waiting for the user is implemented by running the interaction loop until the user has selected a color or dismisse the color picker."

	| w colorPicker |
	w _ self world.
	colorPicker _ self changeColorTarget: nil selector: nil.
	[colorPicker isInWorld] whileTrue: [w doOneCycle].
	^ colorPicker selectedColor
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 1/22/98 16:04'!
chooseTargetSubmorphOf: root caption: caption
	"Put up a menu of possible target names, with the given caption"

	| possibleTargets menu |
	possibleTargets _ root morphsAt: menuTargetOffset.
	possibleTargets size = 1 ifTrue: [^ possibleTargets first].
	menu _ CustomMenu new.
	possibleTargets do: [:m | menu add: (self submorphNameFor: m) action: m].
	^ caption size == 0
		ifTrue:
			[menu startUp]
		ifFalse:
			[menu startUpWithCaption: caption]! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 7/6/2008 17:45'!
closeDebugWindows
	"Close all debugger windows."

	(SelectionMenu confirm: 'Really close all debug windows?')
		ifFalse: [^ self].

	World submorphs do: [:m |
		(m isKindOf: PreDebugWindow) ifTrue: [m delete].
		((m isKindOf: SystemWindow) and: [m model isKindOf: Debugger])
			ifTrue: [m delete]].
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 9/23/1998 01:33'!
closeUnchangedWindows
	"Present a menu of window titles for all windows with changes,
	and activate the one that gets chosen."

	(SelectionMenu confirm:
'Do you really want to close all windows
except those with unaccepted edits?')
		ifFalse: [^ self].

	(SystemWindow windowsIn: self world satisfying: [:w | w model canDiscardEdits])
		do: [:w | w delete]! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 2/21/2000 16:01'!
collapseAll
	"Collapse all windows"
	(SystemWindow windowsIn: self world satisfying: [:w | w isCollapsed not])
		reverseDo: [:w | w collapseOrExpand.  self world displayWorld].
	self collapseNonWindows! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 10/5/2002 06:37'!
collapseNonWindows

	| nonWindowMorphs |
	nonWindowMorphs _ self world submorphs
		select: [:m | (m isKindOf: SystemWindow) not].
	nonWindowMorphs do: [:m | m collapse].
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 6/10/2004 09:46'!
copyToPasteBuffer
	"Save this morph in the paste buffer. This is useful for copying morphs between projects."

	argument isMorph
		ifTrue: [
			PasteBuffer _ argument fullCopy.
			PasteBuffer aboutToBeGrabbedBy: self]
		ifFalse: [PasteBuffer _ nil].
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 4/16/1998 14:33'!
dismissMorph
	self world abandonAllHalos; stopStepping: argument.
	argument delete
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 1/13/98 10:48'!
drawingClass

	^ SketchMorph! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 10/7/2002 07:27'!
duplicateMorph

	| newMorph |
	newMorph _ argument fullCopy.
	self grabMorphFromMenu: newMorph.
	formerPosition _ argument position.
	^ newMorph
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 5/19/1998 09:53'!
expandAll
	"Expand all windows"
	(SystemWindow windowsIn: self world satisfying: [:w | w isCollapsed])
		reverseDo: [:w | w collapseOrExpand.  self world displayWorld]! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 12/7/2005 16:32'!
findDirtyBrowsers
	"Present a menu of window titles for browsers with changes, and activate the one that gets chosen."

	| menu |
	menu _ MenuMorph new.
	(SystemWindow windowsIn: self world
		satisfying: [:w | (w model isKindOf: Browser) and: [w model canDiscardEdits not]])
		do: [:w | menu add: w label target: w action: #activate].
	menu submorphs size > 0 ifTrue: [menu popUpForHand: self].
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 12/7/2005 16:32'!
findDirtyWindows
	"Present a menu of window titles for all windows with changes, and activate the one that gets chosen."

	| menu |
	menu _ MenuMorph new.
	(SystemWindow windowsIn: self world
		satisfying: [:w | w model canDiscardEdits not])
		do: [:w | menu add: w label target: w action: #activate].

	menu submorphs size > 0 ifTrue: [menu popUpForHand: self].
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 12/7/2005 16:33'!
findWindow
	"Present a menu of window titles, and activate the one that gets chosen. Collapsed windows appear below the line, expand if chosen."

	| menu expanded collapsed nakedMorphs |
	menu _ MenuMorph new.
	expanded _ SystemWindow windowsIn: self world satisfying: [:w | w isCollapsed not].
	collapsed _ SystemWindow windowsIn: self world satisfying: [:w | w isCollapsed].
	nakedMorphs _ self world submorphs select: [:m | (m isKindOf: SystemWindow) not].
	(expanded isEmpty & (collapsed isEmpty & nakedMorphs isEmpty)) ifTrue: [^ self beep].
	(expanded asSortedCollection: [:w1 :w2 | w1 label caseInsensitiveLessOrEqual: w2 label]) do:
		[:w | menu add: w label target: w action: #activateAndForceLabelToShow.
			w model canDiscardEdits ifFalse: [menu lastItem color: Color red]].
	(expanded isEmpty | (collapsed isEmpty & nakedMorphs isEmpty)) ifFalse: [menu addLine].
	(collapsed asSortedCollection: [:w1 :w2 | w1 label caseInsensitiveLessOrEqual: w2 label]) do: 
		[:w | menu add: w label target: w action: #collapseOrExpand.
		w model canDiscardEdits ifFalse: [menu lastItem color: Color red]].
	nakedMorphs isEmpty ifFalse: [menu addLine].
	(nakedMorphs asSortedCollection: [:w1 :w2 | w1 externalName caseInsensitiveLessOrEqual: w2 externalName]) do:
		[:w | menu add: w externalName target: w action: #comeToFrontAndAddHalo].
	menu addTitle: 'find window'.

	menu popUpForHand: self.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 11/16/97 16:28'!
goBehind

	argument goBehind
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 8/1/97 17:04'!
grabDrawingFromScreen
	"Allow the user to specify a rectangular area of the Display, capture the pixels from that area, and use them to create a new drawing morph. Attach the result to the hand."

	| m |
	m _ self drawingClass new form: Form fromUser.
	self attachMorph: m.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 1/26/98 18:47'!
grabMorph

	self grabMorphFromMenu: argument.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 4/21/1998 21:47'!
inspectMorph
	| targetMorph |
	targetMorph _ self chooseTargetSubmorphOf: argument caption: 'inspect whom?
(deepest at top)'.
	targetMorph ifNotNil: [targetMorph inspect]
	
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 4/18/1998 10:26'!
inspectMorphInMorphic

	self attachMorph: ((Inspector openAsMorphOn: argument) extent: 300@200)! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 12/7/2005 16:33'!
invokeMetaMenu: evt
	"Invoke the meta menu. If the hand is over the background, the world menu is presented. If it is over a morph, a menu of operations for that morph is presented. Each menu entry contains a string to be presented in the menu and a selector. If the selector takes an argument, the mouse-down event that invoked the menu is passed as an argument. This lets the command know which hand invoked it in order to do things like attaching the result of the command to that hand.

If the hand is over the background and the shift key is pressed, the find-window menu is immediately put up.

If the hand is over the background but the yellow button was pressed, an alternate menu, which individual users are encouraged to personalize, is put up -- see HandMorph.yellowButtonClickOnDesktopWithEvent:"

	| menu |
	Preferences noviceMode ifTrue: [^ self].

	"if carrying morphs, just drop them"
	self hasSubmorphs ifTrue: [^ self dropMorphsEvent: evt].

	targetOffset _ menuTargetOffset _ self position.
	argument _ self argumentOrNil.
	argument == nil
		ifTrue: [
			evt shiftPressed
				ifFalse: [  "put put screen menu"
					menu _ self buildWorldMenu.
					menu addTitle: 'World']
				ifTrue: [^ self findWindow]]
		ifFalse: [
			menu _ self buildMorphMenuFor: argument.
			menu addTitle: argument class name].

	menu popUpForHand: self.

! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sma 6/5/2000 13:52'!
jumpToProject
	(Project buildJumpToMenu: (MenuMorph new defaultTarget: Project; addTitle: 'Projects'))
		popUpForHand: self! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 7/23/2003 23:30'!
newMorphOfClass: morphClass event: evt
	"Attach a new morph of the given class to the invoking hand."

	| m |
	m _ morphClass new.
	evt hand attachMorph: m.
	owner startSteppingSubmorphsOf: m.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 12/6/1999 10:04'!
openBrowser
	Browser openBrowser! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 10/18/1999 22:44'!
openChangeSorter: oneOrTwo
	oneOrTwo = 1
		ifTrue: [ChangeSorter new morphicWindow openInWorld: self world]
		ifFalse: [DualChangeSorter new morphicWindow openInWorld: self world]! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 5/11/1998 16:09'!
openChangesLog
	ChangeList browseRecentLog! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jens 2/10/2009 01:06'!
openElementsBrowser

	| m |
	m _ ElementsMethodEditorMorph new.
	m openInWorld.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 8/4/1998 18:21'!
openFileList
	FileList openAsMorph openInWorld: self world! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 5/4/1998 22:35'!
openMVCProject

	ProjectViewMorph newMVCProject openInWorld.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 6/9/1999 15:45'!
openMorphicProject

	(ProjectViewMorph newMorphicProjectOn: nil) openInWorld.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'JM 11/10/2011 10:54'!
openScratchFrame

	| m |
	m _ ScratchFrameMorph new.
	m extent: Display extent - 50.
	m position: 0@0.
	m startup.
	m newScratchProject.
	m openInWorld.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 10/18/1999 22:39'!
openTranscript
	(Transcript openAsMorphLabel: 'Transcript')
		openInWorld: self world! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 8/4/1998 18:21'!
openWorkspace
	Workspace new openAsMorphLabel: 'Workspace' inWorld: self world! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 12/7/2005 16:33'!
operateOnSubmorph: aMorph event: evt
	"Invoke the morph menu for the given submorph."

	| menu |
	menu _ self buildMorphMenuFor: aMorph.
	menu addTitle: aMorph class name.
	menu popUpForHand: self.

! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 6/10/2004 09:45'!
pasteMorph

	| m |
	PasteBuffer ifNil: [^ self inform: 'Nothing to paste.'].
	self attachMorph: (m _ PasteBuffer fullCopy).
	m align: m center with: self position.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 9/9/1998 15:49'!
placeArgumentIn 
	"Let the user choose a new layer in the core sample for the argument to reside in, but don't allow strange loops"
	|  targetMorph |
	targetMorph _ self selectEmbedTargetMorph: ('Place ', argument externalName, ' in...').
	targetMorph ifNotNil:
		[targetMorph addMorphFront: argument fromWorldPosition: argument position]
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 5/29/2003 19:49'!
potentialEmbeddingTargets
	"Answer a list of targets into which the hand's arguement could be embedded"

	| possibleTargets |
	possibleTargets _ self world morphsAt: menuTargetOffset.
	argument ifNotNil:
		[possibleTargets removeAll: argument allMorphs].
	^ possibleTargets! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 5/11/1998 16:19'!
quitSession
	Smalltalk
		snapshot: (self confirm: 'Save changes before quitting?' orCancel: [^ self])
		andQuit: true! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 5/7/1998 01:21'!
resizeMorph
	| handle minExtent |
	argument isAlignmentMorph
		ifTrue: [minExtent _ argument minWidth @ argument minHeight]
		ifFalse: [minExtent _ 1@1].
	handle _ HandleMorph new forEachPointDo:
		[:newPoint | argument extent: ((newPoint - argument bounds topLeft)
										max: minExtent)].
	self attachMorph: handle.
	handle startStepping.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 5/11/1998 16:18'!
saveAndQuit
	Smalltalk snapshot: true andQuit: true! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 5/11/1998 16:16'!
saveAs
	^ Smalltalk saveAs! !

!HandMorph methodsFor: 'world menu commands' stamp: 'di 5/11/1998 16:15'!
saveSession
	Smalltalk snapshot: true andQuit: false! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sw 9/9/1998 16:07'!
selectEmbedTargetMorph: caption
	"Put up a menu of morphs found in a core sample taken of the world at the receiver's menuTargetOffset, with the given caption"
	|  menu |
	menu _ CustomMenu new.
	self potentialEmbeddingTargets  do: [:m | menu add: (self submorphNameFor: m) action: m].
	^ caption size == 0
		ifTrue:
			[menu startUp]
		ifFalse:
			[menu startUpWithCaption: caption]! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 12/7/2005 16:35'!
selectSubmorphToOperateOn: rootMorph sending: aSymbol event: evt
	"Let the user select a submorph of the given root morph. When selected, the given selector is sent with the selected submorph as an argument."

	| possibleTargets menu |
	possibleTargets _ rootMorph morphsAt: targetOffset.
	possibleTargets size = 1 ifTrue: [^ self perform: aSymbol with: possibleTargets first with: evt].
	menu _ MenuMorph new.
	possibleTargets do: [:m |
		menu add: (self submorphNameFor: m)
			target: self
			selector: aSymbol
			argumentList: (Array with: m with: evt)].
	menu popUpForHand: evt hand.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'sma 4/30/2000 09:57'!
setDisplayDepth
	"Let the user choose a new depth for the display. "

	| result oldDepth |
	oldDepth _ Display depth.
	(result _ (SelectionMenu selections: Display supportedDisplayDepths) startUpWithCaption:
'Choose a display depth
(it is currently ' , oldDepth printString , ')') ifNotNil: [Display newDepth: result].
	(Smalltalk isMorphic and: [(Display depth < 4) ~= (oldDepth < 4)])
		ifTrue:
			["Repaint windows since they look better all white in depth < 4"
			(SystemWindow windowsIn: World satisfying: [:w | true]) do:
				[:w |
				oldDepth < 4
					ifTrue: [w restoreDefaultPaneColor]
					ifFalse: [w updatePaneColors]]]! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 10/14/2002 08:56'!
showHiders

	| container |
	container _ argument ifNotNil: [argument] ifNil: [self world].
	container allMorphsDo: [:m | m isHidden: false].
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 12/5/2005 21:23'!
startMessageTally

	(self confirm: 'MessageTally will start now,
and stop when the cursor goes
to the top of the screen') ifFalse: [^ self].

	MessageTally spyOn: [
		[Sensor cursorPoint y > 0] whileTrue: [World doOneCycle]].
! !

!HandMorph methodsFor: 'world menu commands'!
subclassMorph
	"Create a new subclass of this morph's class and make this morph be an instance of it."

	| m oldClass newClassName newClass newMorph |
	m _ argument.
	oldClass _ m class.
	newClassName _ FillInTheBlank
		request: 'Please give this new class a name'
		initialAnswer: oldClass name.
	newClassName = '' ifTrue: [^ self].
	(Smalltalk includesKey: newClassName)
		ifTrue: [^ self inform: 'Sorry, there is already a class of that name'].

	newClass _ oldClass subclass: newClassName asSymbol
		instanceVariableNames: ''
		classVariableNames: ''
		poolDictionaries: ''
		category: oldClass category asString.
	newMorph _ m as: newClass.
	m become: newMorph.
! !

!HandMorph methodsFor: 'world menu commands' stamp: 'jm 10/4/2002 07:19'!
submorphNameFor: aMorph

	^ aMorph class name asString
! !


!HandMorph methodsFor: 'halos' stamp: 'jm 9/30/2003 00:19'!
addHalo

	argument addHalo: nil.
! !

!HandMorph methodsFor: 'halos' stamp: 'jm 9/30/2003 00:13'!
addHalo: evt

	argument addHalo: evt.
! !

!HandMorph methodsFor: 'halos' stamp: 'jm 12/7/2005 16:33'!
invokeMetaMenuFor: aMorph

	| menu |
	menu _ self buildMorphMenuFor: aMorph.
	menu addTitle: aMorph externalName.
	menu popUpForHand: self.

! !

!HandMorph methodsFor: 'halos' stamp: 'jm 9/30/2003 00:16'!
popUpHaloFor: aMorph event: evt

	self world abandonAllHalos.
	targetOffset _ self position.
	aMorph addHalo: evt.
! !

!HandMorph methodsFor: 'halos' stamp: 'jm 9/30/2003 00:15'!
popUpHaloFromClick: evt
	"Pop up a halo on a suitable morph below the hand.
	If there are multiple possible targets, and one of them already has a halo, then
	choose the next inner target.  That is, unless we are already at the bottom, in which case
	go topmost again."

	| oldTargets targets anIndex |
	oldTargets _ OrderedCollection new.
	self world haloMorphs do:
		[:h | oldTargets addLast: h target. h delete].

	targetOffset _ self position.
	(argument _ self argumentOrNil) ifNil: [^ owner "the world" addHalo: evt].
	argument submorphCount = 0 ifTrue: [^ argument wantsHaloFromClick ifTrue: [argument addHalo: evt "sole target"]].

	"Multiple possible targets, choose the outermost suitable one first, but if one already
		has a halo, then choose the next farther in."
	targets _ argument unlockedMorphsAt: targetOffset.
	targets _ targets reversed select: [:aMorph | aMorph wantsHaloFromClick].

	targets size = 0 ifTrue: [^ argument wantsHaloFromClick
			ifTrue: [argument addHalo: evt "sole target"]
			ifFalse: ["no halo recipient"]].
	targets size = 1 ifTrue: [^ targets first addHalo: evt "sole target"].
	anIndex _ targets findFirst: [:t | oldTargets includes: t].
	anIndex = 0 ifTrue:
		[^ self popUpNewHaloFromClick: evt targets: targets].

	^ (targets atWrap: anIndex + 1) addHalo: evt
! !

!HandMorph methodsFor: 'halos' stamp: 'jm 12/8/2003 11:56'!
popUpNewHaloFromClick: evt targets: targets
	"Pop up a halo for the most opportune morph, given that this is not a progressive halo transfer. evt is the precipitating mouse event. targets is the list of potential targets under the mouse."

	| outer possible haloRecipient |
	possible _ targets
		detect: [:m | (m isKindOf: PasteUpMorph) not]
		ifNone: [targets last].

	outer _ possible owner ifNil: [targets first].
	haloRecipient _ targets reversed
		detect: [:m | m == outer or: [m seeksOutHalo and: [outer defersHaloOnClickTo: m]]]
		ifNone: [outer].
	haloRecipient _ targets
		detect: [:m | (m defersHaloOnClickTo: haloRecipient) not]
		ifNone: [haloRecipient].
	haloRecipient addHalo: evt.
! !


!HandMorph methodsFor: 'private' stamp: 'jm 6/20/2003 09:37'!
alphabeticalMorphMenu

	| menu morphClasses |
	menu _ MenuMorph new defaultTarget: self.
	morphClasses _ self morphClassesForNewMorphMenu.
	(morphClasses asArray sort: [:c1 :c2 | c1 name < c2 name]) do: [:cl |
		menu add: cl name target: self selector: #newMorphOfClass:event: argument: cl].
	^ menu
! !

!HandMorph methodsFor: 'private' stamp: 'jm 5/31/2003 20:15'!
morphClassesForNewMorphMenu
	"Answer a collection of morph classes for the 'new morph...' menu."
	"HandMorph someInstance morphClassesForNewMorphMenu"

	^ Morph allSubclasses asArray select: [:c |
		(c class includesSelector: #includeInNewMorphMenu) and: [c includeInNewMorphMenu]]
! !

!HandMorph methodsFor: 'private' stamp: 'jm 2/1/2005 19:56'!
releaseCachedState

	| savedGrid savedGridOffset savedOwner |
	super releaseCachedState.
	cacheCanvas _ nil.
	savedGrid _ grid.
	savedGridOffset _ gridOffset.
	savedOwner _ owner.
	self removeAllMorphs.
	self initialize.	"nuke everything"
	self privateOwner: savedOwner.
	grid _ savedGrid.
	gridOffset _ savedGridOffset.
	mouseDownMorph _ nil.
	argument _ nil.
	formerOwner _ nil.
! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HandMorph class
	instanceVariableNames: ''!

!HandMorph class methodsFor: 'class initialization' stamp: 'jens 7/14/2010 18:33'!
initialize
	"HandMorph initialize"

	PasteBuffer _ nil.
	DoubleClickTime _ 400.
	HoldTime _ 650.
	NormalCursor _ ColorForm mappingWhiteToTransparentFrom: Cursor normal.
	TranslucentWhenDragging _ true.
	TranslucencyWhenDragging _ 170.
! !


!HandMorph class methodsFor: 'accessing' stamp: 'jm 10/14/2002 07:34'!
clearPasteBuffer
	"Clear the paste buffer."

	PasteBuffer _ nil.
! !


!HandMorph class methodsFor: 'BYOB' stamp: 'jens 7/13/2010 22:59'!
translucencyWhenDragging

	TranslucentWhenDragging
		ifTrue: [^ TranslucencyWhenDragging ]
		ifFalse: [ ^ 255 ]! !

!HandMorph class methodsFor: 'BYOB' stamp: 'jens 7/13/2010 22:59'!
translucentWhenDragging
	^ TranslucentWhenDragging! !

!HandMorph class methodsFor: 'BYOB' stamp: 'jens 7/13/2010 23:00'!
translucentWhenDragging: aBool

	TranslucentWhenDragging _ aBool! !


HandMorph initialize!
