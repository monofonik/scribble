Object subclass: #Utilities
	instanceVariableNames: ''
	classVariableNames: 'AuthorInitials AuthorName '
	poolDictionaries: ''
	category: 'System-Support'!
!Utilities commentStamp: '<historical>' prior: 0!
A repository for general and miscellaneous utilities; much of what is here are in effect global methods that don't naturally attach to anything else. All the functionality is implemented as class messages.
!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Utilities class
	instanceVariableNames: ''!

!Utilities class methodsFor: 'identification' stamp: 'dhhi 11/6/97 16:48'!
authorInitials
	"Answer the initials to be used to identify the current code author.  "

	[AuthorInitials isEmpty] whileTrue: [self setAuthorInitials].
	^ AuthorInitials! !

!Utilities class methodsFor: 'identification' stamp: 'sw 7/6/1998 11:49'!
authorInitialsPerSe
	"Answer the currently-prevailing author initials, such as they, empty or not"

	^ AuthorInitials! !

!Utilities class methodsFor: 'identification' stamp: 'jm 5/31/2003 16:25'!
authorName

	AuthorName ifNil: [
		AuthorName _ FillInTheBlank 
			request: 'Please type your name:'
			initialAnswer: 'Your Name'].
	^ AuthorName
! !

!Utilities class methodsFor: 'identification' stamp: 'tk 4/10/98 06:25'!
changeStamp 
	"Answer a string to be pasted into source code to mark who changed it and when."
	^ self authorInitials , ' ' , Date today mmddyyyy, ' ',
		((String streamContents: [:s | Time now print24: true on: s]) copyFrom: 1 to: 5)! !

!Utilities class methodsFor: 'identification' stamp: 'jm 6/23/2003 09:36'!
clearAuthorInfo

	AuthorInitials _ ''.
	AuthorName _ nil.
! !

!Utilities class methodsFor: 'identification' stamp: 'sw 11/13/1999 22:45'!
dateTimeSuffix
	"Answer a string which indicates the date and time, intended for use in building fileout filenames, etc."

	"Utilities dateTimeSuffix"
	^ Preferences twentyFourHourFileStamps
		ifFalse:
			[self monthDayTimeStringFrom: Time primSecondsClock]
		ifTrue:
			[self monthDayTime24StringFrom: Time primSecondsClock]! !

!Utilities class methodsFor: 'identification' stamp: 'di 6/13/97 13:52'!
fixStamp: changeStamp 
	| parts |
	parts _ changeStamp findTokens: ' '.
	(parts size > 0 and: [parts last first isLetter]) ifTrue:
		["Put initials first in all time stamps..."
		^ String streamContents:
				[:s | s nextPutAll: parts last.
				parts allButLast do: [:p | s space; nextPutAll: p]]].
	^ changeStamp! !

!Utilities class methodsFor: 'identification' stamp: 'sw 11/13/1999 23:03'!
monthDayTime24StringFrom: aSecondCount
	| aDate aTime |
	"From the date/time represented by aSecondCount, produce a string which indicates the date and time in the compact form
             ddMMMhhmm		where dd is a two-digit day-of-month, MMM is the alpha month abbreviation and hhmm is the time on a 24-hr clock.

          Utilities monthDayTime24StringFrom: Time primSecondsClock
"

	aDate _ Date fromSeconds: aSecondCount.
	aTime _ Time fromSeconds: aSecondCount \\ 86400.

	^ (aDate dayOfMonth asTwoCharacterString), 
		(aDate monthName copyFrom: 1 to: 3), 
		(aTime hhmm24)! !

!Utilities class methodsFor: 'identification' stamp: 'sw 11/13/1999 23:03'!
monthDayTimeStringFrom: aSecondCount
	| aDate aTime |
	"From the date/time represented by aSecondCount, produce a string which indicates the date and time in the form:
		ddMMMhhmmPP	  where:
							dd is a two-digit day-of-month,
							MMM is the alpha month abbreviation,
							hhmm is the time,
							PP is either am or pm

          Utilities monthDayTimeStringFrom: Time primSecondsClock
