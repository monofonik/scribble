ScriptableScratchMorph subclass: #ScratchStageMorph
	instanceVariableNames: 'zoom hPan vPan penTrailsForm lastPenPositions runningBlocks inProcessStep sensorBoard midiPortNum midiPort notePlayerDict obsoleteSavedState sprites scratchServer isQuarterSize cachedForm showMotorBlocks feedbackMorph '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Scratch-Objects'!
!ScratchStageMorph commentStamp: '<historical>' prior: 0!
I represent the background of the Scratch work pane. Like a sprite, I have a set of media and can change my costume. I also have my own scripts and variables. The main difference between me and a sprite is that I am fixed in position: I cannot move or rotate.
!


!ScratchStageMorph methodsFor: 'initialization' stamp: 'jm 6/4/2009 12:03'!
initialize

	super initialize.
	color _ Color white.
	self enableDragNDrop: true.
	objName _ 'Stage' localized.
	costume _ self defaultImageMedia.
	media _ OrderedCollection with: costume with: SoundMedia new.
	zoom _ 1.0.
	hPan _ 0.
	vPan _ 0.
	runningBlocks _ OrderedCollection new.
	inProcessStep _ false.
	sensorBoard _ SensorBoardMorph new.
	midiPortNum _ -1.
	notePlayerDict _ Dictionary new.
	obsoleteSavedState _ nil.
	sprites _ OrderedCollection new.
	showMotorBlocks _ false.
! !


!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 8/2/2004 20:14'!
copyForExport
	"Answer a copy of me with no sprites for use in exporting the background by itself."

	^ super copyForExport removeAllMorphs
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 11/22/2004 13:43'!
costumeChanged

	costumeChangeMSecs _ Time millisecondClockValue.
	filterPack ifNotNil: [filterPack clearFilterCaches].
	self changed.
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'ee 11/12/2007 14:12'!
defaultImageMedia

	^ ImageMedia new
		form: DefaultBackgroundForm;
		mediaName: ('background' localized, '1')
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 11/18/2008 15:37'!
isQuarterSize

	isQuarterSize ifNil: [isQuarterSize _ false].  "lazy initialization"
	^ isQuarterSize
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 11/18/2008 13:09'!
isQuarterSize: aBoolean

	isQuarterSize _ aBoolean.
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 10/25/2007 19:21'!
objName

	^ 'Stage' localized
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 3/18/2005 23:41'!
rotationCenter

	^ costume rotationCenter
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 2/14/2008 18:21'!
scratchServer

	^ scratchServer
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 2/14/2008 18:22'!
scratchServer: anObject

	scratchServer _ anObject.
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 8/2/2005 19:02'!
sensorBoard

	^ sensorBoard
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 11/28/2005 14:52'!
sensorBoard: aSensorBoardMorph

	sensorBoard _ aSensorBoardMorph.
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 2/13/2009 14:49'!
showMotorBlocks

	^ showMotorBlocks
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 2/13/2009 14:49'!
showMotorBlocks: aBoolean

	showMotorBlocks _ aBoolean.
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'tis 11/2/2006 18:44'!
sprites

	^ sprites
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'tis 12/11/2006 10:27'!
updateSpritesList
	"Populate the sprites list, which keeps track of the ordering of the sprite thumbnails"

	| frame |
	frame _ self ownerThatIsA: ScratchFrameMorph.
	frame ifNil: [^ self].
	sprites _ OrderedCollection new.
	frame libraryPane spriteThumbnails do: [:m | m target ifNotNil: [sprites addLast: m target]].
! !


!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 10/3/2007 09:13'!
backgroundIndex
	"Answer the index of my current costume."

	^ self costumeIndex
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 10/6/2006 22:22'!
changeBackgroundIndexBy: aNumber
	"Change my background index by the given amount."

	self changeCostumeIndexBy: aNumber.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 18:58'!
changeHPanBy: amount
	"Change my horizontal pan by the given amount."

	hPan _ hPan + amount truncated.
	self changed.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 18:59'!
changeVPanBy: amount
	"Change my vertical pan by the given amount."

	vPan _ vPan + amount truncated.
	self changed.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 19:00'!
changeZoomBy: percent
	"Change my zoom by the given percent."

	zoom _ zoom + percent.
	self changed.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jens 2/8/2011 23:02'!
lookLike: costumeName

	self undeleteAttribute: #costumeIndex.
	self passiveLookLike: costumeName.
	costumeName isNumber ifFalse: [
		self lookLike: self costumeIndex ].! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/18/2004 18:16'!
makeVisible
	"Do nothing. I'm always visible."
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'ee 6/27/2008 17:46'!
newScene

	| sceneName |
	sceneName _ StringDialog ask: 'Enter Scene Name:'.
	sceneName size = 0 ifTrue: [ ^ self ].

	sceneStates at: sceneName put: self backgroundIndex.
	submorphs do: [:m |
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			m recordScene: sceneName]].
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 11/28/2006 13:39'!
nextBackground
	"Show the next background in my backgrounds list."

	self nextCostume.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'nb 1/7/2008 14:19'!
rerecordScene

	| sceneName sceneList menu |
	sceneList _ self sceneNames .
	sceneList _ sceneList copyFrom: 1 to: sceneList size - 3.
	menu _ CustomMenu new.
	sceneList do: [:n | menu add: n action: n].
	(sceneName _ menu startUp) ifNil: [^ self].

	sceneStates at: sceneName put: self backgroundIndex.
	submorphs do: [:m |
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			m recordScene: sceneName]].
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 4/25/2008 16:01'!
sceneNames

	| setOfNames |
	setOfNames _ Set new.
	submorphs do: [:m |
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			setOfNames addAll: m scenes]].

	^ setOfNames asArray sort, (Array
		with: '-'
		with: 'record' localized, ScratchTranslator ellipsesSuffix
		with: 're-record' localized, ScratchTranslator ellipsesSuffix)
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 19:00'!
setHPanTo: aNumber
	"Set my horizontal pan to the given offset."

	hPan _ aNumber truncated.
	self changed.

! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 19:00'!
setVPanTo: aNumber
	"Set my vertical pan to the given offset."

	vPan _ aNumber truncated.
	self changed.

! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 19:01'!
setZoomTo: percent
	"Set my zoom to the given percent."

	zoom _ percent truncated.
	self changed.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 12/11/2006 11:42'!
showBackground: costumeNameOrIndex
	"This is lookLike: for the stage..."

	self lookLike: costumeNameOrIndex.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'nb 1/7/2008 12:52'!
showScene: sceneName

	(sceneStates includesKey: sceneName) ifTrue: [
		self showBackground: (sceneStates at: sceneName)].

	submorphs do: [:m |
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			m setScene: sceneName]].
! !


!ScratchStageMorph methodsFor: 'sensing ops' stamp: 'jm 4/18/2008 14:07'!
attributeNames

	^ #('background #' 'volume') collect: [:s | s]
! !

!ScratchStageMorph methodsFor: 'sensing ops' stamp: 'jens 1/24/2011 22:42'!
getAttribute: attr
	"Answer the value of my variable or built-in attribute with the given name. Answer zero if I have no attribute or variable with the given name."

	| a |
	(vars includesKey: attr) ifTrue: [^ vars at: attr].
	(self allLocalBlockIds includes: attr) ifTrue: [ ^self lambda: attr ].

	a _ attr localized.
	'background #' localized = a ifTrue: [^ self backgroundIndex].
	'costume #' localized = a ifTrue: [^ self backgroundIndex].
	'volume' localized = a ifTrue: [^ self volume].
	^ 0
! !


!ScratchStageMorph methodsFor: 'sound ops' stamp: 'jens 2/4/2011 02:37'!
setTempoTo: aNumber

	tempoBPM _ (aNumber asNumberNoError within: 20 and: 500).
! !

!ScratchStageMorph methodsFor: 'sound ops' stamp: 'jm 11/27/2007 11:26'!
tempo

	^ tempoBPM
! !


