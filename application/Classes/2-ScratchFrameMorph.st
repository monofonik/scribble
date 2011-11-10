Morph subclass: #ScratchFrameMorph
	instanceVariableNames: 'blockEditors topPane viewerPane scriptsPane stageFrame workPane titlePane libraryPane menuPanel stageButtonsPanel readoutPane logoMorph projectTitleMorph flagButton pauseButton fillScreenFlag paintingInProgress projectDirectory projectName projectInfo author loginName loginPassword watcherPositions shuffledCostumeNames justSaved viewModeButtons viewMode lastViewMode viewModeButtonsPanel toolbarPanel lastWeDoPoll quitFlag '
	classVariableNames: 'AllowSharing Clipboard DefaultNotes DefaultSprite Fonts FontsXO IsXO ScratchServers ScratchSkin ScratchSkinXO ShareServer ShareServerPath SupportServer SupportServerPath TakeOverScreen UseErrorCatcher Version VersionDate VisibleDrives WorkpaneExtent '
	poolDictionaries: ''
	category: 'Scratch-UI-Panes'!
!ScratchFrameMorph commentStamp: 'jm 7/20/2003 14:21' prior: 0!
I am the top level user interface for Scratch. I tile the screen with a toolbar, a work pane (for content), a viewer pane, and a script editor pane. I can resize myself to fill the entire Squeak window.

I keep a list of Scratch processes (threads) and run each one to the its next stopping point when I am stepped each screen update cycle.
!


!ScratchFrameMorph methodsFor: 'intialization' stamp: 'ee 1/27/2009 16:44'!
createBasicPanes
	"Create and add my palette (viewer), script editor, stage, and library panes."

	topPane _ ImageFrameMorph new initFromForm: (ScratchFrameMorph skinAt: 'topPane').
	viewerPane _ ScratchViewerMorph new rebuildCategorySelectors.	
	scriptsPane _ ScratchScriptEditorMorph new.
	stageFrame _ ImageFrameMorph new initFromForm: (ScratchFrameMorph skinAt: 'stagePane').
	titlePane _ ImageFrameMorph new initFromForm: (ScratchFrameMorph skinAt: 'titlePane').
	workPane _ ScratchStageMorph new extent: WorkpaneExtent.
	libraryPane _ ScratchLibraryMorph new.

	"make panes sticky so clicking on them doesn't pick up entire frame"
	self
		addMorph: (topPane isSticky: true);
		addMorph: (viewerPane isSticky: true);
		addMorph: (scriptsPane isSticky: true);
		addMorph: (stageFrame isSticky: true);
		addMorph: (workPane isSticky: true);
		addMorph: (titlePane isSticky: true);
		addMorph: (libraryPane isSticky: true).

	self createReadoutPane.
	workPane comeToFront.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'ee 1/27/2009 13:21'!
createLogo
	"Create and the Scratch logo."

	logoMorph _ SketchMorph withForm: (ScratchFrameMorph skinAt: #scratchLogo).
	logoMorph position: topPane position + (12@8).
	topPane addMorph: logoMorph.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jens 8/16/2009 23:46'!
createMenuPanel
	"Create and add a panel containing the menus and close button."

	| menuSpecs m |
	"create panel"
	menuPanel _ AlignmentMorph new
		color: Color transparent;
		centering: #center;
		inset: 0;
		height: 0.	"will grow as needed"

	self addShortcutButtonsTo: menuPanel.

	"menuSpecs defines the menus"
	menuSpecs _ #(
		"name			selector"
		(File			fileMenu:)
		(Edit			editMenu:)
		(Share			shareMenu:)
		(Help			helpMenu:)
	).

	menuSpecs do: [:spec |
		m _ ScratchMenuTitleMorph new
			contents: (spec at: 1) localized;
			target: self selector: (spec at: 2).
		menuPanel addMorphBack: m.
		#helpMenu: = (spec at: 2) ifFalse: [
			menuPanel addMorphBack: (Morph new color: Color transparent; extent: 12@5)]].

	topPane addMorph: menuPanel.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'ee 1/29/2009 14:21'!
createReadoutPane
	"Create and add my presentation mode button, new sprite buttongs, and mouse readout pane."

	| xyReadout |

	readoutPane _ ImageFrameMorph new initFromForm: (ScratchFrameMorph skinAt: #mouseReadoutPane).
	xyReadout _ self makeXYReadout.
	readoutPane	 addMorph: xyReadout.

	"make pane sticky so clicking on it doesn't pick up entire frame"
	self addMorph: (readoutPane isSticky: true).
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jens 5/19/2010 03:35'!
createStageButtonsPanel
	"Create and add a panel containing the project title, green flag, and stop buttons."

	| buttonSpecs bName button |
	"create panel"
	stageButtonsPanel _ AlignmentMorph new
		color: Color transparent;
		centering: #center;
		height: 20.

	projectTitleMorph _ StringMorph new
		forceUnicodeRendering: true;
		contents: '';
		font: (ScratchFrameMorph getFont: #FrameMorphProjectTitle).
	stageButtonsPanel
		addMorphBack: projectTitleMorph;
		addMorphBack: (AlignmentMorph newSpacer: Color transparent).

	"buttonSpecs defines the toolbar buttons; first is icon name, second is selector"
	buttonSpecs _ #(
		"name	selector		tool tip"
		(go		shoutGo		'Start green flag scripts')
		(pause	togglePause	'Pause/resume everything')
		(stop	stopAll		'Stop everything')).

	buttonSpecs do: [:spec |
		bName _ spec first.
		button _ ToggleButton
			onForm: (ScratchFrameMorph skinAt: (bName, 'ButtonGrayPressed') asSymbol)
			offForm: (ScratchFrameMorph skinAt: (bName, 'ButtonGray') asSymbol)
			overForm: (ScratchFrameMorph skinAt: (bName, 'ButtonGrayPressed') asSymbol).
		button
			target: self;
			actionSelector: (spec at: 2);
			isMomentary: true;
			setProperty: #balloonText toValue: (spec at: 3) localized.

		stageButtonsPanel addMorphBack: button.
		bName = #pause ifTrue: [
			pauseButton _ button].

		bName = #go ifTrue: [
			flagButton _ button.
			"stageButtonsPanel addMorphBack: (Morph new color: Color transparent; extent: 2@5)" "commented out if there is a pause button -jens" ]].

	titlePane addMorph: stageButtonsPanel.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jm 4/14/2009 08:59'!
createToolbar
	"Create and add the toolbar."

	| buttonSpecs bName button |
	toolbarPanel _ AlignmentMorph new
		hResizing: #shrinkWrap;
		vResizing: #shrinkWrap;
		color: Color transparent.
		
	buttonSpecs _ #(
		"name			selector"			"tooltip"
		(copy			copyTool		'Duplicate')
		(delete			cutTool			'Delete')
		(zoomIn 		zoomInTool		'Grow sprite')
		(zoomOut 		zoomOutTool		'Shrink sprite')
	).

	buttonSpecs do: [:spec |
		bName _ spec at: 1.
		button _ ToggleButton
			onForm: (ScratchFrameMorph skinAt: (bName, 'ButtonPressed') asSymbol)
			offForm: (ScratchFrameMorph skinAt: (bName, 'Button') asSymbol)
			overForm: (ScratchFrameMorph skinAt: (bName, 'ButtonOver') asSymbol).
		button
			target: self;
			actionSelector: (spec at: 2);
			isMomentary: true;
			setProperty: #balloonText toValue: (spec at: 3) localized.
		toolbarPanel addMorphBack: button].

	self addMorph: toolbarPanel.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jm 4/14/2009 08:57'!
createViewModeButtonsPanel

	| specs bName button |
	viewModeButtonsPanel _ AlignmentMorph newRow
		hResizing: #shrinkWrap;
		vResizing: #shrinkWrap;
		color: Color transparent.

	viewModeButtons _ OrderedCollection new.
	specs _ OrderedCollection new.
	specs add: #(quarter			enterQuarterMode		'Switch to small stage').
	specs add: #(normal			enterNormalMode		'Switch to full stage').
	specs add: #(presentation	enterPresentationMode	'Switch to presentation mode').

	specs do: [:spec |
		bName _ spec first.
		button _ ToggleButton new
			onForm: (ScratchFrameMorph skinAt: bName, 'ViewModeOn')
			offForm: (ScratchFrameMorph skinAt: bName, 'ViewMode')
			overForm: (ScratchFrameMorph skinAt: bName, 'ViewModeOver').
		button
			target: self;
			actionSelector: (spec at: 2);
			alphaOn: true;
			setProperty: #balloonText toValue: (spec at: 3) localized.
		viewModeButtonsPanel
			addMorphBack: button;
			addMorphBack: (Morph new extent: 1@5; color: Color transparent).
		viewModeButtons add: button].

	self addMorph: viewModeButtonsPanel.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jens 6/10/2010 21:17'!
initialize

	super initialize.
	fillScreenFlag _ false.
	paintingInProgress _ false.
	projectInfo _ Dictionary new.
	watcherPositions _ Dictionary new.
	justSaved _ false.
	quitFlag _ false.
	blockEditors _ Set new.
	author _ ''.
	loginName _ ''.
	loginPassword _ ''.
	viewMode _ #normal.

	self createBasicPanes.
	self createLogo.
	self createMenuPanel.
	self createViewModeButtonsPanel.
	self createStageButtonsPanel.
	self createToolbar.

	self extent: 1000@600.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jm 5/4/2009 11:15'!
