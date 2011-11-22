BorderedMorph subclass: #ScratchListMorph
	instanceVariableNames: 'titleMorph addItemMorph addSublistMorph countMorph resizeMorph scrollPane emptyMorph numberMorphs cellMorphs listName target resizeOffset focusIndex lastActivityIndex highlightActive lastActivityError listLayoutNeeded deleteMorph '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Scratch-UI-Watchers'!
!ScratchListMorph commentStamp: 'jm 5/14/2008 10:59' prior: 0!
A scrollable, ordered list of editable strings.

The following are top-level submorphs:
	titleMorph
	addItemMorph
	resizeMorph
	countMorph
	scrollPane

These morphs appear inside the scroll pane:
	emptyMorph -- added/removed to indicate when list is empty
	numberMorphs -- cell numbers (indices)
	cellMorphs -- list of cells

Each cell consists of a frame containing a line-wrapping string morph.

!


!ScratchListMorph methodsFor: 'initialization' stamp: 'jm 6/28/2008 12:37'!
addScrollPane

	scrollPane _ ScrollFrameMorph2 new
		vBarInset: 16;
		hBarInset: 18;
		color: Color transparent;
		growthFraction: 0.0;
		scrollbarStartInset: 2 endInset: -2;
		contents: (Morph new color: Color transparent).

	self addMorph: scrollPane.
! !