"

	aDate _ Date fromSeconds: aSecondCount.
	aTime _ Time fromSeconds: aSecondCount \\ 86400.

	^ (aDate dayOfMonth asTwoCharacterString), 
		(aDate monthName copyFrom: 1 to: 3), 
		((aTime hours \\ 12) asTwoCharacterString), 
		(aTime minutes asTwoCharacterString),
		(aTime hours > 12 ifTrue: ['pm'] ifFalse: ['am'])! !

!Utilities class methodsFor: 'identification' stamp: 'jm 12/5/2002 12:15'!
setAuthorInitials
	"Put up a dialog allowing the user to specify the author's initials.  "

	self setAuthorInitials:
		(FillInTheBlank
			request: 'Please type your initials: '
			initialAnswer: AuthorInitials)
! !

!Utilities class methodsFor: 'identification' stamp: 'dhhi 11/6/97 16:44'!
setAuthorInitials: aString

	AuthorInitials _ aString! !


!Utilities class methodsFor: 'support windows' stamp: 'sma 2/12/2000 20:29'!
commandKeyMappings
	^ self class firstCommentAt: #commandKeyMappings

"Lower-case command keys
(use with Cmd key on Mac and Alt key on other platforms)

a	Select all
b	Browse it (selection is a class name)
c	Copy selection
d	Do it (selection is a valid expression)
e	Exchange selection with prior selection
f	Find
g	Find again
h	Set selection as search string for find again
i	Inspect it (selection is a valid expression)
j	Again once
k	Set font
l	Cancel
m	Implementors of it (selection is a message selector)
n	Senders of it (selection is a message selector)
o	Spawn current method
p	Print it (selection is a valid expression)
q	Query symbol (toggle all possible completion for a given prefix)
r	Recognizer
s	Save (i.e. accept)
u	Toggle alignment
v	Paste
w	Delete preceding word
x	Cut selection
y	Swap characters
z	Undo

Note: for Do it, Senders of it, etc., a null selection will be expanded to a word or to the current line in an attempt to do what you want.  Also note that Senders/Implementors of it will find the outermost keyword selector in a large selection, as when you have selected a bracketed expression or an entire line.  Finally note that the same cmd-m and cmd-n (and cmd-v for versions) work in the message pane of most browsers.

Upper-case command keys
(use with Shift-Cmd, or Ctrl on Mac
 or Shift-Alt on other platforms; sometimes Ctrl works too)

A	Advance argument
B	Browse it in this same browser (in System browsers only)
C	Compare argument to clipboard
D	Duplicate
E	Method strings containing it
F	Insert 'ifFalse:'
I	Inspect via Object Explorer
J	Again many
K	Set style
L	Outdent (move selection one tab-stop left)
N	References to it
O	Open single-message browser (in selector lists)
R	Indent (move selection one tab-stap right)
S	Search
T	Insert 'ifTrue:'
U	Convert linefeeds to carriage returns in selection
V	Paste author's initials
W	Selectors containing it
X	Force selection to lowercase
Y	Force selection to uppercase
Z	Capitalize all words in selection

Other special keys

Backspace	Backward delete character
Del			Forward delete character
Shift-Bcksp	Backward delete word
Shift-Del	Forward delete word
Esc			Select current type-in

Cursor keys
left, right,
up, or
down		Move cursor left, right, up or down
Ctrl+Left	Move cursor left one word
Ctrl+Right	Move cursor right one word
Home		Move cursor to begin of line or begin of text
End			Move cursor to end of line or end of text
PgUp, or
Ctrl+Up		Move cursor up one page
PgDown, or
Ctrl+Down	Move cursor down one page

Note all these keys can be used together with Shift to define or enlarge the selection. You cannot however shrink that selection again, which is, compared to other systems, still a limitation aka bug.

Other Cmd-key combinations (does not work on all platforms)

Return		Insert return followed by as many tabs as the previous line
			(with a further adjustment for additional brackets in that line)
