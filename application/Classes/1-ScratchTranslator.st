Object subclass: #ScratchTranslator
	instanceVariableNames: ''
	classVariableNames: 'ColonSuffix EllipsesSuffix HeaderString ISODict IsRTL IsRTLMath Language MIDITranslationSet RenderAntiAliasing RenderCenterOffsetCache RenderFont RenderHintString RenderPlugin RenderScale RenderSuppressBold RenderVerticalTrimCache RenderWithSqueak TranslationDict UITranslationSet '
	poolDictionaries: ''
	category: 'Scratch-Translation'!
!ScratchTranslator commentStamp: '<historical>' prior: 0!
I manage language translations for Scratch. All of my code in in class methods.
!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScratchTranslator class
	instanceVariableNames: ''!

!ScratchTranslator class methodsFor: 'class initialization' stamp: 'jm 6/9/2008 14:50'!
initialize
	"ScratchTranslator initialize"

	TranslationDict _ Dictionary new.
	ISODict _ Dictionary new.
	MIDITranslationSet _ Set new.
	UITranslationSet _ Set new.

	RenderAntiAliasing _ false.
	HeaderString _ ''.
	RenderPlugin _ nil.
	self setRenderingHints.

	ColonSuffix _ ':' asUTF8, (UTF32 with: 16r200F) asUTF8.
	EllipsesSuffix _ '...' asUTF8, (UTF32 with: 16r200F) asUTF8.
! !


!ScratchTranslator class methodsFor: 'startup' stamp: 'jm 10/29/2008 13:22'!
shutDown
	"Clear the rendering plugin."

	RenderPlugin _ nil.
! !

!ScratchTranslator class methodsFor: 'startup' stamp: 'jm 6/27/2008 21:23'!
startUp
	"self startup"

	self detectRenderPlugin.
! !


!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 10/14/2007 17:22'!
addMIDITranslation: aString

	MIDITranslationSet add: aString.
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 6/9/2008 09:36'!
addSensorTranslations
	"Add translations for the sensor names such as 'resistance-A' and 'A connected' from the translations of the root words if they exist."

	| root prefix postfix |
	root _ TranslationDict at: 'connected' ifAbsent: [nil].
	root ifNotNil: [
		#(A B C D) do: [:ch |
			prefix _ ch asString, ' '.
			root isUnicode ifTrue: [prefix _ UTF8 withAll: prefix].
			TranslationDict at: (prefix, 'connected') put: (prefix, root)]].

	root _ TranslationDict at: 'resistance' ifAbsent: [nil].
	root ifNotNil: [
		#(A B C D) do: [:ch |
			postfix _ '-', ch asString.
			TranslationDict at: ('resistance', postfix) put: (root, postfix)]].
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 9/21/2007 16:00'!
addUITranslation: aString

	UITranslationSet add: aString.
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 9/20/2007 18:36'!
checkAllTranslations
	"Check all the translation dictionaries."
	"self checkAllTranslations"

	| untranslated |
	self languageNames do: [:lang |
		self setLanguage: lang.
		untranslated _ self checkTranslationDict.
		untranslated size > 0 ifTrue: [self halt: lang, ' missing ', untranslated size printString]].
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 9/20/2007 18:37'!
checkTranslationDict
	"Do some sanity check on the current translation dictionary."

	| categories allSpecs mathOps |
	TranslationDict size = 0 ifTrue: [^ #()].  "English"

	categories _ #(motion control looks pen numbers	sound sensing variables).
	categories do: [:cat | self assert: [TranslationDict includesKey: cat asString]].

	"make sure all translations have the same number arguments"
	TranslationDict associationsDo: [:assoc |
		self assert: [(self parameterSpecs: assoc key) = (self parameterSpecs: assoc value)]].

	"makes sure there is a translation for every block in every category (except variables)"
	allSpecs _ Set new: 100.
	(ScratchSpriteMorph blockSpecs, ScratchStageMorph blockSpecs) do: [:spec |
		(spec isKindOf: Array) ifTrue: [allSpecs add: spec]].
	allSpecs add: #('else').

	"remove obsolete specs and math operators"
	ScratchSpriteMorph obsoleteBlockSpecs do: [:spec |  "remove obsolete block specs"
		allSpecs remove: spec ifAbsent: []].
	mathOps _ ('+-*/<=>' asArray collect: [:ch | '%n ', ch asString, ' %n']) asSet.
	allSpecs _ allSpecs select: [:spec | (mathOps includes: spec first) not].

	allSpecs _ allSpecs asArray sort: [:s1 :s2 | s1 first < s2 first].
	^ allSpecs select: [:spec | (TranslationDict includesKey: spec first) not]
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 4/25/2008 15:57'!
colonSuffix
	"Answer a colon suffix. If the current language is RTL, then include the Unicode RTL mark after the colon."

	^ self isRTL ifTrue: [ColonSuffix] ifFalse: [':']
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 10/27/2007 09:49'!
currentLanguage

	Language ifNil: [Language _ 'en'].
	^ Language
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 5/15/2009 14:17'!
doNotTranslate

	^ #(
	'!!'
	'0'
	'1'
	'2'
	'3'
	'4'
	'5'
	'6'
	'7'
	'8'
	'9'
	'10'
	'a'
	'b'
	'c'
	'd'
	'e'
	'f'
	'g'
	'h'
	'i'
	'j'
	'k'
	'l'
	'm'
	'n'
	'o'
	'p'
	'q'
	'r'
	's'
	't'
	'u'
	'v'
	'w'
	'x'
	'y'
	'z'
	'A'
	'B'
	'%n * %n'
	'%n + %n'
	'%n - %n'
	'%n / %n'
	'%n < %n'
	'%n = %n'
	'%n > %n'
	'%s > %s'
	'%s = %s'
	'%s < %s'
	'*'
	'+'
	'-'
	'/'
	'<'
	'='
	'>'
	'sin'
	'cos'
	'tan'
	'asin'
	'acos'
	'atan'
	'ln'
	'log'
	'e ^'
	'10 ^'
	'enter'
	'motor'
	'Scratch'
	'Sprite1'
	'['
	']'
	'set translation formatting...'
	'enable remote access...'
	'Host Mesh'
	'Join Mesh'
	're-record')
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 4/25/2008 15:55'!
ellipsesSuffix
	"Answer an ellipses suffix (three periods). If the current language is RTL, then include the Unicode RTL mark after the colon."

	^ self isRTL ifTrue: [EllipsesSuffix] ifFalse: ['...']
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 10/4/2007 14:20'!
extractQuotedStringFrom: aString
	"Extract the contents of a quoted string from a translation file line. If the line contains no double-quote characters, the string after the first space character is returned or, if there is no space character, the entire line. Only two escape sequences are currently recognized: newline and double-quote."

	| i s result ch |
	i _ aString indexOf: $".
	i = 0 ifTrue: [aString indexOf: String space].
	s _ ReadStream on: (aString copyFrom: i + 1 to: aString size).

	result _ WriteStream on: String new.
	[s atEnd] whileFalse: [
		ch _ s next.
		ch = $" ifTrue: [^ result contents].
		ch = $\
			ifTrue: [
				ch _ s next.
				ch = $n ifTrue: [result cr].
				ch = $" ifTrue: [result nextPut: $"]]
			ifFalse: [result nextPut: ch]].
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 7/9/2008 16:12'!
formattingHeaderFields

	^ #(
		'Language-Name'
		'Language-Direction'
		'Font-Scale'
		'Suppress-Bold'
		'Win-Font'
		'Mac-Font'
		'Linux-Font')
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 8/8/2008 20:56'!
formattingSectionForPOT

	| s |
	s _
'# Language name as you''d like it to appear in the Languages menu
# (Required)
msgid "Language-Name"
msgstr ""

# Directionality of language
# LTR = Left to Right
# RTL = Right to Left
msgid "Language-Direction"
msgstr ""

# Scale to apply to font size (2 for twice as large)
# Use this if the font is too small for legibility on the Scratch interface
msgid "Font-Scale"
msgstr ""

# Set to ''true'' or ''false''
# Use this if you do not want any of the text to be bolded, for legibility
msgid "Suppress-Bold"
msgstr ""

# Font to use on a Windows system
msgid "Win-Font"
msgstr ""