!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 11/21/2008 13:57'!
containsPoint: aPoint

	self isQuarterSize ifTrue: [^ (self position extent: self extent // 2)  containsPoint: aPoint].
	^ self bounds containsPoint: aPoint
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 12/9/2008 10:53'!
fullContainsPoint: aPoint
	"Answer true if the given point is in my visible bounds. In quarterSize mode, my visible bounds is only half of my extent."

	| r |
	r _ self isQuarterSize
		ifTrue: [self position extent: bounds extent // 2]
		ifFalse: [bounds].

	^ r containsPoint: aPoint
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 8/3/2008 13:16'!
grabSpriteFromScreen
	"Create a new sprite, grabbing it's costume from an area of the screen."

	| frame m f |
	(frame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self].
	m _ ScratchSpriteMorph new.
	(f _ m grabFormFromScreen) ifNil: [^ self].
	m onlyCostume: f.
	frame addAndView: m.

! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 12/19/2008 17:22'!
mouseDown: evt
	"Handle a mouse down event."

	evt hand newKeyboardFocus: nil.
	evt hand toolType ifNotNil: [evt hand toolType: nil].

	evt rightButtonPressed
		ifTrue: [Sensor waitNoButton. ^ self rightButtonMenu]
		ifFalse:	[evt hand waitForClicksOrDrag: self event: evt].
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'tis 12/7/2006 16:04'!
stageShot

	| result |
	result _ ScratchFileChooserDialog
		chooseNewFileDefault: ''
		title: 'Save Stage Shot'
		type: #stageShot.
	result = #cancelled ifTrue: [^ self].
	result size > 0 ifTrue: [self exportFileName: result].
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 3/2/2009 15:22'!
startDrag: evt
	"Ignore drag events."
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 11/18/2008 19:34'!
transformFrom: uberMorph
	"Return a transform to map coorinates of uberMorph, a morph above me in my owner chain, into the coordinates of my submorphs."

	| transform |
	self isQuarterSize ifFalse: [^ super transformFrom: uberMorph].

	transform _ MorphicTransform offset: (self position // -2) angle: 0.0 scale: 0.5.
	owner == uberMorph ifTrue: [^ transform].
	owner ifNil: [^ transform].
	^ (owner transformFrom: uberMorph) composedWith: transform

! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 12/9/2008 10:53'!
unlockedMorphsAt: aPoint addTo: mList
	"Adjust aPoint to handle quarter-size case if necessary."

	| p |
	self isQuarterSize ifFalse: [
		super unlockedMorphsAt: aPoint addTo: mList.
		^ mList].

	(self containsPoint: aPoint) ifFalse: [^ mList]. "quick elimination"
	p _ self position + (2 * (aPoint - self position)).

	submorphs size > 0 ifTrue: [
		submorphs do: [:m | m unlockedMorphsAt: p addTo: mList]].
	mList addLast: self.

	^ mList
! !


!ScratchStageMorph methodsFor: 'dropping/grabbing' stamp: 'jm 11/18/2008 17:43'!
acceptDroppingMorph: aMorph event: evt

	self isQuarterSize ifTrue: [
		aMorph center: (2 * aMorph center) - self position.
		self changed].

	self addMorph: aMorph.
	self isInWorld ifTrue: [self world startSteppingSubmorphsOf: aMorph].
	((aMorph respondsTo: #penDown) and: [aMorph penDown])
		ifTrue: [self penUpOrDownChangeFor: aMorph].
	self changed.

! !

!ScratchStageMorph methodsFor: 'dropping/grabbing' stamp: 'jm 5/25/2004 14:56'!
rootForGrabOf: aMorph
	"Allow the given submorph to be extracted."

	| root |
	root _ aMorph.
	[root = self] whileFalse: [
		root owner == self ifTrue: [^ root].
		root _ root owner].

	^ super rootForGrabOf: aMorph
! !


!ScratchStageMorph methodsFor: 'drawing' stamp: 'JM 11/8/2011 16:41'!
drawOn: aCanvas
	"Draw myself if my visibility is > 0. If my visibility is 1, draw using the normal 'paint' mode. Otherwise, draw using 'alpha' resulting in a partially transparent rendering."

	| clipC f p alpha |
	clipC _ aCanvas copyClipRect: bounds.
	clipC fillRectangle: bounds color: Color white.
	f _ self filteredForm.

	f ifNotNil: [
		p _ bounds center - (f extent // 2) + (hPan@vPan).
		visibility < 100
			ifTrue: [
				visibility > 0 ifTrue: [
					alpha _ ((255.0 * visibility) / 100.0) truncated.
					clipC paintImage: f at: p sourceRect: f boundingBox alpha: alpha]]
			ifFalse: [clipC paintImage: f at: p]].

	self updateTrailsForm.
	penTrailsForm ifNotNil: [clipC translucentImage: penTrailsForm at: self position].
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 1/23/2009 11:14'!
drawQuarterSizeOn: aCanvas
	"Draw myself and my submorphs to an offscreen canvas, then scale down to quarter size and draw that on the given canvas."

	| r srcR c |
	cachedForm ifNil: [cachedForm _ Form extent: self extent depth: 32].
	r _ aCanvas clipRect intersect: (bounds origin extent: bounds extent // 2).

	srcR _ ((r origin - bounds origin) * 2.0) truncated extent: (r extent * 2.0) rounded.
	c _ (FormCanvas on: cachedForm)
		copyOrigin: self position negated
		clipRect: srcR.
	super fullDrawOn: c.

	ScratchPlugin halfSize: cachedForm into: Display srcPoint: srcR origin dstRect: r.

"xxx
	cachedForm unhibernate.
	LowResPlugin
		primHalf2Average: cachedForm bits w: cachedForm width h: cachedForm height
		into: Display bits w: Display width h: Display height
		srcX: srcR left srcY: srcR top
		dstX: r left dstY: r top dstW: r width dstH: r height.

	(WarpBlt toForm: Display)
		sourceForm: cachedForm;
		combinationRule: Form over;
		clipRect: aCanvas clipRect;
		cellSize: 2;
		copyQuad: srcR corners toRect: r.
xxx"

	"the following scales down entire stage:"
"	LowResPlugin scale: cachedForm into: aCanvas form at: aCanvas origin + self position."
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 11/30/2007 23:41'!
drawSubmorphsOn: aCanvas
	"Clip submorph drawing to my bounds."

	| clipCanvas |
	clipCanvas _ aCanvas copyClipRect: bounds.
	submorphs reverseDo:[:m |
		(clipCanvas isVisible: m fullBounds) ifTrue: [
			m fullDrawOn: clipCanvas]].

	"draw sprite talk bubbles in front of all morphs:"
	submorphs reverseDo:[:m |
		((m isKindOf: ScratchSpriteMorph) and:
		 [m isHidden not and:
		 [clipCanvas isVisible: m fullBounds]]) ifTrue: [
			m drawTalkBubbleOn: clipCanvas]].

! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 12/16/2006 12:21'!
exportFileName: fileName

	| form fName |
	form _ self stageShotForm.
	form depth <= 8 ifTrue: [
		(fileName asLowercase endsWith: '.gif')
			ifTrue: [fName _ fileName]
			ifFalse: [fName _ fileName, '.gif'].
		GIFReadWriter putForm: form colorReduced8Bit onFileNamed: fName.
		^ self].

	(fileName asLowercase endsWith: '.bmp')
		ifTrue: [fName _ fileName]
		ifFalse: [fName _ fileName, '.bmp'].
	(form asFormOfDepth: 32) writeBMPFileNamed: fName.
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 6/3/2004 20:17'!
fullBounds
	"Overridden to clip submorph hit detection to my bounds."

	^ bounds
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 12/9/2008 10:51'!
fullDrawOn: aCanvas
	"Calls super fullDrawOn and then draws the frame shadow"

	| shadowOrigin topShadowExtent leftShadowExtent alphas |

	(self isQuarterSize and: [self isInWorld]) ifTrue: [
		^ self drawQuarterSizeOn: aCanvas].

	super fullDrawOn: aCanvas.

	"don't draw shadows if owner is not a ScratchFrameMorph"
	(owner isKindOf: ScratchFrameMorph) ifFalse: [^ self].

	"shadow constants"
	shadowOrigin _ self topLeft + aCanvas origin.
	topShadowExtent _ self width@1.
	leftShadowExtent _ 1@self height.

	"shadow alpha values"
	alphas _ FloatArray
		with: 0.51
		with: 0.26
		with: 0.07.

	"top/horizontal shadow"
	1 to: 3 do: [:i |
		aCanvas grafPort
			fill: (shadowOrigin + (0@(i-1)) extent: topShadowExtent)
			fillColor: (Color black alpha: (alphas at: i))
			rule: Form blend].

	"left/vertical shadow"
	1 to: 3 do: [:i |
		aCanvas grafPort
			fill: (shadowOrigin + ((i-1)@0) extent: leftShadowExtent)
			fillColor: (Color black alpha: (alphas at: i))
			rule: Form blend].

	"corner shadow fix"
	aCanvas grafPort
		fill: (shadowOrigin extent: (1@1))
		fillColor: (Color white alpha: 0.32)
		rule: Form blend.
	aCanvas grafPort
		fill: (shadowOrigin +(0@1) extent: (1@1))
		fillColor: (Color white alpha: 0.19)
		rule: Form blend.
	aCanvas grafPort
		fill: (shadowOrigin + (1@0) extent: (1@1))
		fillColor: (Color white alpha: 0.19)
		rule: Form blend.
	aCanvas grafPort
		fill: (shadowOrigin +(0@2) extent: (1@1))
		fillColor: (Color white alpha: 0.05)
		rule: Form blend.
	aCanvas grafPort
		fill: (shadowOrigin + (2@0) extent: (1@1))
		fillColor: (Color white alpha: 0.05)
		rule: Form blend.
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 11/8/2006 18:09'!
incrRedraw: damageList
	"Redraw the damaged areas of this stage directly onto the display. Assumes that no other morph is in front of me."

	| f c p screenR |
	damageList do: [:r |
		f _ Form extent: r extent depth: 32.
		c _ (FormCanvas on: f) copyOffset: r origin negated.
		self fullDrawOn: c.
		DoubleSize
			ifTrue: [
				p _ (self center - self extent) + (2 * (r origin - self topLeft)).
				screenR _ p extent: 2 * f extent.
				(Display boundingBox containsRect: screenR) ifTrue: [
					[
						ScratchPlugin
							primDouble: f bits w: f width h: f height
							into: Display bits w: Display width h: Display height
							x: screenR left y: screenR top.
					] ifError: [].
					Display forceToScreen: screenR]]
			ifFalse: [
				f displayOn: Display at: r topLeft rule: Form over]].
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 12/10/2008 13:57'!
invalidRect: damageRect
	"Clip damage reports to my bounds, since drawing is clipped to my bounds."

	| r |
	(owner isKindOf: ScratchFrameMorph) ifTrue: [owner projectModified].

	(self isQuarterSize and: [owner isKindOf: ScratchFrameMorph])
		ifTrue: [
			r _ (bounds origin + ((damageRect origin - bounds origin) / 2.0)) extent: (damageRect extent / 2.0).
			r _ r intersect: (bounds origin extent: bounds extent // 2)]
		ifFalse: [
			r _ (damageRect topLeft truncated) corner: (damageRect right ceiling@damageRect bottom ceiling).
			r _ r intersect: self bounds].

	(r width > 0 and: [r height > 0]) ifTrue: [super invalidRect: r].
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'ee 8/1/2008 17:17'!
patchAt: patchRect withoutWatchersAnd: stopMorph andNothingAbove: stopThere
	"Return a complete rendering of this patch of the display screen without drawing stopMorph and, if stopThere is true, without drawing any morph above it."

	| c morphsToDraw i |
	c _ FormCanvas extent: patchRect extent depth: Display depth.
	c _ c copyOrigin: patchRect topLeft negated clipRect: (0@0 extent: patchRect extent).

	(self bounds containsRect: patchRect) ifFalse: [
		"fill areas of patchRect outside my bounds with black"
		c form fillColor: Color black].
	(self bounds intersects: patchRect) ifFalse: [^ c form].  "entirely out of bounds"

	"draw all morphs intersecting the given patch, stopping at the given morph"
	c fillRectangle: self bounds color: color.  "draw world color"
	self drawOn: c.
	morphsToDraw _ submorphs reversed asOrderedCollection.
	(i _ morphsToDraw indexOf: stopMorph) > 0 ifTrue: [
		stopThere
			ifTrue: [morphsToDraw _ morphsToDraw copyFrom: 1 to: i - 1]  "stop at stopMorph"
			ifFalse: [morphsToDraw removeIndex: i]].  "skip stopMorph"
	morphsToDraw do: [:m |
		((m isKindOf: WatcherMorph) or: [(m isKindOf: SensorBoardMorph)])
			ifFalse: [m fullDrawOn: c]].
	^ c form
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 8/2/2006 14:43'!
previewForm
	"Answer a full-size preview of me and my submorphs. Use super fullDrawOn: to avoid drawing the shadows along the top and left edges of the workspace."

	| canvas |
	canvas _ FormCanvas extent: bounds extent depth: 32.
	canvas translateBy: bounds topLeft negated during: [:c | super fullDrawOn: c].
	^ canvas form
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'tis 8/3/2006 16:06'!
stageShotForm
	"Answer a stage shot of me and my submorphs."

	^ self stageShotSized: self width @ self height
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'tis 8/3/2006 15:55'!
stageShotSized: size
	"Answer a thumbnail of me and my submorphs. Use super fullDrawOn: to avoid drawing the shadows along the top and left edges of the workspace."

	| canvas thumbForm |
	canvas _ FormCanvas extent: bounds extent depth: 32.
	canvas translateBy: bounds topLeft negated during: [:c | super fullDrawOn: c].
	thumbForm _ Form extent: size depth: 32.
	(WarpBlt toForm: thumbForm)
		sourceForm: canvas form;
		cellSize: 2;
		combinationRule: Form over;
		copyQuad: (0@0 extent: canvas extent) innerCorners toRect: thumbForm boundingBox.

	thumbForm _ thumbForm colorReduced.  "first try to make a ColorForm with exact colors"
	thumbForm depth > 8 ifTrue: [
		thumbForm _ thumbForm asFormOfDepth: 8].  "if that fails, use the closest 8-bit colors"
	^ thumbForm

! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'tis 8/3/2006 16:01'!
thumbnailForm
	"Answer a thumbnail of me and my submorphs."

	^ self stageShotSized: (160@120)
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 1/3/2006 22:23'!
updateStageDisplay
	"Redraw the damaged areas of this stage directly onto the display. Assumes that no other morph is in front of me."

	| root damageList |
	root _ owner.
	[root owner notNil] whileTrue: [root _ root owner].
	(root respondsTo: #damageRecorder) ifFalse: [^ self].

	damageList _ root damageRecorder filteredDamageWithin: self bounds.
	damageList size > 0 ifTrue: [self incrRedraw: damageList].
! !


!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 5/14/2009 14:28'!
allEventNames
	"Answer a list of all events that have been defined in this project."

	| result |
	result _ Set new: 100.
	self submorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			m addEventNamesTo: result]].
	self addEventNamesTo: result.

	scratchServer ifNotNil: [
		result addAll: scratchServer broadcastsSeen].

	"remove empty string"
	result remove: '' ifAbsent: [].

	^ result asArray sort
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 2/14/2008 18:23'!
broadcastEventNamed: name with: value
	"Broadcast a ScratchEvent with given name and argument value to all Scratch objects and answer a collection of the newly created processes. This is done by finding all public scripts that respond to this event, and starting new processes for any not already running."

	| event objList newProcs |
	scratchServer ifNotNil: [scratchServer queueBroadcast: name].
	event _ ScratchEvent new name: name argument: value.
	newProcs _ OrderedCollection new.

	"start scripts"
	objList _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	objList do: [:obj |
		newProcs addAll: (obj eventReceived: event)].
	newProcs addAll: (self eventReceived: event).

	^ newProcs asArray
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 9/27/2007 15:10'!
defaultEventName
	"Answer a default event name for message send and receive blocks."

	| evtNames |
	evtNames _ self allEventNames.
	^ evtNames size = 0 ifTrue: [''] ifFalse: [evtNames first]
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 12:10'!
processesToRun
	"Answer a collection of processes to run. Filter out any processes for objects have been picked up. Always return a copy of the processes list."

	| result m |
	result _ runningBlocks collect: [:b | b scratchProc].
	result _ result select: [:proc | proc notNil].

	World activeHand submorphs size > 0 ifTrue: [
		m _ World activeHand submorphs first.
		result _ result select: [:proc | (proc includesReceiver: m) not]].

	^ result
 ! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 13:06'!
removeTerminatedProcesses
	"Remove terminated processes from the process list."

	| newRunning proc |
	newRunning _ runningBlocks species new: 100.
	runningBlocks do: [:b |
		(proc _ b scratchProc) ifNotNil: [
			proc isRunning
				ifTrue: [newRunning addLast: b]
				ifFalse: [proc errorFlag ifFalse: [b stop]]]].

	runningBlocks _ newRunning.
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 12:27'!
startProcessFor: topBlock
	"Start a process to run the given block or stack of blocks. Return the new process."

	| sequence proc |
	sequence _ topBlock blockSequence.
	sequence first isHatBlock ifTrue: [
		sequence _ sequence allButFirst].  "skip hat block"

	topBlock scratchProc ifNotNil: [topBlock stop].

	proc _ ScratchProcess new
		topBlock: topBlock;
		expression: sequence.
	topBlock scratchProc: proc.

	(runningBlocks includes: topBlock) ifFalse: [runningBlocks addLast: topBlock].

	^ proc
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 12/12/2008 14:08'!
stepProcesses
	"Run each Scratch process until it gives up control, then filter out any processes that have terminated."
	"Details: Iterate over a copy of processes to allow processes to stop themselves. During development, the error catcher makes it difficult to track down errors, so it can be disabled."

	| proc |
	sensorBoard processIncomingData.

	ScratchProcess blockHighlightMSecs = 0 ifTrue: [^ self stepProcessesTurbo].

	inProcessStep ifTrue: [^ self].
	inProcessStep _ true.
	ScratchFrameMorph useErrorCatcher
		ifTrue: [
			[self processesToRun do: [:p | (proc _ p) runStepFor: self]]
				ifError: [proc errorFlag: true]]
		ifFalse: [
			self processesToRun do: [:p | p runStepFor: self]].

	self removeTerminatedProcesses.
"	self deleteTerminatedClones."

	inProcessStep _ false.
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 12:03'!
stepProcessesTurbo
	"Run each Scratch process until it gives up control, then filter out any processes that have terminated. Do this repeatedly until time is up."

	| sliceMSecs startMSecs now proc |
	sliceMSecs _ 100.
	inProcessStep ifTrue: [^ self].
	inProcessStep _ true.

	startMSecs _ Time millisecondClockValue.
	[
		[now _ Time millisecondClockValue.
		 runningBlocks size > 0 and:
		  [(now >= startMSecs) and: [(now - startMSecs) < sliceMSecs]]] whileTrue: [
			self processesToRun do: [:p | (proc _ p) runStepFor: self].
			self removeTerminatedProcesses].
	] ifError: [proc errorFlag: true].

	inProcessStep _ false.
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jens 5/21/2010 03:09'!
stopAll
	"Stop all processes and make sure I am stepping."

	| sFrame |
	World hands do: [:h | h newKeyboardFocus: nil; clearUnclaimedKeystrokes].
	Sensor clearKeystate.
	SoundPlayer stopPlayingAll.
	self class stopSoundRecorder.
	self stopAllProcesses.
	self stopAsks.
	self deleteAllClones.
	self midiAllNotesOff.
	WeDoPlugin resetWeDo.
	self stopPlaying.
	self allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [m stopPlaying]].

	DebuggerFrameMorph allInstancesDo: [:df | df delete ].

	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNotNil: [
		sFrame scriptsPane allMorphsDo: [:m |
			(m respondsTo: #stop) ifTrue: [m stop].
			(m respondsTo: #litUp:) ifTrue: [m litUp: false]].
		World startSteppingSubmorphsOf: sFrame].

	World startSteppingSubmorphsOf: self.
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 13:13'!
stopAllProcesses
	"Stop all running Scratch processes."

	| allObjs |
	"clear all processes, including those with error feedback"
	allObjs _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	allObjs _ allObjs copyWith: self.
	allObjs do: [:obj |
		(obj blocksBin isKindOf: Morph) ifTrue: [
			obj blocksBin submorphs do: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b clearProcess]]]].

	runningBlocks _ OrderedCollection new.
	inProcessStep _ false.
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 12/1/2006 19:02'!
stopAllSounds
	"Stop all sounds and MIDI notes/drums."

	SoundPlayer shutDown.
	self midiAllNotesOff.

! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 3/24/2009 17:09'!
stopAsks
	"Stop/close any ask that is currently on the screen."

	ScratchPrompterMorph allInstancesDo: [:m | m stopAsk].
	ScratchPrompterMorph clearLastAnswer.
! !


!ScratchStageMorph methodsFor: 'clones' stamp: 'jm 6/6/2008 14:41'!
allClones
	"Answer a collection of all sprite clones."

	^ self submorphs select: [:m |
		(m isKindOf: ScriptableScratchMorph) and: [m isClone]].
! !

!ScratchStageMorph methodsFor: 'clones' stamp: 'jm 6/6/2008 14:41'!
deleteAllClones
	"Delete all clones."

	self allClones do: [:clone | clone delete].
! !

!ScratchStageMorph methodsFor: 'clones' stamp: 'jm 6/4/2009 12:34'!
deleteTerminatedClones
	"Delete all clones that have no running scripts."

	| isRunning |
	self allClones do: [:clone |
		isRunning _ false.
		clone blocksBin allMorphsDo: [:b |
			((b isKindOf: BlockMorph) and: [b hasRunningProcess])
				ifTrue: [isRunning _ true]].
		isRunning ifFalse: [clone delete]].
! !


!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:08'!
closeMIDI
	"Close the MIDI port and clear the note player dictionary."

	midiPort ifNotNil: [
		midiPort close.
		midiPort _ nil].
	notePlayerDict _ Dictionary new.
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:09'!
midiAllNotesOff
	"If the MIDI port is open, send an 'all notes off' command on every channel."

	midiPort ifNil: [^ self].
	midiPort ensureOpenIfFail: [self closeMIDI].
	notePlayerDict do: [:player | player noteOff].
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:23'!
midiPortNum

	^ midiPortNum
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:23'!
midiPortNum: anInteger

	midiPortNum _ anInteger.

! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 6/2/2009 18:46'!
notePlayerFor: aScratchObject
	"Answer a note player for the given object, creating one if necessary. Open the MIDI port if necessary."

	| deletedMorphs channelUsage ch newCh newPlayer |
	midiPort ifNil: [self tryToOpenMidiPort].

	(notePlayerDict includesKey: aScratchObject) ifTrue: [
		^ notePlayerDict at: aScratchObject].

	"remove deleted morphs from the note player dictionary"
	deletedMorphs _ notePlayerDict keys select: [:m | m owner isNil].
	deletedMorphs do: [:m | notePlayerDict removeKey: m].

	"find the channel used by the fewest objects"
	channelUsage _ Array new: 16 withAll: 0.
	channelUsage at: 10 put: 1000000.  "make sure channel 10 (drums) is not chosen"
	notePlayerDict do: [:player |
		ch _ player channel.
		channelUsage at: ch put: (channelUsage at: ch) + 1].
	newCh _ channelUsage indexOf: channelUsage min.

	newPlayer _ ScratchNotePlayer new
		channel: newCh;
		midiPort: midiPort;
		instrument: 1.
	notePlayerDict at: aScratchObject put: newPlayer.

	^ newPlayer
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:09'!
openMIDI
	"Prompt the user to select a MIDI port number, then open it."

	| possiblePorts dir menu choice |
	self closeMIDI.
	possiblePorts _ (0 to: SimpleMIDIPort primPortCount - 1) select: [:i |
		dir _ SimpleMIDIPort primPortDirectionalityOf: i.
		(dir = 2) | (dir = 3)].  "out or in/out port"
	possiblePorts size = 0 ifTrue: [^ self inform: 'No MIDI ports currently available.'].
	menu _ CustomMenu new title: 'MIDI port:'.
	possiblePorts do: [:i | menu add: (SimpleMIDIPort portDescription: i) action: i].
	choice _ menu startUp.
	choice ifNil: [^ self].
	midiPortNum _ choice.
	self tryToOpenMidiPort.
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 6/3/2009 15:37'!
tryToOpenMidiPort
	"Attempt to open the MIDI port. First try the port selected by the user, if any. If that port number is not a MIDI output port, try to find another port number. If all measures fail, leave midiPort set to nil."

	| possiblePorts dir portNum |
	Smalltalk isUnix ifTrue: [midiPort _ nil. ^ self].

	possiblePorts _ (0 to: SimpleMIDIPort primPortCount - 1) select: [:i |
		dir _ SimpleMIDIPort primPortDirectionalityOf: i.
		(dir = 2) | (dir = 3)].  "out or in/out port"

	possiblePorts size = 0 ifTrue: [midiPort _ nil. ^ self].  "no midi ports"


	(possiblePorts includes: midiPortNum)
		ifTrue: [portNum _ midiPortNum]  "use the port requested by the user"
		ifFalse: [portNum _ possiblePorts first].  "use the first available port"
			
	[midiPort _ SimpleMIDIPort openOnPortNumber: portNum] ifError: [midiPort _ nil].
! !


!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 2/5/2005 11:31'!
clearPenTrails
	"Remove my pen trails Form. It will be recreated later if it is needed."

	penTrailsForm _ nil.
	self changed.
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'JM 11/14/2011 11:39'!
createOrResizeTrailsForm
	"If necessary, create a new penTrailsForm or resize the existing one to fill my bounds. On return, penTrailsForm will be a Form of the correct size."

	| newForm |
	penTrailsForm ifNil: [
		penTrailsForm _ Form extent: self extent depth: 32.
		^ self].

	penTrailsForm extent = self extent ifFalse: [  "resize trails Form to my current exent"
		newForm _ Form extent: self extent depth: 32.
		newForm
			copy: penTrailsForm boundingBox
			from: penTrailsForm
			to: 0@0
			rule: Form paint.
		penTrailsForm _ newForm].
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'JM 11/14/2011 12:16'!
drawCircleFor: aSprite radius: aNumber

	| o d circle |

	self createOrResizeTrailsForm.
	o _ 	aSprite referencePosition + ScratchOrigin.
	d _ aNumber@aNumber * 2.

	circle _ FormCanvas on: penTrailsForm.
	circle fillOval: (Rectangle origin: o corner: d) color: Color red borderWidth: 2 borderColor: Color black.

	Transcript show: o; cr.
	Transcript show: d; cr.
	Transcript show: ScratchOrigin.! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'JM 11/10/2011 14:20'!
drawPenTrailFor: aMorph from: oldPoint to: newPoint
	"Draw a pen trail between the given points for the given morph using its pen size and color. The points are in Scratch coordinates (that is, 0@0 is the center of the work pane and y increases toward the top of the screen."
	"The penTrailsForm is created on demand when the first pen is put down and removed (to save space) when pen trails are cleared."

	| pen penSize offset p1 p2 r |
	self createOrResizeTrailsForm.
	pen _ Pen newOnForm: penTrailsForm. 
	penSize _ aMorph penSize.
	aMorph penSize ~= 1 ifTrue: [
		pen roundNib: penSize.
		pen sourceForm offset: nil].  "clear form offset"
	pen color: (aMorph penColor alpha: 1.0 - (aMorph penGhosting / 100)).
	offset _ (penTrailsForm extent - penSize) / 2.0.
	p1 _ ((oldPoint * (1 @ -1)) + offset) rounded.
	p2 _ ((newPoint * (1 @ -1)) + offset) rounded.
	pen combinationRule: 24.
	pen drawFrom: p1 to: p2 withFirstPoint: false.
	r _ ((p1 rect: p2) expandBy: penSize + 1) translateBy: self topLeft.
	self invalidRect: r.
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 6/2/2009 18:50'!
penTrailsForm

	^ penTrailsForm
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 6/2/2009 18:51'!
penTrailsForm: aForm

	penTrailsForm _ aForm.
	penTrailsForm ifNotNil: [self createOrResizeTrailsForm].
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 10/6/2007 14:53'!
penUpOrDownChangeFor: aSprite
	"The pen up/down state for the given sprite may have changed; update lastPenPositions accordingly."

	| p |
	aSprite penDown
		ifTrue: [  "pen down transition"
			lastPenPositions ifNil: [lastPenPositions _ IdentityDictionary new].
			p _ aSprite penPosition.
			lastPenPositions at: aSprite put: p.
			self drawPenTrailFor: aSprite from: p to: p]
		ifFalse: [
			lastPenPositions ifNil: [^ self].
			lastPenPositions removeKey: aSprite ifAbsent: [].
			lastPenPositions size = 0 ifTrue: [lastPenPositions _ nil]].
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'JM 11/9/2011 16:53'!
stampCostume: aSprite
	"Stamp a copy of the given sprite on my pen trails form."
	
	| f b destLoc |
	f _ aSprite filteredForm.
	destLoc _ aSprite bounds origin - (bounds origin).

	self createOrResizeTrailsForm.

	b _ BitBlt toForm: penTrailsForm.
	b sourceForm: f;
		combinationRule: 31;
		destX: destLoc x;
		destY: destLoc y;
		sourceX: 0;
		sourceY: 0;
		width: f width;
		height: f height;
		copyBitsTranslucent: (aSprite visibility / 100 * 255) rounded.
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 11/15/2006 16:57'!
updatePenPositionFor: aSprite
	"Update the given sprites pen position if necessary. Used to avoid drawing glitches when going between normal and presentation mode."

	lastPenPositions ifNil: [^ self].  "no pens are down"
	(lastPenPositions includes: aSprite) ifTrue: [
		lastPenPositions at: aSprite put: aSprite penPosition].
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 2/5/2005 11:33'!
updateTrailsForm
	"Update the pen trails form using the current positions of all sprites with their pens down."
	"Details: The positions of all sprites with their pens down are recorded by my draw method. If the list from the last display update isn't empty, then trails are drawn from the old to the current positions of all such morphs on the pen trails form. The pen trails form is created on demand when the first pen is put down and removed (to save space) when the pen trails are cleared."

	| spritesToRemove m oldPoint newPoint |
	(lastPenPositions isNil or: [lastPenPositions size = 0]) ifTrue: [^ self].

	spritesToRemove _ OrderedCollection new.
	lastPenPositions associationsDo: [:assoc |
		m _ assoc key.
		(m penDown and: [m owner == self])
			ifTrue: [
				oldPoint _ assoc value.
				newPoint _ m penPosition.
				newPoint = oldPoint ifFalse: [
					self drawPenTrailFor: m from: oldPoint to: newPoint.
					assoc value: newPoint]]
			ifFalse: [spritesToRemove add: m]].

	"remove sprites that are not longer owned by me or whose pens are up"
	spritesToRemove do: [:key | lastPenPositions removeKey: key ifAbsent: []].
! !


!ScratchStageMorph methodsFor: 'object i/o' stamp: 'nb 1/7/2008 14:01'!
fieldsVersion

	^ 5
! !

!ScratchStageMorph methodsFor: 'object i/o' stamp: 'jm 7/8/2008 06:13'!
initFieldsFrom: anObjStream version: classVersion

	super initFieldsFrom: anObjStream version: classVersion.
	self initFieldsNamed: #(
		zoom
		hPan
		vPan
	) from: anObjStream.
	classVersion = 1 ifTrue: [^ self].

	"fields added in version 2"
	self initFieldsNamed: #(
		obsoleteSavedState
	) from: anObjStream.
	classVersion = 2 ifTrue: [^ self].

	"fields added in version 3"
	self initFieldsNamed: #(
		sprites
	) from: anObjStream.
	classVersion = 3 ifTrue: [^ self].

	"fields added in version 4"
	self initFieldsNamed: #(
		volume
		tempoBPM
	) from: anObjStream.
	classVersion = 4 ifTrue: [^ self].

	"fields added in version 5"
	self initFieldsNamed: #(
		sceneStates
		lists
	) from: anObjStream.
	lists ifNil: [lists _ Dictionary new].  "work around"
! !

!ScratchStageMorph methodsFor: 'object i/o' stamp: 'jm 5/12/2008 11:58'!
storeFieldsOn: anObjStream

	super storeFieldsOn: anObjStream.
	self storeFieldsNamed: #(
		zoom
		hPan
		vPan
		obsoleteSavedState
		sprites
		volume
		tempoBPM
		sceneStates
		lists
	) on: anObjStream.
! !


!ScratchStageMorph methodsFor: 'menus' stamp: 'jm 10/25/2007 19:25'!
rightButtonMenu
	"Present the right button menu."

	| menu |
	menu _ CustomMenu new.
	menu add: 'grab screen region for new sprite' action: #grabSpriteFromScreen.
	menu addLine.
	menu add: 'save picture of stage...' action: #stageShot.
	menu localize; invokeOn: self.
! !


!ScratchStageMorph methodsFor: 'media' stamp: 'jm 6/22/2009 14:15'!
savePhoto: aForm

	| n f |
	n _ self unusedMediaNameFromBaseName: 'background' localized, '1'.

	f _ Form extent: self extent depth: 32.
	(WarpBlt toForm: f)
		sourceForm: aForm;
		cellSize: 1;  "installs a new colormap if cellSize > 1"
		combinationRule: Form over;
		copyQuad: aForm boundingBox innerCorners toRect: f boundingBox.

	self addMediaItem: (ImageMedia new mediaName: n; form: f).

! !


!ScratchStageMorph methodsFor: 'nesting' stamp: 'jens 8/4/2009 00:08'!
step

	| cp targets dragged |
	super step.
	feedbackMorph ifNotNil: [feedbackMorph delete].
	cp _ self adjustedCursorPoint. Sensor cursorPoint. 
	(self containsPoint: Sensor cursorPoint) ifFalse: [^self].
	(World activeHand submorphs isEmpty not and: [World activeHand submorphs first isKindOf: LibraryItemMorph]) ifFalse: [^self].
	dragged _ World activeHand submorphs first target.
	targets _ self sprites select: [:each| 
		each containsPoint: cp ].
	targets size > 0 ifTrue: [
		targets first == dragged ifFalse:[
			feedbackMorph _ targets first feedbackMorph.
			World activeHand addMorphFront: feedbackMorph ]].


! !


!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 2/24/2011 20:09'!
clearAllVariables

	self clearVariables.
	sprites do: [:each |
		each clearVariables]
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 5/18/2010 01:35'!
isPaused

	| allObjs |
	allObjs _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	allObjs _ allObjs copyWith: self.
	allObjs do: [:obj |
		(obj blocksBin isKindOf: Morph) ifTrue: [
			obj blocksBin submorphs do: [:b |
				(b isKindOf: BlockMorph) ifTrue: [(b scratchProc notNil and: [b scratchProc isPaused not]) ifTrue: [^ false]]]]].
	^ true

! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 11/23/2009 21:28'!
listInVarNamed: varName targetName: targetName

	targetName = 'Stage' ifTrue: [
		^self getVar: varName].

	sprites do: [:sprite |
		(sprite varNames includes: varName)
			ifTrue: [^sprite getVar: varName]].

	^ nil! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 11/23/2009 21:26'!
listNamed: listName targetName: targetName

	targetName = 'Stage' ifTrue: [
		^self listNamed: listName ].

	sprites do: [:sprite |
		(sprite listVarNames includes: listName)
			ifTrue: [^sprite listNamed: listName ]].

	^ nil! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 10/18/2010 02:03'!
pauseAllProcesses
	"Pause all running Scratch processes."

	| allObjs |
	"pause all sounds"
	SoundPlayer pauseAll.
		
	"clear all processes, including those with error feedback"
"
	allObjs _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	allObjs _ allObjs copyWith: self.
	allObjs do: [:obj |
		(obj blocksBin isKindOf: Morph) ifTrue: [
			obj blocksBin submorphs do: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b pauseProcess]]]].
"

	runningBlocks do: [:each |
		each pauseProcess]
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 11/23/2009 20:33'!
referenceToList: aScratchList

	"answer an Array describing the variable which holds an anonymous list, nil
	if there isn't any.

	format:

		1 - target obj name
		2 - var name"

	self varNames do: [:key |
		aScratchList == (vars at: key)
			ifTrue: [^ Array with: 'Stage' with: key ]].

	sprites do: [:sprite |
		sprite varNames do: [:vname |
			aScratchList == (sprite getVar: vname)
				ifTrue: [^ Array with: sprite objName with: vname ]]].

	^ nil! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 10/18/2010 02:04'!
resumeAllProcesses
	"Pause all running Scratch processes."

	| allObjs |
	"resume all sounds"
	SoundPlayer resumeAll.

	"clear all processes, including those with error feedback"
"
	allObjs _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	allObjs _ allObjs copyWith: self.
	allObjs do: [:obj |
		(obj blocksBin isKindOf: Morph) ifTrue: [
			obj blocksBin submorphs do: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b resumeProcess]]]].