makeXYReadout
	"Make and answer an x-y readout."

	| normalFont boldFont panel spaceWidth labelX readoutX labelY readoutY |
	normalFont _ (ScratchFrameMorph getFont: #XYReadout).
	boldFont _ (ScratchFrameMorph getFont: #XYReadoutBold).

	(ScratchTranslator renderScale ~= 1) ifTrue: [
		"force fonts to be fixed size:"
		normalFont _ StrikeFont
			osFontName: normalFont name
			size: normalFont pointSize / ScratchTranslator renderScale asFloat.
		boldFont _ StrikeFont
			osFontName: boldFont name
			size: boldFont pointSize / ScratchTranslator renderScale asFloat].

	panel _ Morph new color: (Color r: 0.753 g: 0.764 b: 0.776).

	ScratchTranslator isRTL
		ifTrue: [labelX _ StringMorph new font: normalFont; contents: ':x' asUTF8]
		ifFalse: [labelX _ StringMorph new font: normalFont; contents: 'x:' asUTF8].
	readoutX _ UpdatingStringMorph new
		target: self; getSelector: #mouseX;
		forceUnicodeRendering: true;
		font: boldFont;
		stepTime: 150;
		growable: false.
	readoutX width: (readoutX stringWidth: '-1000').
	ScratchTranslator isRTL
		ifTrue: [labelY _ labelX fullCopy contents: ':y' asUTF8]
		ifFalse: [labelY _ labelX fullCopy contents: 'y:' asUTF8].
	readoutY _ readoutX fullCopy getSelector: #mouseY.

	spaceWidth _ ((readoutX stringWidth: ' ') * 0.8) asInteger.

	ScratchTranslator isRTL
		ifTrue: [readoutY rightJustify: true.
			panel addMorph: (readoutY position: 0@0).
			panel addMorph: (labelY position: ((readoutY topRight) + (spaceWidth@0))).]
		ifFalse: [panel addMorph: (labelX position: 0@0).
			panel addMorph: (readoutX position: ((labelX topRight) + (spaceWidth@0)))].

	ScratchTranslator isRTL
		ifTrue: [readoutX rightJustify: true.
			panel addMorph: (readoutX position: (labelY right@labelY top) + (spaceWidth@0)).
			panel addMorph: (labelX position: ((readoutX topRight) + (spaceWidth@0)))]
		ifFalse: [panel addMorph: (labelY position: (labelX right + readoutX width + 8)@(labelX top)).
			panel addMorph: (readoutY position: ((labelY topRight) + (spaceWidth@0)))].
	
	ScratchTranslator isRTL
		ifTrue: [panel extent: ((labelX right) max: (labelY right))@(labelY bottom)]
		ifFalse: [panel extent: ((readoutX right) max: (readoutY right))@(labelY bottom)].

	^ panel
! !


!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:34'!
author

	^ author
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:35'!
author: aString
	"This is the author used in notes and save as, which is different from the user name used when uploading to the website."

	author _ aString.

! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jens 2/24/2011 20:13'!
editMenu: aMenuTitleMorph

	| menu onstage |

	"first create the widest label"
	onstage _ self checkBoxLabelled: 
				'Allow Sprites offstage' "localized asMacRoman"
				marked: ScriptableScratchMorph keepOnStage not
				width: 0.

	menu _ CustomMenu new.
	menu add: 'Undelete' action: #undoTool.
	menu add: 'Undo last drop' action: #undoLastDrop.

	menu addLine.

	menu addIcon: (self checkBoxLabelled: 'Turbo'
				marked: self isTurbo
				width: onstage width)
			toolTip: 'check to squeeze more computational steps into one display cycle'
			action: #toggleTurboMode.
"
	menu addIcon: (self checkBoxLabelled: 'Single Stepping'
				marked: (ScratchProcess blockHighlightMSecs <= 1) not
				width: onstage width)
			toolTip: nil
			action: #toggleSingleStepping.

	menu add: 'Set Single Stepping' action: #setSingleStepping.
	menu addLine.
"
	menu addIcon: onstage
			toolTip: 'check to allow sprites to move offscreen'
			action: #toggleKeepSpritesOnStage.

	menu addIcon: (self checkBoxLabelled: 'Thread safe scripts' 
				marked: EventHatMorph threadSafeMode 
				width: onstage width)
			toolTip: 'check to disallow script reentrancy'
			action: #toggleThreadSafeMode.

	menu addIcon: (self checkBoxLabelled: 'Zebra Coloring' 
				marked: BlockMorph contrast = #strong 
				width: onstage width)
			toolTip: 'check to alternate color contrast among nested reporters with the same color' localized asMacRoman
			action: #toggleZebraColoring.

	menu addIcon: (self checkBoxLabelled: 'Translucent Dragging'
				marked: HandMorph translucentWhenDragging 
				width: onstage width)
			toolTip: 'check to see through objects when they are dragged'
			action: #toggleTranslucentDragging.

	menu addIcon: (self checkBoxLabelled: 'Scope Contrast'
				marked: VariableFrame scopeContrast 
				width: onstage width)
			toolTip: 'check to contrast the color of lexically scoped blocks'
			action: #toggleScopeContrast.

	menu addLine.
	menu add: 'Compress Sounds' action: #compressSounds.
	menu add: 'Compress Images' action: #compressImages.
	menu add: 'Unload unused blocks' action: #unloadAllUnusedCustomBlocks.
	menu add: 'Clear all Variables' action: #clearAllVariables.

	menu addLine.

	menu addIcon: (self checkBoxLabelled: 'Show Motor Blocks'
				marked: workPane showMotorBlocks
				width: onstage width)
			toolTip: nil
			action: #toggleShowMotorBlocks.

	Sensor shiftPressed ifTrue: [	self isDevelopmentMode ifTrue: [
			menu addLine.
		fillScreenFlag
			ifTrue: [menu add: 'turn fill screen off' localized asMacRoman action: #fillScreenOff]
			ifFalse: [menu add: 'turn fill screen on' localized asMacRoman action: #fillScreenOn].
		UseErrorCatcher
			ifTrue: [menu add: 'turn error catching off' localized asMacRoman action: #toggleErrorCatcher]
			ifFalse: [menu add: 'turn error catching on' localized asMacRoman action: #toggleErrorCatcher].
		menu addLine.
		menu add: 'save image for end-user' localized asMacRoman action: #saveImageForEndUser]].
 
	menu localize.

	#(3 4 7 8) do: [:n |
		menu labels at: n put:
			((menu labels at: n) copyFrom: 1 to: (menu labels at: n) size - 1), ScratchTranslator ellipsesSuffix].

	menu invokeOn: self at: aMenuTitleMorph bottomLeft + (0@10).
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'tis 11/8/2006 13:34'!
libraryPane

	^ libraryPane
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:27'!
loginName

	^ loginName
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:30'!
loginName: aString

	loginName _ aString.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:27'!
loginPassword

	^ loginPassword
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:30'!
loginPassword: aString

	loginPassword _ aString.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 5/2/2005 17:22'!
paintingInProgress
	"Answer true if the paint editor is in use."

	^ paintingInProgress
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 5/2/2005 17:06'!
paintingInProgress: aBoolean

	paintingInProgress _ aBoolean.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 2/28/2009 14:29'!
projectComment

	^ projectInfo at: 'comment' ifAbsent: ['']
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/2/2009 12:56'!
projectCommentOrTemplate

	| s |
	s _ projectInfo at: 'comment' ifAbsent: [''].
	s size = 0 ifTrue: [s _ DefaultNotes].
	^ s
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 10/29/2005 10:26'!
projectInfo
	"Answer the project info dictionary."

	^ projectInfo
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'ee 6/2/2009 18:55'!
projectName

	^ self nameFromFileName: projectName
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 10/26/2008 17:44'!
projectName: aString

	projectName _ aString.
	projectTitleMorph contents: aString.
	self fixLayout.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 6/23/2004 09:54'!
scratchObjects
	"Answer a collection of all the scratch objects in the work pane."

	^ self workPane submorphs select: [:m | m isKindOf: ScriptableScratchMorph]
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 7/20/2003 12:13'!
scriptsPane

	^ scriptsPane
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'ee 12/30/2008 13:47'!
viewMode

	^ viewMode
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 7/20/2003 12:08'!
viewerPane

	^ viewerPane
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 7/20/2003 12:08'!
workPane

	^ workPane
! !


!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 2/7/2011 23:35'!
aboutScratch

	| dialogBox |
	dialogBox _ DialogBoxMorph new
		title: 'About BYOB';
		withButtonsForYes: false no: false okay: true cancel: false.
	dialogBox
		message: 'BYOB ', Version, '
Build Your Own Blocks - an extension to Scratch

Copyright 2011 Brian Harvey and Jens Moenig
bh@cs.berkeley.edu, jens@moenig.org
All rights reserved

Based on SCRATCH
Copyright (C)  2009 Massachusetts Institute of Technology.
All rights reserved.

Scratch is developed by the Lifelong Kindergarten Group at the MIT Media Lab,
with support from the National Science Foundation, Microsoft, Intel,
Nokia, and MIT Media Lab research consortia.

For more information, see http://byob.berkeley.edu
http://scratch.mit.edu and http://chirp.scratchr.org.
for license, see license.txt in folder.

Please report bugs to http://byobugs.com.
'
		font: (ScratchFrameMorph getFont: #AboutScratch).

	dialogBox setBalloonText: ((CommandBlockMorph new color: (ScriptableScratchMorph blockColorFor: 'control'); commandSpec: 'B Y %r B')) asLambda displayForm.

	dialogBox getUserResponse.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 8/13/2009 22:45'!
addServerCommandsTo: menu
	"Add Scratch server commands to the given menu."

	| disable endCmd |
	disable _ false.  "make this true to disable this feature"
	disable ifTrue: [^ self].

	menu addLine.
	(workPane scratchServer notNil and:
	 [workPane scratchServer sessionInProgress])
		ifTrue: [
			menu add: 'Show IP Address' action: #showNetworkAddress.
			endCmd _ workPane scratchServer isHosting
				ifTrue: ['Stop Hosting Mesh']
				ifFalse: ['Leave Mesh'].
			menu add: endCmd action: #exitScratchSession]
		ifFalse: [
			menu add: 'Host Mesh' action: #startHostingScratchSession.
			menu add: 'Join Mesh' action: #joinScratchSession].

! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 5/3/2010 02:36'!
addShortcutButtonsTo: rowMorph

	| buttonSpecs b |

	self class disableSharing.

	buttonSpecs _ #(
		"name		tool tip				selector"
		(language	'Set language'		languageMenu:)
		(save		'Save this project'	saveScratchProjectNoDialog)
"		(share		'Share this project'	share)"
	).
	AllowSharing ifFalse: [
		buttonSpecs _ buttonSpecs select: [:spec | spec first ~= #share]].

	buttonSpecs do: [:spec |
		b _ ToggleButton
			onForm: (ScratchFrameMorph skinAt: (spec at: 1), 'ButtonOver')
			offForm: (ScratchFrameMorph skinAt: (spec at: 1), 'Button')
			overForm: (ScratchFrameMorph skinAt: (spec at: 1), 'ButtonOver').
		b
			target: self;
			actionSelector: (spec at: 3);
			setBalloonText: (spec at: 2) localized;
			actWhen: #buttonUp;
			isMomentary: true.
		
		('language' = (spec at: 1)) ifTrue: [  "language special case"
			b arguments: (Array with: b)].

		('save' = (spec at: 1)) ifTrue: [  "bigger spacer"
			rowMorph addMorphBack: (Morph new extent: (10@5); color: Color transparent)].

		('share' = (spec at: 1)) ifTrue: [  "add spacer between buttons"
			rowMorph addMorphBack: (Morph new extent: (8@5); color: Color transparent)].
		rowMorph addMorphBack: b].

	rowMorph addMorphBack: (Morph new extent: (15@5); color: Color transparent).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 5/3/2010 22:29'!
addSpriteMorph

	| result f m el |
	self world activeHand toolType: nil.
	self paintingInProgress ifTrue: [^ self beep].

	result _ ScratchFileChooserDialog chooseSpriteCostumeFor: self.
	result = #cancelled ifTrue: [^ self].
	((result asLowercase endsWith: '.sprite') | (result asLowercase endsWith: '.ysp'))
		ifTrue: [^ self importSpriteOrProject: result].

	[f _ Form fromFileNamed: result] ifError: [^ self].
	el _ ImageMedia new form: (ScratchFrameMorph scaledFormForPaintEditor: f).
	m _ ScratchSpriteMorph new soleCostume: el.
	el mediaName: (m unusedMediaNameFromBaseName: (FileDirectory localNameFor: result)).
	self addAndView: m.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/16/2007 19:12'!
allProjectMedia
	"Answer a collection of all media items in the current project."

	| result |
	result _ OrderedCollection new.
	(workPane submorphs copyWith: workPane) do: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			result addAll: m media]].
	^ result
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/17/2007 12:29'!
canonicalizeImagesQuality: qualityOrNil saveOriginal: saveFlag

	| count unique match |
	count _ 0.
	unique _ OrderedCollection new: 1000.
	self allProjectMedia do: [:m |
		m isImage ifTrue: [
			match _ unique detect: [:u | u form equals: m form] ifNone: [nil].
			match
				ifNil: [
					qualityOrNil ifNotNil: [
						(m jpegCompressIfPossibleQuality: qualityOrNil saveOriginal: saveFlag)
							ifTrue: [count _ count + 1]].
					unique add: m]
				ifNotNil: [
					m shareFormWith: match]]].
	^ count
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/17/2007 13:47'!
canonicalizeSoundsBits: bitsPerSample saveOriginal: saveFlag

	| count unique match |
	count _ 0.
	unique _ OrderedCollection new: 1000.
	self allProjectMedia do: [:m |
		m isSound ifTrue: [
			match _ unique detect: [:u | u sound equals: m sound] ifNone: [nil].
			match
				ifNil: [
					bitsPerSample ifNotNil: [
						(m compressBitsPerSample: bitsPerSample saveOriginal: saveFlag)
							ifTrue: [count _ count + 1]].
					unique add: m]
				ifNotNil: [
					m shareSoundWith: match]]].

	bitsPerSample notNil & saveFlag not ifTrue: [
		"uncompress compressed sounds so the result can be heard"
		self allProjectMedia do: [:m | m isSound ifTrue: [ m decompress]]].

	^ count
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 7/9/2008 18:19'!
compressImages

	| s q count |
	s _ StringDialog askWithCancel: 'JPEG Quality (10-100)?' initialAnswer: '70'.
	s size = 0 ifTrue: [^ self].
	q _ [s asNumber] ifError: [nil].
	q ifNil: [^ self].
	q _ (q within: 10 and: 101) truncated.

	q > 100 ifTrue: [q _ nil].  "just canonicalize, don't compress"
	count _ self canonicalizeImagesQuality: q saveOriginal: false.

	scriptsPane categoryChanged: 'Costumes'.
	DialogBoxMorph inform: 'Images compressed' withDetails: count printString.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 8/8/2008 13:16'!
compressSounds

	| menu bitsPerSample count |
	menu _ CustomMenu new title: 'Sound quality:'.
	menu add: 'High (biggest)' action: 5.
	menu add: 'Normal' action: 4.
	menu add: 'Low' action: 3.
	menu add: 'Lowest (smallest)' action: 2.
	menu addLine.
	menu add: 'cancel' action: nil.
	menu localize.
	(bitsPerSample _ menu startUp) ifNil: [^ self].

	count _ self canonicalizeSoundsBits: bitsPerSample saveOriginal: false.
	scriptsPane categoryChanged: 'Sounds'.
	DialogBoxMorph inform: 'Sounds compressed' withDetails: count printString.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/11/2006 17:56'!
editNotes

	(ScratchNotesDialog editNotesFor: self) getUserResponse.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 8/26/2008 11:50'!
enableRemoteSensors
	"Start running the Scratch server, allowing Scratch and other applications to interact with this Scratch remotely."

	| server |
	workPane scratchServer ifNil: [
		server _ ScratchServer new userName: 'Scratch'.
		server stage: workPane.
		workPane scratchServer: server].

	workPane scratchServer startHosting.
	DialogBoxMorph inform: 'Remote sensor connections enabled' localized.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 2/27/2009 09:04'!
exitScratchSession
	"Close all connections to remote collaborators."

	workPane scratchServer ifNil: [^ self].
	workPane scratchServer endScratchSession.
	workPane scratchServer: nil.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/28/2008 14:53'!
exportSprite

	scriptsPane target exportObject.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 4/14/2009 09:56'!
fillScreenOff
	"Stop filling the entire screen. Useful during development."


	Smalltalk fullScreenMode: false.
	World restoreDisplay.

	fillScreenFlag _ false.
	self isSticky: false.
	self extent: Display extent - 50.
	UseErrorCatcher _ false.
	Preferences disable: #noviceMode.
	Preferences enable: #warnIfNoSourcesFile.
	Preferences enable: #warnIfNoChangesFile.
	Preferences insertionPointColor: (Color r: 0.4 g: 1.0 b: 0.0).
	Preferences textHighlightColor: (Color r: 0.4 g: 1.0 b: 0.0).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 4/14/2009 09:55'!
fillScreenOn
	"Start filling the entire screen and being sticky. Also configure a few other things for the end user such as turning off halos and the control menu (noviceMode) and making sure that error catching is enabled."

	TakeOverScreen ifTrue: [
		Smalltalk fullScreenMode: true.
		World restoreDisplay].

	fillScreenFlag _ true.
	self position: 0@0.
	self isSticky: true.
	self comeToFront.
	UseErrorCatcher _ true.
	Sensor useOSEvents: true.
	Preferences enable: #noviceMode.
	Preferences disable: #warnIfNoSourcesFile.
	Preferences disable: #warnIfNoChangesFile.
	Preferences insertionPointColor: (Color r: 0.353 g: 0.607 b: 0.788).
	Preferences textHighlightColor: (Color r: 0.353 g: 0.607 b: 0.788).
	self updateProjectName.
	self step.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/13/2009 14:37'!
getLoginName
	"Ask the user for their name name and record their answer in 'loginName'."

	| s |
	s _ StringDialog
		askWithCancel: 'User name:'
		initialAnswer: loginName.
	s size = 0 ifTrue: [^ ''].
	loginName _ s.
	^ s
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 7/7/2010 03:21'!
helpMenu: aMenuTitleMorph

	| menu |
	menu _ CustomMenu new.
	menu add: 'BYOB Reference Manual' action: #openBYOBManual.
	menu add: 'BYOB Website' action: #launchWebsite.
	menu addLine.
	menu add: 'Scratch Help Page' action: #launchHelpPage.
	menu add: 'Help Screens' action: #launchAllHelpScreens.
	menu addLine.
	menu add: 'About BYOB' action: #aboutScratch.

	menu localize.

	#(1 2 3 4 5) do: [:n |
		menu labels at: n put:
			((menu labels at: n) copyFrom: 1 to: (menu labels at: n) size - 1), ScratchTranslator ellipsesSuffix].

	menu invokeOn: self at: aMenuTitleMorph bottomLeft + (0@10).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 2/17/2009 11:33'!
hideMotorBlocks

	workPane showMotorBlocks: false.
	viewerPane refresh.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 6/30/2010 23:26'!
importSpriteOrProject: fileNameOrData
	"Read the sprite or project file and merge into the current project."

	| data f importedStage defaultForm defaultSound |

	data _ fileNameOrData.
	(data isKindOf: String) ifTrue: [  "read the contents of a local file"
		(FileDirectory default fileExists: fileNameOrData) ifFalse: [^ self].
		f _ (FileStream readOnlyFileNamed: fileNameOrData) binary.
		f ifNil: [^ self].
		data _ f contentsOfEntireFile].

	[importedStage _ self extractProjectFrom: data] ifError: [^ self].

	"fix references to old stage"
	importedStage allMorphsDo: [:m |
		(m isKindOf: WatcherMorph) ifTrue: [m mapReceiver: importedStage to: workPane].
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			m blocksBin submorphs do: [:stack |
				(stack isKindOf: BlockMorph) ifTrue: [
					stack blockSequence do: [:b | b mapReceiver: importedStage to: workPane]]]]].

	"add global variables from importated stage to my stage"
	importedStage varNames do: [:v |
		workPane addVariable: v value: (importedStage getVar: v)].
	importedStage varNames do: [:v | workPane addVariable: v].

	"add imported stage scripts"
	importedStage blocksBin submorphs do: [:stack |
		(stack isKindOf: BlockMorph) ifTrue: [workPane addStack: stack fullCopy]].

	"add imported background costumes and scripts to my stage, filtering out default items"
	defaultForm _ workPane defaultImageMedia form hibernate.
	defaultSound _ SoundMedia new sound.
	importedStage media do: [:media |
		(media isImage and: [media form hibernate bits ~= defaultForm bits])
			ifTrue: [workPane addMediaItem: media].
		(media isSound and: [media sound samples ~= defaultSound samples])
			ifTrue: [workPane addMediaItem: media]].

	"add imported global custom block definitions"
	importedStage customBlocks ifNotNil: [

		'installing globals...' 
			displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
			from: 0 to: importedStage customBlocks size
			during: [:bar | | i | i _ 0.

		importedStage customBlocks do: [:eachDef |
			i _ i + 1. bar value: i.
			workPane sprites, {workPane} do: [:obj |
				obj
					updateCustomBlockDefinitionId: eachDef id with: eachDef;
					updateLocalId: eachDef id withSpec: eachDef userSpec]]]].

	importedStage position: workPane position.

	importedStage submorphs do: [:m | 
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			"m objName: m  nextInstanceName".
			workPane addMorphFront: m.
			m startStepping.
			workPane sprites addLast: m.
			self view: m tab: 'Scripts' category: 'motion'.
			m refPos ifNotNil: [
				m referencePosition: m refPos + (50@-50) ]]].

	workPane layoutChanged.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/14/2009 08:11'!
joinScratchSession
	"Join another Scratch user or a Scratch-compatible remote application."

	| server addrString ok |
	server _ ScratchServer new.
	server stage: workPane.
	workPane scratchServer: server.

	addrString _ StringDialog askWithCancel: 'IP address:'.
	addrString size = 0 ifTrue: [^ self].

	ok _ workPane scratchServer joinSessionAt: addrString.
	ok ifFalse: [DialogBoxMorph warn: 'Could not connect to ', addrString].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 10/5/2010 00:01'!
languageMenu: aToggleButtonMorph
	"Present a menu of possible languages for blocks."

	| bullet menu choice |
	ScratchTranslator canRenderUnicode ifFalse: [
		"try to find a Unicode plugin in case this is the first use after startup"
		ScratchTranslator detectRenderPlugin].

"	bullet _ UTF8 withAll: '• '."
	bullet _ UTF8 withAll: '*'.
	menu _ CustomMenu new.
	ScratchTranslator languageNames do: [:lang |
		((ScratchTranslator isoCodeForName: lang) = (ScratchTranslator currentLanguage))
			ifTrue: [menu add: (bullet, ' ', lang asMacRoman, ' ', bullet) action: lang]
			ifFalse: [menu add: lang asMacRoman action: lang]].
	choice _ menu startUp: nil withCaption: nil at: aToggleButtonMorph bottomLeft + (0@10).

	choice ifNil: [^ self].
	self stopAll.
	self setLanguage: choice.
	self recordLanguage: (ScratchTranslator currentLanguage).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 2/23/2009 07:07'!
launchAllHelpScreens

	self launchHelpFile: 'allscreens.html'
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 4/16/2009 12:45'!
launchHelpFile: aFilename

	| helpDir subDir |
	(FileDirectory default directoryNames includes: 'Help') ifFalse: [^ self beep].  "no help folder"
	self stopAll.
	helpDir _ FileDirectory default directoryNamed: 'Help'.

	"use the English subfolder by default if it exists"
	(helpDir directoryNames includes: 'en') ifTrue: [subDir _ helpDir directoryNamed: 'en'].
	"use subfolder for the current language if it exists"
	(helpDir directoryNames includes: ScratchTranslator currentLanguage) ifTrue: [
		subDir _ helpDir directoryNamed: ScratchTranslator currentLanguage].
	subDir ifNotNil: [helpDir _ subDir].

	(helpDir fileExists: aFilename)
		ifTrue: [Smalltalk isMacOSX
			ifTrue: [ScratchPlugin primOpenURL: 'file://', (helpDir pathName, FileDirectory slash, aFilename) encodeForHTTP]
			ifFalse: [ScratchPlugin primOpenURL: helpDir pathName, FileDirectory slash, aFilename]]
		ifFalse: [
			DialogBoxMorph inform: 'Scratch help file not found.' localized].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 4/15/2009 11:55'!
launchHelpPage

	self launchHelpFile: 'index.html'.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 2/12/2009 16:45'!
launchScratchWebsite

	self world displayWorldSafely.
	Cursor wait showWhile: [ScratchPlugin primOpenURL: 'http://', ScratchFrameMorph shareServer].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 7/7/2010 03:18'!
launchWebsite

	self world displayWorldSafely.
	Cursor wait showWhile: [ScratchPlugin primOpenURL: 'http://byob.berkeley.edu'].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 12/8/2008 12:05'!
paintSpriteMorph

	| m |
	m _ ScratchSpriteMorph new soleCostume: ImageMedia new.
	self addAndView: m.
	m editDrawingOldCostumeName: m costume mediaName deleteOnCancel: true.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/27/2008 13:49'!
pressGreenFlagButton
	"Simulate pressing the green flag button when enter key is pressed."

	flagButton on.
	World displayWorld.
	Delay waitMSecs: 100.
	flagButton off.
	World displayWorld.
	self shoutGo.

! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/26/2009 20:48'!
quitScratch
	"Quit from Scratch. Ask the user if they want to save, first."

	| response |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	(justSaved or: [self projectIsEmpty]) ifFalse: [
		response _ ScratchCloseDialog new getUserResponse.
		response = #cancelled ifTrue: [^ self].
		response ifTrue: [
			self saveScratchProjectNoDialog.
			justSaved ifFalse: [^ self]]].

	Smalltalk snapshot: false andQuit: true.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 6/28/2008 08:48'!
renderingMenu

	ScratchTranslator renderingMenu.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 12/3/2007 21:34'!
resaveAllProjects
	"Resave all the projects in the given directory (to recompress them)."

	| dir |
	dir _ ScratchFileChooserDialog chooseFolder: FileDirectory default.
	dir = #cancelled ifTrue: [^ self].

	dir allFileNamesDo: [:fn |
		((fn asLowercase endsWith: '.sb') and:
		 [(fn endsWith: '-2.sb') not]) ifTrue: [
			self openScratchProjectNamed: fn.
			World doOneCycleNoInput.
"			projectName _ (fn copyFrom: 1 to: fn size - 3), '-3.sb'."
			self writeScratchProject]].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 6/9/2010 22:38'!
saveImageForEndUser

	(self confirm: '
Close non-Scratch windows and save this
image in end-user (fillScreen) mode?') ifFalse: [^ self].

	ScratchFrameMorph isXO ifTrue: [Preferences useLargeFonts].

	self setLanguage: 'en'.

	self enterNormalMode.
	self blockContrastStrong.
	ScriptableScratchMorph keepOnStage: true.
	self recordKeepOnStage: 1. 
	EventHatMorph threadSafeMode: false.
	self recordThreadSafeMode: 0.

	BlockLabelFragmentDialog isExpanded: false.

	World submorphs do: [:m |
		(m isKindOf: SystemWindow) ifTrue: [m delete]].
	self clearStage.

	Display newDepth: 32.
	self fillScreenOn.
	World doOneCycleNow.
	Smalltalk snapshot: true andQuit: true.
	self startup.
	Sensor useOSEvents: true.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 11/10/2007 19:05'!
setSingleStepping
	"Ask whether script should be single-stepped."

	| menu mSecs |
	menu _ CustomMenu new title: 'Single-step speed?'.
	menu add: 'Turbo speed' action: 0.
	menu add: 'Normal' action: 1.
	menu add: 'Flash blocks (fast)' action: 30.
	menu add: 'Flash blocks (slow)' action: 200.
	mSecs _ menu localize startUp.
	mSecs ifNil: [^ self].
	ScratchProcess blockHighlightMSecs: mSecs.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 8/17/2009 00:12'!
shareMenu: aMenuTitleMorph

	| menu stage |
	menu _ CustomMenu new.
	menu add: 'Compile This Project' action: #makeExe.
	menu addLine.
	self addServerCommandsTo: menu.

	stage _ workPane.
	stage ifNotNil: [
		(stage scratchServer notNil and: 
		[stage scratchServer sessionInProgress])
			ifTrue: [
				menu add: 'share this sprite' action: #shareSprite ]].

	menu localize.

	#(1) do: [:n |
		menu labels at: n put:
			((menu labels at: n) copyFrom: 1 to: (menu labels at: n) size - 1), ScratchTranslator ellipsesSuffix].

	menu invokeOn: self at: aMenuTitleMorph bottomLeft + (0@10).

! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 5/19/2010 03:40'!
shoutGo
	"Broadcasts the start event to all objects and processes."

	self stopAll.
	workPane broadcastEventNamed: 'Scratch-StartClicked' with: 0.
	flagButton on.
	self showPause.
	World displayWorldSafely.  "force button flash"
	Delay waitMSecs: 20.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/26/2009 22:21'!
showMotorBlocks

	workPane showMotorBlocks: true.
	viewerPane currentCategory: 'motion'.
	viewerPane pageViewer vScrollRelative: 1.0.! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/14/2009 10:33'!
showNetworkAddress
	"Display my IP address. This is a temporary feature to allow connected multiple Scratch computers in a peer-to-peer configuration without the help of a presence server."

	| localAddr wanAddr msg |
	Socket initializeNetwork.
	localAddr _ NetNameResolver localHostAddress.
	wanAddr _ nil.
"	wanAddr _ ScratchServer getIPAddressFromServer."

	msg _ NetNameResolver stringFromAddress: localAddr.
	(wanAddr notNil and: [wanAddr ~= localAddr]) ifTrue: [
		msg _ msg, String cr, 'Internet:   ', (NetNameResolver stringFromAddress: wanAddr)].

	DialogBoxMorph inform: msg title: 'IP Address'.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/31/2006 20:59'!
showSensorBoard

	| sb |
	sb _ workPane sensorBoard.
	sb position: self workPane position + 20.
	self workPane addMorph: sb.
	sb tryToOpenPort.
	World startSteppingSubmorphsOf: sb.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/14/2009 10:33'!
startHostingScratchSession
	"Start running the Scratch server, allowing Scratch and other applications to interact with this Scratch remotely."

	| server |
	workPane scratchServer ifNil: [
		server _ ScratchServer new.
		server stage: workPane.
		workPane scratchServer: server].

	workPane scratchServer startHosting.
	self showNetworkAddress.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 5/18/2010 01:57'!
stopAll
	"Tell my workPane to stop everything."

	| oldJustSaved |
	oldJustSaved _ justSaved.
	workPane stopAll.
	pauseButton off.
	justSaved _ oldJustSaved.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 12/8/2008 12:05'!
surpriseSpriteMorph

	| fileName f el m e |
	self world activeHand toolType: nil.
	self paintingInProgress ifTrue: [^ self beep].

	fileName _ self nextSurpriseCostumeName.
	fileName ifNil: [
		^ self addAndView: ScratchFrameMorph defaultSprite fullCopy].

	[f _ Form fromFileNamed: fileName] ifError: [^ self].
	el _ ImageMedia new form: (ScratchFrameMorph scaledFormForPaintEditor: f).
	m _ ScratchSpriteMorph new soleCostume: el.
	el mediaName: (m unusedMediaNameFromBaseName: (FileDirectory localNameFor: fileName)).
	self addAndView: m.

	e _ (workPane extent - m extent) abs // 2.
	m referencePosition: ((e x negated) to: e x) atRandom @ ((e y negated) to: e y) atRandom.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 9/29/2003 23:19'!
toggleErrorCatcher

	UseErrorCatcher _ UseErrorCatcher not.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/14/2005 15:13'!
toggleSingleStepping
	"Toggle single stepping."

	ScratchProcess blockHighlightMSecs <= 1
		ifTrue: [ScratchProcess blockHighlightMSecs: 60]
		ifFalse: [ScratchProcess blockHighlightMSecs: 1].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 6/14/2007 18:44'!
uniqueSummaryFileName

	| baseName fileName n |
	baseName _ self projectName.
	baseName size <= 1 ifTrue: [baseName _ 'newProject'].
	fileName _ baseName, '-summary.txt'.
	n _ 1.

	[FileDirectory default fileExists: fileName] whileTrue: [
		fileName _ baseName, n printString, '-summary.txt'.
		n _ n + 1].

	^ fileName

! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 6/14/2007 17:07'!
writeMultipleSummaries
	"Write the summary for all Scratch projects in a given folder."

	| dir |
	dir _ ScratchFileChooserDialog chooseFolder: FileDirectory default.
	dir = #cancelled ifTrue: [^ self].

	dir allFileNamesDo: [:fn |
		(fn asLowercase endsWith: '.scratch') | (fn asLowercase endsWith: '.sb') ifTrue: [
			self openScratchProjectNamed: fn.
			World doOneCycleNoInput.
			self writeSummaryFile: fn]].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 6/14/2007 17:06'!
writeSummaryFile
	"Write a summary of this project to a file."

	self writeSummaryFile: ''.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/21/2009 10:28'!
writeSummaryFile: fullFileName
	"Write a summary of this project to a file."

	| s sprites f fName |
	s _ WriteStream on: (String new: 10000).

	s nextPutAll: 'Project: ', self projectName; crlf.
	fullFileName size > 0 ifTrue: [s nextPutAll: 'Location: ', fullFileName; crlf].
	(projectInfo includesKey: 'author') ifTrue: [
		s nextPutAll: 'Author: ', (projectInfo at: 'author'); crlf].
	(projectInfo includesKey: 'scratch-version') ifTrue: [
		s nextPutAll: 'Scratch: ', (projectInfo at: 'scratch-version'); crlf].
	(projectInfo includesKey: 'comment') ifTrue: [
		s nextPutAll: 'Notes:'; crlf.
		(projectInfo at: 'comment') lines do: [:l | s nextPutAll: '    ', l; crlf].
		s crlf].
	(projectInfo includesKey: 'history') ifTrue: [
		s nextPutAll: 'History:'; crlf.
		(projectInfo at: 'history') lines do: [:l | s nextPutAll: '    ', l; crlf].
		s crlf].

	self writeSummaryTotalsOn: s.
	s nextPutAll: '--------'; crlf.
	workPane printSummaryOn: s.
	sprites _ workPane submorphs select: [:m | m isKindOf: ScratchSpriteMorph].
	sprites do: [:m |
		s skip: -2.  "remove last crlf"
		s nextPutAll: '--------'; crlf.
		m printSummaryOn: s].
	s nextPutAll: '--------'; crlf.

	ParagraphEditor clipboardTextPut: s contents asText.

	fName _ fullFileName.
	fullFileName size = 0
		ifTrue: [
			fName _ ScratchFileChooserDialog
				chooseNewFileDefault: self uniqueSummaryFileName
				title: 'File Name?'
				type: #projectSummary.
			fName = #cancelled ifTrue: [^ self]]
		ifFalse: [
			fName _ self uniqueSummaryFileName].

	f _ StandardFileStream newScratchFileNamed: fName.
	f ifNil: [^ self].
	f nextPutAll: s contents.
	f close.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/20/2007 09:50'!
writeSummaryTotalsOn: aStream
	"Write the totals for this project on the given stream."

	| sprites uniqueCostumes uniqueSounds stackCount |
	sprites _ workPane submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	sprites _ sprites asArray copyWith: workPane.
	uniqueCostumes _ IdentitySet new: 100.
	uniqueSounds _ IdentitySet new: 100.
	stackCount _ 0.
	sprites do: [:m |
		m media do: [:item |
			item isImage ifTrue: [uniqueCostumes add: item form].
			item isSound ifTrue: [uniqueSounds add: item sound]].
		stackCount _ stackCount + m blocksBin submorphCount].

	aStream nextPutAll: 'Totals: '; crlf.
	aStream nextPutAll: '    Sprites: ', (sprites size - 1) printString; crlf.
	aStream nextPutAll: '    Stacks: ', stackCount printString; crlf.
	aStream nextPutAll: '    Unique costumes: ', uniqueCostumes size printString; crlf.
	aStream nextPutAll: '    Unique sounds: ', uniqueSounds size printString; crlf.
! !


!ScratchFrameMorph methodsFor: 'geometry' stamp: 'jm 10/26/2008 17:44'!
extent: aPoint
	"Position all my submorphs whenever I get resized."

	super extent: aPoint.
	self fixLayout.
! !

!ScratchFrameMorph methodsFor: 'geometry' stamp: 'jm 4/22/2009 08:59'!
fixLayout

	| stageExtent xyReadout w |
	stageExtent _
		workPane isQuarterSize
			ifTrue: [workPane extent // 2]
			ifFalse: [workPane extent].

	topPane
		position: self topLeft;
		width: self width;
		height: (menuPanel height + 0 max: logoMorph height + 10).

	stageFrame
		extent: stageExtent + (14@42);
		top: topPane bottom;
		right: self right.

	workPane position: stageFrame topLeft + (4@37).

	titlePane
		position: stageFrame topLeft + (0@1);
		width: stageFrame width - 6;
		height: 36.

	self fixProjectTitleMorphLayout.

	scriptsPane fixLayout.
	w _ (viewerPane catButtonsExtent x + 17)
		within: 40
		and: (self width - (scriptsPane bareMinimumWidth + stageFrame width)).
	viewerPane position: topPane bottomLeft;
		width: w;
		height: self bottom - topPane bottom.

	scriptsPane
		position: viewerPane topRight;
		width: self width - (stageFrame width + viewerPane width);
		height: self bottom - topPane bottom;
		fixLayout.

	libraryPane position: stageFrame bottomLeft;
		width: (self right - scriptsPane right);
		height: self bottom - libraryPane top.

	menuPanel
		left: logoMorph right + 18;
		top: topPane top + ((topPane height - menuPanel height) // 2) + 2.

	viewModeButtonsPanel
		right: stageFrame right - 8;
		top: self top + 7.

	stageButtonsPanel
		position: (stageFrame left + 10)@(topPane bottom + 5);
		width: stageFrame width - 28;
		height: (workPane top - stageFrame top) - 8.

	xyReadout _ readoutPane submorphs at: 1.
	readoutPane
		width: xyReadout width + 23;
		height: xyReadout height + 15;
		position: stageFrame bottomRight - ((readoutPane width + 6)@3).
	xyReadout position: readoutPane position + (18@5).

	toolbarPanel
		left: (stageFrame left - 4 max: menuPanel right);
		top: self top + ((topPane height - toolbarPanel height) // 2) + 3.

	((toolbarPanel right - 5) > viewModeButtonsPanel left)
		ifTrue: [toolbarPanel delete]
		ifFalse: [
			(toolbarPanel owner = self) ifFalse: [
				self addMorphFront: toolbarPanel]].
! !

!ScratchFrameMorph methodsFor: 'geometry' stamp: 'jm 12/23/2008 13:50'!
hidePalette: hidePalette
	"Hide or show the blocks palette."

	hidePalette = viewerPane owner isNil ifTrue: [^ self].  "no change"

	hidePalette
		ifTrue: [
			viewerPane delete.
			scriptsPane
				initFrontFromForm: (ScratchFrameMorph skinAt: #blocksPaletteFrameTransparent2) topSectionHeight: 90;
				middleBarLeftMargin: 5 rightMargin: 0]
		ifFalse: [
			self addMorph: viewerPane.
			scriptsPane
				initFrontFromForm: (ScratchFrameMorph skinAt: #scriptPaneFrameTransparent2) topSectionHeight: 90;
				middleBarLeftMargin: 0 rightMargin: 0].

	scriptsPane color: (Color r: 149/255 g: 154/255 b: 159/255).
! !


!ScratchFrameMorph methodsFor: 'drawing' stamp: 'jm 12/9/2008 18:27'!
areasRemainingToFill: aRectangle
	"Drawing optimization. Since I completely fill my bounds with opaque pixels, this method tells Morphic that it isn't necessary to draw any morphs covered by me."
	
	^ aRectangle areasOutside: self bounds
! !

!ScratchFrameMorph methodsFor: 'drawing' stamp: 'jm 4/27/2005 17:29'!
drawOn: aCanvas
	"Optimization: Don't draw myself at all since I am completely tiled."

! !

!ScratchFrameMorph methodsFor: 'drawing' stamp: 'jm 2/3/2009 19:17'!
fullDrawOn: aCanvas
	"Draw my full Morphic structure on the given Canvas."
	"Optimization: if damage is entirely contained in a given pane, draw only that pane."

	| damageR stageR |
	damageR _ aCanvas clipRect.

	stageR _ workPane bounds.
	workPane isQuarterSize ifTrue: [
		stageR _ workPane position extent: (workPane width // 2) @ (workPane height // 2)].
	(stageR containsRect: damageR) ifTrue: [
		workPane fullDrawOn: aCanvas.
		^ self].

	(scriptsPane bounds containsRect: damageR) ifTrue: [
		scriptsPane fullDrawOn: aCanvas.
		^ self].

	(viewerPane bounds containsRect: damageR) ifTrue: [
		viewerPane fullDrawOn: aCanvas.
		^ self].

	(readoutPane bounds containsRect: damageR) ifTrue: [
		readoutPane fullDrawOn: aCanvas.
		^ self].

	(libraryPane bounds containsRect: damageR) ifTrue: [
		libraryPane fullDrawOn: aCanvas.
		^ self].

	super fullDrawOn: aCanvas.
! !


!ScratchFrameMorph methodsFor: 'event handling' stamp: 'jm 3/16/2007 16:53'!
handlesMouseDown: evt

	^ true
! !

!ScratchFrameMorph methodsFor: 'event handling' stamp: 'jens 5/5/2010 00:27'!
mouseDown: evt
	"Revert to normal cursor."

	evt hand toolType: nil.
	(evt cursorPoint y - self top) < topPane height ifTrue: [
		fillScreenFlag ifFalse: [evt hand grabMorph: self]].
! !

!ScratchFrameMorph methodsFor: 'event handling' stamp: 'jm 10/2/2006 15:48'!
wantsKeyboardFocusFor: aSubmorph
	"Don't allow shift-click edit and select in random label strings."

	^ false
! !


!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 6/25/2009 17:13'!
checkForWeDo
	"Check for WeDo, and show motor blocks if it is found."
	"Note: Polling on Vista can take several hundred milliseconds, so reduce polling to just a few times per minute."

	| now |
	now _ Time millisecondClockValue.
	(lastWeDoPoll isNil or: [lastWeDoPoll > now]) ifTrue: [lastWeDoPoll _ 0].
	((now - lastWeDoPoll) < 15000) ifTrue: [^ self]. "don't poll too often"
	lastWeDoPoll _ now.
	WeDoPlugin readInputs.
	WeDoPlugin isOpen ifTrue: [
		workPane showMotorBlocks ifTrue: [^ self].
		self showMotorBlocks.
		WeDoPlugin readInputs].
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jens 5/3/2010 22:16'!
processDroppedFiles
	"Process any files that have been dropped onto me."

	| droppedFiles m dropPoint fName |
	droppedFiles _ FileStream droppedFiles.
	droppedFiles size = 0 ifTrue: [^ self].
	(m _ self viewerPane target) ifNil: [^ self].
	dropPoint _ droppedFiles first.

	(droppedFiles copyFrom: 2 to: droppedFiles size) do: [:file |
		file close.
		fName _ file fullName.
		((fName asLowercase endsWith: '.scratch') | (fName asLowercase endsWith: '.sb') | (fName asLowercase endsWith: '.ypr'))
			ifTrue: [self openScratchDroppedProjectNamed: fName]
			ifFalse: [
				((fName asLowercase endsWith: '.sprite') | (fName asLowercase endsWith: '.ysp'))
					ifTrue: [self importSpriteOrProject: fName]
					ifFalse: [m importMedia: fName]]].
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 12/9/2008 23:01'!
processKeyboardEvents

	| evt ch |
	World hands do: [:h |
		[(evt _ h nextUnclaimedKeystrokeOrNil) notNil] whileTrue: [
			ch _ evt keyValue.
			evt commandKeyPressed ifTrue: [ch _ ch \\ 32].	"map cmd/alt keys to control keys"
			(ch = 3) | (ch = 13) ifTrue: [^ self pressGreenFlagButton].
			ch = 15 ifTrue: [^ self openScratchProject].
			ch = 17 ifTrue: [^ self quitScratch].
			ch = 19 ifTrue: [^ self saveScratchProjectNoDialog].
			ch = 27 ifTrue: [
				TakeOverScreen ifTrue: [
					Smalltalk fullScreenMode: false.
					Smalltalk fullScreenMode: true.
					World restoreDisplay].
				^ self].
			workPane broadcastEventNamed: 'Scratch-KeyPressedEvent' with: evt]].
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 6/4/2009 12:33'!
processWhenConditions
	"Trigger any 'when <condition>' hats."

	| objList |
	true ifTrue: [^ self].  "disabled"
	objList _ workPane submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	objList _ objList copyWith: workPane.
	objList do: [:obj |
		obj scripts do: [:hat |
			(hat isMemberOf: WhenHatBlockMorph) ifTrue: [
				(hat hasRunningProcess not and: [hat evaluateCondition]) ifTrue: [
					hat start; layoutChanged]]]].
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jens 3/9/2011 22:47'!
step
	"Run each process until it gives up control, then filter out any processes that have terminated."

	| screenExtent oldJustSaved |
	fillScreenFlag ifTrue: [
		screenExtent _ Display extent.
		((self position = (0@0)) and: [self extent = screenExtent]) ifFalse: [
			oldJustSaved _ justSaved.
			self position: 0@0.
			self extent: screenExtent.
			self enterQuarterModeIfSmallScreen.
			scriptsPane currentCategory: scriptsPane currentCategory.
			justSaved _ oldJustSaved.
			^ self]].

	workPane ifNotNil: [
		ScriptableScratchMorph scratchOrigin: workPane center.
		viewerPane target isNil 
			ifTrue: [workPane viewBlocksAndScripts]
			ifFalse: [viewerPane target isInWorld ifFalse: [workPane viewBlocksAndScriptsQuickly]]].

	Sensor processOSMenuEvents.
	paintingInProgress ifTrue: [^ self].

	workPane scratchServer ifNotNil: [workPane scratchServer stepServer].
	self checkForWeDo.
	self updateToolButtons.
	self processWhenConditions.
	self processKeyboardEvents.
	workPane stepProcesses.
	workPane scratchServer ifNotNil: [workPane scratchServer stepServer].
	self processDroppedFiles.
	workPane processesToRun size > 0
		ifTrue: [flagButton on]
		ifFalse: [flagButton off. self showPause]
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 7/9/2003 12:02'!
stepTime
	"Every screen update cycle."

	^ 0
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 4/22/2009 08:36'!
updateToolButtons
	"Update the highlighting of my tool buttons."

	| toolButtons currentTool |
	Sensor anyButtonPressed ifTrue: [^ self].  "don't update if mouse button pressed"

	toolButtons _ toolbarPanel submorphs select: [:m |
		(m isKindOf: ToggleButton) and: [m actionSelector endsWith: 'Tool']].

	currentTool _ (World activeHand toolType ifNil: ['none']) asLowercase.
	toolButtons do: [:b |
		(b actionSelector asLowercase = currentTool)
			ifTrue: [b on]
			ifFalse: [b off]].

! !


!ScratchFrameMorph methodsFor: 'dropping/grabbing' stamp: 'ee 5/14/2008 12:55'!
wantsDroppedMorph: aMorph event: evt

	^ (aMorph isKindOf: BlockMorph) or: [
	  	(aMorph isKindOf: ScriptableScratchMorph) or: [
			(aMorph isKindOf: ScratchCommentMorph)]].
! !


!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 4/13/2009 21:05'!
enterNormalMode
	"Go into normal (full-stage) mode."

	(viewMode = #normal) ifTrue: [
		self updateViewModeButtons.
		^ self].

	viewMode _ #normal.

	workPane isQuarterSize: false.
	workPane isInWorld
		ifTrue: [self fixLayout]
		ifFalse: [self exitPresentationMode].

	self updatePanes.
	self updateViewModeButtons.
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 6/22/2009 12:54'!
enterPresentationMode
	"Go into presentation mode."

	| presenter |
	ScratchPlugin pluginAvailable ifFalse: [
		self updateViewModeButtons.
		^ self beep].

	(viewMode = #presentation) ifTrue: [^ self].

	lastViewMode _ viewMode.
	viewMode _ #presentation.

	self closeDialogBoxes.
	workPane isQuarterSize: false.
	presenter _ ScratchPresenterMorph new frame: self.

	self delete.

	Display fillBlack.
	Smalltalk fullScreenMode: true.
	World restoreDisplay.
	Display fillBlack.
	World assuredCanvas.  "re-allocate canvas after entering full-screen mode"

	((Display width >= 965) & (Display height >= 750))
		ifTrue: [presenter beDoubleSize].
	presenter extent: Display extent.

	World addMorphFront: presenter.
	World startSteppingSubmorphsOf: presenter.
	World activeHand newKeyboardFocus: nil.
	self updatePenPositions.
	self updateViewModeButtons.

	World assuredCanvas.  "re-allocate canvas after entering full-screen mode"
	World fullRepaintNeeded.
	World displayWorldSafely.
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 4/13/2009 21:01'!
enterQuarterMode
	"Go into quarter stage mode."

	(viewMode = #quarter) ifTrue: [
		self updateViewModeButtons.
		^ self].

	viewMode _ #quarter.

	workPane isQuarterSize: true.
	workPane isInWorld
		ifTrue: [self fixLayout]
		ifFalse: [self exitPresentationMode].

	self updatePanes.
	self updateViewModeButtons.
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jens 8/13/2009 23:48'!
exitPresentationMode
	"Exit presentation mode."

	quitFlag ifTrue: [^Smalltalk quitPrimitive].

	TakeOverScreen ifFalse: [
		Smalltalk fullScreenMode: false.
		World restoreDisplay].

	ScriptableScratchMorph doubleSize: false.
	self addMorphFront: workPane.
	self fixLayout.
	World addMorphFront: self.
	World startSteppingSubmorphsOf: self.
	World fullRepaintNeeded.
	self updatePenPositions.

	lastViewMode = #normal ifTrue: [^ self enterNormalMode].
	lastViewMode = #quarter ifTrue: [^ self enterQuarterMode].
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 3/2/2009 12:56'!
projectComment: aString

	aString = DefaultNotes ifTrue: [
		projectInfo removeKey: 'comment' ifAbsent: [].
		^ self].

	projectInfo at: 'comment' put: aString asString.
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 11/15/2006 17:10'!
updatePenPositions
	"Update the pen positions of my sprites when going between normal and presentation mode."

	| stage |
	stage _ self workPane.
	ScriptableScratchMorph scratchOrigin: stage center.
	stage submorphsDo: [:m | stage updatePenPositionFor: m].
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'ee 12/5/2008 17:27'!
updateViewModeButtons

	viewModeButtons do: [:b | b off].
	viewModeButtons do: [:b |
		(b actionSelector = #enterQuarterMode and: [viewMode = #quarter])
			ifTrue: [b on].
		(b actionSelector = #enterNormalMode and: [viewMode = #normal])
			ifTrue: [b on].
		(b actionSelector = #enterPresentationMode and: [viewMode = #presentation])
			ifTrue: [b on]].
! !


!ScratchFrameMorph methodsFor: 'other' stamp: 'jens 5/3/2010 02:20'!
addAndView: aSpriteMorph
	"Add given morph to the work pane and view it."

	| pos i p |
	aSpriteMorph center: workPane center.
	pos _ self scratchObjects collect: [:o | o referencePosition].
	i _ 0.
	[pos includes: (p _ (10 * i) asPoint)] whileTrue: [i _ i + 1].
	workPane addMorphFront: aSpriteMorph.
	aSpriteMorph objName: aSpriteMorph nextInstanceName.
	aSpriteMorph referencePosition: p.

	aSpriteMorph installGlobalBlocks.

	workPane customBlocks ifNotNil: [
		workPane customBlocks do: [:eachDef |
			eachDef isGlobal ifTrue: [
				aSpriteMorph ensureCustomBlockExists: eachDef ]]].

	aSpriteMorph startStepping.
	workPane sprites addLast: aSpriteMorph.
	self view: aSpriteMorph tab: 'Scripts' category: 'motion'.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'ee 7/1/2008 11:09'!
closeMediaEditorsAndDialogs
	"Close any open paint or sound editors, asking the user first to avoid losing edits. Answer true if all are closed."

	| mList mHasCancel |
	mList _ PaintFrame allInstances select: [:m | m isInWorld].
	mList size > 0 ifTrue: [
		(DialogBoxMorph ask: 'Close paint editor?') ifFalse: [^ false].
		mList do: [:m | m cancelled; delete].
		paintingInProgress _ false].

	mList _ ScratchSoundRecorderDialogMorph allInstances select: [:m | m isInWorld].
	mList size > 0 ifTrue: [
		(DialogBoxMorph ask: 'Close sound recorder?') ifFalse: [^ false].
		mList do: [:m | m cancelled; delete]].

	mList _ DialogBoxMorph allInstances select: [:m | m isInWorld].
	mList size > 0 ifTrue: [
		(DialogBoxMorph ask: 'Close dialog?') ifFalse: [^ false].
		mList do: [:m |
			mHasCancel _ false.
			m buttons do: [:b |
				b action = #cancelled ifTrue: [mHasCancel _ true]].
			mHasCancel
				ifTrue: [m cancelled; delete]
				ifFalse: [m no; delete]]].

	DialogBoxMorph subclassesDo: [:c |
		mList _ c allInstances select: [:m | m isInWorld].
		mList size > 0 ifTrue: [
			(DialogBoxMorph ask: 'Close dialog?') ifFalse: [^ false].
			mList do: [:m |
				mHasCancel _ false.
				m buttons do: [:b |
					b action = #cancelled ifTrue: [mHasCancel _ true]].
				mHasCancel
					ifTrue: [m cancelled; delete]
					ifFalse: [m no; delete]]]].

	"subclass of a subclass of DialogBoxMorph"
	mList _ NewVariableDialog allInstances select: [:m | m isInWorld].
	mList size > 0 ifTrue: [
		(DialogBoxMorph ask: 'Close dialog?') ifFalse: [^ false].
		mList do: [:m | m cancelled; delete]].

	^ true
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 2/24/2004 18:57'!
delete

	World activeHand toolType: nil.
	super delete.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 10/21/2005 18:45'!
mouseX

	^ workPane mouseX
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 10/21/2005 18:46'!
mouseY

	^ workPane mouseY
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'ee 11/4/2008 11:46'!
newSound
	"Open the dialog to record a new sound."

	scriptsPane tabPane currentTab: 'Sounds'.
	viewerPane target recordSound.! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 8/2/2005 19:17'!
openMIDI
	"Prompt the user to select a MIDI port number, then open it."

	workPane openMIDI.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 6/22/2009 12:46'!
presentHelpScreen: aStringOrNil
	"Look for a help screen with the given name in the 'Help' folder. If found, present it to the user."

	| helpDir subDir fileNames helpFileName helpForm |
	aStringOrNil ifNil: [^ self beep].

	(FileDirectory default directoryNames includes: 'Help') ifFalse: [^ self beep].  "no help folder"
	helpDir _ FileDirectory default directoryNamed: 'Help'.

	"use the English subfolder by default if it exists"
	(helpDir directoryNames includes: 'en') ifTrue: [subDir _ helpDir directoryNamed: 'en'].
	"use subfolder for the current language if it exists"
	(helpDir directoryNames includes: ScratchTranslator currentLanguage) ifTrue: [
		subDir _ helpDir directoryNamed: ScratchTranslator currentLanguage].
	subDir ifNotNil: [helpDir _ subDir].

	fileNames _ helpDir fileNames collect: [:s | s asLowercase].

	helpFileName _ nil.
	#(hlp gif png jpg bmp) do: [:ext |
		helpFileName ifNil: [
			helpFileName _ aStringOrNil, '.', ext.
			(fileNames includes: helpFileName asLowercase)
				ifFalse: [helpFileName _ nil]]].
	helpFileName ifNil: [^ self beep].

	World doOneCycle.  "update cursor before fetching helpForm"
	[helpForm _ Form fromFileNamed: (helpDir fullNameFor: helpFileName)]
		ifError: [^ self beep].

	HelpDialog showForm: helpForm.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 11/13/2003 20:42'!
projectDirectory

	projectDirectory ifNil: [^ FileDirectory default].
	^ projectDirectory
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jens 7/15/2010 01:31'!
projectModified
	"Record that the current project has changed since it was last saved."

	justSaved _ false.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'ee 4/14/2008 15:01'!
updateMediaCategoryFor: anObject
	"Update the media viewer for the given object's media category. Do nothing if the media category of the given object is not being viewed."

	scriptsPane target = anObject ifTrue: [
		scriptsPane categoryChanged: 'Sounds'.
		scriptsPane categoryChanged: 'Costumes'].
	viewerPane target = anObject ifTrue: [
		viewerPane categoryChanged: 'Sound'].
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'ee 11/4/2008 11:45'!
view: aMorph tab: t category: c
	"Add given morph to the work pane and view it."

	scriptsPane target: aMorph.
	scriptsPane tabPane currentTab: t.
	viewerPane
		target: aMorph;
		currentCategory: c.
! !


!ScratchFrameMorph methodsFor: 'startup' stamp: 'jens 8/2/2010 23:27'!
processSettingsFile
	"Process settings from the Scratch.ini file."

	| lang settings k |
	self class setVisibleDrives: nil.
	lang _ nil.
	AllowSharing _ true.
	ScratchFileChooserDialog clearFolderCache. "clear homeDir and last folder cache"
	settings _ self readSettingsFile.
	settings associationsDo: [:assoc |
		k _ assoc key.
		k = 'language' ifTrue: [lang _ assoc value].
		k = 'home' ifTrue: [ScratchFileChooserDialog setHomeDir: assoc value].
		k = 'visibledrives' ifTrue: [self class setVisibleDrives: assoc value].
		k = 'share' ifTrue: [(assoc value) = '0' ifTrue: [AllowSharing _ false]].
"		k = 'proxyserver' ifTrue: [ScratchUploadProgressDialog proxyServer: assoc value].
		k = 'proxyport' ifTrue: [ScratchUploadProgressDialog proxyPort: assoc value asNumberNoError]."
		k = 'keepspritesonstage' ifTrue: [self keepSpritesOnStage: assoc value asNumberNoError].
		k = 'blockcontrast' ifTrue: [assoc value = '0' ifTrue: [self blockContrastOff] ifFalse: [self blockContrastStrong]].
		k = 'threadsafemode' ifTrue: [assoc value = '0' ifTrue: [EventHatMorph threadSafeMode: false] ifFalse: [EventHatMorph threadSafeMode: true]].
		k = 'scopecontrast' ifTrue: [assoc value = '0' ifTrue: [VariableFrame scopeContrast: false] ifFalse: [VariableFrame scopeContrast: true]].
		k = 'translucentdragging' ifTrue: [assoc value = '0' ifTrue: [HandMorph translucentWhenDragging: false] ifFalse: [HandMorph translucentWhenDragging: true]].
].

	lang ifNil: [lang _ ScratchTranslator guessLanguage].
	self setLanguage: lang.
! !

!ScratchFrameMorph methodsFor: 'startup' stamp: 'jm 3/2/2009 12:56'!
readDefaultNotes
	"If there is a file named 'defaultNotes.txt' in the Scratch folder, read it in."

	| dir |
	DefaultNotes _ ''.
	dir _ FileDirectory default.
	(dir fileExists: 'defaultNotes.txt') ifTrue: [
		DefaultNotes _ (FileStream oldFileNamed: 'defaultNotes.txt') contentsOfEntireFile].
! !

!ScratchFrameMorph methodsFor: 'startup' stamp: 'jens 2/1/2010 01:26'!
readSettingsFile
	"Read my settings file and answer a Dictionary of settings."
	"ScratchFrameMorph new readSettingsFile"

	| f dict s tokens k |
	f _ FileStream readOnlyFileNamedOrNil: 'BYOB.ini'.
	f ifNil: [^ Dictionary new].
	dict _ Dictionary new.
	f contentsOfEntireFile lines do: [:line |
		s _ line collect: [:c | (c asciiValue < 32) ifTrue: [Character space] ifFalse: [c]].
		tokens _ s findTokens: '='.
		k _ tokens first withBlanksTrimmed asLowercase.
		tokens size = 2
			ifTrue: [dict at: k put: tokens second withBlanksTrimmed]
			ifFalse: [dict at: k put: '1']].
	^ dict
! !

!ScratchFrameMorph methodsFor: 'startup' stamp: 'jens 8/3/2010 00:16'!
startup

	| startupFileNames fileName arg presentationMode |

	HostSystemMenus startUp.
	HostSystemMenus menuBarControler reviseHostMenus.

	ScriptableScratchMorph randomInit.
	ScratchTranslator detectRenderPlugin.
	ScratchTranslator importLanguagesList.

	ScratchFrameMorph readShareServerEntry.
	BlockMorph contrastStrong.
	self keepSpritesOnStage: 1.
	EventHatMorph threadSafeMode: false.
	HandMorph translucentWhenDragging: true.
	VariableFrame scopeContrast: false.
	self processSettingsFile.
	self readDefaultNotes.

	BlockEditorFrameMorph resetDimensions.
	ElementsEditorFrameMorph resetDimensions.
	DebuggerFrameMorph resetDimensions.

	self updateProjectName.
	shuffledCostumeNames _ nil.
	author _ ''.
	loginName _ ''.
	loginPassword _ ''.
	justSaved _ true.
	presentationMode _ false.

	startupFileNames _ InputSensor startupFileNames asOrderedCollection.
	2 to: 10 do: [:i |
		arg _ Smalltalk getSystemAttribute: i.
		(arg notNil and: [arg size > 0]) ifTrue: [
			startupFileNames addLast: (ScratchPlugin primShortToLongPath: arg)]].

	startupFileNames do: [:n |
		(n asLowercase = 'presentation') ifTrue: [
			quitFlag _ true. 
			presentationMode _ true.
			self isHidden: true.
			Display fillBlack].
		(n asLowercase = 'fullscreen') ifTrue: [TakeOverScreen _ true]].

	TakeOverScreen ifTrue: [
		Smalltalk fullScreenMode: true.
		World restoreDisplay].

	self enterQuarterModeIfSmallScreen.

	fileName _ startupFileNames
		detect: [:fn |
			(fn asLowercase endsWith: '.sb') or: [(fn asLowercase endsWith: '.scratch') or: [fn asLowercase endsWith: '.ypr']]]
		ifNone: [presentationMode ifTrue: [self randomProjectName]]. "this is BYOB's screensaver feature -jens"
	fileName ifNotNil: [
		presentationMode ifTrue: [Display fillColor: Color black].
		self openScratchProjectNamed: fileName.
		presentationMode ifTrue: [self enterPresentationMode; shoutGo].
		^ self].

	viewerPane currentCategory: 'motion'.
	self setDefaultSprite.
	self newScratchProject.

	fileName _ startupFileNames
		detect: [:fn | (fn asLowercase endsWith: '.sprite') or: [fn asLowercase endsWith: '.ysp']]
		ifNone: [^ self].

	"open a .sprite file"
	workPane submorphs do: [:m | (m isKindOf: ScratchSpriteMorph) ifTrue: [m deleteSprite]].
	self importSpriteOrProject: fileName.
! !


!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jm 6/2/2009 18:54'!
clearStage

	self stopAll.
	projectDirectory _ ScratchFileChooserDialog getDefaultFolderForType: #project.
	projectName _ ''.
	projectInfo _ Dictionary new.

	self installNewProject: ScratchStageMorph new.
	self initializeWatcherPositions.
	justSaved _ true.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jm 7/30/2008 17:12'!
extractInfoFrom: aByteArray
	"Answer a Scratch info dictionary from the given ByteArray. Answer an empty dictionary if it is an old project."

	| s version |
	s _ ReadStream on: aByteArray.
	version _ ObjStream scratchFileVersionFrom: (s next: 10) asString.
	(version = 1) | (version = 2)
		ifTrue: [
			s skip: 4.  "skip info header byte count"
			^ ObjStream new readObjFrom: s showProgress: false]
		ifFalse: [^ Dictionary new].

! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 6/30/2010 23:26'!
extractProjectFrom: aByteArray
	"Answer a Scratch project (i.e. a ScratchStageMorph possibly containing sprites) from the given ByteArray. Answer nil if the project cannot be unpacked."

	| s version proj |

	ObjStream initialize. "just to make sure this works in filed-in changesets, -Jens"

	s _ ReadStream on: aByteArray.
	version _ ObjStream scratchFileVersionFrom: (s next: 10) asString.
	version = 0 ifTrue: [
		ScriptableScratchMorph decodeAsByob.	"make sure we initialize every field - this breaks compatibility with Scratch-sprites. -Jens"
		s position: 0.
		[proj _ ObjStream new readObjFrom: s showProgress: true] ifError: [
		^ self extractScratchProjectFrom: aByteArray]].
	(version = 1) | (version = 2) ifTrue: [
		s skip: s uint32.  "skip header"
		proj _ ObjStream new readObjFrom: s showProgress: true].

	proj class = ScratchStageMorph ifFalse: [
		version > 2
			ifTrue: [self error: 'Project created by a later version of Scratch']
			ifFalse: [self error: 'Problem reading project.'].
		^ nil].

	ScriptableScratchMorph buildBlockSpecDictionary.

	'initializing...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((proj allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 2
		during: [:bar | | i | i _ 0.

	proj allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			 i _ i + 1. bar value: i.
			m convertTuplesToDefinitions]].

	proj allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [  "convert to new blocks" 
			i _ i + 1. bar value: i.
			m convertStacksToTuples.
			m convertTuplesToStacks]]].

	^ proj
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 6/30/2010 23:26'!
extractScratchProjectFrom: aByteArray
	"Answer a Scratch project (i.e. a ScratchStageMorph possibly containing sprites) from the given ByteArray. Answer nil if the project cannot be unpacked.

Note: this is a compatibility force method for BYOB - jens"

	| s version proj |

	ObjStream initialize. "just to make sure this works in filed-in changesets, -Jens"

	s _ ReadStream on: aByteArray.
	version _ ObjStream scratchFileVersionFrom: (s next: 10) asString.
	version = 0 ifTrue: [
		ScriptableScratchMorph decodeAsScratch.	"this is the forcing part. -Jens"
		s position: 0.
		proj _ ObjStream new readObjFrom: s showProgress: true].
	(version = 1) | (version = 2) ifTrue: [
		s skip: s uint32.  "skip header"
		proj _ ObjStream new readObjFrom: s showProgress: true].

	proj class = ScratchStageMorph ifFalse: [
		version > 2
			ifTrue: [self error: 'Project created by a later version of Scratch']
			ifFalse: [self error: 'Problem reading project.'].
		^ nil].

	ScriptableScratchMorph buildBlockSpecDictionary.

	'initializing...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((proj allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 2
		during: [:bar | | i | i _ 0.

	proj allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			 i _ i + 1. bar value: i.
			m convertTuplesToDefinitions]].

	proj allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [  "convert to new blocks" 
			i _ i + 1. bar value: i.
			m convertStacksToTuples.
			m convertTuplesToStacks]]].

	^ proj
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jm 5/8/2007 11:04'!
fixByteReversedSounds
	"See if the current project contains any byte-reversed copies of one of the standard sounds. If it does, byte-reverse all sounds. This is a workaround for a bug in Scratch 1.0 that did not upload sounds in big-endian order."

	| allSoundBuffers badMeowPrefix badPopPrefix foundBadSound |
	allSoundBuffers _ IdentitySet new.
	self allProjectMedia do: [:media |
		media isSound ifTrue: [
			allSoundBuffers add: media sound samples]].
	allSoundBuffers remove: ScriptableScratchMorph meowSound samples ifAbsent: [].
	allSoundBuffers remove: ScriptableScratchMorph popSound samples ifAbsent: [].

	badMeowPrefix _ ScriptableScratchMorph oldMeowPrefixReversed.
	badPopPrefix _ (ScriptableScratchMorph popSound samples copyFrom: 1 to: 100) reverseEndiannessStereo: false.
	foundBadSound _ false.
	allSoundBuffers do: [:buf |
		foundBadSound ifFalse: [
			((buf beginsWith: badMeowPrefix) or:
			 [buf beginsWith: badPopPrefix])
				ifTrue: [foundBadSound _ true]]].

	foundBadSound ifTrue: [
		allSoundBuffers do: [:buf | buf reverseEndiannessStereo: false]].
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 5/10/2010 01:24'!
importScratchProject
	"Allow the user to select a project to open, then merge that project's sprites with the
current project."

	| response |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	response _ ScratchFileChooserDialog
		chooseExistingFileType: #project
		extensions: #(scratch sb ypr)
		title: 'Import Project'.
	response ifNil: [^ self].

	self importSpriteOrProject: response.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 7/27/2010 13:23'!
installNewProject: newWorkpane
	"Called after creating or reading a new project to clear the process scheduler, pick an object to view, clear the library thumbnails, and perform other housekeeping."

	| viewTarget sb |
	self stopAll.

	newWorkpane class = ScratchStageMorph
		ifFalse: [^ self inform: 'Incompatible Scratch file format'].

	"self exitScratchSession."
	workPane scratchServer ifNotNil: [
		workPane scratchServer clearCaches.
		workPane scratchServer stage: newWorkpane.
		newWorkpane scratchServer: workPane scratchServer].

	newWorkpane isQuarterSize: workPane isQuarterSize.
	newWorkpane bounds: workPane bounds.
	newWorkpane midiPortNum: workPane midiPortNum.
	workPane closeMIDI.

	"use the same sensorboard for the new project"
	sb _ workPane sensorBoard.
	newWorkpane submorphs do: [:m |
		(m isKindOf: SensorBoardMorph) ifTrue: [
			sb position: m position.
			newWorkpane replaceSubmorph: m by: sb.
			sb tryToOpenPort]].
	newWorkpane sensorBoard: sb.

	workPane owner replaceSubmorph: workPane by: newWorkpane.
	workPane _ newWorkpane.

	self fixByteReversedSounds.

	"fix sprite positions (backward compatability)"
	workPane submorphs do: [:m |
		(m isKindOf: WatcherMorph) ifTrue: [m convertFromOldWatcher].
		(m respondsTo: #costume) ifTrue: [
			m position: m position + m costume rotationCenter]. "fix up positions"
		m layoutChanged].
	workPane layoutChanged.

	"reset timer"
	ScriptableScratchMorph resetTimer.

	"pick an object view, or view the background if there is no other"
	viewTarget _ workPane.
	workPane submorphs do: [:m |
		(m respondsTo: #scripts) ifTrue: [
			m scripts size >= viewTarget scripts size ifTrue: [viewTarget _ m]]].
	viewTarget viewBlocksAndScripts.

	"populate the sprites list if it is empty (backward compatability)"
	workPane sprites isEmpty ifTrue: [
		workPane submorphs do: [:m |
			(m isKindOf: ScriptableScratchMorph) ifTrue: [workPane sprites addLast: m]]].

	scriptsPane tabPane currentTab: 'Scripts'.
	libraryPane clearLibrary.
	workPane clearPenTrails.
	self updateProjectName.
	ScratchProcess blockHighlightMSecs: 1.
	ScratchPrompterMorph clearLastAnswer.

	(projectInfo at: 'isHosting' ifAbsent: [false]) ifTrue: [
		self enableRemoteSensors].
	(projectInfo at: 'hasMotorBlocks' ifAbsent: [false]) ifTrue: [
		self showMotorBlocks].
	(projectInfo includesKey: 'penTrails') ifTrue: [
		workPane penTrailsForm: (projectInfo at: 'penTrails')].

	(projectInfo at: 'keepOnStage' ifAbsent: [true]) = ScriptableScratchMorph keepOnStage
		ifFalse: [self toggleKeepSpritesOnStage].

	Clipboard _ nil.
	World cleanseStepList.  "make sure garbage collect can clean up the old sprites"
	Smalltalk garbageCollect.  "get rid of old sprite instances"

	self world ifNotNil: [self world startSteppingSubmorphsOf: self].
	ScriptableScratchMorph scratchOrigin: workPane center.
	justSaved _ true.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 5/3/2010 22:01'!
nameFromFileName: fileName
	"Return the given Scratch file name without the trailing .sb or .scratch or .ypr extension, if it has one. Ensure the the result is UTF8."

	| s |
	s _ fileName.
	(s asLowercase endsWith: '.scratch') ifTrue: [s _ s copyFrom: 1 to: s size - 8].
	(s asLowercase endsWith: '.sb') ifTrue: [s _ s copyFrom: 1 to: s size - 3].
	(s asLowercase endsWith: '.ypr') ifTrue: [s _ s copyFrom: 1 to: s size - 4].
	s isUnicode ifFalse: [s _ UTF8 withAll: s].

	^ s

! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'ee 6/12/2008 12:02'!
openScratchDroppedProjectNamed: fName
	"Open a Scratch project with the given name that was dropped on the Scratch window."

	| response |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	(justSaved or: [self projectIsEmpty]) ifFalse: [
		"ask the user if they want to save the current project"
		response _ DialogBoxMorph askWithCancel: 'Save the current project?'.
		response = #cancelled ifTrue: [^ self].
		response ifTrue: [self saveScratchProjectNoDialog]].

	self openScratchProjectNamed: fName.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 7/27/2010 13:24'!
openScratchProject
	"Allow the user to select a project to open, then open that project."

	| response newProj |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	(justSaved or: [self projectIsEmpty]) ifFalse: [
		"ask the user if they want to save the current project"
		response _ DialogBoxMorph askWithCancel: 'Save the current project?'.
		response = #cancelled ifTrue: [^ self].
		response ifTrue: [self saveScratchProjectNoDialog]].

	response _ ScratchFileChooserDialog openScratchFileFor: self.
	response = #cancelled ifTrue: [^ self].

	(response isKindOf: String) ifTrue: [  "read the contents of a local file"
		^ self openScratchProjectNamed: response].

	(response isKindOf: ByteArray) ifTrue: [
		[projectInfo _ self extractInfoFrom: response] ifError: [projectInfo _ Dictionary new].
		[newProj _ self extractProjectFrom: response] ifError: [^ self].
		self installNewProject: newProj.
		projectDirectory _ ScratchFileChooserDialog getDefaultFolderForType: #project].
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 1/14/2011 02:11'!
openScratchProjectNamed: fName
	"Open a Scratch project with the given name."

	| f projData newProj dir fn|
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	
	fn _ fName.
	f _ FileStream readOnlyFileNamedOrNil: fn.
 	f ifNil: ["try a different encoding, fixes a Firefox bug, -Jens"
		fn _ fName isoLatinToMac asUTF8.
		f _ FileStream readOnlyFileNamedOrNil: fn.
		f ifNil: [^ self inform: 'Could not read' withDetails: fName]].

	[	projData _ f binary contentsOfEntireFile. 
		newProj _ self extractProjectFrom: projData.
		projectInfo _ self extractInfoFrom: projData. 

	] ifError: [:err :rcvr | ^ self inform: 'Could not read project; file may be damaged' withDetails: '(', err, ')'].

	dir _ FileDirectory dirPathFor: fn.
	projectDirectory _ FileDirectory on: dir.
	ScratchFileChooserDialog setLastFolderTo: projectDirectory forType: #project.
	projectName _ FileDirectory localNameFor: fn.

	self installNewProject: newProj.
	self initializeWatcherPositions.
	viewerPane updateContents.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 6/29/2010 12:57'!
saveScratchProject

	| fName result |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	fName _ ScratchFileChooserDialog saveScratchFileFor: self.
	(fName size = 0 or: [fName = #cancelled]) ifTrue: [^ self].

	[(result _ ScratchFileChooserDialog confirmFileOverwriteIfExisting: fName) = false] whileTrue: [
		fName _ ScratchFileChooserDialog saveScratchFileFor: self.
		(fName size = 0 or: [fName = #cancelled]) ifTrue: [^ self]].
	(result = #cancelled) ifTrue: [^ self].

"
	(ScriptableScratchMorph currentEncoding = #scratch) ifTrue: [
		(DialogBoxMorph new 
			title: 'Caution!! Converting Scratch to BYOB'; 
			withButtonsForYes: true no: true okay: false cancel: false;
			message: 'You will not be able to open this file in Scratch. Proceed anyway?';
			getUserResponse) ifFalse: [^self ]].
"
	self updateLastHistoryEntryIfNeeded.

"	fName _ (self nameFromFileName: fName), '.sb'."

	fName _ (self nameFromFileName: fName), '.ypr'.
	projectDirectory _ FileDirectory on: (FileDirectory dirPathFor: fName).
	projectName _ FileDirectory localNameFor: fName.

	projectInfo at: 'author' put: author.
	self updateHistoryProjectName: projectName op: 'save'.
	self writeScratchProject.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 5/3/2010 22:20'!
saveScratchProjectNoDialog

	| fName dir |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].

	projectName ifNil: [projectName _ ''].
	fName _ self nameFromFileName: projectName.

	dir _ ScratchFileChooserDialog getLastFolderForType: #project.
"	(fName size = 0 | (dir fileExists: fName , '.sb') not) ifTrue: [^ self saveScratchProject]."
	(fName size = 0 | (dir fileExists: fName , '.ypr') not) ifTrue: [^ self saveScratchProject].
	ScratchFileChooserDialog lastFolderIsSampleProjectsFolder ifTrue:  [^ self saveScratchProject].

"
	(ScriptableScratchMorph currentEncoding = #scratch) ifTrue: [
		(DialogBoxMorph new 
			title: 'Caution!! Converting Scratch to BYOB'; 
			withButtonsForYes: true no: true okay: false cancel: false;
			message: 'You will not be able to open this file in Scratch. Proceed anyway?';
			getUserResponse) ifFalse: [^self ]].
"
	self updateLastHistoryEntryIfNeeded.

"	projectName _ FileDirectory localNameFor: (fName, '.sb'). " "ignore path, if any; save in the original project directory"
	projectName _ FileDirectory localNameFor: (fName, '.ypr').  "ignore path, if any; save in the original project directory"
	projectDirectory _ dir.

	self updateHistoryProjectName: projectName op: 'save'.
	self writeScratchProject.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 7/27/2010 13:43'!
storeProjectInfoOn: aBinaryStream

	| s |
	projectInfo at: 'thumbnail' put: workPane thumbnailForm.
	projectInfo at: 'keepOnStage' put: ScriptableScratchMorph keepOnStage.

	s _ WriteStream on: (ByteArray new: 100000).
	ObjStream new storeObj: projectInfo on: s.

	aBinaryStream uint32: s size.
	aBinaryStream nextPutAll: s contents.

! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 6/29/2010 13:01'!
updateHistoryProjectName: projName op: operation
	"The given user is about to save or upload a project with the given name. Update the project history. operation is a string specifying the operation."

	| timestamp tab history platform osVersion |
	projectInfo removeKey: 'organization' ifAbsent: [].	"obsolete"
	projectInfo at: 'scratch-version' put: Version.

	timestamp _ (Date today printFormat: #(3 2 1 $- 1 1)), ' ', Time now print24.
	tab _ String tab.

	history _ projectInfo at: 'history' ifAbsent: [''].
	history _ history, timestamp, tab.
	history _ history, operation, tab, (self nameFromFileName: projName), tab, loginName, tab, author.
	history _ history, String cr.
	projectInfo at: 'history' put: history.

	"record other data"
	projectInfo at: 'scratch-version' put: Version.
	projectInfo at: 'language' put: ScratchTranslator currentLanguage.

	platform _ Smalltalk platformName.
	platform ifNil: [platform _ 'unknown'].
	'linux' = platform ifTrue: [
		Display extent = (1200@900) ifTrue: [platform _ 'XO']].
	projectInfo at: 'platform' put: platform.

	osVersion _ Smalltalk osVersion.
	osVersion ifNil: [osVersion _ 'unknown'].
	projectInfo at: 'os-version' put: osVersion.

	(workPane scratchServer notNil and:
	 [workPane scratchServer isHosting])
		ifTrue: [projectInfo at: 'isHosting' put: true]
		ifFalse: [projectInfo removeKey: 'isHosting' ifAbsent: []].

	(self allBlocksString includesSubString: 'motor')
		ifTrue: [projectInfo at: 'hasMotorBlocks' put: true]
		ifFalse: [projectInfo removeKey: 'hasMotorBlocks' ifAbsent: []].

	workPane penTrailsForm
		ifNil: [projectInfo removeKey: 'penTrails' ifAbsent: []]
		ifNotNil: [projectInfo at: 'penTrails' put: workPane penTrailsForm].

! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jm 3/28/2007 12:43'!
updateLastHistoryEntryIfNeeded
	"If the the last entry in this project's history is an old-sytle entry (i.e. one that does not include the project name and author) update it."

	| lines lastLine oldAuthor tab s |
	lines _ (projectInfo at: 'history' ifAbsent: ['']) lines.
	lines size = 0 ifTrue: [^ self].
	lastLine _ lines at: lines size.
	(lastLine includes: Character tab) ifTrue: [^ self].  "last line is already a new-style entry"

	oldAuthor _ projectInfo at: 'author' ifAbsent: [''].
	tab _ String tab.
	lastLine _ lastLine, tab, 'old', tab, projectName, tab, "blank scratchr name" tab, oldAuthor.
	lines at: lines size put: lastLine.

	s _ WriteStream on: (String new: 1000).
	lines do: [:entry | s nextPutAll: entry; cr].
	projectInfo at: 'history' put: s contents.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 3/3/2011 08:54'!
writeScratchProject
	"Write this Scratch project to the file named projectFile in the project directory. Called by saveScratchProject."

	| oldScriptsTarget oldTab oldViewerCategory oldPosition saveError out |
	self stopAll.

	ObjStream initialize. "just to make sure this works in filed-in changesets, -Jens"

	self world ifNotNil: [self world activeHand newKeyboardFocus: nil].  "terminates active editor"

	"share duplicate sounds and images"
	self canonicalizeSoundsBits: nil saveOriginal: false.
	self canonicalizeImagesQuality: nil saveOriginal: false.

	oldScriptsTarget _ scriptsPane target.
	oldTab _ scriptsPane tabPane currentTab.
	oldViewerCategory _ viewerPane currentCategory.
	scriptsPane target: nil.

	workPane updateSpritesList.
	oldPosition _ workPane position.
	workPane delete; position: 0@0.
	self updatePenPositions.

	ScriptableScratchMorph buildBlockSpecDictionary.



	'saving...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((workPane allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 2
		during: [:bar | | i | i _ 0.

	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			(m isKindOf: ScratchSpriteMorph)
				ifTrue: [m cacheRefPos].
			m blocksBin allMorphsDo: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b stop]].
			m convertStacksToTuples]].

	saveError _ nil.
	[	out _ FileStream newFileNamed: (projectDirectory unusedNameStartingWith: 'tmp').
		out
			ifNil: [saveError _ 'Folder may be locked or read-only']
			ifNotNil: [
				out binary.
				out nextPutAll: 'BloxExpV01' asByteArray. "changed the internal version marker for the byob-prototype -Jens"
				self storeProjectInfoOn: out.
				ObjStream new storeObj: workPane on: out.
				out close].
	] ifError: [:err :rcvr |
		out ifNotNil: [
			[	out close.
				projectDirectory deleteFileNamed: out localName.
			] ifError: []]. 
		saveError _ err].

	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertTuplesToStacks]]].

	self addMorph: (workPane position: oldPosition).
	oldScriptsTarget ifNil: [oldScriptsTarget _ workPane].
	oldScriptsTarget viewBlocksAndScripts.
	scriptsPane tabPane currentTab: oldTab.
	viewerPane currentCategory: oldViewerCategory.
	self updatePenPositions.
	ScriptableScratchMorph decodeAsByob. "remember that we save this project in BYOB format"

	saveError
		ifNil: [
			justSaved _ true.
			self updateProjectName.
			projectDirectory deleteFileNamed: projectName.
			[projectDirectory rename: out localName toBe: projectName]
				ifError: [^ self inform: 'Save failed' withDetails: 'Is the folder read-only?' localized].
			projectDirectory setMacFileNamed: projectName type: 'STyb' creator: 'BYOB']
		ifNotNil: [
			projectName _ ''.
			self inform: 'Save failed' withDetails: saveError].
! !


!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 2/27/2009 11:31'!
allBlocksString

	| s stacks |
	s _ WriteStream on: (String new: 10000).
	((Array with: workPane), self scratchObjects) do: [:obj |
		stacks _ obj blocksBin submorphs select: [:m | m isKindOf: BlockMorph].
		stacks size > 0 ifTrue: [
			s nextPutAll: 'All stacks for ', obj objName, ':'; cr; cr.
			stacks do: [:blocks | self printTupleList: blocks tupleSequence on: s. s cr; cr].
			s cr]].

	^ s contents
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/25/2007 14:35'!
compressMediaForUpload
	"Compress my media prior to uploading this project."

	self canonicalizeSoundsBits: 4 saveOriginal: true.
	self canonicalizeImagesQuality: 90 saveOriginal: true.

! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/23/2007 23:29'!
printTupleElement: el on: s

	(el isKindOf: Array) ifTrue: [self printTupleList: el on: s. ^ self].
	(el isKindOf: Symbol) ifTrue: [s nextPutAll: el. ^ self].
	(el isKindOf: String) ifTrue: [s nextPut: $". s nextPutAll: el. s nextPut: $". ^ self].
	(el isKindOf: ScriptableScratchMorph) ifTrue: [s nextPutAll: el objName. ^ self].
	s nextPutAll: el printString.
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/23/2007 23:30'!
printTupleList: anArray on: s

	s nextPut: $(.
	1 to: anArray size do: [:i |
		self printTupleElement: (anArray at: i) on: s.
		i = anArray size ifFalse: [s space]].
	s nextPut: $).
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 3/28/2007 11:29'!
removeLastHistoryEntry
	"Remove the last entry in the project history. This is done if an upload attempt fails or is cancelled."

	| lines s |
	lines _ (projectInfo at: 'history' ifAbsent: ['']) lines.
	lines size = 0 ifTrue: [^ self].

	lines _ lines copyFrom: 1 to: lines size - 1.

	s _ WriteStream on: (String new: 1000).
	lines do: [:entry | s nextPutAll: entry; cr].
	projectInfo at: 'history' put: s contents.
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/18/2007 16:26'!
revertToUncompressedMedia
	"Revert to uncomprssed media after uploading this project."

	self allProjectMedia do: [:m | m revertToUncompressed].
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/23/2007 23:34'!
scriptsStringForUpload

	| s scripts |
	s _ WriteStream on: (String new: 10000).
	((Array with: workPane), self scratchObjects) do: [:obj |
		scripts _ obj blocksBin submorphs select: [:m | m isKindOf: HatBlockMorph].
		scripts size > 0 ifTrue: [
			s nextPutAll: 'Scripts for ', obj objName, ':'; cr; cr.
			scripts do: [:hat | self printTupleList: hat tupleSequence on: s. s cr].
			s cr]].
	^ s contents
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jens 7/27/2010 13:44'!
writeScratchProjectOn: aStream
	"Write this Scratch project in a serialized form on the given stream."

	| oldScriptsTarget oldTab oldViewerCategory oldPosition storeError |
	self stopAll.
	self world ifNotNil: [self world activeHand newKeyboardFocus: nil].  "terminates active editor"

	oldScriptsTarget _ scriptsPane target.
	oldTab _ scriptsPane tabPane currentTab.
	oldViewerCategory _ viewerPane currentCategory.
	scriptsPane target: nil.

	workPane updateSpritesList.
	oldPosition _ workPane position.
	workPane delete; position: 0@0.
	self updatePenPositions.

	ScriptableScratchMorph buildBlockSpecDictionary.
	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			m blocksBin allMorphsDo: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b stop]].
			m convertStacksToTuples]].

	storeError _ nil.
	[	aStream nextPutAll: 'ScratchV02' asByteArray.
		self storeProjectInfoOn: aStream.
		ObjStream new storeObj: workPane on: aStream.
	] ifError: [:err :rcvr | storeError _ err].

	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			m convertTuplesToStacks]].

	self addMorph: (workPane position: oldPosition).
	oldScriptsTarget ifNil: [oldScriptsTarget _ workPane].
	oldScriptsTarget viewBlocksAndScripts.
	scriptsPane tabPane currentTab: oldTab.
	viewerPane currentCategory: oldViewerCategory.
	self updatePenPositions.

	storeError ifNotNil: [self error: storeError].
! !


!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 5/6/2008 18:13'!
deleteWatchersForSprite: aSprite
	"The given sprite is being deleted. Delete all watchers associated with it."

	aSprite lists do: [:m | m delete].

	workPane submorphsDo: [:m |
		(m isKindOf: WatcherMorph) ifTrue: [
			(m target = aSprite) ifTrue: [m delete]]].

	watcherPositions keys do: [:k | 
		(k at: 1) = aSprite ifTrue: [watcherPositions removeKey: k]].
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 12/1/2007 23:22'!
deleteWatchersForVar: varName ofSprite: aSprite
	"The given variable is being deleted. Delete all watchers associated with it."

	workPane submorphsDo: [:m |
		(m isKindOf: WatcherMorph) ifTrue: [
			((m target = aSprite) and:
			 [(m getSelector = #getVar:) and:
			 [m parameter = varName]])
				ifTrue: [m delete]]].
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jens 5/18/2010 02:33'!
deletingWatcher
	"The given watcher is being removed from the stage; remember it's last position."

	| palette w |
	watcherPositions do: [:rec |
		rec first ifNotNil: [
			w _ rec first.
			w owner ifNil: [
				rec at: 1 put: nil.
				rec at: 2 put: w position - workPane position. "record old position and layout style"
				rec at: 3 put: w layoutStyle.
				rec at: 4 put: w sliderRange]]].

	palette _ viewerPane pageViewer contents.
	(palette respondsTo: #updateWatcherButtonsForFrame:) 
		ifTrue: [palette updateWatcherButtonsForFrame: self].
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 8/25/2008 09:56'!
initializeWatcherPositions
	"If any watchers are on the stage, store their position. The dictionary, which is created lazily, is formatted in the following way:
	(<sprite or nil, depending on whether the block isSpriteSpecific>, <name of block>) ->
		(<watcher or nil, depending on whether the watcher is showing on stage>,
		 <position of watcher with top-left corner of stage = 0@0>
		 <layout style>
		 <slider range>)
	Or, more concisely: (sprite/nil,selectorAndArg)->(watcher/nil,position,style,range)."
 
	| p |
	watcherPositions _ Dictionary new.
	self scratchWatchers do: [:w |
		p _ w position - workPane position.
		watcherPositions
			at: {w getAssociatedSprite. w selectorAndArg}
			put: {w. p. w layoutStyle. w sliderRange}].
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'ee 7/11/2008 22:26'!
listWatchers
	"Answer a collection of all the list watchers in the work pane."

	^ self workPane submorphs select: [:m | m isKindOf: ScratchListMorph]
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'tis 7/31/2006 09:08'!
scratchWatchers
	"Answer a collection of all the scratch watchers in the work pane."

	^ self workPane submorphs select: [:m | m isKindOf: WatcherMorph]
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 8/25/2008 10:05'!
showWatcher: watcher
	"Show the given watcher. Reuse it's old position if it was showing before. Otherwise, find a new position for it."

	| rec style range |
	rec _ watcherPositions
		at: {watcher getAssociatedSprite. watcher selectorAndArg}
		ifAbsent: [nil].
	rec
		ifNil: [
			watcher position: self unusedPositionForWatcher.
			style _ #small.
			range _ watcher sliderRange]
		ifNotNil: [
			watcher position: workPane position + rec second.
			style _ rec third.
			range _ rec fourth].

	watcherPositions
		at: {watcher getAssociatedSprite. watcher selectorAndArg}
		put: {watcher. (watcher position - workPane position). style. range}.

	watcher sliderRange: range.
	watcher layoutStyle: style.
	watcher updateTargetName.
	workPane addMorph: watcher.
	watcher world ifNotNil: [watcher world startSteppingSubmorphsOf: watcher].

! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'ee 6/28/2008 15:27'!
unusedPositionForWatcher
	"Return an unused watcher position on the stage."

	| watchers positions rowH x y newX |
	watchers _ (watcherPositions collect: [:r | r first]) select: [:w | w notNil].
	positions _ watchers collect: [:w | w position].

	(watchers size > 0)
		ifTrue: [rowH _ (watchers at: 1) height]
		ifFalse: [rowH _ 25].
	x _ workPane left + 10.
	y _ workPane top + 10.
	[positions includes: (x@y)] whileTrue: [
		y _ y + rowH.
		(y > (workPane bottom - rowH)) ifTrue: [  "start a new column"
			newX _ 0.
			watchers do: [:w |
				w left < (x + 20) ifTrue: [newX _ newX max: w right + 4]].
			newX > (workPane right - 20) ifTrue: [
				^ ((10 to: 400) atRandom) @ ((10 to: 330) atRandom)].  "no free location"
			x _ newX.
			y _ workPane top + 10]].

	^ x@y
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 11/30/2007 19:35'!
watcherForBlock: aBlockMorph
	"Answer a watcher for the given block if there is one currently showing on the stage."

	| pair |
	pair _ watcherPositions
		at: {aBlockMorph getAssociatedSprite. aBlockMorph selectorAndArg}
		ifAbsent: [^ nil].

	^ pair first

! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jens 1/19/2011 00:45'!
watcherShowingFor: sprite selectorAndArg: selectorAndArg
	"Answer true if a watcher for the given sprite, selector, and argument is currently showing on the stage."

	| sel arg listM pair |
	sel _ selectorAndArg first.
	arg _ selectorAndArg second.
	#listNamed: = sel ifTrue: [
		listM _ sprite listNamed: arg ifNone: [^ false].
		^ listM owner notNil].

	pair _ watcherPositions at: {sprite. selectorAndArg} ifAbsent: [^ false].
	pair first ifNotNil: [
		pair first owner ifNil: [pair at: 1 put: nil]].
	^ pair first notNil
! !


!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/13/2009 15:26'!
copyTool

	| hand cursorForm offset |
	self paintingInProgress ifTrue: [^ self beep].
	hand _ self world activeHand.
	hand toolType: 'CopyTool'.

	cursorForm _ ScratchFrameMorph skinAt: #copyCursor.
	offset _ 8@13.

	ScratchFrameMorph isXO ifTrue: [
		cursorForm _ cursorForm magnifyBy: 1.5.
		offset _ (offset * 1.5) rounded].

	hand showTemporaryCursor: cursorForm hotSpotOffset: offset.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/13/2009 15:26'!
cutTool

	| hand cursorForm offset |
	self paintingInProgress ifTrue: [^ self beep].
	hand _ self world activeHand.
	hand toolType: 'CutTool'.

	cursorForm _ ScratchFrameMorph skinAt: #cutCursor.
	offset _ 8@8.

	ScratchFrameMorph isXO ifTrue: [
		cursorForm _ cursorForm magnifyBy: 1.5.
		offset _ (offset * 1.5) rounded].

	hand showTemporaryCursor: cursorForm hotSpotOffset: offset.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/24/2004 18:58'!
normalTool

	self paintingInProgress ifTrue: [^ self beep].
	self world activeHand toolType: nil.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jens 2/24/2011 22:14'!
undoTool

	| m newOwner oldName |
	self paintingInProgress ifTrue: [^ self beep].
	Clipboard ifNil: [^ self beep].
	self activeHand toolType: nil.
	m _ Clipboard fullCopy.
	((m isKindOf: BlockMorph) and: [m isCustomBlock and: [m definition isNil]])
		ifTrue: [^ self beep].
	"Reset clipboard to empty since an undo just happened"
	
	(m isKindOf: BlockMorph) ifTrue: [
		newOwner _ viewerPane target.
		newOwner ifNotNil: [m newScriptOwner: newOwner].
		(viewerPane currentCategory = 'variables') ifTrue: [
			"update 'variables' category if it is showing"
			viewerPane currentCategory: 'variables']].

	(m isKindOf: ScratchSpriteMorph) ifTrue: [  "sprite; add to stage"
		m filterReset; show.
		m objName: Clipboard objName.
		Clipboard _ nil.
		oldName _ m objName.
		self addAndView: m.
		m objName: oldName.
		^ self].

	"blocks or anything else: attach to hand"
	self activeHand attachMorph: m.
	Clipboard _ nil.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/13/2009 15:26'!
zoomInTool

	| hand cursorForm offset |
	self paintingInProgress ifTrue: [^ self beep].
	hand _ self world activeHand.
	hand toolType: 'ZoomInTool'.

	cursorForm _ ScratchFrameMorph skinAt: #zoomInCursor.
	offset _ 8@8.

	ScratchFrameMorph isXO ifTrue: [
		cursorForm _ cursorForm magnifyBy: 1.5.
		offset _ (offset * 1.5) rounded].

	hand showTemporaryCursor: cursorForm hotSpotOffset: offset.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/13/2009 15:26'!
zoomOutTool

	| hand cursorForm offset |
	self paintingInProgress ifTrue: [^ self beep].
	hand _ self world activeHand.
	hand toolType: 'ZoomOutTool'.

	cursorForm _ ScratchFrameMorph skinAt: #zoomOutCursor.
	offset _ 8@8.

	ScratchFrameMorph isXO ifTrue: [
		cursorForm _ cursorForm magnifyBy: 1.5.
		offset _ (offset * 1.5) rounded].

	hand showTemporaryCursor: cursorForm hotSpotOffset: offset.

! !


!ScratchFrameMorph methodsFor: 'private' stamp: 'jm 4/22/2009 09:37'!
enterQuarterModeIfSmallScreen

	(Display width >= 980) & (Display height >= 555) ifTrue: [^ self].
	viewMode = #normal ifTrue: [self enterQuarterMode].
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'ee 2/3/2009 13:26'!
fixProjectTitleMorphLayout
 
	| s truncated eWidth w |

	projectName ifNotNil: [
		s _  (self nameFromFileName: projectName).
		"trim project name to fit, if necessary"
		truncated _ false.
		eWidth _ (ScratchTranslator stringExtent: '...' font: projectTitleMorph font) x.
		w _ titlePane width - 100 - eWidth.
		[((ScratchTranslator stringExtent: s font: projectTitleMorph font) x) > w] whileTrue: [
			truncated _ true.
			s _ s copyFrom: 1 to: s size - 1].
		truncated ifTrue: [s _ s, '...'].
		projectTitleMorph contents: s].
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jm 1/4/2007 23:10'!
nextSurpriseCostumeName
	"Answer a surprise costume name or nil if there are no costumes."
	"Details: Shuffle the list of available costume names and return them one at a time. When there are none left, generate a new shuffle. This avoids repeats."

	| dir ext |
	(shuffledCostumeNames isNil or:
	 [shuffledCostumeNames size = 0]) ifTrue: [
		shuffledCostumeNames _ OrderedCollection new: 1000.
		dir _ (FileDirectory default directoryNamed: 'Media') directoryNamed: 'Costumes'.
		dir allFileNamesDo: [:fn |
			(fn includesSubString: 'Letters') ifFalse: [
				ext _ (FileDirectory extensionFor: fn) asLowercase.
				((ext size > 0) and: [#(gif png jpg) includes: ext])
					ifTrue: [shuffledCostumeNames add: fn]]]].

	shuffledCostumeNames _ shuffledCostumeNames shuffledBy: Random new.
	shuffledCostumeNames size = 0
		ifTrue: [^ nil]
		ifFalse: [^ shuffledCostumeNames removeFirst].
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 7/27/2010 21:42'!
projectIsEmpty
	"Answer true if the current project has no scripts, no variables, no special costumes or sounds, and at most a single sprite."

	| allScriptables defaultCostumes defaultSnds |
	"at most one sprite in workpane?"
	workPane submorphs size > 1 ifTrue: [^ false].
	workPane submorphs size = 1 ifTrue: [
		(workPane submorphs first isKindOf: ScratchSpriteMorph) ifFalse: [^ false]].

	allScriptables _ workPane submorphs copyWith: workPane.
	defaultCostumes _ Set
		with: ScriptableScratchMorph defaultBackgroundForm.
	defaultSnds _ Set
		with: ScriptableScratchMorph popSound
		with: ScriptableScratchMorph meowSound.

	ScratchFrameMorph defaultSprite ifNotNil: [
		ScratchFrameMorph defaultSprite media do: [:media |
			media isImage ifTrue: [defaultCostumes add: media form].
			media isSound ifTrue: [defaultSnds add: media sound]]].

	allScriptables do: [:m |
		m customBlocks ifNotNil: [m customBlocks size > 0 ifTrue: [^ false]].  "any custom blocks?"
		m blocksBin submorphs size > 0 ifTrue: [^ false].  "any stacks?"
		m varNames size > 1 ifTrue: [^ false].  "any variables?"
		m media do: [:media |
			(media isImage and: [(defaultCostumes includes: media form) not]) ifTrue: [^ false].
			(media isSound and: [(defaultSnds includes: media sound) not]) ifTrue: [^ false]]].

	^ true
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'ee 11/4/2008 11:46'!
rebuildUIForNewLanguage
	"Rebuild my UI after the language or font has been changed."

	World fullRepaintNeeded.
	viewerPane rebuildCategorySelectors.
	self updatePanes.
	self
		view: scriptsPane target
		tab: scriptsPane tabPane currentTab
		category: viewerPane currentCategory.

! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 2/1/2010 01:25'!
recordLanguage: aString
	"Record my language in the settings file."
	"ScratchFrameMorph new recordLanguage: 'English'"

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'language='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('Language=', aString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 6/30/2010 23:27'!
setLanguage: aString
	"Set my language and update my blocks."

	| tempJustSaved |

	self closeDialogBoxes.

	'updating...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((workPane allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 2
		during: [:bar | | i | i _ 0.

	tempJustSaved _ justSaved.
	(workPane submorphs copyWith: workPane) do: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertStacksToTuples]].

	ScratchTranslator setLanguage: (ScratchTranslator isoCodeForName: aString).
	viewerPane rebuildCategorySelectors.

	(workPane submorphs copyWith: workPane) do: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertTuplesToStacks]].
	self updatePanes.
	self
		view: scriptsPane target
		tab: scriptsPane tabPane currentTab
		category: viewerPane currentCategory.
	justSaved _ tempJustSaved].
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 11/19/2009 21:45'!
updatePanes

	| p |
	menuPanel delete.
	self createMenuPanel.

	toolbarPanel delete.
	self createToolbar.

	viewModeButtonsPanel delete.
	self createViewModeButtonsPanel.

	stageButtonsPanel delete.
	self createStageButtonsPanel.
	titlePane addMorph: stageButtonsPanel.

	scriptsPane tabPane delete.
	scriptsPane createTabPane.

	readoutPane delete.
	self createReadoutPane.

	workPane sensorBoard owner
		ifNil: [p _ nil]
		ifNotNil: [p _ workPane sensorBoard position].

	workPane sensorBoard addReadouts.
	p ifNotNil:[
		self showSensorBoard.
		workPane sensorBoard position: p].

	libraryPane clearLibrary.

	self scratchWatchers do: [:w | w languageChanged].
	self listWatchers do: [:w | w fixLayoutForNewLanguage].

	World startSteppingSubmorphsOf: self.
	self fixLayout.
	scriptsPane fixLayout.
	self updateViewModeButtons.
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 8/14/2009 02:10'!
updateProjectName
	"Update the project name display in the Scratch title bar."

	| s |
	projectName ifNil: [projectName _ ''].
	projectTitleMorph contents: (self nameFromFileName: projectName).

	projectTitleMorph contents size > 0
		ifTrue: [s _ projectTitleMorph contents, '- BYOB']
		ifFalse: [s _ 'BYOB ', Version].
	ScratchPlugin primSetWindowTitle: s.

	self fixLayout.
! !


!ScratchFrameMorph methodsFor: 'buttonActions' stamp: 'jens 5/5/2010 00:09'!
developersMenu
	"Present the Scratch developer's menu."

	| menu |

	self isDevelopmentMode ifFalse: [^ self].

	self world activeHand toolType: nil.
	Cursor normal show.
	menu _ CustomMenu new.

	fillScreenFlag
		ifTrue: [menu add: 'turn fill screen off' action: #fillScreenOff]
		ifFalse: [menu add: 'turn fill screen on' action: #fillScreenOn].
	UseErrorCatcher
		ifTrue: [menu add: 'turn error catching off' action: #toggleErrorCatcher]
		ifFalse: [menu add: 'turn error catching on' action: #toggleErrorCatcher].

	menu addLine.
	menu add: 'save image for end-user' action: #saveImageForEndUser.
 
	menu invokeOn: self.
! !

!ScratchFrameMorph methodsFor: 'buttonActions' stamp: 'jens 9/2/2010 14:41'!
newScratchProject
	"Make a new, blank Scratch project."

	| response newProject sprite |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	(justSaved or: [self projectIsEmpty]) ifFalse: [
		"ask the user if they want to save the current project"
		response _ DialogBoxMorph askWithCancel: 'Save the current project?'.
		response = #cancelled ifTrue: [^ self].
		response ifTrue: [self saveScratchProjectNoDialog.
			justSaved ifFalse: [^ self]]].

	projectDirectory _ ScratchFileChooserDialog getDefaultFolderForType: #project.
	projectName _ ''.
	projectInfo _ Dictionary new.

	newProject _ ScratchStageMorph new.
	sprite _ ScratchFrameMorph defaultSprite fullCopy.
	sprite position: (240@180) - sprite extent.
	newProject addMorph: sprite.
	self installNewProject: newProject.
	sprite installGlobalBlocks.

	ScriptableScratchMorph decodeAsByob. "remember we created this project in byob and not in Scratch"

	self initializeWatcherPositions.
	blockEditors _ Set new.
	justSaved _ true.
! !


!ScratchFrameMorph methodsFor: 'presentation mode' stamp: 'jens 6/10/2010 22:20'!
closeDialogBoxes
	"Close all dialog boxes, including PaintEditors and SoundRecorders."

	World submorphs do: [:m |
		(m isKindOf: DialogBoxMorph) ifTrue: [m cancelled; delete]].

	blockEditors _ Set new
! !


!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 22:01'!
addBlockEditor: aBlockEditor
	blockEditors add: aBlockEditor! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 01:32'!
blockContrastOff

	BlockMorph contrastOff.
	self refreshBlocks.
	self recordBlockContrast: 0! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 01:31'!
blockContrastStrong

	BlockMorph contrastStrong.
	self refreshBlocks.
	self recordBlockContrast: 1! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 21:18'!
blockEditors
	^blockEditors! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/28/2010 21:33'!
checkBoxLabelled: aString marked: aBool width: anInt
	"answer a form consisting of a checkbox and a label - used for the EDIT menu in BYOB"

	| box label pic line cnts |
	aBool
		ifTrue: [pic _ ScratchFrameMorph skinAt: #watcherButtonPressed]
		ifFalse: [pic _ ScratchFrameMorph skinAt: #watcherButton].
	box _ ImageMorph new form: pic. 
	
	ScratchTranslator useSqueakRendering
		ifTrue: [cnts _ ' ', aString localized asMacRoman]
		ifFalse: [cnts _ ' ' asUTF8, aString localized].

	label _ StringMorph contents: cnts font: Preferences standardMenuFont.
	line _ Morph new color: Color transparent.
	line height: (box height max: label height).
	line width: (box width + label width max: anInt).
	box left: line left.
	box top: line top + (line height - box height // 2).
	label left: box right.
	label top: line top + (line height - label height // 2).
	line addMorph: box.
	line addMorph: label.
	^ line imageForm! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/24/2011 20:10'!
clearAllVariables

	workPane clearAllVariables! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/15/2010 01:32'!
closeBlockEditor
	blockEditors do:[:each | each yes "no"].
	blockEditors _ Set new.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/11/2011 01:01'!
editBlockDefinition: aCustomBlockDefinition for: aScriptableScratchMorph

	| editor def id |
	"for prototypal inheritance:"
	id _ aCustomBlockDefinition id.
	aScriptableScratchMorph ensureOwnBlockExists: aCustomBlockDefinition.
	def _ aScriptableScratchMorph customBlocks detect: [:eachDef | eachDef id = id]
		ifNone: [^ self ].
	(self notEditingBlockDefinition: def) ifFalse: [^self].
	def fixBlockVarReporters.
	editor 	_ BlockEditorFrameMorph new
		withButtonsForYes: false no: false okay: true cancel: true;
		receiver: aScriptableScratchMorph;
		definition: def.
	blockEditors add: editor.
	editor getUserResponse.
	blockEditors remove: editor ifAbsent: []! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/26/2010 21:06'!
isDevelopmentMode

	| args arg |

	Preferences noviceMode
		ifTrue: [
			args _ OrderedCollection new.
			2 to: 10 do: [:i |
				arg _ Smalltalk getSystemAttribute: i.
				arg ifNotNil: [args add: arg ]].
			args detect: [:each |
				each asLowercase = 'dev'] ifNone: [^false].
			^true]
		ifFalse: [^ true]
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/18/2010 02:16'!
isTurbo
	^ ScratchProcess blockHighlightMSecs < 1! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 02:06'!
keepSpritesOnStage: anInt
	| bool |

	bool _ {false. true} at: anInt + 1.
	ScriptableScratchMorph keepOnStage: bool! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 22:23'!
notEditingBlock
	blockEditors size = 0 ifTrue: [^true].
	(DialogBoxMorph ask: 'Close open block editor(s)?') ifFalse: [^false].
	blockEditors do:[:each | each no].
	blockEditors _ Set new.
	^true! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/30/2010 00:44'!
notEditingBlockDefinition: aCustomBlockDefinition
	| editor |
	blockEditors size = 0 ifTrue: [^true].
	editor _ blockEditors detect: [:each | 
		each definition id = aCustomBlockDefinition id] 
		ifNone: [nil].
	editor ifNil: [^true].
	editor comeToFront.
	^ false! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/10/2010 01:36'!
openBYOBManual
	
	| manual |
	manual _ 'BYOBManual.pdf'.

	Smalltalk isMacOSX
			ifTrue: [ScratchPlugin primOpenURL: 'file://', (FileDirectory default pathName, FileDirectory slash, manual) encodeForHTTP]
			ifFalse: [ScratchPlugin primOpenURL: FileDirectory default pathName, FileDirectory slash, manual]
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 23:52'!
purgeBlockEditors
	blockEditors _ blockEditors reject: [:each | 
		each isInWorld not]! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/3/2010 00:30'!
randomProjectName
	| dir projects |
"	dir _ ScratchFileChooserDialog getDefaultFolderForType: #project."

	(FileDirectory default directoryExists: 'Projects') 
		ifTrue: [ dir _ FileDirectory default directoryNamed: 'Projects']
		ifFalse: [ Smalltalk quitPrimitive ].

	projects _ dir fileNames
				select: [:fn | (fn asLowercase endsWith: '.sb')
						or: [(fn asLowercase endsWith: '.scratch')
						or: [fn asLowercase endsWith: '.ypr']]].
	projects size > 0 ifTrue: [^ dir fullNameFor: (projects asArray at: Random new next * projects size + 1)].
	^ nil! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 01:31'!
recordBlockContrast: anInteger
	"Record my language in the settings file."
	"ScratchFrameMorph new recordLanguage: 'English'"

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'blockcontrast='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('BlockContrast=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 01:35'!
recordKeepOnStage: anInteger
	"Record a setting in the settings file."

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'keepspritesonstage='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('KeepSpritesOnStage=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/2/2010 23:25'!
recordScopeContrast: anInteger
	"Record a setting in the settings file."

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'scopecontrast='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('ScopeContrast=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/9/2010 22:29'!
recordThreadSafeMode: anInteger
	"Record a setting in the settings file."

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'threadsafemode='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('ThreadSafeMode=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/13/2010 23:06'!
recordTranslucentDragging: anInteger
	"Record a setting in the settings file."

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'translucentdragging='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('TranslucentDragging=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/30/2010 23:27'!
refreshBlocks

	'updating...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((workPane allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 3
		during: [:bar | | i | i _ 0.

	(workPane submorphs copyWith: workPane) do: [:m |
	(m isKindOf: ScriptableScratchMorph) ifTrue: [
		i _ i + 1. bar value: i.
		m convertStacksToTuples]].

	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertTuplesToDefinitions]].

	(workPane submorphs copyWith: workPane) do: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertTuplesToStacks]].
	self updatePanes.
	self
		view: scriptsPane target
		tab: scriptsPane tabPane currentTab
		category: viewerPane currentCategory].
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 21:18'!
removeBlockEditor: aBlockEditor
	blockEditors remove: aBlockEditor! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/16/2009 23:53'!
shareSprite

	scriptsPane target shareObject.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/19/2010 03:38'!
showPause

	pauseButton
		onForm: (ScratchFrameMorph skinAt: 'pauseButtonGrayPressed' asSymbol)
		offForm: (ScratchFrameMorph skinAt: 'pauseButtonGray'asSymbol)
		overForm: (ScratchFrameMorph skinAt: 'pauseButtonGrayPressed' asSymbol)
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/19/2010 03:39'!
showPlay

	pauseButton
		onForm: (ScratchFrameMorph skinAt: 'playButtonGrayPressed' asSymbol)
		offForm: (ScratchFrameMorph skinAt: 'playButtonGray'asSymbol)
		overForm: (ScratchFrameMorph skinAt: 'playButtonGrayPressed' asSymbol)
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 4/21/2010 00:37'!
toggleKeepSpritesOnStage
	| choice |
	ScriptableScratchMorph keepOnStage: ScriptableScratchMorph keepOnStage not.
	ScriptableScratchMorph keepOnStage
		ifTrue: [choice _ 1]
		ifFalse: [choice _ 0].
	self recordKeepOnStage: choice! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/19/2010 03:39'!
togglePause
	workPane togglePause.
	workPane isPaused
		ifTrue: [self showPlay]
		ifFalse: [self showPause]
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/2/2010 23:29'!
toggleScopeContrast
	| choice |
	VariableFrame scopeContrast: VariableFrame scopeContrast not.
	VariableFrame scopeContrast
		ifTrue: [choice _ 1]
		ifFalse: [choice _ 0].
	self refreshBlocks.
	self recordScopeContrast: choice! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/2/2010 23:22'!
toggleShowMotorBlocks

	workPane showMotorBlocks
		ifTrue: [self hideMotorBlocks]
		ifFalse: [self showMotorBlocks]! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/9/2010 22:36'!
toggleThreadSafeMode
	| choice |
	EventHatMorph threadSafeMode: EventHatMorph threadSafeMode not.
	EventHatMorph threadSafeMode
		ifTrue: [choice _ 1]
		ifFalse: [choice _ 0].
	self recordThreadSafeMode: choice! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/13/2010 23:09'!
toggleTranslucentDragging
	| choice |
	HandMorph translucentWhenDragging: HandMorph translucentWhenDragging not.
	HandMorph translucentWhenDragging
		ifTrue: [choice _ 1]
		ifFalse: [choice _ 0].
	self recordTranslucentDragging: choice! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/18/2010 02:17'!
toggleTurboMode

	self isTurbo ifTrue: [
		^ ScratchProcess blockHighlightMSecs: 1].
	ScratchProcess blockHighlightMSecs: 0! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/2/2010 22:58'!
toggleZebraColoring

	BlockMorph contrast = #off
		ifTrue: [self blockContrastStrong]
		ifFalse: [self blockContrastOff]! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/17/2009 00:44'!
undoLastDrop

	scriptsPane currentCategory: 'Scripts'.
	scriptsPane target blocksBin undoLastDrop! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/5/2010 10:44'!
unloadAllUnusedCustomBlocks

	workPane unloadAllUnusedCustomBlocks! !


!ScratchFrameMorph methodsFor: 'compiler' stamp: 'jens 7/7/2010 03:09'!
makeExe

	| argStr delim |
	justSaved ifFalse: [ 
		self saveScratchProject ].
	delim _ FileDirectory activeDirectoryClass pathNameDelimiter asString.
	argStr _ (ScratchFileChooserDialog getLastFolderForType: #project) pathName
				, delim
				, projectName.
	Smalltalk isWindows ifTrue: [
		^ SystemPlugin primLaunch: 'mak\pack ', argStr ].
	SystemPlugin primLaunch: 
		'"'
		, FileDirectory activeDirectoryClass default pathName
		, delim
		, 'compile.sh" '
		, '"'
		, argStr
		, '"'
! !


!ScratchFrameMorph methodsFor: 'version control' stamp: 'JM 11/9/2011 17:12'!
versionControlExport
	"Outputs all classes that have changed since the project start date to a directory that should be managed by an external revision control system."

	| dir date |

	dir _ self class versionControlDirectory.
	date _ self class versionControlStartDate.
	
	dir fileOutClassesChangedSince: date.	! !

!ScratchFrameMorph methodsFor: 'version control' stamp: 'JM 11/9/2011 17:12'!
versionControlImport
	"Updates the classes in the Squeak VM by importing them from a 'Classes' directory that should be managed by your revision control system."

	self class versionControlDirectory fileInContents! !


!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 2/7/2011 23:35'!
aboutScratch

	| dialogBox |
	dialogBox _ DialogBoxMorph new
		title: 'About BYOB';
		withButtonsForYes: false no: false okay: true cancel: false.
	dialogBox
		message: 'BYOB ', Version, '
Build Your Own Blocks - an extension to Scratch

Copyright 2011 Brian Harvey and Jens Moenig
bh@cs.berkeley.edu, jens@moenig.org
All rights reserved

Based on SCRATCH
Copyright (C)  2009 Massachusetts Institute of Technology.
All rights reserved.

Scratch is developed by the Lifelong Kindergarten Group at the MIT Media Lab,
with support from the National Science Foundation, Microsoft, Intel,
Nokia, and MIT Media Lab research consortia.

For more information, see http://byob.berkeley.edu
http://scratch.mit.edu and http://chirp.scratchr.org.
for license, see license.txt in folder.

Please report bugs to http://byobugs.com.
'
		font: (ScratchFrameMorph getFont: #AboutScratch).

	dialogBox setBalloonText: ((CommandBlockMorph new color: (ScriptableScratchMorph blockColorFor: 'control'); commandSpec: 'B Y %r B')) asLambda displayForm.

	dialogBox getUserResponse.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jens 5/3/2010 02:20'!
addAndView: aSpriteMorph
	"Add given morph to the work pane and view it."

	| pos i p |
	aSpriteMorph center: workPane center.
	pos _ self scratchObjects collect: [:o | o referencePosition].
	i _ 0.
	[pos includes: (p _ (10 * i) asPoint)] whileTrue: [i _ i + 1].
	workPane addMorphFront: aSpriteMorph.
	aSpriteMorph objName: aSpriteMorph nextInstanceName.
	aSpriteMorph referencePosition: p.

	aSpriteMorph installGlobalBlocks.

	workPane customBlocks ifNotNil: [
		workPane customBlocks do: [:eachDef |
			eachDef isGlobal ifTrue: [
				aSpriteMorph ensureCustomBlockExists: eachDef ]]].

	aSpriteMorph startStepping.
	workPane sprites addLast: aSpriteMorph.
	self view: aSpriteMorph tab: 'Scripts' category: 'motion'.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 22:01'!
addBlockEditor: aBlockEditor
	blockEditors add: aBlockEditor! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 8/13/2009 22:45'!
addServerCommandsTo: menu
	"Add Scratch server commands to the given menu."

	| disable endCmd |
	disable _ false.  "make this true to disable this feature"
	disable ifTrue: [^ self].

	menu addLine.
	(workPane scratchServer notNil and:
	 [workPane scratchServer sessionInProgress])
		ifTrue: [
			menu add: 'Show IP Address' action: #showNetworkAddress.
			endCmd _ workPane scratchServer isHosting
				ifTrue: ['Stop Hosting Mesh']
				ifFalse: ['Leave Mesh'].
			menu add: endCmd action: #exitScratchSession]
		ifFalse: [
			menu add: 'Host Mesh' action: #startHostingScratchSession.
			menu add: 'Join Mesh' action: #joinScratchSession].

! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 5/3/2010 02:36'!
addShortcutButtonsTo: rowMorph

	| buttonSpecs b |

	self class disableSharing.

	buttonSpecs _ #(
		"name		tool tip				selector"
		(language	'Set language'		languageMenu:)
		(save		'Save this project'	saveScratchProjectNoDialog)
"		(share		'Share this project'	share)"
	).
	AllowSharing ifFalse: [
		buttonSpecs _ buttonSpecs select: [:spec | spec first ~= #share]].

	buttonSpecs do: [:spec |
		b _ ToggleButton
			onForm: (ScratchFrameMorph skinAt: (spec at: 1), 'ButtonOver')
			offForm: (ScratchFrameMorph skinAt: (spec at: 1), 'Button')
			overForm: (ScratchFrameMorph skinAt: (spec at: 1), 'ButtonOver').
		b
			target: self;
			actionSelector: (spec at: 3);
			setBalloonText: (spec at: 2) localized;
			actWhen: #buttonUp;
			isMomentary: true.
		
		('language' = (spec at: 1)) ifTrue: [  "language special case"
			b arguments: (Array with: b)].

		('save' = (spec at: 1)) ifTrue: [  "bigger spacer"
			rowMorph addMorphBack: (Morph new extent: (10@5); color: Color transparent)].

		('share' = (spec at: 1)) ifTrue: [  "add spacer between buttons"
			rowMorph addMorphBack: (Morph new extent: (8@5); color: Color transparent)].
		rowMorph addMorphBack: b].

	rowMorph addMorphBack: (Morph new extent: (15@5); color: Color transparent).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 5/3/2010 22:29'!
addSpriteMorph

	| result f m el |
	self world activeHand toolType: nil.
	self paintingInProgress ifTrue: [^ self beep].

	result _ ScratchFileChooserDialog chooseSpriteCostumeFor: self.
	result = #cancelled ifTrue: [^ self].
	((result asLowercase endsWith: '.sprite') | (result asLowercase endsWith: '.ysp'))
		ifTrue: [^ self importSpriteOrProject: result].

	[f _ Form fromFileNamed: result] ifError: [^ self].
	el _ ImageMedia new form: (ScratchFrameMorph scaledFormForPaintEditor: f).
	m _ ScratchSpriteMorph new soleCostume: el.
	el mediaName: (m unusedMediaNameFromBaseName: (FileDirectory localNameFor: result)).
	self addAndView: m.
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 2/27/2009 11:31'!
allBlocksString

	| s stacks |
	s _ WriteStream on: (String new: 10000).
	((Array with: workPane), self scratchObjects) do: [:obj |
		stacks _ obj blocksBin submorphs select: [:m | m isKindOf: BlockMorph].
		stacks size > 0 ifTrue: [
			s nextPutAll: 'All stacks for ', obj objName, ':'; cr; cr.
			stacks do: [:blocks | self printTupleList: blocks tupleSequence on: s. s cr; cr].
			s cr]].

	^ s contents
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/16/2007 19:12'!
allProjectMedia
	"Answer a collection of all media items in the current project."

	| result |
	result _ OrderedCollection new.
	(workPane submorphs copyWith: workPane) do: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			result addAll: m media]].
	^ result
! !

!ScratchFrameMorph methodsFor: 'drawing' stamp: 'jm 12/9/2008 18:27'!
areasRemainingToFill: aRectangle
	"Drawing optimization. Since I completely fill my bounds with opaque pixels, this method tells Morphic that it isn't necessary to draw any morphs covered by me."
	
	^ aRectangle areasOutside: self bounds
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:34'!
author

	^ author
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:35'!
author: aString
	"This is the author used in notes and save as, which is different from the user name used when uploading to the website."

	author _ aString.

! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 01:32'!
blockContrastOff

	BlockMorph contrastOff.
	self refreshBlocks.
	self recordBlockContrast: 0! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 01:31'!
blockContrastStrong

	BlockMorph contrastStrong.
	self refreshBlocks.
	self recordBlockContrast: 1! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 21:18'!
blockEditors
	^blockEditors! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/17/2007 12:29'!
canonicalizeImagesQuality: qualityOrNil saveOriginal: saveFlag

	| count unique match |
	count _ 0.
	unique _ OrderedCollection new: 1000.
	self allProjectMedia do: [:m |
		m isImage ifTrue: [
			match _ unique detect: [:u | u form equals: m form] ifNone: [nil].
			match
				ifNil: [
					qualityOrNil ifNotNil: [
						(m jpegCompressIfPossibleQuality: qualityOrNil saveOriginal: saveFlag)
							ifTrue: [count _ count + 1]].
					unique add: m]
				ifNotNil: [
					m shareFormWith: match]]].
	^ count
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/17/2007 13:47'!
canonicalizeSoundsBits: bitsPerSample saveOriginal: saveFlag

	| count unique match |
	count _ 0.
	unique _ OrderedCollection new: 1000.
	self allProjectMedia do: [:m |
		m isSound ifTrue: [
			match _ unique detect: [:u | u sound equals: m sound] ifNone: [nil].
			match
				ifNil: [
					bitsPerSample ifNotNil: [
						(m compressBitsPerSample: bitsPerSample saveOriginal: saveFlag)
							ifTrue: [count _ count + 1]].
					unique add: m]
				ifNotNil: [
					m shareSoundWith: match]]].

	bitsPerSample notNil & saveFlag not ifTrue: [
		"uncompress compressed sounds so the result can be heard"
		self allProjectMedia do: [:m | m isSound ifTrue: [ m decompress]]].

	^ count
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/28/2010 21:33'!
checkBoxLabelled: aString marked: aBool width: anInt
	"answer a form consisting of a checkbox and a label - used for the EDIT menu in BYOB"

	| box label pic line cnts |
	aBool
		ifTrue: [pic _ ScratchFrameMorph skinAt: #watcherButtonPressed]
		ifFalse: [pic _ ScratchFrameMorph skinAt: #watcherButton].
	box _ ImageMorph new form: pic. 
	
	ScratchTranslator useSqueakRendering
		ifTrue: [cnts _ ' ', aString localized asMacRoman]
		ifFalse: [cnts _ ' ' asUTF8, aString localized].

	label _ StringMorph contents: cnts font: Preferences standardMenuFont.
	line _ Morph new color: Color transparent.
	line height: (box height max: label height).
	line width: (box width + label width max: anInt).
	box left: line left.
	box top: line top + (line height - box height // 2).
	label left: box right.
	label top: line top + (line height - label height // 2).
	line addMorph: box.
	line addMorph: label.
	^ line imageForm! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 6/25/2009 17:13'!
checkForWeDo
	"Check for WeDo, and show motor blocks if it is found."
	"Note: Polling on Vista can take several hundred milliseconds, so reduce polling to just a few times per minute."

	| now |
	now _ Time millisecondClockValue.
	(lastWeDoPoll isNil or: [lastWeDoPoll > now]) ifTrue: [lastWeDoPoll _ 0].
	((now - lastWeDoPoll) < 15000) ifTrue: [^ self]. "don't poll too often"
	lastWeDoPoll _ now.
	WeDoPlugin readInputs.
	WeDoPlugin isOpen ifTrue: [
		workPane showMotorBlocks ifTrue: [^ self].
		self showMotorBlocks.
		WeDoPlugin readInputs].
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/24/2011 20:10'!
clearAllVariables

	workPane clearAllVariables! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jm 6/2/2009 18:54'!
clearStage

	self stopAll.
	projectDirectory _ ScratchFileChooserDialog getDefaultFolderForType: #project.
	projectName _ ''.
	projectInfo _ Dictionary new.

	self installNewProject: ScratchStageMorph new.
	self initializeWatcherPositions.
	justSaved _ true.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/15/2010 01:32'!
closeBlockEditor
	blockEditors do:[:each | each yes "no"].
	blockEditors _ Set new.
! !

!ScratchFrameMorph methodsFor: 'presentation mode' stamp: 'jens 6/10/2010 22:20'!
closeDialogBoxes
	"Close all dialog boxes, including PaintEditors and SoundRecorders."

	World submorphs do: [:m |
		(m isKindOf: DialogBoxMorph) ifTrue: [m cancelled; delete]].

	blockEditors _ Set new
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'ee 7/1/2008 11:09'!
closeMediaEditorsAndDialogs
	"Close any open paint or sound editors, asking the user first to avoid losing edits. Answer true if all are closed."

	| mList mHasCancel |
	mList _ PaintFrame allInstances select: [:m | m isInWorld].
	mList size > 0 ifTrue: [
		(DialogBoxMorph ask: 'Close paint editor?') ifFalse: [^ false].
		mList do: [:m | m cancelled; delete].
		paintingInProgress _ false].

	mList _ ScratchSoundRecorderDialogMorph allInstances select: [:m | m isInWorld].
	mList size > 0 ifTrue: [
		(DialogBoxMorph ask: 'Close sound recorder?') ifFalse: [^ false].
		mList do: [:m | m cancelled; delete]].

	mList _ DialogBoxMorph allInstances select: [:m | m isInWorld].
	mList size > 0 ifTrue: [
		(DialogBoxMorph ask: 'Close dialog?') ifFalse: [^ false].
		mList do: [:m |
			mHasCancel _ false.
			m buttons do: [:b |
				b action = #cancelled ifTrue: [mHasCancel _ true]].
			mHasCancel
				ifTrue: [m cancelled; delete]
				ifFalse: [m no; delete]]].

	DialogBoxMorph subclassesDo: [:c |
		mList _ c allInstances select: [:m | m isInWorld].
		mList size > 0 ifTrue: [
			(DialogBoxMorph ask: 'Close dialog?') ifFalse: [^ false].
			mList do: [:m |
				mHasCancel _ false.
				m buttons do: [:b |
					b action = #cancelled ifTrue: [mHasCancel _ true]].
				mHasCancel
					ifTrue: [m cancelled; delete]
					ifFalse: [m no; delete]]]].

	"subclass of a subclass of DialogBoxMorph"
	mList _ NewVariableDialog allInstances select: [:m | m isInWorld].
	mList size > 0 ifTrue: [
		(DialogBoxMorph ask: 'Close dialog?') ifFalse: [^ false].
		mList do: [:m | m cancelled; delete]].

	^ true
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 7/9/2008 18:19'!
compressImages

	| s q count |
	s _ StringDialog askWithCancel: 'JPEG Quality (10-100)?' initialAnswer: '70'.
	s size = 0 ifTrue: [^ self].
	q _ [s asNumber] ifError: [nil].
	q ifNil: [^ self].
	q _ (q within: 10 and: 101) truncated.

	q > 100 ifTrue: [q _ nil].  "just canonicalize, don't compress"
	count _ self canonicalizeImagesQuality: q saveOriginal: false.

	scriptsPane categoryChanged: 'Costumes'.
	DialogBoxMorph inform: 'Images compressed' withDetails: count printString.
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/25/2007 14:35'!
compressMediaForUpload
	"Compress my media prior to uploading this project."

	self canonicalizeSoundsBits: 4 saveOriginal: true.
	self canonicalizeImagesQuality: 90 saveOriginal: true.

! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 8/8/2008 13:16'!
compressSounds

	| menu bitsPerSample count |
	menu _ CustomMenu new title: 'Sound quality:'.
	menu add: 'High (biggest)' action: 5.
	menu add: 'Normal' action: 4.
	menu add: 'Low' action: 3.
	menu add: 'Lowest (smallest)' action: 2.
	menu addLine.
	menu add: 'cancel' action: nil.
	menu localize.
	(bitsPerSample _ menu startUp) ifNil: [^ self].

	count _ self canonicalizeSoundsBits: bitsPerSample saveOriginal: false.
	scriptsPane categoryChanged: 'Sounds'.
	DialogBoxMorph inform: 'Sounds compressed' withDetails: count printString.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/13/2009 15:26'!
copyTool

	| hand cursorForm offset |
	self paintingInProgress ifTrue: [^ self beep].
	hand _ self world activeHand.
	hand toolType: 'CopyTool'.

	cursorForm _ ScratchFrameMorph skinAt: #copyCursor.
	offset _ 8@13.

	ScratchFrameMorph isXO ifTrue: [
		cursorForm _ cursorForm magnifyBy: 1.5.
		offset _ (offset * 1.5) rounded].

	hand showTemporaryCursor: cursorForm hotSpotOffset: offset.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'ee 1/27/2009 16:44'!
createBasicPanes
	"Create and add my palette (viewer), script editor, stage, and library panes."

	topPane _ ImageFrameMorph new initFromForm: (ScratchFrameMorph skinAt: 'topPane').
	viewerPane _ ScratchViewerMorph new rebuildCategorySelectors.	
	scriptsPane _ ScratchScriptEditorMorph new.
	stageFrame _ ImageFrameMorph new initFromForm: (ScratchFrameMorph skinAt: 'stagePane').
	titlePane _ ImageFrameMorph new initFromForm: (ScratchFrameMorph skinAt: 'titlePane').
	workPane _ ScratchStageMorph new extent: WorkpaneExtent.
	libraryPane _ ScratchLibraryMorph new.

	"make panes sticky so clicking on them doesn't pick up entire frame"
	self
		addMorph: (topPane isSticky: true);
		addMorph: (viewerPane isSticky: true);
		addMorph: (scriptsPane isSticky: true);
		addMorph: (stageFrame isSticky: true);
		addMorph: (workPane isSticky: true);
		addMorph: (titlePane isSticky: true);
		addMorph: (libraryPane isSticky: true).

	self createReadoutPane.
	workPane comeToFront.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'ee 1/27/2009 13:21'!
createLogo
	"Create and the Scratch logo."

	logoMorph _ SketchMorph withForm: (ScratchFrameMorph skinAt: #scratchLogo).
	logoMorph position: topPane position + (12@8).
	topPane addMorph: logoMorph.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jens 8/16/2009 23:46'!
createMenuPanel
	"Create and add a panel containing the menus and close button."

	| menuSpecs m |
	"create panel"
	menuPanel _ AlignmentMorph new
		color: Color transparent;
		centering: #center;
		inset: 0;
		height: 0.	"will grow as needed"

	self addShortcutButtonsTo: menuPanel.

	"menuSpecs defines the menus"
	menuSpecs _ #(
		"name			selector"
		(File			fileMenu:)
		(Edit			editMenu:)
		(Share			shareMenu:)
		(Help			helpMenu:)
	).

	menuSpecs do: [:spec |
		m _ ScratchMenuTitleMorph new
			contents: (spec at: 1) localized;
			target: self selector: (spec at: 2).
		menuPanel addMorphBack: m.
		#helpMenu: = (spec at: 2) ifFalse: [
			menuPanel addMorphBack: (Morph new color: Color transparent; extent: 12@5)]].

	topPane addMorph: menuPanel.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'ee 1/29/2009 14:21'!
createReadoutPane
	"Create and add my presentation mode button, new sprite buttongs, and mouse readout pane."

	| xyReadout |

	readoutPane _ ImageFrameMorph new initFromForm: (ScratchFrameMorph skinAt: #mouseReadoutPane).
	xyReadout _ self makeXYReadout.
	readoutPane	 addMorph: xyReadout.

	"make pane sticky so clicking on it doesn't pick up entire frame"
	self addMorph: (readoutPane isSticky: true).
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jens 5/19/2010 03:35'!
createStageButtonsPanel
	"Create and add a panel containing the project title, green flag, and stop buttons."

	| buttonSpecs bName button |
	"create panel"
	stageButtonsPanel _ AlignmentMorph new
		color: Color transparent;
		centering: #center;
		height: 20.

	projectTitleMorph _ StringMorph new
		forceUnicodeRendering: true;
		contents: '';
		font: (ScratchFrameMorph getFont: #FrameMorphProjectTitle).
	stageButtonsPanel
		addMorphBack: projectTitleMorph;
		addMorphBack: (AlignmentMorph newSpacer: Color transparent).

	"buttonSpecs defines the toolbar buttons; first is icon name, second is selector"
	buttonSpecs _ #(
		"name	selector		tool tip"
		(go		shoutGo		'Start green flag scripts')
		(pause	togglePause	'Pause/resume everything')
		(stop	stopAll		'Stop everything')).

	buttonSpecs do: [:spec |
		bName _ spec first.
		button _ ToggleButton
			onForm: (ScratchFrameMorph skinAt: (bName, 'ButtonGrayPressed') asSymbol)
			offForm: (ScratchFrameMorph skinAt: (bName, 'ButtonGray') asSymbol)
			overForm: (ScratchFrameMorph skinAt: (bName, 'ButtonGrayPressed') asSymbol).
		button
			target: self;
			actionSelector: (spec at: 2);
			isMomentary: true;
			setProperty: #balloonText toValue: (spec at: 3) localized.

		stageButtonsPanel addMorphBack: button.
		bName = #pause ifTrue: [
			pauseButton _ button].

		bName = #go ifTrue: [
			flagButton _ button.
			"stageButtonsPanel addMorphBack: (Morph new color: Color transparent; extent: 2@5)" "commented out if there is a pause button -jens" ]].

	titlePane addMorph: stageButtonsPanel.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jm 4/14/2009 08:59'!
createToolbar
	"Create and add the toolbar."

	| buttonSpecs bName button |
	toolbarPanel _ AlignmentMorph new
		hResizing: #shrinkWrap;
		vResizing: #shrinkWrap;
		color: Color transparent.
		
	buttonSpecs _ #(
		"name			selector"			"tooltip"
		(copy			copyTool		'Duplicate')
		(delete			cutTool			'Delete')
		(zoomIn 		zoomInTool		'Grow sprite')
		(zoomOut 		zoomOutTool		'Shrink sprite')
	).

	buttonSpecs do: [:spec |
		bName _ spec at: 1.
		button _ ToggleButton
			onForm: (ScratchFrameMorph skinAt: (bName, 'ButtonPressed') asSymbol)
			offForm: (ScratchFrameMorph skinAt: (bName, 'Button') asSymbol)
			overForm: (ScratchFrameMorph skinAt: (bName, 'ButtonOver') asSymbol).
		button
			target: self;
			actionSelector: (spec at: 2);
			isMomentary: true;
			setProperty: #balloonText toValue: (spec at: 3) localized.
		toolbarPanel addMorphBack: button].

	self addMorph: toolbarPanel.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jm 4/14/2009 08:57'!
createViewModeButtonsPanel

	| specs bName button |
	viewModeButtonsPanel _ AlignmentMorph newRow
		hResizing: #shrinkWrap;
		vResizing: #shrinkWrap;
		color: Color transparent.

	viewModeButtons _ OrderedCollection new.
	specs _ OrderedCollection new.
	specs add: #(quarter			enterQuarterMode		'Switch to small stage').
	specs add: #(normal			enterNormalMode		'Switch to full stage').
	specs add: #(presentation	enterPresentationMode	'Switch to presentation mode').

	specs do: [:spec |
		bName _ spec first.
		button _ ToggleButton new
			onForm: (ScratchFrameMorph skinAt: bName, 'ViewModeOn')
			offForm: (ScratchFrameMorph skinAt: bName, 'ViewMode')
			overForm: (ScratchFrameMorph skinAt: bName, 'ViewModeOver').
		button
			target: self;
			actionSelector: (spec at: 2);
			alphaOn: true;
			setProperty: #balloonText toValue: (spec at: 3) localized.
		viewModeButtonsPanel
			addMorphBack: button;
			addMorphBack: (Morph new extent: 1@5; color: Color transparent).
		viewModeButtons add: button].

	self addMorph: viewModeButtonsPanel.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/13/2009 15:26'!
cutTool

	| hand cursorForm offset |
	self paintingInProgress ifTrue: [^ self beep].
	hand _ self world activeHand.
	hand toolType: 'CutTool'.

	cursorForm _ ScratchFrameMorph skinAt: #cutCursor.
	offset _ 8@8.

	ScratchFrameMorph isXO ifTrue: [
		cursorForm _ cursorForm magnifyBy: 1.5.
		offset _ (offset * 1.5) rounded].

	hand showTemporaryCursor: cursorForm hotSpotOffset: offset.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 2/24/2004 18:57'!
delete

	World activeHand toolType: nil.
	super delete.
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 5/6/2008 18:13'!
deleteWatchersForSprite: aSprite
	"The given sprite is being deleted. Delete all watchers associated with it."

	aSprite lists do: [:m | m delete].

	workPane submorphsDo: [:m |
		(m isKindOf: WatcherMorph) ifTrue: [
			(m target = aSprite) ifTrue: [m delete]]].

	watcherPositions keys do: [:k | 
		(k at: 1) = aSprite ifTrue: [watcherPositions removeKey: k]].
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 12/1/2007 23:22'!
deleteWatchersForVar: varName ofSprite: aSprite
	"The given variable is being deleted. Delete all watchers associated with it."

	workPane submorphsDo: [:m |
		(m isKindOf: WatcherMorph) ifTrue: [
			((m target = aSprite) and:
			 [(m getSelector = #getVar:) and:
			 [m parameter = varName]])
				ifTrue: [m delete]]].
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jens 5/18/2010 02:33'!
deletingWatcher
	"The given watcher is being removed from the stage; remember it's last position."

	| palette w |
	watcherPositions do: [:rec |
		rec first ifNotNil: [
			w _ rec first.
			w owner ifNil: [
				rec at: 1 put: nil.
				rec at: 2 put: w position - workPane position. "record old position and layout style"
				rec at: 3 put: w layoutStyle.
				rec at: 4 put: w sliderRange]]].

	palette _ viewerPane pageViewer contents.
	(palette respondsTo: #updateWatcherButtonsForFrame:) 
		ifTrue: [palette updateWatcherButtonsForFrame: self].
! !

!ScratchFrameMorph methodsFor: 'buttonActions' stamp: 'jens 5/5/2010 00:09'!
developersMenu
	"Present the Scratch developer's menu."

	| menu |

	self isDevelopmentMode ifFalse: [^ self].

	self world activeHand toolType: nil.
	Cursor normal show.
	menu _ CustomMenu new.

	fillScreenFlag
		ifTrue: [menu add: 'turn fill screen off' action: #fillScreenOff]
		ifFalse: [menu add: 'turn fill screen on' action: #fillScreenOn].
	UseErrorCatcher
		ifTrue: [menu add: 'turn error catching off' action: #toggleErrorCatcher]
		ifFalse: [menu add: 'turn error catching on' action: #toggleErrorCatcher].

	menu addLine.
	menu add: 'save image for end-user' action: #saveImageForEndUser.
 
	menu invokeOn: self.
! !

!ScratchFrameMorph methodsFor: 'drawing' stamp: 'jm 4/27/2005 17:29'!
drawOn: aCanvas
	"Optimization: Don't draw myself at all since I am completely tiled."

! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/11/2011 01:01'!
editBlockDefinition: aCustomBlockDefinition for: aScriptableScratchMorph

	| editor def id |
	"for prototypal inheritance:"
	id _ aCustomBlockDefinition id.
	aScriptableScratchMorph ensureOwnBlockExists: aCustomBlockDefinition.
	def _ aScriptableScratchMorph customBlocks detect: [:eachDef | eachDef id = id]
		ifNone: [^ self ].
	(self notEditingBlockDefinition: def) ifFalse: [^self].
	def fixBlockVarReporters.
	editor 	_ BlockEditorFrameMorph new
		withButtonsForYes: false no: false okay: true cancel: true;
		receiver: aScriptableScratchMorph;
		definition: def.
	blockEditors add: editor.
	editor getUserResponse.
	blockEditors remove: editor ifAbsent: []! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jens 2/24/2011 20:13'!
editMenu: aMenuTitleMorph

	| menu onstage |

	"first create the widest label"
	onstage _ self checkBoxLabelled: 
				'Allow Sprites offstage' "localized asMacRoman"
				marked: ScriptableScratchMorph keepOnStage not
				width: 0.

	menu _ CustomMenu new.
	menu add: 'Undelete' action: #undoTool.
	menu add: 'Undo last drop' action: #undoLastDrop.

	menu addLine.

	menu addIcon: (self checkBoxLabelled: 'Turbo'
				marked: self isTurbo
				width: onstage width)
			toolTip: 'check to squeeze more computational steps into one display cycle'
			action: #toggleTurboMode.
"
	menu addIcon: (self checkBoxLabelled: 'Single Stepping'
				marked: (ScratchProcess blockHighlightMSecs <= 1) not
				width: onstage width)
			toolTip: nil
			action: #toggleSingleStepping.

	menu add: 'Set Single Stepping' action: #setSingleStepping.
	menu addLine.
"
	menu addIcon: onstage
			toolTip: 'check to allow sprites to move offscreen'
			action: #toggleKeepSpritesOnStage.

	menu addIcon: (self checkBoxLabelled: 'Thread safe scripts' 
				marked: EventHatMorph threadSafeMode 
				width: onstage width)
			toolTip: 'check to disallow script reentrancy'
			action: #toggleThreadSafeMode.

	menu addIcon: (self checkBoxLabelled: 'Zebra Coloring' 
				marked: BlockMorph contrast = #strong 
				width: onstage width)
			toolTip: 'check to alternate color contrast among nested reporters with the same color' localized asMacRoman
			action: #toggleZebraColoring.

	menu addIcon: (self checkBoxLabelled: 'Translucent Dragging'
				marked: HandMorph translucentWhenDragging 
				width: onstage width)
			toolTip: 'check to see through objects when they are dragged'
			action: #toggleTranslucentDragging.

	menu addIcon: (self checkBoxLabelled: 'Scope Contrast'
				marked: VariableFrame scopeContrast 
				width: onstage width)
			toolTip: 'check to contrast the color of lexically scoped blocks'
			action: #toggleScopeContrast.

	menu addLine.
	menu add: 'Compress Sounds' action: #compressSounds.
	menu add: 'Compress Images' action: #compressImages.
	menu add: 'Unload unused blocks' action: #unloadAllUnusedCustomBlocks.
	menu add: 'Clear all Variables' action: #clearAllVariables.

	menu addLine.

	menu addIcon: (self checkBoxLabelled: 'Show Motor Blocks'
				marked: workPane showMotorBlocks
				width: onstage width)
			toolTip: nil
			action: #toggleShowMotorBlocks.

	Sensor shiftPressed ifTrue: [	self isDevelopmentMode ifTrue: [
			menu addLine.
		fillScreenFlag
			ifTrue: [menu add: 'turn fill screen off' localized asMacRoman action: #fillScreenOff]
			ifFalse: [menu add: 'turn fill screen on' localized asMacRoman action: #fillScreenOn].
		UseErrorCatcher
			ifTrue: [menu add: 'turn error catching off' localized asMacRoman action: #toggleErrorCatcher]
			ifFalse: [menu add: 'turn error catching on' localized asMacRoman action: #toggleErrorCatcher].
		menu addLine.
		menu add: 'save image for end-user' localized asMacRoman action: #saveImageForEndUser]].
 
	menu localize.

	#(3 4 7 8) do: [:n |
		menu labels at: n put:
			((menu labels at: n) copyFrom: 1 to: (menu labels at: n) size - 1), ScratchTranslator ellipsesSuffix].

	menu invokeOn: self at: aMenuTitleMorph bottomLeft + (0@10).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/11/2006 17:56'!
editNotes

	(ScratchNotesDialog editNotesFor: self) getUserResponse.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 8/26/2008 11:50'!
enableRemoteSensors
	"Start running the Scratch server, allowing Scratch and other applications to interact with this Scratch remotely."

	| server |
	workPane scratchServer ifNil: [
		server _ ScratchServer new userName: 'Scratch'.
		server stage: workPane.
		workPane scratchServer: server].

	workPane scratchServer startHosting.
	DialogBoxMorph inform: 'Remote sensor connections enabled' localized.
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 4/13/2009 21:05'!
enterNormalMode
	"Go into normal (full-stage) mode."

	(viewMode = #normal) ifTrue: [
		self updateViewModeButtons.
		^ self].

	viewMode _ #normal.

	workPane isQuarterSize: false.
	workPane isInWorld
		ifTrue: [self fixLayout]
		ifFalse: [self exitPresentationMode].

	self updatePanes.
	self updateViewModeButtons.
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 6/22/2009 12:54'!
enterPresentationMode
	"Go into presentation mode."

	| presenter |
	ScratchPlugin pluginAvailable ifFalse: [
		self updateViewModeButtons.
		^ self beep].

	(viewMode = #presentation) ifTrue: [^ self].

	lastViewMode _ viewMode.
	viewMode _ #presentation.

	self closeDialogBoxes.
	workPane isQuarterSize: false.
	presenter _ ScratchPresenterMorph new frame: self.

	self delete.

	Display fillBlack.
	Smalltalk fullScreenMode: true.
	World restoreDisplay.
	Display fillBlack.
	World assuredCanvas.  "re-allocate canvas after entering full-screen mode"

	((Display width >= 965) & (Display height >= 750))
		ifTrue: [presenter beDoubleSize].
	presenter extent: Display extent.

	World addMorphFront: presenter.
	World startSteppingSubmorphsOf: presenter.
	World activeHand newKeyboardFocus: nil.
	self updatePenPositions.
	self updateViewModeButtons.

	World assuredCanvas.  "re-allocate canvas after entering full-screen mode"
	World fullRepaintNeeded.
	World displayWorldSafely.
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 4/13/2009 21:01'!
enterQuarterMode
	"Go into quarter stage mode."

	(viewMode = #quarter) ifTrue: [
		self updateViewModeButtons.
		^ self].

	viewMode _ #quarter.

	workPane isQuarterSize: true.
	workPane isInWorld
		ifTrue: [self fixLayout]
		ifFalse: [self exitPresentationMode].

	self updatePanes.
	self updateViewModeButtons.
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jm 4/22/2009 09:37'!
enterQuarterModeIfSmallScreen

	(Display width >= 980) & (Display height >= 555) ifTrue: [^ self].
	viewMode = #normal ifTrue: [self enterQuarterMode].
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jens 8/13/2009 23:48'!
exitPresentationMode
	"Exit presentation mode."

	quitFlag ifTrue: [^Smalltalk quitPrimitive].

	TakeOverScreen ifFalse: [
		Smalltalk fullScreenMode: false.
		World restoreDisplay].

	ScriptableScratchMorph doubleSize: false.
	self addMorphFront: workPane.
	self fixLayout.
	World addMorphFront: self.
	World startSteppingSubmorphsOf: self.
	World fullRepaintNeeded.
	self updatePenPositions.

	lastViewMode = #normal ifTrue: [^ self enterNormalMode].
	lastViewMode = #quarter ifTrue: [^ self enterQuarterMode].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 2/27/2009 09:04'!
exitScratchSession
	"Close all connections to remote collaborators."

	workPane scratchServer ifNil: [^ self].
	workPane scratchServer endScratchSession.
	workPane scratchServer: nil.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/28/2008 14:53'!
exportSprite

	scriptsPane target exportObject.
! !

!ScratchFrameMorph methodsFor: 'geometry' stamp: 'jm 10/26/2008 17:44'!
extent: aPoint
	"Position all my submorphs whenever I get resized."

	super extent: aPoint.
	self fixLayout.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jm 7/30/2008 17:12'!
extractInfoFrom: aByteArray
	"Answer a Scratch info dictionary from the given ByteArray. Answer an empty dictionary if it is an old project."

	| s version |
	s _ ReadStream on: aByteArray.
	version _ ObjStream scratchFileVersionFrom: (s next: 10) asString.
	(version = 1) | (version = 2)
		ifTrue: [
			s skip: 4.  "skip info header byte count"
			^ ObjStream new readObjFrom: s showProgress: false]
		ifFalse: [^ Dictionary new].

! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 6/30/2010 23:26'!
extractProjectFrom: aByteArray
	"Answer a Scratch project (i.e. a ScratchStageMorph possibly containing sprites) from the given ByteArray. Answer nil if the project cannot be unpacked."

	| s version proj |

	ObjStream initialize. "just to make sure this works in filed-in changesets, -Jens"

	s _ ReadStream on: aByteArray.
	version _ ObjStream scratchFileVersionFrom: (s next: 10) asString.
	version = 0 ifTrue: [
		ScriptableScratchMorph decodeAsByob.	"make sure we initialize every field - this breaks compatibility with Scratch-sprites. -Jens"
		s position: 0.
		[proj _ ObjStream new readObjFrom: s showProgress: true] ifError: [
		^ self extractScratchProjectFrom: aByteArray]].
	(version = 1) | (version = 2) ifTrue: [
		s skip: s uint32.  "skip header"
		proj _ ObjStream new readObjFrom: s showProgress: true].

	proj class = ScratchStageMorph ifFalse: [
		version > 2
			ifTrue: [self error: 'Project created by a later version of Scratch']
			ifFalse: [self error: 'Problem reading project.'].
		^ nil].

	ScriptableScratchMorph buildBlockSpecDictionary.

	'initializing...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((proj allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 2
		during: [:bar | | i | i _ 0.

	proj allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			 i _ i + 1. bar value: i.
			m convertTuplesToDefinitions]].

	proj allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [  "convert to new blocks" 
			i _ i + 1. bar value: i.
			m convertStacksToTuples.
			m convertTuplesToStacks]]].

	^ proj
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 6/30/2010 23:26'!
extractScratchProjectFrom: aByteArray
	"Answer a Scratch project (i.e. a ScratchStageMorph possibly containing sprites) from the given ByteArray. Answer nil if the project cannot be unpacked.

Note: this is a compatibility force method for BYOB - jens"

	| s version proj |

	ObjStream initialize. "just to make sure this works in filed-in changesets, -Jens"

	s _ ReadStream on: aByteArray.
	version _ ObjStream scratchFileVersionFrom: (s next: 10) asString.
	version = 0 ifTrue: [
		ScriptableScratchMorph decodeAsScratch.	"this is the forcing part. -Jens"
		s position: 0.
		proj _ ObjStream new readObjFrom: s showProgress: true].
	(version = 1) | (version = 2) ifTrue: [
		s skip: s uint32.  "skip header"
		proj _ ObjStream new readObjFrom: s showProgress: true].

	proj class = ScratchStageMorph ifFalse: [
		version > 2
			ifTrue: [self error: 'Project created by a later version of Scratch']
			ifFalse: [self error: 'Problem reading project.'].
		^ nil].

	ScriptableScratchMorph buildBlockSpecDictionary.

	'initializing...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((proj allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 2
		during: [:bar | | i | i _ 0.

	proj allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			 i _ i + 1. bar value: i.
			m convertTuplesToDefinitions]].

	proj allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [  "convert to new blocks" 
			i _ i + 1. bar value: i.
			m convertStacksToTuples.
			m convertTuplesToStacks]]].

	^ proj
! !

!ScratchFrameMorph methodsFor: '-- all --' stamp: 'JM 11/9/2011 17:10'!
fileMenu: aMenuTitleMorph

	| menu |
	menu _ CustomMenu new.
	menu add: 'New' action: #newScratchProject.
	menu add: 'Open' action: #openScratchProject.
	menu add: 'Save' action: #saveScratchProjectNoDialog.
	menu add: 'Save As' action: #saveScratchProject.
	menu addLine.
	menu add: 'Import Project' action: #importScratchProject.
	menu add: 'Export Sprite' action: #exportSprite.
	menu addLine.
	menu add: 'Project Notes' action: #editNotes.

	Sensor shiftPressed ifTrue: [
"		menu addLine.
		menu add: 'Write Project Summary' action: #writeSummaryFile.
		menu add: 'Write Multiple Project Summaries' action: #writeMultipleSummaries].
"		menu addLine.
		menu add: 'Import from version control' action: #versionControlImport.
		menu add: 'Export to version control' action: #versionControlExport.
	].

	menu addLine.
	menu add: 'Quit' action: #quitScratch.
	menu localize.
	
	#(2 4 5 6 7) do: [:n |
		menu labels at: n put:
			((menu labels at: n) copyFrom: 1 to: (menu labels at: n) size - 1), ScratchTranslator ellipsesSuffix].

	menu invokeOn: self at: aMenuTitleMorph bottomLeft + (0@10).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 4/14/2009 09:56'!
fillScreenOff
	"Stop filling the entire screen. Useful during development."


	Smalltalk fullScreenMode: false.
	World restoreDisplay.

	fillScreenFlag _ false.
	self isSticky: false.
	self extent: Display extent - 50.
	UseErrorCatcher _ false.
	Preferences disable: #noviceMode.
	Preferences enable: #warnIfNoSourcesFile.
	Preferences enable: #warnIfNoChangesFile.
	Preferences insertionPointColor: (Color r: 0.4 g: 1.0 b: 0.0).
	Preferences textHighlightColor: (Color r: 0.4 g: 1.0 b: 0.0).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 4/14/2009 09:55'!
fillScreenOn
	"Start filling the entire screen and being sticky. Also configure a few other things for the end user such as turning off halos and the control menu (noviceMode) and making sure that error catching is enabled."

	TakeOverScreen ifTrue: [
		Smalltalk fullScreenMode: true.
		World restoreDisplay].

	fillScreenFlag _ true.
	self position: 0@0.
	self isSticky: true.
	self comeToFront.
	UseErrorCatcher _ true.
	Sensor useOSEvents: true.
	Preferences enable: #noviceMode.
	Preferences disable: #warnIfNoSourcesFile.
	Preferences disable: #warnIfNoChangesFile.
	Preferences insertionPointColor: (Color r: 0.353 g: 0.607 b: 0.788).
	Preferences textHighlightColor: (Color r: 0.353 g: 0.607 b: 0.788).
	self updateProjectName.
	self step.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jm 5/8/2007 11:04'!
fixByteReversedSounds
	"See if the current project contains any byte-reversed copies of one of the standard sounds. If it does, byte-reverse all sounds. This is a workaround for a bug in Scratch 1.0 that did not upload sounds in big-endian order."

	| allSoundBuffers badMeowPrefix badPopPrefix foundBadSound |
	allSoundBuffers _ IdentitySet new.
	self allProjectMedia do: [:media |
		media isSound ifTrue: [
			allSoundBuffers add: media sound samples]].
	allSoundBuffers remove: ScriptableScratchMorph meowSound samples ifAbsent: [].
	allSoundBuffers remove: ScriptableScratchMorph popSound samples ifAbsent: [].

	badMeowPrefix _ ScriptableScratchMorph oldMeowPrefixReversed.
	badPopPrefix _ (ScriptableScratchMorph popSound samples copyFrom: 1 to: 100) reverseEndiannessStereo: false.
	foundBadSound _ false.
	allSoundBuffers do: [:buf |
		foundBadSound ifFalse: [
			((buf beginsWith: badMeowPrefix) or:
			 [buf beginsWith: badPopPrefix])
				ifTrue: [foundBadSound _ true]]].

	foundBadSound ifTrue: [
		allSoundBuffers do: [:buf | buf reverseEndiannessStereo: false]].
! !

!ScratchFrameMorph methodsFor: 'geometry' stamp: 'jm 4/22/2009 08:59'!
fixLayout

	| stageExtent xyReadout w |
	stageExtent _
		workPane isQuarterSize
			ifTrue: [workPane extent // 2]
			ifFalse: [workPane extent].

	topPane
		position: self topLeft;
		width: self width;
		height: (menuPanel height + 0 max: logoMorph height + 10).

	stageFrame
		extent: stageExtent + (14@42);
		top: topPane bottom;
		right: self right.

	workPane position: stageFrame topLeft + (4@37).

	titlePane
		position: stageFrame topLeft + (0@1);
		width: stageFrame width - 6;
		height: 36.

	self fixProjectTitleMorphLayout.

	scriptsPane fixLayout.
	w _ (viewerPane catButtonsExtent x + 17)
		within: 40
		and: (self width - (scriptsPane bareMinimumWidth + stageFrame width)).
	viewerPane position: topPane bottomLeft;
		width: w;
		height: self bottom - topPane bottom.

	scriptsPane
		position: viewerPane topRight;
		width: self width - (stageFrame width + viewerPane width);
		height: self bottom - topPane bottom;
		fixLayout.

	libraryPane position: stageFrame bottomLeft;
		width: (self right - scriptsPane right);
		height: self bottom - libraryPane top.

	menuPanel
		left: logoMorph right + 18;
		top: topPane top + ((topPane height - menuPanel height) // 2) + 2.

	viewModeButtonsPanel
		right: stageFrame right - 8;
		top: self top + 7.

	stageButtonsPanel
		position: (stageFrame left + 10)@(topPane bottom + 5);
		width: stageFrame width - 28;
		height: (workPane top - stageFrame top) - 8.

	xyReadout _ readoutPane submorphs at: 1.
	readoutPane
		width: xyReadout width + 23;
		height: xyReadout height + 15;
		position: stageFrame bottomRight - ((readoutPane width + 6)@3).
	xyReadout position: readoutPane position + (18@5).

	toolbarPanel
		left: (stageFrame left - 4 max: menuPanel right);
		top: self top + ((topPane height - toolbarPanel height) // 2) + 3.

	((toolbarPanel right - 5) > viewModeButtonsPanel left)
		ifTrue: [toolbarPanel delete]
		ifFalse: [
			(toolbarPanel owner = self) ifFalse: [
				self addMorphFront: toolbarPanel]].
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'ee 2/3/2009 13:26'!
fixProjectTitleMorphLayout
 
	| s truncated eWidth w |

	projectName ifNotNil: [
		s _  (self nameFromFileName: projectName).
		"trim project name to fit, if necessary"
		truncated _ false.
		eWidth _ (ScratchTranslator stringExtent: '...' font: projectTitleMorph font) x.
		w _ titlePane width - 100 - eWidth.
		[((ScratchTranslator stringExtent: s font: projectTitleMorph font) x) > w] whileTrue: [
			truncated _ true.
			s _ s copyFrom: 1 to: s size - 1].
		truncated ifTrue: [s _ s, '...'].
		projectTitleMorph contents: s].
! !

!ScratchFrameMorph methodsFor: 'drawing' stamp: 'jm 2/3/2009 19:17'!
fullDrawOn: aCanvas
	"Draw my full Morphic structure on the given Canvas."
	"Optimization: if damage is entirely contained in a given pane, draw only that pane."

	| damageR stageR |
	damageR _ aCanvas clipRect.

	stageR _ workPane bounds.
	workPane isQuarterSize ifTrue: [
		stageR _ workPane position extent: (workPane width // 2) @ (workPane height // 2)].
	(stageR containsRect: damageR) ifTrue: [
		workPane fullDrawOn: aCanvas.
		^ self].

	(scriptsPane bounds containsRect: damageR) ifTrue: [
		scriptsPane fullDrawOn: aCanvas.
		^ self].

	(viewerPane bounds containsRect: damageR) ifTrue: [
		viewerPane fullDrawOn: aCanvas.
		^ self].

	(readoutPane bounds containsRect: damageR) ifTrue: [
		readoutPane fullDrawOn: aCanvas.
		^ self].

	(libraryPane bounds containsRect: damageR) ifTrue: [
		libraryPane fullDrawOn: aCanvas.
		^ self].

	super fullDrawOn: aCanvas.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/13/2009 14:37'!
getLoginName
	"Ask the user for their name name and record their answer in 'loginName'."

	| s |
	s _ StringDialog
		askWithCancel: 'User name:'
		initialAnswer: loginName.
	s size = 0 ifTrue: [^ ''].
	loginName _ s.
	^ s
! !

!ScratchFrameMorph methodsFor: 'event handling' stamp: 'jm 3/16/2007 16:53'!
handlesMouseDown: evt

	^ true
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 7/7/2010 03:21'!
helpMenu: aMenuTitleMorph

	| menu |
	menu _ CustomMenu new.
	menu add: 'BYOB Reference Manual' action: #openBYOBManual.
	menu add: 'BYOB Website' action: #launchWebsite.
	menu addLine.
	menu add: 'Scratch Help Page' action: #launchHelpPage.
	menu add: 'Help Screens' action: #launchAllHelpScreens.
	menu addLine.
	menu add: 'About BYOB' action: #aboutScratch.

	menu localize.

	#(1 2 3 4 5) do: [:n |
		menu labels at: n put:
			((menu labels at: n) copyFrom: 1 to: (menu labels at: n) size - 1), ScratchTranslator ellipsesSuffix].

	menu invokeOn: self at: aMenuTitleMorph bottomLeft + (0@10).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 2/17/2009 11:33'!
hideMotorBlocks

	workPane showMotorBlocks: false.
	viewerPane refresh.
! !

!ScratchFrameMorph methodsFor: 'geometry' stamp: 'jm 12/23/2008 13:50'!
hidePalette: hidePalette
	"Hide or show the blocks palette."

	hidePalette = viewerPane owner isNil ifTrue: [^ self].  "no change"

	hidePalette
		ifTrue: [
			viewerPane delete.
			scriptsPane
				initFrontFromForm: (ScratchFrameMorph skinAt: #blocksPaletteFrameTransparent2) topSectionHeight: 90;
				middleBarLeftMargin: 5 rightMargin: 0]
		ifFalse: [
			self addMorph: viewerPane.
			scriptsPane
				initFrontFromForm: (ScratchFrameMorph skinAt: #scriptPaneFrameTransparent2) topSectionHeight: 90;
				middleBarLeftMargin: 0 rightMargin: 0].

	scriptsPane color: (Color r: 149/255 g: 154/255 b: 159/255).
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 5/10/2010 01:24'!
importScratchProject
	"Allow the user to select a project to open, then merge that project's sprites with the
current project."

	| response |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	response _ ScratchFileChooserDialog
		chooseExistingFileType: #project
		extensions: #(scratch sb ypr)
		title: 'Import Project'.
	response ifNil: [^ self].

	self importSpriteOrProject: response.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 6/30/2010 23:26'!
importSpriteOrProject: fileNameOrData
	"Read the sprite or project file and merge into the current project."

	| data f importedStage defaultForm defaultSound |

	data _ fileNameOrData.
	(data isKindOf: String) ifTrue: [  "read the contents of a local file"
		(FileDirectory default fileExists: fileNameOrData) ifFalse: [^ self].
		f _ (FileStream readOnlyFileNamed: fileNameOrData) binary.
		f ifNil: [^ self].
		data _ f contentsOfEntireFile].

	[importedStage _ self extractProjectFrom: data] ifError: [^ self].

	"fix references to old stage"
	importedStage allMorphsDo: [:m |
		(m isKindOf: WatcherMorph) ifTrue: [m mapReceiver: importedStage to: workPane].
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			m blocksBin submorphs do: [:stack |
				(stack isKindOf: BlockMorph) ifTrue: [
					stack blockSequence do: [:b | b mapReceiver: importedStage to: workPane]]]]].

	"add global variables from importated stage to my stage"
	importedStage varNames do: [:v |
		workPane addVariable: v value: (importedStage getVar: v)].
	importedStage varNames do: [:v | workPane addVariable: v].

	"add imported stage scripts"
	importedStage blocksBin submorphs do: [:stack |
		(stack isKindOf: BlockMorph) ifTrue: [workPane addStack: stack fullCopy]].

	"add imported background costumes and scripts to my stage, filtering out default items"
	defaultForm _ workPane defaultImageMedia form hibernate.
	defaultSound _ SoundMedia new sound.
	importedStage media do: [:media |
		(media isImage and: [media form hibernate bits ~= defaultForm bits])
			ifTrue: [workPane addMediaItem: media].
		(media isSound and: [media sound samples ~= defaultSound samples])
			ifTrue: [workPane addMediaItem: media]].

	"add imported global custom block definitions"
	importedStage customBlocks ifNotNil: [

		'installing globals...' 
			displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
			from: 0 to: importedStage customBlocks size
			during: [:bar | | i | i _ 0.

		importedStage customBlocks do: [:eachDef |
			i _ i + 1. bar value: i.
			workPane sprites, {workPane} do: [:obj |
				obj
					updateCustomBlockDefinitionId: eachDef id with: eachDef;
					updateLocalId: eachDef id withSpec: eachDef userSpec]]]].

	importedStage position: workPane position.

	importedStage submorphs do: [:m | 
		(m isKindOf: ScratchSpriteMorph) ifTrue: [
			"m objName: m  nextInstanceName".
			workPane addMorphFront: m.
			m startStepping.
			workPane sprites addLast: m.
			self view: m tab: 'Scripts' category: 'motion'.
			m refPos ifNotNil: [
				m referencePosition: m refPos + (50@-50) ]]].

	workPane layoutChanged.
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jens 6/10/2010 21:17'!
initialize

	super initialize.
	fillScreenFlag _ false.
	paintingInProgress _ false.
	projectInfo _ Dictionary new.
	watcherPositions _ Dictionary new.
	justSaved _ false.
	quitFlag _ false.
	blockEditors _ Set new.
	author _ ''.
	loginName _ ''.
	loginPassword _ ''.
	viewMode _ #normal.

	self createBasicPanes.
	self createLogo.
	self createMenuPanel.
	self createViewModeButtonsPanel.
	self createStageButtonsPanel.
	self createToolbar.

	self extent: 1000@600.
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 8/25/2008 09:56'!
initializeWatcherPositions
	"If any watchers are on the stage, store their position. The dictionary, which is created lazily, is formatted in the following way:
	(<sprite or nil, depending on whether the block isSpriteSpecific>, <name of block>) ->
		(<watcher or nil, depending on whether the watcher is showing on stage>,
		 <position of watcher with top-left corner of stage = 0@0>
		 <layout style>
		 <slider range>)
	Or, more concisely: (sprite/nil,selectorAndArg)->(watcher/nil,position,style,range)."
 
	| p |
	watcherPositions _ Dictionary new.
	self scratchWatchers do: [:w |
		p _ w position - workPane position.
		watcherPositions
			at: {w getAssociatedSprite. w selectorAndArg}
			put: {w. p. w layoutStyle. w sliderRange}].
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 7/27/2010 13:23'!
installNewProject: newWorkpane
	"Called after creating or reading a new project to clear the process scheduler, pick an object to view, clear the library thumbnails, and perform other housekeeping."

	| viewTarget sb |
	self stopAll.

	newWorkpane class = ScratchStageMorph
		ifFalse: [^ self inform: 'Incompatible Scratch file format'].

	"self exitScratchSession."
	workPane scratchServer ifNotNil: [
		workPane scratchServer clearCaches.
		workPane scratchServer stage: newWorkpane.
		newWorkpane scratchServer: workPane scratchServer].

	newWorkpane isQuarterSize: workPane isQuarterSize.
	newWorkpane bounds: workPane bounds.
	newWorkpane midiPortNum: workPane midiPortNum.
	workPane closeMIDI.

	"use the same sensorboard for the new project"
	sb _ workPane sensorBoard.
	newWorkpane submorphs do: [:m |
		(m isKindOf: SensorBoardMorph) ifTrue: [
			sb position: m position.
			newWorkpane replaceSubmorph: m by: sb.
			sb tryToOpenPort]].
	newWorkpane sensorBoard: sb.

	workPane owner replaceSubmorph: workPane by: newWorkpane.
	workPane _ newWorkpane.

	self fixByteReversedSounds.

	"fix sprite positions (backward compatability)"
	workPane submorphs do: [:m |
		(m isKindOf: WatcherMorph) ifTrue: [m convertFromOldWatcher].
		(m respondsTo: #costume) ifTrue: [
			m position: m position + m costume rotationCenter]. "fix up positions"
		m layoutChanged].
	workPane layoutChanged.

	"reset timer"
	ScriptableScratchMorph resetTimer.

	"pick an object view, or view the background if there is no other"
	viewTarget _ workPane.
	workPane submorphs do: [:m |
		(m respondsTo: #scripts) ifTrue: [
			m scripts size >= viewTarget scripts size ifTrue: [viewTarget _ m]]].
	viewTarget viewBlocksAndScripts.

	"populate the sprites list if it is empty (backward compatability)"
	workPane sprites isEmpty ifTrue: [
		workPane submorphs do: [:m |
			(m isKindOf: ScriptableScratchMorph) ifTrue: [workPane sprites addLast: m]]].

	scriptsPane tabPane currentTab: 'Scripts'.
	libraryPane clearLibrary.
	workPane clearPenTrails.
	self updateProjectName.
	ScratchProcess blockHighlightMSecs: 1.
	ScratchPrompterMorph clearLastAnswer.

	(projectInfo at: 'isHosting' ifAbsent: [false]) ifTrue: [
		self enableRemoteSensors].
	(projectInfo at: 'hasMotorBlocks' ifAbsent: [false]) ifTrue: [
		self showMotorBlocks].
	(projectInfo includesKey: 'penTrails') ifTrue: [
		workPane penTrailsForm: (projectInfo at: 'penTrails')].

	(projectInfo at: 'keepOnStage' ifAbsent: [true]) = ScriptableScratchMorph keepOnStage
		ifFalse: [self toggleKeepSpritesOnStage].

	Clipboard _ nil.
	World cleanseStepList.  "make sure garbage collect can clean up the old sprites"
	Smalltalk garbageCollect.  "get rid of old sprite instances"

	self world ifNotNil: [self world startSteppingSubmorphsOf: self].
	ScriptableScratchMorph scratchOrigin: workPane center.
	justSaved _ true.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/26/2010 21:06'!
isDevelopmentMode

	| args arg |

	Preferences noviceMode
		ifTrue: [
			args _ OrderedCollection new.
			2 to: 10 do: [:i |
				arg _ Smalltalk getSystemAttribute: i.
				arg ifNotNil: [args add: arg ]].
			args detect: [:each |
				each asLowercase = 'dev'] ifNone: [^false].
			^true]
		ifFalse: [^ true]
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/18/2010 02:16'!
isTurbo
	^ ScratchProcess blockHighlightMSecs < 1! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/14/2009 08:11'!
joinScratchSession
	"Join another Scratch user or a Scratch-compatible remote application."

	| server addrString ok |
	server _ ScratchServer new.
	server stage: workPane.
	workPane scratchServer: server.

	addrString _ StringDialog askWithCancel: 'IP address:'.
	addrString size = 0 ifTrue: [^ self].

	ok _ workPane scratchServer joinSessionAt: addrString.
	ok ifFalse: [DialogBoxMorph warn: 'Could not connect to ', addrString].
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 02:06'!
keepSpritesOnStage: anInt
	| bool |

	bool _ {false. true} at: anInt + 1.
	ScriptableScratchMorph keepOnStage: bool! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 10/5/2010 00:01'!
languageMenu: aToggleButtonMorph
	"Present a menu of possible languages for blocks."

	| bullet menu choice |
	ScratchTranslator canRenderUnicode ifFalse: [
		"try to find a Unicode plugin in case this is the first use after startup"
		ScratchTranslator detectRenderPlugin].

"	bullet _ UTF8 withAll: '• '."
	bullet _ UTF8 withAll: '*'.
	menu _ CustomMenu new.
	ScratchTranslator languageNames do: [:lang |
		((ScratchTranslator isoCodeForName: lang) = (ScratchTranslator currentLanguage))
			ifTrue: [menu add: (bullet, ' ', lang asMacRoman, ' ', bullet) action: lang]
			ifFalse: [menu add: lang asMacRoman action: lang]].
	choice _ menu startUp: nil withCaption: nil at: aToggleButtonMorph bottomLeft + (0@10).

	choice ifNil: [^ self].
	self stopAll.
	self setLanguage: choice.
	self recordLanguage: (ScratchTranslator currentLanguage).
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 2/23/2009 07:07'!
launchAllHelpScreens

	self launchHelpFile: 'allscreens.html'
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 4/16/2009 12:45'!
launchHelpFile: aFilename

	| helpDir subDir |
	(FileDirectory default directoryNames includes: 'Help') ifFalse: [^ self beep].  "no help folder"
	self stopAll.
	helpDir _ FileDirectory default directoryNamed: 'Help'.

	"use the English subfolder by default if it exists"
	(helpDir directoryNames includes: 'en') ifTrue: [subDir _ helpDir directoryNamed: 'en'].
	"use subfolder for the current language if it exists"
	(helpDir directoryNames includes: ScratchTranslator currentLanguage) ifTrue: [
		subDir _ helpDir directoryNamed: ScratchTranslator currentLanguage].
	subDir ifNotNil: [helpDir _ subDir].

	(helpDir fileExists: aFilename)
		ifTrue: [Smalltalk isMacOSX
			ifTrue: [ScratchPlugin primOpenURL: 'file://', (helpDir pathName, FileDirectory slash, aFilename) encodeForHTTP]
			ifFalse: [ScratchPlugin primOpenURL: helpDir pathName, FileDirectory slash, aFilename]]
		ifFalse: [
			DialogBoxMorph inform: 'Scratch help file not found.' localized].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 4/15/2009 11:55'!
launchHelpPage

	self launchHelpFile: 'index.html'.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 2/12/2009 16:45'!
launchScratchWebsite

	self world displayWorldSafely.
	Cursor wait showWhile: [ScratchPlugin primOpenURL: 'http://', ScratchFrameMorph shareServer].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 7/7/2010 03:18'!
launchWebsite

	self world displayWorldSafely.
	Cursor wait showWhile: [ScratchPlugin primOpenURL: 'http://byob.berkeley.edu'].
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'tis 11/8/2006 13:34'!
libraryPane

	^ libraryPane
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'ee 7/11/2008 22:26'!
listWatchers
	"Answer a collection of all the list watchers in the work pane."

	^ self workPane submorphs select: [:m | m isKindOf: ScratchListMorph]
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:27'!
loginName

	^ loginName
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:30'!
loginName: aString

	loginName _ aString.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:27'!
loginPassword

	^ loginPassword
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/24/2007 09:30'!
loginPassword: aString

	loginPassword _ aString.
! !

!ScratchFrameMorph methodsFor: 'compiler' stamp: 'jens 7/7/2010 03:09'!
makeExe

	| argStr delim |
	justSaved ifFalse: [ 
		self saveScratchProject ].
	delim _ FileDirectory activeDirectoryClass pathNameDelimiter asString.
	argStr _ (ScratchFileChooserDialog getLastFolderForType: #project) pathName
				, delim
				, projectName.
	Smalltalk isWindows ifTrue: [
		^ SystemPlugin primLaunch: 'mak\pack ', argStr ].
	SystemPlugin primLaunch: 
		'"'
		, FileDirectory activeDirectoryClass default pathName
		, delim
		, 'compile.sh" '
		, '"'
		, argStr
		, '"'
! !

!ScratchFrameMorph methodsFor: 'intialization' stamp: 'jm 5/4/2009 11:15'!
makeXYReadout
	"Make and answer an x-y readout."

	| normalFont boldFont panel spaceWidth labelX readoutX labelY readoutY |
	normalFont _ (ScratchFrameMorph getFont: #XYReadout).
	boldFont _ (ScratchFrameMorph getFont: #XYReadoutBold).

	(ScratchTranslator renderScale ~= 1) ifTrue: [
		"force fonts to be fixed size:"
		normalFont _ StrikeFont
			osFontName: normalFont name
			size: normalFont pointSize / ScratchTranslator renderScale asFloat.
		boldFont _ StrikeFont
			osFontName: boldFont name
			size: boldFont pointSize / ScratchTranslator renderScale asFloat].

	panel _ Morph new color: (Color r: 0.753 g: 0.764 b: 0.776).

	ScratchTranslator isRTL
		ifTrue: [labelX _ StringMorph new font: normalFont; contents: ':x' asUTF8]
		ifFalse: [labelX _ StringMorph new font: normalFont; contents: 'x:' asUTF8].
	readoutX _ UpdatingStringMorph new
		target: self; getSelector: #mouseX;
		forceUnicodeRendering: true;
		font: boldFont;
		stepTime: 150;
		growable: false.
	readoutX width: (readoutX stringWidth: '-1000').
	ScratchTranslator isRTL
		ifTrue: [labelY _ labelX fullCopy contents: ':y' asUTF8]
		ifFalse: [labelY _ labelX fullCopy contents: 'y:' asUTF8].
	readoutY _ readoutX fullCopy getSelector: #mouseY.

	spaceWidth _ ((readoutX stringWidth: ' ') * 0.8) asInteger.

	ScratchTranslator isRTL
		ifTrue: [readoutY rightJustify: true.
			panel addMorph: (readoutY position: 0@0).
			panel addMorph: (labelY position: ((readoutY topRight) + (spaceWidth@0))).]
		ifFalse: [panel addMorph: (labelX position: 0@0).
			panel addMorph: (readoutX position: ((labelX topRight) + (spaceWidth@0)))].

	ScratchTranslator isRTL
		ifTrue: [readoutX rightJustify: true.
			panel addMorph: (readoutX position: (labelY right@labelY top) + (spaceWidth@0)).
			panel addMorph: (labelX position: ((readoutX topRight) + (spaceWidth@0)))]
		ifFalse: [panel addMorph: (labelY position: (labelX right + readoutX width + 8)@(labelX top)).
			panel addMorph: (readoutY position: ((labelY topRight) + (spaceWidth@0)))].
	
	ScratchTranslator isRTL
		ifTrue: [panel extent: ((labelX right) max: (labelY right))@(labelY bottom)]
		ifFalse: [panel extent: ((readoutX right) max: (readoutY right))@(labelY bottom)].

	^ panel
! !

!ScratchFrameMorph methodsFor: 'event handling' stamp: 'jens 5/5/2010 00:27'!
mouseDown: evt
	"Revert to normal cursor."

	evt hand toolType: nil.
	(evt cursorPoint y - self top) < topPane height ifTrue: [
		fillScreenFlag ifFalse: [evt hand grabMorph: self]].
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 10/21/2005 18:45'!
mouseX

	^ workPane mouseX
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 10/21/2005 18:46'!
mouseY

	^ workPane mouseY
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 5/3/2010 22:01'!
nameFromFileName: fileName
	"Return the given Scratch file name without the trailing .sb or .scratch or .ypr extension, if it has one. Ensure the the result is UTF8."

	| s |
	s _ fileName.
	(s asLowercase endsWith: '.scratch') ifTrue: [s _ s copyFrom: 1 to: s size - 8].
	(s asLowercase endsWith: '.sb') ifTrue: [s _ s copyFrom: 1 to: s size - 3].
	(s asLowercase endsWith: '.ypr') ifTrue: [s _ s copyFrom: 1 to: s size - 4].
	s isUnicode ifFalse: [s _ UTF8 withAll: s].

	^ s

! !

!ScratchFrameMorph methodsFor: 'buttonActions' stamp: 'jens 9/2/2010 14:41'!
newScratchProject
	"Make a new, blank Scratch project."

	| response newProject sprite |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	(justSaved or: [self projectIsEmpty]) ifFalse: [
		"ask the user if they want to save the current project"
		response _ DialogBoxMorph askWithCancel: 'Save the current project?'.
		response = #cancelled ifTrue: [^ self].
		response ifTrue: [self saveScratchProjectNoDialog.
			justSaved ifFalse: [^ self]]].

	projectDirectory _ ScratchFileChooserDialog getDefaultFolderForType: #project.
	projectName _ ''.
	projectInfo _ Dictionary new.

	newProject _ ScratchStageMorph new.
	sprite _ ScratchFrameMorph defaultSprite fullCopy.
	sprite position: (240@180) - sprite extent.
	newProject addMorph: sprite.
	self installNewProject: newProject.
	sprite installGlobalBlocks.

	ScriptableScratchMorph decodeAsByob. "remember we created this project in byob and not in Scratch"

	self initializeWatcherPositions.
	blockEditors _ Set new.
	justSaved _ true.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'ee 11/4/2008 11:46'!
newSound
	"Open the dialog to record a new sound."

	scriptsPane tabPane currentTab: 'Sounds'.
	viewerPane target recordSound.! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jm 1/4/2007 23:10'!
nextSurpriseCostumeName
	"Answer a surprise costume name or nil if there are no costumes."
	"Details: Shuffle the list of available costume names and return them one at a time. When there are none left, generate a new shuffle. This avoids repeats."

	| dir ext |
	(shuffledCostumeNames isNil or:
	 [shuffledCostumeNames size = 0]) ifTrue: [
		shuffledCostumeNames _ OrderedCollection new: 1000.
		dir _ (FileDirectory default directoryNamed: 'Media') directoryNamed: 'Costumes'.
		dir allFileNamesDo: [:fn |
			(fn includesSubString: 'Letters') ifFalse: [
				ext _ (FileDirectory extensionFor: fn) asLowercase.
				((ext size > 0) and: [#(gif png jpg) includes: ext])
					ifTrue: [shuffledCostumeNames add: fn]]]].

	shuffledCostumeNames _ shuffledCostumeNames shuffledBy: Random new.
	shuffledCostumeNames size = 0
		ifTrue: [^ nil]
		ifFalse: [^ shuffledCostumeNames removeFirst].
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/24/2004 18:58'!
normalTool

	self paintingInProgress ifTrue: [^ self beep].
	self world activeHand toolType: nil.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 22:23'!
notEditingBlock
	blockEditors size = 0 ifTrue: [^true].
	(DialogBoxMorph ask: 'Close open block editor(s)?') ifFalse: [^false].
	blockEditors do:[:each | each no].
	blockEditors _ Set new.
	^true! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/30/2010 00:44'!
notEditingBlockDefinition: aCustomBlockDefinition
	| editor |
	blockEditors size = 0 ifTrue: [^true].
	editor _ blockEditors detect: [:each | 
		each definition id = aCustomBlockDefinition id] 
		ifNone: [nil].
	editor ifNil: [^true].
	editor comeToFront.
	^ false! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/10/2010 01:36'!
openBYOBManual
	
	| manual |
	manual _ 'BYOBManual.pdf'.

	Smalltalk isMacOSX
			ifTrue: [ScratchPlugin primOpenURL: 'file://', (FileDirectory default pathName, FileDirectory slash, manual) encodeForHTTP]
			ifFalse: [ScratchPlugin primOpenURL: FileDirectory default pathName, FileDirectory slash, manual]
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 8/2/2005 19:17'!
openMIDI
	"Prompt the user to select a MIDI port number, then open it."

	workPane openMIDI.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'ee 6/12/2008 12:02'!
openScratchDroppedProjectNamed: fName
	"Open a Scratch project with the given name that was dropped on the Scratch window."

	| response |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	(justSaved or: [self projectIsEmpty]) ifFalse: [
		"ask the user if they want to save the current project"
		response _ DialogBoxMorph askWithCancel: 'Save the current project?'.
		response = #cancelled ifTrue: [^ self].
		response ifTrue: [self saveScratchProjectNoDialog]].

	self openScratchProjectNamed: fName.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 7/27/2010 13:24'!
openScratchProject
	"Allow the user to select a project to open, then open that project."

	| response newProj |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	(justSaved or: [self projectIsEmpty]) ifFalse: [
		"ask the user if they want to save the current project"
		response _ DialogBoxMorph askWithCancel: 'Save the current project?'.
		response = #cancelled ifTrue: [^ self].
		response ifTrue: [self saveScratchProjectNoDialog]].

	response _ ScratchFileChooserDialog openScratchFileFor: self.
	response = #cancelled ifTrue: [^ self].

	(response isKindOf: String) ifTrue: [  "read the contents of a local file"
		^ self openScratchProjectNamed: response].

	(response isKindOf: ByteArray) ifTrue: [
		[projectInfo _ self extractInfoFrom: response] ifError: [projectInfo _ Dictionary new].
		[newProj _ self extractProjectFrom: response] ifError: [^ self].
		self installNewProject: newProj.
		projectDirectory _ ScratchFileChooserDialog getDefaultFolderForType: #project].
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 1/14/2011 02:11'!
openScratchProjectNamed: fName
	"Open a Scratch project with the given name."

	| f projData newProj dir fn|
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	
	fn _ fName.
	f _ FileStream readOnlyFileNamedOrNil: fn.
 	f ifNil: ["try a different encoding, fixes a Firefox bug, -Jens"
		fn _ fName isoLatinToMac asUTF8.
		f _ FileStream readOnlyFileNamedOrNil: fn.
		f ifNil: [^ self inform: 'Could not read' withDetails: fName]].

	[	projData _ f binary contentsOfEntireFile. 
		newProj _ self extractProjectFrom: projData.
		projectInfo _ self extractInfoFrom: projData. 

	] ifError: [:err :rcvr | ^ self inform: 'Could not read project; file may be damaged' withDetails: '(', err, ')'].

	dir _ FileDirectory dirPathFor: fn.
	projectDirectory _ FileDirectory on: dir.
	ScratchFileChooserDialog setLastFolderTo: projectDirectory forType: #project.
	projectName _ FileDirectory localNameFor: fn.

	self installNewProject: newProj.
	self initializeWatcherPositions.
	viewerPane updateContents.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 12/8/2008 12:05'!
paintSpriteMorph

	| m |
	m _ ScratchSpriteMorph new soleCostume: ImageMedia new.
	self addAndView: m.
	m editDrawingOldCostumeName: m costume mediaName deleteOnCancel: true.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 5/2/2005 17:22'!
paintingInProgress
	"Answer true if the paint editor is in use."

	^ paintingInProgress
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 5/2/2005 17:06'!
paintingInProgress: aBoolean

	paintingInProgress _ aBoolean.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 6/22/2009 12:46'!
presentHelpScreen: aStringOrNil
	"Look for a help screen with the given name in the 'Help' folder. If found, present it to the user."

	| helpDir subDir fileNames helpFileName helpForm |
	aStringOrNil ifNil: [^ self beep].

	(FileDirectory default directoryNames includes: 'Help') ifFalse: [^ self beep].  "no help folder"
	helpDir _ FileDirectory default directoryNamed: 'Help'.

	"use the English subfolder by default if it exists"
	(helpDir directoryNames includes: 'en') ifTrue: [subDir _ helpDir directoryNamed: 'en'].
	"use subfolder for the current language if it exists"
	(helpDir directoryNames includes: ScratchTranslator currentLanguage) ifTrue: [
		subDir _ helpDir directoryNamed: ScratchTranslator currentLanguage].
	subDir ifNotNil: [helpDir _ subDir].

	fileNames _ helpDir fileNames collect: [:s | s asLowercase].

	helpFileName _ nil.
	#(hlp gif png jpg bmp) do: [:ext |
		helpFileName ifNil: [
			helpFileName _ aStringOrNil, '.', ext.
			(fileNames includes: helpFileName asLowercase)
				ifFalse: [helpFileName _ nil]]].
	helpFileName ifNil: [^ self beep].

	World doOneCycle.  "update cursor before fetching helpForm"
	[helpForm _ Form fromFileNamed: (helpDir fullNameFor: helpFileName)]
		ifError: [^ self beep].

	HelpDialog showForm: helpForm.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/27/2008 13:49'!
pressGreenFlagButton
	"Simulate pressing the green flag button when enter key is pressed."

	flagButton on.
	World displayWorld.
	Delay waitMSecs: 100.
	flagButton off.
	World displayWorld.
	self shoutGo.

! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/23/2007 23:29'!
printTupleElement: el on: s

	(el isKindOf: Array) ifTrue: [self printTupleList: el on: s. ^ self].
	(el isKindOf: Symbol) ifTrue: [s nextPutAll: el. ^ self].
	(el isKindOf: String) ifTrue: [s nextPut: $". s nextPutAll: el. s nextPut: $". ^ self].
	(el isKindOf: ScriptableScratchMorph) ifTrue: [s nextPutAll: el objName. ^ self].
	s nextPutAll: el printString.
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/23/2007 23:30'!
printTupleList: anArray on: s

	s nextPut: $(.
	1 to: anArray size do: [:i |
		self printTupleElement: (anArray at: i) on: s.
		i = anArray size ifFalse: [s space]].
	s nextPut: $).
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jens 5/3/2010 22:16'!
processDroppedFiles
	"Process any files that have been dropped onto me."

	| droppedFiles m dropPoint fName |
	droppedFiles _ FileStream droppedFiles.
	droppedFiles size = 0 ifTrue: [^ self].
	(m _ self viewerPane target) ifNil: [^ self].
	dropPoint _ droppedFiles first.

	(droppedFiles copyFrom: 2 to: droppedFiles size) do: [:file |
		file close.
		fName _ file fullName.
		((fName asLowercase endsWith: '.scratch') | (fName asLowercase endsWith: '.sb') | (fName asLowercase endsWith: '.ypr'))
			ifTrue: [self openScratchDroppedProjectNamed: fName]
			ifFalse: [
				((fName asLowercase endsWith: '.sprite') | (fName asLowercase endsWith: '.ysp'))
					ifTrue: [self importSpriteOrProject: fName]
					ifFalse: [m importMedia: fName]]].
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 12/9/2008 23:01'!
processKeyboardEvents

	| evt ch |
	World hands do: [:h |
		[(evt _ h nextUnclaimedKeystrokeOrNil) notNil] whileTrue: [
			ch _ evt keyValue.
			evt commandKeyPressed ifTrue: [ch _ ch \\ 32].	"map cmd/alt keys to control keys"
			(ch = 3) | (ch = 13) ifTrue: [^ self pressGreenFlagButton].
			ch = 15 ifTrue: [^ self openScratchProject].
			ch = 17 ifTrue: [^ self quitScratch].
			ch = 19 ifTrue: [^ self saveScratchProjectNoDialog].
			ch = 27 ifTrue: [
				TakeOverScreen ifTrue: [
					Smalltalk fullScreenMode: false.
					Smalltalk fullScreenMode: true.
					World restoreDisplay].
				^ self].
			workPane broadcastEventNamed: 'Scratch-KeyPressedEvent' with: evt]].
! !

!ScratchFrameMorph methodsFor: 'startup' stamp: 'jens 8/2/2010 23:27'!
processSettingsFile
	"Process settings from the Scratch.ini file."

	| lang settings k |
	self class setVisibleDrives: nil.
	lang _ nil.
	AllowSharing _ true.
	ScratchFileChooserDialog clearFolderCache. "clear homeDir and last folder cache"
	settings _ self readSettingsFile.
	settings associationsDo: [:assoc |
		k _ assoc key.
		k = 'language' ifTrue: [lang _ assoc value].
		k = 'home' ifTrue: [ScratchFileChooserDialog setHomeDir: assoc value].
		k = 'visibledrives' ifTrue: [self class setVisibleDrives: assoc value].
		k = 'share' ifTrue: [(assoc value) = '0' ifTrue: [AllowSharing _ false]].
"		k = 'proxyserver' ifTrue: [ScratchUploadProgressDialog proxyServer: assoc value].
		k = 'proxyport' ifTrue: [ScratchUploadProgressDialog proxyPort: assoc value asNumberNoError]."
		k = 'keepspritesonstage' ifTrue: [self keepSpritesOnStage: assoc value asNumberNoError].
		k = 'blockcontrast' ifTrue: [assoc value = '0' ifTrue: [self blockContrastOff] ifFalse: [self blockContrastStrong]].
		k = 'threadsafemode' ifTrue: [assoc value = '0' ifTrue: [EventHatMorph threadSafeMode: false] ifFalse: [EventHatMorph threadSafeMode: true]].
		k = 'scopecontrast' ifTrue: [assoc value = '0' ifTrue: [VariableFrame scopeContrast: false] ifFalse: [VariableFrame scopeContrast: true]].
		k = 'translucentdragging' ifTrue: [assoc value = '0' ifTrue: [HandMorph translucentWhenDragging: false] ifFalse: [HandMorph translucentWhenDragging: true]].
].

	lang ifNil: [lang _ ScratchTranslator guessLanguage].
	self setLanguage: lang.
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 6/4/2009 12:33'!
processWhenConditions
	"Trigger any 'when <condition>' hats."

	| objList |
	true ifTrue: [^ self].  "disabled"
	objList _ workPane submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	objList _ objList copyWith: workPane.
	objList do: [:obj |
		obj scripts do: [:hat |
			(hat isMemberOf: WhenHatBlockMorph) ifTrue: [
				(hat hasRunningProcess not and: [hat evaluateCondition]) ifTrue: [
					hat start; layoutChanged]]]].
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 2/28/2009 14:29'!
projectComment

	^ projectInfo at: 'comment' ifAbsent: ['']
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 3/2/2009 12:56'!
projectComment: aString

	aString = DefaultNotes ifTrue: [
		projectInfo removeKey: 'comment' ifAbsent: [].
		^ self].

	projectInfo at: 'comment' put: aString asString.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 3/2/2009 12:56'!
projectCommentOrTemplate

	| s |
	s _ projectInfo at: 'comment' ifAbsent: [''].
	s size = 0 ifTrue: [s _ DefaultNotes].
	^ s
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jm 11/13/2003 20:42'!
projectDirectory

	projectDirectory ifNil: [^ FileDirectory default].
	^ projectDirectory
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 10/29/2005 10:26'!
projectInfo
	"Answer the project info dictionary."

	^ projectInfo
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 7/27/2010 21:42'!
projectIsEmpty
	"Answer true if the current project has no scripts, no variables, no special costumes or sounds, and at most a single sprite."

	| allScriptables defaultCostumes defaultSnds |
	"at most one sprite in workpane?"
	workPane submorphs size > 1 ifTrue: [^ false].
	workPane submorphs size = 1 ifTrue: [
		(workPane submorphs first isKindOf: ScratchSpriteMorph) ifFalse: [^ false]].

	allScriptables _ workPane submorphs copyWith: workPane.
	defaultCostumes _ Set
		with: ScriptableScratchMorph defaultBackgroundForm.
	defaultSnds _ Set
		with: ScriptableScratchMorph popSound
		with: ScriptableScratchMorph meowSound.

	ScratchFrameMorph defaultSprite ifNotNil: [
		ScratchFrameMorph defaultSprite media do: [:media |
			media isImage ifTrue: [defaultCostumes add: media form].
			media isSound ifTrue: [defaultSnds add: media sound]]].

	allScriptables do: [:m |
		m customBlocks ifNotNil: [m customBlocks size > 0 ifTrue: [^ false]].  "any custom blocks?"
		m blocksBin submorphs size > 0 ifTrue: [^ false].  "any stacks?"
		m varNames size > 1 ifTrue: [^ false].  "any variables?"
		m media do: [:media |
			(media isImage and: [(defaultCostumes includes: media form) not]) ifTrue: [^ false].
			(media isSound and: [(defaultSnds includes: media sound) not]) ifTrue: [^ false]]].

	^ true
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'jens 7/15/2010 01:31'!
projectModified
	"Record that the current project has changed since it was last saved."

	justSaved _ false.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'ee 6/2/2009 18:55'!
projectName

	^ self nameFromFileName: projectName
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 10/26/2008 17:44'!
projectName: aString

	projectName _ aString.
	projectTitleMorph contents: aString.
	self fixLayout.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 23:52'!
purgeBlockEditors
	blockEditors _ blockEditors reject: [:each | 
		each isInWorld not]! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/26/2009 20:48'!
quitScratch
	"Quit from Scratch. Ask the user if they want to save, first."

	| response |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	(justSaved or: [self projectIsEmpty]) ifFalse: [
		response _ ScratchCloseDialog new getUserResponse.
		response = #cancelled ifTrue: [^ self].
		response ifTrue: [
			self saveScratchProjectNoDialog.
			justSaved ifFalse: [^ self]]].

	Smalltalk snapshot: false andQuit: true.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/3/2010 00:30'!
randomProjectName
	| dir projects |
"	dir _ ScratchFileChooserDialog getDefaultFolderForType: #project."

	(FileDirectory default directoryExists: 'Projects') 
		ifTrue: [ dir _ FileDirectory default directoryNamed: 'Projects']
		ifFalse: [ Smalltalk quitPrimitive ].

	projects _ dir fileNames
				select: [:fn | (fn asLowercase endsWith: '.sb')
						or: [(fn asLowercase endsWith: '.scratch')
						or: [fn asLowercase endsWith: '.ypr']]].
	projects size > 0 ifTrue: [^ dir fullNameFor: (projects asArray at: Random new next * projects size + 1)].
	^ nil! !

!ScratchFrameMorph methodsFor: 'startup' stamp: 'jm 3/2/2009 12:56'!
readDefaultNotes
	"If there is a file named 'defaultNotes.txt' in the Scratch folder, read it in."

	| dir |
	DefaultNotes _ ''.
	dir _ FileDirectory default.
	(dir fileExists: 'defaultNotes.txt') ifTrue: [
		DefaultNotes _ (FileStream oldFileNamed: 'defaultNotes.txt') contentsOfEntireFile].
! !

!ScratchFrameMorph methodsFor: 'startup' stamp: 'jens 2/1/2010 01:26'!
readSettingsFile
	"Read my settings file and answer a Dictionary of settings."
	"ScratchFrameMorph new readSettingsFile"

	| f dict s tokens k |
	f _ FileStream readOnlyFileNamedOrNil: 'BYOB.ini'.
	f ifNil: [^ Dictionary new].
	dict _ Dictionary new.
	f contentsOfEntireFile lines do: [:line |
		s _ line collect: [:c | (c asciiValue < 32) ifTrue: [Character space] ifFalse: [c]].
		tokens _ s findTokens: '='.
		k _ tokens first withBlanksTrimmed asLowercase.
		tokens size = 2
			ifTrue: [dict at: k put: tokens second withBlanksTrimmed]
			ifFalse: [dict at: k put: '1']].
	^ dict
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'ee 11/4/2008 11:46'!
rebuildUIForNewLanguage
	"Rebuild my UI after the language or font has been changed."

	World fullRepaintNeeded.
	viewerPane rebuildCategorySelectors.
	self updatePanes.
	self
		view: scriptsPane target
		tab: scriptsPane tabPane currentTab
		category: viewerPane currentCategory.

! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 01:31'!
recordBlockContrast: anInteger
	"Record my language in the settings file."
	"ScratchFrameMorph new recordLanguage: 'English'"

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'blockcontrast='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('BlockContrast=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/1/2010 01:35'!
recordKeepOnStage: anInteger
	"Record a setting in the settings file."

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'keepspritesonstage='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('KeepSpritesOnStage=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 2/1/2010 01:25'!
recordLanguage: aString
	"Record my language in the settings file."
	"ScratchFrameMorph new recordLanguage: 'English'"

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'language='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('Language=', aString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/2/2010 23:25'!
recordScopeContrast: anInteger
	"Record a setting in the settings file."

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'scopecontrast='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('ScopeContrast=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/9/2010 22:29'!
recordThreadSafeMode: anInteger
	"Record a setting in the settings file."

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'threadsafemode='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('ThreadSafeMode=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/13/2010 23:06'!
recordTranslucentDragging: anInteger
	"Record a setting in the settings file."

	| fName f sz settings all |
	fName _ FileDirectory default fullNameFor: 'BYOB.ini'.
	f _ FileStream concreteStream new open: fName forWrite: true.
	f ifNil: [^ self].
	sz _ f size.
	settings _ (f next: sz) lines.
	settings _ settings reject: [:s | s asLowercase beginsWith: 'translucentdragging='].
	settings _ settings reject: [:s | all _ s asByteArray asSet. (all size = 1) and: [all asArray first = 0]].
	settings _ settings copyWith: ('TranslucentDragging=', anInteger printString).
	f position: 0.
	settings do: [:s | f nextPutAll: s, String crlf].
	[f position < sz] whileTrue: [f nextPut: 0 asCharacter].
	f close.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/30/2010 23:27'!
refreshBlocks

	'updating...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((workPane allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 3
		during: [:bar | | i | i _ 0.

	(workPane submorphs copyWith: workPane) do: [:m |
	(m isKindOf: ScriptableScratchMorph) ifTrue: [
		i _ i + 1. bar value: i.
		m convertStacksToTuples]].

	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertTuplesToDefinitions]].

	(workPane submorphs copyWith: workPane) do: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertTuplesToStacks]].
	self updatePanes.
	self
		view: scriptsPane target
		tab: scriptsPane tabPane currentTab
		category: viewerPane currentCategory].
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/10/2010 21:18'!
removeBlockEditor: aBlockEditor
	blockEditors remove: aBlockEditor! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 3/28/2007 11:29'!
removeLastHistoryEntry
	"Remove the last entry in the project history. This is done if an upload attempt fails or is cancelled."

	| lines s |
	lines _ (projectInfo at: 'history' ifAbsent: ['']) lines.
	lines size = 0 ifTrue: [^ self].

	lines _ lines copyFrom: 1 to: lines size - 1.

	s _ WriteStream on: (String new: 1000).
	lines do: [:entry | s nextPutAll: entry; cr].
	projectInfo at: 'history' put: s contents.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 6/28/2008 08:48'!
renderingMenu

	ScratchTranslator renderingMenu.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 12/3/2007 21:34'!
resaveAllProjects
	"Resave all the projects in the given directory (to recompress them)."

	| dir |
	dir _ ScratchFileChooserDialog chooseFolder: FileDirectory default.
	dir = #cancelled ifTrue: [^ self].

	dir allFileNamesDo: [:fn |
		((fn asLowercase endsWith: '.sb') and:
		 [(fn endsWith: '-2.sb') not]) ifTrue: [
			self openScratchProjectNamed: fn.
			World doOneCycleNoInput.
"			projectName _ (fn copyFrom: 1 to: fn size - 3), '-3.sb'."
			self writeScratchProject]].
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/18/2007 16:26'!
revertToUncompressedMedia
	"Revert to uncomprssed media after uploading this project."

	self allProjectMedia do: [:m | m revertToUncompressed].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 6/9/2010 22:38'!
saveImageForEndUser

	(self confirm: '
Close non-Scratch windows and save this
image in end-user (fillScreen) mode?') ifFalse: [^ self].

	ScratchFrameMorph isXO ifTrue: [Preferences useLargeFonts].

	self setLanguage: 'en'.

	self enterNormalMode.
	self blockContrastStrong.
	ScriptableScratchMorph keepOnStage: true.
	self recordKeepOnStage: 1. 
	EventHatMorph threadSafeMode: false.
	self recordThreadSafeMode: 0.

	BlockLabelFragmentDialog isExpanded: false.

	World submorphs do: [:m |
		(m isKindOf: SystemWindow) ifTrue: [m delete]].
	self clearStage.

	Display newDepth: 32.
	self fillScreenOn.
	World doOneCycleNow.
	Smalltalk snapshot: true andQuit: true.
	self startup.
	Sensor useOSEvents: true.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 6/29/2010 12:57'!
saveScratchProject

	| fName result |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].
	self stopAll.

	fName _ ScratchFileChooserDialog saveScratchFileFor: self.
	(fName size = 0 or: [fName = #cancelled]) ifTrue: [^ self].

	[(result _ ScratchFileChooserDialog confirmFileOverwriteIfExisting: fName) = false] whileTrue: [
		fName _ ScratchFileChooserDialog saveScratchFileFor: self.
		(fName size = 0 or: [fName = #cancelled]) ifTrue: [^ self]].
	(result = #cancelled) ifTrue: [^ self].

"
	(ScriptableScratchMorph currentEncoding = #scratch) ifTrue: [
		(DialogBoxMorph new 
			title: 'Caution!! Converting Scratch to BYOB'; 
			withButtonsForYes: true no: true okay: false cancel: false;
			message: 'You will not be able to open this file in Scratch. Proceed anyway?';
			getUserResponse) ifFalse: [^self ]].
"
	self updateLastHistoryEntryIfNeeded.

"	fName _ (self nameFromFileName: fName), '.sb'."

	fName _ (self nameFromFileName: fName), '.ypr'.
	projectDirectory _ FileDirectory on: (FileDirectory dirPathFor: fName).
	projectName _ FileDirectory localNameFor: fName.

	projectInfo at: 'author' put: author.
	self updateHistoryProjectName: projectName op: 'save'.
	self writeScratchProject.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 5/3/2010 22:20'!
saveScratchProjectNoDialog

	| fName dir |
	self closeMediaEditorsAndDialogs ifFalse: [^ self].

	projectName ifNil: [projectName _ ''].
	fName _ self nameFromFileName: projectName.

	dir _ ScratchFileChooserDialog getLastFolderForType: #project.
"	(fName size = 0 | (dir fileExists: fName , '.sb') not) ifTrue: [^ self saveScratchProject]."
	(fName size = 0 | (dir fileExists: fName , '.ypr') not) ifTrue: [^ self saveScratchProject].
	ScratchFileChooserDialog lastFolderIsSampleProjectsFolder ifTrue:  [^ self saveScratchProject].

"
	(ScriptableScratchMorph currentEncoding = #scratch) ifTrue: [
		(DialogBoxMorph new 
			title: 'Caution!! Converting Scratch to BYOB'; 
			withButtonsForYes: true no: true okay: false cancel: false;
			message: 'You will not be able to open this file in Scratch. Proceed anyway?';
			getUserResponse) ifFalse: [^self ]].
"
	self updateLastHistoryEntryIfNeeded.

"	projectName _ FileDirectory localNameFor: (fName, '.sb'). " "ignore path, if any; save in the original project directory"
	projectName _ FileDirectory localNameFor: (fName, '.ypr').  "ignore path, if any; save in the original project directory"
	projectDirectory _ dir.

	self updateHistoryProjectName: projectName op: 'save'.
	self writeScratchProject.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 6/23/2004 09:54'!
scratchObjects
	"Answer a collection of all the scratch objects in the work pane."

	^ self workPane submorphs select: [:m | m isKindOf: ScriptableScratchMorph]
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'tis 7/31/2006 09:08'!
scratchWatchers
	"Answer a collection of all the scratch watchers in the work pane."

	^ self workPane submorphs select: [:m | m isKindOf: WatcherMorph]
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 7/20/2003 12:13'!
scriptsPane

	^ scriptsPane
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jm 10/23/2007 23:34'!
scriptsStringForUpload

	| s scripts |
	s _ WriteStream on: (String new: 10000).
	((Array with: workPane), self scratchObjects) do: [:obj |
		scripts _ obj blocksBin submorphs select: [:m | m isKindOf: HatBlockMorph].
		scripts size > 0 ifTrue: [
			s nextPutAll: 'Scripts for ', obj objName, ':'; cr; cr.
			scripts do: [:hat | self printTupleList: hat tupleSequence on: s. s cr].
			s cr]].
	^ s contents
! !

!ScratchFrameMorph methodsFor: '-- all --' stamp: 'jens 5/3/2010 22:31'!
setDefaultSprite
	"Look for default sprite in Media directory. If none found, use the DefaultCatSprite"

	| d f data importedProject fName |

	DefaultSprite _ nil.

	"if dfault.ysp exists, use that"
	d _ ScratchFileChooserDialog getDefaultFolderForType: #costume.
	(d fileExists: 'default.ysp') ifTrue: [
		f _ (FileStream readOnlyFileNamed: (d fullNameFor: 'default.ysp')) binary.
		f ifNotNil: [
			data _ f contentsOfEntireFile.
			importedProject _ [self extractProjectFrom: data] ifError: [nil].
			importedProject ifNil: [^ self].

			"add imported global custom block definitions"
"
			importedProject customBlocks ifNotNil: [
				importedProject customBlocks do: [:eachDef |
					workPane sprites, {workPane} do: [:obj |
						obj
							updateCustomBlockDefinitionId: eachDef id with: eachDef;
							updateLocalId: eachDef id withSpec: eachDef userSpec]]].
"

			importedProject submorphs do: [:m |
				(m isKindOf: ScratchSpriteMorph) ifTrue: [DefaultSprite _ m].
				^ self]]].

	"if default image exists, use the image and add 'pop' sound"
	#(gif png jpg bmp) do: [:e |
		fName _ 'default.', e.
		(d fileExists: fName) ifTrue: [
			DefaultSprite _ ScratchSpriteMorph new
				importMedia: (d fullNameFor: fName);
				addMediaItem: (SoundMedia new
					mediaName: 'pop' localized;
					sound: ScratchSpriteMorph popSound).
			^ self]].
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 6/30/2010 23:27'!
setLanguage: aString
	"Set my language and update my blocks."

	| tempJustSaved |

	self closeDialogBoxes.

	'updating...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((workPane allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 2
		during: [:bar | | i | i _ 0.

	tempJustSaved _ justSaved.
	(workPane submorphs copyWith: workPane) do: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertStacksToTuples]].

	ScratchTranslator setLanguage: (ScratchTranslator isoCodeForName: aString).
	viewerPane rebuildCategorySelectors.

	(workPane submorphs copyWith: workPane) do: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertTuplesToStacks]].
	self updatePanes.
	self
		view: scriptsPane target
		tab: scriptsPane tabPane currentTab
		category: viewerPane currentCategory.
	justSaved _ tempJustSaved].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'ee 11/10/2007 19:05'!
setSingleStepping
	"Ask whether script should be single-stepped."

	| menu mSecs |
	menu _ CustomMenu new title: 'Single-step speed?'.
	menu add: 'Turbo speed' action: 0.
	menu add: 'Normal' action: 1.
	menu add: 'Flash blocks (fast)' action: 30.
	menu add: 'Flash blocks (slow)' action: 200.
	mSecs _ menu localize startUp.
	mSecs ifNil: [^ self].
	ScratchProcess blockHighlightMSecs: mSecs.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 8/17/2009 00:12'!
shareMenu: aMenuTitleMorph

	| menu stage |
	menu _ CustomMenu new.
	menu add: 'Compile This Project' action: #makeExe.
	menu addLine.
	self addServerCommandsTo: menu.

	stage _ workPane.
	stage ifNotNil: [
		(stage scratchServer notNil and: 
		[stage scratchServer sessionInProgress])
			ifTrue: [
				menu add: 'share this sprite' action: #shareSprite ]].

	menu localize.

	#(1) do: [:n |
		menu labels at: n put:
			((menu labels at: n) copyFrom: 1 to: (menu labels at: n) size - 1), ScratchTranslator ellipsesSuffix].

	menu invokeOn: self at: aMenuTitleMorph bottomLeft + (0@10).

! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/16/2009 23:53'!
shareSprite

	scriptsPane target shareObject.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 5/19/2010 03:40'!
shoutGo
	"Broadcasts the start event to all objects and processes."

	self stopAll.
	workPane broadcastEventNamed: 'Scratch-StartClicked' with: 0.
	flagButton on.
	self showPause.
	World displayWorldSafely.  "force button flash"
	Delay waitMSecs: 20.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/26/2009 22:21'!
showMotorBlocks

	workPane showMotorBlocks: true.
	viewerPane currentCategory: 'motion'.
	viewerPane pageViewer vScrollRelative: 1.0.! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/14/2009 10:33'!
showNetworkAddress
	"Display my IP address. This is a temporary feature to allow connected multiple Scratch computers in a peer-to-peer configuration without the help of a presence server."

	| localAddr wanAddr msg |
	Socket initializeNetwork.
	localAddr _ NetNameResolver localHostAddress.
	wanAddr _ nil.
"	wanAddr _ ScratchServer getIPAddressFromServer."

	msg _ NetNameResolver stringFromAddress: localAddr.
	(wanAddr notNil and: [wanAddr ~= localAddr]) ifTrue: [
		msg _ msg, String cr, 'Internet:   ', (NetNameResolver stringFromAddress: wanAddr)].

	DialogBoxMorph inform: msg title: 'IP Address'.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/19/2010 03:38'!
showPause

	pauseButton
		onForm: (ScratchFrameMorph skinAt: 'pauseButtonGrayPressed' asSymbol)
		offForm: (ScratchFrameMorph skinAt: 'pauseButtonGray'asSymbol)
		overForm: (ScratchFrameMorph skinAt: 'pauseButtonGrayPressed' asSymbol)
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/19/2010 03:39'!
showPlay

	pauseButton
		onForm: (ScratchFrameMorph skinAt: 'playButtonGrayPressed' asSymbol)
		offForm: (ScratchFrameMorph skinAt: 'playButtonGray'asSymbol)
		overForm: (ScratchFrameMorph skinAt: 'playButtonGrayPressed' asSymbol)
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 10/31/2006 20:59'!
showSensorBoard

	| sb |
	sb _ workPane sensorBoard.
	sb position: self workPane position + 20.
	self workPane addMorph: sb.
	sb tryToOpenPort.
	World startSteppingSubmorphsOf: sb.
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 8/25/2008 10:05'!
showWatcher: watcher
	"Show the given watcher. Reuse it's old position if it was showing before. Otherwise, find a new position for it."

	| rec style range |
	rec _ watcherPositions
		at: {watcher getAssociatedSprite. watcher selectorAndArg}
		ifAbsent: [nil].
	rec
		ifNil: [
			watcher position: self unusedPositionForWatcher.
			style _ #small.
			range _ watcher sliderRange]
		ifNotNil: [
			watcher position: workPane position + rec second.
			style _ rec third.
			range _ rec fourth].

	watcherPositions
		at: {watcher getAssociatedSprite. watcher selectorAndArg}
		put: {watcher. (watcher position - workPane position). style. range}.

	watcher sliderRange: range.
	watcher layoutStyle: style.
	watcher updateTargetName.
	workPane addMorph: watcher.
	watcher world ifNotNil: [watcher world startSteppingSubmorphsOf: watcher].

! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/14/2009 10:33'!
startHostingScratchSession
	"Start running the Scratch server, allowing Scratch and other applications to interact with this Scratch remotely."

	| server |
	workPane scratchServer ifNil: [
		server _ ScratchServer new.
		server stage: workPane.
		workPane scratchServer: server].

	workPane scratchServer startHosting.
	self showNetworkAddress.
! !

!ScratchFrameMorph methodsFor: 'startup' stamp: 'jens 8/3/2010 00:16'!
startup

	| startupFileNames fileName arg presentationMode |

	HostSystemMenus startUp.
	HostSystemMenus menuBarControler reviseHostMenus.

	ScriptableScratchMorph randomInit.
	ScratchTranslator detectRenderPlugin.
	ScratchTranslator importLanguagesList.

	ScratchFrameMorph readShareServerEntry.
	BlockMorph contrastStrong.
	self keepSpritesOnStage: 1.
	EventHatMorph threadSafeMode: false.
	HandMorph translucentWhenDragging: true.
	VariableFrame scopeContrast: false.
	self processSettingsFile.
	self readDefaultNotes.

	BlockEditorFrameMorph resetDimensions.
	ElementsEditorFrameMorph resetDimensions.
	DebuggerFrameMorph resetDimensions.

	self updateProjectName.
	shuffledCostumeNames _ nil.
	author _ ''.
	loginName _ ''.
	loginPassword _ ''.
	justSaved _ true.
	presentationMode _ false.

	startupFileNames _ InputSensor startupFileNames asOrderedCollection.
	2 to: 10 do: [:i |
		arg _ Smalltalk getSystemAttribute: i.
		(arg notNil and: [arg size > 0]) ifTrue: [
			startupFileNames addLast: (ScratchPlugin primShortToLongPath: arg)]].

	startupFileNames do: [:n |
		(n asLowercase = 'presentation') ifTrue: [
			quitFlag _ true. 
			presentationMode _ true.
			self isHidden: true.
			Display fillBlack].
		(n asLowercase = 'fullscreen') ifTrue: [TakeOverScreen _ true]].

	TakeOverScreen ifTrue: [
		Smalltalk fullScreenMode: true.
		World restoreDisplay].

	self enterQuarterModeIfSmallScreen.

	fileName _ startupFileNames
		detect: [:fn |
			(fn asLowercase endsWith: '.sb') or: [(fn asLowercase endsWith: '.scratch') or: [fn asLowercase endsWith: '.ypr']]]
		ifNone: [presentationMode ifTrue: [self randomProjectName]]. "this is BYOB's screensaver feature -jens"
	fileName ifNotNil: [
		presentationMode ifTrue: [Display fillColor: Color black].
		self openScratchProjectNamed: fileName.
		presentationMode ifTrue: [self enterPresentationMode; shoutGo].
		^ self].

	viewerPane currentCategory: 'motion'.
	self setDefaultSprite.
	self newScratchProject.

	fileName _ startupFileNames
		detect: [:fn | (fn asLowercase endsWith: '.sprite') or: [fn asLowercase endsWith: '.ysp']]
		ifNone: [^ self].

	"open a .sprite file"
	workPane submorphs do: [:m | (m isKindOf: ScratchSpriteMorph) ifTrue: [m deleteSprite]].
	self importSpriteOrProject: fileName.
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jens 3/9/2011 22:47'!
step
	"Run each process until it gives up control, then filter out any processes that have terminated."

	| screenExtent oldJustSaved |
	fillScreenFlag ifTrue: [
		screenExtent _ Display extent.
		((self position = (0@0)) and: [self extent = screenExtent]) ifFalse: [
			oldJustSaved _ justSaved.
			self position: 0@0.
			self extent: screenExtent.
			self enterQuarterModeIfSmallScreen.
			scriptsPane currentCategory: scriptsPane currentCategory.
			justSaved _ oldJustSaved.
			^ self]].

	workPane ifNotNil: [
		ScriptableScratchMorph scratchOrigin: workPane center.
		viewerPane target isNil 
			ifTrue: [workPane viewBlocksAndScripts]
			ifFalse: [viewerPane target isInWorld ifFalse: [workPane viewBlocksAndScriptsQuickly]]].

	Sensor processOSMenuEvents.
	paintingInProgress ifTrue: [^ self].

	workPane scratchServer ifNotNil: [workPane scratchServer stepServer].
	self checkForWeDo.
	self updateToolButtons.
	self processWhenConditions.
	self processKeyboardEvents.
	workPane stepProcesses.
	workPane scratchServer ifNotNil: [workPane scratchServer stepServer].
	self processDroppedFiles.
	workPane processesToRun size > 0
		ifTrue: [flagButton on]
		ifFalse: [flagButton off. self showPause]
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 7/9/2003 12:02'!
stepTime
	"Every screen update cycle."

	^ 0
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jens 5/18/2010 01:57'!
stopAll
	"Tell my workPane to stop everything."

	| oldJustSaved |
	oldJustSaved _ justSaved.
	workPane stopAll.
	pauseButton off.
	justSaved _ oldJustSaved.
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 7/27/2010 13:43'!
storeProjectInfoOn: aBinaryStream

	| s |
	projectInfo at: 'thumbnail' put: workPane thumbnailForm.
	projectInfo at: 'keepOnStage' put: ScriptableScratchMorph keepOnStage.

	s _ WriteStream on: (ByteArray new: 100000).
	ObjStream new storeObj: projectInfo on: s.

	aBinaryStream uint32: s size.
	aBinaryStream nextPutAll: s contents.

! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 12/8/2008 12:05'!
surpriseSpriteMorph

	| fileName f el m e |
	self world activeHand toolType: nil.
	self paintingInProgress ifTrue: [^ self beep].

	fileName _ self nextSurpriseCostumeName.
	fileName ifNil: [
		^ self addAndView: ScratchFrameMorph defaultSprite fullCopy].

	[f _ Form fromFileNamed: fileName] ifError: [^ self].
	el _ ImageMedia new form: (ScratchFrameMorph scaledFormForPaintEditor: f).
	m _ ScratchSpriteMorph new soleCostume: el.
	el mediaName: (m unusedMediaNameFromBaseName: (FileDirectory localNameFor: fileName)).
	self addAndView: m.

	e _ (workPane extent - m extent) abs // 2.
	m referencePosition: ((e x negated) to: e x) atRandom @ ((e y negated) to: e y) atRandom.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 9/29/2003 23:19'!
toggleErrorCatcher

	UseErrorCatcher _ UseErrorCatcher not.
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 4/21/2010 00:37'!
toggleKeepSpritesOnStage
	| choice |
	ScriptableScratchMorph keepOnStage: ScriptableScratchMorph keepOnStage not.
	ScriptableScratchMorph keepOnStage
		ifTrue: [choice _ 1]
		ifFalse: [choice _ 0].
	self recordKeepOnStage: choice! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 5/19/2010 03:39'!
togglePause
	workPane togglePause.
	workPane isPaused
		ifTrue: [self showPlay]
		ifFalse: [self showPause]
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/2/2010 23:29'!
toggleScopeContrast
	| choice |
	VariableFrame scopeContrast: VariableFrame scopeContrast not.
	VariableFrame scopeContrast
		ifTrue: [choice _ 1]
		ifFalse: [choice _ 0].
	self refreshBlocks.
	self recordScopeContrast: choice! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/2/2010 23:22'!
toggleShowMotorBlocks

	workPane showMotorBlocks
		ifTrue: [self hideMotorBlocks]
		ifFalse: [self showMotorBlocks]! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/14/2005 15:13'!
toggleSingleStepping
	"Toggle single stepping."

	ScratchProcess blockHighlightMSecs <= 1
		ifTrue: [ScratchProcess blockHighlightMSecs: 60]
		ifFalse: [ScratchProcess blockHighlightMSecs: 1].
! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/9/2010 22:36'!
toggleThreadSafeMode
	| choice |
	EventHatMorph threadSafeMode: EventHatMorph threadSafeMode not.
	EventHatMorph threadSafeMode
		ifTrue: [choice _ 1]
		ifFalse: [choice _ 0].
	self recordThreadSafeMode: choice! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 7/13/2010 23:09'!
toggleTranslucentDragging
	| choice |
	HandMorph translucentWhenDragging: HandMorph translucentWhenDragging not.
	HandMorph translucentWhenDragging
		ifTrue: [choice _ 1]
		ifFalse: [choice _ 0].
	self recordTranslucentDragging: choice! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 6/18/2010 02:17'!
toggleTurboMode

	self isTurbo ifTrue: [
		^ ScratchProcess blockHighlightMSecs: 1].
	ScratchProcess blockHighlightMSecs: 0! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 2/2/2010 22:58'!
toggleZebraColoring

	BlockMorph contrast = #off
		ifTrue: [self blockContrastStrong]
		ifFalse: [self blockContrastOff]! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/17/2009 00:44'!
undoLastDrop

	scriptsPane currentCategory: 'Scripts'.
	scriptsPane target blocksBin undoLastDrop! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jens 2/24/2011 22:14'!
undoTool

	| m newOwner oldName |
	self paintingInProgress ifTrue: [^ self beep].
	Clipboard ifNil: [^ self beep].
	self activeHand toolType: nil.
	m _ Clipboard fullCopy.
	((m isKindOf: BlockMorph) and: [m isCustomBlock and: [m definition isNil]])
		ifTrue: [^ self beep].
	"Reset clipboard to empty since an undo just happened"
	
	(m isKindOf: BlockMorph) ifTrue: [
		newOwner _ viewerPane target.
		newOwner ifNotNil: [m newScriptOwner: newOwner].
		(viewerPane currentCategory = 'variables') ifTrue: [
			"update 'variables' category if it is showing"
			viewerPane currentCategory: 'variables']].

	(m isKindOf: ScratchSpriteMorph) ifTrue: [  "sprite; add to stage"
		m filterReset; show.
		m objName: Clipboard objName.
		Clipboard _ nil.
		oldName _ m objName.
		self addAndView: m.
		m objName: oldName.
		^ self].

	"blocks or anything else: attach to hand"
	self activeHand attachMorph: m.
	Clipboard _ nil.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 6/14/2007 18:44'!
uniqueSummaryFileName

	| baseName fileName n |
	baseName _ self projectName.
	baseName size <= 1 ifTrue: [baseName _ 'newProject'].
	fileName _ baseName, '-summary.txt'.
	n _ 1.

	[FileDirectory default fileExists: fileName] whileTrue: [
		fileName _ baseName, n printString, '-summary.txt'.
		n _ n + 1].

	^ fileName

! !

!ScratchFrameMorph methodsFor: 'byob' stamp: 'jens 8/5/2010 10:44'!
unloadAllUnusedCustomBlocks

	workPane unloadAllUnusedCustomBlocks! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'ee 6/28/2008 15:27'!
unusedPositionForWatcher
	"Return an unused watcher position on the stage."

	| watchers positions rowH x y newX |
	watchers _ (watcherPositions collect: [:r | r first]) select: [:w | w notNil].
	positions _ watchers collect: [:w | w position].

	(watchers size > 0)
		ifTrue: [rowH _ (watchers at: 1) height]
		ifFalse: [rowH _ 25].
	x _ workPane left + 10.
	y _ workPane top + 10.
	[positions includes: (x@y)] whileTrue: [
		y _ y + rowH.
		(y > (workPane bottom - rowH)) ifTrue: [  "start a new column"
			newX _ 0.
			watchers do: [:w |
				w left < (x + 20) ifTrue: [newX _ newX max: w right + 4]].
			newX > (workPane right - 20) ifTrue: [
				^ ((10 to: 400) atRandom) @ ((10 to: 330) atRandom)].  "no free location"
			x _ newX.
			y _ workPane top + 10]].

	^ x@y
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 6/29/2010 13:01'!
updateHistoryProjectName: projName op: operation
	"The given user is about to save or upload a project with the given name. Update the project history. operation is a string specifying the operation."

	| timestamp tab history platform osVersion |
	projectInfo removeKey: 'organization' ifAbsent: [].	"obsolete"
	projectInfo at: 'scratch-version' put: Version.

	timestamp _ (Date today printFormat: #(3 2 1 $- 1 1)), ' ', Time now print24.
	tab _ String tab.

	history _ projectInfo at: 'history' ifAbsent: [''].
	history _ history, timestamp, tab.
	history _ history, operation, tab, (self nameFromFileName: projName), tab, loginName, tab, author.
	history _ history, String cr.
	projectInfo at: 'history' put: history.

	"record other data"
	projectInfo at: 'scratch-version' put: Version.
	projectInfo at: 'language' put: ScratchTranslator currentLanguage.

	platform _ Smalltalk platformName.
	platform ifNil: [platform _ 'unknown'].
	'linux' = platform ifTrue: [
		Display extent = (1200@900) ifTrue: [platform _ 'XO']].
	projectInfo at: 'platform' put: platform.

	osVersion _ Smalltalk osVersion.
	osVersion ifNil: [osVersion _ 'unknown'].
	projectInfo at: 'os-version' put: osVersion.

	(workPane scratchServer notNil and:
	 [workPane scratchServer isHosting])
		ifTrue: [projectInfo at: 'isHosting' put: true]
		ifFalse: [projectInfo removeKey: 'isHosting' ifAbsent: []].

	(self allBlocksString includesSubString: 'motor')
		ifTrue: [projectInfo at: 'hasMotorBlocks' put: true]
		ifFalse: [projectInfo removeKey: 'hasMotorBlocks' ifAbsent: []].

	workPane penTrailsForm
		ifNil: [projectInfo removeKey: 'penTrails' ifAbsent: []]
		ifNotNil: [projectInfo at: 'penTrails' put: workPane penTrailsForm].

! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jm 3/28/2007 12:43'!
updateLastHistoryEntryIfNeeded
	"If the the last entry in this project's history is an old-sytle entry (i.e. one that does not include the project name and author) update it."

	| lines lastLine oldAuthor tab s |
	lines _ (projectInfo at: 'history' ifAbsent: ['']) lines.
	lines size = 0 ifTrue: [^ self].
	lastLine _ lines at: lines size.
	(lastLine includes: Character tab) ifTrue: [^ self].  "last line is already a new-style entry"

	oldAuthor _ projectInfo at: 'author' ifAbsent: [''].
	tab _ String tab.
	lastLine _ lastLine, tab, 'old', tab, projectName, tab, "blank scratchr name" tab, oldAuthor.
	lines at: lines size put: lastLine.

	s _ WriteStream on: (String new: 1000).
	lines do: [:entry | s nextPutAll: entry; cr].
	projectInfo at: 'history' put: s contents.
! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'ee 4/14/2008 15:01'!
updateMediaCategoryFor: anObject
	"Update the media viewer for the given object's media category. Do nothing if the media category of the given object is not being viewed."

	scriptsPane target = anObject ifTrue: [
		scriptsPane categoryChanged: 'Sounds'.
		scriptsPane categoryChanged: 'Costumes'].
	viewerPane target = anObject ifTrue: [
		viewerPane categoryChanged: 'Sound'].
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 11/19/2009 21:45'!
updatePanes

	| p |
	menuPanel delete.
	self createMenuPanel.

	toolbarPanel delete.
	self createToolbar.

	viewModeButtonsPanel delete.
	self createViewModeButtonsPanel.

	stageButtonsPanel delete.
	self createStageButtonsPanel.
	titlePane addMorph: stageButtonsPanel.

	scriptsPane tabPane delete.
	scriptsPane createTabPane.

	readoutPane delete.
	self createReadoutPane.

	workPane sensorBoard owner
		ifNil: [p _ nil]
		ifNotNil: [p _ workPane sensorBoard position].

	workPane sensorBoard addReadouts.
	p ifNotNil:[
		self showSensorBoard.
		workPane sensorBoard position: p].

	libraryPane clearLibrary.

	self scratchWatchers do: [:w | w languageChanged].
	self listWatchers do: [:w | w fixLayoutForNewLanguage].

	World startSteppingSubmorphsOf: self.
	self fixLayout.
	scriptsPane fixLayout.
	self updateViewModeButtons.
! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'jm 11/15/2006 17:10'!
updatePenPositions
	"Update the pen positions of my sprites when going between normal and presentation mode."

	| stage |
	stage _ self workPane.
	ScriptableScratchMorph scratchOrigin: stage center.
	stage submorphsDo: [:m | stage updatePenPositionFor: m].
! !

!ScratchFrameMorph methodsFor: 'private' stamp: 'jens 8/14/2009 02:10'!
updateProjectName
	"Update the project name display in the Scratch title bar."

	| s |
	projectName ifNil: [projectName _ ''].
	projectTitleMorph contents: (self nameFromFileName: projectName).

	projectTitleMorph contents size > 0
		ifTrue: [s _ projectTitleMorph contents, '- BYOB']
		ifFalse: [s _ 'BYOB ', Version].
	ScratchPlugin primSetWindowTitle: s.

	self fixLayout.
! !

!ScratchFrameMorph methodsFor: 'stepping' stamp: 'jm 4/22/2009 08:36'!
updateToolButtons
	"Update the highlighting of my tool buttons."

	| toolButtons currentTool |
	Sensor anyButtonPressed ifTrue: [^ self].  "don't update if mouse button pressed"

	toolButtons _ toolbarPanel submorphs select: [:m |
		(m isKindOf: ToggleButton) and: [m actionSelector endsWith: 'Tool']].

	currentTool _ (World activeHand toolType ifNil: ['none']) asLowercase.
	toolButtons do: [:b |
		(b actionSelector asLowercase = currentTool)
			ifTrue: [b on]
			ifFalse: [b off]].

! !

!ScratchFrameMorph methodsFor: 'view mode' stamp: 'ee 12/5/2008 17:27'!
updateViewModeButtons

	viewModeButtons do: [:b | b off].
	viewModeButtons do: [:b |
		(b actionSelector = #enterQuarterMode and: [viewMode = #quarter])
			ifTrue: [b on].
		(b actionSelector = #enterNormalMode and: [viewMode = #normal])
			ifTrue: [b on].
		(b actionSelector = #enterPresentationMode and: [viewMode = #presentation])
			ifTrue: [b on]].
! !

!ScratchFrameMorph methodsFor: 'version control' stamp: 'JM 11/9/2011 17:12'!
versionControlExport
	"Outputs all classes that have changed since the project start date to a directory that should be managed by an external revision control system."

	| dir date |

	dir _ self class versionControlDirectory.
	date _ self class versionControlStartDate.
	
	dir fileOutClassesChangedSince: date.	! !

!ScratchFrameMorph methodsFor: 'version control' stamp: 'JM 11/9/2011 17:12'!
versionControlImport
	"Updates the classes in the Squeak VM by importing them from a 'Classes' directory that should be managed by your revision control system."

	self class versionControlDirectory fileInContents! !

!ScratchFrameMorph methodsFor: 'other' stamp: 'ee 11/4/2008 11:45'!
view: aMorph tab: t category: c
	"Add given morph to the work pane and view it."

	scriptsPane target: aMorph.
	scriptsPane tabPane currentTab: t.
	viewerPane
		target: aMorph;
		currentCategory: c.
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'ee 12/30/2008 13:47'!
viewMode

	^ viewMode
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 7/20/2003 12:08'!
viewerPane

	^ viewerPane
! !

!ScratchFrameMorph methodsFor: 'dropping/grabbing' stamp: 'ee 5/14/2008 12:55'!
wantsDroppedMorph: aMorph event: evt

	^ (aMorph isKindOf: BlockMorph) or: [
	  	(aMorph isKindOf: ScriptableScratchMorph) or: [
			(aMorph isKindOf: ScratchCommentMorph)]].
! !

!ScratchFrameMorph methodsFor: 'event handling' stamp: 'jm 10/2/2006 15:48'!
wantsKeyboardFocusFor: aSubmorph
	"Don't allow shift-click edit and select in random label strings."

	^ false
! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jm 11/30/2007 19:35'!
watcherForBlock: aBlockMorph
	"Answer a watcher for the given block if there is one currently showing on the stage."

	| pair |
	pair _ watcherPositions
		at: {aBlockMorph getAssociatedSprite. aBlockMorph selectorAndArg}
		ifAbsent: [^ nil].

	^ pair first

! !

!ScratchFrameMorph methodsFor: 'watchers' stamp: 'jens 1/19/2011 00:45'!
watcherShowingFor: sprite selectorAndArg: selectorAndArg
	"Answer true if a watcher for the given sprite, selector, and argument is currently showing on the stage."

	| sel arg listM pair |
	sel _ selectorAndArg first.
	arg _ selectorAndArg second.
	#listNamed: = sel ifTrue: [
		listM _ sprite listNamed: arg ifNone: [^ false].
		^ listM owner notNil].

	pair _ watcherPositions at: {sprite. selectorAndArg} ifAbsent: [^ false].
	pair first ifNotNil: [
		pair first owner ifNil: [pair at: 1 put: nil]].
	^ pair first notNil
! !

!ScratchFrameMorph methodsFor: 'accessing' stamp: 'jm 7/20/2003 12:08'!
workPane

	^ workPane
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 6/14/2007 17:07'!
writeMultipleSummaries
	"Write the summary for all Scratch projects in a given folder."

	| dir |
	dir _ ScratchFileChooserDialog chooseFolder: FileDirectory default.
	dir = #cancelled ifTrue: [^ self].

	dir allFileNamesDo: [:fn |
		(fn asLowercase endsWith: '.scratch') | (fn asLowercase endsWith: '.sb') ifTrue: [
			self openScratchProjectNamed: fn.
			World doOneCycleNoInput.
			self writeSummaryFile: fn]].
! !

!ScratchFrameMorph methodsFor: 'file read/write' stamp: 'jens 3/3/2011 08:54'!
writeScratchProject
	"Write this Scratch project to the file named projectFile in the project directory. Called by saveScratchProject."

	| oldScriptsTarget oldTab oldViewerCategory oldPosition saveError out |
	self stopAll.

	ObjStream initialize. "just to make sure this works in filed-in changesets, -Jens"

	self world ifNotNil: [self world activeHand newKeyboardFocus: nil].  "terminates active editor"

	"share duplicate sounds and images"
	self canonicalizeSoundsBits: nil saveOriginal: false.
	self canonicalizeImagesQuality: nil saveOriginal: false.

	oldScriptsTarget _ scriptsPane target.
	oldTab _ scriptsPane tabPane currentTab.
	oldViewerCategory _ viewerPane currentCategory.
	scriptsPane target: nil.

	workPane updateSpritesList.
	oldPosition _ workPane position.
	workPane delete; position: 0@0.
	self updatePenPositions.

	ScriptableScratchMorph buildBlockSpecDictionary.



	'saving...' 
		displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
		from: 0 to: ((workPane allMorphs) select: [:m| m isKindOf: ScriptableScratchMorph]) size * 2
		during: [:bar | | i | i _ 0.

	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			(m isKindOf: ScratchSpriteMorph)
				ifTrue: [m cacheRefPos].
			m blocksBin allMorphsDo: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b stop]].
			m convertStacksToTuples]].

	saveError _ nil.
	[	out _ FileStream newFileNamed: (projectDirectory unusedNameStartingWith: 'tmp').
		out
			ifNil: [saveError _ 'Folder may be locked or read-only']
			ifNotNil: [
				out binary.
				out nextPutAll: 'BloxExpV01' asByteArray. "changed the internal version marker for the byob-prototype -Jens"
				self storeProjectInfoOn: out.
				ObjStream new storeObj: workPane on: out.
				out close].
	] ifError: [:err :rcvr |
		out ifNotNil: [
			[	out close.
				projectDirectory deleteFileNamed: out localName.
			] ifError: []]. 
		saveError _ err].

	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			i _ i + 1. bar value: i.
			m convertTuplesToStacks]]].

	self addMorph: (workPane position: oldPosition).
	oldScriptsTarget ifNil: [oldScriptsTarget _ workPane].
	oldScriptsTarget viewBlocksAndScripts.
	scriptsPane tabPane currentTab: oldTab.
	viewerPane currentCategory: oldViewerCategory.
	self updatePenPositions.
	ScriptableScratchMorph decodeAsByob. "remember that we save this project in BYOB format"

	saveError
		ifNil: [
			justSaved _ true.
			self updateProjectName.
			projectDirectory deleteFileNamed: projectName.
			[projectDirectory rename: out localName toBe: projectName]
				ifError: [^ self inform: 'Save failed' withDetails: 'Is the folder read-only?' localized].
			projectDirectory setMacFileNamed: projectName type: 'STyb' creator: 'BYOB']
		ifNotNil: [
			projectName _ ''.
			self inform: 'Save failed' withDetails: saveError].
! !

!ScratchFrameMorph methodsFor: 'uploading' stamp: 'jens 7/27/2010 13:44'!
writeScratchProjectOn: aStream
	"Write this Scratch project in a serialized form on the given stream."

	| oldScriptsTarget oldTab oldViewerCategory oldPosition storeError |
	self stopAll.
	self world ifNotNil: [self world activeHand newKeyboardFocus: nil].  "terminates active editor"

	oldScriptsTarget _ scriptsPane target.
	oldTab _ scriptsPane tabPane currentTab.
	oldViewerCategory _ viewerPane currentCategory.
	scriptsPane target: nil.

	workPane updateSpritesList.
	oldPosition _ workPane position.
	workPane delete; position: 0@0.
	self updatePenPositions.

	ScriptableScratchMorph buildBlockSpecDictionary.
	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			m blocksBin allMorphsDo: [:b |
				(b isKindOf: BlockMorph) ifTrue: [b stop]].
			m convertStacksToTuples]].

	storeError _ nil.
	[	aStream nextPutAll: 'ScratchV02' asByteArray.
		self storeProjectInfoOn: aStream.
		ObjStream new storeObj: workPane on: aStream.
	] ifError: [:err :rcvr | storeError _ err].

	workPane allMorphsDo: [:m |
		(m isKindOf: ScriptableScratchMorph) ifTrue: [
			m convertTuplesToStacks]].

	self addMorph: (workPane position: oldPosition).
	oldScriptsTarget ifNil: [oldScriptsTarget _ workPane].
	oldScriptsTarget viewBlocksAndScripts.
	scriptsPane tabPane currentTab: oldTab.
	viewerPane currentCategory: oldViewerCategory.
	self updatePenPositions.

	storeError ifNotNil: [self error: storeError].
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 6/14/2007 17:06'!
writeSummaryFile
	"Write a summary of this project to a file."

	self writeSummaryFile: ''.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 5/21/2009 10:28'!
writeSummaryFile: fullFileName
	"Write a summary of this project to a file."

	| s sprites f fName |
	s _ WriteStream on: (String new: 10000).

	s nextPutAll: 'Project: ', self projectName; crlf.
	fullFileName size > 0 ifTrue: [s nextPutAll: 'Location: ', fullFileName; crlf].
	(projectInfo includesKey: 'author') ifTrue: [
		s nextPutAll: 'Author: ', (projectInfo at: 'author'); crlf].
	(projectInfo includesKey: 'scratch-version') ifTrue: [
		s nextPutAll: 'Scratch: ', (projectInfo at: 'scratch-version'); crlf].
	(projectInfo includesKey: 'comment') ifTrue: [
		s nextPutAll: 'Notes:'; crlf.
		(projectInfo at: 'comment') lines do: [:l | s nextPutAll: '    ', l; crlf].
		s crlf].
	(projectInfo includesKey: 'history') ifTrue: [
		s nextPutAll: 'History:'; crlf.
		(projectInfo at: 'history') lines do: [:l | s nextPutAll: '    ', l; crlf].
		s crlf].

	self writeSummaryTotalsOn: s.
	s nextPutAll: '--------'; crlf.
	workPane printSummaryOn: s.
	sprites _ workPane submorphs select: [:m | m isKindOf: ScratchSpriteMorph].
	sprites do: [:m |
		s skip: -2.  "remove last crlf"
		s nextPutAll: '--------'; crlf.
		m printSummaryOn: s].
	s nextPutAll: '--------'; crlf.

	ParagraphEditor clipboardTextPut: s contents asText.

	fName _ fullFileName.
	fullFileName size = 0
		ifTrue: [
			fName _ ScratchFileChooserDialog
				chooseNewFileDefault: self uniqueSummaryFileName
				title: 'File Name?'
				type: #projectSummary.
			fName = #cancelled ifTrue: [^ self]]
		ifFalse: [
			fName _ self uniqueSummaryFileName].

	f _ StandardFileStream newScratchFileNamed: fName.
	f ifNil: [^ self].
	f nextPutAll: s contents.
	f close.
! !

!ScratchFrameMorph methodsFor: 'menu/button actions' stamp: 'jm 3/20/2007 09:50'!
writeSummaryTotalsOn: aStream
	"Write the totals for this project on the given stream."

	| sprites uniqueCostumes uniqueSounds stackCount |
	sprites _ workPane submorphs select: [:m | m isKindOf: ScriptableScratchMorph].
	sprites _ sprites asArray copyWith: workPane.
	uniqueCostumes _ IdentitySet new: 100.
	uniqueSounds _ IdentitySet new: 100.
	stackCount _ 0.
	sprites do: [:m |
		m media do: [:item |
			item isImage ifTrue: [uniqueCostumes add: item form].
			item isSound ifTrue: [uniqueSounds add: item sound]].
		stackCount _ stackCount + m blocksBin submorphCount].

	aStream nextPutAll: 'Totals: '; crlf.
	aStream nextPutAll: '    Sprites: ', (sprites size - 1) printString; crlf.
	aStream nextPutAll: '    Stacks: ', stackCount printString; crlf.
	aStream nextPutAll: '    Unique costumes: ', uniqueCostumes size printString; crlf.
	aStream nextPutAll: '    Unique sounds: ', uniqueSounds size printString; crlf.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/13/2009 15:26'!
zoomInTool

	| hand cursorForm offset |
	self paintingInProgress ifTrue: [^ self beep].
	hand _ self world activeHand.
	hand toolType: 'ZoomInTool'.

	cursorForm _ ScratchFrameMorph skinAt: #zoomInCursor.
	offset _ 8@8.

	ScratchFrameMorph isXO ifTrue: [
		cursorForm _ cursorForm magnifyBy: 1.5.
		offset _ (offset * 1.5) rounded].

	hand showTemporaryCursor: cursorForm hotSpotOffset: offset.
! !

!ScratchFrameMorph methodsFor: 'tools (no longer used)' stamp: 'jm 2/13/2009 15:26'!
zoomOutTool

	| hand cursorForm offset |
	self paintingInProgress ifTrue: [^ self beep].
	hand _ self world activeHand.
	hand toolType: 'ZoomOutTool'.

	cursorForm _ ScratchFrameMorph skinAt: #zoomOutCursor.
	offset _ 8@8.

	ScratchFrameMorph isXO ifTrue: [
		cursorForm _ cursorForm magnifyBy: 1.5.
		offset _ (offset * 1.5) rounded].

	hand showTemporaryCursor: cursorForm hotSpotOffset: offset.

! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScratchFrameMorph class
	instanceVariableNames: ''!

!ScratchFrameMorph class methodsFor: 'class initialization' stamp: 'jm 4/13/2009 21:05'!
initialize
	"self initialize"

	Clipboard _ nil.
	WorkpaneExtent _ 480@360.
	UseErrorCatcher _ true.
	AllowSharing _ true.
	DefaultNotes _ ''.

	self initFonts.
! !


!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'ee 11/10/2008 13:30'!
getFont: aSymbol
	"Get a font for a given purpose (specified by aSymbol) based on the current font setting."

	^ self isXO
		ifTrue: [FontsXO at: aSymbol]
		ifFalse: [Fonts at: aSymbol].
! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'jm 5/7/2009 11:42'!
initFonts
	"self initFonts"

	| fontSpecs fonts fontsXO |
	fontSpecs _ #(
		(Arg						Verdana		10	HelveticaMedium 14)
		(Label			VerdanaBoldNarrowSpace	10	Helvetica		18)
		(MenuTitle					VerdanaBold		14	ArialBold		16)
		(Button						VerdanaBold		10	ArialBold		16)
		(Category					VerdanaBold		10	ArialBold		16)
		(Tab						VerdanaBold		11	ArialBold		16)
		(CommentBlock				Verdana		10	Verdana		14)
		(TalkBubble					VerdanaBold		12	VerdanaBold		18)
		(ToolTip						Verdana		13	ArialBold		16)
		(ReporterToolTip				Verdana		14	ArialBold		16)
		(XYReadout					Verdana		10	Arial			14)
		(XYReadoutBold				VerdanaBold		10	ArialBold		14)
		(CostumesPage				VerdanaBold		11	ArialBold		14)
		(SoundsPage					VerdanaBold		11	ArialBold		14)
		(ViewerPage				VerdanaBold		11	ArialBold		14)
		(UpdatingStringField			VerdanaBold		11	VerdanaBold		14)
		(Watcher					VerdanaBold		10	ArialBold		14)
		(WatcherLarge				VerdanaBold		14	VerdanaBold		14)

		(PaintUtilityButton			VerdanaBold		10	ArialBold		16)
		(PaintSetRotationCenter		VerdanaBold		11	ArialBold		14)

		"Library"
		(LibraryItemName			VerdanaBold		9	ArialBold		14)
		(LibraryItemInfo			Verdana		6	Verdana		10)
		(MediaItemInfo				Verdana		9	Arial			14)

		"Dialog Boxes"
		(DialogBoxTitle				VerdanaBold		14	VerdanaBold		16)
		(DialogBoxMessage			VerdanaBold		13	VerdanaBold		16)
		(DialogBoxButton			VerdanaBold		11	VerdanaBold		16)
		(ProjectNotes				Verdana		10	Verdana		12)
		(LinkMorphDefault			VerdanaBold		10	VerdanaBold		12)
		(ShareLink					VerdanaBold		13	VerdanaBold		12)
		(SoundRecorderButton		VerdanaBold		13	VerdanaBold		12)
		(SoundRecorderTimer		NewYorkBold	10	NewYorkBold	12)
		(StringDialogTypeIn			Verdana		12	Verdana		16)
		(NewVariableDialogBox		Verdana		11	Verdana		14)
		(AboutScratch				VerdanaBold		11	VerdanaBold		14)
		(UploadTagLabel				VerdanaBold		10	VerdanaBold		12)
		(UploadTag					Verdana		10	Verdana		12)
		(UploadDialogLabel			VerdanaBold		10	VerdanaBold		12)
		(UploadDialogContents		Verdana		10	Verdana		12)
		(UploadDialogComment		Verdana		10	Verdana		12)

		"File Choosers"
		"This is the for the folder shortcuts in the file dialog"
		(FolderShortcut				Verdana		11	Verdana		14)
		(FileChooserNewFileTitle		VerdanaBold		10	VerdanaBold		14)
		(FileChooserNewFilename		Verdana		10	Verdana		12)
		(FileChooserLabel			VerdanaBold		10	VerdanaBold		14)
		(FileChooserContents			Verdana		12	Verdana		12)
		(FileChooserComment			Verdana		10	Verdana		12)
		(FilePickerDirectoryName	VerdanaBold		9	VerdanaBold		12)
		(FilePickerEntry				Verdana		11	Verdana		13)
		(FilePickerEntryHighlighted	VerdanaBold		11	VerdanaBold		13)

		(FrameMorphProjectTitle		VerdanaBold		13	ArialBold		16)
	).

	fonts _ Dictionary new.
	fontsXO _ Dictionary new.
	fontSpecs do: [:r |
		fonts at: (r at: 1) put: (StrikeFont fontName: (r at: 2) size: (r at: 3)).
		fontsXO at: (r at: 1) put: (StrikeFont fontName: (r at: 4) size: (r at: 5))].
	Fonts _ fonts.
	FontsXO _ fontsXO.
! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'jm 4/10/2008 12:00'!
isXO
	"Return true if the current skin is XO."

	^ IsXO
! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'jm 4/10/2008 12:00'!
isXO: aBoolean
	"Set the current skin style to #XO if the argument is true, normal otherwise."
	"self isXO: true"
	"self isXO: false"

	IsXO _ aBoolean.

	"aBoolean ifTrue: [(Preferences setMenuFontTo: (StrikeFont fontName: #VerdanaBold size: 18))]
			ifFalse: [(Preferences restoreDefaultFonts)]." "annoying for development"
! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'ee 12/5/2008 13:42'!
readSkinFrom: aDirectory
	"Read the Forms for my skin from the given directory and store them in myskin dictionary."
	"When in XO mode, entries in ScratchSkinXO override the corresponding entries in ScratchSkin."
	"self readSkinFrom: (FileDirectory default directoryNamed: 'ScratchSkin')"

	| dict img i xoDict |
	dict _ Dictionary new.
	xoDict _ Dictionary new.
	aDirectory fileNames do: [:fn |
		Cursor read showWhile: [
			img _ [Form fromFileNamed: (aDirectory fullNameFor: fn)] ifError: [nil]].
		img ifNotNil: [
			i _ fn findLast: [:c | c = $.].
			i = 0 ifFalse: [fn _ fn copyFrom: 1 to: i - 1].
			(fn asLowercase endsWith: '_xo')
				ifTrue: [xoDict at: (fn copyFrom: 1 to: fn size - 3) asSymbol put: img]
				ifFalse: [dict at: fn asSymbol put: img]]].
	ScratchSkin _ dict.
	ScratchSkinXO _ xoDict.

	img _ ScratchSkin at: #scriptsPaneTexture ifAbsent: [nil].
	(img notNil and: [img depth ~= 32]) ifTrue: [
		ScratchSkin at: #scriptsPaneTexture put: (img asFormOfDepth: 32)].
! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'jens 2/14/2011 01:22'!
skin
	^ScratchSkin! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'jm 4/10/2008 12:11'!
skinAt: aSymbolOrString

	^ self skinAt: aSymbolOrString ifAbsent: [ScratchSkin errorKeyNotFound]
! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'ee 12/4/2008 11:43'!
skinAt: aSymbolOrString ifAbsent: aBlock
	"Answer the skin image with the given name. In XO mode, first check to see if an entry appears in ScratchSkinXO. If so, use it. Otherwise, use the image from the normal skin dictionary."

	| k |
	k _ aSymbolOrString asSymbol.
	self isXO ifTrue: [
		k = #scriptsPaneTexture ifTrue: [^ aBlock value].
		(ScratchSkinXO includesKey: k) ifTrue: [^ ScratchSkinXO at: k]].

	^ ScratchSkin at: k ifAbsent: aBlock
! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'jm 12/8/2008 16:09'!
takeOverScreen: aBoolean
	"self takeOverScreen: true"
	"self takeOverScreen: false"

	TakeOverScreen _ aBoolean
! !

!ScratchFrameMorph class methodsFor: 'scratch skin' stamp: 'jens 5/18/2010 00:46'!
updateSkinFrom: aDirectory
	"Read the Forms for my skin from the given directory and update them in myskin dictionary."
	"When in XO mode, entries in ScratchSkinXO override the corresponding entries in ScratchSkin."
	"self updateSkinFrom: (FileDirectory default directoryNamed: 'skinRestore')"

	| dict img i xoDict |
	dict _ Dictionary new.
	xoDict _ Dictionary new.
	aDirectory fileNames do: [:fn |
		Cursor read showWhile: [
			img _ [Form fromFileNamed: (aDirectory fullNameFor: fn)] ifError: [Transcript cr; show: 'error'. nil]].
		img ifNotNil: [
			i _ fn findLast: [:c | c = $.].
			i = 0 ifFalse: [fn _ fn copyFrom: 1 to: i - 1].
			(fn asLowercase endsWith: '_xo')
				ifTrue: [xoDict at: (fn copyFrom: 1 to: fn size - 3) asSymbol put: img]
				ifFalse: [dict at: fn asSymbol put: img]]].
	dict keys do: [:key| Transcript cr; show: key. ScratchSkin at: key put: (dict at: key)].
	xoDict keys do: [:key| ScratchSkinXO at: key put: (xoDict at: key)].

	img _ ScratchSkin at: #scriptsPaneTexture ifAbsent: [nil].
	(img notNil and: [img depth ~= 32]) ifTrue: [
		ScratchSkin at: #scriptsPaneTexture put: (img asFormOfDepth: 32)].
! !


!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 2/13/2009 15:26'!
buttonLabel: aString selector: aSymbolOrNil
	"Answer a big button with the given label."

	| button |
	button _ ResizableToggleButton2 new
		offForm: (ScratchFrameMorph skinAt: #btn)
			onForm: (ScratchFrameMorph skinAt: #btnPressed);
		label: aString font: (ScratchFrameMorph getFont: #Button);
		actionSelector: aSymbolOrNil.

	^ button
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 11/17/2008 17:21'!
cameraMode

	^ #normal
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 11/17/2008 17:23'!
colorToTrack

	^ Color red

! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jens 8/14/2009 02:07'!
defaultSprite
"Return the default sprite if one was set, or the cat otherwise"

	DefaultSprite
		ifNotNil: [^ DefaultSprite]
		ifNil: [^ ScratchSpriteMorph new
			addMediaItem: (ImageMedia new
				mediaName: ('costume' localized, '1');
				form: (ScratchFrameMorph skinAt: #defaultSpriteCostume));
"			addMediaItem: (ImageMedia new
				mediaName: ('costume' localized, '2');
				form: (ScratchFrameMorph skinAt: #defaultSpriteCostume2));
			addMediaItem: (SoundMedia new
				mediaName: 'meow' localized;
				sound: ScratchSpriteMorph meowSound); "
			lookLike: ('costume' localized, '1')].
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 4/14/2008 17:57'!
palettePaneColor

	| c |
	c _ Color r: 124 g: 128 b: 131 range: 255.
	self isXO ifTrue: [c _ c mixed: 0.75 with: Color white].
	^ c
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 3/17/2007 11:43'!
parseDownloadDatabase: fileName
	"Parse the HTML file for the Scratch download database."
	"self parseDownloadDatabase: 'mlist.html'"
	"To list downloads by date:
		(db collect: [:r | r first upTo: Character space]) asBag sortedElements"

	| raw lines inTable s records r |
	raw _ (FileStream oldFileNamed: fileName) contentsOfEntireFile.
	lines _ OrderedCollection new.
	inTable _ false.
	raw lines do: [:ln |
		s _ ln withBlanksTrimmed.
		s = '</table>' ifTrue: [inTable _ false].
		inTable ifTrue: [lines addLast: s].
		s = '<table>' ifTrue: [inTable _ true]].

	records _ OrderedCollection new.
	lines _ ReadStream on: lines.
	[lines atEnd] whileFalse: [
		ln _ lines next.
		ln = '<tr>' ifTrue: [
			r _ self parseRecordFrom: lines.
			r size > 0 ifTrue: [records addLast: r asArray]]].

	^ records asArray

! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 1/21/2007 16:20'!
parseRecordFrom: lineStream
	"An HTML table record from the given stream of lines."

	| rec ln buf |
	rec _ OrderedCollection new.
	[true] whileTrue: [
		ln _ lineStream next.
		ln = '</tr>' ifTrue: [^ rec].
		(ln beginsWith: '<td>') ifTrue: [
			buf _ ln copyFrom: 5 to: ln size.
			[lineStream atEnd | (buf endsWith: '</td>')] whileFalse: [buf _ buf, ' ', lineStream next].
			buf _ buf copyFrom: 1 to: buf size - 5.
			rec addLast: buf]].
	^ rec
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 12/14/2004 23:50'!
patchWindowsVM: vmFileName quitMessage: aString
	"Modify the Squeak application (the .exe file) for Windows to display the given string when you quit. You must start with a copy of the original VM, not one that has already been modified. This file will be modified in place, so make sure you keep a copy of the original!! The string is truncated to 27 characters since it must fit into the space of the original quit message."
	"self patchWindowsVM: 'Scratch.exe' quitMessage: 'Want to quit Scratch now?'"

	| orig firstOrigByte replacement f found startPos |
	orig _ 'Quit Squeak without saving?' asByteArray.
	firstOrigByte _ orig first.

	replacement _ aString asByteArray copyFrom: 1 to: (aString size min: orig size).
	replacement size < orig size ifTrue: [  "pad with zeros to the same size as the original"
		replacement _ replacement, (ByteArray new: orig size - replacement size withAll: 0)].

	f _ (FileStream oldFileNamed: vmFileName) binary.

	found _ false.
	[f atEnd | found] whileFalse: [
		[f atEnd not and: [f next ~= firstOrigByte]] whileTrue.  "scan for first byte"
		startPos _ f position - 1.
		f position: startPos.
		found _ true.
		1 to: orig size do: [:i | f next = (orig at: i) ifFalse: [found _ false]]].

	found ifTrue: [  "over-write the original message with the replacement"
		f position: startPos.
		replacement do: [:byte | f nextPut: byte]].

	f position: f size.  "position to end of file to avoid possible file truncation"
	f close.

	found
		ifTrue: [self inform: 'New quit message installed']
		ifFalse: [self inform: 'Original quit message not found; no change made'].

! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'MD 2/12/2004 18:27'!
putInClipboard: anObject
	
	Clipboard _ anObject.! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 12/31/2006 18:38'!
quitFromMenu
	"The user is using the application menu to quit from Scratch. If there is an open Scratch window, ask the user about saving the project. Otherwise, confirm that the user really wants to quit."

	| scratchWindow |
	scratchWindow _ World submorphs detect: [:m | (m isKindOf: self)] ifNone: [nil].
	scratchWindow
		ifNil: [World hands first quitSession]
		ifNotNil: [scratchWindow quitScratch].
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'e 2/24/2009 16:27'!
readShareServerEntry
	"Check for a file containing a list of Scratch servers.
	If this file is found and it includes an entry labled '*share*' then make that entry the server and path for 'Share' uploads. 
	If this file includes an entry labeled *support* then make that entry the server and path for the 'Support' site link.
	This is meant to be done once when Scratch is first started. Other entries in this file used to appear as Scratch servers in the Scratch project open dialog."
	"self readShareServerEntry"

	| s entryList servers key shareExists |
	"set defaults in case there is no 'servers.txt' file"
	ShareServer _ 'scratch.mit.edu'.
	ShareServerPath _ '/services/upload'.
	SupportServer _ ShareServer.
	SupportServerPath _ '/support'.
	ScratchServers _ #(
"xxx
		('LTC Scratch Server'		'ltc.smm.org'			'/scratch/')
		('MIT Scratch Server'		'web.media.mit.edu'		'/~jmaloney/mit_scratch/')
xxx"
	).

	(FileDirectory default fileExists: 'servers.txt') ifFalse: [^ self].
	[s _ (FileStream readOnlyFileNamed: 'servers.txt') contentsOfEntireFile] ifError: [^ self].
	entryList _ HtmlChunker parseTabbedString: s.

	"collect Scratch servers for open dialog"
	servers _ entryList select: [:entry | (entry first beginsWith: '*share*') not].
	servers do: [:entry |
		entry size >= 3 ifTrue: [
			key _ entry first asLowercase.
			ScratchServers _ ScratchServers reject: [:e | e first asLowercase = key].
			ScratchServers _ ScratchServers copyWith: entry]].
	ScratchServers sort: [:e1 :e2 | (e1 first compare: e2 first) <= 2].

	shareExists _ true.
	"if there is a file *share* entry, it overrides the default Share server"
	entry _ entryList detect: [:e | (e first beginsWith: '*share*')] ifNone: [shareExists _ false].
	shareExists ifTrue: [
		entry size >= 3 ifTrue: [
			ShareServer _ entry at: 2.
			ShareServerPath _ entry at: 3]].

	"if there is a file *support* entry, it overrides the default Support server"
	entry _ entryList detect: [:e | (e first beginsWith: '*support*')] ifNone: [^ self].
	entry size >= 3 ifTrue: [
		SupportServer _ entry at: 2.
		SupportServerPath _ entry at: 3].
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 11/8/2006 18:09'!
scaledFormForPaintEditor: aForm
	"Answer either the given form or a copy of it scaled down to fit into the paint editor."
	"This method supports a quick fix to the following problem: When a big image is loaded onto a sprite and then edited in the image editor, (a) you cannot edit offscreen pixels and (b) if you click 'OK' to accept the edits, the image will be cropped. This fix resizes the loaded image to fit into paint editor canvas to avoid these problems. In the longer term, we should fix the paint editor to allow editing images larger than the canvas size."

	| maxExtent scale |
	maxExtent _ WorkpaneExtent.
	((aForm width <= maxExtent x) and:
	 [aForm height <= maxExtent y])
		ifTrue: [^ aForm].

	scale _ (maxExtent x / aForm width) min: (maxExtent y / aForm height).
	^ ScratchPlugin scale: aForm by: scale
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 12/31/2006 13:18'!
scratchServers

	^ ScratchServers
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 4/14/2008 17:39'!
scriptsPaneColor

	| c |
	c _ Color r: 124 g: 128 b: 131 range: 255.
	self isXO ifTrue: [c _ c mixed: 0.8 with: Color white].
	^ c
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 3/17/2009 22:02'!
setVisibleDrives: driveListString
	"Set my set of visible drives. If the argument is nil, then all drives are made visible."

	| in drive |
	VisibleDrives _ nil.
	driveListString ifNil: [^ self].

	VisibleDrives _ OrderedCollection new.
	in _ ReadStream on: driveListString.
	[in atEnd] whileFalse: [
		in skipSeparators.
		drive _ (in upTo: $,) withBlanksTrimmed.
		drive size > 0 ifTrue: [VisibleDrives addLast: drive asUppercase]].

	VisibleDrives size > 0
		ifTrue: [VisibleDrives _ VisibleDrives asArray]
		ifFalse: [VisibleDrives _ nil].
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 10/11/2006 15:02'!
shareServer
	"Answer the name of the Scratch project sharing server."

	^ ShareServer
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'e 2/24/2009 15:57'!
supportServer
	"Answer the name of the Scratch support site server."

	^ SupportServer
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'e 2/24/2009 15:57'!
supportServerPath
	"Answer the path of the Scratch support site server."

	^ SupportServerPath
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 7/19/2004 20:20'!
useErrorCatcher

	^ UseErrorCatcher
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jens 4/14/2010 11:06'!
vanity

	^ 'BYOB ', self version, ' (C) Brian Harvey & Jens M�nig'! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 8/12/2008 19:32'!
version

	^ Version
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jens 5/19/2011 12:43'!
version: aString
	"self version: '3.1.1 (', (Date today printFormat: #(1 2 3 $- 2 2)), ')'"
	"self version: '1.0'"

	Version _ aString.
	VersionDate _ Date today printFormat: #(3 2 1 $- 1 1).
!
]style[(16 23 1 152)f1b,f1,f2,f1! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 8/13/2008 15:13'!
versionDate

	^ VersionDate
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 9/27/2007 15:52'!
visibleDrives
	"For Win32. Answer a list of visible drive names or nil. If nil, then all drives are visble."

	^ VisibleDrives
! !

!ScratchFrameMorph class methodsFor: 'utilities' stamp: 'jm 4/4/2005 08:09'!
workpaneExtent
	"Answer the extent of the work pane."

	^ WorkpaneExtent
! !


!ScratchFrameMorph class methodsFor: 'byob' stamp: 'jens 1/25/2010 01:05'!
addSlotShapesToSkin

	"ScratchFrameMorph addSlotShapesToSkin"
	"ImageMorph new form: (ScratchFrameMorph skinAt: #typeCommand); openInWorld"

	| block form big slot halfList |

	"typeCommand"
	form _ Form fromFileNamed: 'command_new.png'.
	form replaceColor: Color black withColor: Color transparent.
	ScratchSkin at: #typeCommand put: (form withEmbeddedOutlineColor: Color darkGray width: 1).

	"typePredicate"
	form _ Form fromFileNamed: 'predicate_new.png'.
	form replaceColor: Color black withColor: Color transparent.
	ScratchSkin at: #typePredicate put: (form withEmbeddedOutlineColor: Color darkGray width: 1).

	"typeReporter"
	form _ Form fromFileNamed: 'reporter_new.png'.
	form replaceColor: Color black withColor: Color transparent.
	ScratchSkin at: #typeReporter put: (form withEmbeddedOutlineColor: Color darkGray width: 1).

	"typeList"
	block _ ReporterBlockMorph new color: (ScriptableScratchMorph blockColorFor: 'list'); commandSpec: '%s'.
	slot _ block argMorphs first.
	slot extent: 7 @ 4.
	form _ slot imageForm.
	form replaceColor: (form colorAt: 2@2) withColor: (ScriptableScratchMorph blockColorFor: 'list').
	halfList _ slot extent + 1.
	big _ Form extent: halfList x @ (halfList y * 2) depth: 8.
	(WarpBlt toForm: big)
		sourceForm: form;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: form boundingBox corners toRect: form boundingBox.
	(WarpBlt toForm: big)
		sourceForm: form;
		cellSize: 2; 
		combinationRule: Form paint;
		copyQuad: form boundingBox corners toRect: (form boundingBox translateBy: 0@(halfList y)).
	ScratchSkin at: #typeList put: ((big withOutlineColor: Color white width: 2) withEmbeddedOutlineColor: Color darkGray width: 1).

	"typeText"
	block _ ReporterBlockMorph new color: Color lightGray; commandSpec: '%s'.
	block argMorphs first stringExpression: '     '.
	form _ block argMorphs first imageForm.
	ScratchSkin at: #typeText put: form. 

! !

!ScratchFrameMorph class methodsFor: 'byob' stamp: 'jens 8/17/2009 00:01'!
disableSharing
	AllowSharing _ false! !


!ScratchFrameMorph class methodsFor: 'version control' stamp: 'JM 11/9/2011 17:13'!
versionControlDirectory
	"Returns the directory used by the revision control directory to store filed-out classes."

	| baseDirectory subdirName |

	baseDirectory _ FileDirectory default.	"Use the folder the image is in"
	subdirName _ 'Classes'.

	"Create the source code revision directory is it doesn't exist"
	(baseDirectory directoryExists: subdirName) 
		ifFalse: [ baseDirectory createDirectory: subdirName ].

	"Return the code directory"
	^ baseDirectory directoryNamed: subdirName	! !

!ScratchFrameMorph class methodsFor: 'version control' stamp: 'JM 11/9/2011 17:13'!
versionControlStartDate

	"Only classes that have changed since this date will be exported to the revision control system"

	^ '07/01/2011' asDate! !


ScratchFrameMorph initialize!
