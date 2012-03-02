CharacterScanner subclass: #DisplayScanner
	instanceVariableNames: 'bitBlt lineY runX foregroundColor backgroundColor fillBlt lineHeight paragraph paragraphColor morphicOffset ignoreColorChanges '
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'Graphics-Text'!
!DisplayScanner commentStamp: '<historical>' prior: 0!
My instances are used to scan text and display it on the screen or in a hidden form.!


!DisplayScanner methodsFor: 'scanning' stamp: 'jm 7/23/2003 01:50'!
displayLine: textLine offset: offset leftInRun: leftInRun
	"The call on the primitive (scanCharactersFrom:to:in:rightX:) will be interrupted according to an array of stop conditions passed to the scanner at which time the code to handle the stop condition is run and the call on the primitive continued until a stop condition returns true (which means the line has terminated).  leftInRun is the # of characters left to scan in the current run; when 0, it is time to call setStopConditions."
	| done stopCondition nowLeftInRun startIndex string lastPos |
	line _ textLine.
	morphicOffset _ offset.
	leftMargin _ (line leftMarginForAlignment: textStyle alignment) + offset x.
	destX _ runX _ leftMargin.
	rightMargin _ line rightMargin + offset x.
	lineY _ line top + offset y.
	lineHeight _ line lineHeight.
	fillBlt == nil ifFalse:
		["Not right"
		fillBlt destX: line left destY: lineY
			width: leftMargin - line left height: lineHeight; copyBits].
	lastIndex _ line first.
	leftInRun <= 0
		ifTrue: [self setStopConditions.  "also sets the font"
				nowLeftInRun _ text runLengthFor: lastIndex]
		ifFalse: [nowLeftInRun _ leftInRun].
	destY _ lineY + line baseline - font ascent.
	runStopIndex _ lastIndex + (nowLeftInRun - 1) min: line last.
	spaceCount _ 0.
	self handleIndentation.
	done _ false.
	string _ text string.
	[done] whileFalse:[
		startIndex _ lastIndex.
		lastPos _ destX@destY.
		stopCondition _ self scanCharactersFrom: lastIndex to: runStopIndex
						in: string rightX: rightMargin stopConditions: stopConditions
						kern: kern.
		lastIndex >= startIndex ifTrue:[
			font displayString: string on: bitBlt 
				from: startIndex to: lastIndex at: lastPos kern: kern].
		"see setStopConditions for stopping conditions for displaying."
		done _ self perform: stopCondition].
	fillBlt == nil ifFalse:
		[fillBlt destX: destX destY: lineY width: line right-destX height: lineHeight;
				copyBits].
	^ runStopIndex - lastIndex   "Number of characters remaining in the current run"! !