"

	runningBlocks do: [:each |
		each resumeProcess]
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 9/22/2010 01:29'!
startProcessForSequence: anArray
	"Start a process to run the given block or stack of blocks. Return the new process."

	| sequence proc topBlock |
	sequence _ anArray last.
	topBlock _ sequence first.
	sequence first isHatBlock ifTrue: [
		sequence _ sequence allButFirst].  "skip hat block"

	topBlock scratchProc ifNotNil: [topBlock stop].

	proc _ ScratchProcess new
		topBlock: topBlock;
		scriptList: anArray;
		expression: sequence.
	topBlock scratchProc: proc.
	(runningBlocks includes: topBlock) ifFalse: [runningBlocks addLast: topBlock].

	^ proc
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 6/9/2010 00:20'!
stopAllScriptsFor: eventName

"	remember to implement this in the mesh network later -jens"
"	scratchServer ifNotNil: [scratchServer queueBroadcast: name]."

	"stop scripts"
	submorphs do: [:m | (m isKindOf: ScriptableScratchMorph) ifTrue: [
		m stopScriptsFor: eventName]].
	self stopScriptsFor: eventName 
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 5/18/2010 01:13'!
togglePause

	self isPaused
		ifTrue: [self resumeAllProcesses]
		ifFalse: [self pauseAllProcesses] ! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 8/5/2010 11:30'!
