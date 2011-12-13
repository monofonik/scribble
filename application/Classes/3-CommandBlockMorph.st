BlockMorph subclass: #CommandBlockMorph
	instanceVariableNames: 'commandSpec argPermutation argMorphs titleMorph receiver selector isReporter isTimed wantsName wantsPossession numberArgFlags stopFrame '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Scratch-Blocks'!
!CommandBlockMorph commentStamp: '<historical>' prior: 0!
I represent a command or reporter. I have a label and may also have one or more arguments. The label text, number of arguments, and ordering of arguments and keywords are defined by my commandSpec string. This string consists of a sequence of keywords interspersed with argument specifications that indicate where the arguments appear. Here are some possible argument specifications:

	%b	- boolean
	%c	- color
	%C	- color (chosen with eyedropper, not palette)
	%m	- morph reference
	%n	- number
	%s	- string

Examples:

	%b and %b
	%m's color %C sees %C
	repeat %n times
!


!CommandBlockMorph methodsFor: 'initialization' stamp: 'jm 10/22/2007 09:15'!
initialize

	super initialize.
	commandSpec _ ''.
	argMorphs _ OrderedCollection new.
	receiver _ nil.
	selector _ nil.
	isTimed _ false.
! !


!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 8/6/2008 20:59'!
argMorphs

	^ argMorphs
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'ee 3/2/2009 11:53'!
argPermutation: aSet

	argPermutation _ aSet
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jens 12/21/2009 11:46'!
args
	"Answer my arguments evaluated and permuted into the order expected by the underlying Squeak method."

	^ self organizeArgs: (argMorphs collect: [:m | m evaluate]) asArray
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 8/24/2003 17:05'!
color: aColor

	super color: aColor.
	self layoutChanged.
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 11/20/2002 09:16'!
commandSpec

	^ commandSpec
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jens 1/11/2010 21:31'!
commandSpec: aString
	"Set my command spec string. See my class comment."
	"CommandBlockMorph new commandSpec: 'forward %n'"

	commandSpec _ aString.
	numberArgFlags _ nil.
	self addLabel.
	self addCommandIcons.
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 5/7/2009 14:16'!
defaultArgs: defaultValues
	"Set the default values of my arguments from the given list."

	| argM defaultValue |
	1 to: (defaultValues size min: argMorphs size) do: [:i |
		argM _ argMorphs at: (argPermutation at: i).
		defaultValue _ defaultValues at: i.
		(argM  isKindOf: ExpressionArgMorph)
			ifTrue: [argM defaultValueFromSpec: defaultValue]
			ifFalse: [argM defaultValue: defaultValue]].

! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 1/21/2007 11:43'!
helpScreenName
	"Answer the name of the help screen for this block, or nil if no help is available."

	selector isInfix ifTrue: [
		'+' = selector ifTrue: [^ 'minus'].
		'-' = selector ifTrue: [^ 'minus'].
		'*' = selector ifTrue: [^ 'minus'].
		'/' = selector ifTrue: [^ 'minus'].

		'<' = selector ifTrue: [^ 'lessThan'].
		'=' = selector ifTrue: [^ 'equals'].
		'>' = selector ifTrue: [^ 'greaterThan'].

		'&' = selector ifTrue: [^ 'and'].
		'|' = selector ifTrue: [^ 'or'].

		'\\' = selector ifTrue: [^ 'mod'].

		^ nil].

	"answer the selector with colons mapped to underscores"
	^ selector asString collect: [:ch | ch = $: ifTrue: [$_] ifFalse: [ch]]
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 4/15/2007 20:01'!
isForever

	^ (selector = #doForever) | (selector = #doForeverIf)
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jens 4/14/2010 10:48'!
isStop

	^ #(doReturn stopAll doAnswer doStopBlock) includes: selector
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 12/10/2003 20:58'!
isTimed

	^ isTimed
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'DaveF 7/10/2003 17:41'!
isTimed: aBoolean
	"Indicates that this block's evaluate method will be called repeatedly throughout some time interval."

	isTimed _ aBoolean.! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'ee 2/28/2009 17:05'!
numberArgFlags
	"Answer an array of booleans indicating which of my arguments must be numbers. Compute on first use and cache the result."

	| argSpecs argM |
	numberArgFlags ifNotNil: [^ numberArgFlags].

	argSpecs _ (CommandBlockMorph parseCommandSpec: commandSpec) select: [:s | CommandBlockMorph isArgSpec: s].
	argSpecs _ self organizeArgs: argSpecs.
	numberArgFlags _ argSpecs collect: [:spec |
		argM _ self uncoloredArgMorphFor: spec.
		(argM isKindOf: ExpressionArgMorph)
			ifTrue: [
				(argM isKindOf: ExpressionArgMorphWithMenu)
					ifTrue: [
						argM isNumberExpression or:
						[#(listIndexMenu listIndexForDeleteMenu) includes: argM menuSelector]]
					ifFalse: [argM isNumberExpression]]
			ifFalse: [false]].

	^ numberArgFlags
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 6/22/2003 21:50'!
receiver

	^ receiver
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 7/7/2004 00:09'!
receiver: anObject
	"Set my receiver object."

	receiver _ anObject.
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 7/2/2003 11:47'!
selector

	^ selector
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 8/3/2003 23:52'!
selector: aSymbol

	selector _ aSymbol.
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'jm 11/30/2007 12:21'!
selectorAndArg
	"Answer an array containing my selector and argument (if any)."

	| args |
	args _ self args.
	^ Array with: selector with: (args size = 0 ifTrue: [nil] ifFalse: [args first])
! !

!CommandBlockMorph methodsFor: 'accessing' stamp: 'JM 12/13/2011 14:30'!
uncoloredArgMorphFor: specString
	"Answer an argument morph for the given argument specification string."

	| code |

	code _ specString at: 2.
	$a = code ifTrue: [^ AttributeArgMorph new choice: ''].
	$b = code ifTrue: [^ BooleanArgMorph new].
	$B = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #blockId; choice: ''].
	$c = code ifTrue: [^ ColorArgMorph new showPalette: true].
	$C = code ifTrue: [^ ColorArgMorph new showPalette: false].  "don't use palette; pick from screen"
	$d = code ifTrue: [^ ExpressionArgMorphWithMenu new numExpression: '0'; menuSelector: #directionMenu].
	$D = code ifTrue: [^ ExpressionArgMorphWithMenu new numExpression: '48'; menuSelector: #midiDrumMenu].
	$e = code ifTrue: [^ EventTitleMorph new].
	$f = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #mathFunctionNames; choice: 'sqrt'].
	$g = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #graphicEffectNames; choice: 'color'].
	$H = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #hookupSensorNames].
	$h = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #hookupBooleanSensorNames].
	$I = code ifTrue: [^ ExpressionArgMorphWithMenu new numExpression: '1'; menuSelector: #midiInstrumentMenu].
	$i = code ifTrue: [^ ExpressionArgMorphWithMenu new numExpression: '1'; menuSelector: #listIndexMenu].
	$k = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #keyNames; choice: 'space'].
	$L = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #listVarMenu].
	$l = code ifTrue: [^ ChoiceOrExpressionArgMorph new getOptionsSelector: #costumeNames; choice: 'costume1'].
	$m = code ifTrue: [^ SpriteArgMorph new].
	$M = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #motorNames].
	$n = code ifTrue: [^ ExpressionArgMorph new numExpression: '10'].
	$N = code ifTrue: [^ ExpressionArgMorphWithMenu new numExpression: '60'; menuSelector: #noteSelector].
	$s = code ifTrue: [^ ExpressionArgMorph new stringExpression: ''].
	$S = code ifTrue: [^ ChoiceOrExpressionArgMorph new getOptionsSelector: #soundNames; choice: 'pop'].
	$v = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #varNamesMenu; choice: ''].
	$W = code ifTrue: [^ ChoiceArgMorph new getOptionsSelector: #motorDirection].
	$x = code ifTrue: [^ ChoiceOrExpressionArgMorph new getOptionsSelector: #sceneNames; choice: ''].
	$y = code ifTrue: [^ ExpressionArgMorphWithMenu new numExpression: '1'; menuSelector: #listIndexForDeleteMenu].

	"special args for BYOB"

	$o = code ifTrue: [ ^ CSlotMorph new "SpecialArgMorph new type: #command"].
	$O = code ifTrue: [ ^ MultiArgMorph type: #command].
	$r = code ifTrue: [ ^ OSlotMorph new receiver: receiver; type: #reporterslot; yourself "SpecialArgMorph new type: #reporter"].
	$R = code ifTrue: [ ^ MultiArgMorph type: #reporter].
	$p = code ifTrue: [ ^ OSlotMorph new receiver: receiver; type: #booleanslot; yourself "SpecialArgMorph new type: #predicate"].
	$P = code ifTrue: [ ^ MultiArgMorph type: #predicate].
	$t = code ifTrue: [ ^ SpecialArgMorph new type: #list].
	$u = code ifTrue: [ ^ MultiArgMorph type: #list].
	$T = code ifTrue: [ ^ ExpressionArgMorph new stringExpression: ''; isText: true.  "SpecialArgMorph new type: #text"].
	$U = code ifTrue: [ ^ MultiArgMorph type: #text].
	$V = code ifTrue: [ ^ MultiArgMorph type: #boolean].
	$w = code ifTrue: [ ^ MultiArgMorph type: #number].
	$X = code ifTrue: [ ^ MultiArgMorph type: #any].
	$z = code ifTrue: [ ^ VariableBlockMorph new 
							isSpecialForm: true; 
							selector: #getVar:;
							"color: (ScriptableScratchMorph blockColorFor: 'variables');"
							commandSpec: '?'].
	$Z = code ifTrue: [ ^ SpecialArgMorph new type: #reporterslot].
	$Y = code ifTrue: [ ^ SpecialArgMorph new type: #booleanslot].

"++++ deprecated +++++++++++
	$K = code ifTrue: [ ^ PredicateArgMorph new ].
+++++++++++++++++++++++++++"
	
	$A = code ifTrue: [ ^ ChoiceArgMorph new options: {'with inputs' asUTF8 localized. 'with input list' asUTF8 localized}; choice: 'with inputs'].
	$F = code ifTrue: [ ^ ChoiceArgMorph new options: {'number' localized. 'text' localized. 'boolean' localized. 'list' localized. 'command' localized. 'reporter' localized. 'predicate' localized. 'object' localized}; choice: 'number' localized].

	$E = code ifTrue: [ ^ CSlotMorph new].
	$G = code ifTrue: [ ^ CArgSlotMorph new].
	$J = code ifTrue: [ ^ MultiArgMorph type: #loop].

" ++++++++ commented out because we need the codes for other slots -jens +++++++++++++++++++++++

	$K = code ifTrue: [ ^ CReporterSlotMorph new receiver: receiver; yourself ].
	$Q = code ifTrue: [ ^ MultiArgMorph type: #reporterSlot].
	$j = code ifTrue: [ ^ TypeInReporterSlotMorph new].
	$q = code ifTrue: [ ^ MultiArgMorph type: #typeInReporter].

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	$j = code ifTrue: [ ^ UnevaluatedExpressionArgMorph new stringExpression: ''].
	$q = code ifTrue: [ ^ MultiArgMorph type: #unevaluated].
	$Q = code ifTrue: [ ^ UnevaluatedBooleanArgMorph new].
	$K = code ifTrue: [ ^ MultiArgMorph type: #unevaluatedBoolean].

	$1 = code ifTrue: [ ^ SpecialArgMorph new type: #objSlot].
	$2 = code ifTrue: [ ^ MultiArgMorph type: #objSlot].
	$3 = code ifTrue: [ ^ ChoiceArgMorph new options: StrikeFont fontNames ].

	^ ExpressionArgMorph new numExpression: '10'
! !


!CommandBlockMorph methodsFor: 'evaluation' stamp: 'jens 6/13/2009 19:55'!
argumentAt: index
	"Returns the argument morph at the given index."

	argPermutation ifNil: [^argMorphs at: index].	"BYOB custom blocks don't need argPermutations"
	^ argMorphs at: (argPermutation at: index).
! !

!CommandBlockMorph methodsFor: 'evaluation' stamp: 'jm 12/10/2003 18:41'!
argumentCount
	"Returns the number of arguments to this command block."

	^ argMorphs size
! !

!CommandBlockMorph methodsFor: 'evaluation' stamp: 'jens 1/11/2010 13:34'!
coerceArgs: argList
	"Answer an arguments array in which all arguments that should be numbers have been coerced to numbers if necessary."

	| args specialCommands ignoreCases numFlags |
	args _ argList asArray.
	specialCommands _ #(
		"append:toList: deleteLine:ofList: getLine:ofList: insert:at:ofList: list:contains: setLine:ofList:to:"
		lookLike: showBackground:
		playSound: doPlaySoundAndWait
		"setVar:to:").

	ignoreCases _ Dictionary new.
	ignoreCases
		at: #deleteLine:ofList: put: 1;
		at: #getLine:ofList: put: 1;
		at: #insert:at:ofList: put: 2;
		at: #setLine:ofList:to: put: 1.

	(specialCommands includes: selector) ifFalse: [
		"ensure args are numbers where numbers are expected"
		numFlags _ self numberArgFlags.

		(ignoreCases keys includes: selector) ifTrue: [
			numFlags at: (ignoreCases at: selector) put: false ].

		1 to: args size do: [:i |
			(numFlags at: i) ifTrue: [args at: i put: (args at: i) asNumberNoError]]].

	^ args
! !

!CommandBlockMorph methodsFor: 'evaluation' stamp: 'jens 7/21/2010 01:06'!
evaluate

	^ self evaluateWithArgs: self args
! !

!CommandBlockMorph methodsFor: 'evaluation' stamp: 'jens 1/31/2011 00:09'!
evaluateInfixWithArgs: rawArgs
	"Evalue an infix operator with the given arguments list. Special case for comparison operatores when both operands are strings. Reverse order of comparison operands in RTL languages."
	"Note: The strings 'true' and 'false' in either English or the current language are equal to the boolean value that they name."

	| args result arg1 arg2 |

	args _ rawArgs.
	#= = selector ifTrue: [
		"special case: check for equality between a boolean and the special strings 'true' or 'false'"
		((args first isKindOf: String) and: [args second isKindOf: Boolean]) ifTrue: [
			(args first = 'true') ifTrue: [^ args second = true].
			(args first = 'false') ifTrue: [^ args second = false].
			(args first = (ScratchTranslator translationFor: 'true')) ifTrue: [^ args second = true].
			(args first = (ScratchTranslator translationFor: 'false')) ifTrue: [^ args second = false]].
		((args first isKindOf: Boolean) and: [args second isKindOf: String]) ifTrue: [
			(args second = 'true') ifTrue: [^ args first = true].
			(args second = 'false') ifTrue: [^ args first = false].
			(args second = (ScratchTranslator translationFor: 'true')) ifTrue: [^ args first = true].
			(args second = (ScratchTranslator translationFor: 'false')) ifTrue: [^ args first = false]]].

	(#(< = >) includes: selector)
		ifTrue: [((args first isKindOf: String) or: [args second isKindOf: String])
			ifTrue: [
				arg1 _ receiver interpretStringAsNumberIfPossible: args first.
				arg2 _ receiver interpretStringAsNumberIfPossible: args second.
				((arg1 isKindOf: String) and: [arg2 isKindOf: String]) ifTrue: [
					result _ args first compare: args second.
					#< = selector ifTrue: [^ result = 1].
					#= = selector ifTrue: [^ result = 2].
					#> = selector ifTrue: [^ result = 3]].
				((arg1 isKindOf: Number) and: [arg2 isKindOf: Number]) ifTrue: [
					^ arg1 perform: selector with: arg2].
				^ false]
			ifFalse: [
				(args first isKindOf: ScratchListMorph)
					ifTrue: [^ args first equals: args second].
				(args second isKindOf: ScratchListMorph)
					ifTrue: [^ args second equals: args first]]]
		ifFalse: [(ScratchTranslator isRTLMath and: [((selector = #\\) not)]) ifTrue: [args _ args reversed]]. "RTLMath operators are RTL"

	(#(& |) includes: selector) ifTrue: [^ args first perform: selector with: args second].

	((args first isKindOf: ScriptableScratchMorph) or: [args second isKindOf: ScriptableScratchMorph])
		ifTrue: [^ args first = args second].

	^ args first asNumberNoError perform: selector with: args second asNumberNoError
! !

!CommandBlockMorph methodsFor: 'evaluation' stamp: 'jens 2/28/2011 02:22'!
evaluateWithArgs: rawArgs
	"Evalue this block with the given argument list."

	| args |
	"special case for math and boolean infix operators"
	selector isInfix ifTrue: [^ self evaluateInfixWithArgs: rawArgs].

	args _ self coerceArgs: rawArgs..

	"special case for unary operators"
	(#(abs not rounded sqrt truncated) includes: selector) ifTrue: [^ args first perform: selector].

	^ receiver perform: selector withArguments: args
! !

!CommandBlockMorph methodsFor: 'evaluation' stamp: 'jens 1/11/2010 13:34'!
organizeArgs: argList
	"Answer an arugments array in which all arguments have been rearranged to the original English permutation"

	| newArgList |

	argPermutation ifNil: [^ argList].
	(#(+ - / * =) includes: selector) ifTrue: [^ argList].
	newArgList _ #().
	1 to: argPermutation size do: [:i |
		newArgList _ newArgList copyWith: (argList at: (argPermutation at: i))].
	^ newArgList
! !


!CommandBlockMorph methodsFor: 'elements' stamp: 'jens 6/28/2010 22:51'!
editElements
	| cls sel |
	sel _ selector.
	cls _ receiver class classThatUnderstands: sel.
	cls ifNil: [cls _ ScratchProcess].
	(cls canUnderstand: sel)
		ifFalse: [isSpecialForm ifTrue: [
			(#(getBlockVar: getVar:) includes: sel) ifTrue: [sel _ #getVar].
			(#(setBlockVar:to: setVar:to:) includes: sel) ifTrue: [sel _ #setVar].
			(#(changeBlockVar:by: changeVar:by:) includes: sel) ifTrue: [sel _ #changeVar]]].
	ElementsEditorFrameMorph new 
		onMethod: sel ofClass: cls! !




!CommandBlockMorph methodsFor: 'object i/o' stamp: 'jm 9/24/2003 18:54'!
fieldsVersion

	^ 1
! !

!CommandBlockMorph methodsFor: 'object i/o' stamp: 'jm 9/24/2003 19:01'!
initFieldsFrom: anObjStream version: classVersion

	super initFieldsFrom: anObjStream version: classVersion.
	self initFieldsNamed: #(
		commandSpec
		argMorphs
		titleMorph
		receiver
		selector
		isReporter
		isTimed
		wantsName
		wantsPossession
	) from: anObjStream.
! !

!CommandBlockMorph methodsFor: 'object i/o' stamp: 'jm 9/24/2003 19:01'!
storeFieldsOn: anObjStream

	super storeFieldsOn: anObjStream.
	self storeFieldsNamed: #(
		commandSpec
		argMorphs
		titleMorph
		receiver
		selector
		isReporter
		isTimed
		wantsName
		wantsPossession
	) on: anObjStream.
! !


!CommandBlockMorph methodsFor: 'stack/tuple conversion' stamp: 'jens 3/21/2011 01:43'!
asBlockTuple
	"Answer a tuple (Array) describing this block and its arguments."

	| blockTuple argList arg val eval |
	
	blockTuple _ Array new: argMorphs size + 3.
	blockTuple
		at: 1 put: #byob;
		at: 2 put: self rcvr;
		at: 3 put: selector.

	argList _ argMorphs.
	argList _ self organizeArgs: argList.
	((#(+ - / * =) includes: selector) and: [ScratchTranslator isRTLMath]) "RTLMath operators are RTL"
		ifTrue: [argList _ argList reversed].
	1 to: argList size do: [:i |
		arg _ argList at: i.
		(arg isKindOf: ArgMorph) | (arg isKindOf: EventTitleMorph)
			ifTrue: [(arg isKindOf: MultiArgMorph)
				ifTrue: [ blockTuple at: i + 3 put: arg listValue convertStacksToTuples] "a list"
				ifFalse: [ ((arg isKindOf: CSlotMorph) or: [arg isKindOf: OSlotMorph])
					ifTrue: [blockTuple at: i + 3 put: arg asBlockTuple]
					ifFalse: [(arg isKindOf: ExpressionArgMorph)
						ifTrue: [
							val _ arg getExpression.
							arg isNumberExpression
								ifTrue: [val = ' ' asUTF8
									ifTrue: [eval _ val]
									ifFalse: [(arg evaluate isKindOf: Symbol)	" special case for special values in list blocks (first, last, any)"
										ifTrue: [eval _ arg evaluate]
										ifFalse: [eval _ val asNumberNoError]]]
								ifFalse: [eval _ arg evaluate]]
						ifFalse: [ (arg isKindOf: SpriteArgMorph)
							ifTrue: [eval _ arg getChoice]
							ifFalse: [eval _ arg evaluate]].
						blockTuple at: i + 3 put: eval]]]
			ifFalse: [blockTuple at: i + 3 put: arg asBlockTuple]].
	^ blockTuple
! !


!CommandBlockMorph methodsFor: 'private' stamp: 'ee 1/28/2009 14:04'!
addCommandIcons
	"Add additional icons to certain blocks. Do nothing if this isn't one of those blocks."

	| f m |
	#turnLeft: = selector ifTrue: [
		f _ ScratchFrameMorph skinAt: #turnCCW ifAbsent: [^ self].
		m _ self firstSubmorph delete.
		self addMorphFront: (ImageMorph new form: f).
		self addMorphFront: m].

	#turnRight: = selector ifTrue: [
		f _ ScratchFrameMorph skinAt: #turnCW ifAbsent: [^ self].
		m _ self firstSubmorph delete.
		self addMorphFront: (ImageMorph new form: f).
		self addMorphFront: m].

	#stopAll = selector ifTrue: [
		f _ ScratchFrameMorph skinAt: #stopButton ifAbsent: [^ self].
		self addMorphBack: (ImageMorph new form: f)].
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 6/15/2010 21:27'!
addLabel
	"Add a label for my command and arguments. This is the method that really creates the whole block."
	"Details: We remove all the pieces of this block, and then reassemble them, being careful not to destroy any argument morphs that we might still want to use. This is helpful if someone adds/removes parameters from a hat block."

	| tokens args nextArgIndex m next slot |

	commandSpec ifNil: [^ self].

	"we make sure not to remove the next block."
	next _ self nextBlock.
	self removeAllMorphsIn: (self submorphs reject: [:t | t = next]).

	tokens _ CommandBlockMorph parseCommandSpec: commandSpec.
	args _ tokens select: [:s | CommandBlockMorph isArgSpec: s].

	"remove any excess arg morphs from the list."
	[argMorphs size > args size] whileTrue: [
		m _ argMorphs last.
		argMorphs remove: m.

		"if the argument we're throwing out is anything complicated, we'd like to keep it around in the world."
		(m isKindOf: BlockMorph) ifTrue: [m openInWorld]].

	"create new arg morphs."
	[argMorphs size < args size] whileTrue: [
		argMorphs addLast: (self argMorphFor: (args at: argMorphs size + 1))].

	nextArgIndex _ 1.

	tokens do: [:s |
		(CommandBlockMorph isArgSpec: s)
			ifTrue:	[ "check if the arg type has changed (jens)"
				m _ argMorphs at: nextArgIndex.
				(m isKindOf: ArgMorph) ifTrue: [
					slot _ self uncoloredArgMorphFor: s.
					m class = slot class ifFalse: [
						m _ slot.
						argMorphs at: nextArgIndex put: m]].
				nextArgIndex _ nextArgIndex + 1]
			ifFalse:	[
				m _ self labelMorphFor: s].
		self addMorphBack: m].

	self isReporter ifTrue: [

		"attempt to embed ReporterScripts more gracefully. Has some issues, 
		commented out for now, (jens)"
		
		"self adjustReporterLayoutForLambda."
		
		m _ submorphs last.
		((m isKindOf: ChoiceArgMorph) | (m isKindOf: SpriteArgMorph)) ifTrue: [  "add spacer"
			self addMorphBack: (Morph new color: Color transparent; extent: 2@5)]].
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 3/22/2010 00:28'!
argMorphFor: specString
	"Answer an argument morph for the given argument specification string. Set it's color appropriately."

	| m |
	m _ self uncoloredArgMorphFor: specString.
	(m isKindOf: ColorArgMorph)
		ifTrue: [m color: Color random].
	^ m


! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jm 6/2/2009 22:03'!
argMorphToReplace: aMorph
	"Answer a new argument morph to be used to replace the given morph. Answer nil if the given morph is not one of my argMorphs."

	| i argSpecs spec argM defaults v |
	i _ argMorphs indexOf: aMorph ifAbsent: [^ nil].
	argSpecs _ (CommandBlockMorph parseCommandSpec: commandSpec) select: [:s | CommandBlockMorph isArgSpec: s].
	i > argSpecs size ifTrue: [^ nil].
	argM _ self argMorphFor: (argSpecs at: i).

	(#setVar:to: = selector and: [(argSpecs at: i) = '%n']) ifTrue: [
		^ argM stringExpression: '0'].
	spec _ ScriptableScratchMorph blockSpecDict at: selector ifAbsent: [^ argM].

	defaults _ receiver defaultArgsFor: spec.
	i <= defaults size ifTrue: [
		v _ defaults at: (argPermutation indexOf: i).
		(v isKindOf: String)
			ifTrue: [
				(argM isKindOf: ExpressionArgMorph)
					ifTrue: [argM defaultValueFromSpec: v localized]
					ifFalse: [argM defaultValue: v localized]]
			ifFalse: [argM defaultValue: v]].

	^ argM
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 2/23/2011 00:04'!
canBecomeWatcher
	"I determine which blocks can become watchers."

	| i |
	(#(	contentsOfList: 
		lambda: 
		doReport 
		listNamed: 
		newList:
		getTrue 
		getFalse 
		function 
		functionWithArgs
		copyOfList:
		doPauseThreadReporter
		asciiLetter:
		asciiCodeOf:
		getObject:
		getSpawnOf:
		spawn
		get:
	) includes: selector) ifTrue: [^false].

	i _ selector asString findAnySubStr: #('mouse' 'key' 'touching' 'distance') startingAt: 1.
	^ (self isReporter) &
	   (self argumentCount <= 1) &
	   ((#(not atRandom abs rounded lineCountOfList: stringLength:) includes: selector) not) &
	   (i > selector asString size)
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 4/6/2010 01:08'!
fixBlockLayout
	"Update the positions of my submorphs."

	self fixBlockLayoutWrap! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 6/23/2010 00:28'!
fixBlockLayoutNoWrap
	"Update the positions of my submorphs."

	| isFirst h x minXForArgs hAdjust nextB w oldPos oldExtent space |
	blockLayoutNeeded ifFalse: [^ self].
	space _ 4.
	self isCustomBlock ifTrue: [
		self isTemplate ifTrue: [ space _ 2 ]].
	super fixBlockLayout.
	oldPos _ self position.
	oldExtent _ self extent.
	hAdjust _ 4.

	isFirst _ true.
	h _ 14.  "minimum height"
	self nonControlFlowSubmorphs do: [:m |
		(m isKindOf: BlockMorph) ifTrue: [m fixBlockLayout].
		(m isKindOf: ArgMorph) ifTrue: [m fixArgLayout].
		(isFirst and: [(m isKindOf: StringMorph) not]) ifTrue: [
			"extra space when an arg overlaps with notch"
			h _ h max: m height + 3.
			hAdjust _ 1].
		isFirst _ false.
		((m isKindOf: CommandBlockMorph) and: [m isBlockTemplate])
			ifTrue: [h _ h max: (m height + 2)]
			ifFalse: [h _ h max: m height]].

	((self isKindOf: CBlockMorph) or: [self isKindOf: IfElseBlockMorph])
		ifTrue: [minXForArgs _ self left + PuzzleInset + PuzzleWidth + 8]
		ifFalse: [minXForArgs _ self left].

	h _ h + 10.
	self isReporter ifTrue: [h _ h - 2. hAdjust _ 2].
	self isStop ifTrue: [h _ h - 5. hAdjust _ 0].

	x _ self left + 5.
	self nonControlFlowSubmorphs do: [:m |
		(m isKindOf: StringMorph)
			ifTrue: [(m isKindOf: BlockLabelFragmentMorph) 
				ifFalse: [m color: self labelColor]]
			ifFalse: [x _ x max: minXForArgs].
		m position: x@(self top + (((h - hAdjust) - m height) // 2)).
		x _ x + m width + space].

	w _ (x - self left) max: 37.
	((self isKindOf: CBlockMorph) or:
	 [self isKindOf: IfElseBlockMorph])
		ifTrue: [w _ w max: 71].
	self extent: w @ h.
	ScratchTranslator isRTL ifTrue: [
		self left: oldPos x + (oldExtent x - self width)].

	(nextB _ self nextBlock) ifNotNil: [
		(self isKindOf: CBlockMorph) ifFalse: [
			ScratchTranslator isRTL
				ifTrue: [nextB position: (self right - nextB width)@(self bottom - 4)]
				ifFalse: [nextB position: self left@(self bottom - 4)]].
		nextB fixBlockLayout].
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 4/20/2010 22:14'!
labelColor
	"Answer a label color, either black or white, that maximizes the contrast with my color."

	(self class contrast = #strong and: [isContrasted])
		ifTrue: [^Color black].
	^ LabelColor
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 10/5/2010 11:45'!
labelMorphFor: aString

	| s |
	s _ aString.
	commandSpec isUnicode ifTrue: [s _ UTF8 withAll: s].
	^ (StringMorph contents: s font: (ScratchFrameMorph getFont: #Label))
		color: self labelColor
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jm 6/3/2009 16:38'!
mapReceiver: oldObj to: newObj
	"Used in cloning an object to make blocks that refererred to the original object new refer to the new copy."

	receiver == oldObj ifTrue: [receiver _ newObj].
	argMorphs do: [:arg |
		(arg isKindOf: CommandBlockMorph) ifTrue: [
			arg mapReceiver: oldObj to: newObj]].
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jm 8/31/2006 09:18'!
nextBlock
	"Answer the block following myself in the block sequence or nil if I am the last block in the sequence. Each block is a submorph of the previous block."

	^ self submorphs
		detect: [:m | (m isKindOf: BlockMorph) and: [(argMorphs includes: m) not]]
		ifNone: [nil]
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jm 3/23/2005 18:02'!
nextBlock: aBlock
	"Add the given block as the block following me. Delete old nextBlock, if any."

	self nextBlock ifNotNil: [self nextBlock delete].
	self addMorph: aBlock.
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jm 6/3/2008 15:48'!
parseCommandSpec
	"Answer an array of token strings containing my keywords and argument specs."

	| spec result len i j |
	result _ OrderedCollection new.
	spec _ commandSpec.
	(spec isKindOf: UTF8) ifTrue: [spec _ String withAll: spec].
	len _ commandSpec size.

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

	^ result asArray collect: [:s | s withBlanksTrimmed]
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jm 12/10/2005 11:04'!
printCodeOn: aStream indent: indent
	"Append a human-readable string for this block on the given stream."

	| nextB hasFinalSpace |
	indent timesRepeat: [aStream nextPutAll: '    '].
	nextB _ self nextBlock.
	hasFinalSpace _ false.
	submorphs do: [:m |
		m ~~ nextB ifTrue: [
			self printCodeSubmorph: m on: aStream.
			hasFinalSpace _ true.
			aStream space]].
	hasFinalSpace ifTrue: [aStream skip: -1].
	aStream cr.
	self nextBlock ifNotNil: [self nextBlock printCodeOn: aStream indent: indent].
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 1/20/2010 12:04'!
replaceArgMorph: oldMorph by: newMorph
	"Replace oldMorph with newMorph in my argMorphs and submorphs lists. This is done when dropping a reporter block onto one of my arguments."

	argMorphs _ argMorphs collect: [:m |
		m == oldMorph ifTrue: [newMorph] ifFalse: [m]].
	self replaceSubmorph: oldMorph by: newMorph.

	"attempt at a more graceful way to embed ReporterScripts,
	has some issues, commented out for now (jens) "

"
	(newMorph = argMorphs first and: [ 
		(newMorph isKindOf: ReporterScriptBlockMorph) or: [
			oldMorph isKindOf: ReporterScriptBlockMorph]]) ifTrue: [
			self addLabel].
"
	self layoutChanged.
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jens 6/28/2010 20:29'!
tabToNextField: evt
	"Move the keyboard focus to the next submorph that responds to keyboard events."

	| fields current |
	fields _ self topBlock tabFields "allMorphs select: [:m | m isKindOf: ExpressionArgMorph]".

	current _ (1 to: fields size) detect: [:i | (fields at: i) labelMorph == evt hand keyboardFocus] ifNone: [fields size].
	evt hand newKeyboardFocus: (fields at: (current \\ fields size) + 1) labelMorph.
! !

!CommandBlockMorph methodsFor: 'private' stamp: 'jm 3/15/2003 11:23'!
updateReferencesUsing: aDictionary
	"Update my arg morphs."

	super updateReferencesUsing: aDictionary.
	argMorphs _ argMorphs collect: [:m | aDictionary at: m ifAbsent: [m]].
! !


!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 1/6/2010 00:04'!
addArg: argMorph
	"private - only for graphical representation in BYOB"

		argMorphs add: argMorph.
		self addMorphBack: argMorph.
		self layoutChanged! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 1/17/2010 19:39'!
adjustReporterLayoutForLambda

	"this method must be called *after* #addLine has been completed (jens)"

	| lambdas distToLeft distToRight extra |

	distToLeft _ [:lambda |
			| edgeDist extraDist |
			edgeDist _ lambda left - self left.
			extraDist _ lambda height // 2.7 - edgeDist.
			extraDist > 0
				ifTrue: [extraDist]
				ifFalse: [0]].

	distToRight _ [:lambda |
			| edgeDist extraDist |
			edgeDist _ self right - lambda right.
			edgeDist > 0
				ifTrue: [extraDist _ lambda height // 2.7 - edgeDist]
				ifFalse: [extraDist _ extraDist abs + (lambda height // 2.7)].
			extraDist > 0
				ifTrue: [extraDist]
				ifFalse: [0]].
	
	lambdas _ argMorphs select:[:a |
			a isKindOf: CommandScriptBlockMorph ].

	lambdas do: [:l |
		extra _ distToLeft value: l.
		extra > 0 ifTrue: [
			self addMorphFront: (Morph new color: Color transparent; extent: extra@5)].
		extra _ distToRight value: l.
		extra > 0 ifTrue: [
			self addMorphBack: (Morph new color: Color transparent; extent: extra@5)]].

! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 4/15/2010 21:58'!
asLambda

	| lambda |
	lambda _ CommandScriptBlockMorph new
		receiver: ScriptableScratchMorph new;
		isSpecialForm: false;
		minArgs: 1;
		commandSpec: '.';
		selector: #procedure.
	lambda attachBlock: self.
	^ lambda evaluate! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 10/30/2009 11:29'!
blockWidth
	^self width! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 7/7/2010 00:16'!
drawBodyOn: aCanvas 

	| leftEdge middle rightEdge l m r cArgs relevant |

	leftEdge _ Array with: (self left@(self top + 2) corner: (self left + 2)@(self bottom - 7)).
	middle _ Array with: (self left@(self top + 5) corner: (self right - 1)@(self bottom - 7)).
	rightEdge _ Array with: ((self right - 1)@(self top + 3) corner: self right@(self bottom - 7)).

	cArgs _ self nonControlFlowSubmorphs select: [:s | 
		(s isKindOf: CArgSlotMorph) 
		or: [(s isKindOf: CReporterSlotMorph)
		or: [(s isKindOf: MultiArgMorph) 
			and: [#(loop reporterSlot) includes: s type]]]].

	cArgs do: [:c |
		relevant _ c bounds.
		(c isKindOf: MultiArgMorph) ifTrue: [
			relevant _ c transparentRect].

		l _ OrderedCollection new.
		leftEdge do: [:rect |
			l addAll: (rect areasOutside: relevant)].
		leftEdge _ l.

		m _ OrderedCollection new.
		middle do: [:rect |
			m addAll: (rect areasOutside: relevant)].
		middle _ m.
	
		r _ OrderedCollection new.
		rightEdge do: [:rect |
			r addAll: (rect areasOutside: relevant)].
		rightEdge _ r].


	leftEdge do: [:rect |
		aCanvas
			fillRectangle: rect
			color: highlightColor2].

	middle do: [:rect |
		aCanvas
			fillRectangle: rect
			color: color].

	rightEdge do: [:rect |
		aCanvas
			fillRectangle: rect
			color: shadowColor]
! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 7/21/2010 14:19'!
drawInlinePaletteOn: aCanvas

	| templates |
	templates _ submorphs select: [:m |
		(m isKindOf: ReporterBlockMorph)
		and: [m isBlockTemplate ]].


	templates do: [:t |
		aCanvas paintImage: ((t imageForm withOutlineColor: color width: 1) withRaisedOutlineColor: color width: 1) 
					at: t position - 2].

"
	argMorphs do: [:m |
		(#booleanslot = (self typeOfArg: m)
		and: [m isKindOf: ReporterBlockMorph]) ifTrue: [
			aCanvas paintImage: (m imageForm outlineHalfEmbeddedAdjustedColor: color) 
					at: m position - 1]]

"
! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 9/16/2010 02:58'!
fixBlockLayoutWrap
	"Update the positions of my submorphs."

	| parts lines line h x y minXForArgs nextB w space left maxX maxHeight mh |

	(self isCustomBlock and: [self isTemplate]) ifTrue: [^ self fixBlockLayoutNoWrap].
	blockLayoutNeeded ifFalse: [^ self].

	cachedForm _ nil.
	cachedFeedbackForm _ nil.

	parts _ self nonControlFlowSubmorphs.
	lines _ OrderedCollection new.


	"distribute parts horizontally and cut up into lines"

	line _ OrderedCollection new.
	x _ self left + 5.
	left _ x.
	maxX _ x.
	minXForArgs _ self left.
	space _ 4.

	parts do: [:m |
	((m isKindOf: CArgSlotMorph) or: [(m isKindOf: CReporterSlotMorph) or: [(m isKindOf: MultiArgMorph) and: [m isWrapping]]])
		ifTrue: [ 
			line isEmpty ifFalse: [
				lines add: line].
			m left: "self" left.
			lines add: (OrderedCollection with: m).
			(m isKindOf: MultiArgMorph)
				ifTrue: [m fixArgLayout]
				ifFalse: [m fixBlockLayout].
			((m isKindOf: CArgSlotMorph) or: [m isKindOf: CReporterSlotMorph])
				ifTrue: [m width: 40].
			line _ OrderedCollection new.
			maxX _ maxX max: left + m width.
			x _ left ]
		ifFalse: [
			x - left > 400 ifTrue: [
				lines add: line.
				line _ OrderedCollection new.
				x _ left].
			(m isKindOf: BlockMorph) ifTrue: [m fixBlockLayout].
			(m isKindOf: ArgMorph) ifTrue: [m fixArgLayout].
			(m isKindOf: StringMorph)
				ifTrue: [m color: self labelColor]
				ifFalse: [x _ x max: minXForArgs].

			m left: x.
			(m fullBounds right - left > 400 and: [line isEmpty not])
				ifTrue: [
					lines add: line.
					line _ OrderedCollection new.
					m left: left.
					line add: m.
					x _ left]
				ifFalse: [ line add: m].
				x _ x + m fullBounds width + space.
			maxX _ maxX max: x]].
	x = left ifFalse: [
		lines add: line].
	w _ maxX - self left max: 37.

	"distribute lines vertically"

	space _ 2.
	y _ self top + 2 "4" "space".
	lines do: [:eachLine |
		maxHeight _ 14.
		eachLine do: [:m |
			((m isKindOf: ReporterBlockMorph)
			and: [m isBlockTemplate 
			or: [((m isKindOf: CArgSlotMorph) or: [m isKindOf: OSlotMorph]) and: [m isEmptySlot not]]])
				ifTrue: [ m == eachLine first
					ifTrue: [mh _  m height + 10]
					ifFalse: [mh _ m height + 5]]
				ifFalse: [ ((m isKindOf: CArgSlotMorph) or: [m isKindOf: OSlotMorph])
					ifTrue: [mh _ m height + 5]
					ifFalse: [mh _ m height]].
			maxHeight _ mh max: maxHeight.
			((m isKindOf: CArgSlotMorph) or: [m isKindOf: CReporterSlotMorph]) ifTrue: [
				maxHeight _ m height - 4]].
		eachLine do: [:m |
			m top: y + (maxHeight - m height // 2) + 1].
		y _ y + maxHeight + space].

	"adjust CArgSlots"

	parts do: [:m |
		((m isKindOf: CArgSlotMorph) or: [m isKindOf: CReporterSlotMorph])
			ifTrue: [m width: w - 5]].

	self isStop
		ifTrue: [h _ y - self top + space]
		ifFalse: [h _ y - self top + space + 4.].

	parts size > 0 ifTrue: [
		((parts last isKindOf: CArgSlotMorph) or: [(parts last isKindOf: CReporterSlotMorph)]) ifTrue: [
			h _ h + space + 5]].
	
	self extent: w @ h.

	"adjust Multi-CArgSlots"

	parts do: [:m | (m isKindOf: MultiArgMorph)
		ifTrue: [m loopsWidth: w - 5]].

	(nextB _ self nextBlock) ifNotNil: [
		nextB position: self left@(self bottom - 4).
		nextB fixBlockLayout].
! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 4/20/2010 00:41'!
isCShape

	^ (argMorphs detect: [:am | 
		am isKindOf: CArgSlotMorph] ifNone: [nil]) notNil! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 5/19/2010 01:28'!
isMaxNestedAt: int
	"kludge-alert!!"

	(receiver isKindOf: VariableFrame)
		ifFalse: [^ false].
	^ receiver isMaxNestedAt: int + 1
! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 4/20/2010 02:44'!
nests: aCommandBlock

	| cslots |
	cslots _ argMorphs select: [:am | am isKindOf: CArgSlotMorph].
	cslots do: [:cs |
		cs nestedBlock ifNotNil: [
			(cs nestedBlock blockSequence includes: aCommandBlock)
				ifTrue: [^ true]]].
	^ false
! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'JM 11/22/2011 15:22'!
rcvr
	"answer a String description of my receiver which can be used in a tuple"

	| rcvr |
	(receiver isKindOf: ScriptableScratchMorph)
		ifTrue: [(receiver isKindOf: ScratchStageMorph)
			ifTrue: [rcvr _ 'Canvas']
			ifFalse: [rcvr _ receiver objName]]
		ifFalse: [ rcvr _ '' ].
	^rcvr
! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 7/18/2010 23:17'!
references: obj
	"kludge-alert: answer true if any part of me contains a reference to obj"

	(receiver isKindOf: VariableFrame)
		ifFalse: [^ false].
	^ receiver references: obj! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 2/8/2011 13:29'!
rightButtonMenu

	| menu sFrame choice spec |
	menu _ CustomMenu new.
	menu add: 'help' action: #presentHelpScreen.

	(owner isKindOf: ScratchBlockPaletteMorph) ifFalse: [
		menu addLine.
		(#(+ - * / \\) includes: selector) ifTrue: [
			#(+ - * / mod) with: #(+ - * / \\) do: [:s :op | menu add: s action: op]].
		(#(< = >) includes: selector) ifTrue: [
			#(< = >) do: [:op | menu add: op action: op]].
		(#(& |) includes: selector) ifTrue: [
			#(and or) with: #(& |) do: [:s :op | menu add: s action: op]].

		menu addLine.
		menu add: 'duplicate' action: #duplicate.
		(self isKindOf: ReporterBlockMorph) ifFalse: [
			menu add: '- this block' action: #fastDuplicate].
		(self isKindOf: VariableBlockMorph) ifTrue: [
			menu add: 'relabel' action: #rename].
		(self owner isKindOf: BlockMorph) ifFalse: [  "can't yet delete a blocks inside a script"
			menu add: 'delete' action: #delete]].

	menu addLine.

	self isInheritableAttribute ifTrue: [
		self isDeletedAttribute 
			ifTrue: [menu add: 'disinherit' action: #disinheritAttribute]
			ifFalse: [menu add: 'inherit' action: #inheritAttribute]].
	
	menu add: 'edit elements' action: #editElements.

	sFrame _ self ownerThatIsA: ScratchFrameMorph.
	(sFrame notNil and: [#(sensor: sensorPressed:) includes: selector]) ifTrue: [
		menu addLine.
		menu add: 'show ScratchBoard watcher' action: #showSensorBoard.
		sFrame workPane scratchServer
			ifNil: [menu add: 'enable remote sensor connections' action: #enableRemoteSensors]
			ifNotNil: [menu add: 'disable remote sensor connections' action: #exitScratchSession]].

	DebugMenu ifTrue: [
		menu addLine.
		menu add: 'show tuples' action: #showTuples].
	
	(choice _ menu localize; startUp) ifNil: [^ self].
	(#(presentHelpScreen duplicate fastDuplicate rename delete editElements inheritAttribute disinheritAttribute) includes: choice) ifTrue: [^ self perform: choice].
	choice = #showSensorBoard ifTrue: [sFrame showSensorBoard. ^ self].
	choice = #enableRemoteSensors ifTrue: [sFrame enableRemoteSensors. ^ self].
	choice = #exitScratchSession ifTrue: [sFrame exitScratchSession. ^ self].
	choice = #showTuples ifTrue: [^ self showTuples].

	"change operator"
	spec _ '%n ', choice, ' %n'.
	'\\' = choice	ifTrue: [spec _ ScratchTranslator translationFor: '%n mod %n'].
	'&' = choice	ifTrue: [spec _ ScratchTranslator translationFor: '%b and %b'].
	'|' = choice	ifTrue: [spec _ ScratchTranslator translationFor: '%b or %b'].

	self commandSpec: spec.
	self selector: choice.
! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 2/3/2010 01:31'!
scratchObject

	| be sm sf so |
	be _ self ownerThatIsA: BlockEditorFrameMorph.
	be isNil
		ifTrue: [
			sm _ self ownerThatIsA: ScratchScriptsMorph.
			sf _ self ownerThatIsA: ScratchFrameMorph.
			sm isNil | sf isNil ifTrue: [^ nil].
			so _ sf scratchObjects detect: [:obj | obj blocksBin = sm] ifNone: [sf workPane]]
		ifFalse: [so _ be template receiver].
	^so! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 9/22/2010 02:29'!
scriptVars
	"private - answer the names of all script variables reachable by myself"

	| blockVars o be |

	blockVars _ Set new.
	o _ owner.
	[ (o isKindOf: BlockMorph) or: [o isKindOf: ArgMorph]] whileTrue: [
		o isLambdaForm ifTrue: [
			blockVars addAll: o allVarNames ].
		(o isKindOf: VariableDeclarationBlockMorph) ifTrue: [
			blockVars addAll: o variables ].
		(o isKindOf: ProcedureHatBlockMorph) ifTrue: [
			blockVars addAll: o argMorph allVarNames ].
		(o isKindOf: ReporterBlockDropTargetMorph)
			ifTrue: [
				be _ o ownerThatIsA: BlockEditorFrameMorph.
				blockVars addAll: be template allVarNames.
				o _ be hat bottomBlock.
				(o isKindOf: VariableDeclarationBlockMorph) ifTrue: [
					blockVars addAll: o variables ].
				(o isKindOf: ProcedureHatBlockMorph) ifTrue: [
					blockVars addAll: o argMorph allVarNames ]].
		o _ o owner].
	^blockVars! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 8/2/2010 22:42'!
start

	| stage rcvr |
	self stop.
	self receiver ifNil: [^ self].
	scratchProc ifNotNil: [^ self].  "this stack is already running"

	rcvr _ self receiver.
	(rcvr isKindOf: ScriptableScratchMorph)
		ifTrue: [ (stage _ rcvr ownerThatIsA: ScratchStageMorph) ifNil: [^ self]]
		ifFalse: [stage _ (self ownerThatIsA: ScratchFrameMorph) workPane].	

	scratchProc _ stage startProcessFor: self.
	self changed.
! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 8/3/2010 10:33'!
stopFrame
	^ stopFrame! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 8/3/2010 13:02'!
stopFrame: aFrame

		stopFrame _ aFrame! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 6/28/2010 20:33'!
tabToPreviousField: evt
	"Move the keyboard focus to the previous submorph that responds to keyboard events."

	| fields current |
	fields _ self topBlock tabFields  " allMorphs select: [:m | m isKindOf: ExpressionArgMorph]".

	current _ (1 to: fields size) detect: [:i | (fields at: i) labelMorph == evt hand keyboardFocus] ifNone: [fields size].
	evt hand newKeyboardFocus: (fields at: ((current - 1 \\ fields size) max: 1)) labelMorph.

! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 7/23/2010 01:17'!
typeOfArg: aMorph
	"answer a symbol representing the type of my argument morph being aMorph"

	| idx tokens args spec specs |
	idx _ argMorphs indexOf: aMorph.
	tokens _ CommandBlockMorph parseCommandSpec: commandSpec.
	args _ tokens select: [:s | CommandBlockMorph isArgSpec: s].
	args size < idx ifTrue: [^ #any].
	spec _ args at: idx.
	'%s' = spec ifTrue: [^#any].

	specs _ Dictionary new.
	specs
		at: #command put: '%o';
		at: #commandList put: '%O';
		at: #reporter put: '%r';
		at: #repoerterList put: '%R';
		at: #predicate put: '%p';
		at: #predicateList put: '%P';
		at: #list put: '%t';
		at: #listList put: '%u';
		at: #text put: '%T';
		at: #textList put: '%U';
		at: #any put: '%s';
		at: #anyList put:  '%X';
		at: #boolean put: '%b';
		at: #booleanList put: '%V';
		at: #number put: '%n';
		at: #numberList put: '%w';
		at: #template put: '%z';
		at: #booleanslot put: '%Y';
		at: #unevaluated put: '%j';
		at: #unevaluatedList put: '%q';
		at: #loop put: '%G';
		at: #unevaluatedBoolean put: '%Q';
		at: #unevaluatedBooleanList put: '%K'.

	specs keysDo: [:t |
		spec = (specs at: t) ifTrue: [^t]].
	^#any! !

!CommandBlockMorph methodsFor: 'byob' stamp: 'jens 6/22/2010 20:33'!
varNamesMenu

	| blockVars objVars obj | 

	obj _ self scratchObject.
	obj ifNil: [^#()].
	blockVars _ self scriptVars asSortedCollection asArray.
	objVars _ obj varNamesMenu asOrderedCollection.
	objVars removeAll: blockVars.

	(#(
		doRun
		doRunBlockWithArgs
		doFork
		doForkBlockWithArgs
		doReport
		doCallBlockWithArgs
	) includes: selector )	
		ifTrue: [ ^ (objVars copyWith: #-), blockVars, #('')].

	^ (objVars copyWith: #-), blockVars! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CommandBlockMorph class
	instanceVariableNames: ''!

!CommandBlockMorph class methodsFor: 'utilities' stamp: 'ee 3/28/2009 20:07'!
argPermutationForSpec: spec withTranslation: translatedSpec
	"CommandBlockMorph argPermutationForSpec: '%a of %m of %m of %t' withTranslation: '%a de %m de %m de %t'"
	"CommandBlockMorph argPermutationForSpec: '%a of %m of %m of %t' withTranslation: '%t de %m2 de %m1 de %a'"

	| parsedSpec parsedTranslatedSpec parsedSpecArgs parsedTranslatedSpecArgs permutation a copiesSize n originalPermutation |

	parsedSpec _ CommandBlockMorph parseCommandSpec: spec.
	parsedSpecArgs _ parsedSpec select: [:s | CommandBlockMorph isArgSpec: s].
	parsedTranslatedSpec _ CommandBlockMorph parseCommandSpec: translatedSpec.
	parsedTranslatedSpecArgs _ parsedTranslatedSpec select: [:s | CommandBlockMorph isArgSpec: s].

	permutation _ #().
	1 to: parsedSpecArgs size do: [:i | permutation _ permutation copyWith: i].
	originalPermutation _ permutation.

	"no change"
	(parsedSpecArgs = parsedTranslatedSpecArgs) ifTrue: [
			^ originalPermutation].

	"otherwise, calculate permutation"
	1 to: parsedSpecArgs size do: [:i |
		a _ parsedSpecArgs at: i.
		copiesSize _ (parsedSpecArgs select: [:s | (s = a)]) size.
		(copiesSize = 1)
			ifTrue:[permutation at: i put: (parsedTranslatedSpecArgs indexOf: a
				ifAbsent: [Transcript show: 'Permutation failed: ', spec.
						^ originalPermutation])]
			ifFalse:["count copies until now"
				n _ ((parsedSpecArgs copyFrom: 1 to: i) select: [:s | (s = a)]) size.
				permutation at: i put: (parsedTranslatedSpecArgs indexOf: (a,n asString)
					ifAbsent: [Transcript show: 'Permutation failed: ', spec.
						^ originalPermutation])]].
	^ permutation
! !

!CommandBlockMorph class methodsFor: 'utilities' stamp: 'ee 2/28/2009 13:39'!
isArgSpec: aString
	"Answer true if the given string is an argument specification."

	^ ((aString size > 1) and: [aString first = $%])
! !

!CommandBlockMorph class methodsFor: 'utilities' stamp: 'jens 2/14/2011 00:13'!
parseCommandSpec: aCommandSpec
	"Answer an array of token strings containing my keywords and argument specs."

	| result len i j spec k |
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
					ifTrue: [k _ j + 1.
						((spec at: k) isLetter | (spec at: k) isDigit)	"added Digits for BYOB slots -Jens"
							ifTrue: [[(k+1 <= len) and: [(spec at: k+1) isDigit]] whileTrue:[
								k _ k + 1].
								(k >= len)
									ifTrue: [result addLast: (spec copyFrom: j to: len).
										i _ len + 1]
									ifFalse: [result addLast: (spec copyFrom: j to: k).
										i _ k+1]]
							ifFalse: [result addLast: '%'.
										i _ j + 1]]
					ifFalse: [result addLast: '%'.
						i _ j + 2]]
			ifFalse: [
				result addLast: (spec copyFrom: i to: len).
				i _ len + 1]].

	result _ result select: [:s | s ~= ' '].
	^ result asArray collect: [:s | s withBlanksTrimmed]
! !