!DisplayScanner methodsFor: 'scanning' stamp: 'jm 7/22/2003 20:49'!
displayLines: linesInterval in: aParagraph clippedBy: visibleRectangle
	"The central display routine. The call on the primitive 
	(scanCharactersFrom:to:in:rightX:) will be interrupted according to an 
	array of stop conditions passed to the scanner at which time the code to 
	handle the stop condition is run and the call on the primitive continued 
	until a stop condition returns true (which means the line has 
	terminated)."
	| runLength done stopCondition leftInRun startIndex string lastPos |
	"leftInRun is the # of characters left to scan in the current run;
		when 0, it is time to call 'self setStopConditions'"
	leftInRun _ 0.
	self initializeFromParagraph: aParagraph clippedBy: visibleRectangle.
	ignoreColorChanges _ false.
	paragraph _ aParagraph.
	foregroundColor _ paragraphColor _ aParagraph foregroundColor.
	backgroundColor _ aParagraph backgroundColor.
	aParagraph backgroundColor isTransparent
		ifTrue: [fillBlt _ nil]
		ifFalse: [fillBlt _ bitBlt copy.  "Blt to fill spaces, tabs, margins"
				fillBlt sourceForm: nil; sourceOrigin: 0@0.
				fillBlt fillColor: aParagraph backgroundColor].
	rightMargin _ aParagraph rightMarginForDisplay.
	lineY _ aParagraph topAtLineIndex: linesInterval first.
	linesInterval do: 
		[:lineIndex | 
		leftMargin _ aParagraph leftMarginForDisplayForLine: lineIndex.
		destX _ (runX _ leftMargin).
		line _ aParagraph lines at: lineIndex.
		lineHeight _ line lineHeight.
		fillBlt == nil ifFalse:
			[fillBlt destX: visibleRectangle left destY: lineY
				width: leftMargin - visibleRectangle left height: lineHeight; copyBits].
		lastIndex _ line first.
		leftInRun <= 0
			ifTrue: [self setStopConditions.  "also sets the font"
					leftInRun _ text runLengthFor: line first].
		destY _ lineY + line baseline - font ascent.  "Should have happened in setFont"
		runLength _ leftInRun.
		runStopIndex _ lastIndex + (runLength - 1) min: line last.
		leftInRun _ leftInRun - (runStopIndex - lastIndex + 1).
		spaceCount _ 0.
		done _ false.
		string _ text string.
		self handleIndentation.
		[done] whileFalse:[
			startIndex _ lastIndex.
			lastPos _ destX@destY.
			stopCondition _ self scanCharactersFrom: lastIndex to: runStopIndex
						in: string rightX: rightMargin stopConditions: stopConditions
						kern: kern.
			lastIndex >= startIndex ifTrue:[
				font displayString: string on: bitBlt 
					from: startIndex to: lastIndex at: lastPos kern: kern].
		"see setStopConditions for stopping conditions for displaying."
		done _ self perform: stopCondition].
		fillBlt == nil ifFalse:
			[fillBlt destX: destX destY: lineY width: visibleRectangle right-destX height: lineHeight; copyBits].
		lineY _ lineY + lineHeight]! !

!DisplayScanner methodsFor: 'scanning' stamp: 'ar 5/17/2000 17:36'!
placeEmbeddedObject: anchoredMorph
	(super placeEmbeddedObject: anchoredMorph) ifFalse: [^ false].
	anchoredMorph isMorph 
		ifTrue: [anchoredMorph position: ((destX - anchoredMorph width)@lineY) - morphicOffset]
		ifFalse: [destY _ lineY.
				runX _ destX.
				anchoredMorph displayOn: bitBlt destForm at: destX - anchoredMorph width @ destY].
	^ true! !


!DisplayScanner methodsFor: 'private' stamp: 'ar 5/17/2000 17:36'!
fillLeading
	"At the end of every run (really only needed when font size changes),
	fill any extra leading above and below the font in the larger line height"

	fillBlt == nil ifTrue: [^ self].  "No fill requested"

	"Fill space above the font"
	fillBlt destX: runX destY: lineY width: destX - runX height: destY - lineY;
		copyBits.

	"Fill space below the font"
	fillBlt destY: (destY + font height); height: (lineY + lineHeight) - (destY + font height);
		copyBits.
! !

!DisplayScanner methodsFor: 'private' stamp: 'jm 5/29/2003 17:58'!
initializeFromParagraph: aParagraph clippedBy: clippingRectangle

	super initializeFromParagraph: aParagraph clippedBy: clippingRectangle.
	bitBlt _ BitBlt toForm: aParagraph destinationForm.
	bitBlt fillColor: aParagraph fillColor.	"sets halftoneForm"
	bitBlt combinationRule: aParagraph rule.
	bitBlt clipRect: clippingRectangle.
! !

!DisplayScanner methodsFor: 'private' stamp: 'ar 5/17/2000 19:26'!
setDestForm: df
	bitBlt setDestForm: df.! !

!DisplayScanner methodsFor: 'private' stamp: 'ar 5/17/2000 18:57'!
setFont 
	foregroundColor _ paragraphColor.
	super setFont.  "Sets font and emphasis bits, and maybe foregroundColor"
	font installOn: bitBlt foregroundColor: foregroundColor backgroundColor: backgroundColor.
	text ifNotNil:[destY _ lineY + line baseline - font ascent]! !

!DisplayScanner methodsFor: 'private' stamp: 'ar 5/17/2000 20:25'!
setPort: aBitBlt
	"Install the BitBlt to use"
	bitBlt _ aBitBlt.
	bitBlt sourceForm: nil. "Make sure font installation won't be confused"
! !