unloadAllUnusedCustomBlocks

	'updating...' 
		displayProgressAt: Display center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((self allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size
		during: [:bar | | i | i _ 0.

	{self}, self sprites do: [:obj |
		i _ i + 1. bar value: i.
		obj unloadUnusedCustomBlocks]]
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 2/22/2011 00:05'!
userSelectSpriteDefault: defaultSprite butNotAnyOf: excludeArray

	| menu current |
	menu _ CustomMenu new.
	(defaultSprite isKindOf: ScratchSpriteMorph)
		ifTrue: [current _ defaultSprite objName]
		ifFalse: [current _ 'none'].
	menu title: 'current parent: ', current.
	sprites do: [:each |
		(excludeArray includes: each) ifFalse: [
			menu add: each objName action: each]].
	menu addLine.
	menu add: 'none' action: #null.
	^ menu startUp: #null
! !


!ScratchStageMorph methodsFor: 'byob OOP' stamp: 'jens 1/27/2011 00:20'!
asReferenceTuple

	" answer an array describing the receiver in an abstract way
	format conventions:"

	^ Array with: #stage
! !

!ScratchStageMorph methodsFor: 'byob OOP' stamp: 'jens 2/14/2011 22:19'!
attribute: attr
	"Answer the value of my variable or built-in attribute with the given name. Answer zero if I have no attribute or variable with the given name."

	| a |
	
	(attr isKindOf: CommandBlockMorph)
		ifTrue: [^ attr fullCopy newScriptOwner: self; yourself] 		"self blockLike: attr body]".

	a _ attr asString.
	(vars includesKey: a) ifTrue: [^ vars at: a].
	(self allLocalBlockIds includes: a) ifTrue: [ ^self lambda: a ].

	a _ a localized.
	'background #' localized = a ifTrue: [^ self backgroundIndex].
	'costume #' localized = a ifTrue: [^ self backgroundIndex].
	'volume' localized = a ifTrue: [^ self volume].
	^ 0
! !

!ScratchStageMorph methodsFor: 'byob OOP' stamp: 'jens 1/31/2011 00:30'!
deleteSprite
	"override the inherited default method to do nothing"
	^ self! !

!ScratchStageMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 22:49'!
passiveLookLike: costumeName
	"Change to the costume with the given name. Noop if there is no costume of the given name in my library."

	zoom _ 100.
	hPan _ 0.
	vPan _ 0.
	super lookLike: costumeName.

	self propagate: #costumeIndex! !


!ScratchStageMorph methodsFor: 'dropping/grabbing' stamp: 'jm 11/18/2008 17:43'!
acceptDroppingMorph: aMorph event: evt

	self isQuarterSize ifTrue: [
		aMorph center: (2 * aMorph center) - self position.
		self changed].

	self addMorph: aMorph.
	self isInWorld ifTrue: [self world startSteppingSubmorphsOf: aMorph].
	((aMorph respondsTo: #penDown) and: [aMorph penDown])
		ifTrue: [self penUpOrDownChangeFor: aMorph].
	self changed.

! !

!ScratchStageMorph methodsFor: '-- all --' stamp: 'jens 7/27/2009 23:14'!
adjustedCursorPoint
	"Answer the current mouse cursorPoint adjusted for the scaling presentation and q-mode."

	DoubleSize
		ifTrue: [^((Sensor cursorPoint - self center) // 2) + self center].
	isQuarterSize
		ifTrue: [^((Sensor cursorPoint - self position) * 2) + self position].
	^Sensor cursorPoint




! !

!ScratchStageMorph methodsFor: 'clones' stamp: 'jm 6/6/2008 14:41'!
allClones
	"Answer a collection of all sprite clones."

	^ self submorphs select: [:m |
		(m isKindOf: ScriptableScratchMorph) and: [m isClone]].
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 5/14/2009 14:28'!
allEventNames
	"Answer a list of all events that have been defined in this project."

	| result |
	result _ Set new: 100.
	self submorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			m addEventNamesTo: result]].
	self addEventNamesTo: result.

	scratchServer ifNotNil: [
		result addAll: scratchServer broadcastsSeen].

	"remove empty string"
	result remove: '' ifAbsent: [].

	^ result asArray sort
! !

!ScratchStageMorph methodsFor: 'byob OOP' stamp: 'jens 1/27/2011 00:20'!
asReferenceTuple

	" answer an array describing the receiver in an abstract way
	format conventions:"

	^ Array with: #stage
! !

!ScratchStageMorph methodsFor: 'byob OOP' stamp: 'jens 2/14/2011 22:19'!
attribute: attr
	"Answer the value of my variable or built-in attribute with the given name. Answer zero if I have no attribute or variable with the given name."

	| a |
	
	(attr isKindOf: CommandBlockMorph)
		ifTrue: [^ attr fullCopy newScriptOwner: self; yourself] 		"self blockLike: attr body]".

	a _ attr asString.
	(vars includesKey: a) ifTrue: [^ vars at: a].
	(self allLocalBlockIds includes: a) ifTrue: [ ^self lambda: a ].

	a _ a localized.
	'background #' localized = a ifTrue: [^ self backgroundIndex].
	'costume #' localized = a ifTrue: [^ self backgroundIndex].
	'volume' localized = a ifTrue: [^ self volume].
	^ 0
! !

!ScratchStageMorph methodsFor: 'sensing ops' stamp: 'jm 4/18/2008 14:07'!
attributeNames

	^ #('background #' 'volume') collect: [:s | s]
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 10/3/2007 09:13'!
backgroundIndex
	"Answer the index of my current costume."

	^ self costumeIndex
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 2/14/2008 18:23'!
broadcastEventNamed: name with: value
	"Broadcast a ScratchEvent with given name and argument value to all Scratch objects and answer a collection of the newly created processes. This is done by finding all public scripts that respond to this event, and starting new processes for any not already running."

	| event objList newProcs |
	scratchServer ifNotNil: [scratchServer queueBroadcast: name].
	event _ ScratchEvent new name: name argument: value.
	newProcs _ OrderedCollection new.

	"start scripts"
	objList _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	objList do: [:obj |
		newProcs addAll: (obj eventReceived: event)].
	newProcs addAll: (self eventReceived: event).

	^ newProcs asArray
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 10/6/2006 22:22'!
changeBackgroundIndexBy: aNumber
	"Change my background index by the given amount."

	self changeCostumeIndexBy: aNumber.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 18:58'!
changeHPanBy: amount
	"Change my horizontal pan by the given amount."

	hPan _ hPan + amount truncated.
	self changed.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 18:59'!
changeVPanBy: amount
	"Change my vertical pan by the given amount."

	vPan _ vPan + amount truncated.
	self changed.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 19:00'!
changeZoomBy: percent
	"Change my zoom by the given percent."

	zoom _ zoom + percent.
	self changed.
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 2/24/2011 20:09'!
clearAllVariables

	self clearVariables.
	sprites do: [:each |
		each clearVariables]
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 2/5/2005 11:31'!
clearPenTrails
	"Remove my pen trails Form. It will be recreated later if it is needed."

	penTrailsForm _ nil.
	self changed.
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:08'!
closeMIDI
	"Close the MIDI port and clear the note player dictionary."

	midiPort ifNotNil: [
		midiPort close.
		midiPort _ nil].
	notePlayerDict _ Dictionary new.
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 11/21/2008 13:57'!
containsPoint: aPoint

	self isQuarterSize ifTrue: [^ (self position extent: self extent // 2)  containsPoint: aPoint].
	^ self bounds containsPoint: aPoint
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 8/2/2004 20:14'!
copyForExport
	"Answer a copy of me with no sprites for use in exporting the background by itself."

	^ super copyForExport removeAllMorphs
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 11/22/2004 13:43'!
costumeChanged

	costumeChangeMSecs _ Time millisecondClockValue.
	filterPack ifNotNil: [filterPack clearFilterCaches].
	self changed.
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'JM 11/14/2011 11:39'!
createOrResizeTrailsForm
	"If necessary, create a new penTrailsForm or resize the existing one to fill my bounds. On return, penTrailsForm will be a Form of the correct size."

	| newForm |
	penTrailsForm ifNil: [
		penTrailsForm _ Form extent: self extent depth: 32.
		^ self].

	penTrailsForm extent = self extent ifFalse: [  "resize trails Form to my current exent"
		newForm _ Form extent: self extent depth: 32.
		newForm
			copy: penTrailsForm boundingBox
			from: penTrailsForm
			to: 0@0
			rule: Form paint.
		penTrailsForm _ newForm].
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 9/27/2007 15:10'!
defaultEventName
	"Answer a default event name for message send and receive blocks."

	| evtNames |
	evtNames _ self allEventNames.
	^ evtNames size = 0 ifTrue: [''] ifFalse: [evtNames first]
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'ee 11/12/2007 14:12'!
defaultImageMedia

	^ ImageMedia new
		form: DefaultBackgroundForm;
		mediaName: ('background' localized, '1')
! !

!ScratchStageMorph methodsFor: 'clones' stamp: 'jm 6/6/2008 14:41'!
deleteAllClones
	"Delete all clones."

	self allClones do: [:clone | clone delete].
! !

!ScratchStageMorph methodsFor: 'byob OOP' stamp: 'jens 1/31/2011 00:30'!
deleteSprite
	"override the inherited default method to do nothing"
	^ self! !

!ScratchStageMorph methodsFor: 'clones' stamp: 'jm 6/4/2009 12:34'!
deleteTerminatedClones
	"Delete all clones that have no running scripts."

	| isRunning |
	self allClones do: [:clone |
		isRunning _ false.
		clone blocksBin allMorphsDo: [:b |
			((b isKindOf: BlockMorph) and: [b hasRunningProcess])
				ifTrue: [isRunning _ true]].
		isRunning ifFalse: [clone delete]].
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'JM 11/14/2011 12:16'!
drawCircleFor: aSprite radius: aNumber

	| o d circle |

	self createOrResizeTrailsForm.
	o _ 	aSprite referencePosition + ScratchOrigin.
	d _ aNumber@aNumber * 2.

	circle _ FormCanvas on: penTrailsForm.
	circle fillOval: (Rectangle origin: o corner: d) color: Color red borderWidth: 2 borderColor: Color black.

	Transcript show: o; cr.
	Transcript show: d; cr.
	Transcript show: ScratchOrigin.! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'JM 11/8/2011 16:41'!
drawOn: aCanvas
	"Draw myself if my visibility is > 0. If my visibility is 1, draw using the normal 'paint' mode. Otherwise, draw using 'alpha' resulting in a partially transparent rendering."

	| clipC f p alpha |
	clipC _ aCanvas copyClipRect: bounds.
	clipC fillRectangle: bounds color: Color white.
	f _ self filteredForm.

	f ifNotNil: [
		p _ bounds center - (f extent // 2) + (hPan@vPan).
		visibility < 100
			ifTrue: [
				visibility > 0 ifTrue: [
					alpha _ ((255.0 * visibility) / 100.0) truncated.
					clipC paintImage: f at: p sourceRect: f boundingBox alpha: alpha]]
			ifFalse: [clipC paintImage: f at: p]].

	self updateTrailsForm.
	penTrailsForm ifNotNil: [clipC translucentImage: penTrailsForm at: self position].
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'JM 11/10/2011 14:20'!
drawPenTrailFor: aMorph from: oldPoint to: newPoint
	"Draw a pen trail between the given points for the given morph using its pen size and color. The points are in Scratch coordinates (that is, 0@0 is the center of the work pane and y increases toward the top of the screen."
	"The penTrailsForm is created on demand when the first pen is put down and removed (to save space) when pen trails are cleared."

	| pen penSize offset p1 p2 r |
	self createOrResizeTrailsForm.
	pen _ Pen newOnForm: penTrailsForm. 
	penSize _ aMorph penSize.
	aMorph penSize ~= 1 ifTrue: [
		pen roundNib: penSize.
		pen sourceForm offset: nil].  "clear form offset"
	pen color: (aMorph penColor alpha: 1.0 - (aMorph penGhosting / 100)).
	offset _ (penTrailsForm extent - penSize) / 2.0.
	p1 _ ((oldPoint * (1 @ -1)) + offset) rounded.
	p2 _ ((newPoint * (1 @ -1)) + offset) rounded.
	pen combinationRule: 24.
	pen drawFrom: p1 to: p2 withFirstPoint: false.
	r _ ((p1 rect: p2) expandBy: penSize + 1) translateBy: self topLeft.
	self invalidRect: r.
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 1/23/2009 11:14'!
drawQuarterSizeOn: aCanvas
	"Draw myself and my submorphs to an offscreen canvas, then scale down to quarter size and draw that on the given canvas."

	| r srcR c |
	cachedForm ifNil: [cachedForm _ Form extent: self extent depth: 32].
	r _ aCanvas clipRect intersect: (bounds origin extent: bounds extent // 2).

	srcR _ ((r origin - bounds origin) * 2.0) truncated extent: (r extent * 2.0) rounded.
	c _ (FormCanvas on: cachedForm)
		copyOrigin: self position negated
		clipRect: srcR.
	super fullDrawOn: c.

	ScratchPlugin halfSize: cachedForm into: Display srcPoint: srcR origin dstRect: r.

"xxx
	cachedForm unhibernate.
	LowResPlugin
		primHalf2Average: cachedForm bits w: cachedForm width h: cachedForm height
		into: Display bits w: Display width h: Display height
		srcX: srcR left srcY: srcR top
		dstX: r left dstY: r top dstW: r width dstH: r height.

	(WarpBlt toForm: Display)
		sourceForm: cachedForm;
		combinationRule: Form over;
		clipRect: aCanvas clipRect;
		cellSize: 2;
		copyQuad: srcR corners toRect: r.
xxx"

	"the following scales down entire stage:"
"	LowResPlugin scale: cachedForm into: aCanvas form at: aCanvas origin + self position."
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 11/30/2007 23:41'!
drawSubmorphsOn: aCanvas
	"Clip submorph drawing to my bounds."

	| clipCanvas |
	clipCanvas _ aCanvas copyClipRect: bounds.
	submorphs reverseDo:[:m |
		(clipCanvas isVisible: m fullBounds) ifTrue: [
			m fullDrawOn: clipCanvas]].

	"draw sprite talk bubbles in front of all morphs:"
	submorphs reverseDo:[:m |
		((m isKindOf: ScratchSpriteMorph) and:
		 [m isHidden not and:
		 [clipCanvas isVisible: m fullBounds]]) ifTrue: [
			m drawTalkBubbleOn: clipCanvas]].

! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 12/16/2006 12:21'!
exportFileName: fileName

	| form fName |
	form _ self stageShotForm.
	form depth <= 8 ifTrue: [
		(fileName asLowercase endsWith: '.gif')
			ifTrue: [fName _ fileName]
			ifFalse: [fName _ fileName, '.gif'].
		GIFReadWriter putForm: form colorReduced8Bit onFileNamed: fName.
		^ self].

	(fileName asLowercase endsWith: '.bmp')
		ifTrue: [fName _ fileName]
		ifFalse: [fName _ fileName, '.bmp'].
	(form asFormOfDepth: 32) writeBMPFileNamed: fName.
! !

!ScratchStageMorph methodsFor: 'object i/o' stamp: 'nb 1/7/2008 14:01'!
fieldsVersion

	^ 5
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 6/3/2004 20:17'!
fullBounds
	"Overridden to clip submorph hit detection to my bounds."

	^ bounds
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 12/9/2008 10:53'!
fullContainsPoint: aPoint
	"Answer true if the given point is in my visible bounds. In quarterSize mode, my visible bounds is only half of my extent."

	| r |
	r _ self isQuarterSize
		ifTrue: [self position extent: bounds extent // 2]
		ifFalse: [bounds].

	^ r containsPoint: aPoint
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 12/9/2008 10:51'!
fullDrawOn: aCanvas
	"Calls super fullDrawOn and then draws the frame shadow"

	| shadowOrigin topShadowExtent leftShadowExtent alphas |

	(self isQuarterSize and: [self isInWorld]) ifTrue: [
		^ self drawQuarterSizeOn: aCanvas].

	super fullDrawOn: aCanvas.

	"don't draw shadows if owner is not a ScratchFrameMorph"
	(owner isKindOf: ScratchFrameMorph) ifFalse: [^ self].

	"shadow constants"
	shadowOrigin _ self topLeft + aCanvas origin.
	topShadowExtent _ self width@1.
	leftShadowExtent _ 1@self height.

	"shadow alpha values"
	alphas _ FloatArray
		with: 0.51
		with: 0.26
		with: 0.07.

	"top/horizontal shadow"
	1 to: 3 do: [:i |
		aCanvas grafPort
			fill: (shadowOrigin + (0@(i-1)) extent: topShadowExtent)
			fillColor: (Color black alpha: (alphas at: i))
			rule: Form blend].

	"left/vertical shadow"
	1 to: 3 do: [:i |
		aCanvas grafPort
			fill: (shadowOrigin + ((i-1)@0) extent: leftShadowExtent)
			fillColor: (Color black alpha: (alphas at: i))
			rule: Form blend].

	"corner shadow fix"
	aCanvas grafPort
		fill: (shadowOrigin extent: (1@1))
		fillColor: (Color white alpha: 0.32)
		rule: Form blend.
	aCanvas grafPort
		fill: (shadowOrigin +(0@1) extent: (1@1))
		fillColor: (Color white alpha: 0.19)
		rule: Form blend.
	aCanvas grafPort
		fill: (shadowOrigin + (1@0) extent: (1@1))
		fillColor: (Color white alpha: 0.19)
		rule: Form blend.
	aCanvas grafPort
		fill: (shadowOrigin +(0@2) extent: (1@1))
		fillColor: (Color white alpha: 0.05)
		rule: Form blend.
	aCanvas grafPort
		fill: (shadowOrigin + (2@0) extent: (1@1))
		fillColor: (Color white alpha: 0.05)
		rule: Form blend.
! !

!ScratchStageMorph methodsFor: 'sensing ops' stamp: 'jens 1/24/2011 22:42'!
getAttribute: attr
	"Answer the value of my variable or built-in attribute with the given name. Answer zero if I have no attribute or variable with the given name."

	| a |
	(vars includesKey: attr) ifTrue: [^ vars at: attr].
	(self allLocalBlockIds includes: attr) ifTrue: [ ^self lambda: attr ].

	a _ attr localized.
	'background #' localized = a ifTrue: [^ self backgroundIndex].
	'costume #' localized = a ifTrue: [^ self backgroundIndex].
	'volume' localized = a ifTrue: [^ self volume].
	^ 0
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 8/3/2008 13:16'!
grabSpriteFromScreen
	"Create a new sprite, grabbing it's costume from an area of the screen."

	| frame m f |
	(frame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self].
	m _ ScratchSpriteMorph new.
	(f _ m grabFormFromScreen) ifNil: [^ self].
	m onlyCostume: f.
	frame addAndView: m.

! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 11/8/2006 18:09'!
incrRedraw: damageList
	"Redraw the damaged areas of this stage directly onto the display. Assumes that no other morph is in front of me."

	| f c p screenR |
	damageList do: [:r |
		f _ Form extent: r extent depth: 32.
		c _ (FormCanvas on: f) copyOffset: r origin negated.
		self fullDrawOn: c.
		DoubleSize
			ifTrue: [
				p _ (self center - self extent) + (2 * (r origin - self topLeft)).
				screenR _ p extent: 2 * f extent.
				(Display boundingBox containsRect: screenR) ifTrue: [
					[
						ScratchPlugin
							primDouble: f bits w: f width h: f height
							into: Display bits w: Display width h: Display height
							x: screenR left y: screenR top.
					] ifError: [].
					Display forceToScreen: screenR]]
			ifFalse: [
				f displayOn: Display at: r topLeft rule: Form over]].
! !

!ScratchStageMorph methodsFor: 'object i/o' stamp: 'jm 7/8/2008 06:13'!
initFieldsFrom: anObjStream version: classVersion

	super initFieldsFrom: anObjStream version: classVersion.
	self initFieldsNamed: #(
		zoom
		hPan
		vPan
	) from: anObjStream.
	classVersion = 1 ifTrue: [^ self].

	"fields added in version 2"
	self initFieldsNamed: #(
		obsoleteSavedState
	) from: anObjStream.
	classVersion = 2 ifTrue: [^ self].

	"fields added in version 3"
	self initFieldsNamed: #(
		sprites
	) from: anObjStream.
	classVersion = 3 ifTrue: [^ self].

	"fields added in version 4"
	self initFieldsNamed: #(
		volume
		tempoBPM
	) from: anObjStream.
	classVersion = 4 ifTrue: [^ self].

	"fields added in version 5"
	self initFieldsNamed: #(
		sceneStates
		lists
	) from: anObjStream.
	lists ifNil: [lists _ Dictionary new].  "work around"
! !

!ScratchStageMorph methodsFor: 'initialization' stamp: 'jm 6/4/2009 12:03'!
initialize

	super initialize.
	color _ Color white.
	self enableDragNDrop: true.
	objName _ 'Stage' localized.
	costume _ self defaultImageMedia.
	media _ OrderedCollection with: costume with: SoundMedia new.
	zoom _ 1.0.
	hPan _ 0.
	vPan _ 0.
	runningBlocks _ OrderedCollection new.
	inProcessStep _ false.
	sensorBoard _ SensorBoardMorph new.
	midiPortNum _ -1.
	notePlayerDict _ Dictionary new.
	obsoleteSavedState _ nil.
	sprites _ OrderedCollection new.
	showMotorBlocks _ false.
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 12/10/2008 13:57'!
invalidRect: damageRect
	"Clip damage reports to my bounds, since drawing is clipped to my bounds."

	| r |
	(owner isKindOf: ScratchFrameMorph) ifTrue: [owner projectModified].

	(self isQuarterSize and: [owner isKindOf: ScratchFrameMorph])
		ifTrue: [
			r _ (bounds origin + ((damageRect origin - bounds origin) / 2.0)) extent: (damageRect extent / 2.0).
			r _ r intersect: (bounds origin extent: bounds extent // 2)]
		ifFalse: [
			r _ (damageRect topLeft truncated) corner: (damageRect right ceiling@damageRect bottom ceiling).
			r _ r intersect: self bounds].

	(r width > 0 and: [r height > 0]) ifTrue: [super invalidRect: r].
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 5/18/2010 01:35'!
isPaused

	| allObjs |
	allObjs _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	allObjs _ allObjs copyWith: self.
	allObjs do: [:obj |
		(obj blocksBin isKindOf: Morph) ifTrue: [
			obj blocksBin submorphs do: [:b |
				(b isKindOf: BlockMorph) ifTrue: [(b scratchProc notNil and: [b scratchProc isPaused not]) ifTrue: [^ false]]]]].
	^ true

! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 11/18/2008 15:37'!
isQuarterSize

	isQuarterSize ifNil: [isQuarterSize _ false].  "lazy initialization"
	^ isQuarterSize
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 11/18/2008 13:09'!
isQuarterSize: aBoolean

	isQuarterSize _ aBoolean.
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 11/23/2009 21:28'!
listInVarNamed: varName targetName: targetName

	targetName = 'Stage' ifTrue: [
		^self getVar: varName].

	sprites do: [:sprite |
		(sprite varNames includes: varName)
			ifTrue: [^sprite getVar: varName]].

	^ nil! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 11/23/2009 21:26'!
listNamed: listName targetName: targetName

	targetName = 'Stage' ifTrue: [
		^self listNamed: listName ].

	sprites do: [:sprite |
		(sprite listVarNames includes: listName)
			ifTrue: [^sprite listNamed: listName ]].

	^ nil! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jens 2/8/2011 23:02'!
lookLike: costumeName

	self undeleteAttribute: #costumeIndex.
	self passiveLookLike: costumeName.
	costumeName isNumber ifFalse: [
		self lookLike: self costumeIndex ].! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/18/2004 18:16'!
makeVisible
	"Do nothing. I'm always visible."
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:09'!
midiAllNotesOff
	"If the MIDI port is open, send an 'all notes off' command on every channel."

	midiPort ifNil: [^ self].
	midiPort ensureOpenIfFail: [self closeMIDI].
	notePlayerDict do: [:player | player noteOff].
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:23'!
midiPortNum

	^ midiPortNum
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:23'!
midiPortNum: anInteger

	midiPortNum _ anInteger.

! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 12/19/2008 17:22'!
mouseDown: evt
	"Handle a mouse down event."

	evt hand newKeyboardFocus: nil.
	evt hand toolType ifNotNil: [evt hand toolType: nil].

	evt rightButtonPressed
		ifTrue: [Sensor waitNoButton. ^ self rightButtonMenu]
		ifFalse:	[evt hand waitForClicksOrDrag: self event: evt].
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'ee 6/27/2008 17:46'!
newScene

	| sceneName |
	sceneName _ StringDialog ask: 'Enter Scene Name:'.
	sceneName size = 0 ifTrue: [ ^ self ].

	sceneStates at: sceneName put: self backgroundIndex.
	submorphs do: [:m |
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			m recordScene: sceneName]].
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 11/28/2006 13:39'!
nextBackground
	"Show the next background in my backgrounds list."

	self nextCostume.
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 6/2/2009 18:46'!
notePlayerFor: aScratchObject
	"Answer a note player for the given object, creating one if necessary. Open the MIDI port if necessary."

	| deletedMorphs channelUsage ch newCh newPlayer |
	midiPort ifNil: [self tryToOpenMidiPort].

	(notePlayerDict includesKey: aScratchObject) ifTrue: [
		^ notePlayerDict at: aScratchObject].

	"remove deleted morphs from the note player dictionary"
	deletedMorphs _ notePlayerDict keys select: [:m | m owner isNil].
	deletedMorphs do: [:m | notePlayerDict removeKey: m].

	"find the channel used by the fewest objects"
	channelUsage _ Array new: 16 withAll: 0.
	channelUsage at: 10 put: 1000000.  "make sure channel 10 (drums) is not chosen"
	notePlayerDict do: [:player |
		ch _ player channel.
		channelUsage at: ch put: (channelUsage at: ch) + 1].
	newCh _ channelUsage indexOf: channelUsage min.

	newPlayer _ ScratchNotePlayer new
		channel: newCh;
		midiPort: midiPort;
		instrument: 1.
	notePlayerDict at: aScratchObject put: newPlayer.

	^ newPlayer
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 10/25/2007 19:21'!
objName

	^ 'Stage' localized
! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 8/2/2005 19:09'!
openMIDI
	"Prompt the user to select a MIDI port number, then open it."

	| possiblePorts dir menu choice |
	self closeMIDI.
	possiblePorts _ (0 to: SimpleMIDIPort primPortCount - 1) select: [:i |
		dir _ SimpleMIDIPort primPortDirectionalityOf: i.
		(dir = 2) | (dir = 3)].  "out or in/out port"
	possiblePorts size = 0 ifTrue: [^ self inform: 'No MIDI ports currently available.'].
	menu _ CustomMenu new title: 'MIDI port:'.
	possiblePorts do: [:i | menu add: (SimpleMIDIPort portDescription: i) action: i].
	choice _ menu startUp.
	choice ifNil: [^ self].
	midiPortNum _ choice.
	self tryToOpenMidiPort.
! !

!ScratchStageMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 22:49'!
passiveLookLike: costumeName
	"Change to the costume with the given name. Noop if there is no costume of the given name in my library."

	zoom _ 100.
	hPan _ 0.
	vPan _ 0.
	super lookLike: costumeName.

	self propagate: #costumeIndex! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'ee 8/1/2008 17:17'!
patchAt: patchRect withoutWatchersAnd: stopMorph andNothingAbove: stopThere
	"Return a complete rendering of this patch of the display screen without drawing stopMorph and, if stopThere is true, without drawing any morph above it."

	| c morphsToDraw i |
	c _ FormCanvas extent: patchRect extent depth: Display depth.
	c _ c copyOrigin: patchRect topLeft negated clipRect: (0@0 extent: patchRect extent).

	(self bounds containsRect: patchRect) ifFalse: [
		"fill areas of patchRect outside my bounds with black"
		c form fillColor: Color black].
	(self bounds intersects: patchRect) ifFalse: [^ c form].  "entirely out of bounds"

	"draw all morphs intersecting the given patch, stopping at the given morph"
	c fillRectangle: self bounds color: color.  "draw world color"
	self drawOn: c.
	morphsToDraw _ submorphs reversed asOrderedCollection.
	(i _ morphsToDraw indexOf: stopMorph) > 0 ifTrue: [
		stopThere
			ifTrue: [morphsToDraw _ morphsToDraw copyFrom: 1 to: i - 1]  "stop at stopMorph"
			ifFalse: [morphsToDraw removeIndex: i]].  "skip stopMorph"
	morphsToDraw do: [:m |
		((m isKindOf: WatcherMorph) or: [(m isKindOf: SensorBoardMorph)])
			ifFalse: [m fullDrawOn: c]].
	^ c form
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 10/18/2010 02:03'!
pauseAllProcesses
	"Pause all running Scratch processes."

	| allObjs |
	"pause all sounds"
	SoundPlayer pauseAll.
		
	"clear all processes, including those with error feedback"
"
	allObjs _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	allObjs _ allObjs copyWith: self.
	allObjs do: [:obj |
		(obj blocksBin isKindOf: Morph) ifTrue: [
			obj blocksBin submorphs do: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b pauseProcess]]]].
"

	runningBlocks do: [:each |
		each pauseProcess]
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 6/2/2009 18:50'!
penTrailsForm

	^ penTrailsForm
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 6/2/2009 18:51'!
penTrailsForm: aForm

	penTrailsForm _ aForm.
	penTrailsForm ifNotNil: [self createOrResizeTrailsForm].
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 10/6/2007 14:53'!
penUpOrDownChangeFor: aSprite
	"The pen up/down state for the given sprite may have changed; update lastPenPositions accordingly."

	| p |
	aSprite penDown
		ifTrue: [  "pen down transition"
			lastPenPositions ifNil: [lastPenPositions _ IdentityDictionary new].
			p _ aSprite penPosition.
			lastPenPositions at: aSprite put: p.
			self drawPenTrailFor: aSprite from: p to: p]
		ifFalse: [
			lastPenPositions ifNil: [^ self].
			lastPenPositions removeKey: aSprite ifAbsent: [].
			lastPenPositions size = 0 ifTrue: [lastPenPositions _ nil]].
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 8/2/2006 14:43'!
previewForm
	"Answer a full-size preview of me and my submorphs. Use super fullDrawOn: to avoid drawing the shadows along the top and left edges of the workspace."

	| canvas |
	canvas _ FormCanvas extent: bounds extent depth: 32.
	canvas translateBy: bounds topLeft negated during: [:c | super fullDrawOn: c].
	^ canvas form
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 12:10'!
processesToRun
	"Answer a collection of processes to run. Filter out any processes for objects have been picked up. Always return a copy of the processes list."

	| result m |
	result _ runningBlocks collect: [:b | b scratchProc].
	result _ result select: [:proc | proc notNil].

	World activeHand submorphs size > 0 ifTrue: [
		m _ World activeHand submorphs first.
		result _ result select: [:proc | (proc includesReceiver: m) not]].

	^ result
 ! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 11/23/2009 20:33'!
referenceToList: aScratchList

	"answer an Array describing the variable which holds an anonymous list, nil
	if there isn't any.

	format:

		1 - target obj name
		2 - var name"

	self varNames do: [:key |
		aScratchList == (vars at: key)
			ifTrue: [^ Array with: 'Stage' with: key ]].

	sprites do: [:sprite |
		sprite varNames do: [:vname |
			aScratchList == (sprite getVar: vname)
				ifTrue: [^ Array with: sprite objName with: vname ]]].

	^ nil! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 13:06'!
removeTerminatedProcesses
	"Remove terminated processes from the process list."

	| newRunning proc |
	newRunning _ runningBlocks species new: 100.
	runningBlocks do: [:b |
		(proc _ b scratchProc) ifNotNil: [
			proc isRunning
				ifTrue: [newRunning addLast: b]
				ifFalse: [proc errorFlag ifFalse: [b stop]]]].

	runningBlocks _ newRunning.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'nb 1/7/2008 14:19'!
rerecordScene

	| sceneName sceneList menu |
	sceneList _ self sceneNames .
	sceneList _ sceneList copyFrom: 1 to: sceneList size - 3.
	menu _ CustomMenu new.
	sceneList do: [:n | menu add: n action: n].
	(sceneName _ menu startUp) ifNil: [^ self].

	sceneStates at: sceneName put: self backgroundIndex.
	submorphs do: [:m |
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			m recordScene: sceneName]].
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 10/18/2010 02:04'!
resumeAllProcesses
	"Pause all running Scratch processes."

	| allObjs |
	"resume all sounds"
	SoundPlayer resumeAll.

	"clear all processes, including those with error feedback"
"
	allObjs _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	allObjs _ allObjs copyWith: self.
	allObjs do: [:obj |
		(obj blocksBin isKindOf: Morph) ifTrue: [
			obj blocksBin submorphs do: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b resumeProcess]]]].

