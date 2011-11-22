Object subclass: #VariableFrame
	instanceVariableNames: 'vars '
	classVariableNames: 'ScopeContrast '
	poolDictionaries: ''
	category: 'Scratch-BYOB'!

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 12/17/2009 23:12'!
add: varName
	vars at: varName put: 0

! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 1/27/2010 01:44'!
changeVar: varName by: increment
	"Change the value of the given variable of this object by the given amount."

	|  n |
	n _ vars at: varName asString ifAbsent: [^ self].
	self setVar: varName to: n asNumberNoError + increment asNumberNoError.
! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 1/27/2011 01:23'!
convertStacksToTuples

	| obj isCyclic |
	vars keysDo: [:key |
		obj _ vars at: key. 
		(obj isKindOf: ScriptableScratchMorph)
			ifTrue: [ vars at: key put: obj asReferenceTuple ]
			ifFalse: [
			(obj respondsTo: #convertStacksToTuples) ifTrue: [		"this must be a list or another variable"
				obj convertStacksToTuples ].
			(obj respondsTo: #asBlockTuple) ifTrue: [ 				"this must be a block"

				isCyclic _ obj allMorphs anySatisfy: [ :m |
					(m isKindOf: SetterBlockMorph) | (m isKindOf: VariableBlockMorph) and: [
						m receiver == self or: [(m receiver isKindOf: self class) and: [m receiver isReferencing: self]] ]].
				isCyclic
					ifTrue: [ obj receiver: nil]
					ifFalse: [ vars at: key put: obj asBlockTuple ]]]]

! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'JM 11/22/2011 15:24'!
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

	| obj stage rcvr block |

	stage _ ScratchFrameMorph someInstance workPane.

	vars keysDo: [:key |
		obj _ vars at: key.

		(obj isKindOf: Array) ifTrue: [

			obj second = 'Canvas'
				ifTrue: [rcvr _ stage ]
				ifFalse: [rcvr _ stage coerceSpriteArg: obj second ].

			#block = obj first ifTrue: [
				block _ stage stackFromTupleList: obj third receiver: rcvr.
				vars at: key put: block ].

			#namedList = obj first ifTrue: [
				vars at: key put: (stage listNamed: obj third targetName: obj second)].

			#variableList = obj first ifTrue: [
				vars at: key put: (stage listInVarNamed: obj third targetName: obj second)].

			#stage = obj first ifTrue: [
				vars at: key put: stage].	

			#sprite = obj first ifTrue: [
				vars at: key put: (stage coerceSpriteArg: obj second)]].

		(obj isKindOf: ScratchListMorph) ifTrue: [
			obj convertTuplesToStacks ]]! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 12/16/2009 00:52'!
fieldsVersion

	^ 1
! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 9/25/2008 10:25'!
forNames: aCollectionOfStrings
	aCollectionOfStrings do:[:eachVarName |
		vars at: eachVarName put: 0 ]! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 1/26/2010 22:56'!
getVar: varName
	"Answer the value of the given user variable of this object, or 0 if the variable has been deleted."

	^ vars at: varName asString ifAbsent: [0]
! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 3/28/2011 00:21'!
getVar: varName block: aVariableBlockMorph
	"Answer the value of the given user variable of this object, or 0 if the variable has been deleted."

	^ vars at: varName asString ifAbsent: [0]
! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 12/16/2009 00:55'!
initFieldsFrom: anObjStream version: classVersion
	"Set my instance variables from the given object stream."

	self initFieldsNamed: #(
		vars
	) from: anObjStream.
! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 9/25/2008 10:23'!
initialize
	super initialize.
	vars _ Dictionary new.! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 6/13/2009 20:00'!
interpretStringAsNumberIfPossible: anObject
	"If the argument is a string that can be interpreted as a number, such as '123', then return it's value as a number. Otherwise, return the original object."

	| s digits hasDigit |
	(anObject isKindOf: String) ifFalse: [^ anObject].
	anObject size = 0 ifTrue: [^ anObject].

	(anObject first isKindOf: Character)
		ifTrue: [s _ ReadStream on: anObject asByteArray]
		ifFalse: [s _ ReadStream on: anObject].

	"see if the string can be parsed as a Scratch number:"
	digits _ '0123456789' asByteArray.
	hasDigit _ false.
	(s atEnd not and: [s peek = $- asciiValue]) ifTrue: [s next].
	[s atEnd not and: [digits includes: s peek]] whileTrue: [hasDigit _ true. s next].
	(s atEnd not and: [s peek = $. asciiValue]) ifTrue: [s next].
	[s atEnd not and: [digits includes: s peek]] whileTrue: [hasDigit _ true. s next].

	(s atEnd and: [hasDigit])
		ifTrue: [^ anObject asNumberNoError]
		ifFalse: [^ anObject].

! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 5/19/2010 01:34'!
isMaxNestedAt: int
	"kludge-alert!!"

	vars do: [:each |
		(each respondsTo: #isMaxNestedAt:)
			ifTrue: [ (each isMaxNestedAt: int + 1)
				ifTrue: [^ true]]].
	^ false! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 6/30/2010 22:35'!
isReferencing: aVarFrame

	| obj |
	
	vars keysDo: [:key |
		obj _ vars at: key. 
		(obj isKindOf: BlockMorph) ifTrue: [
			(obj allMorphs anySatisfy: [ :m |
				(m isKindOf: SetterBlockMorph) | (m isKindOf: VariableBlockMorph) and: [
					m receiver == aVarFrame or: [
						(m receiver isKindOf: self class) and: [
							m receiver isReferencing: aVarFrame]]]])
				ifTrue: [^ true]].
		(obj isKindOf: ScratchListMorph) ifTrue: [
			(obj asArray anySatisfy: [ :item |
				(item isKindOf: SetterBlockMorph) | (item isKindOf: VariableBlockMorph) and: [
					item receiver == aVarFrame or: [
						(item receiver isKindOf: self class) and: [
							item receiver isReferencing: aVarFrame]]]])]].
	^ false

! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 7/27/2010 17:16'!
references: obj
	"kludge-alert: answer true if any part of me contains a reference to obj"

	vars do: [:each |
		each == obj ifTrue: [^ true].
		(each respondsTo: #references:)
			ifTrue: [ (each references: obj)
				ifTrue: [^ true]]].
	^ false! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 12/17/2009 23:08'!
remove: varName
	vars removeKey: varName! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 5/12/2010 19:08'!
renameVar: old to: new

	| value |
	(vars includesKey: old)
		ifTrue: [ 
			value _ vars at: old.
			self remove: old]
		ifFalse: [ value _ 0 ].
	vars at: new put: value! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 1/27/2010 01:26'!
scope

	^self varNamesMenu! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 8/2/2010 16:55'!
setVar: varName to: newValue
	"Set the value of the given variable of this object to the given value."

"	|  v |
	v _ self interpretStringAsNumberIfPossible: newValue."

	vars at: varName put: newValue.
! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 12/16/2009 00:54'!
storeFieldsOn: anObjStream

	self storeFieldsNamed: #(
		vars
	) on: anObjStream.

! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 12/18/2009 00:45'!
varNamesMenu
	^vars keys asSortedCollection asArray! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 8/2/2010 22:49'!
variableBlockColor

	^ self class variableBlockColor! !

!VariableFrame methodsFor: 'as yet unclassified' stamp: 'jens 5/20/2010 22:53'!
vars
	"private"
	^ vars! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VariableFrame class
	instanceVariableNames: ''!

!VariableFrame class methodsFor: 'as yet unclassified' stamp: 'jens 9/25/2008 10:26'!
forNames: aCollection
	^self new forNames: aCollection! !

!VariableFrame class methodsFor: 'as yet unclassified' stamp: 'jens 8/2/2010 23:12'!
initialize

	"VariableFrame initialize"

	super initialize.
	ScopeContrast _ false.! !

!VariableFrame class methodsFor: 'as yet unclassified' stamp: 'jens 5/18/2010 23:46'!
maxNestingDepth
	"kludge alert!!"

	^ 100! !

!VariableFrame class methodsFor: 'as yet unclassified' stamp: 'jens 8/2/2010 23:21'!
scopeContrast

	^ ScopeContrast! !

!VariableFrame class methodsFor: 'as yet unclassified' stamp: 'jens 8/2/2010 23:12'!
scopeContrast: bool

	ScopeContrast _ bool! !

!VariableFrame class methodsFor: 'as yet unclassified' stamp: 'jens 8/3/2010 13:26'!
variableBlockColor

	ScopeContrast
		ifTrue: [^ (Color brown darker mixed: 0.8 with: Color orange) lighter]
		ifFalse: [^ ScriptableScratchMorph blockColorFor: 'variables']
	
! !


VariableFrame initialize!