!DisplayScanner methodsFor: 'private' stamp: 'ar 1/8/2000 14:51'!
text: t textStyle: ts foreground: foreColor background: backColor fillBlt: blt ignoreColorChanges: shadowMode
	text _ t.
	textStyle _ ts. 
	foregroundColor _ paragraphColor _ foreColor.
	(backgroundColor _ backColor) isTransparent ifFalse:
		[fillBlt _ blt.
		fillBlt fillColor: backgroundColor].
	ignoreColorChanges _ shadowMode! !

!DisplayScanner methodsFor: 'private' stamp: 'ar 1/8/2000 14:51'!
textColor: textColor
	ignoreColorChanges ifTrue: [^ self].
	foregroundColor _ textColor! !


!DisplayScanner methodsFor: 'stop conditions' stamp: 'ar 5/19/2000 14:46'!
characterNotInFont
	"See the note in CharacterScanner>>characterNotInFont.
	All fonts have an illegal character to be used when a character is not 
	within the font's legal range. When characters out of ranged are 
	encountered in scanning text, then this special character indicates the 
	appropriate behavior. The character is usually treated as a unary 
	message understood by a subclass of CharacterScanner."

	| illegalAsciiString saveIndex stopCondition lastPos |
	saveIndex _ lastIndex.
	lastPos _ destX @ destY.
	illegalAsciiString _ String with: (font maxAscii + 1) asCharacter.
	stopCondition _ self scanCharactersFrom: 1 to: 1
			in: illegalAsciiString
			rightX: rightMargin stopConditions: stopConditions
			kern: kern.
	font displayString: illegalAsciiString 
			on: bitBlt from: 1 to: 1 at: lastPos kern: kern.
	lastIndex _ saveIndex + 1.
	stopCondition ~= (stopConditions at: EndOfRun)
		ifTrue:	[^self perform: stopCondition]
		ifFalse: [lastIndex = runStopIndex
					ifTrue:	[^self perform: (stopConditions at: EndOfRun)].
				^false]
! !

!DisplayScanner methodsFor: 'stop conditions' stamp: 'ar 1/8/2000 14:42'!
cr
	"When a carriage return is encountered, simply increment the pointer 
	into the paragraph."

	lastIndex_ lastIndex + 1.
	^false! !

!DisplayScanner methodsFor: 'stop conditions' stamp: 'ar 1/8/2000 14:42'!
crossedX
	"This condition will sometimes be reached 'legally' during display, when, 
	for instance the space that caused the line to wrap actually extends over 
	the right boundary. This character is allowed to display, even though it 
	is technically outside or straddling the clipping ectangle since it is in 
	the normal case not visible and is in any case appropriately clipped by 
	the scanner."

	self fillLeading.
	^ true ! !

!DisplayScanner methodsFor: 'stop conditions' stamp: 'ar 1/9/2000 13:56'!
endOfRun
	"The end of a run in the display case either means that there is actually 
	a change in the style (run code) to be associated with the string or the 
	end of this line has been reached."
	| runLength |
	self fillLeading.  "Fill any leading above or below the font"
	lastIndex = line last ifTrue: [^true].
	runX _ destX.
	runLength _ text runLengthFor: (lastIndex _ lastIndex + 1).
	runStopIndex _ lastIndex + (runLength - 1) min: line last.
	self setStopConditions.
	^ false! !

!DisplayScanner methodsFor: 'stop conditions' stamp: 'ar 5/17/2000 17:36'!
paddedSpace
	"Each space is a stop condition when the alignment is right justified. 
	Padding must be added to the base width of the space according to 
	which space in the line this space is and according to the amount of 
	space that remained at the end of the line when it was composed."
	| oldX |
	spaceCount _ spaceCount + 1.
	oldX _ destX.
	destX _ oldX + spaceWidth + (line justifiedPadFor: spaceCount).
	fillBlt == nil ifFalse:
		[fillBlt destX: oldX destY: destY width: destX - oldX height: font height; copyBits].
	lastIndex _ lastIndex + 1.
	^ false! !

!DisplayScanner methodsFor: 'stop conditions' stamp: 'jm 7/23/2003 16:20'!
plainTab

	| oldX |
	oldX _ destX.
	super plainTab.
	fillBlt ifNotNil: [
		fillBlt destX: oldX destY: destY width: destX - oldX height: font height; copyBits].