!ScratchListMorph methodsFor: 'initialization' stamp: 'jens 4/19/2010 00:28'!
addTitleAndControls

	titleMorph _ StringMorph new contents: 'myList'; font: (ScratchFrameMorph getFont: #Label).
	deleteMorph _ (ImageMorph new form: (ScratchFrameMorph skinAt: #deleteItem)).
	addItemMorph _ (ImageMorph new form: (ScratchFrameMorph skinAt: #addItem)).
	addSublistMorph _ (ImageMorph new form: self sublistIcon).
	resizeMorph _ ScratchResizeMorph ofType: #corner.
	countMorph _ StringMorph new
		contents: '0';
		font: (ScratchFrameMorph getFont: #XYReadout);
		color: (Color gray: 0.15).

	"emptyMorph is added to contents pane when list is empty"
	emptyMorph _ StringMorph new
		contents: '(empty)' localized;
		font: (ScratchFrameMorph getFont: #CommentBlock).

	self addMorph: titleMorph.
	self addMorph: deleteMorph.
	self addMorph: addItemMorph.
	self addMorph: addSublistMorph.
	self addMorph: resizeMorph.
	self addMorph: countMorph.
! !

!ScratchListMorph methodsFor: 'initialization' stamp: 'jm 5/31/2008 11:56'!
initialize

	super initialize.
	self
		color: (Color r: (193/255) g: (196/255) b: (199/255));
		borderWidth: 2;
		borderColor: self normalBorderColor;
		useRoundedCorners.

	cellMorphs _ OrderedCollection new: 1000.
	numberMorphs _ #().
	listLayoutNeeded _ true.
	focusIndex _ 0.
	lastActivityError _ false.
	highlightActive _ false.

	self addTitleAndControls.
	self addScrollPane.

	self extent: 65@115.
! !

!ScratchListMorph methodsFor: 'initialization' stamp: 'jm 7/11/2008 15:01'!
listName: asString target: aScriptableSpriteMorph

	listName _ asString asUTF8.
	target _ aScriptableSpriteMorph.
	self updateTitle.
! !


!ScratchListMorph methodsFor: 'accessing' stamp: 'jm 5/14/2008 18:13'!
focusCell: cellMorph

	focusIndex _ cellMorphs indexOf: cellMorph ifAbsent: [1].
	World activeHand newKeyboardFocus: cellMorph firstSubmorph.
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'ee 5/6/2008 16:04'!
focusIndex

	^ focusIndex
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jens 4/19/2010 02:42'!
focusIndex: anInteger

	| cell |
	focusIndex _ anInteger.
	focusIndex > cellMorphs size ifTrue: [focusIndex _ 1].
	focusIndex < 1 ifTrue: [focusIndex _ cellMorphs size].

	cellMorphs size > 0 ifTrue: [
		cell _ cellMorphs at: focusIndex.
		(cell complexObject isKindOf: Morph) ifFalse: [
			World activeHand newKeyboardFocus: cell firstSubmorph.
			scrollPane scrollSubmorphIntoView: cell]].
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jm 5/14/2008 18:22'!
indexOfCell: cellMorph

	^ cellMorphs indexOf: cellMorph ifAbsent: [-1]
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jm 6/4/2008 19:44'!
listContents

	^ cellMorphs collect: [:m | m firstSubmorph contents].
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jm 6/4/2008 19:07'!
listName

	^ listName
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jens 9/22/2008 11:23'!
target

	^ target
! !


!ScratchListMorph methodsFor: 'dropping/grabbing' stamp: 'jm 5/15/2008 14:32'!
delete

	super delete.
	ScratchFrameMorph allInstancesDo: [:frame | frame deletingWatcher].
! !

!ScratchListMorph methodsFor: 'dropping/grabbing' stamp: 'jm 6/4/2008 18:53'!
justDroppedInto: aMorph event: evt

	(aMorph isKindOf: ScratchStageMorph) ifTrue: [
		super justDroppedInto: aMorph event: evt.
		self world ifNotNil: [self world startSteppingSubmorphsOf: self].
		^ self].

	"delete me if dropped anywhere but the stage"
	self position:  evt hand formerPosition.
	^ self delete
! !


!ScratchListMorph methodsFor: 'event handling' stamp: 'jens 4/19/2010 01:59'!
handlesMouseDown: evt

	^ self world notNil! !

!ScratchListMorph methodsFor: 'event handling' stamp: 'jens 4/19/2010 02:28'!
mouseDown: evt
	"Handle a mouse click. Left button either drags or performs click action. Right button brings up a menu."

	| p listOwner newList |

	resizeOffset _ nil.
	evt hand toolType = 'CutTool' ifTrue: [
		evt shiftPressed ifFalse: [evt hand toolType: nil].
		^ self delete].

	World activeHand showTemporaryCursor: nil.
	evt hand newKeyboardFocus: nil.
	p _ evt cursorPoint.

	((addItemMorph bounds expandBy: 2) containsPoint: p) ifTrue: [
		^ self insertLine: '' at: (self lineCount + 1)].

	((addSublistMorph bounds expandBy: 2) containsPoint: p) ifTrue: [
		newList _ ScratchListMorph new 
							listName: '' target: nil; 
							updateCountMorph; 
							startStepping;
							yourself.
		self insertLine: newList at: (self lineCount + 1).
		^ newList fixLayout].

	listOwner _ self listOwner.
	(((deleteMorph bounds expandBy: 2) containsPoint: p) and: [listOwner notNil]) ifTrue: [
		^ listOwner deleteLineAt: (listOwner indexOf: self)].

	evt rightButtonPressed
		ifTrue: [Sensor waitNoButton. ^ self rightButtonMenu]
		ifFalse:	[
			((resizeMorph bounds expandBy: 4) containsPoint: p)
				ifFalse: [evt hand grabMorph: self]
				ifTrue: [resizeOffset _ self bottomRight - p]].
! !

!ScratchListMorph methodsFor: 'event handling' stamp: 'jm 5/15/2008 14:27'!
mouseMove: evt

	resizeOffset ifNotNil: [
		self extent: (evt cursorPoint - self topLeft) + resizeOffset].
! !

!ScratchListMorph methodsFor: 'event handling' stamp: 'ee 7/31/2008 12:56'!
rightButtonMenu

	| menu |
	menu _ CustomMenu new.
	menu add: 'export' action: #exportList.
	menu add: 'import' action: #importList.
	menu addLine.
	menu add: 'hide' action: #delete.

	menu localize.
	menu labels at: 2 put: 
		((menu labels at: 2) copyFrom: 1 to: (menu labels at: 2) size - 1), ScratchTranslator ellipsesSuffix.
	menu invokeOn: self.
! !


!ScratchListMorph methodsFor: 'geometry' stamp: 'jens 4/16/2010 00:52'!
extent: aPoint

	super extent: (aPoint max: 95@115).
	self fixLayout.
! !

!ScratchListMorph methodsFor: 'geometry' stamp: 'jens 4/19/2010 00:37'!
fixLayout

	titleMorph fitContents.
	(titleMorph width > (self width - 12)) ifTrue: [
		self width: titleMorph width + 12].

	titleMorph position: (self center x - (titleMorph width // 2)) @ (self top + 5).

	self listOwner 
		ifNil: [deleteMorph isHidden: true]
		ifNotNil: [
			deleteMorph position: (self right - deleteMorph width - 3) @ (self top + 3).
			deleteMorph isHidden: false; changed].

	countMorph fitContents.

	scrollPane
		position: (self left + 2) @ (titleMorph bottom + 3);
		extent: (self width - 4) @ (self bottom - titleMorph bottom - countMorph height - 12).

	addItemMorph position: (self left + 3) @ (self bottom - addItemMorph height - 3).
	addSublistMorph position: addItemMorph position + (addItemMorph width + 1 @ 0).

	resizeMorph position: (self bottomRight - resizeMorph extent).

	self updateCountMorph.
	countMorph bottom: self bottom - 3.

	self updateContents.
! !

!ScratchListMorph methodsFor: 'geometry' stamp: 'jens 4/16/2010 00:09'!
fixLayoutForNewLanguage
	"This method updates the height and word-wrapping of cells after a language or font change."

	| cellContents oldH |
	cellMorphs size = 0 ifTrue: [self fixLayout. ^ self showEmpty].
	cellContents _ cellMorphs first firstSubmorph.
	oldH _ cellContents height.
	(cellContents isKindOf: ScratchListMorph)
		ifFalse: [ cellContents font: cellContents font].
	cellContents height = oldH ifTrue: [self fixLayout. ^ self].  "no size change"

	scrollPane vScrollRelative: 0.
	cellMorphs do: [:c | c firstSubmorph font: c firstSubmorph font].
	self fixLayout.
! !


!ScratchListMorph methodsFor: 'stepping' stamp: 'jm 6/4/2008 19:09'!
step

	self updateTitle.
	self updateBorder.
	self updateCountMorph.
	self updateIndexHighlight.
	listLayoutNeeded ifTrue: [self updateContents].
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jm 5/31/2008 11:46'!
stepTime

	^ 200
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jm 5/31/2008 13:56'!
updateBorder

	lastActivityError
		ifTrue: [self borderColor: Color red]
		ifFalse: [self borderColor: self normalBorderColor].
	lastActivityError _ false.
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jens 4/18/2010 23:35'!
updateCountMorph

	countMorph contents: 'length' localized, ScratchTranslator colonSuffix, ' ', self lineCount printString.
	countMorph left: ((self left + ((self width - countMorph width) // 2) + 3) max: (addSublistMorph right + 1))
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jens 4/19/2010 02:26'!
updateIndexHighlight
	"Update the highlighted index."

	highlightActive ifTrue: [
		numberMorphs do: [:m | m color: self indexColor].
		highlightActive _ false].
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jm 6/17/2008 21:35'!
updateTitle
	"Update my title if I am owned by a sprite and the sprite name changes."

	| s |
	listName ifNil: [^ self].

	(target isKindOf: ScratchSpriteMorph)
		ifTrue: [s _ target objName, ' ', listName]
		ifFalse: [s _ listName].

	titleMorph contents = s ifFalse: [
		titleMorph contents: s.
		self fixLayout].
! !


!ScratchListMorph methodsFor: 'list ops' stamp: 'jm 1/28/2009 11:39'!
addLettersOf: anObject

	anObject asString asUTF32 do: [:ch |
		cellMorphs addLast: (self createCell: (UTF32 with: ch) asUTF8)].

	self noteChangeAtIndex: cellMorphs size.
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jm 5/14/2008 14:19'!
clear

	cellMorphs _ cellMorphs species new: 1000.
	self updateContents.
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 11/24/2009 23:00'!
concatenatedLines

	| isSingleLetters s |
	isSingleLetters _ true.
	cellMorphs do: [:m |
		isSingleLetters ifTrue: [
			m firstSubmorph contents asString asUTF32 size <= 1 ifFalse: [isSingleLetters _ false]]].

	s _ WriteStream on: (UTF8 new: 1000).
	isSingleLetters
		ifTrue: [
			cellMorphs do: [:m | s nextPutAll: m firstSubmorph contents asString]]
		ifFalse: [
			cellMorphs do: [:m | s nextPutAll: m firstSubmorph contents asString; space].
			s position > 0 ifTrue: [s skip: -1]].

	^ s contents
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 3/21/2011 17:07'!
contains: anObject

	| s isComplex |
	isComplex _ (anObject isKindOf: ScriptableScratchMorph) 
				| (anObject isKindOf: ScratchListMorph) 
				| (anObject isKindOf: CommandBlockMorph).

	isComplex ifTrue: [
		cellMorphs do: [:m |
			m complexObject = anObject ifTrue: [^ true]].
		^ false].

	s _ anObject asString asUTF8.
	cellMorphs do: [:m |
		m complexObject = anObject ifTrue: [^ true ].
		s = m firstSubmorph contents ifTrue: [^ true]].

	^ false
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 1/20/2011 00:34'!
createCell: anObject

	| readout cell font numberRight txt double |

	txt _ anObject.
	(anObject isKindOf: String)
		ifFalse: [txt _ anObject printString].

	font _ ScratchFrameMorph getFont: #Watcher.
	readout _ ListMultilineStringMorph new
		borderWidth: 0;
		color: Color transparent;
		textColor: Color white;
		growWithText: true;
		contents: txt font: font.
	readout height: ((ScratchTranslator stringExtent: 'A' font: font) y) + 6.
	ScratchTranslator isRTL
		ifTrue: [numberRight _ self right - 5]
		ifFalse: [numberRight _ self left + self largestIndexWidth + 6].
	ScratchTranslator isRTL
		ifTrue: [readout width: self right - self left - self largestIndexWidth - 33]
		ifFalse: [readout width: self right - numberRight - 25].

	cell _ WatcherReadoutFrameMorph new
		color: ScriptableScratchMorph listBlockColor;
		extent: readout extent + 3;
		addMorphBack: readout.

	(anObject isKindOf: String) ifFalse: [
		cell complexObject: anObject ].

	cell position: scrollPane contents bottomLeft.

	"avoid recursive lists"

	anObject = self ifFalse: [scrollPane contents addMorph: cell].

"
	double _ scrollPane contents allMorphs detect: [:m | cell allMorphs includes: m] ifNone: [nil].
	double ifNil: [
		scrollPane contents addMorph: cell]
		ifNotNil: [].
"
	^ cell
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 4/22/2010 09:33'!
deleteLineAt: aNumber

	| index |

	index _ aNumber asInteger.
	(index > 0 and: [index <= cellMorphs size]) ifFalse: [
		lastActivityError _ true.
		^ self].

	index = numberMorphs size ifTrue: [
		numberMorphs last delete.
		numberMorphs _ numberMorphs copyFrom: 1 to: numberMorphs size - 1].

	(cellMorphs removeAt: index) delete.
	self noteChangeAtIndex: index.
	owner ifNil: [self step].
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 7/19/2010 21:03'!
insertLine: aString at: aNumber

	| index newCell |

"
	(aString isKindOf: self class) ifTrue: [
		(aString containsRecursive: self) ifTrue: [
			self error: 'attempting to create a recursive list']].
"

	index _ aNumber asInteger.
	(index > 0 and: [index <= (cellMorphs size + 1)]) ifFalse: [
		lastActivityError _ true.
		^ self].

	newCell _ self createCell: aString.
	index = 1
		ifTrue: [cellMorphs addFirst: newCell]
		ifFalse: [
			index > cellMorphs size
				ifTrue: [cellMorphs addLast: newCell]
				ifFalse: [cellMorphs add: newCell afterIndex: index - 1]].

	self updateCountMorph.
	self noteChangeAtIndex: index.
	^ newCell
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 8/3/2010 23:02'!
lineAt: aNumber

	| index cell |

	index _ aNumber asInteger.
	(index > 0 and: [index <= cellMorphs size])
		ifTrue: [
			self isInWorld ifTrue: [
				self noteChangeForReadingAtIndex: index ].
			cell _ (cellMorphs at: index).
			^cell complexObject ifNil: [
				cell firstSubmorph contents "asUTF8"]]
		ifFalse: [
			lastActivityError _ true.
			^ ''].
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jm 5/13/2008 16:48'!
lineCount

	^ cellMorphs size
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 7/8/2010 22:59'!
setLineAt: aNumber to: newContents

	| index cell obj |

	(newContents isKindOf: self class) ifTrue: [
		(newContents containsRecursive: self) ifTrue: [
			self error: 'attempting to create a recursive list']].

	index _ aNumber asInteger.
	(index > 0 and: [index <= cellMorphs size]) ifFalse: [
		lastActivityError _ true.
		^ self].

	(newContents isKindOf: self class)
	| (newContents isKindOf: Morph)
	| (newContents isKindOf: Array)
	| (newContents isKindOf: Boolean)

		ifTrue: [obj _ newContents]
		ifFalse: [ obj _ newContents asString ].
	
	cell _ cellMorphs at: index.

	(cell complexObject respondsTo: #delete)
		ifTrue: [cell complexObject delete].

	(obj isKindOf: String)
		ifTrue: [ 
			cell complexObject: nil.
			cell firstSubmorph contents: obj ]
		ifFalse: [
			cell firstSubmorph contents: ''.
			cell complexObject: obj ].

	cell changed.
	self noteChangeAtIndex: index

! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 1/20/2011 00:45'!
updateContents
	"Update and layout my contents."

	| page numberRight cellWidth inset x y listOwner |

	listOwner _ self listOwner.
	listOwner ifNotNil: [
"		listOwner noteChangeAtIndex: (listOwner indexOf: self)]."
		listOwner updateContentsRecursive].

	cellMorphs size = 0 ifTrue: [^ self showEmpty].

	emptyMorph delete.

	page _ scrollPane contents.
	page changed.

	ScratchTranslator isRTL
		ifTrue: [numberRight _ self right - 5]
		ifFalse: [numberRight _ self left + self largestIndexWidth + 6].

	"word-wrap cell contents and fix cell extents, if needed"
	ScratchTranslator isRTL
		ifTrue: [cellWidth _ self right - self left - self largestIndexWidth - 33]
		ifFalse: [cellWidth _ self right - numberRight - 25].
	inset _ 3.
	cellMorphs do: [:cell |

		(cell complexObject isKindOf: Morph)
			ifTrue: [ (cell complexObject respondsTo: #displayForm)
				ifTrue: [cell extent: cell complexObject displayForm extent +(10@10)]
				ifFalse: [(cell complexObject respondsTo: #thumbnailImageForm)
					ifTrue: [cell extent: cell complexObject thumbnailImageForm extent + (10@10)]
					ifFalse: [cell extent: cell complexObject fullBounds extent +(10@10)]]]
			ifFalse: [
				((cell width ~= cellWidth) or: [cell extent ~= (cell firstSubmorph extent + inset)]) ifTrue: [
				cell firstSubmorph width: cellWidth - inset.
				cell extent: cell firstSubmorph extent + inset]]].

	"position cells"
	ScratchTranslator isRTL
		ifTrue: [x _ self left + 26]
		ifFalse: [x _ numberRight + 4].
	y _ page top + 3.
	cellMorphs do: [:cell |
		cell position: x@y.
		y _ y + cell height - 1].

	self updateIndices: numberRight.

	page extent: (self width - (2 * borderWidth)) @ (y + 3).

	lastActivityIndex ifNotNil: [
 		(lastActivityIndex between: 1 and: cellMorphs size) ifTrue: [
			(numberMorphs at: lastActivityIndex) color: (Color white).
			highlightActive _ true].
		self scrollActiveCellIntoView.
		lastActivityIndex _ nil].
	scrollPane updateScrollbars.
	scrollPane updateScrollbars.

	listLayoutNeeded _ false.
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 8/3/2010 22:38'!
updateContentsForReading
	"Update and layout my contents."

	| page numberRight cellWidth inset x y listOwner |

	listOwner _ self listOwner.
	listOwner ifNotNil: [
		listOwner noteChangeAtIndex: (listOwner indexOf: self)].
"		listOwner updateContentsRecursive]."

	cellMorphs size = 0 ifTrue: [^ self showEmpty].

	emptyMorph delete.

	page _ scrollPane contents.
	page changed.

	ScratchTranslator isRTL
		ifTrue: [numberRight _ self right - 5]
		ifFalse: [numberRight _ self left + self largestIndexWidth + 6].

	"word-wrap cell contents and fix cell extents, if needed"
	ScratchTranslator isRTL
		ifTrue: [cellWidth _ self right - self left - self largestIndexWidth - 33]
		ifFalse: [cellWidth _ self right - numberRight - 25].
	inset _ 3.
	cellMorphs do: [:cell |

		(cell complexObject isKindOf: Morph)
			ifTrue: [ (cell complexObject respondsTo: #displayForm)
				ifTrue: [cell extent: cell complexObject displayForm extent +(10@10)]
				ifFalse: [cell extent: cell complexObject fullBounds extent +(10@10)]]
			ifFalse: [
				((cell width ~= cellWidth) or: [cell extent ~= (cell firstSubmorph extent + inset)]) ifTrue: [
				cell firstSubmorph width: cellWidth - inset.
				cell extent: cell firstSubmorph extent + inset]]].

	"position cells"
	ScratchTranslator isRTL
		ifTrue: [x _ self left + 26]
		ifFalse: [x _ numberRight + 4].
	y _ page top + 3.
	cellMorphs do: [:cell |
		cell position: x@y.
		y _ y + cell height - 1].

	self updateIndices: numberRight.

	page extent: (self width - (2 * borderWidth)) @ (y + 3).

	lastActivityIndex ifNotNil: [
 		(lastActivityIndex between: 1 and: cellMorphs size) ifTrue: [
			(numberMorphs at: lastActivityIndex) color: (Color white).
			highlightActive _ true].
		self scrollActiveCellIntoView.
		lastActivityIndex _ nil].
	scrollPane updateScrollbars.
	scrollPane updateScrollbars.

	listLayoutNeeded _ false.
! !


!ScratchListMorph methodsFor: 'import/export' stamp: 'jm 5/21/2009 10:25'!
exportList

	| fName f |
	fName _ titleMorph contents.
	fName size <= 1 ifTrue: [fName _ 'newList'].
	fName _ fName, '.txt'.

	fName _ ScratchFileChooserDialog
		chooseNewFileDefault: fName
		title: 'File Name?'
		type: #list.
	fName = #cancelled ifTrue: [^ self].

	f _ StandardFileStream newScratchFileNamed: fName.
	f ifNil: [^ self].
	cellMorphs do: [:m | f nextPutAll: m firstSubmorph contents; crlf].
	f close.
! !

!ScratchListMorph methodsFor: 'import/export' stamp: 'jm 5/21/2009 10:21'!
importList

	| result |
	result _ ScratchFileChooserDialog
		chooseExistingFileType: #list
		extensions: #(txt)
		title: 'Import List'.

	#cancelled = result ifTrue: [^ self].
	self importListFromFileNamed: result.
! !

!ScratchListMorph methodsFor: 'import/export' stamp: 'jm 6/25/2009 17:13'!
importListFromFileNamed: aFilename

	| f |
	f _ FileStream readOnlyFileNamedOrNil: (FileDirectory default fullNameFor: aFilename).
	f ifNil: [
		DialogBoxMorph inform: 'File not found' withDetails: aFilename.
		^ nil].

	"Assume the file was encoded as UTF8"
	[	self newContents:
			(f contentsOfEntireFile lines collect: [:s | UTF8 withAll: s]).
	] ifError: [self beep].
! !


!ScratchListMorph methodsFor: 'object i/o' stamp: 'jens 11/19/2009 20:40'!
fieldsVersion

	^ 3
! !

!ScratchListMorph methodsFor: 'object i/o' stamp: 'jens 11/30/2009 23:06'!
initFieldsFrom: anObjStream version: classVersion
	"Note: To simplify my representation in the project file, my submorphs are removed before saving and restored when I am read in from an object file."

	| strings complex |
	super initFieldsFrom: anObjStream version: classVersion.

	listName _ anObjStream nextField.
	strings _ anObjStream nextField.
	classVersion > 1 ifTrue: [target _ anObjStream nextField].
	classVersion > 2 ifTrue: [complex _ anObjStream nextField].

	self removeAllMorphs.
	self addTitleAndControls; addScrollPane.
	titleMorph contents: listName.
	self newContents: strings.
	complex ifNotNil: [
		self complexContents: complex ].
	self fixLayout.
	self updateContents.
! !

!ScratchListMorph methodsFor: 'object i/o' stamp: 'jens 11/24/2009 22:43'!
storeFieldsOn: anObjStream
	"Note: To simplify my representation in the project file, my submorphs are removed before saving and restored when I am read in from an object file."

	| strings complex |

	"self purge.	"

	strings _ cellMorphs asArray collect: [:m | m firstSubmorph contents asString].
	complex _ cellMorphs asArray collect: [:m | m complexObject].

	self removeAllMorphs.
	numberMorphs _ #().

	super storeFieldsOn: anObjStream.
	anObjStream putField: listName.
	anObjStream putField: strings.
	anObjStream putField: target.
	anObjStream putField: complex.

	self addTitleAndControls; addScrollPane.
	titleMorph contents: listName.
	self newContents: strings.
	self complexContents: complex.
	self fixLayout.

! !


!ScratchListMorph methodsFor: 'private' stamp: 'jm 5/31/2008 13:57'!
indexColor

	^ Color gray: 0.32
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 5/14/2008 11:05'!
largestIndexWidth
	"Estimate the width needed for the largest cell number."
	"Note: we estimate using the width of the the digit '0' times the number of digits needed."

	| digitWidth digitCount n |
	digitWidth _ (ScratchFrameMorph getFont: #Label) widthOf: $0.
	n _ cellMorphs size + 1 max: 100.
	digitCount _ n log ceiling.
	^ digitCount * digitWidth

! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 6/4/2008 17:36'!
newContents: listOfStrings
	"Set my contents to the given collection of strings."

	scrollPane contents
		removeAllMorphs;
		top: scrollPane top;
		extent: scrollPane extent.

	cellMorphs _ cellMorphs species new: ((2 * listOfStrings size) max: 1000).
	numberMorphs _ #().

	listOfStrings do: [:s | cellMorphs addLast: (self createCell: s)].
	self updateContents.
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 5/31/2008 11:04'!
normalBorderColor

	^ Color r: (148/255) g: (145/255) b: (145/255)
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jens 7/15/2010 23:28'!
scrollActiveCellIntoView

	| cell page newTop |

	lastActivityIndex _ lastActivityIndex within: 1 and: cellMorphs size.
	cell _ cellMorphs at: lastActivityIndex.
	page _ scrollPane contents.
	(scrollPane bounds containsRect: cell bounds) ifFalse: [
		newTop _ (scrollPane bounds center y) - (cell top - page top).
		newTop _ newTop max: (scrollPane bottom - (cellMorphs last bottom - page top) - 3).
		newTop _ newTop min: scrollPane top.
		page top: newTop].
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 8/13/2008 15:33'!
showEmpty
	"Show the empty label."

	| page |
	scrollPane hScrollRelative: 0; vScrollRelative: 0.
	page _ scrollPane contents
		removeAllMorphs;
		extent: scrollPane extent.

	numberMorphs size > 0 ifTrue: [numberMorphs _ #()].

	emptyMorph
		contents: '(empty)' localized;
		position: (page center - (emptyMorph extent // 2)).
	page addMorph: emptyMorph.

	scrollPane updateScrollbars.
	listLayoutNeeded _ false.

! !

!ScratchListMorph methodsFor: 'private' stamp: 'jens 8/1/2010 23:59'!
updateContentsRecursive
	"Update and layout my contents and those of my children."

	| page numberRight cellWidth inset x y |

	cellMorphs size = 0 ifTrue: [^ self showEmpty].
	emptyMorph delete.

	page _ scrollPane contents.
	page changed.

	ScratchTranslator isRTL
		ifTrue: [numberRight _ self right - 5]
		ifFalse: [numberRight _ self left + self largestIndexWidth + 6].

	"word-wrap cell contents and fix cell extents, if needed"
	ScratchTranslator isRTL
		ifTrue: [cellWidth _ self right - self left - self largestIndexWidth - 33]
		ifFalse: [cellWidth _ self right - numberRight - 25].
	inset _ 3.
	cellMorphs do: [:cell |

		(cell complexObject isKindOf: Morph)
			ifTrue: [ 
				(cell complexObject respondsTo: #displayForm)
					ifTrue: [cell extent: cell complexObject displayForm extent +(10@10)]
					ifFalse: [cell extent: cell complexObject fullBounds extent +(10@10)].
				(cell complexObject isKindOf: self class)
					ifTrue: [cell complexObject updateContentsRecursive]]
			ifFalse: [
				((cell width ~= cellWidth) or: [cell extent ~= (cell firstSubmorph extent + inset)]) ifTrue: [
				cell firstSubmorph width: cellWidth - inset.
				cell extent: cell firstSubmorph extent + inset]]].

	"position cells"
	ScratchTranslator isRTL
		ifTrue: [x _ self left + 26]
		ifFalse: [x _ numberRight + 4].
	y _ page top + 3.
	cellMorphs do: [:cell |
		cell position: x@y.
		y _ y + cell height - 1].

	self updateIndices: numberRight.

	page extent: (self width - (2 * borderWidth)) @ (y + 3).

	lastActivityIndex ifNotNil: [
 		(lastActivityIndex between: 1 and: cellMorphs size) ifTrue: [
			(numberMorphs at: lastActivityIndex) color: (Color white).
			highlightActive _ true].
		self scrollActiveCellIntoView.
		lastActivityIndex _ nil].
	scrollPane updateScrollbars.
	scrollPane updateScrollbars.

	listLayoutNeeded _ false.
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 5/31/2008 13:57'!
updateIndices: rightX

	| s newNumbers page num cell |
	numberMorphs size > cellMorphs size ifTrue: [
		cellMorphs size + 1 to: numberMorphs size do: [:i | (numberMorphs at: i) delete].
		numberMorphs _ numberMorphs copyFrom: 1 to: cellMorphs size].

	newNumbers _ #().
	numberMorphs size < cellMorphs size ifTrue: [
		page _ scrollPane contents.
		s _ StringMorph new
			color: self indexColor;
			font: (ScratchFrameMorph getFont: #Label).
		newNumbers _ (numberMorphs size + 1 to: cellMorphs size)
			collect: [:i | s fullCopy contents: i printString].
		newNumbers do: [:m | page addMorph: m].
		numberMorphs _ numberMorphs, newNumbers].

	1 to: cellMorphs size do: [:i |
		num _ numberMorphs at: i.
		cell _ cellMorphs at: i.
		num position: (rightX - num width) @ (cell top + ((cell height - num height) // 2))].

! !


!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/19/2010 01:58'!
aboutToBeGrabbedBy: aHand

	self listOwner
		ifNil: [^ self]
		ifNotNil: [^ nil]! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 2/22/2010 00:05'!
asArray

	| result |
	result _ Array new: self lineCount.
	1 to: self lineCount do: [:i |
		result at: i put: (self lineAt: i)].
	^ result! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'JM 11/22/2011 15:24'!
asReferenceTuple

	" answer an array describing the receiver in an abstract way
	format conventions:

		named list reference:

					1 - #namedList
					2 - target obj name
					3 - list name

		variable-bound anonymous list reference:

					1 - #variableList
					2 - target obj name
					3 - var name

		anonymous list (either within a list or bound to a variable):

					converted to tuples in place"

	| stage rcvr ref |

	target isNil ifTrue: [
		stage _ ScratchFrameMorph someInstance workPane.
		ref _ stage referenceToList: self.
		ref ifNil: [^nil].
		^(Array with: #variableList), ref].

	stage _ target ownerThatIsA: ScratchStageMorph.
	target == stage
		ifTrue: [rcvr _ 'Canvas']
		ifFalse: [rcvr _ target objName].
	^ Array with: #namedList with: rcvr with: listName	

		! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 11/29/2009 20:06'!
complexContents: anArray

	| obj |
	1 to: anArray size do: [:i |
		obj _ anArray at: i.
		obj isNil ifFalse: [
			self setLineAt: i to: obj]].
	anArray isEmpty ifFalse: [ self noteChangeAtIndex: 1 ]! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 5/18/2010 13:11'!
containsRecursive: anObject

	| s |
	s _ anObject asString asUTF8.
	cellMorphs do: [:m |
		m complexObject notNil
			ifTrue: [
				m complexObject = anObject ifTrue: [^ true ].
				(m complexObject isKindOf: self class) ifTrue: [
					(m complexObject containsRecursive: anObject) ifTrue: [^true]]]
			ifFalse: [
				s = m firstSubmorph contents ifTrue: [^ true]]].

	^ false
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 3/2/2010 21:20'!
convertBlockTuplesToStacksFor: aScriptableScratchMorph

	"only for multi arg persistence"
	| obj block |

	cellMorphs do: [:m | obj _ m complexObject.

		(obj isKindOf: Array) ifTrue: [

			#block = obj first ifTrue: [
				block _ aScriptableScratchMorph stackFromTupleList: obj third receiver: aScriptableScratchMorph.
				m complexObject: block ]]].

	self updateContents! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'JM 11/22/2011 15:23'!
convertStacksToTuples

	"format conventions:

		block: 
					1 - #block
					2 - receiver
					3 - tupleSequence

		named list reference:

					1 - #namedList
					2 - target obj name
					3 - list name

		variable-bound anonymous list reference:

					1 - #variableList
					2 - target obj name
					3 - var name

		anonymous list (either within a list or bound to a variable):

					converted to tuples in place"


	| obj rcvr ref |

	cellMorphs do: [:m | obj _ m complexObject.

		(obj isKindOf: BlockMorph) ifTrue: [
			(obj receiver isKindOf: ScriptableScratchMorph)
				ifTrue: [(obj receiver isKindOf: ScratchStageMorph)
					ifTrue: [rcvr _ 'Canvas']
					ifFalse: [rcvr _ obj receiver objName]]
				ifFalse: [ rcvr _ '' ].
			m complexObject: (Array with: #block with: rcvr with: obj tupleSequence) ].

		(obj isKindOf: self class) ifTrue: [ 
			ref _ obj asReferenceTuple.
			ref isNil
				ifTrue: [ obj convertStacksToTuples]
				ifFalse: [ m complexObject: ref]].

		(obj isKindOf: ScriptableScratchMorph) ifTrue: [ 
			ref _ obj asReferenceTuple.
			m complexObject: ref]].
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'JM 11/22/2011 15:23'!
convertTuplesToStacks

	"format conventions:

		sprite:
					1 - #sprite
					2 - name

		stage:		#stage

		block: 
					1 - #block
					2 - receiver
					3 - tupleSequence

		named list reference:

					1 - #namedList
					2 - target obj name
					3 - list name

		variable-bound anonymous list reference:

					1 - #variableList
					2 - target obj name
					3 - var name

		anonymous list (either within a list or bound to a variable):

					converted to tuples in place"

	| obj rcvr block stage |

	cellMorphs do: [:m | obj _ m complexObject.

		(obj isKindOf: Array) ifTrue: [

			target isNil
				ifTrue: [ stage _ ScratchFrameMorph someInstance workPane]
				ifFalse: [stage _ target ownerThatIsA: ScratchStageMorph ].

			obj second = 'Canvas'
				ifTrue: [rcvr _ stage ]
				ifFalse: [rcvr _ stage coerceSpriteArg: obj second ].

			#block = obj first ifTrue: [
				block _ stage stackFromTupleList: obj third receiver: rcvr.
				m complexObject: block ].

			#namedList = obj first ifTrue: [
				m complexObject: (stage listNamed: obj third targetName: obj second)].

			#variableList = obj first ifTrue: [
				m complexObject: (stage listInVarNamed: obj third targetName: obj second)].

			#stage = obj first ifTrue: [
				m complexObject: stage].	

			#sprite = obj first ifTrue: [
				m complexObject: (stage coerceSpriteArg: obj second)]].

		(obj isKindOf: self class) ifTrue: [
			obj convertTuplesToStacks.
			m complexObject: obj]].

	self updateContents! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 8/1/2010 23:32'!
equals: another

	another class == self class ifFalse: [^ false].
	^ self asArray = another asArray! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 11/17/2009 22:00'!
fullDrawOn: aCanvas
	"private - ensure that I show the correct length"
	self updateCountMorph.
	super fullDrawOn: aCanvas! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/19/2010 00:50'!
indexOf: anObject

	1 to: self lineCount do: [:i | 
		(self lineAt: i) = anObject ifTrue: [^ i]].
	^ -1! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 5/19/2010 01:28'!
isMaxNestedAt: int
	"kludge-alert!!"

	int > VariableFrame maxNestingDepth
		ifTrue: [^ true].

	cellMorphs do: [:m |
		m complexObject ifNotNil: [
			(m complexObject respondsTo: #isMaxNestedAt:) ifTrue: [
				(m complexObject isMaxNestedAt: int + 1) 
					ifTrue:[^ true]]]].
	^ false
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/17/2010 22:04'!
listOwner

	owner ifNil: [^ nil].
	^ owner ownerThatIsA: self class.
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/21/2010 16:20'!
privateInsertLine: aString at: aNumber

	| index newCell |
	index _ aNumber asInteger.
	(index > 0 and: [index <= (cellMorphs size + 1)]) ifFalse: [
		lastActivityError _ true.
		^ self].

	newCell _ self createCell: aString.
	index = 1
		ifTrue: [cellMorphs addFirst: newCell]
		ifFalse: [
			index > cellMorphs size
				ifTrue: [cellMorphs addLast: newCell]
				ifFalse: [cellMorphs add: newCell afterIndex: index - 1]].
	^ newCell
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 7/27/2010 17:16'!
references: anObject

	cellMorphs do: [:m |
		m complexObject ifNotNil: [
			m complexObject == anObject ifTrue: [^ true ].
			(m complexObject respondsTo: #references:) ifTrue: [
				(m complexObject references: anObject) ifTrue: [^true]]]].
	^ false
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/18/2010 23:31'!
sublistIcon

	| block slot form halfList big |
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
	^((big withOutlineColor: Color gray muchLighter width: 2) "withOutlineColor: Color darkGray width: 1").
! !


!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/19/2010 01:58'!
aboutToBeGrabbedBy: aHand

	self listOwner
		ifNil: [^ self]
		ifNotNil: [^ nil]! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jm 1/28/2009 11:39'!
addLettersOf: anObject

	anObject asString asUTF32 do: [:ch |
		cellMorphs addLast: (self createCell: (UTF32 with: ch) asUTF8)].

	self noteChangeAtIndex: cellMorphs size.
! !

!ScratchListMorph methodsFor: 'initialization' stamp: 'jm 6/28/2008 12:37'!
addScrollPane

	scrollPane _ ScrollFrameMorph2 new
		vBarInset: 16;
		hBarInset: 18;
		color: Color transparent;
		growthFraction: 0.0;
		scrollbarStartInset: 2 endInset: -2;
		contents: (Morph new color: Color transparent).

	self addMorph: scrollPane.
! !

!ScratchListMorph methodsFor: 'initialization' stamp: 'jens 4/19/2010 00:28'!
addTitleAndControls

	titleMorph _ StringMorph new contents: 'myList'; font: (ScratchFrameMorph getFont: #Label).
	deleteMorph _ (ImageMorph new form: (ScratchFrameMorph skinAt: #deleteItem)).
	addItemMorph _ (ImageMorph new form: (ScratchFrameMorph skinAt: #addItem)).
	addSublistMorph _ (ImageMorph new form: self sublistIcon).
	resizeMorph _ ScratchResizeMorph ofType: #corner.
	countMorph _ StringMorph new
		contents: '0';
		font: (ScratchFrameMorph getFont: #XYReadout);
		color: (Color gray: 0.15).

	"emptyMorph is added to contents pane when list is empty"
	emptyMorph _ StringMorph new
		contents: '(empty)' localized;
		font: (ScratchFrameMorph getFont: #CommentBlock).

	self addMorph: titleMorph.
	self addMorph: deleteMorph.
	self addMorph: addItemMorph.
	self addMorph: addSublistMorph.
	self addMorph: resizeMorph.
	self addMorph: countMorph.
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 2/22/2010 00:05'!
asArray

	| result |
	result _ Array new: self lineCount.
	1 to: self lineCount do: [:i |
		result at: i put: (self lineAt: i)].
	^ result! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'JM 11/22/2011 15:24'!
asReferenceTuple

	" answer an array describing the receiver in an abstract way
	format conventions:

		named list reference:

					1 - #namedList
					2 - target obj name
					3 - list name

		variable-bound anonymous list reference:

					1 - #variableList
					2 - target obj name
					3 - var name

		anonymous list (either within a list or bound to a variable):

					converted to tuples in place"

	| stage rcvr ref |

	target isNil ifTrue: [
		stage _ ScratchFrameMorph someInstance workPane.
		ref _ stage referenceToList: self.
		ref ifNil: [^nil].
		^(Array with: #variableList), ref].

	stage _ target ownerThatIsA: ScratchStageMorph.
	target == stage
		ifTrue: [rcvr _ 'Canvas']
		ifFalse: [rcvr _ target objName].
	^ Array with: #namedList with: rcvr with: listName	

		! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jm 5/14/2008 14:19'!
clear

	cellMorphs _ cellMorphs species new: 1000.
	self updateContents.
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 11/29/2009 20:06'!
complexContents: anArray

	| obj |
	1 to: anArray size do: [:i |
		obj _ anArray at: i.
		obj isNil ifFalse: [
			self setLineAt: i to: obj]].
	anArray isEmpty ifFalse: [ self noteChangeAtIndex: 1 ]! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 11/24/2009 23:00'!
concatenatedLines

	| isSingleLetters s |
	isSingleLetters _ true.
	cellMorphs do: [:m |
		isSingleLetters ifTrue: [
			m firstSubmorph contents asString asUTF32 size <= 1 ifFalse: [isSingleLetters _ false]]].

	s _ WriteStream on: (UTF8 new: 1000).
	isSingleLetters
		ifTrue: [
			cellMorphs do: [:m | s nextPutAll: m firstSubmorph contents asString]]
		ifFalse: [
			cellMorphs do: [:m | s nextPutAll: m firstSubmorph contents asString; space].
			s position > 0 ifTrue: [s skip: -1]].

	^ s contents
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 3/21/2011 17:07'!
contains: anObject

	| s isComplex |
	isComplex _ (anObject isKindOf: ScriptableScratchMorph) 
				| (anObject isKindOf: ScratchListMorph) 
				| (anObject isKindOf: CommandBlockMorph).

	isComplex ifTrue: [
		cellMorphs do: [:m |
			m complexObject = anObject ifTrue: [^ true]].
		^ false].

	s _ anObject asString asUTF8.
	cellMorphs do: [:m |
		m complexObject = anObject ifTrue: [^ true ].
		s = m firstSubmorph contents ifTrue: [^ true]].

	^ false
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 5/18/2010 13:11'!
containsRecursive: anObject

	| s |
	s _ anObject asString asUTF8.
	cellMorphs do: [:m |
		m complexObject notNil
			ifTrue: [
				m complexObject = anObject ifTrue: [^ true ].
				(m complexObject isKindOf: self class) ifTrue: [
					(m complexObject containsRecursive: anObject) ifTrue: [^true]]]
			ifFalse: [
				s = m firstSubmorph contents ifTrue: [^ true]]].

	^ false
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 3/2/2010 21:20'!
convertBlockTuplesToStacksFor: aScriptableScratchMorph

	"only for multi arg persistence"
	| obj block |

	cellMorphs do: [:m | obj _ m complexObject.

		(obj isKindOf: Array) ifTrue: [

			#block = obj first ifTrue: [
				block _ aScriptableScratchMorph stackFromTupleList: obj third receiver: aScriptableScratchMorph.
				m complexObject: block ]]].

	self updateContents! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'JM 11/22/2011 15:23'!
convertStacksToTuples

	"format conventions:

		block: 
					1 - #block
					2 - receiver
					3 - tupleSequence

		named list reference:

					1 - #namedList
					2 - target obj name
					3 - list name

		variable-bound anonymous list reference:

					1 - #variableList
					2 - target obj name
					3 - var name

		anonymous list (either within a list or bound to a variable):

					converted to tuples in place"


	| obj rcvr ref |

	cellMorphs do: [:m | obj _ m complexObject.

		(obj isKindOf: BlockMorph) ifTrue: [
			(obj receiver isKindOf: ScriptableScratchMorph)
				ifTrue: [(obj receiver isKindOf: ScratchStageMorph)
					ifTrue: [rcvr _ 'Canvas']
					ifFalse: [rcvr _ obj receiver objName]]
				ifFalse: [ rcvr _ '' ].
			m complexObject: (Array with: #block with: rcvr with: obj tupleSequence) ].

		(obj isKindOf: self class) ifTrue: [ 
			ref _ obj asReferenceTuple.
			ref isNil
				ifTrue: [ obj convertStacksToTuples]
				ifFalse: [ m complexObject: ref]].

		(obj isKindOf: ScriptableScratchMorph) ifTrue: [ 
			ref _ obj asReferenceTuple.
			m complexObject: ref]].
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'JM 11/22/2011 15:23'!
convertTuplesToStacks

	"format conventions:

		sprite:
					1 - #sprite
					2 - name

		stage:		#stage

		block: 
					1 - #block
					2 - receiver
					3 - tupleSequence

		named list reference:

					1 - #namedList
					2 - target obj name
					3 - list name

		variable-bound anonymous list reference:

					1 - #variableList
					2 - target obj name
					3 - var name

		anonymous list (either within a list or bound to a variable):

					converted to tuples in place"

	| obj rcvr block stage |

	cellMorphs do: [:m | obj _ m complexObject.

		(obj isKindOf: Array) ifTrue: [

			target isNil
				ifTrue: [ stage _ ScratchFrameMorph someInstance workPane]
				ifFalse: [stage _ target ownerThatIsA: ScratchStageMorph ].

			obj second = 'Canvas'
				ifTrue: [rcvr _ stage ]
				ifFalse: [rcvr _ stage coerceSpriteArg: obj second ].

			#block = obj first ifTrue: [
				block _ stage stackFromTupleList: obj third receiver: rcvr.
				m complexObject: block ].

			#namedList = obj first ifTrue: [
				m complexObject: (stage listNamed: obj third targetName: obj second)].

			#variableList = obj first ifTrue: [
				m complexObject: (stage listInVarNamed: obj third targetName: obj second)].

			#stage = obj first ifTrue: [
				m complexObject: stage].	

			#sprite = obj first ifTrue: [
				m complexObject: (stage coerceSpriteArg: obj second)]].

		(obj isKindOf: self class) ifTrue: [
			obj convertTuplesToStacks.
			m complexObject: obj]].

	self updateContents! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 1/20/2011 00:34'!
createCell: anObject

	| readout cell font numberRight txt double |

	txt _ anObject.
	(anObject isKindOf: String)
		ifFalse: [txt _ anObject printString].

	font _ ScratchFrameMorph getFont: #Watcher.
	readout _ ListMultilineStringMorph new
		borderWidth: 0;
		color: Color transparent;
		textColor: Color white;
		growWithText: true;
		contents: txt font: font.
	readout height: ((ScratchTranslator stringExtent: 'A' font: font) y) + 6.
	ScratchTranslator isRTL
		ifTrue: [numberRight _ self right - 5]
		ifFalse: [numberRight _ self left + self largestIndexWidth + 6].
	ScratchTranslator isRTL
		ifTrue: [readout width: self right - self left - self largestIndexWidth - 33]
		ifFalse: [readout width: self right - numberRight - 25].

	cell _ WatcherReadoutFrameMorph new
		color: ScriptableScratchMorph listBlockColor;
		extent: readout extent + 3;
		addMorphBack: readout.

	(anObject isKindOf: String) ifFalse: [
		cell complexObject: anObject ].

	cell position: scrollPane contents bottomLeft.

	"avoid recursive lists"

	anObject = self ifFalse: [scrollPane contents addMorph: cell].

"
	double _ scrollPane contents allMorphs detect: [:m | cell allMorphs includes: m] ifNone: [nil].
	double ifNil: [
		scrollPane contents addMorph: cell]
		ifNotNil: [].
"
	^ cell
! !

!ScratchListMorph methodsFor: 'dropping/grabbing' stamp: 'jm 5/15/2008 14:32'!
delete

	super delete.
	ScratchFrameMorph allInstancesDo: [:frame | frame deletingWatcher].
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 4/22/2010 09:33'!
deleteLineAt: aNumber

	| index |

	index _ aNumber asInteger.
	(index > 0 and: [index <= cellMorphs size]) ifFalse: [
		lastActivityError _ true.
		^ self].

	index = numberMorphs size ifTrue: [
		numberMorphs last delete.
		numberMorphs _ numberMorphs copyFrom: 1 to: numberMorphs size - 1].

	(cellMorphs removeAt: index) delete.
	self noteChangeAtIndex: index.
	owner ifNil: [self step].
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 8/1/2010 23:32'!
equals: another

	another class == self class ifFalse: [^ false].
	^ self asArray = another asArray! !

!ScratchListMorph methodsFor: 'import/export' stamp: 'jm 5/21/2009 10:25'!
exportList

	| fName f |
	fName _ titleMorph contents.
	fName size <= 1 ifTrue: [fName _ 'newList'].
	fName _ fName, '.txt'.

	fName _ ScratchFileChooserDialog
		chooseNewFileDefault: fName
		title: 'File Name?'
		type: #list.
	fName = #cancelled ifTrue: [^ self].

	f _ StandardFileStream newScratchFileNamed: fName.
	f ifNil: [^ self].
	cellMorphs do: [:m | f nextPutAll: m firstSubmorph contents; crlf].
	f close.
! !

!ScratchListMorph methodsFor: 'geometry' stamp: 'jens 4/16/2010 00:52'!
extent: aPoint

	super extent: (aPoint max: 95@115).
	self fixLayout.
! !

!ScratchListMorph methodsFor: 'object i/o' stamp: 'jens 11/19/2009 20:40'!
fieldsVersion

	^ 3
! !

!ScratchListMorph methodsFor: 'geometry' stamp: 'jens 4/19/2010 00:37'!
fixLayout

	titleMorph fitContents.
	(titleMorph width > (self width - 12)) ifTrue: [
		self width: titleMorph width + 12].

	titleMorph position: (self center x - (titleMorph width // 2)) @ (self top + 5).

	self listOwner 
		ifNil: [deleteMorph isHidden: true]
		ifNotNil: [
			deleteMorph position: (self right - deleteMorph width - 3) @ (self top + 3).
			deleteMorph isHidden: false; changed].

	countMorph fitContents.

	scrollPane
		position: (self left + 2) @ (titleMorph bottom + 3);
		extent: (self width - 4) @ (self bottom - titleMorph bottom - countMorph height - 12).

	addItemMorph position: (self left + 3) @ (self bottom - addItemMorph height - 3).
	addSublistMorph position: addItemMorph position + (addItemMorph width + 1 @ 0).

	resizeMorph position: (self bottomRight - resizeMorph extent).

	self updateCountMorph.
	countMorph bottom: self bottom - 3.

	self updateContents.
! !

!ScratchListMorph methodsFor: 'geometry' stamp: 'jens 4/16/2010 00:09'!
fixLayoutForNewLanguage
	"This method updates the height and word-wrapping of cells after a language or font change."

	| cellContents oldH |
	cellMorphs size = 0 ifTrue: [self fixLayout. ^ self showEmpty].
	cellContents _ cellMorphs first firstSubmorph.
	oldH _ cellContents height.
	(cellContents isKindOf: ScratchListMorph)
		ifFalse: [ cellContents font: cellContents font].
	cellContents height = oldH ifTrue: [self fixLayout. ^ self].  "no size change"

	scrollPane vScrollRelative: 0.
	cellMorphs do: [:c | c firstSubmorph font: c firstSubmorph font].
	self fixLayout.
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jm 5/14/2008 18:13'!
focusCell: cellMorph

	focusIndex _ cellMorphs indexOf: cellMorph ifAbsent: [1].
	World activeHand newKeyboardFocus: cellMorph firstSubmorph.
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'ee 5/6/2008 16:04'!
focusIndex

	^ focusIndex
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jens 4/19/2010 02:42'!
focusIndex: anInteger

	| cell |
	focusIndex _ anInteger.
	focusIndex > cellMorphs size ifTrue: [focusIndex _ 1].
	focusIndex < 1 ifTrue: [focusIndex _ cellMorphs size].

	cellMorphs size > 0 ifTrue: [
		cell _ cellMorphs at: focusIndex.
		(cell complexObject isKindOf: Morph) ifFalse: [
			World activeHand newKeyboardFocus: cell firstSubmorph.
			scrollPane scrollSubmorphIntoView: cell]].
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 11/17/2009 22:00'!
fullDrawOn: aCanvas
	"private - ensure that I show the correct length"
	self updateCountMorph.
	super fullDrawOn: aCanvas! !

!ScratchListMorph methodsFor: 'event handling' stamp: 'jens 4/19/2010 01:59'!
handlesMouseDown: evt

	^ self world notNil! !

!ScratchListMorph methodsFor: 'import/export' stamp: 'jm 5/21/2009 10:21'!
importList

	| result |
	result _ ScratchFileChooserDialog
		chooseExistingFileType: #list
		extensions: #(txt)
		title: 'Import List'.

	#cancelled = result ifTrue: [^ self].
	self importListFromFileNamed: result.
! !

!ScratchListMorph methodsFor: 'import/export' stamp: 'jm 6/25/2009 17:13'!
importListFromFileNamed: aFilename

	| f |
	f _ FileStream readOnlyFileNamedOrNil: (FileDirectory default fullNameFor: aFilename).
	f ifNil: [
		DialogBoxMorph inform: 'File not found' withDetails: aFilename.
		^ nil].

	"Assume the file was encoded as UTF8"
	[	self newContents:
			(f contentsOfEntireFile lines collect: [:s | UTF8 withAll: s]).
	] ifError: [self beep].
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 5/31/2008 13:57'!
indexColor

	^ Color gray: 0.32
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/19/2010 00:50'!
indexOf: anObject

	1 to: self lineCount do: [:i | 
		(self lineAt: i) = anObject ifTrue: [^ i]].
	^ -1! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jm 5/14/2008 18:22'!
indexOfCell: cellMorph

	^ cellMorphs indexOf: cellMorph ifAbsent: [-1]
! !

!ScratchListMorph methodsFor: 'object i/o' stamp: 'jens 11/30/2009 23:06'!
initFieldsFrom: anObjStream version: classVersion
	"Note: To simplify my representation in the project file, my submorphs are removed before saving and restored when I am read in from an object file."

	| strings complex |
	super initFieldsFrom: anObjStream version: classVersion.

	listName _ anObjStream nextField.
	strings _ anObjStream nextField.
	classVersion > 1 ifTrue: [target _ anObjStream nextField].
	classVersion > 2 ifTrue: [complex _ anObjStream nextField].

	self removeAllMorphs.
	self addTitleAndControls; addScrollPane.
	titleMorph contents: listName.
	self newContents: strings.
	complex ifNotNil: [
		self complexContents: complex ].
	self fixLayout.
	self updateContents.
! !

!ScratchListMorph methodsFor: 'initialization' stamp: 'jm 5/31/2008 11:56'!
initialize

	super initialize.
	self
		color: (Color r: (193/255) g: (196/255) b: (199/255));
		borderWidth: 2;
		borderColor: self normalBorderColor;
		useRoundedCorners.

	cellMorphs _ OrderedCollection new: 1000.
	numberMorphs _ #().
	listLayoutNeeded _ true.
	focusIndex _ 0.
	lastActivityError _ false.
	highlightActive _ false.

	self addTitleAndControls.
	self addScrollPane.

	self extent: 65@115.
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 7/19/2010 21:03'!
insertLine: aString at: aNumber

	| index newCell |

"
	(aString isKindOf: self class) ifTrue: [
		(aString containsRecursive: self) ifTrue: [
			self error: 'attempting to create a recursive list']].
"

	index _ aNumber asInteger.
	(index > 0 and: [index <= (cellMorphs size + 1)]) ifFalse: [
		lastActivityError _ true.
		^ self].

	newCell _ self createCell: aString.
	index = 1
		ifTrue: [cellMorphs addFirst: newCell]
		ifFalse: [
			index > cellMorphs size
				ifTrue: [cellMorphs addLast: newCell]
				ifFalse: [cellMorphs add: newCell afterIndex: index - 1]].

	self updateCountMorph.
	self noteChangeAtIndex: index.
	^ newCell
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 5/19/2010 01:28'!
isMaxNestedAt: int
	"kludge-alert!!"

	int > VariableFrame maxNestingDepth
		ifTrue: [^ true].

	cellMorphs do: [:m |
		m complexObject ifNotNil: [
			(m complexObject respondsTo: #isMaxNestedAt:) ifTrue: [
				(m complexObject isMaxNestedAt: int + 1) 
					ifTrue:[^ true]]]].
	^ false
! !

!ScratchListMorph methodsFor: 'dropping/grabbing' stamp: 'jm 6/4/2008 18:53'!
justDroppedInto: aMorph event: evt

	(aMorph isKindOf: ScratchStageMorph) ifTrue: [
		super justDroppedInto: aMorph event: evt.
		self world ifNotNil: [self world startSteppingSubmorphsOf: self].
		^ self].

	"delete me if dropped anywhere but the stage"
	self position:  evt hand formerPosition.
	^ self delete
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 5/14/2008 11:05'!
largestIndexWidth
	"Estimate the width needed for the largest cell number."
	"Note: we estimate using the width of the the digit '0' times the number of digits needed."

	| digitWidth digitCount n |
	digitWidth _ (ScratchFrameMorph getFont: #Label) widthOf: $0.
	n _ cellMorphs size + 1 max: 100.
	digitCount _ n log ceiling.
	^ digitCount * digitWidth

! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 8/3/2010 23:02'!
lineAt: aNumber

	| index cell |

	index _ aNumber asInteger.
	(index > 0 and: [index <= cellMorphs size])
		ifTrue: [
			self isInWorld ifTrue: [
				self noteChangeForReadingAtIndex: index ].
			cell _ (cellMorphs at: index).
			^cell complexObject ifNil: [
				cell firstSubmorph contents "asUTF8"]]
		ifFalse: [
			lastActivityError _ true.
			^ ''].
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jm 5/13/2008 16:48'!
lineCount

	^ cellMorphs size
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jm 6/4/2008 19:44'!
listContents

	^ cellMorphs collect: [:m | m firstSubmorph contents].
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jm 6/4/2008 19:07'!
listName

	^ listName
! !

!ScratchListMorph methodsFor: 'initialization' stamp: 'jm 7/11/2008 15:01'!
listName: asString target: aScriptableSpriteMorph

	listName _ asString asUTF8.
	target _ aScriptableSpriteMorph.
	self updateTitle.
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/17/2010 22:04'!
listOwner

	owner ifNil: [^ nil].
	^ owner ownerThatIsA: self class.
! !

!ScratchListMorph methodsFor: 'event handling' stamp: 'jens 4/19/2010 02:28'!
mouseDown: evt
	"Handle a mouse click. Left button either drags or performs click action. Right button brings up a menu."

	| p listOwner newList |

	resizeOffset _ nil.
	evt hand toolType = 'CutTool' ifTrue: [
		evt shiftPressed ifFalse: [evt hand toolType: nil].
		^ self delete].

	World activeHand showTemporaryCursor: nil.
	evt hand newKeyboardFocus: nil.
	p _ evt cursorPoint.

	((addItemMorph bounds expandBy: 2) containsPoint: p) ifTrue: [
		^ self insertLine: '' at: (self lineCount + 1)].

	((addSublistMorph bounds expandBy: 2) containsPoint: p) ifTrue: [
		newList _ ScratchListMorph new 
							listName: '' target: nil; 
							updateCountMorph; 
							startStepping;
							yourself.
		self insertLine: newList at: (self lineCount + 1).
		^ newList fixLayout].

	listOwner _ self listOwner.
	(((deleteMorph bounds expandBy: 2) containsPoint: p) and: [listOwner notNil]) ifTrue: [
		^ listOwner deleteLineAt: (listOwner indexOf: self)].

	evt rightButtonPressed
		ifTrue: [Sensor waitNoButton. ^ self rightButtonMenu]
		ifFalse:	[
			((resizeMorph bounds expandBy: 4) containsPoint: p)
				ifFalse: [evt hand grabMorph: self]
				ifTrue: [resizeOffset _ self bottomRight - p]].
! !

!ScratchListMorph methodsFor: 'event handling' stamp: 'jm 5/15/2008 14:27'!
mouseMove: evt

	resizeOffset ifNotNil: [
		self extent: (evt cursorPoint - self topLeft) + resizeOffset].
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 6/4/2008 17:36'!
newContents: listOfStrings
	"Set my contents to the given collection of strings."

	scrollPane contents
		removeAllMorphs;
		top: scrollPane top;
		extent: scrollPane extent.

	cellMorphs _ cellMorphs species new: ((2 * listOfStrings size) max: 1000).
	numberMorphs _ #().

	listOfStrings do: [:s | cellMorphs addLast: (self createCell: s)].
	self updateContents.
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 5/31/2008 11:04'!
normalBorderColor

	^ Color r: (148/255) g: (145/255) b: (145/255)
! !

!ScratchListMorph methodsFor: '-- all --' stamp: 'ee 8/7/2008 20:11'!
noteChangeAtIndex: index

	lastActivityIndex _ index.	

	cellMorphs size < 20
		ifTrue: [
			self updateContents.
			(index between: 1 and: numberMorphs size) ifTrue: [
				(numberMorphs at: index) color: (Color white).
				highlightActive _ true].
			lastActivityIndex _ nil]
		ifFalse: [
			listLayoutNeeded _ true].
! !

!ScratchListMorph methodsFor: '-- all --' stamp: 'jens 8/3/2010 22:39'!
noteChangeForReadingAtIndex: index

	lastActivityIndex _ index.	

	cellMorphs size < 20
		ifTrue: [
			self updateContentsForReading.
			(index between: 1 and: numberMorphs size) ifTrue: [
				(numberMorphs at: index) color: (Color white).
				highlightActive _ true].
			lastActivityIndex _ nil]
		ifFalse: [
			listLayoutNeeded _ true].
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/21/2010 16:20'!
privateInsertLine: aString at: aNumber

	| index newCell |
	index _ aNumber asInteger.
	(index > 0 and: [index <= (cellMorphs size + 1)]) ifFalse: [
		lastActivityError _ true.
		^ self].

	newCell _ self createCell: aString.
	index = 1
		ifTrue: [cellMorphs addFirst: newCell]
		ifFalse: [
			index > cellMorphs size
				ifTrue: [cellMorphs addLast: newCell]
				ifFalse: [cellMorphs add: newCell afterIndex: index - 1]].
	^ newCell
! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 7/27/2010 17:16'!
references: anObject

	cellMorphs do: [:m |
		m complexObject ifNotNil: [
			m complexObject == anObject ifTrue: [^ true ].
			(m complexObject respondsTo: #references:) ifTrue: [
				(m complexObject references: anObject) ifTrue: [^true]]]].
	^ false
! !

!ScratchListMorph methodsFor: 'event handling' stamp: 'ee 7/31/2008 12:56'!
rightButtonMenu

	| menu |
	menu _ CustomMenu new.
	menu add: 'export' action: #exportList.
	menu add: 'import' action: #importList.
	menu addLine.
	menu add: 'hide' action: #delete.

	menu localize.
	menu labels at: 2 put: 
		((menu labels at: 2) copyFrom: 1 to: (menu labels at: 2) size - 1), ScratchTranslator ellipsesSuffix.
	menu invokeOn: self.
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jens 7/15/2010 23:28'!
scrollActiveCellIntoView

	| cell page newTop |

	lastActivityIndex _ lastActivityIndex within: 1 and: cellMorphs size.
	cell _ cellMorphs at: lastActivityIndex.
	page _ scrollPane contents.
	(scrollPane bounds containsRect: cell bounds) ifFalse: [
		newTop _ (scrollPane bounds center y) - (cell top - page top).
		newTop _ newTop max: (scrollPane bottom - (cellMorphs last bottom - page top) - 3).
		newTop _ newTop min: scrollPane top.
		page top: newTop].
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 7/8/2010 22:59'!
setLineAt: aNumber to: newContents

	| index cell obj |

	(newContents isKindOf: self class) ifTrue: [
		(newContents containsRecursive: self) ifTrue: [
			self error: 'attempting to create a recursive list']].

	index _ aNumber asInteger.
	(index > 0 and: [index <= cellMorphs size]) ifFalse: [
		lastActivityError _ true.
		^ self].

	(newContents isKindOf: self class)
	| (newContents isKindOf: Morph)
	| (newContents isKindOf: Array)
	| (newContents isKindOf: Boolean)

		ifTrue: [obj _ newContents]
		ifFalse: [ obj _ newContents asString ].
	
	cell _ cellMorphs at: index.

	(cell complexObject respondsTo: #delete)
		ifTrue: [cell complexObject delete].

	(obj isKindOf: String)
		ifTrue: [ 
			cell complexObject: nil.
			cell firstSubmorph contents: obj ]
		ifFalse: [
			cell firstSubmorph contents: ''.
			cell complexObject: obj ].

	cell changed.
	self noteChangeAtIndex: index

! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 8/13/2008 15:33'!
showEmpty
	"Show the empty label."

	| page |
	scrollPane hScrollRelative: 0; vScrollRelative: 0.
	page _ scrollPane contents
		removeAllMorphs;
		extent: scrollPane extent.

	numberMorphs size > 0 ifTrue: [numberMorphs _ #()].

	emptyMorph
		contents: '(empty)' localized;
		position: (page center - (emptyMorph extent // 2)).
	page addMorph: emptyMorph.

	scrollPane updateScrollbars.
	listLayoutNeeded _ false.

! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jm 6/4/2008 19:09'!
step

	self updateTitle.
	self updateBorder.
	self updateCountMorph.
	self updateIndexHighlight.
	listLayoutNeeded ifTrue: [self updateContents].
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jm 5/31/2008 11:46'!
stepTime

	^ 200
! !

!ScratchListMorph methodsFor: 'object i/o' stamp: 'jens 11/24/2009 22:43'!
storeFieldsOn: anObjStream
	"Note: To simplify my representation in the project file, my submorphs are removed before saving and restored when I am read in from an object file."

	| strings complex |

	"self purge.	"

	strings _ cellMorphs asArray collect: [:m | m firstSubmorph contents asString].
	complex _ cellMorphs asArray collect: [:m | m complexObject].

	self removeAllMorphs.
	numberMorphs _ #().

	super storeFieldsOn: anObjStream.
	anObjStream putField: listName.
	anObjStream putField: strings.
	anObjStream putField: target.
	anObjStream putField: complex.

	self addTitleAndControls; addScrollPane.
	titleMorph contents: listName.
	self newContents: strings.
	self complexContents: complex.
	self fixLayout.

! !

!ScratchListMorph methodsFor: 'byob lambdas' stamp: 'jens 4/18/2010 23:31'!
sublistIcon

	| block slot form halfList big |
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
	^((big withOutlineColor: Color gray muchLighter width: 2) "withOutlineColor: Color darkGray width: 1").
! !

!ScratchListMorph methodsFor: 'accessing' stamp: 'jens 9/22/2008 11:23'!
target

	^ target
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jm 5/31/2008 13:56'!
updateBorder

	lastActivityError
		ifTrue: [self borderColor: Color red]
		ifFalse: [self borderColor: self normalBorderColor].
	lastActivityError _ false.
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 1/20/2011 00:45'!
updateContents
	"Update and layout my contents."

	| page numberRight cellWidth inset x y listOwner |

	listOwner _ self listOwner.
	listOwner ifNotNil: [
"		listOwner noteChangeAtIndex: (listOwner indexOf: self)]."
		listOwner updateContentsRecursive].

	cellMorphs size = 0 ifTrue: [^ self showEmpty].

	emptyMorph delete.

	page _ scrollPane contents.
	page changed.

	ScratchTranslator isRTL
		ifTrue: [numberRight _ self right - 5]
		ifFalse: [numberRight _ self left + self largestIndexWidth + 6].

	"word-wrap cell contents and fix cell extents, if needed"
	ScratchTranslator isRTL
		ifTrue: [cellWidth _ self right - self left - self largestIndexWidth - 33]
		ifFalse: [cellWidth _ self right - numberRight - 25].
	inset _ 3.
	cellMorphs do: [:cell |

		(cell complexObject isKindOf: Morph)
			ifTrue: [ (cell complexObject respondsTo: #displayForm)
				ifTrue: [cell extent: cell complexObject displayForm extent +(10@10)]
				ifFalse: [(cell complexObject respondsTo: #thumbnailImageForm)
					ifTrue: [cell extent: cell complexObject thumbnailImageForm extent + (10@10)]
					ifFalse: [cell extent: cell complexObject fullBounds extent +(10@10)]]]
			ifFalse: [
				((cell width ~= cellWidth) or: [cell extent ~= (cell firstSubmorph extent + inset)]) ifTrue: [
				cell firstSubmorph width: cellWidth - inset.
				cell extent: cell firstSubmorph extent + inset]]].

	"position cells"
	ScratchTranslator isRTL
		ifTrue: [x _ self left + 26]
		ifFalse: [x _ numberRight + 4].
	y _ page top + 3.
	cellMorphs do: [:cell |
		cell position: x@y.
		y _ y + cell height - 1].

	self updateIndices: numberRight.

	page extent: (self width - (2 * borderWidth)) @ (y + 3).

	lastActivityIndex ifNotNil: [
 		(lastActivityIndex between: 1 and: cellMorphs size) ifTrue: [
			(numberMorphs at: lastActivityIndex) color: (Color white).
			highlightActive _ true].
		self scrollActiveCellIntoView.
		lastActivityIndex _ nil].
	scrollPane updateScrollbars.
	scrollPane updateScrollbars.

	listLayoutNeeded _ false.
! !

!ScratchListMorph methodsFor: 'list ops' stamp: 'jens 8/3/2010 22:38'!
updateContentsForReading
	"Update and layout my contents."

	| page numberRight cellWidth inset x y listOwner |

	listOwner _ self listOwner.
	listOwner ifNotNil: [
		listOwner noteChangeAtIndex: (listOwner indexOf: self)].
"		listOwner updateContentsRecursive]."

	cellMorphs size = 0 ifTrue: [^ self showEmpty].

	emptyMorph delete.

	page _ scrollPane contents.
	page changed.

	ScratchTranslator isRTL
		ifTrue: [numberRight _ self right - 5]
		ifFalse: [numberRight _ self left + self largestIndexWidth + 6].

	"word-wrap cell contents and fix cell extents, if needed"
	ScratchTranslator isRTL
		ifTrue: [cellWidth _ self right - self left - self largestIndexWidth - 33]
		ifFalse: [cellWidth _ self right - numberRight - 25].
	inset _ 3.
	cellMorphs do: [:cell |

		(cell complexObject isKindOf: Morph)
			ifTrue: [ (cell complexObject respondsTo: #displayForm)
				ifTrue: [cell extent: cell complexObject displayForm extent +(10@10)]
				ifFalse: [cell extent: cell complexObject fullBounds extent +(10@10)]]
			ifFalse: [
				((cell width ~= cellWidth) or: [cell extent ~= (cell firstSubmorph extent + inset)]) ifTrue: [
				cell firstSubmorph width: cellWidth - inset.
				cell extent: cell firstSubmorph extent + inset]]].

	"position cells"
	ScratchTranslator isRTL
		ifTrue: [x _ self left + 26]
		ifFalse: [x _ numberRight + 4].
	y _ page top + 3.
	cellMorphs do: [:cell |
		cell position: x@y.
		y _ y + cell height - 1].

	self updateIndices: numberRight.

	page extent: (self width - (2 * borderWidth)) @ (y + 3).

	lastActivityIndex ifNotNil: [
 		(lastActivityIndex between: 1 and: cellMorphs size) ifTrue: [
			(numberMorphs at: lastActivityIndex) color: (Color white).
			highlightActive _ true].
		self scrollActiveCellIntoView.
		lastActivityIndex _ nil].
	scrollPane updateScrollbars.
	scrollPane updateScrollbars.

	listLayoutNeeded _ false.
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jens 8/1/2010 23:59'!
updateContentsRecursive
	"Update and layout my contents and those of my children."

	| page numberRight cellWidth inset x y |

	cellMorphs size = 0 ifTrue: [^ self showEmpty].
	emptyMorph delete.

	page _ scrollPane contents.
	page changed.

	ScratchTranslator isRTL
		ifTrue: [numberRight _ self right - 5]
		ifFalse: [numberRight _ self left + self largestIndexWidth + 6].

	"word-wrap cell contents and fix cell extents, if needed"
	ScratchTranslator isRTL
		ifTrue: [cellWidth _ self right - self left - self largestIndexWidth - 33]
		ifFalse: [cellWidth _ self right - numberRight - 25].
	inset _ 3.
	cellMorphs do: [:cell |

		(cell complexObject isKindOf: Morph)
			ifTrue: [ 
				(cell complexObject respondsTo: #displayForm)
					ifTrue: [cell extent: cell complexObject displayForm extent +(10@10)]
					ifFalse: [cell extent: cell complexObject fullBounds extent +(10@10)].
				(cell complexObject isKindOf: self class)
					ifTrue: [cell complexObject updateContentsRecursive]]
			ifFalse: [
				((cell width ~= cellWidth) or: [cell extent ~= (cell firstSubmorph extent + inset)]) ifTrue: [
				cell firstSubmorph width: cellWidth - inset.
				cell extent: cell firstSubmorph extent + inset]]].

	"position cells"
	ScratchTranslator isRTL
		ifTrue: [x _ self left + 26]
		ifFalse: [x _ numberRight + 4].
	y _ page top + 3.
	cellMorphs do: [:cell |
		cell position: x@y.
		y _ y + cell height - 1].

	self updateIndices: numberRight.

	page extent: (self width - (2 * borderWidth)) @ (y + 3).

	lastActivityIndex ifNotNil: [
 		(lastActivityIndex between: 1 and: cellMorphs size) ifTrue: [
			(numberMorphs at: lastActivityIndex) color: (Color white).
			highlightActive _ true].
		self scrollActiveCellIntoView.
		lastActivityIndex _ nil].
	scrollPane updateScrollbars.
	scrollPane updateScrollbars.

	listLayoutNeeded _ false.
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jens 4/18/2010 23:35'!
updateCountMorph

	countMorph contents: 'length' localized, ScratchTranslator colonSuffix, ' ', self lineCount printString.
	countMorph left: ((self left + ((self width - countMorph width) // 2) + 3) max: (addSublistMorph right + 1))
! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jens 4/19/2010 02:26'!
updateIndexHighlight
	"Update the highlighted index."

	highlightActive ifTrue: [
		numberMorphs do: [:m | m color: self indexColor].
		highlightActive _ false].
! !

!ScratchListMorph methodsFor: 'private' stamp: 'jm 5/31/2008 13:57'!
updateIndices: rightX

	| s newNumbers page num cell |
	numberMorphs size > cellMorphs size ifTrue: [
		cellMorphs size + 1 to: numberMorphs size do: [:i | (numberMorphs at: i) delete].
		numberMorphs _ numberMorphs copyFrom: 1 to: cellMorphs size].

	newNumbers _ #().
	numberMorphs size < cellMorphs size ifTrue: [
		page _ scrollPane contents.
		s _ StringMorph new
			color: self indexColor;
			font: (ScratchFrameMorph getFont: #Label).
		newNumbers _ (numberMorphs size + 1 to: cellMorphs size)
			collect: [:i | s fullCopy contents: i printString].
		newNumbers do: [:m | page addMorph: m].
		numberMorphs _ numberMorphs, newNumbers].

	1 to: cellMorphs size do: [:i |
		num _ numberMorphs at: i.
		cell _ cellMorphs at: i.
		num position: (rightX - num width) @ (cell top + ((cell height - num height) // 2))].

! !

!ScratchListMorph methodsFor: 'stepping' stamp: 'jm 6/17/2008 21:35'!
updateTitle
	"Update my title if I am owned by a sprite and the sprite name changes."

	| s |
	listName ifNil: [^ self].

	(target isKindOf: ScratchSpriteMorph)
		ifTrue: [s _ target objName, ' ', listName]
		ifFalse: [s _ listName].

	titleMorph contents = s ifFalse: [
		titleMorph contents: s.
		self fixLayout].
! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScratchListMorph class
	instanceVariableNames: ''!

!ScratchListMorph class methodsFor: 'instance creation' stamp: 'jens 4/21/2010 21:56'!
deepCopyFrom: anArray
	^self deepCopyFrom: anArray from: 1 to: anArray size

! !

!ScratchListMorph class methodsFor: 'instance creation' stamp: 'jens 4/21/2010 22:11'!
deepCopyFrom: anArray from: start to: stop

	| ans converter element |
	converter _ ScriptableScratchMorph new.
	ans _ self new.
	ans listName: '' target: nil.
	start to: stop do: [:i |
		element _ converter asListElement: (anArray at: i).
		(element isKindOf: self)
			ifTrue: [element _ self deepCopyFrom: (element asArray) from: 1 to: element lineCount].
		ans privateInsertLine: element at: (ans lineCount + 1)].
	ans updateCountMorph.
	ans updateContents.
	stop > 0 ifTrue: [
		ans noteChangeAtIndex: stop].
	^ ans
	
! !

!ScratchListMorph class methodsFor: 'instance creation' stamp: 'jens 4/21/2010 16:27'!
on: anArray
	^self on: anArray from: 1 to: anArray size

! !

!ScratchListMorph class methodsFor: 'instance creation' stamp: 'jens 4/21/2010 22:24'!
on: anArray from: start to: stop

	| ans converter |
	converter _ ScriptableScratchMorph new.
	ans _ self new.
	ans listName: '' target: nil.
	start to: stop do: [:i |
		ans privateInsertLine: (converter asListElement: (anArray at: i)) at: (ans lineCount + 1)].
	ans updateCountMorph.
	ans updateContents.
	stop > 0 ifTrue: [
		ans noteChangeAtIndex: stop].
	^ ans
	
! !

!ScratchListMorph class methodsFor: 'instance creation' stamp: 'jens 2/22/2010 02:01'!
with: anObject

	^ self new
		insertLine: (ScriptableScratchMorph new asListElement: anObject) at: 1
	
! !
