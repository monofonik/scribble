ArgMorph subclass: #SpriteArgMorph
	instanceVariableNames: 'menuIconMorph morph '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Scratch-Blocks'!
!SpriteArgMorph commentStamp: '<historical>' prior: 0!
I represent a scriptable scratch morph argument for a command block.  Clicking on me and then another point on the screen allows the user to set my value to the scriptable scratch morph that has been clicked on.!


!SpriteArgMorph methodsFor: 'initialize' stamp: 'jm 7/9/2008 23:29'!
initialize

	super initialize.
	self borderInset.
	self borderWidth: 1.
	self color: Color white.

	labelMorph _ StringMorph new
		font: (ScratchFrameMorph getFont: #Arg);
		forceUnicodeRendering: true;
		color: Color white.
	self addMorph: labelMorph.
	((labelMorph extent y) > 15)
		ifTrue: [ self extent: 20@((labelMorph extent y) + 3) ]
		ifFalse: [ self extent: 20@15 ].
	menuIconMorph _ ImageMorph new form: DropDownMenuForm.
	self addMorphFront: menuIconMorph.

	morph _ nil.
	self updateLabel.
! !


!SpriteArgMorph methodsFor: 'event handling' stamp: 'jens 4/19/2011 16:40'!
fixGetAttribueBlock
	"If my owner is a get attribute block, make sure that the attribute is consistent the the type of the target sprite or stage."

	| attributeArg possibleAttributes |
	morph = #null ifTrue: [^ self].
	morph ifNil: [^ self].
	((owner isKindOf: ReporterBlockMorph) and: [owner selector = #getAttribute:of:]) ifFalse: [^ self].

	attributeArg _ owner submorphs detect: [:m | m isKindOf: AttributeArgMorph] ifNone: [^ self].

	possibleAttributes _ morph attributeNames, morph varNames.
	(possibleAttributes includes: attributeArg choice) ifFalse: [
		 attributeArg choice: possibleAttributes first].
! !

!SpriteArgMorph methodsFor: 'event handling' stamp: 'jm 1/23/2007 12:33'!
handlesMouseDown: evt

	^ evt hand toolType isNil and:
		[(self topRight - (14@0) corner: self bottomRight) containsPoint: evt cursorPoint]
! !

!SpriteArgMorph methodsFor: 'event handling' stamp: 'jm 12/13/2006 21:28'!
mouseDown: evt

	self presentMenu.
! !

!SpriteArgMorph methodsFor: 'event handling' stamp: 'JM 11/22/2011 15:24'!
presentMenu
	"Let the user select a Scratch object or the special value #mouse."

	| frame sel objList menu choice be |

	(frame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [
		be _ self ownerThatIsA: BlockEditorFrameMorph.
		be ifNil: [^self].
		(frame _ be scratchFrame) ifNil: [^ self]].

	(owner isKindOf: CommandBlockMorph) ifTrue: [sel _ owner selector].

	objList _ frame scratchObjects.
	objList sort: [:obj1 :obj2 | obj1 objName asLowercase < obj2 objName asLowercase].

	menu _ CustomMenu new.

	menu add: '' action: #null.

	(#(getAttribute:of: getObject: attribute:of:) includes: sel) ifTrue: [
		menu add: ('Canvas' localized) asMacRoman action: frame workPane].

	(#(stickTo:) includes: sel) ifTrue: [
		menu add: ('nothing' localized) asMacRoman action: #nothing].

	(#("getAttribute:of:" attribute:of: getObject: getSpawnOf: deleteSprite:) includes: sel) ifTrue: [
		menu add: ('myself' localized) asMacRoman action: #myself].

	(#(getObject: ) includes: sel) ifTrue: [
		menu add: ('all sprites' localized) asMacRoman action: #allSprites].

" --- on second thought I moved the following options to the ArgMorph's menu ----------------------

	relatives _ OrderedCollection new.
	#getObject: = sel ifTrue: [
		relatives add: 'my name'].
	relatives
		add: 'my prototype';
		add: 'my owner'.
	#getObject: = sel ifTrue: [
		relatives add: 'my parts'].
	menu addLine.
	relatives do: [:sym | menu add: sym action: sym].
 ----------------------------------------------------------------------------------------------------------------- "

	(#(getAttribute:of: getObject: getSpawnOf: deleteSprite: attribute:of: stickTo: deleteObject:) includes: sel)
		ifFalse: [
			menu add: 'mouse-pointer' localized asUTF8 action: #mouse.
			sel = #touching: ifTrue: [menu add: 'edge' localized asUTF8 action: #edge].
			objList _ objList copyWithout: owner receiver].

	objList size > 0 ifTrue: [menu addLine].
	objList do: [:obj | menu add: obj objName action: obj].

	(choice _ menu startUp) ifNil: [^ self].
	morph _ choice.
	self fixGetAttribueBlock.
	self updateLabel.
! !

!SpriteArgMorph methodsFor: 'event handling' stamp: 'jm 12/14/2004 11:55'!
wantsKeyboardFocusFor: aSubmorph
	"Don't allow shift-click editing of block labels."

	^ false
! !


!SpriteArgMorph methodsFor: 'stepping' stamp: 'jm 9/5/2006 11:20'!
step

	self updateLabel.
! !

!SpriteArgMorph methodsFor: 'stepping' stamp: 'jm 12/9/2008 16:29'!
stepTime

	^ 500
! !

!SpriteArgMorph methodsFor: 'stepping' stamp: 'jens 4/19/2011 16:41'!
updateLabel
	"Update my label string."

	| s |
	self checkForDeletedMorph.
	s _ ' '.
	(morph isKindOf: ScriptableScratchMorph) ifTrue: [s _ morph objName].
	(morph isKindOf: String) ifTrue: [
		s _ morph localized.
		morph = #mouse ifTrue: [s _ 'mouse-pointer' localized].
		morph = #null ifTrue: [s _ '']].

	labelMorph contents = s ifFalse: [
		labelMorph contents: s.
		labelMorph position: self position + borderWidth + (3 @ -1).
		self extent: (labelMorph extent + (16@2) + borderWidth).
		menuIconMorph position: (self right - borderWidth - 10)@(self top + borderWidth + 4).
		(self owner isKindOf: BlockMorph) ifTrue: [
			self owner addLabel].
		(self ownerThatIsA: ScratchBlockPaletteMorph) ifNotNil: [
			(self ownerThatIsA: ScratchBlockPaletteMorph) fixLayout]].
! !


!SpriteArgMorph methodsFor: 'other' stamp: 'jm 3/27/2009 07:47'!
acceptsDroppedReporters

	^ true
! !

!SpriteArgMorph methodsFor: 'other' stamp: 'jm 3/27/2009 07:48'!
acceptsTypeOf: aBlockMorph
	"Answer true if I can accept a dropped reporter of the given type."

	aBlockMorph isReporter ifFalse: [^ false].
	^ aBlockMorph isBooleanReporter not
! !

!SpriteArgMorph methodsFor: 'other' stamp: 'jm 12/5/2007 14:37'!
checkForDeletedMorph
	"If I refer to a Sprite that has been deleted, nil out my morph field. Do nothing if my morph is a ScratchStageMorph"

	(morph isKindOf: Morph) ifFalse: [^ self].
	morph owner ifNotNil: [^ self].

	(morph isKindOf: ScratchStageMorph) ifTrue: [^ self].

	morph _ nil.  "nil out reference to deleted sprite"

! !

!SpriteArgMorph methodsFor: 'other' stamp: 'jm 12/10/2004 14:11'!
clearMorphReference
	"Clear my morph reference."

	(morph isKindOf: Morph) ifFalse: [^ self].
	morph _ nil.
	self updateLabel.
! !

!SpriteArgMorph methodsFor: 'other' stamp: 'jm 3/28/2005 15:14'!
defaultValue: aSpriteMorph

	morph _ aSpriteMorph.
! !

!SpriteArgMorph methodsFor: 'other' stamp: 'jens 4/19/2011 16:45'!
evaluate
	"Answer either nil, the symbols #mouse or #myself, or a Scratch sprite object."

	morph = #null ifTrue: [
		^ nil ].

	morph = #myself ifTrue: [
		^owner receiver ].

	morph = #allSprites ifTrue: [
		^owner receiver allSprites].

" ------------ moved to ArgMorph ---------------

	morph = 'my owner' ifTrue: [
		^owner receiver ownerSprite ].
	morph = 'my parts' ifTrue: [
		^ScratchListMorph on: owner receiver subsprites].
	morph = 'my prototype' ifTrue: [
		^owner receiver prototype ].
	morph = 'my name' ifTrue: [
		^owner receiver objName ].

--------------------------------------------------------"

	morph = #nothing ifTrue: [
		^nil ].
	self checkForDeletedMorph.
	^ morph
! !

!SpriteArgMorph methodsFor: 'other' stamp: 'jm 3/28/2005 17:03'!
fixArgLayout
	"Set my color to my owner's color."

	self color: (owner color mixed: 0.7 with: (Color gray: 0.3)).
! !

!SpriteArgMorph methodsFor: 'other' stamp: 'jens 4/19/2011 18:09'!
implicitValue: anObject

	implicitValue _ anObject.
	morph _ anObject! !

!SpriteArgMorph methodsFor: 'other' stamp: 'jm 3/14/2009 13:53'!
printArgOn: aStream
	"Print this argument morph on the given stream."

	aStream nextPutAll: 's['.
	aStream nextPutAll: self labelMorph contents.
	aStream nextPut: $].
! !


!SpriteArgMorph methodsFor: 'object i/o' stamp: 'jm 9/24/2003 18:34'!
fieldsVersion

	^ 1
! !

!SpriteArgMorph methodsFor: 'object i/o' stamp: 'jm 9/24/2003 18:35'!
initFieldsFrom: anObjStream version: classVersion

	super initFieldsFrom: anObjStream version: classVersion.
	self initFieldsNamed: #(
		morph
	) from: anObjStream.
! !

!SpriteArgMorph methodsFor: 'object i/o' stamp: 'jm 9/24/2003 18:39'!
storeFieldsOn: anObjStream

	super storeFieldsOn: anObjStream.
	self storeFieldsNamed: #(
		morph
	) on: anObjStream.
! !


!SpriteArgMorph methodsFor: 'BYOB' stamp: 'jens 4/19/2011 16:39'!
getChoice
	morph = #null 
		ifTrue: [^ #null].
	morph = #myself 
		ifTrue: [^ #myself].
	morph = #allSprites 
		ifTrue: [^ #allSprites].
	^ self evaluate! !

!SpriteArgMorph methodsFor: 'BYOB' stamp: 'jens 4/19/2011 16:42'!
isEmptySlot
	^morph = #null! !