"

	runningBlocks do: [:each |
		each resumeProcess]
! !

!ScratchStageMorph methodsFor: 'menus' stamp: 'jm 10/25/2007 19:25'!
rightButtonMenu
	"Present the right button menu."

	| menu |
	menu _ CustomMenu new.
	menu add: 'grab screen region for new sprite' action: #grabSpriteFromScreen.
	menu addLine.
	menu add: 'save picture of stage...' action: #stageShot.
	menu localize; invokeOn: self.
! !

!ScratchStageMorph methodsFor: 'dropping/grabbing' stamp: 'jm 5/25/2004 14:56'!
rootForGrabOf: aMorph
	"Allow the given submorph to be extracted."

	| root |
	root _ aMorph.
	[root = self] whileFalse: [
		root owner == self ifTrue: [^ root].
		root _ root owner].

	^ super rootForGrabOf: aMorph
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 3/18/2005 23:41'!
rotationCenter

	^ costume rotationCenter
! !

!ScratchStageMorph methodsFor: 'media' stamp: 'jm 6/22/2009 14:15'!
savePhoto: aForm

	| n f |
	n _ self unusedMediaNameFromBaseName: 'background' localized, '1'.

	f _ Form extent: self extent depth: 32.
	(WarpBlt toForm: f)
		sourceForm: aForm;
		cellSize: 1;  "installs a new colormap if cellSize > 1"
		combinationRule: Form over;
		copyQuad: aForm boundingBox innerCorners toRect: f boundingBox.

	self addMediaItem: (ImageMedia new mediaName: n; form: f).

! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 4/25/2008 16:01'!
sceneNames

	| setOfNames |
	setOfNames _ Set new.
	submorphs do: [:m |
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			setOfNames addAll: m scenes]].

	^ setOfNames asArray sort, (Array
		with: '-'
		with: 'record' localized, ScratchTranslator ellipsesSuffix
		with: 're-record' localized, ScratchTranslator ellipsesSuffix)
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 2/14/2008 18:21'!
scratchServer

	^ scratchServer
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 2/14/2008 18:22'!
scratchServer: anObject

	scratchServer _ anObject.
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 8/2/2005 19:02'!
sensorBoard

	^ sensorBoard
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 11/28/2005 14:52'!
sensorBoard: aSensorBoardMorph

	sensorBoard _ aSensorBoardMorph.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 19:00'!
setHPanTo: aNumber
	"Set my horizontal pan to the given offset."

	hPan _ aNumber truncated.
	self changed.

! !

!ScratchStageMorph methodsFor: 'sound ops' stamp: 'jens 2/4/2011 02:37'!
setTempoTo: aNumber

	tempoBPM _ (aNumber asNumberNoError within: 20 and: 500).
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 19:00'!
setVPanTo: aNumber
	"Set my vertical pan to the given offset."

	vPan _ aNumber truncated.
	self changed.

! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 6/2/2004 19:01'!
setZoomTo: percent
	"Set my zoom to the given percent."

	zoom _ percent truncated.
	self changed.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'jm 12/11/2006 11:42'!
showBackground: costumeNameOrIndex
	"This is lookLike: for the stage..."

	self lookLike: costumeNameOrIndex.
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 2/13/2009 14:49'!
showMotorBlocks

	^ showMotorBlocks
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'jm 2/13/2009 14:49'!
showMotorBlocks: aBoolean

	showMotorBlocks _ aBoolean.
! !

!ScratchStageMorph methodsFor: 'looks ops' stamp: 'nb 1/7/2008 12:52'!
showScene: sceneName

	(sceneStates includesKey: sceneName) ifTrue: [
		self showBackground: (sceneStates at: sceneName)].

	submorphs do: [:m |
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			m setScene: sceneName]].
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'tis 11/2/2006 18:44'!
sprites

	^ sprites
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'tis 12/7/2006 16:04'!
stageShot

	| result |
	result _ ScratchFileChooserDialog
		chooseNewFileDefault: ''
		title: 'Save Stage Shot'
		type: #stageShot.
	result = #cancelled ifTrue: [^ self].
	result size > 0 ifTrue: [self exportFileName: result].
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'tis 8/3/2006 16:06'!
stageShotForm
	"Answer a stage shot of me and my submorphs."

	^ self stageShotSized: self width @ self height
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'tis 8/3/2006 15:55'!
stageShotSized: size
	"Answer a thumbnail of me and my submorphs. Use super fullDrawOn: to avoid drawing the shadows along the top and left edges of the workspace."

	| canvas thumbForm |
	canvas _ FormCanvas extent: bounds extent depth: 32.
	canvas translateBy: bounds topLeft negated during: [:c | super fullDrawOn: c].
	thumbForm _ Form extent: size depth: 32.
	(WarpBlt toForm: thumbForm)
		sourceForm: canvas form;
		cellSize: 2;
		combinationRule: Form over;
		copyQuad: (0@0 extent: canvas extent) innerCorners toRect: thumbForm boundingBox.

	thumbForm _ thumbForm colorReduced.  "first try to make a ColorForm with exact colors"
	thumbForm depth > 8 ifTrue: [
		thumbForm _ thumbForm asFormOfDepth: 8].  "if that fails, use the closest 8-bit colors"
	^ thumbForm

! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'JM 11/9/2011 16:53'!
stampCostume: aSprite
	"Stamp a copy of the given sprite on my pen trails form."
	
	| f b destLoc |
	f _ aSprite filteredForm.
	destLoc _ aSprite bounds origin - (bounds origin).

	self createOrResizeTrailsForm.

	b _ BitBlt toForm: penTrailsForm.
	b sourceForm: f;
		combinationRule: 31;
		destX: destLoc x;
		destY: destLoc y;
		sourceX: 0;
		sourceY: 0;
		width: f width;
		height: f height;
		copyBitsTranslucent: (aSprite visibility / 100 * 255) rounded.
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 3/2/2009 15:22'!
startDrag: evt
	"Ignore drag events."
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 12:27'!
startProcessFor: topBlock
	"Start a process to run the given block or stack of blocks. Return the new process."

	| sequence proc |
	sequence _ topBlock blockSequence.
	sequence first isHatBlock ifTrue: [
		sequence _ sequence allButFirst].  "skip hat block"

	topBlock scratchProc ifNotNil: [topBlock stop].

	proc _ ScratchProcess new
		topBlock: topBlock;
		expression: sequence.
	topBlock scratchProc: proc.

	(runningBlocks includes: topBlock) ifFalse: [runningBlocks addLast: topBlock].

	^ proc
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 9/22/2010 01:29'!
startProcessForSequence: anArray
	"Start a process to run the given block or stack of blocks. Return the new process."

	| sequence proc topBlock |
	sequence _ anArray last.
	topBlock _ sequence first.
	sequence first isHatBlock ifTrue: [
		sequence _ sequence allButFirst].  "skip hat block"

	topBlock scratchProc ifNotNil: [topBlock stop].

	proc _ ScratchProcess new
		topBlock: topBlock;
		scriptList: anArray;
		expression: sequence.
	topBlock scratchProc: proc.
	(runningBlocks includes: topBlock) ifFalse: [runningBlocks addLast: topBlock].

	^ proc
! !

!ScratchStageMorph methodsFor: 'nesting' stamp: 'jens 8/4/2009 00:08'!
step

	| cp targets dragged |
	super step.
	feedbackMorph ifNotNil: [feedbackMorph delete].
	cp _ self adjustedCursorPoint. Sensor cursorPoint. 
	(self containsPoint: Sensor cursorPoint) ifFalse: [^self].
	(World activeHand submorphs isEmpty not and: [World activeHand submorphs first isKindOf: LibraryItemMorph]) ifFalse: [^self].
	dragged _ World activeHand submorphs first target.
	targets _ self sprites select: [:each| 
		each containsPoint: cp ].
	targets size > 0 ifTrue: [
		targets first == dragged ifFalse:[
			feedbackMorph _ targets first feedbackMorph.
			World activeHand addMorphFront: feedbackMorph ]].


! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 12/12/2008 14:08'!
stepProcesses
	"Run each Scratch process until it gives up control, then filter out any processes that have terminated."
	"Details: Iterate over a copy of processes to allow processes to stop themselves. During development, the error catcher makes it difficult to track down errors, so it can be disabled."

	| proc |
	sensorBoard processIncomingData.

	ScratchProcess blockHighlightMSecs = 0 ifTrue: [^ self stepProcessesTurbo].

	inProcessStep ifTrue: [^ self].
	inProcessStep _ true.
	ScratchFrameMorph useErrorCatcher
		ifTrue: [
			[self processesToRun do: [:p | (proc _ p) runStepFor: self]]
				ifError: [proc errorFlag: true]]
		ifFalse: [
			self processesToRun do: [:p | p runStepFor: self]].

	self removeTerminatedProcesses.
"	self deleteTerminatedClones."

	inProcessStep _ false.
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 12:03'!
stepProcessesTurbo
	"Run each Scratch process until it gives up control, then filter out any processes that have terminated. Do this repeatedly until time is up."

	| sliceMSecs startMSecs now proc |
	sliceMSecs _ 100.
	inProcessStep ifTrue: [^ self].
	inProcessStep _ true.

	startMSecs _ Time millisecondClockValue.
	[
		[now _ Time millisecondClockValue.
		 runningBlocks size > 0 and:
		  [(now >= startMSecs) and: [(now - startMSecs) < sliceMSecs]]] whileTrue: [
			self processesToRun do: [:p | (proc _ p) runStepFor: self].
			self removeTerminatedProcesses].
	] ifError: [proc errorFlag: true].

	inProcessStep _ false.
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jens 5/21/2010 03:09'!
stopAll
	"Stop all processes and make sure I am stepping."

	| sFrame |
	World hands do: [:h | h newKeyboardFocus: nil; clearUnclaimedKeystrokes].
	Sensor clearKeystate.
	SoundPlayer stopPlayingAll.
	self class stopSoundRecorder.
	self stopAllProcesses.
	self stopAsks.
	self deleteAllClones.
	self midiAllNotesOff.
	WeDoPlugin resetWeDo.
	self stopPlaying.
	self allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [m stopPlaying]].

	DebuggerFrameMorph allInstancesDo: [:df | df delete ].

	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNotNil: [
		sFrame scriptsPane allMorphsDo: [:m |
			(m respondsTo: #stop) ifTrue: [m stop].
			(m respondsTo: #litUp:) ifTrue: [m litUp: false]].
		World startSteppingSubmorphsOf: sFrame].

	World startSteppingSubmorphsOf: self.
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 6/4/2009 13:13'!
stopAllProcesses
	"Stop all running Scratch processes."

	| allObjs |
	"clear all processes, including those with error feedback"
	allObjs _ submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	allObjs _ allObjs copyWith: self.
	allObjs do: [:obj |
		(obj blocksBin isKindOf: Morph) ifTrue: [
			obj blocksBin submorphs do: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b clearProcess]]]].

	runningBlocks _ OrderedCollection new.
	inProcessStep _ false.
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 6/9/2010 00:20'!
stopAllScriptsFor: eventName

"	remember to implement this in the mesh network later -jens"
"	scratchServer ifNotNil: [scratchServer queueBroadcast: name]."

	"stop scripts"
	submorphs do: [:m | (m isKindOf: ScriptableScratchMorph) ifTrue: [
		m stopScriptsFor: eventName]].
	self stopScriptsFor: eventName 
! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 12/1/2006 19:02'!
stopAllSounds
	"Stop all sounds and MIDI notes/drums."

	SoundPlayer shutDown.
	self midiAllNotesOff.

! !

!ScratchStageMorph methodsFor: 'scratch processes/events' stamp: 'jm 3/24/2009 17:09'!
stopAsks
	"Stop/close any ask that is currently on the screen."

	ScratchPrompterMorph allInstancesDo: [:m | m stopAsk].
	ScratchPrompterMorph clearLastAnswer.
! !

!ScratchStageMorph methodsFor: 'object i/o' stamp: 'jm 5/12/2008 11:58'!
storeFieldsOn: anObjStream

	super storeFieldsOn: anObjStream.
	self storeFieldsNamed: #(
		zoom
		hPan
		vPan
		obsoleteSavedState
		sprites
		volume
		tempoBPM
		sceneStates
		lists
	) on: anObjStream.
! !

!ScratchStageMorph methodsFor: 'sound ops' stamp: 'jm 11/27/2007 11:26'!
tempo

	^ tempoBPM
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'tis 8/3/2006 16:01'!
thumbnailForm
	"Answer a thumbnail of me and my submorphs."

	^ self stageShotSized: (160@120)
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 5/18/2010 01:13'!
togglePause

	self isPaused
		ifTrue: [self resumeAllProcesses]
		ifFalse: [self pauseAllProcesses] ! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 11/18/2008 19:34'!
transformFrom: uberMorph
	"Return a transform to map coorinates of uberMorph, a morph above me in my owner chain, into the coordinates of my submorphs."

	| transform |
	self isQuarterSize ifFalse: [^ super transformFrom: uberMorph].

	transform _ MorphicTransform offset: (self position // -2) angle: 0.0 scale: 0.5.
	owner == uberMorph ifTrue: [^ transform].
	owner ifNil: [^ transform].
	^ (owner transformFrom: uberMorph) composedWith: transform

! !

!ScratchStageMorph methodsFor: 'midi' stamp: 'jm 6/3/2009 15:37'!
tryToOpenMidiPort
	"Attempt to open the MIDI port. First try the port selected by the user, if any. If that port number is not a MIDI output port, try to find another port number. If all measures fail, leave midiPort set to nil."

	| possiblePorts dir portNum |
	Smalltalk isUnix ifTrue: [midiPort _ nil. ^ self].

	possiblePorts _ (0 to: SimpleMIDIPort primPortCount - 1) select: [:i |
		dir _ SimpleMIDIPort primPortDirectionalityOf: i.
		(dir = 2) | (dir = 3)].  "out or in/out port"

	possiblePorts size = 0 ifTrue: [midiPort _ nil. ^ self].  "no midi ports"


	(possiblePorts includes: midiPortNum)
		ifTrue: [portNum _ midiPortNum]  "use the port requested by the user"
		ifFalse: [portNum _ possiblePorts first].  "use the first available port"
			
	[midiPort _ SimpleMIDIPort openOnPortNumber: portNum] ifError: [midiPort _ nil].
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 8/5/2010 11:30'!
unloadAllUnusedCustomBlocks

	'updating...' 
		displayProgressAt: Display center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((self allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size
		during: [:bar | | i | i _ 0.

	{self}, self sprites do: [:obj |
		i _ i + 1. bar value: i.
		obj unloadUnusedCustomBlocks]]
! !

!ScratchStageMorph methodsFor: 'event handling' stamp: 'jm 12/9/2008 10:53'!
unlockedMorphsAt: aPoint addTo: mList
	"Adjust aPoint to handle quarter-size case if necessary."

	| p |
	self isQuarterSize ifFalse: [
		super unlockedMorphsAt: aPoint addTo: mList.
		^ mList].

	(self containsPoint: aPoint) ifFalse: [^ mList]. "quick elimination"
	p _ self position + (2 * (aPoint - self position)).

	submorphs size > 0 ifTrue: [
		submorphs do: [:m | m unlockedMorphsAt: p addTo: mList]].
	mList addLast: self.

	^ mList
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 11/15/2006 16:57'!
updatePenPositionFor: aSprite
	"Update the given sprites pen position if necessary. Used to avoid drawing glitches when going between normal and presentation mode."

	lastPenPositions ifNil: [^ self].  "no pens are down"
	(lastPenPositions includes: aSprite) ifTrue: [
		lastPenPositions at: aSprite put: aSprite penPosition].
! !

!ScratchStageMorph methodsFor: 'accessing' stamp: 'tis 12/11/2006 10:27'!
updateSpritesList
	"Populate the sprites list, which keeps track of the ordering of the sprite thumbnails"

	| frame |
	frame _ self ownerThatIsA: ScratchFrameMorph.
	frame ifNil: [^ self].
	sprites _ OrderedCollection new.
	frame libraryPane spriteThumbnails do: [:m | m target ifNotNil: [sprites addLast: m target]].
! !

!ScratchStageMorph methodsFor: 'drawing' stamp: 'jm 1/3/2006 22:23'!
updateStageDisplay
	"Redraw the damaged areas of this stage directly onto the display. Assumes that no other morph is in front of me."

	| root damageList |
	root _ owner.
	[root owner notNil] whileTrue: [root _ root owner].
	(root respondsTo: #damageRecorder) ifFalse: [^ self].

	damageList _ root damageRecorder filteredDamageWithin: self bounds.
	damageList size > 0 ifTrue: [self incrRedraw: damageList].
! !

!ScratchStageMorph methodsFor: 'pen support' stamp: 'jm 2/5/2005 11:33'!
updateTrailsForm
	"Update the pen trails form using the current positions of all sprites with their pens down."
	"Details: The positions of all sprites with their pens down are recorded by my draw method. If the list from the last display update isn't empty, then trails are drawn from the old to the current positions of all such morphs on the pen trails form. The pen trails form is created on demand when the first pen is put down and removed (to save space) when the pen trails are cleared."

	| spritesToRemove m oldPoint newPoint |
	(lastPenPositions isNil or: [lastPenPositions size = 0]) ifTrue: [^ self].

	spritesToRemove _ OrderedCollection new.
	lastPenPositions associationsDo: [:assoc |
		m _ assoc key.
		(m penDown and: [m owner == self])
			ifTrue: [
				oldPoint _ assoc value.
				newPoint _ m penPosition.
				newPoint = oldPoint ifFalse: [
					self drawPenTrailFor: m from: oldPoint to: newPoint.
					assoc value: newPoint]]
			ifFalse: [spritesToRemove add: m]].

	"remove sprites that are not longer owned by me or whose pens are up"
	spritesToRemove do: [:key | lastPenPositions removeKey: key ifAbsent: []].
! !

!ScratchStageMorph methodsFor: 'byob' stamp: 'jens 2/22/2011 00:05'!
userSelectSpriteDefault: defaultSprite butNotAnyOf: excludeArray

	| menu current |
	menu _ CustomMenu new.
	(defaultSprite isKindOf: ScratchSpriteMorph)
		ifTrue: [current _ defaultSprite objName]
		ifFalse: [current _ 'none'].
	menu title: 'current parent: ', current.
	sprites do: [:each |
		(excludeArray includes: each) ifFalse: [
			menu add: each objName action: each]].
	menu addLine.
	menu add: 'none' action: #null.
	^ menu startUp: #null
! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScratchStageMorph class
	instanceVariableNames: ''!

!ScratchStageMorph class methodsFor: 'block specs' stamp: 'jens 3/21/2011 00:38'!
blockSpecs

	| blocks |
	blocks _ #(
		'sensing'
			('ask %s and wait'			s	doAsk 'What''s your name?')
			('answer'					r	answer)
			-
			('mouse x'					r	mouseX)
			('mouse y'					r	mouseY)
			('mouse down?'				b	mousePressed)
			-
			('key %k pressed?'			b	keyPressed: 'space')
			-
			('reset timer'				-	timerReset)
			('timer'						r	timer)
			-
			('%a of %m'					r	getAttribute:of:)
"			('get %a of %m'				r	attribute:of:)"
			-
			('loudness'					r	soundLevel)
			('loud?'						b	isLoud)
			~
			('%H sensor value'			r	sensor: 'slider')
			('sensor %h?'				b	sensorPressed: 'button pressed')
			=
			('object %m'						r	getObject:)
			('attribute %a'						r	get:)

		'looks'
			('switch to background %l'	-	showBackground: 'background1')
			('next background'			-	nextBackground)
			('background #'				r	backgroundIndex)
			-
			('change %g effect by %n'	-	changeGraphicEffect:by: 'color' 25)
			('set %g effect to %n'		-	setGraphicEffect:to: 'color' 0)
			('clear graphic effects'		-	filterReset)
			-
"xxx			('place sprites for scene %x'	-	showScene:) "
		'pen'
			('clear'						-	clearPenTrails)
	).

	^ blocks, super blockSpecs
! !