! !

!DisplayScanner methodsFor: 'stop conditions' stamp: 'ar 5/18/2000 16:47'!
setStopConditions
	"Set the font and the stop conditions for the current run."
	
	self setFont.
	textStyle alignment = Justified ifTrue:[
		"Make a local copy of stop conditions so we don't modify the default"
		stopConditions == DefaultStopConditions 
			ifTrue:[stopConditions _ stopConditions copy].
		stopConditions at: Space asciiValue + 1 put: #paddedSpace]! !

!DisplayScanner methodsFor: 'stop conditions' stamp: 'jm 8/30/2003 21:47'!
stringWidth: aString from: startIndex to: endIndex
	"Answer the width of the given string between the given indices."

	destX _ destY _ 0.
	aString ifNil: [^ 0].
	self primScanCharactersFrom: startIndex to: endIndex in: aString
		rightX: 99999	"virtual infinity"
		stopConditions: stopConditions
		kern: kern.
	^ destX
! !

!DisplayScanner methodsFor: 'stop conditions' stamp: 'ar 5/17/2000 17:36'!
tab
	| oldX |
	oldX _ destX.
	destX _ (textStyle alignment == Justified and: [self leadingTab not])
		ifTrue:		"imbedded tabs in justified text are weird"
			[destX + (textStyle tabWidth - (line justifiedTabDeltaFor: spaceCount)) max: destX]
		ifFalse: 
			[textStyle nextTabXFrom: destX
				leftMargin: leftMargin
				rightMargin: rightMargin].
	fillBlt == nil ifFalse:
		[fillBlt destX: oldX destY: destY width: destX - oldX height: font height; copyBits].
	lastIndex _ lastIndex + 1.
	^ false! !


!DisplayScanner methodsFor: 'quick print' stamp: 'ar 5/18/2000 18:00'!
drawString: aString at: aPoint
	"Draw the given string."

	destX _ aPoint x asInteger.
	destY _ aPoint y asInteger.
	self primScanCharactersFrom: 1 to: aString size in: aString
		rightX: bitBlt clipX + bitBlt clipWidth + font maxWidth
		stopConditions: stopConditions kern: kern.
	font displayString: aString on: bitBlt from: 1 to: lastIndex at: aPoint kern: kern.! !

!DisplayScanner methodsFor: 'quick print' stamp: 'jm 6/2/2008 14:19'!
lineHeight
	"Answer the height of the font used by QuickPrint."

	^ (self stringExtent: '') y
! !

!DisplayScanner methodsFor: 'quick print' stamp: 'jm 5/29/2003 17:58'!
quickPrintOn: aForm box: aRectangle font: aStrikeFont color: textColor
	"Initialize myself."
	bitBlt _ BitBlt toForm: aForm.
	backgroundColor _ Color transparent.
	paragraphColor _ textColor.
	font _ aStrikeFont ifNil: [TextStyle defaultFont].
	emphasisCode _ 0.
	kern _ 0.
	indentationLevel _ 0.
	self setFont.
	"Override cbrule and map"
	bitBlt combinationRule: Form paint.
	bitBlt colorMap: (Bitmap with: 0      "Assumes 1-bit deep fonts"
						with: (textColor pixelValueForDepth: bitBlt destForm depth)).
	bitBlt clipRect: aRectangle.! !

!DisplayScanner methodsFor: 'quick print' stamp: 'JM 3/2/2012 10:50'!
quickPrintOnAlpha: aForm box: aRectangle font: aStrikeFont color: textColor
	"Initialize myself."
	bitBlt _ BitBlt toForm: aForm.
	backgroundColor _ Color transparent.
	paragraphColor _ textColor.
	font _ aStrikeFont ifNil: [TextStyle defaultFont].
	emphasisCode _ 0.
	kern _ 0.
	indentationLevel _ 0.
	self setFont.
	"Override cbrule and map"
	bitBlt combinationRule: 24.
	bitBlt colorMap: (Bitmap with: 0      "Assumes 1-bit deep fonts"
						with: (textColor pixelValueForDepth: bitBlt destForm depth)).
	bitBlt clipRect: aRectangle.! !

!DisplayScanner methodsFor: 'quick print' stamp: 'jm 6/2/2008 18:00'!
stringExtent: aString
	"Answer the extent of the given string using my font."
	"(1 to: 10) collect: [:i |
		(DisplayScanner quickPrintOn: Display) stringExtent: (String new: i withAll: $A)]"

	aString ifNil: [^ 0@0].

	destX _ destY _ 0.
	aString ifNil: [^ 0].
	self primScanCharactersFrom: 1 to: aString size in: aString
		rightX: 99999	"virtual infinity"
		stopConditions: stopConditions
		kern: 0.

	^ (destX + (kern * ((aString size - 1) max: 0))) @ font height