# Font to use on a Mac system
msgid "Mac-Font"
msgstr ""

# Font to use on a Linux system
msgid "Linux-Font"
msgstr ""

'.

	s _ s copyReplaceTokens: String cr with: String crlf.

	^ s.
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 6/2/2008 20:48'!
importLanguagesList
	"Import the list of languages and language codes translated for Scratch by file names from 'Help/Translations'"

	| dir code lang |
	ISODict _ Dictionary new.
	ISODict at: 'en' put: 'English'.
	dir _ self translationDir.
	dir fileNames do: [:f |
		(f endsWith: '.po') ifTrue: [
			code _ f copyFrom: 1 to: (f size - 3).
			lang _ self extractLanguageFromFileNamed: (dir fullNameFor: f).
			lang ifNil: [lang _ code].
			self canRenderUnicode
				ifTrue: [self insertISOCode: code forLanguage: lang]
				ifFalse: [self insertISOCode: code forLanguage: code]]].
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 10/14/2007 14:06'!
insertISOCode: code forLanguage: lang

	ISODict at: code put: lang.
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 7/9/2008 18:21'!
isRTLMath
	"Returns true if the header 'Language-Direction' is set to 'RTL-math'"

	^ IsRTLMath
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 6/1/2008 18:03'!
isoCodeForName: aString

	(ISODict includes: aString)
		ifFalse:[^ aString]
		ifTrue:[^ ISODict keyAtValue: aString].
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 10/14/2007 14:08'!
isoDict

	^ ISODict
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 9/20/2007 18:44'!
labelPartsFor: aString
	"Answer a collection label strings for the translation of given block label. Currently handles one or two-part labels. In a two-part label, the label is split at the field name begginning with a percent sign. For example, 'when %s clicked' would yield the two label parts 'when' and 'clicked'."

	| s i p1 p2 |
	s _ ScratchTranslator translationFor: aString.
	i _ s indexOf: $% ifAbsent: [^ Array with: s with: ''].
	p1 _ (s copyFrom: 1 to: i - 1) withBlanksTrimmed.
	p2 _ (s copyFrom: i + 2 to: s size) withBlanksTrimmed.
	^ Array with: p1 with: p2
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 10/24/2007 16:10'!
languageNames
	"Answer a list of language names for the languages menu. These are generally in the native language (e.g. 'Espa–ol') and must match the strings in the setLanguage: method."

	self importLanguagesList.
	^ ISODict values sort
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 10/14/2007 17:22'!
midiTranslationSet

	^ MIDITranslationSet
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 9/20/2007 18:41'!
parameterSpecs: aString
	"Answer the sequence of parameter specs (e.g. %n) for the given block specification. Used for checking translations."
	"self parameterSpecs: 'this %b is %s a %c test %n%'"
	"self parameterSpecs: 'this %b'"
	"self parameterSpecs: 'this %'"
	"self parameterSpecs: 'this'"

	| result i |
	result _ OrderedCollection new.
	i _ 1.
	[i < aString size] whileTrue: [
		i _ aString indexOf: $% startingAt: i.
		i = 0 ifTrue: [i _ aString size].  "% not found"
		i < aString size ifTrue: [
			result addLast: (aString copyFrom: i to: i + 1)].
		i _ i + 2].

	^ result asArray
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 5/12/2008 17:08'!
resetMIDITranslationSet

	MIDITranslationSet _ Set new.
	#('Accordion' 'Acoustic Bass' 'Acoustic Bass Drum' 'Acoustic Grand' 'Acoustic Snare' 'Agogo' 'Alto Sax' 'Applause' 'Bagpipe' 'Banjo' 'Baritone Sax' 'Bass Drum 1' 'Bassoon' 'Bird Tweet' 'Blown Bottle' 'Brass Section' 'Breath Noise' 'Bright Acoustic' 'Cabasa' 'Celesta' 'Cello' 'Chinese Cymbal' 'Choir Aahs' 'Church Organ' 'Clarinet' 'Claves' 'Clavinet' 'Closed Hi-Hat' 'Contrabass' 'Cowbell' 'Crash Cymbal 1' 'Crash Cymbal 2' 'Distortion Guitar' 'Drawbar Organ' 'Dulcimer' 'Electric Bass (finger)' 'Electric Bass (pick)' 'Electric Clean Guitar' 'Electric Grand' 'Electric Jazz Guitar' 'Electric Muted Guitar' 'Electric Piano 1' 'Electric Piano 2' 'Electric Snare' 'English Horn' 'FX 1 (rain)' 'FX 2 (soundtrack)' 'FX 3 (crystal)' 'FX 4 (atmosphere)' 'FX 5 (brightness)' 'FX 6 (goblins)' 'FX 7 (echoes)' 'FX 8 (sci-fi)' 'Fiddle' 'Flute' 'French Horn' 'Fretless Bass' 'Glockenspiel' 'Guitar Fret Noise' 'Guitar Harmonics' 'Gunshot' 'Hand Clap' 'Harmonica' 'Harpsichord' 'Helicopter' 'Hi Bongo' 'Hi Wood Block' 'Hi-Mid Tom' 'High Agogo' 'High Floor Tom' 'High Timbale' 'High Tom' 'Honky-Tonk' 'Kalimba' 'Koto' 'Lead 1 (square)' 'Lead 2 (sawtooth)' 'Lead 3 (calliope)' 'Lead 4 (chiff)' 'Lead 5 (charang)' 'Lead 6 (voice)' 'Lead 7 (fifths)' 'Lead 8 (bass+lead)' 'Long Guiro' 'Long Whistle' 'Low Agogo' 'Low Bongo' 'Low Conga' 'Low Floor Tom' 'Low Timbale' 'Low Tom' 'Low Wood Block' 'Low-Mid Tom' 'Maracas' 'Marimba' 'Melodic Tom' 'Music Box' 'Mute Cuica' 'Mute Hi Conga' 'Mute Triangle' 'Muted Trumpet' 'Nylon String Guitar' 'Oboe' 'Ocarina' 'Open Cuica' 'Open Hi Conga' 'Open Hi-Hat' 'Open Triangle' 'Orchestra Hit' 'Orchestral Strings' 'Overdriven Guitar' 'Pad 1 (new age)' 'Pad 2 (warm)' 'Pad 3 (polysynth)' 'Pad 4 (choir)' 'Pad 5 (bowed)' 'Pad 6 (metallic)' 'Pad 7 (halo)' 'Pad 8 (sweep)' 'Pan Flute' 'Pedal Hi-Hat' 'Percussive Organ' 'Piccolo' 'Pizzicato Strings' 'Recorder' 'Reed Organ' 'Reverse Cymbal' 'Ride Bell' 'Ride Cymbal 1' 'Ride Cymbal 2' 'Rock Organ' 'Seashore' 'Shakuhachi' 'Shamisen' 'Shanai' 'Short Guiro' 'Short Whistle' 'Side Stick' 'Sitar' 'Slap Bass 1' 'Slap Bass 2' 'Soprano Sax' 'Splash Cymbal' 'Steel Drums' 'Steel String Guitar' 'String Ensemble 1' 'String Ensemble 2' 'Synth Bass 1' 'Synth Bass 2' 'Synth Drum' 'Synth Voice' 'SynthBrass 1' 'SynthBrass 2' 'SynthStrings 1' 'SynthStrings 2' 'Taiko Drum' 'Tambourine' 'Tango Accordion' 'Telephone Ring' 'Tenor Sax' 'Timpani' 'Tinkle Bell' 'Tremolo Strings' 'Trombone' 'Trumpet' 'Tuba' 'Tubular Bells' 'Vibraphone' 'Vibraslap' 'Viola' 'Violin' 'Voice Oohs' 'Whistle' 'Woodblock' 'Xylophone') do:[:t |
		self addMIDITranslation: t].

	! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'JM 11/22/2011 15:23'!
