DividedImageFrameMorph subclass: #ScratchViewerMorph
	instanceVariableNames: 'target pageViewer currentCategory catButtonsExtent '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Scratch-UI-Panes'!
!ScratchViewerMorph commentStamp: 'jm 2/27/2005 19:49' prior: 0!
I am a Scratch blocks palette viewer. I have a set of ToggleButtons that allow selection of a blocks category to view and a scrollable area showing the blocks in the currently selected category.
!


!ScratchViewerMorph methodsFor: 'initialization' stamp: 'JM 11/24/2011 11:03'!
initialize

	super initialize.
	self
		initFrontFromForm: (ScratchFrameMorph skinAt: #blocksPaletteFrameTransparent2)
		topSectionHeight: 120.
	self middleBarLeftMargin: 5 rightMargin: 0.
	color _ (Color r: 0.584 g: 0.603 b: 0.623).
	pageViewer _ ScrollFrameMorph2 new growthFraction: 0.1.
	self addMorphBack: (pageViewer position: self position + (0@120)).
	self target: nil.
	self extent: 214@500.
! !

!ScratchViewerMorph methodsFor: 'initialization' stamp: 'JM 11/24/2011 11:05'!
rebuildCategorySelectors

	| catList maxExtent buttons label offForm onForm overForm b pad leftColumnX rightColumnX x y |
	catList _ #(
		motion		control
		looks		sensing
		sound		operators
		pen			variables
		shapes	).

	"First, delete the old category buttons"
	submorphs do: [:m | (m isKindOf: ResizableToggleButton2) ifTrue: [m delete]].

	"Create new buttons, keeping track of the maximum extent."
	maxExtent _ 75@0.
	buttons _ catList collect: [:cat |
		label _ (ScratchTranslator translationFor: cat asString) capitalized.
		offForm _ (ScratchFrameMorph skinAt: cat).
		onForm _ (ScratchFrameMorph skinAt: (cat, 'Pressed')).
		overForm _ (ScratchFrameMorph skinAt: (cat, 'Over')).
		ScratchTranslator isRTL
			ifTrue:[
				b _ ResizableToggleButton2 new
					offForm:	(offForm flipBy: #horizontal centerAt: offForm center)
					onForm:		(onForm flipBy: #horizontal centerAt: onForm center)
					overForm:	(overForm flipBy: #horizontal centerAt: overForm center)]
			ifFalse:[
				b _ ResizableToggleButton2 new
					offForm:	offForm
					onForm:		onForm
					overForm:	overForm].
		b
			label: label font: (ScratchFrameMorph getFont: #Category);
			setLabelColor: Color white;
			target: self;
			actionSelector: #currentCategory:;
			arguments: (Array with: cat);
			toggleButtonMode: true;
			toggleMode: false.
		ScratchTranslator isRTL
			ifTrue:[b rightJustifyInset: 10]
			ifFalse:[b leftJustifyInset: 10].
		maxExtent _ maxExtent max: (b extent + (3 @ -6)).
		b].

	"calculate catButtonsExtent"
	pad _ 15. "padding on left, right, and betwen the button columns"
	catButtonsExtent _ ((2 * maxExtent x) + (3 * pad)) @ (((catList size // 2 + 1) * (maxExtent y + 6)) + 25).

	"place the buttons"
	leftColumnX _ self left + 12 + pad.
	rightColumnX _ leftColumnX + maxExtent x + pad.
	x _ leftColumnX.
	y _ self top + 17.
	1 to: buttons size do: [:i |
		b _ buttons at: i.
		b extent: maxExtent.
		self addMorph: (b position: x@y).
		i even
			ifTrue: [x _ leftColumnX. y _ y + b height + 6]
			ifFalse: [x _ rightColumnX]].

	self width: catButtonsExtent x.
	pageViewer position: self position + (0@catButtonsExtent y).
	topSectionHeight _ catButtonsExtent y - 4.
! !


!ScratchViewerMorph methodsFor: 'accessing' stamp: 'nb 1/24/2008 17:35'!
catButtonsExtent

	^ catButtonsExtent
! !

!ScratchViewerMorph methodsFor: 'accessing' stamp: 'jm 6/29/2004 14:20'!
categoryChanged: aString
	"The given category has changed (e.g., due to a variable or script add/remove). If it's the current category, update my contents. Otherwise, do nothing."

	self target ifNil: [^ self].
	currentCategory = aString ifTrue: [self updateContents].
! !

!ScratchViewerMorph methodsFor: 'accessing' stamp: 'jm 2/27/2005 19:04'!
currentCategory

	^ currentCategory
! !

!ScratchViewerMorph methodsFor: 'accessing' stamp: 'TIS 7/10/2006 11:17'!
currentCategory: aString

	World activeHand newKeyboardFocus: nil.
	currentCategory _ aString.
	self lightUpSelectorForCurrentCategory.
	self updateContents.
! !

!ScratchViewerMorph methodsFor: 'accessing' stamp: 'TIS 7/7/2006 13:33'!
pageViewer

	^ pageViewer
! !

!ScratchViewerMorph methodsFor: 'accessing' stamp: 'jm 1/28/2009 10:42'!
refresh
	"Refresh the palette for the current category."

	self currentCategory: currentCategory.
! !

!ScratchViewerMorph methodsFor: 'accessing' stamp: 'jm 5/11/2004 19:36'!
target

	^ target
! !

!ScratchViewerMorph methodsFor: 'accessing' stamp: 'jm 2/27/2005 19:28'!
target: aScratchObject
	"Start viewing the given object, if not object, return an empty viewer."

	| categories |
	target _ aScratchObject.
	aScratchObject ifNil: [
		^ self currentCategory: 'none'].

	"keep the same category selected if possible"
	categories _ target blockCategories.
	(categories includes: currentCategory)
		ifTrue: [self currentCategory: currentCategory]
		ifFalse: [self currentCategory: categories first].

	self isInWorld ifTrue: [self world startSteppingSubmorphsOf: self].
! !


!ScratchViewerMorph methodsFor: 'drawing' stamp: 'jm 10/28/2008 13:07'!
drawBackgroundOn: aCanvas
	"Draw my background."

	color isTransparent ifTrue: [^ self].

	aCanvas
		fillRectangle: (self topLeft extent: (self width @ catButtonsExtent y))
		color: color.
! !


!ScratchViewerMorph methodsFor: 'geometry' stamp: 'jm 2/27/2005 19:36'!
extent: aPoint

	super extent: aPoint.
	pageViewer ifNotNil: [pageViewer extent: self extent - (pageViewer position - self position)].
! !


!ScratchViewerMorph methodsFor: 'private' stamp: 'nb 1/14/2008 20:45'!
lightUpSelectorForCurrentCategory

	submorphs do: [:m |
		(m isKindOf: ResizableToggleButton2) ifTrue: [
			m arguments first = currentCategory
				ifTrue: [m on]
				ifFalse: [m off]]].
! !

!ScratchViewerMorph methodsFor: 'private' stamp: 'jm 4/14/2008 17:52'!
updateContents

	| p |
	self target ifNil: [
		pageViewer contents: (Morph new color: ScratchFrameMorph palettePaneColor).
		^ self].

	p _ self target viewerPageForCategory: currentCategory.
	p color: ScratchFrameMorph palettePaneColor.

	pageViewer contents: p.
	self isInWorld ifTrue: [self world startSteppingSubmorphsOf: p].
	p fixLayout.
	ScratchTranslator isRTL
		ifTrue: [pageViewer hScrollPixels: (p right)].
! !