! !

!DisplayScanner methodsFor: 'quick print' stamp: 'jm 6/2/2008 14:20'!
stringWidth: aString
	"Answer the width of the given string."

	^ (self stringExtent: aString) x
! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DisplayScanner class
	instanceVariableNames: ''!

!DisplayScanner class methodsFor: 'queries' stamp: 'ar 5/17/2000 17:39'!
defaultFont
	^ TextStyle defaultFont! !

!DisplayScanner class methodsFor: 'queries' stamp: 'ar 5/17/2000 17:40'!
quickPrintOn: aForm
	"Create an instance to print on the given form in the given rectangle."

	^(super new) quickPrintOn: aForm box: aForm boundingBox font: self defaultFont color: Color black! !

!DisplayScanner class methodsFor: 'queries' stamp: 'ar 5/17/2000 17:39'!
quickPrintOn: aForm box: aRectangle
	"Create an instance to print on the given form in the given rectangle."

	^(super new) quickPrintOn: aForm box: aRectangle font: self defaultFont color: Color black! !

!DisplayScanner class methodsFor: 'queries' stamp: 'ar 5/17/2000 17:40'!
quickPrintOn: aForm box: aRectangle font: aStrikeFont
	"Create an instance to print on the given form in the given rectangle."

	^(super new) quickPrintOn: aForm box: aRectangle font: aStrikeFont color: Color black! !

!DisplayScanner class methodsFor: 'queries' stamp: 'ar 5/17/2000 17:40'!
quickPrintOn: aForm box: aRectangle font: aStrikeFont color: textColor
	"Create an instance to print on the given form in the given rectangle."

	^ (super new) quickPrintOn: aForm box: aRectangle font: aStrikeFont color: textColor! !

!DisplayScanner class methodsFor: 'queries' stamp: 'jm 8/30/2003 21:48'!
quickPrintOn: aForm font: aStrikeFont
	"Create an instance to print on the given form in the given rectangle."

	^ super new quickPrintOn: aForm box: aForm boundingBox font: aStrikeFont color: Color black! !

!DisplayScanner class methodsFor: 'queries' stamp: 'JM 3/2/2012 10:49'!
quickPrintOnAlpha: aForm box: aRectangle font: aStrikeFont color: textColor
	"Create an instance to print on the given form in the given rectangle."

	^ (super new) quickPrintOnAlpha: aForm box: aRectangle font: aStrikeFont color: textColor! !


!DisplayScanner class methodsFor: 'examples' stamp: 'jm 1/24/2008 12:15'!
example
	"This will quickly print all the numbers from 1 to 100 on the display, then answer the extent of the string 'hello world'."
	"DisplayScanner example"

	| scanner |
	scanner _ self quickPrintOn: Display.
	0 to: 99 do: [: i | scanner drawString: i printString at: (i//10*20) @ (i\\10*12) ].
	^ scanner stringExtent: 'hello world'
! !

!DisplayScanner class methodsFor: 'examples' stamp: 'jm 2/19/2005 21:36'!
multiLineStringExtent: aString font: aStrikeFont
	"Answer the extent of the given string, which may include line breaks. Does not do line wrapping."
	"Example use:
self multiLineStringExtent:
'This is a test
of a multiple line string with a very long line in the
middle.'
	 font: self defaultFont"

	| lines h w scanner |
	lines _ aString lines.
	h _ lines size * (aStrikeFont height + 4).
	w _ 0.
	scanner _ self quickPrintOn: Display font: aStrikeFont.
	lines do: [:s | w _ w max: (scanner stringWidth: s)].
	^ w@h
! !