Space		Select the current word as with double clicking

Enclose the selection in a kind of bracket.  Each is a toggle.
(does not work on all platforms)
Ctrl-(	Enclose within ( and ), or remove enclosing ( and )
Ctrl-[	Enclose within [ and ], or remove enclosing [ and ]
Crtl-{	Enclose within { and }, or remove enclosing { and }
Ctrl-<	Enclose within < and >, or remove enclosing < and >
Ctrl-'	Enclose within ' and ', or remove enclosing ' and '
Ctrl-""	Enclose within "" and "", or remove enclosing "" and ""

Note also that you can double-click just inside any of the above delimiters (or at the beginning or end of a line) to select the text enclosed.

Text Emphasis...
(does not work on all platforms)
Cmd-1	10 point font
Cmd-2	12 point font
Cmd-3	18 point font
Cmd-4	24 point font
Cmd-5	36 point font
Cmd-6	color, action-on-click, link to class comment, link to method, url
		Brings up a menu.  To remove these properties, select
		more than the active part and then use command-0.
Cmd-7	bold
Cmd-8	italic
Cmd-9	narrow (same as negative kern)
Cmd-0	plain text (resets all emphasis)
Cmd--	underlined (toggles it)
Cmd-=	struck out (toggles it)

Shift-Cmd--	(aka _) negative kern (letters 1 pixel closer)
Shift-Cmd-+	positive kern (letters 1 pixel larger spread)
"! !

!Utilities class methodsFor: 'support windows' stamp: 'di 9/23/1998 01:53'!
openCommandKeyHelp
	"Open a window giving command key help."
	"Utilities openCommandKeyHelp"

	(StringHolder new contents: self commandKeyMappings)
		openLabel: 'Command Key Actions'
! !


!Utilities class methodsFor: 'user interface' stamp: 'sma 4/30/2000 10:17'!
informUser: aString during: aBlock
	"Display a message above (or below if insufficient room) the cursor during execution of the given block."
	"Utilities informUser: 'Just a sec!!' during: [(Delay forSeconds: 1) wait]"

	Smalltalk isMorphic
		ifTrue:
			[(MVCMenuMorph from: (SelectionMenu labels: '') title: aString)
				displayAt: Sensor cursorPoint during: [aBlock value].
			^ self].

	(SelectionMenu labels: '')
		displayAt: Sensor cursorPoint
		withCaption: aString
		during: [aBlock value]! !

!Utilities class methodsFor: 'user interface' stamp: 'sma 4/30/2000 10:18'!
informUserDuring: aBlock
	"Display a message above (or below if insufficient room) the cursor during execution of the given block."
	"Utilities informUserDuring:[:bar|
		#(one two three) do:[:info|
			bar value: info.
			(Delay forSeconds: 1) wait]]"
	Smalltalk isMorphic
		ifTrue:
			[(MVCMenuMorph from: (SelectionMenu labels: '') title: '						')
				informUserAt: Sensor cursorPoint during: aBlock.
			^ self].
	aBlock value:[:string| Transcript cr; show: string]! !


!Utilities class methodsFor: 'version control' stamp: 'JM 11/9/2011 17:16'!
dateOfLatestChangeToClass: aClass

	"Returns the date of when a class last changed (or nil if it was long, long ago)"
 
	| dates |

	dates _ aClass selectors asOrderedCollection 
		collect: [ :sel | 
			self dateOfLatestChangeToMethod: (aClass compiledMethodAt: sel) ].
	dates _ dates reject: [ :date | date isNil ].
	dates _ dates asSortedCollection.
	(dates isEmpty) 
		ifFalse:	[^dates last]
		ifTrue: [^nil]! !

!Utilities class methodsFor: 'version control' stamp: 'JM 11/9/2011 17:16'!
dateOfLatestChangeToMethod: aMethod

"Returns the date (extracted from the timestamp) for when a method was last changed, or nil if it is very old"
| datestamp |
 
datestamp _ (self timeStampForMethod: aMethod) withoutLeadingBlanks.

('* */*/* *' match: datestamp)	"initials date time"
"((datestamp size > 4) and: [(datestamp occurrencesOf: Character space) = 2])"
	ifFalse: [^nil] 
	ifTrue: [^
		((datestamp allButFirst: (datestamp findDelimiters: ' ' startingAt: 1)) withoutLeadingBlanks) asDate]
! !


!Utilities class methodsFor: 'miscellaneous'!
awaitMouseUpIn: box repeating: doBlock ifSucceed: succBlock
	"The mouse has gone down in box; track the mouse, inverting the box while it's within, and if, on mouse up, the cursor was still within the box, execute succBlock.  While waiting for the mouse to come up, repeatedly execute doBlock. 5/11/96 sw
	6/10/96 sw: call new method that adds extra feature"

	^ self awaitMouseUpIn: box whileMouseDownDo: doBlock whileMouseDownInsideDo: [] ifSucceed: succBlock! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'JMM 3/31/2000 20:41'!
awaitMouseUpIn: box whileMouseDownDo: doBlock1 whileMouseDownInsideDo: doBlock2 ifSucceed: succBlock
	"The mouse has gone down in box; track the mouse, inverting the box while it's within, and if, on mouse up, the cursor was still within the box, execute succBlock.  While waiting for the mouse to come up, repeatedly execute doBlock1, and also, if the cursor is within the box, execute doBlock2.  6/10/96 sw
3/31/00 JMM added logic to stop multiple redraws"

	| p inside lightForm darkForm isLight |

	p _ Sensor cursorPoint.
	inside _ box insetBy: 1.
	isLight _ true.
	lightForm _ Form fromDisplay: inside.
	darkForm _ lightForm deepCopy reverse.
	[Sensor anyButtonPressed] whileTrue:
		[doBlock1 value.
		(box containsPoint: (p _ Sensor cursorPoint))
			ifTrue: [doBlock2 value.
					isLight ifTrue: 
						[isLight _ false.
						darkForm displayAt: inside origin]]
			ifFalse: [isLight ifFalse:
						[isLight _ true.
						lightForm displayAt: inside origin]]].
	(box containsPoint: p)
		ifTrue: [lightForm displayAt: inside origin.
				^ succBlock value]
! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'jm 5/25/2004 13:45'!
checkClassHierarchy
	"Perform some checks on the integrity of the class hierarchy. For example, make sure every class's subclass list contains only classes whose superclass is that class."
	"self checkClassHierarchy"

	| allClasses cList cl |
	allClasses _ IdentitySet withAll: (Smalltalk asArray select: [:obj | obj isBehavior]).
	self assert: [allClasses size = Metaclass allInstances size].

	cList _ Metaclass allInstances select: [:mc | mc soleInstance class ~~ mc].
	self assert: [cList isEmpty].
	cList _ Metaclass allInstances select: [:mc | (allClasses includes: mc soleInstance) not].
	self assert: [cList isEmpty].
	cList _ Metaclass allInstances select: [:mc | (Smalltalk includes: mc soleInstance) not].
	self assert: [cList isEmpty].
	cList _ Metaclass allInstances select: [:mc |
		cl _ mc soleInstance.
		cl superclass
			ifNil: [false]
			ifNotNil: [(cl superclass subclasses includes: cl) not]].
	self assert: [cList isEmpty].
	cList _ Metaclass allInstances select: [:mc |
		cl _ mc soleInstance.
		cl subclasses anySatisfy: [:subCl | subCl superclass ~~ cl]].
	self assert: [cList isEmpty].
	self inform: 'No class hierarchy problems found.'.! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'sw 10/5/1998 17:58'!
chooseFileWithSuffixFromList: aSuffixList withCaption: aCaption
	"Pop up a list of all files in the default directory which have a suffix in the list.  Return #none if there are none; return nil if the user backs out of the menu without making a choice."
	"Utilities chooseFileWithSuffixFromList: #('.gif' '.jpg')"
	| aList aName |
	aList _ OrderedCollection new.
	aSuffixList do:
		[:aSuffix | aList addAll: (FileDirectory default fileNamesMatching: '*', aSuffix)].
	^ aList size > 0
		ifTrue:
			[aName _ (SelectionMenu selections: aList) startUpWithCaption: aCaption.
			aName]
		ifFalse:
			[#none]! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'sw 5/4/2000 13:47'!
classFromPattern: pattern withCaption: aCaption
	"If there is a class whose name exactly given by pattern, return it.
	If there is only one class in the system whose name matches pattern, return it.
	Otherwise, put up a menu offering the names of all classes that match pattern, and return the class chosen, else nil if nothing chosen"

	| toMatch potentialClassNames classNames exactMatch index |
	pattern isEmpty ifTrue: [^ nil].
	Symbol hasInterned: pattern ifTrue:
		[:patternSymbol | Smalltalk at: patternSymbol ifPresent:
			[:maybeClass | (maybeClass isKindOf: Class) ifTrue: [^ maybeClass]]].

	toMatch _ (pattern copyWithout: $.) asLowercase.
	potentialClassNames _ Smalltalk classNames asOrderedCollection.
	classNames _ pattern last = $. 
		ifTrue: [potentialClassNames select:
					[:nm |  nm asLowercase = toMatch]]
		ifFalse: [potentialClassNames select: 
					[:n | n includesSubstring: toMatch caseSensitive: false]].
	classNames isEmpty ifTrue: [^ nil].
	exactMatch _ classNames detect: [:each | each asLowercase = toMatch] ifNone: [nil].

	index _ classNames size = 1
		ifTrue:	[1]
		ifFalse:	[exactMatch
			ifNil: [(PopUpMenu labelArray: classNames lines: #()) startUpWithCaption: aCaption]
			ifNotNil: [classNames addFirst: exactMatch.
				(PopUpMenu labelArray: classNames lines: #(1)) startUpWithCaption: aCaption]].
	index = 0 ifTrue: [^ nil].
	^ Smalltalk at: (classNames at: index) asSymbol

"
	Utilities classFromPattern: 'CharRecog'
	Utilities classFromPattern: 'rRecog'
	Utilities classFromPattern: 'znak'
	Utilities classFromPattern: 'orph'
"
! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'jm 11/25/1998 22:31'!
convertCRtoLF: fileName
	"Convert the given file to LF line endings. Put the result in a file with the extention '.lf'"

	| in out c justPutCR |
	in _ (FileStream oldFileNamed: fileName) binary.
	out _  (FileStream newFileNamed: fileName, '.lf') binary.
	justPutCR _ false.
	[in atEnd] whileFalse: [
		c _ in next.
		c = 10
			ifTrue: [
				out nextPut: 13.
				justPutCR _ true]
			ifFalse: [
				(justPutCR and: [c = 10]) ifFalse: [out nextPut: c].
				justPutCR _ false]].
	in close.
	out close.
! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'sma 4/30/2000 10:17'!
emergencyCollapse
	Smalltalk isMorphic ifTrue: [^ self].
	ScheduledControllers screenController emergencyCollapse! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'jm 4/4/2005 23:19'!
form: partName from: directory
	"Answer the form with the given name in the given directory or nil if there isn't one." 

	| f |
	directory fileNames do: [:fn |
		((partName, '.*') match: fn) ifTrue: [
			Cursor read show.
			f _ [Form fromFileNamed: (directory fullNameFor: fn)] ifError: [nil].
			Cursor normal show.
			f ifNotNil: [^ f]]].
	^ nil
! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'jm 5/29/2003 19:10'!
inspectGlobals
	"Utilities  inspectGlobals"

	| dict gNames |
	dict _ IdentityDictionary new.
	gNames _ (Smalltalk keys select: [:n | (Smalltalk at: n) isBehavior not]) asArray sort.
	gNames do: [:n | dict add: (Smalltalk associationAt: n)].
	dict inspectWithLabel: 'The Globals'.
! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'sw 7/22/1998 17:12'!
instanceComparisonsBetween: fileName1 and: fileName2
	"For differential results, run printSpaceAnalysis twice with different fileNames,
	then run this method...
		Smalltalk printSpaceAnalysis: 0 on: 'STspace.text1'.
			--- do something that uses space here ---
		Smalltalk printSpaceAnalysis: 0 on: 'STspace.text2'.
		Smalltalk instanceComparisonsBetween: 'STspace.text1' and 'STspace.text2'"

	| instCountDict report f aString items className newInstCount oldInstCount newSpace oldPair oldSpace |
	instCountDict _ Dictionary new.
	report _ ReadWriteStream on: ''.
	f _ FileStream oldFileNamed: fileName1.
	[f atEnd] whileFalse:
		[aString _ f upTo: Character cr.
		items _ aString findTokens: ' '.
		(items size == 4 or: [items size == 5]) ifTrue:
			[instCountDict at: items first put: (Array with: items third asNumber with: items fourth asNumber)]].
	f close.

	f _ FileStream oldFileNamed: fileName2.
	[f atEnd] whileFalse:
		[aString _ f upTo: Character cr.
		items _ aString findTokens: ' '.
		(items size == 4 or: [items size == 5]) ifTrue:
			[className _ items first.
			newInstCount _ items third asNumber.
			newSpace _ items fourth asNumber.
			oldPair _ instCountDict at: className ifAbsent: [nil].
			oldInstCount _ oldPair ifNil: [0] ifNotNil: [oldPair first].
			oldSpace _ oldPair ifNil: [0] ifNotNil: [oldPair second].
			oldInstCount ~= newInstCount ifTrue:
				[report nextPutAll: (newInstCount - oldInstCount) printString; tab; nextPutAll: (newSpace - oldSpace) printString; tab; nextPutAll: className asString; cr]]].
	f close.

	(StringHolder new contents: report contents)
		openLabel: 'Instance count differentials between ', fileName1, ' and ', fileName2! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'sw 1/12/1999 12:24'!
methodDiffFor: aString class: aClass selector: aSelector
	^ (aClass includesSelector: aSelector)
		ifFalse:
			[aString copy]
		ifTrue:
			[TextDiffBuilder buildDisplayPatchFrom: (aClass sourceCodeAt: aSelector) to: aString]! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'tk 4/21/1998 07:59'!
methodHierarchyBrowserForClass: aClass selector: sel
	"Create and schedule a message set browser on all implementors of the 
	currently selected message selector. Do nothing if no message is selected."
	| list tab stab aClassNonMeta isMeta theClassOrMeta |

	aClass ifNil: [^ self].
	sel ifNil: [^ self].
	aClassNonMeta _ aClass theNonMetaClass.
	isMeta _ aClassNonMeta ~~ aClass.
	list _ OrderedCollection new.
	tab _ ''.
	aClass allSuperclasses reverseDo:
		[:cl |
		(cl includesSelector: sel) ifTrue:
			[list addLast: tab , cl name, ' ', sel].
		tab _ tab , '  '].
	aClassNonMeta allSubclassesWithLevelDo:
		[:cl :level |
		theClassOrMeta _ isMeta ifTrue: [cl class] ifFalse: [cl].
		(theClassOrMeta includesSelector: sel) ifTrue:
			[stab _ ''.  1 to: level do: [:i | stab _ stab , '  '].
			list addLast: tab , stab , theClassOrMeta name, ' ', sel]]
	 	startingLevel: 0.
	Smalltalk browseMessageList: list
		name: 'Inheritance of ' , sel

"Utilities methodHierarchyBrowserForClass: ParagraphEditor selector: #isControlActive"! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'jm 5/3/1998 20:12'!
openScratchWorkspaceLabeled: labelString contents: initialContents
	"Open a scratch text view with the given label on the given string. A scratch text view won't warn you about unsaved changes when you close it."
	"Utilities openScratchWorkspaceLabeled: 'Scratch' contents: 'Hello. world!!'"

	| model topView stringView |
	model _ StringHolder new contents: initialContents.
	topView _ StandardSystemView new.
	topView
		model: model;
		label: labelString;
		minimumSize: 180@120.
	topView borderWidth: 1.
	stringView _ PluggableTextView on: model 
		text: #contents
		accept: nil
		readSelection: #contentsSelection
		menu: #codePaneMenu:shifted:.
	stringView
		askBeforeDiscardingEdits: false;
		window: (0@0 extent: 180@120).
	topView addSubView: stringView.
	topView controller open.
! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'sw 10/20/1999 13:48'!
setClassAndSelectorFrom: messageIDString in: csBlock
	"Decode strings of the form <className> [class] <selectorName>.   If <className> does not exist as a class, use nil for the class in the block"

	| aStream aClass maybeClass sel |
	aStream _ ReadStream on: messageIDString.
	aClass _ Smalltalk at: (aStream upTo: $ ) asSymbol ifAbsent: [nil].
	maybeClass _ aStream upTo: $ .
	sel _ aStream upTo: $ .
	((maybeClass = 'class') & (sel size ~= 0))
		ifTrue:
			[aClass
				ifNil:
					[csBlock value: nil value: sel asSymbol]
				ifNotNil:
					[csBlock value: aClass class value: sel asSymbol]]
		ifFalse:
			[csBlock value: aClass value: maybeClass asSymbol]


"
Utilities setClassAndSelectorFrom: 'Utilities class oppositeModeTo:' in: [:aClass :aSelector | Transcript cr; show: 'Class = ', aClass name printString, ' selector = ', aSelector printString].

Utilities setClassAndSelectorFrom: 'MessageSet setClassAndSelectorIn:' in: [:aClass :aSelector | Transcript cr; show: 'Class = ', aClass name printString, ' selector = ', aSelector printString].
"
! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'tk 4/7/98 14:00'!
spawnHierarchyForClass: aClass selector: aSelector
	"Create and schedule a new class hierarchy browser on the requested class/selector."
	| newBrowser |
	(aClass == nil)  ifTrue: [^ self].
	(newBrowser _ Browser new) setClass: aClass selector: aSelector.
	newBrowser spawnHierarchy.

"Utilities spawnHierarchyForClass: SmallInteger selector: #hash"! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'jm 4/20/1999 11:29'!
timeStampForMethod: method
	"Answer the authoring time-stamp for the given method, retrieved from the sources or changes file. Answer the empty string if no time stamp is available."

	| position file preamble stamp tokens tokenCount |
	method fileIndex == 0 ifTrue: [^ String new].  "no source pointer for this method"
	position _ method filePosition.
	file _ SourceFiles at: method fileIndex.
	file ifNil: [^ String new].  "sources file not available"
	file _ file readOnlyCopy.
	file position: (0 max: position - 150).  "Skip back to before the preamble"
		[file position < (position - 1)]  "then pick it up from the front"
			whileTrue: [preamble _ file nextChunk].
		stamp _ String new.
		tokens _ (preamble findString: 'methodsFor:' startingAt: 1) > 0
			ifTrue: [Scanner new scanTokens: preamble]
			ifFalse: [Array new  "ie cant be back ref"].
		(((tokenCount _ tokens size) between: 7 and: 8) and: [(tokens at: tokenCount - 5) = #methodsFor:])
			ifTrue:
				[(tokens at: tokenCount - 3) = #stamp:
					ifTrue: ["New format gives change stamp and unified prior pointer"
							stamp _ tokens at: tokenCount - 2]].
		((tokenCount between: 5 and: 6) and: [(tokens at: tokenCount - 3) = #methodsFor:])
			ifTrue:
				[(tokens at: tokenCount  - 1) = #stamp:
					ifTrue: ["New format gives change stamp and unified prior pointer"
						stamp _ tokens at: tokenCount]].
	file close.
	^ stamp! !

!Utilities class methodsFor: 'miscellaneous' stamp: 'jm 5/12/2004 21:25'!
vmStatisticsReportString
	"StringHolderView open: (StringHolder new contents:
		Utilities vmStatisticsReportString) label: 'VM Statistics'"

	| params oldSpaceEnd youngSpaceEnd memoryEnd fullGCs fullGCTime incrGCs incrGCTime tenureCount upTime |
	params _ Smalltalk getVMParameters.
	oldSpaceEnd			_ params at: 1.
	youngSpaceEnd		_ params at: 2.
	memoryEnd			_ params at: 3.
	fullGCs				_ params at: 7.
	fullGCTime			_ params at: 8.
	incrGCs				_ params at: 9.
	incrGCTime			_ params at: 10.
	tenureCount			_ params at: 11.
	upTime _ Time millisecondClockValue.

	^ String streamContents: [:str |
		str	nextPutAll: 'uptime			';
			print: (upTime / 1000 / 60 // 60); nextPut: $h;
			print: (upTime / 1000 / 60 \\ 60) asInteger; nextPut: $m;
			print: (upTime / 1000 \\ 60) asInteger; nextPut: $s; cr; cr.

		str	nextPutAll: 'memory			';
			nextPutAll: memoryEnd asStringWithCommas; nextPutAll: ' bytes'; cr.
		str	nextPutAll: '	free		';
			nextPutAll: (memoryEnd - youngSpaceEnd) asStringWithCommas; nextPutAll: ' bytes (';
			print: ((memoryEnd - youngSpaceEnd / memoryEnd * 100) roundTo: 0.1); nextPutAll: '%)'; cr.
		str	nextPutAll: '	used		';
			nextPutAll: youngSpaceEnd asStringWithCommas; nextPutAll: ' bytes (';
			print: ((youngSpaceEnd / memoryEnd * 100) roundTo: 0.1); nextPutAll: '%)'; cr.
		str	nextPutAll:	'		old			';
			nextPutAll: oldSpaceEnd asStringWithCommas; nextPutAll: ' bytes (';
			print: ((oldSpaceEnd / youngSpaceEnd * 100) roundTo: 0.1); nextPutAll: '% of used)'; cr.
		str	nextPutAll: '		young		';
			nextPutAll: (youngSpaceEnd - oldSpaceEnd) asStringWithCommas; nextPutAll: ' bytes (';
			print: ((youngSpaceEnd - oldSpaceEnd / youngSpaceEnd * 100) roundTo: 0.1); nextPutAll: '% of used)'; cr; cr.

		str	nextPutAll: 'GCs				';
			nextPutAll: (fullGCs + incrGCs) asStringWithCommas;
			nextPutAll: ' ('; print: ((upTime / (fullGCs + incrGCs)) roundTo: 1); nextPutAll: 'ms between GCs)'; cr.
		str	nextPutAll: '	full			';
			print: fullGCs; nextPutAll: ' in '; nextPutAll: fullGCTime asStringWithCommas; nextPutAll: 'ms (';
			print: ((fullGCTime / upTime * 100) roundTo: 1.0);
			nextPutAll: '% uptime)'.
		fullGCs = 0 ifFalse:
			[str	nextPutAll: ', avg '; print: ((fullGCTime / fullGCs) roundTo: 1.0); nextPutAll: 'ms'].
		str	cr.
		str	nextPutAll: '	incr		';
			print: incrGCs; nextPutAll: ' in '; nextPutAll: incrGCTime asStringWithCommas; nextPutAll: 'ms (';
			print: ((incrGCTime / upTime * 100) roundTo: 1.0);
			nextPutAll: '% uptime), avg '; print: ((incrGCTime / incrGCs) roundTo: 1.0); nextPutAll: 'ms'; cr.
		str	nextPutAll: '	tenures		';
			nextPutAll: tenureCount asStringWithCommas.
		tenureCount = 0 ifFalse:
			[str nextPutAll: ' (avg '; print: (incrGCs / tenureCount) asInteger; nextPutAll: ' GCs/tenure)'].
		str	cr].
! !