resetUITranslationSet

	UITranslationSet _ Set new.
	#('Normal' 'new' 'New' 't' 'New sound:' 'New sprite:' 'No' 'New costume:' 'New Filename:' 'New background:' 'No motion blocks' 'OK' 'New Sprite' '3' 'No variables.' 'no scripts' 'm' 'normal readout' 'No serial ports found' 'No MIDI ports currently available.' 'Open' 'Off' 'f' 'Open Project' 'On' 'Preparing project...' 'or' 'Open a Scratch project' 'only face left-right' '10 ^' 'B' '10' 'play' 'Pictures' 'Password:' 'Project Notes' 'Project notes' 'Paint' 'pop' 'Project uploaded.' 'u' 'Project name' 'Please enter a number' 'Paint Editor' 'Projects' 'Paintbrush' 'pixelate' 'Project author:' 'Paint new sprite' 'Percent? (100 gives original size)' '4' 'n' 'abs' 'atan' 'Position the cross-hair to set the rotation center' 'asin' 'Quit' 'Quit Scratch' 'About Scratch' 'and' '-' 'acos' 'all' 'any' 'Brush size: ' 'g' '1 script' 'add comment' 'Animation' 'Art' 'add comment here' 'About this project:' 'Redo' 'right' 'resistance' 'backgrounds' 'Backgrounds' 'button pressed' 'Reference Guide' 'button' 'save picture of stage...' 'recording' 'Save As' 'record' 'Record' 'right arrow' '<' 'background' 'brightness' 'Remove viewer from stage' 'v' 're-record' 'set translation formatting...' 'reverse' 'Rotate clock-wise' 'Rotation degrees?' 'resize this sprite' 'rotate this sprite' 'Remote sensor connections enabled' 'Reading' 'Rotate counter-clock-wise' '5' 'Clear' 'o' 'space' 'Sounds' 'slider' 'cancel' 'sin' 'Sprite1' 'Sprites' 'connected' 'Canvas' 'Could not read' 'stop' 'Choose a folder' 'color' 'Sound Recorder' 'cos' 'Save failed' 'Slider range:' 'costumes' 'sqrt' 'set slider min and max' 'Costumes' 'show ScratchBoard watcher' 'Cancel' 'Single-step speed?' 'costume' 'Computer' 'Sounds compressed' 'Set language' 'Camera' 'Clear canvas' 'Compress Sounds' 'select serial/USB port' 'Sprite' 'e ^' 'close port' 'Close dialog?' 'Compress Images' 'Rectangle tool (draw outlined or filled rectangle or square)' 'Save this project' 'Share this project' 'Scratch' 'Save the current project' 'Share' 'Switch to full stage' 'Show Motor Blocks' 'Could not write file' 'Switch to small stage' 'Stage selected:' 'Switch to presentation mode' 'a' 'Copy' 'tan' 'Set costume center' 'Save changes before quitting?' 'Shrink' 'Story' 'Save Project' 'Close paint editor?' 'thing' 'Support Site' 'Close sound recorder?' 'Select tool (move, modify, or delete selection)' 'Set Single Stepping' 'Start Single Stepping' 'Save the current project?' 'Simulation' 'Set rotation center' 'Create an empty project' 'Share This Project Online' 'Save' 'Stop everything' 'Scripts' 'Close and continue' 'Switch colors' 'Turbo speed' 'h' 'Stamp tool (select area, then stamp copies of it)' 'Done' 'can rotate' 'Tags:' 'Delete a list' 'Don''t Save' 'down arrow' 'Shrink sprite' 'clean up' 'distance' 'disable remote sensor connections' 'Save Stage Shot' 'Save Scripts Snapshot' 'this way' 'delete' 'Delete' 'drag to rotate' 'down' 'Text tool (edit text layer)' 'duplicate' 'Duplicate' 'Documents' 'Delete a variable' 'drag to resize' 'don''t rotate' 'Desktop' 'that way' 'p' 'Delete this background' 'Export failed' 'up' 'That variable name is already in use' 'tilt' 'Delete this sprite' 'enter' 'Eraser' 'Save a copy of the current project' 'Exit presentation mode' 'Export Costume' 'Undelete' 'Examples' 'Could not read project; file may be damaged' 'Updating thumbnails' 'Exit presentation' 'Export Sprite' 'Create account' 'Choose new sprite from file' 'Compress sounds and images' 'Eraser size' 'export this sprite' '/' 'Delete this costume' 'Connecting to ' '=' 'Upload succeeded!!' 'true' 'up arrow' 'enable remote sensor connections' 'export' 'Extras menu' 'Export Sound' 'Eyedropper tool (select a color)' 'Enter presentation mode' 'save picture of scripts' 'Upload to Scratch Server' 'Start green flag scripts' 'Export Background' 'Data sent. Waiting for response...' 'edge' '6' 'Failed:' 'Edit' 'Ellipse tool (draw outlined or filled ellipse or circle)' 'draggable on website?' 'Stop Single Stepping' 'File' 'Delete this sound' 'w' 'Variable name?' 'View on stage' 'For all sprites' 'b' 'enable remote access...' 'false' 'first' 'Undo' 'Flip vertically' 'File not found' 'Flip horizontally' 'i' 'turn into new sprite' 'fisheye' 'For this sprite only' 'Sound quality:' 'The file name already exists. Overwrite existing file?' 'Uploading' 'Error!!' 'export this costume' 'Flash blocks (fast)' 'export this sound' 'Flash blocks (slow)' '!!' '>' 'x' 'Hmm...' 'Fill tool (fill areas with color or gradient)' 'Game' 'Grow' 'Getting Started' 'world' '7' 'whirl' 'ghost' 'What''s your name?' 'q' 'Get the last thing deleted' 'Grow sprite' 'Write Multiple Project Summaries' 'Get surprise sprite' 'Write Project Summary' 'Go To Scratch Website' 'grab screen region for new costume' '0' 'j' 'grab screen region for new sprite' 'help' 'Home' 'Help' 'Help Page' 'Hello!!' 'hello ' 'Help Screens' 'Hide Motor Blocks' 'Host Mesh' 'c' '(empty)' 'High (biggest)' 'Yes' 'y' 'JPEG Quality (10-100)?' 'Import Project' 'import project' 'Import Image' 'Images compressed' 'import' 'Import' 'Import Sound' 'Import Costume' 'Your project is now online at' 'Import Background' '8' 'Incompatible Scratch file format' 'Import List' 'r' 'Your Scratch website login name:' 'Import an image on top of your current canvas' 'Is the folder read-only?' '1' 'k' 'Zoom in' 'Join Mesh' #[ 'Zoom out' '*' 'd' 'kbytes' 'z' '9' 's' 'left' 'light' 'Language' 'ln' 'List name?' 'Low' 'log' '2' 'last' 'l' 'left arrow' 'length' 'large readout' 'Lowest (smallest)' 'Line tool (draw lines)' '+' 'e' 'Music' 'mosaic' 'Message name:' 'meow' 'mod' #] 'Min:' 'more' 'mouse-pointer' 'Move' 'Make a variable' 'Max:' 'More tags:' 'Make a list' 'My Projects' 'mouse x:' 'mouse y:' 'A' 'New file name?') do: [:t |
		self addUITranslation: t].
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 6/9/2008 14:55'!
setLanguage: aString
	"Set the current language. If the language is not supported, use English (i.e. an empty translation dictionary)."

	| dict |
	"default to English"
	Language _ 'en'.
	TranslationDict _ Dictionary new.
	HeaderString _ ''.
	self setRenderingHints.  "clear rendering hints"
	ScratchTranslator detectRenderPlugin.

	aString = 'en' ifTrue: [^ self].

	dict _ self importTranslation: aString, '.po'.
	dict ifNotNil: [
		Language _ aString.
		TranslationDict _ dict.
		HeaderString _ dict at: '' ifAbsent: [''].
		dict removeKey: '' ifAbsent: [].
		self setRenderingHints.
		RenderWithSqueak ifTrue: [self convertToMacRoman].
		self isRTL ifTrue: [self fixAmbigousRTLPunctuation].
		self addSensorTranslations].
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'ee 11/21/2007 15:13'!
translationDict

	^ TranslationDict
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 7/11/2008 14:36'!
translationFor: englishString
	"Return the translation of the given (English) string for the current language. If there is no entry for the given string, return the original string."

	| s |
	s _ TranslationDict at: englishString ifAbsent: [englishString].
	s size = 0 ifTrue: [s _ englishString].
	RenderWithSqueak
		ifTrue: [s isUnicode ifTrue: [s _ s asMacRoman]]
		ifFalse: [s _ s asUTF8].
	^ s

! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 10/28/2007 16:29'!
uiTranslationSet

	#('' '?'), ScriptableScratchMorph blockSpecsForTranslation do: [:e |
		UITranslationSet remove: e ifAbsent: []].

	^ UITranslationSet
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 10/28/2007 16:30'!
uiTranslationSetAsSortedArray

	^ self uiTranslationSet asArray
		sort: [:a :b | a asLowercase <= b asLowercase]
! !

!ScratchTranslator class methodsFor: 'language translation' stamp: 'jm 6/12/2008 05:02'!
varSpecTranslationFor: spec varName: varName
	"Return the translation of a variable setter command spec for the given variable."

	| s i |
	s _  ScratchTranslator translationFor: spec.
	i _ s indexOfSubCollection: '%v' startingAt: 1.
	^ (s copyFrom: 1 to: i - 1), varName, (s copyFrom: (i + 2) to: s size).
! !


!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 6/2/2008 16:43'!
canRenderUnicode

	^ RenderPlugin notNil
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'ee 6/29/2008 13:33'!
centerOffsetForButtonWithFont: aStrikeFont
	"Answer the vertical offset above the center of a button for the given font. If the translator has provided a render hint string, return an offset that will center the first character of that string. Otherwise, return an offset that will center a lowercase 'x'."
	"[self centerOffsetForFont: (StrikeFont fontName: 'VerdanaBold' size: 10)] msecs"

	| f r vOffset |
	(RenderCenterOffsetCache includesKey: aStrikeFont) ifTrue: [
		^ RenderCenterOffsetCache at: aStrikeFont].

	f _ (StringMorph contents: self renderHintString font: aStrikeFont) imageForm.
	r _ f rectangleEnclosingPixelsNotOfColor: Color transparent.
	vOffset _ r top + (r height // 2).  "offset of string morph above the centerline of a button to center the given letter"

	r height = 0 ifTrue: [vOffset _ f height // 2].

	RenderCenterOffsetCache at: aStrikeFont put: vOffset.
	^ vOffset
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'ee 6/29/2008 13:33'!
centerOffsetForLabelWithFont: aStrikeFont
	
	| co |
	co _ self centerOffsetForButtonWithFont: aStrikeFont.
	^ co - 8.
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 6/9/2008 12:06'!
convertToMacRoman
	"Convert my translations from UTF8 to MacRoman."

	| s |
	TranslationDict associationsDo: [:assoc |
		(assoc key asLowercase ~= 'language-name') ifTrue: [
			s _ assoc value.
			s isUnicode ifTrue: [
				assoc value: s asMacRoman]]].
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 7/2/2008 12:34'!
detectRenderPlugin
	"Determine which plugin is available for rendering Unicode."
	"self detectRenderPlugin"

	| hasPlugin |
	RenderPlugin _ nil.

	RenderCenterOffsetCache _ IdentityDictionary new.
	RenderVerticalTrimCache _ IdentityDictionary new.

	"first try the Uniscribe plugin"
	hasPlugin _ true.
	[UnicodePlugin primMeasureString: 'test'] ifError: [hasPlugin _ false].
	hasPlugin ifTrue: [RenderPlugin _ UnicodePlugin. ^ self].

	"then try the Pango plugin"
	hasPlugin _ true.
	[PangoPlugin2 primMeasureString: 'test'] ifError: [hasPlugin _ false].
	hasPlugin ifTrue: [RenderPlugin _ PangoPlugin2. ^ self].

	"if we get here, we don't have a Unicode rendering plugin"
	RenderPlugin _ nil.
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'ee 5/23/2008 15:08'!
fixAmbigousRTLPunctuation
	"In a right-to-left language such as Arabic, punctuation characters such as period can be treated as either right-to-left or left-to-right characters. When they appear at the beginning of a string, the directionality is ambiguous. We assume that translation strings that start with punctuation characters are intended to start in left-to-right mode. This method prefixes punctuation characters with the Unicode LTR mark character, U+200E."
	"Note: Embedded colons are prefixed with the LTR mark everwhere that they appear since block translation strings are broken into component parts that can start with a colon."

	| punctuation colon prefix utf32 s |
	punctuation _ '.!!%#' asByteArray.
	colon _ $: asciiValue.
	prefix _ UTF32 with: 16r200E.
	TranslationDict keys do: [:k |
		((TranslationDict at: k) isKindOf: UTF8) ifTrue: [
		utf32 _ (UTF8 withAll: (TranslationDict at: k)) asUTF32.
		(utf32 size > 0 and: [punctuation includes: utf32 first]) ifTrue: [
			TranslationDict at: k put: (prefix, utf32) asUTF8].
		(utf32 includes: colon) ifTrue: [
			s _ WriteStream on: (UTF32 new: 100).
			utf32 do: [:ch |
				ch = colon ifTrue: [s nextPut: 16r200E].
				s nextPut: ch].
			TranslationDict at: k put: s contents asUTF8]]].

! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 6/29/2008 11:20'!
formFor: aString font: aStrikeFont fgColor: fgColor bgColor: bgColor
	"Answer a Form containing the given string in the given font and color rendered with the current rendering system. Answer nil if no rendering system is available."
	"(self formFor: 'Hello, Scratch!!' font: (StrikeFont fontName: 'VerdanaBold' size: 48) fgColor: Color black bgColor: Color blue) display"

	| f s |
	RenderPlugin ifNil: [^ nil].

	self setFont: aStrikeFont antialias: RenderAntiAliasing.
	RenderAntiAliasing
		ifTrue: [RenderPlugin setColorFG: fgColor BG: bgColor bgTransparent: true]
		ifFalse: [RenderPlugin setColorFG: fgColor BG: Color transparent bgTransparent: true].
 
	s _ aString.
	s isUnicode ifTrue: [s _ s asUTF8].  "convert from UTF32 to UTF8 if necessary"
	f _ Form extent: (RenderPlugin primMeasureString: s) depth: 32.
	RenderPlugin drawString: s on: f.
	^ f
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 6/29/2008 11:30'!
formFor: aString font: aStrikeFont fgColor: fgColor bgColor: bgColor suppressAntiAliasing: suppressAntiAliasing
	"Answer a Form containing the given string in the given font and color rendered with the current rendering system. The suppressAntiAliasing flag is useful when the background color is not constant, such as when part of the text is highlighted during editing. Answer nil if no rendering system is available."
	"(self formFor: 'Hello, Scratch!!' font: (StrikeFont fontName: 'VerdanaBold' size: 48) fgColor: Color black bgColor: Color blue) display"

	| f s |
	RenderPlugin ifNil: [^ nil].

	self setFont: aStrikeFont antialias: (RenderAntiAliasing & suppressAntiAliasing not).
	RenderAntiAliasing
		ifTrue: [RenderPlugin setColorFG: fgColor BG: bgColor bgTransparent: true]
		ifFalse: [RenderPlugin setColorFG: fgColor BG: Color transparent bgTransparent: true].
 
	s _ aString.
	s isUnicode ifTrue: [s _ s asUTF8].  "convert from UTF32 to UTF8 if necessary"
	f _ Form extent: (RenderPlugin primMeasureString: s) depth: 32.
	RenderPlugin drawString: s on: f.
	^ f
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 7/11/2008 17:57'!
isRTL: aBoolean

	IsRTL _ aBoolean.
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 3/14/2009 09:43'!
renderHintString
	"Answer a string to be used as an example button lable to adjust button size and label centering."
	"self renderHintString"
	"self showHintString"

	| result srcs |
	result _ RenderHintString.
	result ifNil: [
		result _ UTF8 new.
		srcs _ #('New' 'Open' 'Save' 'Save As' 'Share!!' 'Undo' 'Language' 'Extras' 'Want Help?' 'motion' 'looks' 'sound' 'pen' 'control' 'sensing' 'operators' 'variables').
		srcs do: [: s |
			result _ result, (self translationFor: s)]].

	RenderWithSqueak ifTrue: [result _ String withAll: result].

	^ result
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'ee 3/8/2008 18:16'!
renderScale

	^ RenderScale
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 7/9/2008 23:33'!
renderWithSqueak

	^ RenderWithSqueak
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 4/8/2009 17:50'!
setFont: aStrikeFont antialias: antialiasFlag

	| font isBold fontName fontSize |
	font _ aStrikeFont.
	font ifNil: [font _ StrikeFont fontName: 'Times' size: 14].

	fontName _ font name.
	fontSize _ (font pointSize * RenderScale) rounded.
	isBold _ false.

	(fontName asLowercase endsWith: 'bold') ifTrue: [
		fontName _ fontName copyFrom: 1 to: (fontName size - 4).
		isBold _ true].

	aStrikeFont isOSFont ifFalse: [
		(fontName beginsWith: 'VerdanaBoldNarrowSpace') ifTrue: [
			fontName _ 'Verdana'.
			isBold _ true].

		(fontName beginsWith: 'Times') ifTrue: [ "Squeak font; not used by Scratch"
			fontName _ 'Comic'.
			fontSize _ font pointSize + 1].

		RenderFont ifNotNil: [fontName _ RenderFont].
		RenderSuppressBold ifTrue: [isBold _ false]].

	RenderPlugin
		primSetFont: fontName
		size: fontSize
		bold: isBold
		italic: false
		antialias: antialiasFlag.
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 7/11/2008 14:10'!
setRenderingHints
	"Set optional rendering hints from fields in the translation file header. If a given hint is not explicitly set by the header, set it to its default value."

	| s |
	"default values:"
	IsRTL _ false.
	IsRTLMath _ false.
	RenderAntiAliasing _ Smalltalk isMacOSX.
	RenderFont _ nil.
	RenderHintString _ nil.
	RenderScale _ 1.
	RenderSuppressBold _ false.
	RenderCenterOffsetCache _ IdentityDictionary new.
	RenderVerticalTrimCache _ IdentityDictionary new.
	RenderWithSqueak _ true.

	TranslationDict isEmpty ifTrue: [^ self].

	(TranslationDict includesKey: 'Language-Direction') ifTrue: [
		IsRTLMath _ (TranslationDict at: 'Language-Direction') asString asUppercase = 'RTL-MATH'.
		IsRTLMath
			ifTrue: [IsRTL _ true]
			ifFalse: [IsRTL _ (TranslationDict at: 'Language-Direction') asString asUppercase = 'RTL']].

	Smalltalk isWindows ifTrue: [
		((TranslationDict includesKey: 'Win-Font') and: [(TranslationDict at: 'Win-Font') size > 0])
			ifTrue: [RenderFont _ TranslationDict at: 'Win-Font']].

	Smalltalk isMacOSX ifTrue: [
		((TranslationDict includesKey: 'Mac-Font') and: [(TranslationDict at: 'Mac-Font') size > 0])
			ifTrue: [RenderFont _ TranslationDict at: 'Mac-Font']].

	(Smalltalk isWindows | Smalltalk isMacOSX) ifFalse: [
		((TranslationDict includesKey: 'Linux-Font') and: [(TranslationDict at: 'Linux-Font') size > 0])
			ifTrue: [RenderFont _ TranslationDict at: 'Linux-Font']].

	s _ TranslationDict at: 'Font-Scale' ifAbsent: [''].
	s size > 0 ifTrue: [
		RenderScale _ s asString asNumberNoError.
		RenderScale = 0 ifTrue: [RenderScale _ 1].  "non-number string"
		RenderScale _ RenderScale within: 0.5 and: 2.5].

	s _ TranslationDict at: 'Suppress-Bold' ifAbsent: [''].
	s size > 0 ifTrue: [s asString asLowercase = 'true' ifTrue: [RenderSuppressBold _ true]].

	"even though we are not actively using the hint string, keep this code in case we need it in the future:"
	s _ TranslationDict at: 'Layout-Hint' ifAbsent: [''].
	s size > 0 ifTrue: [RenderHintString _ s].

	RenderWithSqueak _ self useSqueakRendering.
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 6/27/2008 21:58'!
showHintString
	"self showHintString"

	| f p r |
	p _ 20@70.
	f _ (StringMorph contents: self renderHintString font: (StrikeFont fontName: 'Verdana' size: 18)) imageForm.
	r _ f rectangleEnclosingPixelsNotOfColor: (f colorAt: 0@0).
	Display fillWhite: (p extent: f extent).
	f displayOn: Display at: p rule: Form paint.
	Display border: (r translateBy: p) width: 1 rule: Form over fillColor: Color blue.

	^ {
		f height.
		r height.
		f height - r height.
		self verticalTrimForFont: (StrikeFont fontName: 'VerdanaBold' size: 10)
	}! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 6/29/2008 11:21'!
stringExtent: aString font: aStrikeFont
	"Answer the extent of the given string using my font under the current font rendering system."
	"self stringExtent: 'Hello, Scratch!!' font: (StrikeFont fontName: 'Verdana' size: 18)"

	| s |
	RenderPlugin ifNil: [  "no renderer; use Squeak font size"
		^ (aStrikeFont widthOfString: aString asString) @ aStrikeFont height].

	aString size = 0 ifTrue: [^ 5@((aStrikeFont pointSize * RenderScale) rounded)].

	s _ aString.
	s isUnicode ifTrue: [s _ s asUTF8].  "convert from UTF32 to UTF8 if necessary"
	self setFont: aStrikeFont antialias: RenderAntiAliasing.
	^ RenderPlugin primMeasureString: s
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jens 6/7/2010 22:39'!
useSqueakRendering
	"Answer true if the current langauge can (or must) be rendered using Squeak,based on the availablility of a rendering plugin, the settings in the .po file and the contents of the translations. Assume that the header has already been processed to initialize HeaderDict."

	self canRenderUnicode ifFalse: [^ true].

	IsRTL ifTrue: [^ false].
	RenderScale ~= 1 ifTrue: [^ false].
	RenderSuppressBold ifTrue: [^ false].

"true ifTrue: [^ false]."  "disable Squeak rendering, even if language can be represented in MacRoman"

	TranslationDict associationsDo: [:assoc |
		((assoc key endsWith: '-comment') not and:
		 [(assoc key asLowercase = 'language-name') not and:
		 [assoc value isUnicode]]) ifTrue: [
			assoc value isMacRoman ifFalse: [^ false]]].

	^ true
! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 7/1/2008 10:32'!
verticalTrimForFont: aStrikeFont
	"Answer the number of pixels to trim from a button labeled with the given font. Some rendering systems (e.g. Pango on Mac OS), add excess space below the lowest extent of a font in some languages. This method computes the actual space needed by from the render hints string. It is the translator's responsibility to provide a render hints string that includes the tallest character and the the character with the maximum descent."
	"[self verticalTrimForFont: (StrikeFont fontName: 'VerdanaBold' size: 10)] msecs"

	| f r extra |
	(RenderVerticalTrimCache includesKey: aStrikeFont) ifTrue: [
		^ RenderVerticalTrimCache at: aStrikeFont].

	f _ (StringMorph contents: self renderHintString font: aStrikeFont) imageForm.
	r _ f rectangleEnclosingPixelsNotOfColor: (f colorAt: 0@0).
	extra _ (f height - r height - 2) max: 0.
	RenderVerticalTrimCache at: aStrikeFont put: extra.
	^ extra

! !

!ScratchTranslator class methodsFor: 'Unicode rendering' stamp: 'jm 6/29/2008 11:21'!
xRangesFor: utf8 font: aStrikeFont
	"Anwer an array of (leftX, rightX) pairs for the given Unicode string. There will be an entry in the resulting array for each UTF character in the input string, even when characters combine. Thus, in general, the x ranges for characters can overlap."

	RenderPlugin ifNil: [^ Array new: (utf8 asUTF32 size) withAll: #(0 0)].
	self setFont: aStrikeFont antialias: RenderAntiAliasing.
	^ RenderPlugin xRangesFor: utf8
! !


!ScratchTranslator class methodsFor: 'Unicode copy/paste' stamp: 'jm 7/11/2008 19:08'!
unicodeClipboard
	"Get the contents of the Unicode clipboard as UTF32."
	"self unicodeClipboard asArray"
	"(StringMorph contents: self unicodeClipboard) openInWorld"

	| n buf raw ch out s ch2 |
	RenderPlugin ifNil: [
		"if there is no plugin, return the normal text clipboard as UTF32"
		^ (UTF8 withAll: Smalltalk clipboardText) asUTF32].

	n _ RenderPlugin primClipboardSize.
	n = 0 ifTrue: [
		"if unicode clipboard is empty, try the normal one"
		^ (UTF8 withAll: Smalltalk clipboardText) asUTF32].

	buf _ SoundBuffer new: n.
	n _ RenderPlugin primGetCliboardInto: buf.
	raw _ (1 to: n) collect: [:i |
		ch _ buf at: i.
		ch < 0 ifTrue: [ch _ ch + 65536].
		ch].

	out _ WriteStream on: (UTF32 new: n).
	s _ ReadStream on: raw.
	[s atEnd] whileFalse: [
		ch _ s next.
		(ch between: 16rD800 and: 16rDBFF)
			ifTrue: [
				(s atEnd not and: [s peek between: 16rDC00 and: 16rDFFF]) ifTrue: [
					ch2 _ s next.
					ch _ ((ch bitAnd: 16r3FF) << 10) + (ch2 bitAnd: 16r3FF) + 16r10000.
					out nextPut: ch]]
			ifFalse: [
				((ch = 0) | (ch = 10)) ifFalse: [out nextPut: ch]]].

	^ out contents
! !

!ScratchTranslator class methodsFor: 'Unicode copy/paste' stamp: 'jm 6/30/2008 16:10'!
unicodeClipboardPut: unicodeOrString
	"Store the given string in the Unicode paste buffer of the underlying OS. If the argument is a String, it is assumed to be encoded in MacRoman and is converted to Unicode."
	"self unicodeClipboardPut: (UTF32 withAll: #(65 0 0 66 67 13 12354 0 27700 119070))"

	| useCRLF s buf |
	RenderPlugin ifNil: [
		"if there is no plugin, put UTF8 for string into the normal text clipboard"
		Smalltalk clipboardText: unicodeOrString asUTF8.
		^ self].

	useCRLF _ Smalltalk isWindows.
	s _ unicodeOrString.
	s isUnicode ifFalse: [s _ s asUTF8].
	s _ s asUTF32.
	buf _ WriteStream on: (Array new: 2 * s size).
	s do: [:ch |
		ch > 16r10000
			ifTrue: [
				"extended range character"
				ch _ ch - 16r10000.
				buf nextPut: (16rD800 bitOr: ((ch >> 10) bitAnd: 16r3FF)) - 16r10000.
				buf nextPut: (16rDC00 bitOr: (ch bitAnd: 16r3FF)) - 16r10000]
			ifFalse: [
				ch >= 16r8000 ifTrue: [
					 "make signed to allow storage in SoundBuffer"
					ch _ ch - 16r10000].
				ch ~= 0 ifTrue: [buf nextPut: ch].
				(useCRLF and: [ch = 13]) ifTrue: [buf nextPut: 10]]].

	RenderPlugin primCliboardPut: (SoundBuffer withAll: buf contents) size: buf size.
! !


!ScratchTranslator class methodsFor: 'locale' stamp: 'jm 8/8/2008 18:54'!
guessLanguage
	"Try to guess a language setting based on the local."
	"ScratchTranslator guessLanguage"

	| lang country myLocale |
	(lang _ self primLanguage) ifNil: [^ 'en'].
	lang size > 2 ifTrue: [lang _ lang copyFrom: 1 to: 2].
	country _ self primCountry ifNil: [^ lang].
	country size > 2 ifTrue: [country _ country copyFrom: 1 to: 2].

	"first try lang + country:"
	myLocale _ lang asLowercase, '_', country asLowercase.
	ISODict keys do: [:code | code asLowercase = myLocale ifTrue: [^ code]].

	"then try just lang:"
	myLocale _ lang asLowercase.
	ISODict keys do: [:code | code asLowercase = myLocale ifTrue: [^ code]].

	^ 'en'  "if no match, use English"

! !

!ScratchTranslator class methodsFor: 'locale' stamp: 'jm 8/4/2008 18:22'!
primCountry
	"Return a string with ISO 639 country tag for this system, or nil if the primitive fails."
	"self primCountry"

	<primitive: 'primitiveCountry' module: 'LocalePlugin'>
	^ nil
! !

!ScratchTranslator class methodsFor: 'locale' stamp: 'jm 8/4/2008 18:22'!
primLanguage
	"Return a string with ISO 639 language tag for this system, or nil if the primitive fails."
	"self primLanguage"

	<primitive:'primitiveLanguage' module: 'LocalePlugin'>
	^ nil
! !


!ScratchTranslator class methodsFor: 'rendering menu' stamp: 'jm 6/27/2008 22:54'!
fontMenu
	"Present a menu of fonts."

	| menu choice |
	RenderPlugin ifNil: [^ self beep].
	menu _ CustomMenu new.
	RenderPlugin getFontList do: [:fn | menu add: fn action: fn].
	choice _ menu startUp.
	choice ifNotNil: [
		RenderFont _ choice.
		self updateScratchUI].
! !

!ScratchTranslator class methodsFor: 'rendering menu' stamp: 'jm 6/27/2008 22:55'!
fontScaleMenu
	"Present a menu of font scales."

	| menu choice s |
	menu _ CustomMenu new.
	(0.8 to: 2.01 by: 0.1) do: [:n |
		s _ n printString, 'x'.
		n = RenderScale ifTrue: [s _ s, ' *'].
		menu add: s action: n].

	choice _ menu startUp.
	choice ifNotNil: [
		RenderScale _ choice.
		self updateScratchUI].
! !

!ScratchTranslator class methodsFor: 'rendering menu' stamp: 'jm 7/10/2008 14:04'!
renderAntiAliasing

	^ RenderAntiAliasing

! !

!ScratchTranslator class methodsFor: 'rendering menu' stamp: 'jm 7/14/2008 22:47'!
renderingMenu
	"Present a menu for experimenting with rendering settings."
	"self renderingMenu"

	| menu |
	World activeHand toolType: nil.
	Cursor normal show.
	RenderWithSqueak ifTrue: [^ self beep].

	menu _ CustomMenu new.
	menu add: 'set font scale...' action: #fontScaleMenu.
	RenderSuppressBold
		ifTrue: [menu add: 'allow bold' action: #toggleSuppressBold]
		ifFalse: [menu add: 'suppress bold' action: #toggleSuppressBold].

	menu localize.
	menu invokeOn: self.! !

!ScratchTranslator class methodsFor: 'rendering menu' stamp: 'jm 6/27/2008 22:58'!
toggleAntiAliasing

	RenderAntiAliasing _ RenderAntiAliasing not.
	self updateScratchUI.
! !

!ScratchTranslator class methodsFor: 'rendering menu' stamp: 'jm 6/27/2008 22:59'!
toggleSuppressBold

	RenderSuppressBold _ RenderSuppressBold not.
	self updateScratchUI.
! !

!ScratchTranslator class methodsFor: 'rendering menu' stamp: 'jm 6/27/2008 22:54'!
updateScratchUI
	"Update the UI of all ScratchFrameMorphs after changing the font or font scale."

	RenderCenterOffsetCache _ RenderCenterOffsetCache species new.
	RenderVerticalTrimCache _ RenderVerticalTrimCache species new.
	ScratchFrameMorph allInstancesDo: [:m | m rebuildUIForNewLanguage].
! !


!ScratchTranslator class methodsFor: 'import/export' stamp: 'jm 6/9/2008 16:32'!
export: keyString value: aStringOrUTF8 to: aStream
	"Write the given string to the given stream as a quoted gettext format. If the string is multiple lines. store it as a sequence of strings in double quotes, each ending with '\n'."

	| lines |
	aStream nextPutAll: keyString; space.
	lines _ (String withAll: aStringOrUTF8) lines.
	lines size = 1
		ifTrue: [aStream nextPut: $"; nextPutAll: lines first; nextPut: $"; crlf]
		ifFalse: [
			aStream nextPutAll: '""'; crlf.
			lines do: [:s | aStream nextPut: $"; nextPutAll: s; nextPutAll: '\n"'; crlf]].
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 5/15/2009 14:38'!
exportPootleTranslations
	"Exports translations from the locale folder into a new localeForPootle directory with a different subdirectory structure"
	"Need to figure out how to overwrite files without getting a permission dialog"
	"self exportPootleTranslations"

	| defaultDir localeDir localeForPootleDir fs dirName sdir |
	defaultDir _ FileDirectory default.
	(defaultDir directoryNames includes: 'locale')
		ifTrue: [localeDir _ self translationDir]
		ifFalse: [^ self "dialog should say no locale folder found"].
	localeForPootleDir _ defaultDir directoryNamed: 'translate.scratch.mit.edu'.
	localeForPootleDir _ localeForPootleDir directoryNamed: 'scratch'.
	localeDir fileNames do: [:n |
		(n endsWith: '.po') ifTrue: [
			dirName _ (n copyFrom: 1 to: n size - 3).
			sdir _ localeForPootleDir directoryNamed: dirName.
			fs _ sdir newFileNamed: n.
			fs nextPutAll: (localeDir fileNamed: n) contentsOfEntireFile.
			fs close]].
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 8/11/2008 17:36'!
exportStringsToTranslateFrom: aDictionary toFile: fName
	"Export the strings to be translated either to Scratch.pot or an existing translation (.po) file."
	"self resetUITranslationSet. self resetMIDITranslationSet. self exportStringsToTranslateFrom: nil toFile: nil"
	"self resetMIDITranslationSet. self exportStringsToTranslateFrom: (self importTranslation: 'es.po') toFile: 'exportTest.po'"

	| dir fn header f sections templateDict title keys comments |

	self setLanguage: 'en'.
	header _ HeaderString.
	dir _ self translationDir.
	fn _ fName.
	fn ifNil: [fn _ self templateFilename].
	(dir fileExists: fn) ifTrue: [  "extract the existing header, then delete the old .po file"
		aDictionary ifNotNil: [
			header _ aDictionary at: '' ifAbsent: [''].
			dir deleteFileNamed: (dir fullNameFor: fn)]].
	f _ FileStream newFileNamed: (dir fullNameFor: fn).
	"f nextPutAll: #(239 187 191) asByteArray asString."  "UTF8 byte-order mark - removed for now (Pootle)"

	"header comments are stored as '-comments' because the header key is the empty string"
	aDictionary ifNotNil: [
		comments _ aDictionary at: '-comments' ifAbsent: [#()].
		comments do: [:s | f nextPutAll: s; crlf]].

	"header is stored as a multi-line translation entry for the empty string"
	self export: 'msgid' value: '' to: f.
	self export: 'msgstr' value: header to: f.
	f crlf.

	sections _ {
		{'FORMATTING'.			self formattingHeaderFields}.
		{'BLOCKS'.				ScriptableScratchMorph blockSpecsForTranslation}.
		{'USER INTERFACE'.		self uiTranslationSetAsSortedArray}.
 		{'MIDI INSTRUMENTS'.	self midiTranslationSet asArray sort}
	}.

	aDictionary ifNotNil: [templateDict _ self importTranslation: self templateFilename].

	sections do: [:pair |
		title _ pair first.
		keys _ pair second asOrderedCollection.
		f nextPutAll: '############################################'; crlf.
		f nextPutAll: '# ', title; crlf.
		f nextPutAll: '############################################'; crlf.
		f crlf.

		((title = 'FORMATTING') and: [aDictionary isNil]) ifTrue: [
			f nextPutAll: self formattingSectionForPOT.
			keys _ OrderedCollection new].

		keys removeAll: self doNotTranslate.
		keys do: [:k |
			(aDictionary isNil or: [templateDict includesKey: k]) ifTrue: [
				"COMMENTS"
				comments _ #().
				(templateDict notNil and: [templateDict includesKey: k,'-comments'])
					ifTrue: [ "use the comment from template .pot file if there is one"
						comments _ (templateDict at: k, '-comments')]
					ifFalse: [ "else use the comment from the translation file"
						aDictionary ifNotNil: [
							comments _ aDictionary at: k, '-comments' ifAbsent: [#()]]].
				comments do: [:s | f nextPutAll: s; crlf].

				"FUZZY TAG"
				(aDictionary notNil and: [aDictionary includesKey: k, '-fuzzy'])
					ifTrue: [f nextPutAll: '#, fuzzy'; crlf].

				"KEY"
				self export: 'msgid' value: k to: f.

				"TRANSLATION"
				(aDictionary notNil and: [aDictionary includesKey: k])
					ifTrue: [
						self export: 'msgstr' value: (aDictionary at: k) to: f]
					ifFalse: [
						(aDictionary notNil and: [aDictionary includesKey: k asLowercase])
							ifTrue: [  "TEMPORARY CAPITALIZATION HACK"
								self export: 'msgstr' value: (aDictionary at: k asLowercase) to: f]
							ifFalse: [
								(aDictionary notNil and: [(k endsWith: '?') and: [aDictionary includesKey: (k copyFrom: 1 to: k size - 1)]])
									ifTrue: [  "TEMPORARY QUESTION HACK"
										self export: 'msgstr' value: (aDictionary at: (k copyFrom: 1 to: k size - 1)) to: f]
									ifFalse: [  "BLANK TRANSLATION"
										self export: 'msgstr' value: '' to: f]]].
				f crlf]]].
	f close.
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'jm 3/17/2009 16:53'!
extractLanguageFromFileNamed: aFilename
	"Return the UTF8 value of the 'Language-Name:' header from the file with the given name, or nil if the file does not exist or it does not include that header."
	"self extractLanguageFromFileNamed: (self translationDir fullNameFor: 'Scratch.pot')"

	| f s i line lang nextLine lineSize |
	f _ FileStream readOnlyFileNamedOrNil: aFilename.
	f ifNil: [^ nil].
	s _ f contentsOfEntireFile.
	i _ 0.
	[true] whileTrue: [
		i _ s findString: 'language-name' startingAt: i + 1 caseSensitive: false.
		i = 0 ifTrue: [^ nil].
		line _ (self withoutComment: (self lineOf: s containingIndex: i)) withBlanksTrimmed.
		lineSize _ line size.
		((line size > 0) and: [line first = $m and: [line last = $"]]) ifTrue: [
			line _ (self extractQuotedStringFrom: line) withBlanksTrimmed.
			(line asLowercase beginsWith: 'language-name') ifTrue: [
				nextLine _ (self withoutComment: (self lineOf: s containingIndex: (i + lineSize))) withBlanksTrimmed.
				lang _ (nextLine copyFrom: 9 to: (nextLine size - 1)) withBlanksTrimmed.
				^ (UTF8 withAll: lang)]]].
	^ nil
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 8/3/2008 20:01'!
importOLPCTranslations
	"Imports translations from the OLPC Pootle translation directory into the Scratch/locale/ directory and renames the .po files"
	"First copy the /scratch/ folder from https://dev.laptop.org/~sayamindu/scratch_translations.zip to the local directory, then run this"
	"self importOLPCTranslations"

	| dir subDir |
	dir _ FileDirectory default.
	(dir directoryNames includes: 'scratch')
		ifTrue: [dir _ dir directoryNamed: 'scratch']
		ifFalse: [^ self "dialog should say no scratch folder found"].
	dir directoryNames do: [:n |
		subDir _ dir directoryNamed: n.
		subDir rename: 'Scratch.po' toBe: (self translationDir fullNameFor: n,'.po')].
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 5/22/2009 14:16'!
importPootleTranslations
	"Imports translations from the LLK Pootle translation directory into the Scratch/locale/ directory"
	"First checkout svn://translate.scratch.mit.edu:52400 to the local directory, then run this"
	"self importPootleTranslations"

	| dir subDir fs |
	dir _ FileDirectory default.
	(dir directoryNames includes: 'translate.scratch.mit.edu')
		ifTrue: [dir _ dir directoryNamed: 'translate.scratch.mit.edu'.
			(dir directoryNames includes: 'scratch')
				ifTrue: [dir _ dir directoryNamed: 'scratch']
				ifFalse: [^ self "dialog should say no scratch folder found"]]
		ifFalse: [^ self "dialog should say no scratch folder found"].
	dir directoryNames do: [:n |
		(n = '.svn') ifFalse: [
			subDir _ dir directoryNamed: n.
			fs _ self translationDir newFileNamed: n,'.po'.
			fs nextPutAll: (subDir fileNamed: n,'.po') contentsOfEntireFile.
			fs close]].
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'jm 6/10/2008 00:11'!
importTranslation: aFilename
	"Import a translation dictionary."
	"self importTranslation: 'cs.po'"

	| f lines lstream result |
	f _ FileStream readOnlyFileNamedOrNil: (self translationDir fullNameFor: aFilename).
	f ifNil: [
		DialogBoxMorph inform: 'File not found' withDetails: aFilename.
		^ nil].
	lines _ f contentsOfEntireFile lines.

	"trim blanks"
	lines _ lines collect: [:s | s withoutLeadingBlanks].

	lstream _ ReadStream on: lines.
	[result _ self parseTranslationLines: lstream] ifError: [
		DialogBoxMorph inform: 'Error reading file: ', aFilename,' at line ', (lstream position asString), '.'].

	^ result
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'jm 6/3/2008 14:03'!
isRTL
	"Returns true if the header 'Language-Direction' is set to 'RTL'"

	^ IsRTL
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'jm 11/2/2007 18:03'!
lineOf: aString containingIndex: anIndex
	"Answer the line of the given string that contains the given index."

	| cr lf i j ch |
	cr _ Character cr.
	lf _ Character lf.
	i _ j _ (anIndex within: 1 and: aString size).
	[(i > 1) and: [((ch _ aString at: i - 1) ~= cr) & (ch ~= lf)]] whileTrue: [i _ i - 1].
	[(j < aString size) and: [((ch _ aString at: j + 1) ~= cr) & (ch ~= lf)]] whileTrue: [j _ j + 1].
	^ aString copyFrom: i to: j
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 7/10/2008 09:20'!
parseCommandSpec: aCommandSpec
	"Answer an array of token strings containing my keywords and argument specs."
	"self parseCommandSpec: '%a of %m'"

	| result len i j spec |
	result _ OrderedCollection new.
	spec _ aCommandSpec.
	(spec isKindOf: UTF8) ifTrue: [spec _ String withAll: spec].
	len _ aCommandSpec size.

	i _ 1.
	[(i < len) and: [(spec at: i) isSeparator]] whileTrue: [i _ i + 1].
	[i <= len] whileTrue: [
		j _ spec indexOf: $% startingAt: i.
		j > 0
			ifTrue: [
				j > i ifTrue: [result addLast: (spec copyFrom: i to: j - 1)].
				j < len
					ifTrue: [result addLast: (spec copyFrom: j to: j + 1)]
					ifFalse: [result addLast: '%'].
				i _ j + 2]
			ifFalse: [
				result addLast: (spec copyFrom: i to: len).
				i _ len + 1]].

	^ result asArray collect: [:s | s withBlanksTrimmed]! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 7/9/2008 16:06'!
parseTranslationLines: lineStream
	"Parse a language translation from the given stream of lines and answer the resulting translation dictionary."

	| result key val comments fuzzy |
	result _ Dictionary new.
	"initialComments _ OrderedCollection new."
	comments _ OrderedCollection new.
	fuzzy _ nil.

	"collect all translation diciontary entries"
	[lineStream atEnd] whileFalse: [
		((lineStream peek beginsWith: '# ')
			and: [(#('# BLOCKS' '# USER INTERFACE' '# MIDI INSTRUMENTS' '# FORMATTING') includes: (lineStream peek)) not])
			ifTrue: [comments add: (UTF8 withAll: (lineStream next))]
			ifFalse: [(lineStream peek beginsWith: '#, fuzzy')
				ifTrue: [fuzzy _ lineStream next]
				ifFalse: [((lineStream peek beginsWith: 'msgid') or: [lineStream peek beginsWith: 'ï»¿msgid']) "BOM"
					ifTrue: [
						key _ self extractQuotedStringFrom: lineStream next.
						val _ ''.
						[lineStream atEnd not and: [lineStream peek beginsWith: 'msgstr']] whileTrue: [
							val _ val, (self extractQuotedStringFrom: lineStream next).
							[lineStream atEnd not and: [lineStream peek beginsWith: '"']] whileTrue:[
								val _ val, (self extractQuotedStringFrom: lineStream next)]].
						comments size > 0 ifTrue: [result at: key,'-comments' put: comments].
						fuzzy ifNotNil: [result at: key,'-fuzzy' put: (UTF8 withAll: fuzzy)].
						result at: key put: (UTF8 withAll: val).
						comments _ OrderedCollection new.
						fuzzy _ nil]
					ifFalse: [lineStream next.
						lineStream atEnd ifTrue: [^ result]]]]].

	^ result
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'jens 5/17/2010 17:35'!
templateFilename
	"Returns the filename for the translation template file to send to users."

	^ 'BYOB.pot'
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'jm 10/28/2007 16:17'!
translationDir
	"Returns the directory which contains the translation files and creates it if it doesn't exist."
	
	| dir |
	dir _ FileDirectory default.
	(dir directoryNames includes: 'locale')
		ifFalse: [[dir createDirectory: 'locale'] ifError: [^ dir]].
	dir _ dir directoryNamed: 'locale'.

	^ dir
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 10/25/2007 13:45'!
updateTranslationFiles
	"Takes the existing .po files and updates them to reflect the latest Scratch strings to be translated."
	"self updateTranslationFiles"

	| translationDict codes |
	self importLanguagesList.
	codes _ self isoDict keys.
	codes do: [:c |
		(c = 'en') ifFalse:[
			translationDict _ self importTranslation: c,'.po'.
			self exportStringsToTranslateFrom: translationDict toFile: c,'.po']].
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 7/10/2008 15:58'!
verifyTranslationFiles
	"Returns a dictionary with each language filename as a key and a dictionary with the header and formatting fields as the key's value"
	"self verifyTranslationFiles"

	| verificationDict dict subDict |
	verificationDict _ Dictionary new.
	self translationDir fileNames do: [: n |
		dict _ self importTranslation: n.
		subDict _ Dictionary new.
		subDict at: 'header' put: (dict at: '' ifAbsent: ['no header']).
		self formattingHeaderFields do: [:f |
			subDict at: f put: (dict at: f ifAbsent: [''])].

		verificationDict at: n put: subDict].
	^ verificationDict! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 6/24/2009 10:43'!
verifyTranslationFilesArgOrder
	"Returns a dictionary with any language file with invalid arguments as the key and the invalid arguments as the value"
	"self verifyTranslationFilesArgOrder2"

	| verificationDict dict subDict ts argsS argsTS |
	verificationDict _ Dictionary new.
	self translationDir fileNames do: [: n |
		dict _ self importTranslation: n.
		subDict _ Dictionary new.
		ScriptableScratchMorph blockSpecsForTranslation do: [:s |
			ts _ dict at: s ifAbsent: [s].
			argsS _ (CommandBlockMorph parseCommandSpec: s) select: [:a | CommandBlockMorph isArgSpec: a].
			argsTS _ (CommandBlockMorph parseCommandSpec: ts) select: [:a | CommandBlockMorph isArgSpec: a].
			(argsS sort = argsTS sort)
				ifFalse: [(ts size > 0) ifTrue: [subDict at: s put: ts]]].
		(subDict values size > 0)
			ifTrue: [verificationDict at: n put: subDict]].

	^ verificationDict
! !

!ScratchTranslator class methodsFor: 'import/export' stamp: 'ee 11/13/2007 16:49'!
withoutComment: s
	"Answer the given string without any comment. A hash character (#) begins a comment that runs to the end of the line unless the hash character is inside a double-quoted string."
	"ScratchTranslator withoutComment: '# full line comment'"
	"ScratchTranslator withoutComment: 'contents …ffnen # plus s comment'"

	| inString lastCh ch |
	(s indexOf: $#) = 0 ifTrue: [^ s].

	inString _ false.
	lastCh _ Character space.
	1 to: s size do: [:i |
		ch _ s at: i.
		ch = $# ifTrue: [
			inString ifFalse: [^ s copyFrom: 1 to: i - 1]].
		ch = $" ifTrue: [
			(inString and: [lastCh = $\]) ifFalse: [
				inString _ inString not]]].
	^ s
! !


ScratchTranslator initialize!
