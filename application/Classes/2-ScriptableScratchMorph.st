Morph subclass: #ScriptableScratchMorph
	instanceVariableNames: 'objName vars lists blocksBin isClone media costume costumeChangeMSecs filterPack visibility volume tempoBPM sceneStates customBlocks deletedAttributes '
	classVariableNames: 'BlockColorDict BlockSpecDict DefaultBackgroundForm DefaultSpriteForm DoubleSize Experimental KeepOnStage ListBlockColor MeowSound ObjEncoding OldMeowPrefixReversed PopSound RandomGen Recorder ScratchOrigin TimerStartMSecs '
	poolDictionaries: ''
	category: 'Scratch-Objects'!
!ScriptableScratchMorph commentStamp: '<historical>' prior: 0!
I am the superclass of all scriptable Scratch morphs.

Scriptable morphs:
  1. allow the user to add user-defined scripts
  2. allow the user to add user-defined variables
  3. when they are copied, their scripts and variables are copied;
     thereafter, script changes to the original and the copy are entirely independent
  4. can be exported and imported into another Scratch project.
!


!ScriptableScratchMorph methodsFor: 'initialization' stamp: 'jens 1/25/2010 22:33'!
initialize

	super initialize.
	temporaryVariables _ VariableFrame new.
	objName _ self nextInstanceName.
	vars _ Dictionary new.
	lists _ Dictionary new.
	blocksBin _ ScratchScriptsMorph new.
	isClone _ false.
	costume _ self defaultImageMedia.
	media _ OrderedCollection new.
	costumeChangeMSecs _ 0.
	visibility _ 100.
	volume _ 100.
	tempoBPM _ 60.
	sceneStates _ Dictionary new.
! !


!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 8/2/2004 20:42'!
costume

	^ costume
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 11/30/2004 16:52'!
costumeChangeMSecs
	"Answer the time of the last costume change. Whenever a costume change (or a filter change) occurs, this value is updated from the current millisecond clock. This value is used to optimize redrawing of thumbnails--if costumeChangeMSecs hasn't changed since the last time the thumbnail was updated we don't need to compute a new thumbnail."

	^ costumeChangeMSecs
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 12/9/2005 16:33'!
costumeForm
	"Answer my current costume form, without filtering, rotation or scaling. If my costume is a movie or animation, answer the appropriate frame."

	^ costume compositeForm
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 10/31/2006 12:28'!
filteredForm

	filterPack ifNil: [^ self rotatedForm].

	filterPack filtersActive ifTrue: [  "filter parameters have changed; apply filters"
		ScratchFrameMorph useErrorCatcher
			ifTrue: [[filterPack applyFiltersTo: self rotatedForm]
						ifError: [filterPack _ nil. ^ self rotatedForm]]
			ifFalse: [filterPack applyFiltersTo: self rotatedForm]].
	^ filterPack resultForm
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 5/3/2004 14:00'!
form
	"Answer my current costume form, without filtering, rotation, or scaling."

	^ self costumeForm
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jens 2/23/2011 22:16'!
form: aForm

	costume _ (ImageMedia new form: aForm).
	costume mediaName: (self unusedMediaNameFromBaseName: 'costume').
	media addLast: costume.
	self costumeChanged.
	self updateMediaCategory.

	self undeleteAttribute: #costumes.
	self propagateCostumes
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 1/8/2006 18:38'!
imageForm
	"Answer a Form showing myself for the purpose of generating a thumbnail."

	^ self filteredForm copy offset: 0@0
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 5/6/2009 17:39'!
inPresentationMode

	^ (self ownerThatIsA: OffscreenWorldMorph) notNil
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 6/9/2004 09:29'!
isClone

	^ false
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 5/10/2004 19:46'!
isClone: aBoolean
	"Ignored here. Overridden by my subclasses."! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 4/30/2004 19:05'!
isColorable

	^ false
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 3/2/2003 12:14'!
isScriptable
	"I am a scriptable Scratch object."

	^ true
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 7/3/2008 15:14'!
isSprite

	^ false
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 6/2/2009 11:43'!
isVisible

	^ self isHidden not and: [visibility > 0]
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 5/8/2005 11:44'!
media

	^ media
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jens 2/21/2011 23:45'!
objName

	^ objName
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 5/11/2009 11:06'!
objName: aString

	"don't allow renaming a sprite to use a name already in use"
	(self spriteNameInUse: aString) ifTrue: [^ self].
	objName _ aString.
	objName size = 0 ifTrue: [objName _ self nextInstanceName].
! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'md 11/8/2004 16:39'!
renewFilterPack

	filterPack _ FilterPack new.! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 1/8/2006 18:41'!
rotatedForm
	"By default, just return my costume form. Sprites override this method to do rotation."

	^ self costumeForm

! !

!ScriptableScratchMorph methodsFor: 'accessing' stamp: 'jm 5/9/2005 09:05'!
rotationCenter: aPoint
	"Set my costume's rotation center."

	costume rotationCenter: aPoint.
	self costumeChanged.
! !


!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 7/10/2004 09:55'!
changeCostumeIndexBy: aNumber
	"Change my costume index by the given amount."

	self costumeIndex: self costumeIndex + aNumber.
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jens 2/9/2011 16:07'!
changeGraphicEffect: effect by: aNumber
	"Change the given graphic effect by the given value."


	'blur' = effect ifTrue: [self blurEffect: self blurEffect + aNumber asNumberNoError].
	'brightness' = effect ifTrue: [self brightnessEffect: self brightnessEffect + aNumber asNumberNoError].
	'fisheye' = effect ifTrue: [self fisheyeEffect: self fisheyeEffect + aNumber asNumberNoError].
	'color' = effect ifTrue: [self colorEffect: self colorEffect + aNumber asNumberNoError].
	'mosaic' = effect ifTrue: [self mosaicEffect: self mosaicEffect + aNumber asNumberNoError].
	'pixelate' = effect ifTrue: [self pixelateEffect: self pixelateEffect + aNumber asNumberNoError].

"
	'pointillize' = effect ifTrue: [filterPack pointillizeSize: filterPack pointillizeSize + aNumber asNumberNoError].
	'saturation' = effect ifTrue: [filterPack saturationShift: filterPack saturationShift + aNumber asNumberNoError].
"
	('transparency' = effect) | ('ghost' = effect) ifTrue: [
		self transparencyEffect: self transparencyEffect + aNumber asNumberNoError].

"
	'water ripple' = effect ifTrue: [filterPack waterRippleRate: filterPack waterRippleRate + aNumber asNumberNoError].
"
	'whirl' = effect ifTrue: [self whirlEffect: self whirlEffect + aNumber asNumberNoError].


"
	filterPack ifNil: [filterPack _ FilterPack new].

	'blur' = effect ifTrue: [filterPack blur: filterPack blur + aNumber].
	'brightness' = effect ifTrue: [filterPack brightnessShift: filterPack brightnessShift + aNumber].
	'fisheye' = effect ifTrue: [filterPack fisheye: filterPack fisheye + aNumber].
	'color' = effect ifTrue: [filterPack hueShift: filterPack hueShift + aNumber].
	'mosaic' = effect ifTrue: [filterPack mosaicCount: filterPack mosaicCount + aNumber].
	'pixelate' = effect ifTrue: [filterPack pixelateCount: filterPack pixelateCount + aNumber].
	'pointillize' = effect ifTrue: [filterPack pointillizeSize: filterPack pointillizeSize + aNumber].
	'saturation' = effect ifTrue: [filterPack saturationShift: filterPack saturationShift + aNumber].
	('transparency' = effect) | ('ghost' = effect) ifTrue: [
		self transparency: self transparency + aNumber].
	'water ripple' = effect ifTrue: [filterPack waterRippleRate: filterPack waterRippleRate + aNumber].
	'whirl' = effect ifTrue: [filterPack whirl: filterPack whirl + aNumber].

	costumeChangeMSecs _ Time millisecondClockValue.
	self changed.
	self spread
"! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 2/18/2008 11:23'!
changeVisibilityBy: delta
	"Obsolete. Do nothing."
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jens 3/15/2011 00:05'!
costumeFromName: aString
	"If there is a costume by the given name, return it. Otherwise, return nil."

	| cameraCostume |
	((aString = '*** camera ***') and:
	 [CameraPlugin cameraIsAvailable]) ifTrue: [
		cameraCostume _ CameraMedia new.
		(self class = ScratchStageMorph) ifTrue: [cameraCostume frameExtent: self extent].
		^ cameraCostume].

	^ media
		detect: [:el | el isSound not and: [el mediaName = aString or: [el mediaName = aString asMacRoman]]]
		ifNone: [nil]
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jens 2/8/2011 22:37'!
costumeIndex
	"Answer the index of my current costume."

	| att |
	att _ #costumeIndex.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ (media reject: [:m | m isSound])
		indexOf: costume ifAbsent: [1]
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 7/10/2004 09:59'!
costumeIndex: aNumber
	"Set my costume to the costume at the given index modulo my total number of costumes. Costumes are numbered starting at 1."

	| cList i newC |
	cList _ media reject: [:m | m isSound].
	cList size = 0 ifTrue: [^ self].  "should never happen..."
	i _ ((aNumber rounded - 1) \\ cList size) + 1.
	newC _ cList at: i.
	costume == newC ifFalse: [self lookLike: newC mediaName].
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 4/30/2007 22:00'!
costumeNameFromNumber: aNumber
	"Return a costume name for the given number--rounded and modulo the number of costumes."

	| costumeList i |
	costumeList _ media reject: [:m | m isSound].
	costumeList size = 0 ifTrue: [^ 'costume'].

	i _ ((aNumber rounded - 1) \\ costumeList size) + 1.
	^ (costumeList at: i) mediaName
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jens 2/9/2011 16:20'!
filterReset

	filterPack _ nil.
	self transparency: 0.
	self costumeChanged.
	self spread.

	self
		colorEffect: 0;
		fisheyeEffect: 0;
		whirlEffect: 0;
		pixelateEffect: 0;
		mosaicEffect: 0;
		brightnessEffect: 0;
		transparencyEffect: 0! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 9/25/2007 11:48'!
graphicEffectNames
	"Answer a collection of graphic effect names."

	^ #(
		'color'
		'fisheye'
		'whirl'
		'pixelate'
		'mosaic'
		'brightness'
		'ghost')
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jens 3/15/2011 00:07'!
lookLike: costumeNameOrIndex
	"Change to the costume indicated by the given name, index, or boolean. Noop if there is no costume of the given name in my library."
	"Note: Costumes can have names that look like numbers, but those numbers have nothing to do with the index of the costume. So, we first try interpreting the argument as a name. If that fails, we try interpreting it as a costume index number."

	| p newCostume i |
	p _ self referencePosition.
	costume suspendPlaying.

	newCostume _ nil.
	(costumeNameOrIndex isKindOf: String) ifTrue: [
		"try interpreting the argument as a costume name"
		newCostume _ self costumeFromName: costumeNameOrIndex.

		"try interpreting the string as a number"
		newCostume ifNil: [
			i _ self interpretStringAsNumberIfPossible: costumeNameOrIndex.
			i isNumber ifTrue: [
				newCostume _ self costumeFromName: (self costumeNameFromNumber: i)]
				ifFalse: [^ self]]].  "string does not match a costume and cannot be coverted to a number"

	"treat other types (number, boolean) as a costume index"
	newCostume ifNil: [
		i _ costumeNameOrIndex asNumberNoError.
		newCostume _ self costumeFromName: (self costumeNameFromNumber: i)].

	newCostume ifNil: [^ self].  "should not happen..."

	costume _ newCostume.
	(self isKindOf: ScratchSpriteMorph) ifTrue: [
		self setSizeTo: self scale ].		"adjust the size if it is really huge or tiny.-jens"
	costume resumePlaying.
	self costumeChanged.
	self referencePosition: p.
	World displayWorldSafely.
!
]style[(28 1275 86 101)f1b,f1,f1cred;,f1! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jens 2/8/2011 22:54'!
nextCostume
	"Show the next costume in my costumes list."

	self lookLike: self costumeIndex + 1.

"
	self costumeIndex: self costumeIndex + 1.
"! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 4/4/2005 13:14'!
penDown
	"Overriden by sprites."

	^ false
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 5/19/2009 12:56'!
sayNothing
	"Default behavior does nothing. Overridden in ScratchSpriteMorph."
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'nb 1/7/2008 12:02'!
sceneNames

	^ (self ownerThatIsA: ScratchStageMorph) sceneNames
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jens 2/9/2011 14:14'!
setGraphicEffect: effect to: aNumber
	"Set the given graphic effect to the given value."

	'blur' = effect ifTrue: [self blurEffect: aNumber].
	'brightness' = effect ifTrue: [self brightnessEffect: aNumber].
	'fisheye' = effect ifTrue: [self fisheyeEffect: aNumber].
	'color' = effect ifTrue: [self colorEffect: aNumber].
	'mosaic' = effect ifTrue: [self mosaicEffect: aNumber].
	'pixelate' = effect ifTrue: [self pixelateEffect: aNumber].
	'pointillize' = effect ifTrue: [self pointillizeEffect: aNumber].
	'saturation' = effect ifTrue: [self saturationEffect: aNumber].
	('transparency' = effect) | ('ghost' = effect) ifTrue: [self transparencyEffect: aNumber].
	'water ripple' = effect ifTrue: [self waterRippleEffect: aNumber].
	'whirl' = effect ifTrue: [self whirlEffect: aNumber].
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 2/18/2008 11:23'!
setVisibilityTo: percent
	"Obsolete. Do nothing."
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 5/22/2005 22:46'!
transparency
	"Answer my transparency. 0 is opaque; 100 is transparent."

	^ 100 - self visibility
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 5/23/2005 08:54'!
transparency: aNumber
	"Set my transparency. 0 is opaque; 100 is transparent."

	self visibility: (100 - aNumber abs).
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 8/2/2006 18:10'!
visibility
	"Answer my visibility. 0 is invisible. 100 is fully opaque."

	^ visibility
! !

!ScriptableScratchMorph methodsFor: 'looks ops' stamp: 'jm 2/18/2008 11:19'!
visibility: aNumber
	"Set my visibility. 0 is invisible. 100 is fully opaque."

	visibility _ (aNumber max: 0) min: 100.
	self changed.
! !


!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 12/2/2007 22:13'!
changeTempoBy: aNumber

	self setTempoTo: self tempo + aNumber.
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 9/24/2007 17:05'!
changeVolumeBy: aNumber

	self setVolumeTo: volume + aNumber.
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 5/3/2008 09:18'!
drum: midiKey duration: beats elapsed: elapsedMSecs from: aNotePlayer

	| stage player |
	aNotePlayer ifNil: [  "first call, start playing the drum"
		(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ ScratchNotePlayer new].
		(player _ stage notePlayerFor: self) ifNil: [^ ScratchNotePlayer new].
		^ player copy drumOn: midiKey].

	elapsedMSecs >= ((60000 * beats) // self tempo) ifTrue: [aNotePlayer drumOff].
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 6/3/2009 18:47'!
midiDrumMenu
	"Provides a drop-down menu for setting the drum number."

	| menu |
	menu _ CustomMenu new.
	#(	('Acoustic Bass Drum' 35)
		('Bass Drum 1' 36)
		('Side Stick' 37)
		('Acoustic Snare' 38)
		('Hand Clap' 39)
		('Electric Snare' 40)
		('Low Floor Tom' 41)
		('Closed Hi-Hat' 42)
		('High Floor Tom' 43)
		('Pedal Hi-Hat' 44)
		('Low Tom' 45)
		('Open Hi-Hat' 46)
		('Low-Mid Tom' 47)
		('Hi-Mid Tom' 48)
		('Crash Cymbal 1' 49)
		('High Tom' 50)
		('Ride Cymbal 1' 51)
		('Chinese Cymbal' 52)
		('Ride Bell' 53)
		('Tambourine' 54)
		('Splash Cymbal' 55)
		('Cowbell' 56)
		('Crash Cymbal 2' 57)
		('Vibraslap' 58)
		('Ride Cymbal 2' 59)
		('Hi Bongo' 60)
		('Low Bongo' 61)
		('Mute Hi Conga' 62)
		('Open Hi Conga' 63)
		('Low Conga' 64)
		('High Timbale' 65)
		('Low Timbale' 66)
		('High Agogo' 67)
		('Low Agogo' 68)
		('Cabasa' 69)
		('Maracas' 70)
		('Short Whistle' 71)
		('Long Whistle' 72)
		('Short Guiro' 73)
		('Long Guiro' 74)
		('Claves' 75)
		('Hi Wood Block' 76)
		('Low Wood Block' 77)
		('Mute Cuica' 78)
		('Open Cuica' 79)
		('Mute Triangle' 80)
		('Open Triangle' 81)
	) do: [:pair |
		menu
			add: (self numberInParens: pair second), (pair first localizedMIDI)
			action: pair second].
	^ menu
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 3/2/2009 13:02'!
midiInstrument: aNumber
	"Old 'set instrument to _' block. Set the MIDI instrument used for note sounds."

	| stage player |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ self].
	(player _ stage notePlayerFor: self) ifNotNil: [
		player instrument: aNumber].
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 6/3/2009 18:34'!
midiInstrumentMenu
	"Provides a drop-down menu for setting the instrument number."

	| menu |
	menu _ CustomMenu new.
	#(	('Acoustic Grand' 1)
		('Bright Acoustic' 2)
		('Electric Grand' 3)
		('Honky-Tonk' 4)
		('Electric Piano 1' 5)
		('Electric Piano 2' 6)
		('Harpsichord' 7)
		('Clavinet' 8)
		('Celesta' 9)
		('Glockenspiel' 10)
		('Music Box' 11)
		('Vibraphone' 12)
		('Marimba' 13)
		('Xylophone' 14)
		('Tubular Bells' 15)
		('Dulcimer' 16)
		('Drawbar Organ' 17)
		('Percussive Organ' 18)
		('Rock Organ' 19)
		('Church Organ' 20)
		('Reed Organ' 21)
		('Accordion' 22)
		('Harmonica' 23)
		('Tango Accordion' 24)
		('Nylon String Guitar' 25)
		('Steel String Guitar' 26)
		('Electric Jazz Guitar' 27)
		('Electric Clean Guitar' 28)
		('Electric Muted Guitar' 29)
		('Overdriven Guitar' 30)
		('Distortion Guitar' 31)
		('Guitar Harmonics' 32)
		('Acoustic Bass' 33)
		('Electric Bass (finger)' 34)
		('Electric Bass (pick)' 35)
		('Fretless Bass' 36)
		('Slap Bass 1' 37)
		('Slap Bass 2' 38)
		('Synth Bass 1' 39)
		('Synth Bass 2' 40)
		('Violin' 41)
		('Viola' 42)
		('Cello' 43)
		('Contrabass' 44)
		('Tremolo Strings' 45)
		('Pizzicato Strings' 46)
		('Orchestral Strings' 47)
		('Timpani' 48)
		('String Ensemble 1' 49)
		('String Ensemble 2' 50)
		('SynthStrings 1' 51)
		('SynthStrings 2' 52)
		('Choir Aahs' 53)
		('Voice Oohs' 54)
		('Synth Voice' 55)
		('Orchestra Hit' 56)
		('Trumpet' 57)
		('Trombone' 58)
		('Tuba' 59)
		('Muted Trumpet' 60)
		('French Horn' 61)
		('Brass Section' 62)
		('SynthBrass 1' 63)
		('SynthBrass 2' 64)
		('Soprano Sax' 65)
		('Alto Sax' 66)
		('Tenor Sax' 67)
		('Baritone Sax' 68)
		('Oboe' 69)
		('English Horn' 70)
		('Bassoon' 71)
		('Clarinet' 72)
		('Piccolo' 73)
		('Flute' 74)
		('Recorder' 75)
		('Pan Flute' 76)
		('Blown Bottle' 77)
		('Shakuhachi' 78)
		('Whistle' 79)
		('Ocarina' 80)
		('Lead 1 (square)' 81)
		('Lead 2 (sawtooth)' 82)
		('Lead 3 (calliope)' 83)
		('Lead 4 (chiff)' 84)
		('Lead 5 (charang)' 85)
		('Lead 6 (voice)' 86)
		('Lead 7 (fifths)' 87)
		('Lead 8 (bass+lead)' 88)
		('Pad 1 (new age)' 89)
		('Pad 2 (warm)' 90)
		('Pad 3 (polysynth)' 91)
		('Pad 4 (choir)' 92)
		('Pad 5 (bowed)' 93)
		('Pad 6 (metallic)' 94)
		('Pad 7 (halo)' 95)
		('Pad 8 (sweep)' 96)
		('FX 1 (rain)' 97)
		('FX 2 (soundtrack)' 98)
		('FX 3 (crystal)' 99)
		('FX 4 (atmosphere)' 100)
		('FX 5 (brightness)' 101)
		('FX 6 (goblins)' 102)
		('FX 7 (echoes)' 103)
		('FX 8 (sci-fi)' 104)
		('Sitar' 105)
		('Banjo' 106)
		('Shamisen' 107)
		('Koto' 108)
		('Kalimba' 109)
		('Bagpipe' 110)
		('Fiddle' 111)
		('Shanai' 112)
		('Tinkle Bell' 113)
		('Agogo' 114)
		('Steel Drums' 115)
		('Woodblock' 116)
		('Taiko Drum' 117)
		('Melodic Tom' 118)
		('Synth Drum' 119)
		('Reverse Cymbal' 120)
		('Guitar Fret Noise' 121)
		('Breath Noise' 122)
		('Seashore' 123)
		('Bird Tweet' 124)
		('Telephone Ring' 125)
		('Helicopter' 126)
		('Applause' 127)
		('Gunshot' 128)
	) do: [:pair |
		menu
			add: (self numberInParens: pair second), pair first localizedMIDI
			action: pair second].
	^ menu
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 12/31/2005 12:48'!
midiNoteMenu
	"Provides a drop-down menu for setting the note number."

	| menu midiKey noteName |
	menu _ CustomMenu new.
	midiKey _ 48.
	#(low middle) do: [:oct |
		#(C 'C#' D 'Eb' E F 'F#' G 'Ab' A 'Bb' B) do: [:n |
			n = #C
				ifTrue: [noteName _ oct, ' ', n]
				ifFalse: [noteName _ n].
			menu
				add: '(', midiKey printString, ') ', noteName
				action: midiKey.
			midiKey _ midiKey + 1]].
		menu add: '(72) high C' action: 72.
	^ menu
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 5/3/2008 09:17'!
noteOn: midiKey duration: beats elapsed: elapsedMSecs from: aNotePlayer

	| stage player |
	aNotePlayer ifNil: [  "first call, start playing the note"
		(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ ScratchNotePlayer new].
		(player _ stage notePlayerFor: self) ifNil: [^ ScratchNotePlayer new].
		^ player copy noteOn: midiKey].

	elapsedMSecs >= ((60000 * beats) // self tempo) ifTrue: [aNotePlayer noteOff].
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 5/3/2008 09:19'!
noteSelector
	"Returns an instance of a ScratchNoteSelector for selecting notes. This object behaves like a CustomMenu."

	| stageMorph notePlayer |
	stageMorph _ (self ownerThatIsA: ScratchStageMorph).
	stageMorph ifNil: [^ self midiNoteMenu].
	notePlayer _ stageMorph notePlayerFor: self.
	notePlayer ifNil: [^ self midiNoteMenu].

	^ ScratchNoteSelector new setNotePlayer: notePlayer
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 6/3/2009 18:45'!
numberInParens: aNumber

	^ (UTF32 with: 16r200E) asUTF8, '(' asUTF8, aNumber printString, ') '
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 5/20/2006 12:37'!
playMidi: fileName
	"Play the midi file with the given name."

	| fname score player |
	fname _ fileName, '.mid'.
	(FileDirectory default fileExists: fname) ifFalse: [^ self].
	score _ (MIDIFileReader scoreFromFileNamed: fname).
	player _ ScorePlayer onScore: score.
	player openMIDIPort: 0.
	player play.
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 5/5/2007 16:49'!
playSound: soundName

	| snd |
	snd _ self soundNamed: soundName ifAbsent: [^ self].
	snd playFromStart.
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 12/4/2007 17:45'!
rest: duration elapsed: elapsed from: ignored
	"Do nothing; just wait for the time interval to elapse."

	^ nil
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 5/5/2007 16:50'!
rewindSound: soundName
	"Rewind the given sound."

	| snd |
	snd _ self soundNamed: soundName ifAbsent: [^ self].
	snd rewindSound.
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 3/19/2009 14:22'!
setInstrument: aNumber
	"New 'set instrument to _' block. Set the instrument used for note sounds. Testing in beta but reverted."

	| stage map n player |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ self].
	map _ #(1 30 25 35).
	n _ aNumber asNumberNoError asInteger.
	(n between: 1 and: map size)
		ifTrue: [n _ map at: n]
		ifFalse: [n _ 1].
	(player _ stage notePlayerFor: self) ifNotNil: [
		player instrument: n].
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 6/3/2009 18:47'!
setInstrumentMenu
	"Provides a drop-down menu for setting the instrument number."

	| menu |
	menu _ CustomMenu new.
	#(	('Piano' 1)
		('Electric Guitar' 2)
		('Acoustic Guiar' 3)
		('Bass' 4)
	) do: [:pair |
		menu
			add: (self numberInParens: pair second), (pair first localizedMIDI)
			action: pair second].
	^ menu
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 11/28/2007 12:56'!
setTempoTo: aNumber

	| stage |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ self].
	stage setTempoTo: aNumber.
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jens 2/8/2011 23:28'!
setVolumeTo: aNumber

	self undeleteAttribute: #volume.
	self passiveSetVolumeTo: aNumber
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 8/10/2008 12:14'!
soundFromIndex: aNumber
	"Return a sound for the given number--rounded and modulo the number of costumes. Return nil if there are not sounds."

	| soundList i |
	soundList _ media select: [:m | m isSound].
	soundList size = 0 ifTrue: [^ nil].

	i _ ((aNumber rounded - 1) \\ soundList size) + 1.
	^ soundList at: i
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 8/10/2008 12:25'!
soundNamed: soundNameOrIndex ifAbsent: absentBlock
	"Return a SoundMedia with the given name (ignoring case differences) or index. If there is none, return the result of evaluating the given block."

	| snd i |
	snd _ nil.
	(soundNameOrIndex isKindOf: String) ifTrue: [ "first, try using the argument as a sound name"
		snd _ media
			detect: [:el | el isSound and: [el mediaName caseInsensitiveEqual: soundNameOrIndex]]
			ifNone: [nil].

		snd ifNil: [
			i _ self interpretStringAsNumberIfPossible: soundNameOrIndex.
			i isNumber ifTrue: [
				snd _ self soundFromIndex: i]].

		snd ifNil: [^ absentBlock value]].

	snd ifNil: [snd _ self soundFromIndex: soundNameOrIndex asNumberNoError].

	snd
		ifNil: [^ absentBlock value]
		ifNotNil: [^ snd]

! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jm 11/27/2007 11:28'!
tempo

	| stage |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ 60].
	^ stage tempo
! !

!ScriptableScratchMorph methodsFor: 'sound ops' stamp: 'jens 2/8/2011 23:26'!
volume

	| att |
	att _ #volume.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ volume
! !


!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 2/11/2009 09:48'!
answer

	^ ScratchPrompterMorph lastAnswer
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 10/25/2007 20:33'!
asciiFor: keyName

	| localizedKey |
	keyName size = 1 ifTrue: [^ keyName first asciiValue].

	localizedKey _ keyName localized.
	'space' localized = localizedKey ifTrue: [^ Character space asciiValue].
	'enter' localized = localizedKey ifTrue: [^ Character cr asciiValue].
	'up arrow' localized = localizedKey ifTrue: [^ 30].
	'down arrow' localized = localizedKey ifTrue: [^ 31].
	'right arrow' localized = localizedKey ifTrue: [^ 29].
	'left arrow' localized = localizedKey ifTrue: [^ 28].

	"needed to support old projects:"
	'up' = keyName ifTrue: [^ 30].
	'down' = keyName ifTrue: [^ 31].
	'right' = keyName ifTrue: [^ 29].
	'left' = keyName ifTrue: [^ 28].

	^ -1  "no match; should never happen"
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 10/2/2007 17:48'!
attributeNames

	^ vars keys
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 6/8/2009 10:36'!
coerceSpriteArg: anObject
	"Coerce the given object to a sprite reference if necessary. If it is a Symbol (e.g. #mouse), just return it. If it is a String, try to find a Sprite with that name. If it is a Number, coerce it to a string and look for a Sprite with a matching name."

	| s targetName |
	(anObject isKindOf: ScriptableScratchMorph) ifTrue: [^ anObject].
	(anObject isKindOf: Symbol) ifTrue: [^ anObject].

	targetName _ anObject isNumber ifTrue: [anObject printString] ifFalse: [anObject].

	(s _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ nil].
	s submorphsDo: [:m |
		((m isKindOf: ScriptableScratchMorph) and:
		 [targetName = m objName])
			ifTrue: [^ m]].

	^ nil

! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jens 11/30/2009 00:18'!
getAttribute: attr
	"Answer the value of my variable or built-in attribute with the given name. Answer zero if I have no attribute or variable with the given name."

	(vars includesKey: attr) ifTrue: [^ vars at: attr].
	^ 0
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jens 4/19/2011 17:16'!
getAttribute: attr of: anObject
	"Answer the variable or built-in attribute value for the given sprite. Answer zero if the given sprite does not have a built-in attribute or variable of the given name."

	| aSpriteOrStage |
	aSpriteOrStage _ self coerceSpriteArg: anObject.
	(aSpriteOrStage isKindOf: ScriptableScratchMorph) ifFalse: [^ 0].
"	^ aSpriteOrStage getAttribute: attr asString"
	^ aSpriteOrStage attribute: attr

! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'ee 11/10/2007 19:20'!
hookupBooleanSensorNames

	^ #(
		'button pressed'
		'connected'
	)
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'ee 6/2/2009 16:29'!
hookupSensorNames

	| sensorNames stage virtualSensors |
	sensorNames _ #(
		'slider'
		'light'
		'sound'
		'resistance'
	).

	sensorNames _ sensorNames, #('-' 'tilt' 'distance'). "WeDo sensors"

	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		stage scratchServer ifNotNil: [
			virtualSensors _ stage scratchServer sensorNames.
			virtualSensors size > 0 ifTrue: [
				^ sensorNames, {'-'}, stage scratchServer sensorNames]]].

	^ sensorNames
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 11/20/2006 12:15'!
hookupSensorNumber
	"Backwards compatibility for old blocks."

	^ (1 to: 8) collect: [:n | n printString]
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 4/11/2007 10:50'!
indexForSensorName: sensorName
	"Answer the index for the given sensor name."

	sensorName startsWithDigit ifTrue: [^ sensorName asNumberNoError].

	'slider' = sensorName		ifTrue: [^ 1].
	'light' = sensorName			ifTrue: [^ 2].
	'sound' = sensorName		ifTrue: [^ 3].
	(sensorName includesSubString: 'button') ifTrue: [^ 4].
	(sensorName includes: $A)	ifTrue: [^ 5].
	(sensorName includes: $B)	ifTrue: [^ 6].
	(sensorName includes: $C)	ifTrue: [^ 7].
	(sensorName includes: $D)	ifTrue: [^ 8].

	^ 1
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 5/12/2006 09:28'!
isLoud

	^ self class soundRecorder meterLevel > 30
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'ee 4/8/2008 12:27'!
keyNames
	"Key names for 'key pressed' block menu. Must keep this list in sync with asciiFor:."

	^ #('up arrow' 'down arrow' 'right arrow' 'left arrow' 'space'),
	   ($a to: $z), ($0 to: $9)
		 collect: [:ch | ch asString]
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 10/19/2006 07:57'!
keyPressed: keyName

	| ch |
	ch _ self asciiFor: keyName.
	(Sensor keyPressed: ch) ifTrue: [^ true].

	"if key is a letter, check the opposite case"
	(ch between: $a asciiValue and: $z asciiValue) ifTrue: [
		^ Sensor keyPressed: ch - 32].
	(ch between: $A asciiValue and: $Z asciiValue) ifTrue: [
		^ Sensor keyPressed: ch + 32].

	^ false
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 8/23/2003 12:22'!
mousePressed

	^ Sensor redButtonPressed
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 5/6/2009 17:45'!
mouseX

	| s centerX |
	DoubleSize ifTrue: [^ (Sensor cursorPoint x - ScratchOrigin x) // 2].

	self inPresentationMode ifFalse: [
		s _ self ownerThatIsA: ScratchStageMorph.
		(s notNil and: [s isQuarterSize]) ifTrue: [
			centerX _ s left + (s width // 4).
			^ 2 * (Sensor cursorPoint x - centerX)]].

	^ Sensor cursorPoint x - ScratchOrigin x
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 5/6/2009 17:45'!
mouseY

	| s centerY |
	DoubleSize ifTrue: [^ (Sensor cursorPoint y - ScratchOrigin y) negated // 2].

	self inPresentationMode ifFalse: [
		s _ self ownerThatIsA: ScratchStageMorph.
		(s notNil and: [s isQuarterSize]) ifTrue: [
			centerY _ s top + (s height // 4).
			^ -2 * (Sensor cursorPoint y - centerY)]].

	^ (Sensor cursorPoint y - ScratchOrigin y) negated
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jens 3/23/2010 00:02'!
promptForInput: questionString

	| s prompter |
	(s _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ self].
	prompter _ ScratchPrompterMorph new.
	((self isKindOf: ScratchStageMorph) | (self isHidden))
		ifTrue: [
			prompter question: questionString]
		ifFalse: [
			self showQuestion: questionString.
			prompter sprite: self].

	prompter left: s center x - (prompter width // 2).
	prompter bottom: s bottom - 5.
	prompter isSticky: true.

	s addMorphFront: prompter.
	prompter grabKeyboardFocus.
	World doOneCycle.
	^ prompter

	! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 3/24/2009 16:55'!
promptInProgress

	| s |
	(s _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ false].
	s submorphsDo: [:m |
		(m isKindOf: ScratchPrompterMorph) ifTrue: [^ true]].
	^ false
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 3/23/2009 15:28'!
sensor: sensorName
	"Answer the value of the given sensor, or zero if the sensorboard is not available."

	| stage v sb |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ 0].
	stage scratchServer ifNotNil: [
		v _ stage scratchServer sensorValueFor: sensorName.
		v ifNotNil: [^ v]].

	'tilt' = sensorName ifTrue: [^ WeDoPlugin tilt].
	'distance' = sensorName ifTrue: [^ WeDoPlugin distance].

	sb _ stage sensorBoard.
	sb tryToOpenPort ifFalse: [^ 0].  "could not open"
	^ sb sensor: (self indexForSensorName: sensorName)
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 11/20/2006 12:11'!
sensorPressed: sensorName
	"Answer true if a button connected to the given input of the sensor board is pressed. That is, if the sensor value is less than 10. Answer false if the sensor board cannot be opened."

	| stage sb |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ false].
	sb _ stage sensorBoard.
	sb tryToOpenPort ifFalse: [^ false].  "could not open"
	^ (sb sensor: (self indexForSensorName: sensorName)) < 10
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jens 3/22/2010 01:19'!
soundLevel

	^ self class soundRecorder meterLevel
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 10/19/2003 09:26'!
timer

	| now |
	now _ Time millisecondClockValue.
	TimerStartMSecs ifNil: [TimerStartMSecs _ now].
	TimerStartMSecs > now ifTrue: [TimerStartMSecs _ now].
	^ (now - TimerStartMSecs) asFloat / 1000.0
! !

!ScriptableScratchMorph methodsFor: 'sensing ops' stamp: 'jm 10/19/2003 09:20'!
timerReset

	TimerStartMSecs _ Time millisecondClockValue.
! !


!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'ee 6/27/2008 17:46'!
addGlobalList

	| sFrame listName |
	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self beep].

	listName _ StringDialog ask: 'List name?'.
	listName size = 0 ifTrue: [^ self].
	sFrame workPane createListNamed: listName.
	sFrame viewerPane categoryChanged: 'variables'.
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'ee 6/27/2008 17:44'!
addList

	| sFrame result listName |
	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self beep].

	result _ NewVariableDialog ask: 'List name?'.
	result = #cancelled ifTrue: [^ self].
	listName _ result first.
	result second
		ifTrue: [self createListNamed: listName]
		ifFalse: [sFrame workPane createListNamed: listName].
	sFrame viewerPane categoryChanged: 'variables'.
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 8/4/2010 01:37'!
append: anObject toList: listName

	| list |

	(listName isKindOf: ScratchListMorph)
		ifTrue: [list _ listName]
		ifFalse: [list _ self listNamed: listName ifNone: [^ 0]].
	list insertLine: (self asListElement: anObject) at: (list lineCount + 1)

! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 1/19/2011 23:47'!
asListElement: anObject
	"Answer the given object converted to an object suitable for storing in a list."

	(anObject isKindOf: ScriptableScratchMorph) ifTrue: [^ anObject].
	(anObject isKindOf: BlockMorph) ifTrue: [^ anObject].
	(anObject isKindOf: ScratchListMorph) ifTrue: [^ anObject].
	(anObject isKindOf: String) ifTrue: [^ anObject].
	anObject isUnicode ifTrue: [^ anObject].
	(anObject isKindOf: Character) ifTrue: [^ anObject asString].

	(anObject isKindOf: Boolean) ifTrue: [
		^ anObject].

"
	(anObject isKindOf: Boolean) ifTrue: [
		^ anObject ifTrue: ['1'] ifFalse: ['0']].
"

	^ anObject printString

! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 2/3/2010 00:13'!
blockFromSpec: spec color: blockColor
	"Create a block from the given block specification. Answer nil if I don't implement the block spec selector."

	| blockLabelSpec blockType selector defaultArgs block rcvr argPermutation |
	blockLabelSpec _ ScratchTranslator translationFor: (spec at: 1).
	argPermutation _ CommandBlockMorph argPermutationForSpec: (spec at: 1) withTranslation: blockLabelSpec.
	blockType _ spec at: 2.
	selector _ (spec at: 3) asSymbol.
	defaultArgs _ self defaultArgsFor: spec.

	(#(E K M S W) includes: blockType) ifTrue: [
		^ (self hatBlockType: blockType) color: blockColor].

	"basic block type: normal or C-shaped"
	(blockType includes: $c)
		ifTrue:	[
			selector = #doIfElse
				ifTrue: [block _ IfElseBlockMorph new isSpecialForm: true]
				ifFalse: [block _ CBlockMorph new isSpecialForm: true]]
		ifFalse:	[
			(blockType includes: $q) | (blockType includes: $Q)
				ifTrue: [ (blockType includes: $Q)
					ifTrue: [ block _ ReporterScriptBlockMorph new minArgs: 1 ]
					ifFalse: [ block _ CommandScriptBlockMorph new ].
					block isSpecialForm: false]
				ifFalse: [
					(blockType includes: $r) | (blockType includes: $b) | (blockType includes: $R)
						ifTrue: [block _ ReporterBlockMorph new]
						ifFalse: [
							(blockType includes: $d)
								ifTrue: [
									block _ MultiArgReporterBlockMorph new.
									(#(doCallBlockWithArgs doReport) includes: selector) ifTrue: [
										block minArgs: 1]]
								ifFalse: [ (blockType includes: $u)
									ifTrue: [
										block _ MultiArgCommandBlockMorph new.
										block minArgs: 1]
									ifFalse: [block _ CommandBlockMorph new]]]]].

	(blockType includes: $b) ifTrue: [block isBoolean: true].
	(blockType includes: $s) 
		| (blockType includes: $R) 
		| (blockType includes: $d) 
		| (blockType includes: $u) 
			ifTrue: [block isSpecialForm: true].
	(blockType includes: $t) ifTrue: [block isTimed: true].

	(ScriptableScratchMorph isSpriteSpecificTarget: self selector: selector)
		ifTrue: [rcvr _ self]
		ifFalse: [rcvr _ self ownerThatIsA: ScratchStageMorph].

	^ block
		argPermutation: argPermutation;
		color: blockColor;
		selector: selector;
		commandSpec: blockLabelSpec;
		defaultArgs: defaultArgs;
		receiver: rcvr
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 5/1/2008 10:51'!
contentsOfList: listName

	| list |
	list _ self listNamed: listName ifNone: [^ ''].
	^ list concatenatedLines
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'ee 8/7/2008 21:12'!
createListNamed: listName

	| list stage n |
	(self variableNameInUse: listName) ifTrue: [
		self beep.
		DialogBoxMorph warn: 'That variable name is already in use'.
		^ self].

	lists at: listName put: (list _ ScratchListMorph new listName: listName target: self).
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		n _ (stage submorphs select: [:m | m isKindOf: ScratchListMorph]) size.
		stage addMorph: (list position: stage topRight - ((list width + 10)@0) + (0@(10+(20*n)))).
		list startStepping].
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 5/1/2008 11:38'!
defaultListName

	| stage |
	lists size > 0 ifTrue: [^ lists keys asArray sort first].

	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		stage lists size > 0 ifTrue: [^ stage lists keys asArray sort first]].

	^ ''
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 6/20/2008 11:14'!
deleteLine: lineNum ofList: listName

	| list |
	list _ self listNamed: listName ifNone: [^ self].
	lineNum = 'all' ifTrue: [list clear. ^ self].
	list deleteLineAt: (self lineNum: lineNum forList: list)
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 5/12/2010 00:48'!
deleteList
	"Ask the user which list variable to delete, then remove it."

	| sFrame stage menu choice |
	sFrame _ self ownerThatIsA: ScratchFrameMorph.
	sFrame ifNil: [^ self].

	stage _ sFrame workPane.
	(stage listVarNames isEmpty) & (self listVarNames isEmpty)
		ifTrue: [^ self inform: 'No lists.' localized].

	menu _ CustomMenu new.
	stage listVarNames do: [:v | menu add: v asMacRoman action: (Array with: v with: #global)].
	self = stage ifFalse: [
		stage listVarNames isEmpty ifFalse: [menu addLine].
		self listVarNames do: [:v | menu add: v asMacRoman action: (Array with: v with: #local)]].
	choice _ menu startUp.
	choice ifNil: [^ self].

	choice second = #global
		ifTrue: [stage deleteList: choice first]
		ifFalse: [self deleteList: choice first].

	sFrame viewerPane categoryChanged: 'variables'.
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 1/18/2011 23:47'!
deleteList: listName
	"Delete the list variable with the given name. Do nothing if the variable doesn't exist."

	| stage |
	stage _ self ownerThatIsA: ScratchStageMorph.
	lists removeKey: listName asString ifAbsent: [].
	(self prototype notNil and: [self prototype lists includesKey: listName]) ifFalse: [ 
	stage submorphs do: [:m |
		((m isKindOf: ScratchListMorph) and: 
		[(m listName = listName) and: 
		[m target = self]])
			ifTrue: [m delete]]].
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 6/22/2010 23:45'!
getLine: lineNum ofList: listName

	| list |

	(listName isKindOf: ScratchListMorph)
		ifTrue: [list _ listName ]
		ifFalse: [ list _ self listNamed: listName ifNone: [^ '']].
	^ list lineAt: (self lineNum: lineNum forList: list)
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 6/29/2010 12:07'!
insert: anObject at: lineNum ofList: listName

	| list i |

	list _ self listNamed: listName ifNone: [^ self].
	i _ self lineNum: lineNum forList: list.
	#last = lineNum ifTrue: [i _ list lineCount + 1].
	list insertLine: (self asListElement: anObject) at: i.

! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 5/1/2008 11:18'!
lineCountOfList: listName

	| list |
	list _ self listNamed: listName ifNone: [^ 0].
	^ list lineCount
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 7/30/2008 16:26'!
lineNum: lineNum forList: list

	| s |
	lineNum isNumber ifTrue: [^ lineNum asInteger].

	s _ lineNum.
	s isUnicode ifTrue: [s _ String withAll: lineNum].
	(s isKindOf: String) ifTrue: [
		#first = s ifTrue: [^ 1].
		#last = s ifTrue: [^ list lineCount].
		#any = s ifTrue: [
			list lineCount = 0 ifTrue: [^ 1].
			^ (1 to: list lineCount) atRandom].
		^ s asNumberNoError].
	^ 0
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 1/28/2009 10:20'!
list: listName contains: anObject

	| list |
	list _ self listNamed: listName ifNone: [^ false].
	^ list contains: anObject
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 8/10/2008 14:33'!
listIndexForDeleteMenu

	| menu |
	menu _ CustomMenu new.
	#('1' last) do: [:s | menu add: s action: s].
	menu addLine.
	menu add: #all action: #all.
	menu localize.
	^ menu
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 8/10/2008 14:31'!
listIndexMenu

	| menu |
	menu _ CustomMenu new.
	#('1' last any) do: [:s | menu add: s action: s].
	menu localize.
	^ menu
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 11/3/2009 00:53'!
listNamed: aString

	^ self listNamed: aString ifNone: [nil]! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 1/18/2011 23:52'!
listNamed: aString ifNone: aBlock
	"Answer a list with the given name. First check the local list variables, otherwise check the global list variables and the prototype. If there is no list variable with the given name, return the result of evaluating the given block."

	| result stage |
	(aString isKindOf: ScratchListMorph)
		ifTrue: [^aString ].
	(result _ lists at: aString ifAbsent: [nil]) ifNotNil: [^ result].

	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		(result _ stage lists at: aString ifAbsent: [nil]) ifNotNil: [^ result]].

	self prototype ifNotNil: [^ self prototype listNamed: aString ifNone: aBlock].

	^ aBlock value


! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 1/19/2011 00:00'!
listVarMenu
	"Answer a menu for selecting a list variables."

	| result stage |
	result _ #().
	((stage _ self ownerThatIsA: ScratchStageMorph) notNil & (stage ~= self)) ifTrue: [
		result _ stage listVarNames].

	self listVarNames size > 0 ifTrue: [
		result size > 0 ifTrue: [result _ result copyWith: '-'].
		result _ result, self listVarNames].

	result size > 0
		ifTrue: [^ #(''), result]
		ifFalse: [^ result]
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jens 1/11/2011 20:13'!
listVarNames
	"Answer a list of list variable names."

	| lst |
	lst _ lists keys.
	self prototype ifNotNil: [
		lst addAll: self prototype listVarNames ].

	^ lst asSet asArray sort

! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 5/1/2008 10:23'!
lists

	^ lists
! !

!ScriptableScratchMorph methodsFor: 'list ops' stamp: 'jm 6/3/2008 18:10'!
setLine: lineNum ofList: listName to: anObject

	| list |
	list _ self listNamed: listName ifNone: [^ ''].
	^ list setLineAt: (self lineNum: lineNum forList: list) to: (self asListElement: anObject)
! !


!ScriptableScratchMorph methodsFor: 'string ops' stamp: 'jens 6/29/2010 11:52'!
concatenate: arg1 with: arg2
	"Concatenate two strings. Arguments are converted to strings."

	^ arg1 asString asUTF8, arg2 asString asUTF8
! !

!ScriptableScratchMorph methodsFor: 'string ops' stamp: 'jens 6/29/2010 12:01'!
letter: index of: anObject
	"Answer the ith letter of the given string. Answer the empty string if the index is out of bounds."

	| s i |
	s _ anObject.

	anObject isUnicode
		ifTrue: [s _ anObject asUTF32]
		ifFalse: [s _ anObject asString asUTF32].

	i _ self letterNum: index of: s.
	((i < 1) | (i > s size)) ifTrue: [^ ''].
	^ (UTF32 with: (s at: i)) asUTF8
! !

!ScriptableScratchMorph methodsFor: 'string ops' stamp: 'jens 6/29/2010 11:24'!
letterNum: letterNum of: aString
	"Answer the ith letter of the given string. Answer the empty string if the index is out of bounds."

	| s |
	letterNum isNumber ifTrue: [^ letterNum asInteger].

	s _ letterNum.
	s isUnicode ifTrue: [s _ String withAll: letterNum].
	(s isKindOf: String) ifTrue: [
		#first = s ifTrue: [^ 1].
		#last = s ifTrue: [^ aString size].
		#any = s ifTrue: [
			aString size = 0 ifTrue: [^ 1].
			^ (1 to: aString size lineCount) atRandom].
		^ s asNumberNoError].
	^ 0
! !

!ScriptableScratchMorph methodsFor: 'string ops' stamp: 'jm 4/1/2009 10:21'!
stringLength: anObject

	anObject isUnicode
		ifTrue: [^ anObject asUTF32 size]
		ifFalse: [^ anObject asString asUTF32 size].
! !


!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 4/8/2009 14:40'!
allMotorsOff
	"Turn all motors off."

	self motorOff: ' '.
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 4/14/2009 11:11'!
allMotorsOn
	"Turn all motors off."

	self motorOn: ' '.
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 4/21/2009 21:06'!
motor: motorName direction: directionName
	"Set the direction of the given motor."

	| dir |
	dir _ 0.
	(directionName includesSubString: 'reverse') ifTrue: [dir _ 0].
	(directionName includesSubString: 'this way') ifTrue: [dir _ 1].
	(directionName includesSubString: 'that way') ifTrue: [dir _ -1].

	'A' = motorName ifTrue: [WeDoPlugin motorADirection: dir].
	'B' = motorName ifTrue: [WeDoPlugin motorBDirection: dir].
	' ' = motorName ifTrue: [
		WeDoPlugin motorADirection: dir.
		WeDoPlugin motorBDirection: dir].
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 3/26/2009 22:13'!
motor: motorName power: power
	"Set the power level of the given motor (0-100)."

	'A' = motorName ifTrue: [WeDoPlugin motorAPower: power].
	'B' = motorName ifTrue: [WeDoPlugin motorBPower: power].
	' ' = motorName ifTrue: [
		WeDoPlugin motorAPower: power.
		WeDoPlugin motorBPower: power].
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'ee 6/2/2009 14:34'!
motorDirection

	^ {
		'this way'.
		'that way'.
		'reverse'
	}
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 3/26/2009 22:10'!
motorNames

	^ #(' ' A B)
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 4/8/2009 15:59'!
motorOff: motorName
	"Turn the given motor off."

	'A' = motorName ifTrue: [WeDoPlugin motorAOn: false].
	'B' = motorName ifTrue: [WeDoPlugin motorBOn: false].
	' ' = motorName ifTrue: [
		WeDoPlugin motorAOn: false.
		WeDoPlugin motorBOn: false].
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 3/26/2009 22:13'!
motorOn: motorName
	"Turn the given motor on."

	'A' = motorName ifTrue: [WeDoPlugin motorAOn: true].
	'B' = motorName ifTrue: [WeDoPlugin motorBOn: true].
	' ' = motorName ifTrue: [
		WeDoPlugin motorAOn: true.
		WeDoPlugin motorBOn: true].
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 3/20/2009 17:34'!
motorOn: motorName duration: secs elapsed: elapsedMSecs from: motorID
	"Turn the given motor on for the given number of seconds."

	motorID ifNil: [  "first call, start motor"
		self motorOn: motorName.
		^ motorName].

	elapsedMSecs >= (1000 * secs) ifTrue: [self motorOff: motorID].
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 4/8/2009 15:59'!
motorOnFor: secs elapsed: elapsedMSecs from: motorID
	"Turn all motors on for the given number of seconds."

	motorID ifNil: [  "first call, start motor"
		self motorOn: ' '.
		^ #' '].

	elapsedMSecs >= (1000 * secs) ifTrue: [self motorOff: motorID].
! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 4/14/2009 11:13'!
setMotorDirection: directionName

	self motor: ' ' direction: directionName.

! !

!ScriptableScratchMorph methodsFor: 'motor ops' stamp: 'jm 4/8/2009 15:59'!
startMotorPower: power

	self motor: ' ' power: power.
	self motorOn: ' '.
! !


!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 6/23/2004 10:05'!
broadcast: name
	"Broadcast the given event name with zero as its argument."

	self broadcast: name withArgument: 0.
! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 5/15/2008 13:49'!
broadcast: name withArgument: arg
	"Broadcast the given event with the given argument."

	| stage |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		stage broadcastEventNamed: name asString with: arg].
! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 10/18/2007 23:09'!
computeFunction: functionName of: aNumber
	"Return the result of computing the given mathematical function on the given number."

	'abs' = functionName ifTrue: [^ aNumber abs].
	'sqrt' = functionName ifTrue: [^ aNumber sqrt].
	'sin' = functionName ifTrue: [^ aNumber degreesToRadians sin].
	'cos' = functionName ifTrue: [^ aNumber degreesToRadians cos].
	'tan' = functionName ifTrue: [^ aNumber degreesToRadians tan].
	'asin' = functionName ifTrue: [^ (aNumber within: -1.0 and: 1.0) arcSin radiansToDegrees].
	'acos' = functionName ifTrue: [^ (aNumber within: -1.0 and: 1.0) arcCos radiansToDegrees].
	'atan' = functionName ifTrue: [^ aNumber arcTan radiansToDegrees].
	
	'ln' = functionName ifTrue: [^ aNumber ln].
	'log' = functionName ifTrue: [^ aNumber log].
	'e ^' = functionName ifTrue: [^ aNumber exp].
	'10 ^' = functionName ifTrue: [^ 10.0 raisedTo: aNumber].

	^ 0
! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 4/27/2007 13:14'!
eventReceived: event
	"Start all non-running stacks with an EventHat matching the given events and answer a collection of the new processes. If a process is already running for a given stack, don't start a new one."

	| targetScripts newProcs |
	targetScripts _ #().
	event name = 'Scratch-KeyPressedEvent'
		ifTrue: [
			targetScripts _ self scripts select: [:s |
				(s class == KeyEventHatMorph) and:
				 [s respondsToKeyEvent: event argument]]]
		ifFalse: [
			event name = 'Scratch-MouseClickEvent'
				ifTrue: [
					self isHidden not ifTrue: [
						targetScripts _ self scripts select: [:s |
							s class == MouseClickEventHatMorph]]]
				ifFalse: [
					targetScripts _ self scripts select: [:s |
						(s class == EventHatMorph) and:
						 [s eventName caseInsensitiveEqual: event name]]]].
	
	newProcs _ targetScripts asArray collect: [:script | script startForEvent: event].
	^ newProcs select: [:p | p notNil]

! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 10/10/2007 11:50'!
mathFunctionNames
	"Answer a collection of math function names."

	^ #(
		'abs'
		'sqrt'
		'sin'
		'cos'
		'tan'
		'asin'
		'acos'
		'atan'
		'ln'
		'log'
		'e ^'
		'10 ^')
! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 5/18/2006 07:43'!
mwait: duration elapsed: elapsed from: ignored
	"Do nothing; just wait for the time interval to elapse."

	^ nil
! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 10/4/2007 15:23'!
randomFrom: start to: stop
	"Answer a random number within the given range. If both min and max are integers, the result is rounded to the nearest integer."

	| min max result |
	min _ start min: stop.
	max _ start max: stop.
	result _ (RandomGen next * (max - min)) + min.
	min isInteger & max isInteger
		ifTrue: [result _ (RandomGen next * ((max + 1) - min)) truncated + min]
		ifFalse: [result _ (RandomGen next * (max - min)) + min].
	^ result
! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 8/8/2005 12:21'!
stopAll
	"Stop everything!!"

	| stage |
	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNotNil: [stage stopAll].
! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 12/1/2006 19:03'!
stopAllSounds
	"Stop all sounds and MIDI notes/drums."

	| stage |
	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNotNil: [stage stopAllSounds].
! !

!ScriptableScratchMorph methodsFor: 'other ops' stamp: 'jm 8/22/2003 19:29'!
wait: duration elapsed: elapsed from: ignored
	"Do nothing; just wait for the time interval to elapse."

	^ nil
! !


!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 1/20/2011 22:43'!
allLocalBlockIds

	| ownIds inheritedIds |
	ownIds _ self blockIds.
	self prototype ifNil: [^ ownIds].
	inheritedIds _ (self prototype localBlocks collect: [:each | 
		each id ]) reject: [:id |
			ownIds includes: id].
	^ (ownIds, inheritedIds) asSortedCollection! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 3/9/2011 22:59'!
deleteSprite: aSprite
	aSprite deleteSpriteQuickly.

	"now the deleted sprite has to be removed from all variables
	and lists - not sure how to accomplish this"! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 3/9/2011 23:04'!
deleteSpriteQuickly
	"Delete the sprite and all watchers that are associated with it."

	| frame sprites presenter instances |
	frame _ self ownerThatIsA: ScratchFrameMorph. 
	frame ifNil: [
		presenter _ World findA: ScratchPresenterMorph.
		presenter ifNil: [^ self delete].
		frame _ presenter frame].

	frame deleteWatchersForSprite: self.
	instances _ self instances.

	frame workPane updateSpritesList.
	sprites _ frame workPane sprites.
	sprites remove: self ifAbsent: [].

	self delete.
	instances do: [:each |
		each undeleteAllAttributes.
		each undeleteAllVariables.
		each prototype: nil].

	frame libraryPane fixLayout.

	"delete my thumbnail, and re-focus on the thumbnail right after me or the stage if there are no sprites"

	frame view: frame workPane tab: 'Scripts' category: 'motion'
"
	i > sprites size ifTrue: [i _ i - 1].
	i < 1 
		ifTrue: [frame view: frame workPane tab: 'Scripts' category: 'motion'] 
		ifFalse: [frame view: (sprites at: i) tab: 'Scripts' category: 'motion'].	
"! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 1/20/2011 01:17'!
getObject: anObject
	^ anObject! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 1/20/2011 01:42'!
getSpawnOf: anObject
	^ anObject spawn! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 1/20/2011 22:40'!
inheritedBlockIds

	| ownIds inheritedIds |
	self prototype ifNil: [^ #()].
	ownIds _ self blockIds.
	inheritedIds _ (self prototype localBlocks collect: [:each | 
		each id ]) reject: [:id |
			ownIds includes: id].
	^ inheritedIds! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 1/20/2011 22:41'!
inheritedBlocks

	^ self inheritedBlockIds collect: [:id | 
		self prototype definitionFor: id ]! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 2/28/2011 00:20'!
initializeVarsAndLists
	"used when spawning (cloning)"

	vars _ Dictionary new.
	lists _ Dictionary new! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 13:43'!
instances

	| stage |
	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNil: [^ #()].
	^ stage sprites select: [:each |
		each prototype = self ]! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 2/9/2011 00:02'!
passiveSetVolumeTo: aNumber

	| stage player |
	volume _ aNumber asNumberNoError within: 0 and: 100.
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		(player _ stage notePlayerFor: self) ifNotNil: [
			player volume: volume]].

	media do: [:snd |
		snd isSound ifTrue: [snd volume: volume]].

	self propagate: #volume

! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 13:52'!
propagate
	"private - apply the method calling me to all subsprites"

	| sel args instances |
	instances _ self instances.
	instances isEmpty ifTrue: [^self].
	sel _ thisContext sender method selector.
	args _ OrderedCollection new.
	1 to: thisContext sender method numArgs do: [:idx |
		args add: (thisContext sender tempAt: idx) ].
	instances do: [:eachPart |
		args isEmpty
			ifTrue: [ eachPart perform: sel]
			ifFalse: [ eachPart perform: sel withArguments: args asArray]]! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 2/8/2011 21:26'!
propagate: attributeName
	"private - apply the method calling me to all subsprites"

	| sel args instances |
	instances _ self instances select: [:each |
		each deletedAttributes includes: attributeName].
	instances isEmpty ifTrue: [^self].
	sel _ thisContext sender method selector.
	args _ OrderedCollection new.
	1 to: thisContext sender method numArgs do: [:idx |
		args add: (thisContext sender tempAt: idx) ].
	instances do: [:eachPart |
		args isEmpty
			ifTrue: [ eachPart perform: sel]
			ifFalse: [ eachPart perform: sel withArguments: args asArray]]! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 1/10/2011 23:40'!
prototype
	(self isKindOf: ScratchSpriteMorph)
		ifTrue: [^ self prototype]
		ifFalse: [^ nil]! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 1/19/2011 23:34'!
thumbnailImageForm

	^ self imageForm toThumbnail: 50@50 borderWidth: 0 borderColor: Color transparent! !

!ScriptableScratchMorph methodsFor: 'byob OOP' stamp: 'jens 2/28/2011 00:54'!
undeleteAllVariables
	"... and lists"

	self varNames do: [:vn |
		self setVar: vn to: (self getVar: vn)].

	self listVarNames do: [:ln |
		lists at: ln put: (self listNamed: ln)]! !


!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 7/3/2008 16:55'!
addGlobalVariable
	"Ask the user for a variable name, then add a background (global) variable of that name."

	| sFrame varName |
	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self beep].

	varName _ StringDialog ask: 'Variable name?'.
	varName size = 0 ifTrue: [^ self].
	varName _ varName asUTF8.
	(sFrame workPane variableNameInUse: varName) ifTrue: [
		self beep.
		DialogBoxMorph warn: 'That variable name is already in use'.
		^ self].

	sFrame workPane addVariable: varName.
	sFrame viewerPane categoryChanged: 'variables'.
	self addWatcherForNewVariable: varName withScope: sFrame workPane.
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 8/21/2006 11:59'!
addVariable: varName
	"Add a new user variable with the given name to this object. Do nothing if the variable already exists or is built in."

	(vars includesKey: varName asString) ifFalse: [
		vars at: varName asString put: 0].
	self isClone: false.
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 6/3/2009 16:43'!
addVariable: varName value: anObject
	"Add a new user variable with the given name to this object. Do nothing if the variable already exists or is built in."

	(vars includesKey: varName asString) ifFalse: [
		vars at: varName asString put: anObject].
	self isClone: false.
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 12/1/2007 22:10'!
addWatcherForNewVariable: varName withScope: spriteOrStage
	"Add a watcher on the stage once a variable has been created."

	| sFrame |
	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self].
	sFrame viewerPane pageViewer submorphs do: [:s | 
		(s isKindOf: ScratchBlockPaletteMorph) ifTrue: [
			s submorphs do: [:block | 
				(block isKindOf: VariableBlockMorph) ifTrue: [
					(block receiver = spriteOrStage) &
					(block commandSpec = varName) ifTrue: [
						(sFrame watcherForBlock: block) ifNil: [
							block toggleWatcher]]]]]].
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 7/30/2008 18:52'!
allVarNames
	"Answer a set of all variable and list variable names."

	| allNames |
	allNames _ vars keys.
	allNames addAll: lists keys.
	^ allNames

! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 2/11/2011 12:22'!
changeVar: varName by: increment
	"Change the value of the given variable of this object by the given amount."

	| stage n frame w |

	(vars includesKey: varName asString) ifFalse: [
		stage _ self ownerThatIsA: ScratchStageMorph.
		(stage notNil and: [stage ~= self]) 
			ifTrue: [stage changeVar: varName by: increment].
		(self prototype notNil and: [self prototype varNames includes: varName])
			ifTrue: [
				vars at: varName put: (self getVar: varName) + increment asNumberNoError.
			frame _ self scratchFrame.
			frame ifNil: [^ self].
			frame viewerPane categoryChanged: 'variables'.
			w _ frame watcherForBlock: (VariableBlockMorph new 
					receiver: self; 
					commandSpec: varName; 
					yourself).
			w ifNotNil: [
				w setCategoryColor: (ScriptableScratchMorph blockColorFor: 'variables') ]].
		^ self].

	n _ vars at: varName asString ifAbsent: [^ self].
	self setVar: varName to: n asNumberNoError + increment asNumberNoError.
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 5/12/2010 00:46'!
deleteVariable
	"Ask the user which user variable to delete, then remove it."

	| sFrame stage menu choice |
	sFrame _ self ownerThatIsA: ScratchFrameMorph.
	sFrame ifNil: [^ self].

	stage _ sFrame workPane.
	(stage varNames isEmpty) & (self varNames isEmpty)
		ifTrue: [^ self inform: 'No variables.' localized].

	menu _ CustomMenu new.
	stage varNames do: [:v | menu add: v asMacRoman action: (Array with: v with: #global)].
	self = stage ifFalse: [
		stage varNames isEmpty ifFalse: [menu addLine].
		self varNames do: [:v | menu add: v asMacRoman action: (Array with: v with: #local)]].
	choice _ menu startUp.
	choice ifNil: [^ self].

	choice second = #global
		ifTrue: [stage deleteVariable: choice first]
		ifFalse: [self deleteVariable: choice first].

	sFrame viewerPane categoryChanged: 'variables'.
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 2/23/2011 00:45'!
deleteVariable: varName
	"Delete the variable with the given name. Do nothing if the variable doesn't exist."

	| frame w |
	frame _ self scratchFrame.
	frame ifNotNil: [
		(self prototype notNil and: [self prototype varNames includes: varName]) ifFalse: [
			frame deleteWatchersForVar: varName ofSprite: self]].
	vars removeKey: varName asString ifAbsent: [^ self].
	frame viewerPane categoryChanged: 'variables'.
	w _ frame watcherForBlock: (VariableBlockMorph new receiver: self; commandSpec: varName; yourself).
	w ifNotNil: [w setCategoryColor: (ScriptableScratchMorph blockColorFor: 'variables') twiceLighter].
	self isClone: false.
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 3/27/2011 23:52'!
desparatelyGetVar: varName from: aVarBlockMorph

	| anotherReceiver |
	anotherReceiver _ aVarBlockMorph scratchObject.
	anotherReceiver ifNil: [^ 0].
	(anotherReceiver varNames includes: varName)	ifFalse: [
		anotherReceiver _ anotherReceiver ownerThatIsA: ScratchStageMorph.
		anotherReceiver ifNil: [^ 0].
		(anotherReceiver varNames includes: varName) ifFalse: [
			^ 0]].
	aVarBlockMorph receiver: anotherReceiver.
	^ anotherReceiver getVar: varName
		! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 1/18/2011 23:41'!
ensureListExists: listName
	"If a list with the given name is not visible to this object, make one."

	| stage |

	listName = '' ifTrue: [^ self].

	(lists includesKey: listName) ifTrue: [^ self].
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		(stage listVarNames includes: listName) ifTrue: [^ self]].
	(self prototype notNil and: [self prototype listVarNames includes: listName])
		ifTrue: [^ self].


	"list not found; create it"
	lists at: listName put: (ScratchListMorph new listName: listName target: self).

! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 5/16/2011 23:18'!
ensureVariableExists: varName
	"Make sure that the variable with the given name is visible to this object. Do nothing if the variable already exists."

	| stage vn |
	(varName isKindOf: Array)
		ifTrue: [^ self].
	(varName isKindOf: CommandBlockMorph)
		ifTrue: [^ self].

	vn _ varName asString.	
	vn = '' ifTrue: [^ self].

	(vars includesKey: vn) ifTrue: [^ self].
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		(stage varNames includes: vn) ifTrue: [^ self]].
	(self prototype notNil and: [self prototype varNames includes: vn])
		ifTrue: [^ self].

	"variable not found; create it"
	vars at: vn asString put: 0.
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 5/19/2011 13:19'!
getVar: varName
	"Answer the value of the given user variable of this object, or 0 if the variable has been deleted."

	| stage |
	(vars includesKey: varName)
		ifFalse: [ stage _ (self ownerThatIsA: ScratchStageMorph).
			stage ifNotNil: [	^ stage vars at: varName asString ifAbsent: [
				(self prototype notNil and: [self prototype varNames includes: varName])
					ifTrue:[^self prototype getVar: varName]
					ifFalse: [^self scratchObject getVar: varName]]].
			(self prototype notNil and: [self prototype varNames includes: varName])
					ifTrue:[^self prototype getVar: varName]
					ifFalse: [^self scratchObject getVar: varName]].
	^ vars at: varName asString ifAbsent: [0]
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 3/27/2011 23:49'!
getVar: varName block: aVariableBlockMorph
	"Answer the value of the given user variable of this object, or 0 if the variable has been deleted."

	(vars includesKey: varName)
		ifFalse: [ ^ (self ownerThatIsA: ScratchStageMorph) vars at: varName asString ifAbsent: [
			(self prototype notNil and: [self prototype varNames includes: varName])
				ifTrue:[self prototype getVar: varName]
				ifFalse: [^ self desparatelyGetVar: varName from: aVariableBlockMorph]]].
	^ vars at: varName asString ifAbsent: [0]
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 7/7/2008 10:28'!
hideVariable: varName
	"Hide the watcher(s) for the given variable. If the receiver is a sprite and both it and and the stage have the given variable, hide both. Do nothing if the variable does not exist or is already hidden."

	| stage |
	self showOrHideVariable: varName show: false.

	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ~= self ifTrue: [stage showOrHideVariable: varName show: false].

! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'JM 11/10/2011 11:03'!
layer: aNumber

	"Override this in a subclass if it is meaningful"! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 5/2/2011 00:12'!
setVar: varName to: newValue
	"Set the value of the given variable of this object to the given value."

	| vName stage sf w |

	"BYOB OOP interface:"
	(varName isKindOf: CommandScriptBlockMorph) ifTrue: [
		^ self set: varName to: newValue].

	vName _ varName asString. "convert Symbol to String if needed"
	(vars includesKey: vName) ifFalse: [
		(self prototype notNil and: [self prototype varNames includes: varName])
			ifTrue: [
				vars at: vName put: newValue.
				sf _ self ownerThatIsA: ScratchFrameMorph.
				sf ifNil: [^ self].
				sf viewerPane categoryChanged: #variables.
				w _ sf watcherForBlock: (VariableBlockMorph new 
						receiver: self; 
						commandSpec: varName; 
						yourself).
				w ifNotNil: [
				w setCategoryColor: (ScriptableScratchMorph blockColorFor: 'variables').
				^ self]].
			stage _ self ownerThatIsA: ScratchStageMorph.
		(stage notNil and: [stage ~= self]) 
			ifTrue: [stage setVar: varName to: newValue].
		^ self ].

	vars at: vName put: newValue.
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 8/3/2008 12:44'!
showOrHideVariable: varName show: showFlag
	"Show the watcher for the given variable. Do nothing if the variable does not exist or is already showing."

	| frame w b palette |
	(self varNames includes: varName) ifFalse: [^ self].
	frame _ self ownerThatIsA: ScratchFrameMorph.
	frame ifNil: [
		(w _ self ownerThatIsA: OffscreenWorldMorph) ifNil: [^ self].
		frame _ w frame].

	b _ VariableBlockMorph new commandSpec: varName; receiver: self blockReceiver.
	w _ frame watcherForBlock: b.
	showFlag
		ifTrue: [w ifNil: [frame showWatcher: b createWatcher]]
		ifFalse: [w ifNotNil: [w delete]].

	palette _ frame viewerPane pageViewer contents.
	palette ifNotNil: [palette updateWatcherButtonsForFrame: frame].
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 7/7/2008 10:17'!
showVariable: varName
	"Show the watcher(s) for the given variable. If the receiver is a sprite and both it and and the stage have the given variable, show both. Do nothing if the variable does not exist or is already showing."

	| stage |
	self showOrHideVariable: varName show: true.

	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ~= self ifTrue: [stage showOrHideVariable: varName show: true].

! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jens 1/10/2011 23:38'!
varNames
	"Answer a list of variable names."

	| lst |
	lst _ vars keys.
	self prototype ifNotNil: [
		lst addAll: self prototype varNames ].

	^ lst asSet asArray sort
! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 7/30/2008 18:41'!
varNamesMenu
	"Answer a list of variable names."

	| varList stage |
	varList _ #().
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [varList _ stage varNames].
	self == stage ifFalse: [
		varList size > 0 ifTrue: [varList _ varList copyWith: #-].
		varList _ varList, self varNames].

	^ varList! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 7/30/2008 18:36'!
variableBlockColor

	^ Color h: 25 s: 0.88 v: 0.95

! !

!ScriptableScratchMorph methodsFor: 'variables' stamp: 'jm 7/30/2008 18:53'!
variableNameInUse: varName
	"Answer true if the given variable name in the receiver would conflict with an existing variable or list. For example, if the receiver is the Stage and the given variable name is used by any sprite."

	| stage |
	(self allVarNames includes: varName) ifTrue: [^ true].

	self isSprite
		ifTrue: [
			(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ false].
			^ stage allVarNames includes: varName]
		ifFalse: [
			submorphs do: [:m |
				(m isKindOf: ScratchSpriteMorph) ifTrue: [
					(m allVarNames includes: varName) ifTrue: [^ true]]]].

	^ false
! !


!ScriptableScratchMorph methodsFor: 'scripts' stamp: 'ee 5/14/2008 13:00'!
addComment: aScratchCommentMorph
	"Aligns the newly added script below the lowest script in the pane."

	| y bottom |
	y _ 10.
	blocksBin submorphsDo: [:m |
		bottom _  (m fullBounds bottom) - (blocksBin position y).
		(bottom > y) ifTrue: 
			[y _ bottom]].
	aScratchCommentMorph position: blocksBin position + (20@(y+10)).

	blocksBin addMorph: aScratchCommentMorph.
! !

!ScriptableScratchMorph methodsFor: 'scripts' stamp: 'jm 6/26/2006 09:57'!
addStack: aBlockStack
	"Aligns the newly added script below the lowest script in the pane."

	| y bottom |
	y _ 10.
	blocksBin submorphsDo: [:m |
		bottom _  (m fullBounds bottom) - (blocksBin position y).
		(bottom > y) ifTrue: 
			[y _ bottom]].
	aBlockStack position: blocksBin position + (20@(y+10)).

	aBlockStack newScriptOwner: self.
	blocksBin addMorph: aBlockStack.
! !

!ScriptableScratchMorph methodsFor: 'scripts' stamp: 'jm 5/7/2009 15:05'!
duplicate

	| newSprite s |
	newSprite _ self duplicateNoAttach.
	self world activeHand attachMorph: newSprite.

	((s _ self ownerThatIsA: ScratchStageMorph) notNil and:
	 [s isQuarterSize]) ifTrue: [
		self world activeHand drawHalfSize: true].

	^ newSprite
! !

!ScriptableScratchMorph methodsFor: 'scripts' stamp: 'jens 3/3/2011 10:11'!
prepareForExport
	self blocksBin allMorphsDo: [:m |
		(m isKindOf: BlockMorph) ifTrue: [m stop].
		(m isKindOf: SpriteArgMorph) ifTrue: [m clearMorphReference]].

	customBlocks ifNotNil: [
		customBlocks do: [:eachDef |
			eachDef body ifNotNil: [
				eachDef body allMorphsDo: [:m |
					(m isKindOf: SpriteArgMorph) ifTrue: [m clearMorphReference]]].
			(eachDef answer isKindOf: Morph) ifTrue: [
				eachDef answer allMorphsDo: [:m |
					(m isKindOf: SpriteArgMorph) ifTrue: [m clearMorphReference]]]]].

	self convertStacksToTuples.

	(self isKindOf: ScratchSpriteMorph) ifTrue: [
		self subsprites do: [:sub |
			sub prepareForExport ]]
! !

!ScriptableScratchMorph methodsFor: 'scripts' stamp: 'jens 2/11/2011 12:07'!
scratchFrame

	| frame w |
	frame _ self ownerThatIsA: ScratchFrameMorph.
	frame ifNil: [
		(w _ self ownerThatIsA: OffscreenWorldMorph) ifNil: [^ nil].
		frame _ w frame].
	^ frame

! !

!ScriptableScratchMorph methodsFor: 'scripts' stamp: 'jm 8/10/2007 10:14'!
scripts
	"Answer my scripts, a collection of HatBlockMorphs."

	(blocksBin isKindOf: Morph) ifFalse: [^ blocksBin].
	^ blocksBin submorphs select: [:m | m isKindOf: HatBlockMorph]
! !


!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 6/24/2010 19:19'!
addEventNamesTo: aSet
	"Add the names of all events implemented by this morph, excluding keyboard events. Suppress duplicates (ignoring case differences)."

	| allCustomBlockMorphs |
	(blocksBin isKindOf: Morph) ifFalse: [^ self].

	allCustomBlockMorphs _ OrderedCollection new.
	customBlocks ifNotNil: [customBlocks do: [:cb | cb allBlocks do: [:ab |
		allCustomBlockMorphs addAll: ab allMorphs]]].

	blocksBin allMorphs, allCustomBlockMorphs do: [:m |
		(m class = EventTitleMorph) ifTrue: [
			(aSet anySatisfy: [:el | el caseInsensitiveEqual: m eventName]) ifFalse: [
				aSet add: m eventName]]].
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 2/23/2010 01:15'!
addGenericListBlocksTo: page y: startY
	"Add the generic list blocks to the given page starting at the given y offset."

	| addButton deleteButton x y hasLists stage listMaker |
	addButton _ ScratchFrameMorph
		buttonLabel: 'Make a list' localized
		selector: #addList.
	(self isKindOf: ScratchStageMorph) ifTrue: [addButton actionSelector: #addGlobalList].

	deleteButton _ ScratchFrameMorph
		buttonLabel: 'Delete a list' localized
		selector: #deleteList.

	x _ 13.
	y _ startY + 10.
	page addMorph: (addButton target: self; position: x@y).
	y _ addButton bottom + 3.

	hasLists _ self listVarNames size > 0.
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		stage listVarNames size > 0 ifTrue: [hasLists _ true]].
	hasLists ifTrue: [

		page addMorph: (deleteButton target: self; position: x@y).
		y _ deleteButton bottom + 10.

		y _ (self addListReportersTo: page x: x y: y) + 10 ].

	"
	listMaker _ MultiArgReporterBlockMorph new
			color: ScriptableScratchMorph listBlockColor;
			receiver: (self ownerThatIsA: ScratchStageMorph);
			isSpecialForm: true;
			commandSpec: 'list %s';
			selector: #doMakeNewList.

	page addMorph: (listMaker position: x @ y).
	y _ y + listMaker height + 3.
	"

	(self blocksFor: 'list') do: [:blockOrSym |
		(blockOrSym = #-) | (blockOrSym = #~) | (blockOrSym = #=)
			ifTrue: [
				(blockOrSym = #-) ifTrue: [y _ y + 15].  "insert a full space"
				(blockOrSym = #~) ifTrue: [y _ y + 5].  "insert a half space"
				(blockOrSym = #=) ifTrue: [
					y _ y + 7.
					page addMorph: ((ImageMorph new form: (ScratchFrameMorph skinAt: #connector)) position: x@y).
					y _ y + 20]]  "insert a line"
			ifFalse: [
				y _ self createBlock: blockOrSym atPosition: x@y onPage: page.
				page submorphs last color: ScriptableScratchMorph listBlockColor]].
	^y
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 2/22/2011 23:51'!
addGenericVariableBlocksTo: page x: x y: startY
	"Add the generic variable blocks to the given page starting at the given y offset. Answer the new y."

	| y vName stage block varBlocks |
	y _ startY.

	"pick a default variable name"
	vName _ nil.
	stage _ self ownerThatIsA: ScratchStageMorph.
	(stage notNil and: [stage varNames size > 0])
		ifTrue: [
			vName _ stage varNames first]
		ifFalse: [
			self varNames size = 0
				ifTrue: [vName = ''  "^ y"]
				ifFalse: [vName _ self varNames first]].

	vName ifNil: [vName _ ''].

	varBlocks _ OrderedCollection new.

	block _ SetterBlockMorph new
		initSetterForVar: vName;
		receiver: self blockReceiver.
	block expressionArg stringExpression: '0'.
	varBlocks add: block.

	block _ SetterBlockMorph new
		initChangerForVar: vName;
		receiver: self blockReceiver.
	block expressionArg numExpression: '1'.
	varBlocks add: block.

	(self blocksFor: 'variables') do: [:b |
		(b isKindOf: BlockMorph) ifTrue: [
			b defaultArgs: (Array with: vName)].
			varBlocks add: b].

	block _ VariableDeclarationBlockMorph new
		minArgs: 1; 
		commandSpec: 'script variables' localized; 
		receiver: self blockReceiver;
		addItem;
		isSpecialForm: true;
		selector: #doDeclareVariables.
	varBlocks add: block afterIndex: 5.

	varBlocks do: [:blockOrSym |
		(blockOrSym = #-) | (blockOrSym = #~) | (blockOrSym = #=)
			ifTrue: [
				(blockOrSym = #-) ifTrue: [y _ y + 15].  "insert a full space"
				(blockOrSym = #~) ifTrue: [y _ y + 5].  "insert a half space"
				(blockOrSym = #=) ifTrue: [
					y _ y + 7.
					page addMorph: ((ImageMorph new form: (ScratchFrameMorph skinAt: #connector)) position: x@y).
					y _ y + 20]]  "insert a line"
			ifFalse: [
				blockOrSym color: ((blockOrSym isKindOf: VariableDeclarationBlockMorph)
									ifTrue: [Color gray]
									ifFalse: [ self variableBlockColor]).
				page addMorph: (blockOrSym position: x@y).
				y _ blockOrSym bottom + 3]].
"


[:b |
		b color: self variableBlockColor.
		page addMorph: (b position: x@y).
		y _ b bottom + 3].
"
	^ y

! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 2/1/2010 00:57'!
addListReportersTo: page x: x y: startY
	"Add the list block reporters to the given page starting at the given y offset. Answer the new y."

	| y stage b watcherButton yOffset line line2 |
	y _ startY.
	stage _ self ownerThatIsA: ScratchStageMorph.
	(stage notNil and: [stage ~= self]) ifTrue: [
		stage listVarNames do: [:listVarName |
			b _ ListContentsBlockMorph new
				color: ScriptableScratchMorph listBlockColor;
				receiver: stage blockReceiver;
				commandSpec: listVarName;
				selector: #listNamed:.
			watcherButton _ self createToggleButtonFor: b.
			yOffset _ (b fullBounds height - watcherButton height) // 2.
			page addMorph: (watcherButton position: x @ (y + yOffset)).
			page addMorph: (b position: (x + watcherButton width + 4)@y).
			y _ y + b height + 3].
		(self listVarNames size > 0) ifTrue: [
			line _ Morph new.
			line
				extent: 90@1;
				color: Color gray darker darker;
				position: x@(y+2).
			line2 _ Morph new.
			line2
				extent: 90@1;
				color: Color gray lighter;
				position: x@(y+3).
			page
				addMorph: line;
				addMorph: line2.
			y _ y + 9]].

	self listVarNames do: [:listVarName |
		b _ ListContentsBlockMorph new
			color: ScriptableScratchMorph listBlockColor;
			receiver: self blockReceiver;
			commandSpec: listVarName;
			selector: #listNamed:.
		watcherButton _ self createToggleButtonFor: b.
		yOffset _ (b fullBounds height - watcherButton height) // 2.
		page addMorph: (watcherButton position: x @ (y + yOffset)).
		page addMorph: (b position: (x + watcherButton width + 4)@y).
		y _ y + b height + 3].

	^ y
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'ee 8/11/2008 19:52'!
addVariableReportersTo: page x: x y: startY
	"Add the list block reporters to the given page starting at the given y offset. Answer the new y."

	| y stage b watcherButton yOffset line line2 |
	y _ startY.

	stage _ self ownerThatIsA: ScratchStageMorph.
	(stage notNil and: [stage ~= self]) ifTrue: [
		stage varNames do: [:vName |
			b _ VariableBlockMorph new
				commandSpec: vName;
				receiver: stage blockReceiver.

			watcherButton _ self createToggleButtonFor: b.
			yOffset _ (b fullBounds height - watcherButton height) // 2.
			page addMorph: (watcherButton position: x @ (y + yOffset)).
			page addMorph: (b position: (x + watcherButton width + 4)@y).
			y _ y + b height + 3].
		(self varNames size > 0) ifTrue: [
			line _ Morph new.
			line
				extent: 90@1;
				color: Color gray darker darker;
				position: x@(y+2).
			line2 _ Morph new.
			line2
				extent: 90@1;
				color: Color gray lighter;
				position: x@(y+3).
			page
				addMorph: line;
				addMorph: line2.
			y _ y + 9]].

	self varNames do: [:vName |
		b _ VariableBlockMorph new
			commandSpec: vName;
			receiver: self blockReceiver.

		watcherButton _ self createToggleButtonFor: b.
		yOffset _ (b fullBounds height - watcherButton height) // 2.
		page addMorph: (watcherButton position: x @ (y + yOffset)).
		page addMorph: (b position: (x + watcherButton width + 4)@y).
		y _ y + b height + 3].

	^ y
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jm 7/7/2008 10:34'!
blockCategories
	"Answer a list of block categories."

	^ (self class blockSpecs select: [:el |
		(el isKindOf: String) and: [el ~= '-' and: [el ~= '~']]]) asArray
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 7/27/2010 23:16'!
blockFromOldFormTuple: tuple receiver: scriptOwner
	"Answer a new block for the given tuple."

	| k spec blockColor block argCount arg argBlock userSpec csp |
	k _ tuple first.
	(#(readVariable changeVariable) includes: k) ifTrue: [
		^ self variableBlockFromTuple: tuple receiver: scriptOwner].

	(#(readBlockVariable changeBlockVariable) includes: k) ifTrue: [
		^ self blockVariableBlockFromTuple: tuple receiver: scriptOwner].

	#listNamed: = k ifTrue: [
		^ ListContentsBlockMorph new
			color: ScriptableScratchMorph listBlockColor;
			receiver: scriptOwner;
			commandSpec: tuple second;
			selector: #listNamed:].

	#lambda: = k ifTrue: [
		block _ ReporterBlockMorph new.
		block
			color: Color lightGray;
			receiver: scriptOwner;
			selector: k;
			commandSpec: 'the %B block'.
		(block argumentAt: 1) defaultValue: (tuple at: 2).
		^block ].

	#doCustomBlock = k ifTrue: [
		userSpec _ tuple at: 2.
		(scriptOwner definitionFor: (CustomBlockDefinition idFromSpec: userSpec)) isReporter
			ifTrue: [ 
				block _ CustomReporterBlockMorph new.
				block isBoolean: (scriptOwner definitionFor: (CustomBlockDefinition idFromSpec: userSpec)) isBoolean]
			ifFalse: [ block _ CustomCommandBlockMorph new].
		block 
			receiver: scriptOwner;
			userSpec: userSpec.
		block isSpecialForm: true.
		block selector: #doCustomBlock.
		argCount _ block argumentCount min: tuple size - 2.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 2.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: scriptOwner.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].
		^block].

	#doMakeNewList = k ifTrue: [
		block _ MultiArgReporterBlockMorph new
			color: ScriptableScratchMorph listBlockColor;
			receiver: scriptOwner;
			isSpecialForm: true;
			selector: #doMakeNewList.
		spec _ 'list'.
		argCount _ tuple size - 1.
		argCount timesRepeat: [ spec _ spec, ' %s' ].
		block commandSpec: spec.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 1.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: scriptOwner.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].
		^block].


	(#(doCallBlockWithArgs doReport) includes: k) ifTrue: [
		block _ MultiArgReporterBlockMorph new
			color: (ScriptableScratchMorph blockColorFor: 'control');
			receiver: scriptOwner;
			isSpecialForm: true;
			minArgs: 1;
			selector: k.
		spec _ scriptOwner blockSpecForSelector: k.
		argCount _ tuple size - 1.
		(argCount - 2) timesRepeat: [ spec _ spec, ' %s' ].
		block commandSpec: spec.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 1.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: scriptOwner.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].
		^block].

	(#(function functionWithArgs) includes: k) ifTrue: [
		block _ ReporterScriptBlockMorph new
			color: (ScriptableScratchMorph blockColorFor: 'operators');
			receiver: scriptOwner;
			isSpecialForm: false;
			minArgs: 1;
			selector: k.
		spec _ scriptOwner blockSpecForSelector: k.
		argCount _ tuple size - 1.
		(argCount - 2) timesRepeat: [ spec _ spec, ' %s' ].
		block commandSpec: spec.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 1.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: scriptOwner.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].
		^block].

	(#(EventHatMorph KeyEventHatMorph MouseClickEventHatMorph WhenHatBlockMorph) includes: k) ifTrue: [
		block _ self hatBlockFromTuple: tuple receiver: scriptOwner.
		(block isKindOf: WhenHatBlockMorph) ifTrue: [block color: Color red].
		^ block].

	#scratchComment = k ifTrue: [
		block _ ScratchCommentMorph new.
		tuple size > 1 ifTrue: [block commentMorph contents: (tuple at: 2)].
		tuple size > 2 ifTrue: [(tuple at: 3) ifFalse: [block toggleShowing]].
		tuple size > 3 ifTrue: [block width: (tuple at: 4)].
		tuple size > 4 ifTrue: [block anchor: (self blockWithID: (tuple at: 5))].
		^ block].

	#comment: = k ifTrue: [
		block _ CommentBlockMorph new.
		tuple size > 1 ifTrue: [block comment: (tuple at: 2)].
		tuple size > 2 ifTrue: [(tuple at: 3) ifFalse: [block toggleShowing]].
		block color: (Color r: 0.8 g: 0 b: 0).  "obsolete"
		^ block].

	spec _ BlockSpecDict at: k ifAbsent: [nil].
	spec ifNil: [
		^ scriptOwner
			blockFromSpec: #('obsolete!!' - yourself)
			color: Color red].

	blockColor _ BlockColorDict at: k ifAbsent: [Color red].
	block _ scriptOwner blockFromSpec: spec color: blockColor.

	#procedureWithArgs = block selector ifTrue: [
		argCount _ tuple size - 2.
		argCount > 1 ifTrue: [
			csp _ block commandSpec.
			argCount - 1 timesRepeat: [ csp _ csp, ' %s' ].
			block commandSpec: csp ]].

	(block isKindOf: CommandBlockMorph) ifTrue: [
		argCount _ block argumentCount min: tuple size - 1.
		1 to: argCount do: [:i |
			((#(+ - / * =) includes: block selector) and: [ScratchTranslator isRTLMath]) "RTLMath operators are RTL"
				ifTrue: [arg _ tuple at: ((argCount + 1) - (i - 1))]
				ifFalse: [arg _ tuple at: i + 1].
			(arg isKindOf: Array)
				ifTrue: [  "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: scriptOwner.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [  "argument is a value"
					(block argumentAt: i) defaultValue: arg]].

		(block isKindOf: CBlockMorph) | (block isKindOf: CommandScriptBlockMorph) ifTrue: [
			(tuple last isKindOf: Array) ifTrue: [
				block firstBlockList: (self stackFromTupleList: tuple last receiver: scriptOwner)]].

		(block isKindOf: IfElseBlockMorph) ifTrue: [
			arg _ tuple at: tuple size - 1.
			(arg isKindOf: Array) ifTrue: [
				block trueBlock: (self stackFromTupleList: arg receiver: scriptOwner)].
			arg _ tuple at: tuple size.
			(arg isKindOf: Array) ifTrue: [
				block falseBlock: (self stackFromTupleList: arg receiver: scriptOwner)]].

		(block isKindOf: ReporterBlockMorph) ifTrue: [
			((spec at: 2) includes: $b) ifTrue: [block isBoolean: true]]].

	^ block
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'JM 11/22/2011 15:24'!
blockFromTuple: tuple receiver: scriptOwner
	"Answer a new block for the given tuple."

	| k rcvr spec blockColor block argCount arg argBlock userSpec csp def |

	#byob = tuple first ifFalse: [
		^self blockFromOldFormTuple: tuple receiver: scriptOwner ].

	'Canvas' = tuple second 
		ifTrue: [ rcvr _ self ownerThatIsA: ScratchStageMorph ]
		ifFalse: [(tuple second isKindOf: VariableFrame) 
			ifFalse: [ rcvr _ self coerceSpriteArg: tuple second ]].
	rcvr ifNil: [ rcvr _ scriptOwner].

	k _ tuple third.

	(#(readVariable changeVariable) includes: k) ifTrue: [
		^ self variableBlockFromTuple: tuple receiver: rcvr].

	(#(readBlockVariable changeBlockVariable) includes: k) ifTrue: [
		^ self blockVariableBlockFromTuple: tuple receiver: rcvr].

	#listNamed: = k ifTrue: [
		^ ListContentsBlockMorph new
			color: ScriptableScratchMorph listBlockColor;
			receiver: rcvr;
			commandSpec: tuple fourth;
			selector: #listNamed:].

	#lambda: = k ifTrue: [
		block _ ReporterBlockMorph new.
		block
			color: Color lightGray;
			receiver: rcvr;
			selector: k;
			commandSpec: 'the %B block'.
		(block argumentAt: 1) defaultValue: (tuple at: 4).
		^block ].

	#autoLambda = k ifTrue: [
		block _ CSlotMorph new.
		(tuple at: 9) ifNotNil: [
			block attachBlockNested: (self stackFromTupleList: (tuple at: 9) receiver: scriptOwner)].
		^block ].

	#loopLambda = k ifTrue: [
		block _ CArgSlotMorph new.
		(tuple at: 9) ifNotNil: [
			block attachBlockNested: (self stackFromTupleList: (tuple at: 9) receiver: scriptOwner)].
		^block ].

	#autoBlock = k ifTrue: [
		block _ OSlotMorph new type: #reporterslot.
		(tuple at: 4) ifNotNil: [
			block replaceArgMorph: block argMorphs first by: (self stackFromTupleList: (tuple at: 4) receiver: scriptOwner)].
		^block ].

	#cLambda = k ifTrue: [
		block _ CReporterSlotMorph new.
		(tuple at: 4) ifNotNil: [
			block replaceArgMorph: block argMorphs first by: (self stackFromTupleList: (tuple at: 4) receiver: scriptOwner)].
		^block ].

	#typeInLambda = k ifTrue: [
		block _ TypeInReporterSlotMorph new.
		((tuple at: 4) isKindOf: String)
			ifTrue: [block argMorphs first defaultValue: (tuple at: 4)]
			ifFalse: [
				block replaceArgMorph: block argMorphs first by: (self stackFromTupleList: (tuple at: 4) receiver: scriptOwner)].
		^block ].

	#autoPredicate = k ifTrue: [
		block _ OSlotMorph new type: #booleanslot.
		(tuple at: 4) ifNotNil: [
			block replaceArgMorph: block argMorphs first by: (self stackFromTupleList: (tuple at: 4) receiver: scriptOwner)].
		^block ].

	#doCustomBlock = k ifTrue: [
		userSpec _ tuple at: 4.
		def _ (rcvr definitionFor: (CustomBlockDefinition idFromSpec: userSpec)).
		(def isNil or: [#none = def type])
			ifTrue: [block _ CustomCommandBlockMorph new]
			ifFalse: [
				block _ CustomReporterBlockMorph new.
				block isBoolean: def type = #boolean].
		block 
			receiver: rcvr;
			userSpec: userSpec.
		block isSpecialForm: true.
		block selector: #doCustomBlock.
		argCount _ block argumentCount min: tuple size - 4.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 4.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: scriptOwner.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(arg isKindOf: ScratchListMorph)
						ifTrue: [arg convertBlockTuplesToStacksFor: self].
					(block argumentAt: i) defaultValue: arg]].
		^block].

	#doMakeNewList = k ifTrue: [
		block _ MultiArgReporterBlockMorph new
			color: ScriptableScratchMorph listBlockColor;
			receiver: rcvr;
			isSpecialForm: true;
			selector: #doMakeNewList.
		spec _ 'list'.
		argCount _ tuple size - 3.
		argCount timesRepeat: [ spec _ spec, ' %s' ].
		block commandSpec: spec.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 3. 
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: rcvr.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].
		^block].


	(#(doCallBlockWithArgs doReport doCallBlockWithArgList) includes: k) ifTrue: [
		block _ MultiArgReporterBlockMorph new
			color: (ScriptableScratchMorph blockColorFor: 'control');
			receiver: rcvr;
			isSpecialForm: true;
			minArgs: 1;
			selector: k.
		spec _ rcvr blockSpecForSelector: k.
		argCount _ tuple size - 3. 
		(argCount - 3) timesRepeat: [ spec _ spec, ' %s' ].
		block commandSpec: spec.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 3.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: rcvr.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					((block argumentAt: i) isKindOf: ChoiceArgMorph)
						ifTrue: [(block argumentAt: i) privateSetChoice: arg asString]
						ifFalse: [arg isNil
							ifFalse: [(block argumentAt: i) stringExpression: arg asString]]]].
		^block].

	(#(function functionWithArgs) includes: k) ifTrue: [
		block _ ReporterScriptBlockMorph new
			color: (ScriptableScratchMorph blockColorFor: 'operators');
			receiver: rcvr;
			isSpecialForm: false;
			minArgs: 1;
			selector: k;
			parameters: (tuple at: 4) asOrderedCollection;
			variables: (tuple at: 5) asOrderedCollection;
			type: (tuple at: 6);
			declarations: (tuple at: 7);
			isAtomic: (tuple at: 8).
		spec _ scriptOwner blockSpecForSelector: k. 
		argCount _ tuple size - 9.
		(argCount - 2) timesRepeat: [ spec _ spec, ' %s' ].
		block commandSpec: spec.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 8.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: rcvr.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].
		block fixInitialFrame.
		^block].

	#doDeclareVariables = k ifTrue: [
		block _ VariableDeclarationBlockMorph new
			receiver: rcvr;
			color: Color gray;
			isSpecialForm: true;
			minArgs: 1;
			selector: k.
		argCount _ tuple size - 3.
		spec _ 'script variables' localized.
		argCount timesRepeat: [ spec _ spec, ' %s' ].
		block commandSpec: spec.
		1 to: argCount do: [:i |
			arg _ tuple at: i + 3.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: rcvr.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].
		^block].



	(#(EventHatMorph KeyEventHatMorph MouseClickEventHatMorph WhenHatBlockMorph) includes: k) ifTrue: [
		block _ self hatBlockFromTuple: tuple receiver: rcvr.
		(block isKindOf: WhenHatBlockMorph) ifTrue: [block color: Color red].
		^ block].

	#scratchComment = k ifTrue: [
		block _ ScratchCommentMorph new.
		tuple size > 3 ifTrue: [block commentMorph contents: (tuple at: 4)].
		tuple size > 4 ifTrue: [(tuple at: 5) ifFalse: [block toggleShowing]].
		tuple size > 5 ifTrue: [block width: (tuple at: 6)].
		tuple size > 6 ifTrue: [block anchor: (self blockWithID: (tuple at: 7))].
		block toggleShowing; toggleShowing.
		^ block].

	#comment: = k ifTrue: [
		block _ CommentBlockMorph new.
		tuple size > 1 ifTrue: [block comment: (tuple at: 2)].
		tuple size > 2 ifTrue: [(tuple at: 3) ifFalse: [block toggleShowing]].
		block color: (Color r: 0.8 g: 0 b: 0).  "obsolete"
		^ block].

	spec _ BlockSpecDict at: k ifAbsent: [nil].
	spec ifNil: [
		^ rcvr
			blockFromSpec: #('obsolete!!' - yourself)
			color: Color red].

	blockColor _ BlockColorDict at: k ifAbsent: [Color red].
	block _ rcvr blockFromSpec: spec color: blockColor.


	#procedure = block selector ifTrue: [
		block
			parameters: (tuple at: 4) asOrderedCollection;
			variables: (tuple at: 5) asOrderedCollection;
			type: (tuple at: 6);
			declarations: (tuple at: 7);
			isAtomic: (tuple at: 8).
		argCount _ tuple size - 9. 
		argCount > 1 ifTrue: [
			csp _ block commandSpec.
			argCount - 1 timesRepeat: [ csp _ csp, ' %s' ].
			block commandSpec: csp ].
		1 to: argCount do: [:i |
			arg _ tuple at: i + 8.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: rcvr.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].

			(tuple last isKindOf: Array) ifTrue: [
				block firstBlockList: (self stackFromTupleList: tuple last receiver: rcvr)].
		block fixInitialFrame.
		^block].

	#procedureWithArgs = block selector ifTrue: [
		block
			parameters: (tuple at: 4) asOrderedCollection;
			variables: (tuple at: 5) asOrderedCollection;
			type: (tuple at: 6);
			declarations: (tuple at: 7);
			isAtomic: (tuple at: 8).
		argCount _ tuple size - 9. 
		argCount > 1 ifTrue: [
			csp _ block commandSpec.
			argCount - 1 timesRepeat: [ csp _ csp, ' %s' ].
			block commandSpec: csp ].
		1 to: argCount do: [:i |
			arg _ tuple at: i + 8.
			(arg isKindOf: Array)
				ifTrue: [ "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: rcvr.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [ "argument is a value"
					(block argumentAt: i) stringExpression: arg asString]].

			(tuple last isKindOf: Array) ifTrue: [
				block firstBlockList: (self stackFromTupleList: tuple last receiver: rcvr)].
		block fixInitialFrame.
		^block].


	(block isKindOf: CommandBlockMorph) ifTrue: [
		argCount _ block argumentCount min: tuple size - 3.

		(block isKindOf: MultiArgCommandBlockMorph) ifTrue: [
			argCount _ tuple size - 3.
			csp _ block commandSpec.
			(argCount - 3) timesRepeat: [ csp _ csp, ' %s' ].
			block commandSpec: csp.
			1 to: argCount do: [:i |
				arg _ tuple at: i + 3.
				(arg isKindOf: Array)
					ifTrue: [ "argument is a block"
						((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
						argBlock _ self blockFromTuple: arg receiver: rcvr.
						block replaceArgMorph: (block argumentAt: i) by: argBlock]
					ifFalse: [ "argument is a value"
						((block argumentAt: i) isKindOf: ChoiceArgMorph)
							ifTrue: [(block argumentAt: i) privateSetChoice: arg asString]
							ifFalse: [(block argumentAt: i) stringExpression: arg asString]]].
			^block].

		1 to: argCount do: [:i |
			((#(+ - / * =) includes: block selector) and: [ScratchTranslator isRTLMath]) "RTLMath operators are RTL"
				ifTrue: [arg _ tuple at: ((argCount + 3) - (i - 1))]
				ifFalse: [arg _ tuple at: i + 3].
			(arg isKindOf: Array)
				ifTrue: [  "argument is a block"
					((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
					argBlock _ self blockFromTuple: arg receiver: scriptOwner.
					block replaceArgMorph: (block argumentAt: i) by: argBlock]
				ifFalse: [  "argument is a value"
					(arg isKindOf: ScratchListMorph)
						ifTrue: [arg convertBlockTuplesToStacksFor: self].
					(block argumentAt: i) defaultValue: arg]].

		(block isKindOf: CBlockMorph) ifTrue: [
			(tuple last isKindOf: Array) ifTrue: [
				block firstBlockList: (self stackFromTupleList: tuple last receiver: rcvr)]].

		(block isKindOf: IfElseBlockMorph) ifTrue: [
			arg _ tuple at: tuple size - 1.
			(arg isKindOf: Array) ifTrue: [
				block trueBlock: (self stackFromTupleList: arg receiver: rcvr)].
			arg _ tuple at: tuple size.
			(arg isKindOf: Array) ifTrue: [
				block falseBlock: (self stackFromTupleList: arg receiver: rcvr)]].

		(block isKindOf: ReporterBlockMorph) ifTrue: [
			((spec at: 2) includes: $b) ifTrue: [block isBoolean: true]]].

	^ block
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jm 12/10/2003 18:06'!
blockReceiver
	"Answer the object that is the receiver of my blocks. By default that is myself, but subclasses may re-direct block operations to another object."

	^ self
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 12/1/2009 19:25'!
blockSpecForSelector: aSymbol
	"Answer a block specification string (in English) for the give selector or nil if there is no spec that has the given selector."

	self class blockSpecs do: [:spec |
		((spec isKindOf: Array) and: [(spec at: 3) = aSymbol])
			ifTrue: [^ spec first]].

	^ nil
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 8/2/2010 22:06'!
blockVariableBlockFromTuple: tuple receiver: scriptOwner
	"Answer a new block for the given variable reference tuple."

	| varName rcvr selector block arg argBlock |
	#byob = tuple first ifFalse: [
		^ self blockVariableBlockFromTupleOldForm: tuple receiver: scriptOwner ].

	varName _ tuple at: 4.
	rcvr _ scriptOwner.

	tuple third = #readBlockVariable ifTrue: [
		((tuple at: 5) isKindOf: VariableFrame) 
			ifTrue: [ rcvr _ (tuple at: 5) convertTuplesToStacks ]
			ifFalse: [ rcvr _ VariableFrame new "definitionFor: (CustomBlockDefinition idFromSpec: (tuple at: 5))" ]. 
		^VariableBlockMorph new
"			color: (ScriptableScratchMorph blockColorFor: 'variables');"
			receiver: rcvr;
			selector: #getVar:;
			commandSpec: varName;
			isSpecialForm: true ].

	tuple third = #changeBlockVariable ifTrue: [
		selector _ tuple at: 5.
		((tuple at: 6) isKindOf: VariableFrame) 
			ifTrue: [ rcvr _ (tuple at: 6) convertTuplesToStacks ]
			ifFalse: [ rcvr _ rcvr definitionFor: (CustomBlockDefinition idFromSpec: (tuple at: 6))]. 

		block _ SetterBlockMorph new
			color: (ScriptableScratchMorph blockColorFor: 'variables').

		(#(setVar:to: setBlockVar:to:) includes: selector)
			ifTrue: [block initSetterForVar: varName]
			ifFalse: [block initChangerForVar: varName].

		block 
			receiver: rcvr;
			isSpecialForm: true.

		arg _ tuple at: 7.
		(arg isKindOf: Array)
			ifTrue: [  "argument is a block"
				((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
				argBlock _ self blockFromTuple: arg receiver: scriptOwner.
				block replaceArgMorph: block expressionArg by: argBlock]
			ifFalse: [ "argument is a value"
				block expressionArg defaultValue: arg].

		^ block].

	self error: 'unknown block variable spec'

! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 8/2/2010 22:06'!
blockVariableBlockFromTupleOldForm: tuple receiver: scriptOwner
	"Answer a new block for the given variable reference tuple."

	| varName rcvr selector block arg argBlock |
	varName _ tuple at: 2.
	rcvr _ scriptOwner.

	tuple first = #readBlockVariable ifTrue: [
		(tuple third isKindOf: VariableFrame) 
			ifTrue: [ rcvr _ tuple third convertTuplesToStacks ]
			ifFalse: [ rcvr _ rcvr definitionFor: (CustomBlockDefinition idFromSpec: tuple third) ]. 
		^ VariableBlockMorph new
"			color: (ScriptableScratchMorph blockColorFor: 'variables');"
			receiver: rcvr;
			selector: #getVar:;
			commandSpec: varName;
			isSpecialForm: true ].

	tuple first = #changeBlockVariable ifTrue: [
		selector _ tuple at: 3.
		(tuple fourth isKindOf: VariableFrame) 
			ifTrue: [ rcvr _ tuple fourth convertTuplesToStacks ]
			ifFalse: [ rcvr _ rcvr definitionFor: (CustomBlockDefinition idFromSpec: tuple fourth) ]. 

		block _ SetterBlockMorph new
			receiver: rcvr;
			color: (ScriptableScratchMorph blockColorFor: 'variables').

		(#(setVar:to: setBlockVar:to:) includes: selector)
			ifTrue: [block initSetterForVar: varName]
			ifFalse: [block initChangerForVar: varName].

		block isSpecialForm: true.

		arg _ tuple at: 5.
		(arg isKindOf: Array)
			ifTrue: [  "argument is a block"
				((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
				argBlock _ self blockFromTuple: arg receiver: scriptOwner.
				block replaceArgMorph: block expressionArg by: argBlock]
			ifFalse: [ "argument is a value"
				block expressionArg defaultValue: arg].

		^ block].

	self error: 'unknown block variable spec'

! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 9/14/2010 11:36'!
blockWithID: id

	| topBlockList blockList|

	topBlockList _ (blocksBin submorphs select: [:m | (m isKindOf: BlockMorph) ]) reversed.
	blockList _ OrderedCollection new.
	topBlockList do: [:top | (top allMorphs select: [:b| b isKindOf: BlockMorph ]) do: [:m |
		blockList add: m ]].

	^ blockList at: id ifAbsent: [nil].
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jm 9/25/2003 12:45'!
blocksBin

	^ blocksBin
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 1/12/2011 00:28'!
blocksFor: aCategory
	"Answer a collection of blocks for the given category. Mixed with the blocks are dash and tilde symbols (#- and #~) indicating where full and half spaces should be inserted when laying out the blocks."

	| blockColor blocksList category b cdefs inherited all |
	blockColor _ self class blockColorFor: aCategory.
	blocksList _ OrderedCollection new.
	category _ nil.
	self class blockSpecs do: [:spec |
		((spec isKindOf: String) and: [spec ~= #- and: [spec ~= #~ and: [spec ~= #=]]])
			ifTrue: [category _ spec]
			ifFalse: [
				category = aCategory ifTrue: [
					(spec = #-) | (spec = #~)  | (spec = #=)
						ifTrue: [blocksList addLast: spec]
						ifFalse: [
							(b _ self blockFromSpec: spec color: blockColor) ifNotNil: [
								blocksList addLast: b]]]]].

	"add custom blocks (jens)"
	inherited _ self inheritedBlocks select: [:def |
		def category = aCategory asSymbol ].

	customBlocks 
		ifNil: [cdefs _ Set new]
		ifNotNil: [ cdefs _ customBlocks select: [:def | 
			def category = aCategory asSymbol]].

	all _ inherited, cdefs.
	all isEmpty ifFalse: [
		blocksList
			add: #=.
		all _ all asSortedCollection: [:x :y | x commandSpec <= y commandSpec].
		blocksList addAll: (all collect: [:each | self newCustomBlockFor: each ])].

	^ blocksList asArray
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 8/16/2010 01:02'!
convertStacksToTuples
	"Convert my blocks bin from a morph containing block stack into a collection of (<point>, <tuple>) pairs the represent the same stacks in compact, language-independent form."

	| stacks blocks comments |
	(blocksBin isKindOf: Array) ifTrue: [^ self].  "already converted"

	self lists do: [:l | l convertStacksToTuples ].
	self convertListVarReferencesToTuples.

	stacks _ (blocksBin submorphs select: [:m | m respondsTo: #tupleSequence]).
	blocks _ stacks select: [:m | m isKindOf: BlockMorph].
	comments _ stacks select: [:m | m isKindOf: ScratchCommentMorph].

	blocks _ blocks collect: [:blockM | 
		Array
			with: blockM position - blocksBin position
			with: blockM tupleSequence].

	comments _ comments collect: [:blockM |
		Array
			with: blockM position - blocksBin position
			with: blockM tupleSequence].

	blocksBin _ blocks, comments.

	customBlocks ifNil: [^self].
	customBlocks do: [:eachDef|
		eachDef fixBlockVarReporters.
		eachDef body ifNotNil: [
			eachDef body: eachDef body tupleSequence ].
		eachDef answer ifNotNil: [
			(eachDef answer isKindOf: ReporterBlockMorph) 
				ifTrue:[	eachDef answer: eachDef answer tupleSequence ]]].

! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 7/30/2010 00:21'!
convertTuplesToStacks
	"Convert my blocks bin from a collection of (<point>, <tuple>) pairs into a morph containing a number of block stacks."

	| tuplesList stack |

	(blocksBin isKindOf: Array) ifFalse: [^ self].  "already converted"

	self lists do: [:l | l convertTuplesToStacks ].
	self convertVarTuplesToListReferences.
	self convertTuplesToDefinitions.

	tuplesList _ blocksBin.
	blocksBin _ ScratchScriptsMorph new.
	tuplesList do: [:pair |
		stack _ self stackFromTupleList: pair second receiver: self.
		stack position: pair first.
		blocksBin addMorph: stack].

	blocksBin allMorphsDo: [:m |
		(m isKindOf: AttributeArgMorph) ifTrue: [
			m refresh ]]

! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'ee 6/2/2009 14:17'!
costumesPage: xOffset
	"Answer a morph containing thumbnails of my costumes."

	| bin label m y images n recBut impBut photoBut maxHeight xMargin yMargin separator |
	xMargin _ 15.
	yMargin _ 15.

	bin _ ScratchBlockPaletteMorph new color: ScratchFrameMorph scriptsPaneColor.

	(self isKindOf: ScratchStageMorph)
		ifTrue: [label _ 'New background:' localized]
		ifFalse: [label _ 'New costume:' localized].
	m _ StringMorph
		contents: label
		font: (ScratchFrameMorph getFont: #CostumesPage).
	m color: Color white.
	bin addMorph: m.

	recBut _ ScratchFrameMorph buttonLabel: 'Paint' localized selector: #drawNewCostume.
	recBut target: self.
	bin addMorph: recBut.

	impBut _ ScratchFrameMorph buttonLabel: 'Import' localized selector: #importImage.
	impBut target: self.
	bin addMorph: impBut.

	photoBut _ ScratchFrameMorph buttonLabel: 'Camera' localized selector: #takePhoto.
	photoBut target: self.
	bin addMorph: photoBut.

	maxHeight _ (m height max: (impBut height max: (recBut height max: photoBut height))).
	ScratchTranslator isRTL
		ifTrue: [
			photoBut position: xMargin@(yMargin + ((maxHeight - photoBut height) / 2)).
			impBut position: (photoBut right + 4)@(yMargin + ((maxHeight - impBut height) / 2)).
			recBut position: (impBut right + 4)@(yMargin + ((maxHeight - recBut height) / 2)).
			m position: (recBut right + 4)@(yMargin + ((maxHeight - m height) / 2))]
		ifFalse: [
			m position: xMargin@(yMargin + ((maxHeight - m height) / 2)).
			recBut position: (m right + 4)@(yMargin + ((maxHeight - recBut height) / 2)).
			impBut position: (recBut right + 4)@(yMargin + ((maxHeight - impBut height) / 2)).
			photoBut position: (impBut right + 4)@(yMargin + ((maxHeight - impBut height) / 2))].

	separator _ TiledImageMorph new tileForm: (ScratchFrameMorph skinAt: #costumeSeparatorTile).
	bin addMorph: (separator position: (xOffset + 17)@(yMargin + maxHeight + 5)).

	y _ yMargin + maxHeight + 9.
	n _ 0.
	images _ media select: [:item | item isImage].
	images do: [:item |
		m _ MediaItemMorph new.
		m scratchObj: self media: item; position: xOffset@y.
		m setNumber: (n _ n + 1).
		item = costume ifTrue: [m highlight: true].
		bin addMorph: m.
		y _ y + m height - 1.].

	bin submorphs size > 0
		ifTrue: [separator width: bin firstSubmorph width - 14]
		ifFalse: [separator width: 240].

	^ bin
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 2/23/2010 01:28'!
createBlock: block atPosition: pos onPage: page
	"Creates a block on the given page. If the block is one that can become a watcher, then a toggle button is created as well."

	| x y changingX toggleButton yOffset frame |

	"don't create the following blocks, but keep their specs so they can be toggles using right / left arrows"

	((block respondsTo: #selector) and: [
	(#(	doRunBlockWithArgs 
		doRunBlockWithArgList
		doForkBlockWithArgs 
		doForkBlockWithArgList
		doCallBlockWithArgs 
		doCallBlockWithArgList
		functionWithArgs 
		procedureWithArgs) 
	includes: block selector)])
		ifTrue: [^pos y ].

	x _ pos x.
	y _ pos y.
	changingX _ x.
	block canBecomeWatcher ifTrue: [
		toggleButton _ self createToggleButtonFor: block.
		yOffset _ (block fullBounds height - toggleButton fullBounds height) // 2.
		page addMorphBack: (toggleButton position: x@(y+yOffset)).
		changingX _ x + toggleButton fullBounds width + 4].

	block fixBlockLayout; position: changingX@y.
	page addMorphBack: block.
	block canBecomeWatcher ifTrue: [
		frame _ self ownerThatIsA: ScratchFrameMorph.
		page updateWatcherButtonsForFrame: frame].

	((block respondsTo: #selector) and: [block selector = #newList:]) ifTrue: [
		block argMorphs first addArgSlot].

	^ y + block height + 3
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jm 3/21/2008 14:04'!
createToggleButtonFor: block
	"Create the toggle button for each variable that could be viewed on the stage."

	| toggleButton |
	toggleButton _ ToggleButton
		onForm: (ScratchFrameMorph skinAt: #watcherButtonPressed)
		offForm: (ScratchFrameMorph skinAt: #watcherButton).

	toggleButton
		target: block;
		actionSelector: #toggleWatcher;
		borderWidth: 0;
		setProperty: #balloonText toValue: 'View on stage' localized.

	^ toggleButton
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 6/14/2010 22:19'!
defaultArgsFor: blockSpec
	"Answer the default argument for the given block specification."

	| defaultArgs stage sel currentSize list |
	defaultArgs _ blockSpec copyFrom: 4 to: blockSpec size.  "may be empty"
	stage _ self ownerThatIsA: ScratchStageMorph.

	sel _ (blockSpec at: 3) asSymbol.
	#gotoX:y: = sel ifTrue: [
		defaultArgs _ Array
			with: self referencePosition x rounded
			with: self referencePosition y rounded].

	#glideSecs:toX:y:elapsed:from: = sel ifTrue: [
		defaultArgs _ Array
			with: 1
			with: self referencePosition x rounded
			with: self referencePosition y rounded].

	#motor:direction: = self ifTrue: [
		defaultArgs _ Array with: 'reverse' localized with: 'this way' localized with: 'that way'].

	#setSizeTo: = sel ifTrue: [
		(self isKindOf: ScratchStageMorph) ifTrue: [ 	"no size ops for stage -jens"
			^Array with: 100].
		currentSize _ (100.0 * (self scalePoint x max: self scalePoint y)) rounded.
		defaultArgs _ Array with: currentSize].

	#getAttribute:of: = sel ifTrue: [
		(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
			list _ stage submorphs select: [:m | m isKindOf: ScratchSpriteMorph].
			list sort: [:s1 :s2 | s1 objName asLowercase < s2 objName asLowercase].
			list size > 0
				ifTrue: [defaultArgs _ Array with: 'x position' with: list first]
				ifFalse: [defaultArgs _ Array with: 'background #' with: stage]]
		ifNil:[defaultArgs _ Array with: 'x position' with: self]].

	#concatenate:with: = sel ifTrue: [
		defaultArgs _ Array with: 'hello ' localized with: 'world' localized].

	#doAsk = sel ifTrue: [
		defaultArgs _ Array with: 'What''s your name?' localized].

	#letter:of: = sel ifTrue: [
		defaultArgs _ Array with: 1 with: 'world' localized].

	#stringLength: = sel ifTrue: [
		defaultArgs _ Array with: 'world' localized].

	#say:duration:elapsed:from: = sel ifTrue: [
		defaultArgs _ Array with: 'Hello!!' localized with: 2].

	#say: = sel ifTrue: [
		defaultArgs _ Array with: 'Hello!!' localized].

	#think:duration:elapsed:from: = sel ifTrue: [
		defaultArgs _ Array with: 'Hmm...' localized with: 2].

	#think: = sel ifTrue: [
		defaultArgs _ Array with: 'Hmm...' localized].

	(#(lookLike: showBackground:) includes: sel) ifTrue: [
		defaultArgs _ Array with: self costumeNames last].

	(#(playSound: doPlaySoundAndWait) includes: sel) ifTrue: [
		list _ self soundNames.
		defaultArgs _ list size <= 2
			ifTrue: [Array with: '']
			ifFalse: [Array with: (list at: (list size - 2))]].

	(#(broadcast: doBroadcastAndWait) includes: sel) ifTrue: [
		stage ifNotNil: [defaultArgs _ Array with: stage defaultEventName]].

	(#(append:toList: deleteLine:ofList: insert:at:ofList:) includes: sel) ifTrue: [
		defaultArgs size >= 1 ifTrue: [
			defaultArgs at: 1 put: (defaultArgs at: 1) localized]].

	(#(append:toList: deleteLine:ofList: getLine:ofList: insert:at:ofList: lineCountOfList: contentsOfList:)
		includes: sel) ifTrue: [
			defaultArgs _ defaultArgs copyWith: self defaultListName].

	#setLine:ofList:to: = sel ifTrue: [
		defaultArgs size >= 3 ifTrue: [
			defaultArgs at: 2 put: self defaultListName.
			defaultArgs at: 3 put: (defaultArgs at: 3) localized]].

	#appendLettersOf:toList: = sel ifTrue: [
		defaultArgs size >= 2 ifTrue: [
			defaultArgs at: 1 put: (defaultArgs at: 1) localized.
			defaultArgs at: 2 put: self defaultListName]].

	#list:contains: = sel ifTrue: [
		defaultArgs size >= 2 ifTrue: [
			defaultArgs at: 1 put: self defaultListName.
			defaultArgs at: 2 put: (defaultArgs at: 2) localized]].

	^ defaultArgs
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 12/17/2009 00:56'!
hatBlockFromTuple: tuple receiver: scriptOwner
	"Answer a new block for the given variable reference tuple."

	| blockClass block eventName arg |

	#byob = tuple first ifFalse: [
		^self hatBlockFromTupleOldForm: tuple receiver: scriptOwner ].

	blockClass _ Smalltalk at: tuple third.
	block _ blockClass new scriptOwner: scriptOwner.

	blockClass = EventHatMorph ifTrue: [
		eventName _ tuple at: 4.
		eventName = 'Scratch-StartClicked'
			ifTrue: [block forStartEvent; scriptOwner: scriptOwner]
			ifFalse: [block eventName: eventName]].

	blockClass = KeyEventHatMorph ifTrue: [
		block choice: (tuple at: 4)].

	blockClass = WhenHatBlockMorph ifTrue: [
		(tuple at: 4) ~= false ifTrue: [
			arg _ self blockFromTuple: (tuple at: 4) receiver: scriptOwner.
			block replaceArgMorph: block argMorph by: arg]].

	^ block
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 12/17/2009 00:54'!
hatBlockFromTupleOldForm: tuple receiver: scriptOwner
	"Answer a new block for the given variable reference tuple."

	| blockClass block eventName arg |
	blockClass _ Smalltalk at: tuple first.
	block _ blockClass new scriptOwner: scriptOwner.

	blockClass = EventHatMorph ifTrue: [
		eventName _ tuple at: 2.
		eventName = 'Scratch-StartClicked'
			ifTrue: [block forStartEvent; scriptOwner: scriptOwner]
			ifFalse: [block eventName: eventName]].

	blockClass = KeyEventHatMorph ifTrue: [
		block choice: (tuple at: 2)].

	blockClass = WhenHatBlockMorph ifTrue: [
		(tuple at: 2) ~= false ifTrue: [
			arg _ self blockFromTuple: (tuple at: 2) receiver: scriptOwner.
			block replaceArgMorph: block argMorph by: arg]].

	^ block
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jm 9/27/2007 15:11'!
hatBlockType: blockType

	| stage evtName |
	'E' = blockType ifTrue: [
		evtName _ ''.
		(stage _ self ownerThatIsA: ScratchStageMorph)
			ifNotNil: [evtName _ stage defaultEventName].
		^ EventHatMorph new scriptOwner: self; eventName: evtName].

	'K' = blockType ifTrue: [^ KeyEventHatMorph new scriptOwner: self].
	'M' = blockType ifTrue: [^ MouseClickEventHatMorph new scriptOwner: self].
	'S' = blockType ifTrue: [^ EventHatMorph new forStartEvent scriptOwner: self].
	'W' = blockType ifTrue: [^ WhenHatBlockMorph new scriptOwner: self].
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jm 8/9/2007 17:31'!
scriptsAsTuples: tuples

	blocksBin _ tuples asArray.
	self convertTuplesToStacks.
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'ee 7/3/2008 13:05'!
soundsPage: xOffset
	"Answer a morph containing thumbnails of my sounds."

	| bin m y sounds n recBut impBut maxHeight yMargin xMargin separator |
	xMargin _ 15.
	yMargin _ 15.

	bin _ ScratchBlockPaletteMorph new.

	m _ StringMorph
		contents: 'New sound:' localized
		font: (ScratchFrameMorph getFont: #SoundsPage).
	m color: Color white.
	bin addMorph: m.

	recBut _ ScratchFrameMorph buttonLabel: 'Record' localized selector: #recordSound.
	recBut target: self.
	bin addMorph: recBut.

	impBut _ ScratchFrameMorph buttonLabel: 'Import' localized selector: #importSound.
	impBut target: self.
	bin addMorph: impBut.

	maxHeight _ (m height max: (impBut height max: recBut height)).
	ScratchTranslator isRTL
		ifTrue: [impBut position: xMargin@(yMargin + ((maxHeight - impBut height) / 2)).
			recBut position: (impBut right + 4)@(yMargin + ((maxHeight - recBut height) / 2)).
			m position: (recBut right + 4)@(yMargin + ((maxHeight - m height) / 2))]
		ifFalse: [m position: xMargin@(yMargin + ((maxHeight - m height) / 2)).
			recBut position: (m right + 4)@(yMargin + ((maxHeight - recBut height) / 2)).
			impBut position: (recBut right + 4)@(yMargin + ((maxHeight - impBut height) / 2))].

	separator _ TiledImageMorph new tileForm: (ScratchFrameMorph skinAt: #costumeSeparatorTile).
	bin addMorph: (separator position: (xOffset + 17)@(yMargin + maxHeight + 5)).

	n _ 0.
	y _ yMargin + maxHeight + 9.
	sounds _ media select: [:item | item isSound].
	sounds do: [:item |
		m _ MediaItemMorph new.
		m scratchObj: self media: item; position: xOffset@y.
		m setNumber: (n _ n + 1).
		bin addMorph: m.
		y _ y + m height - 1].

	bin submorphs size > 0
		ifTrue: [separator width: bin firstSubmorph width - 14]
		ifFalse: [separator width: 240].

	^ bin
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 12/17/2009 01:08'!
stackFromTupleList: tupleList receiver: scriptOwner
	"Answer a new block stack from the given sequence of tuples."
	"self stackFromTupleList: #() receiver: nil"

	| stackTop previousBlock block |
	stackTop _ previousBlock _ nil.
	tupleList do: [:tuple | 
		block _ self blockFromTuple: tuple receiver: scriptOwner.
		previousBlock
			ifNil: [stackTop _ block]
			ifNotNil: [previousBlock nextBlock: block].
		previousBlock _ block].

	^ stackTop
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 5/19/2011 12:29'!
variableBlockFromTuple: tuple receiver: scriptOwner
	"Answer a new block for the given variable reference tuple."

	| varName rcvr bg selector block arg argBlock |

	#byob = tuple first ifFalse: [
		^self variableBlockFromTupleOldForm: tuple receiver: scriptOwner ].

	varName _ tuple at: 4.
	rcvr _ scriptOwner.
	(varName isKindOf: Array) ifFalse: [
		varName = '' ifFalse: [
			(scriptOwner varNames includes: varName) ifFalse: [
				bg _ scriptOwner ownerThatIsA: ScratchStageMorph.
				bg
					ifNil: [scriptOwner addVariable: varName]
					ifNotNil: [
						bg addVariable: varName.
						"rcvr _ bg"]]]].

	tuple third = #readVariable ifTrue: [
		^ VariableBlockMorph new
			commandSpec: varName;
			selector: #getVar:;
			receiver: rcvr].

	tuple third = #changeVariable ifTrue: [
		selector _ tuple at: 5.
		"update selector if necessary (backward compatibility):"
		(selector = #set:to:) ifTrue: [selector _ #setVar:to:].
		block _ SetterBlockMorph new.
		block receiver: rcvr.
		selector = #setVar:to:
			ifTrue: [block initSetterForVar: varName]
			ifFalse: [block initChangerForVar: varName].

		block receiver: rcvr.

		arg _ tuple at: 6.
		(arg isKindOf: Array)
			ifTrue: [  "argument is a block"
				((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
				argBlock _ self blockFromTuple: arg receiver: scriptOwner.
				block replaceArgMorph: block expressionArg by: argBlock]
			ifFalse: [ "argument is a value"
				block expressionArg defaultValue: arg].

		^ block].

	self error: 'unknown variable spec'
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 8/2/2010 22:06'!
variableBlockFromTupleOldForm: tuple receiver: scriptOwner
	"Answer a new block for the given variable reference tuple."

	| varName rcvr bg selector block arg argBlock |

	varName _ tuple at: 2.
	rcvr _ scriptOwner.
	(scriptOwner varNames includes: varName) ifFalse: [
		bg _ scriptOwner ownerThatIsA: ScratchStageMorph.
		bg
			ifNil: [scriptOwner addVariable: varName]
			ifNotNil: [
				bg addVariable: varName.
				"rcvr _ bg"]].

	tuple first = #readVariable ifTrue: [
		^ VariableBlockMorph new
			commandSpec: varName;
			selector: #getVar:;
			receiver: rcvr].

	tuple first = #changeVariable ifTrue: [
		selector _ tuple at: 3.
		"update selector if necessary (backward compatibility):"
		(selector = #set:to:) ifTrue: [selector _ #setVar:to:].
		block _ SetterBlockMorph new.
		selector = #setVar:to:
			ifTrue: [block initSetterForVar: varName]
			ifFalse: [block initChangerForVar: varName].

		block receiver: rcvr.

		arg _ tuple at: 4.
		(arg isKindOf: Array)
			ifTrue: [  "argument is a block"
				((arg size = 1) and: [arg first isKindOf: Array]) ifTrue: [arg _ arg first].
				argBlock _ self blockFromTuple: arg receiver: scriptOwner.
				block replaceArgMorph: block expressionArg by: argBlock]
			ifFalse: [ "argument is a value"
				block expressionArg defaultValue: arg].

		^ block].

	self error: 'unknown variable spec'
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 1/8/2010 06:18'!
variablesPage
	"Answer a morph containing my variables."

	| page addButton deleteButton hasVars stage x y maxX |
	page _ ScratchBlockPaletteMorph new
		color: (Color r: 0.8 g: 0.8 b: 1.0);
		borderWidth: 0.

	addButton _ ScratchFrameMorph
		buttonLabel: 'Make a variable' localized
		selector: #addGlobalVariable.
	(self isKindOf: ScratchSpriteMorph) ifTrue: [addButton actionSelector: #addVariable].

	deleteButton _ ScratchFrameMorph
		buttonLabel: 'Delete a variable' localized
		selector: #deleteVariable.

	x _ 13.
	page addMorph: (addButton target: self; position: x@7).
	y _ addButton bottom + 3.

	hasVars _ self varNames size > 0.
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		stage varNames size > 0 ifTrue: [hasVars _ true]].

	hasVars ifTrue: [
		page addMorph: (deleteButton target: self; position: x@y).
		y _ deleteButton bottom + 10.

		y _ self addVariableReportersTo: page x: x y: y.
		y _ y + 12  ].

	y _ self addGenericVariableBlocksTo: page x: x y: y.

	y _ self addGenericListBlocksTo: page y: y.
	page updateWatcherButtonsForFrame: (self ownerThatIsA: ScratchFrameMorph).

	self addCustomBlocksTo: page y: y.

	maxX _ page submorphs inject: 0 into: [:t :m | t max: m right].
	page extent: (maxX + 10) @ y.
	^ page
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jm 5/19/2009 22:09'!
viewBlocksAndScripts

	| sFrame editor viewer tabs |
	self isClone ifTrue: [^ self].

	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self].
	editor _ sFrame scriptsPane.
	viewer _ sFrame viewerPane.
	tabs _ sFrame scriptsPane tabPane.
	sFrame view: self tab: tabs currentTab category: viewer currentCategory.

	self world ifNotNil: [
		self zoomRectFrom: self bounds to: editor bounds].
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 6/8/2010 22:42'!
viewerPageForCategory: aCategoryName
	"Answer a morph containing blocks for the given category for use in the given ScratchViewer."

	| bin x y |
	aCategoryName = 'variables' ifTrue: [^ self variablesPage].
	aCategoryName = 'motion' ifTrue: [^ self viewerPageForMotion].
	aCategoryName = 'sensing' ifTrue: [^ self viewerPageForSensing].

	bin _ ScratchBlockPaletteMorph new.
	x _ 12.
	y _ 10.
	(self blocksFor: aCategoryName) do: [:blockOrSym |
		(blockOrSym = #-) | (blockOrSym = #~) | (blockOrSym = #=)
			ifTrue: [
				(blockOrSym = #-) ifTrue: [y _ y + 15].  "insert a full space"
				(blockOrSym = #~) ifTrue: [y _ y + 5].  "insert a half space"
				(blockOrSym = #=) ifTrue: [
					y _ y + 7.
					bin addMorph: ((ImageMorph new form: (ScratchFrameMorph skinAt: #connector)) position: x@y).
					y _ y + 20]]  "insert a line"
			ifFalse: [
				y _ self createBlock: blockOrSym atPosition: x@y onPage: bin]].

	^ bin
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 1/7/2010 03:12'!
viewerPageForMotion
	"Answer a morph containing mtion blocks for the given category for use in the given ScratchViewer."

	| bin isStage addMotorBlocks s font x y m |
	bin _ ScratchBlockPaletteMorph new.

	(self isKindOf: ScratchStageMorph)
		ifTrue: [
			isStage _ true.
			addMotorBlocks _ self showMotorBlocks]
		ifFalse: [
			isStage _ false.
			s _ self ownerThatIsA: ScratchStageMorph.
			addMotorBlocks _ s notNil and: [s showMotorBlocks]].

	(isStage & addMotorBlocks not) ifTrue: [
		font _ (ScratchFrameMorph getFont: #ViewerPage).
		x _ 20.
		y _ 12.
		m _ StringMorph contents: 'Stage selected:' localized font: font.
		bin addMorph: (m color: Color white; position: x@y).
		m _ StringMorph contents: 'No motion blocks' localized font: font.
		bin addMorph: (m color: Color white; position: x@(y + 17)).
		^ bin].

	x _ 12.
	y _ 10.
	(self blocksFor: 'motion') do: [:blockOrSym |
		(blockOrSym = #-) | (blockOrSym = #~) |  (blockOrSym = #=)
			ifTrue: [
				(blockOrSym = #-) ifTrue: [y _ y + 15].  "insert a full space"
				(blockOrSym = #~) ifTrue: [y _ y + 5].  "insert a half space"
				(blockOrSym = #=) ifTrue: [
					y _ y + 7.
					bin addMorph: ((ImageMorph new form: (ScratchFrameMorph skinAt: #connector)) position: x@y).
					y _ y + 20]]  "insert a line"
			ifFalse: [
				y _ self createBlock: blockOrSym atPosition: x@y onPage: bin]].

	addMotorBlocks ifFalse: [^ bin].

	isStage ifFalse: [
		y _ y + 7.
		bin addMorph: ((ImageMorph new form: (ScratchFrameMorph skinAt: #connector)) position: x@y).
		y _ y + 20].

	(self blocksFor: 'motor') do: [:blockOrSym |
		(blockOrSym = #-) | (blockOrSym = #~)
			ifTrue: [
				(blockOrSym = #-) ifTrue: [y _ y + 15].  "insert a full space"
				(blockOrSym = #~) ifTrue: [y _ y + 5]]  "insert a half space"
			ifFalse: [
				y _ self createBlock: blockOrSym atPosition: x@y onPage: bin]].

	^ bin
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 1/7/2010 03:16'!
viewerPageForSensing
	"Answer a morph containing mtion blocks for the given category for use in the given ScratchViewer."

	| bin x y |
	bin _ ScratchBlockPaletteMorph new.
	x _ 12.
	y _ 10.
	(self blocksFor: 'sensing') do: [:blockOrSym |
		(blockOrSym = #-) | (blockOrSym = #~) |  (blockOrSym = #=)
			ifTrue: [
				(blockOrSym = #-) ifTrue: [y _ y + 15].  "insert a full space"
				(blockOrSym = #~) ifTrue: [y _ y + 5].  "insert a half space"
				(blockOrSym = #=) ifTrue: [
					y _ y + 7.
					bin addMorph: ((ImageMorph new form: (ScratchFrameMorph skinAt: #connector)) position: x@y).
					y _ y + 20]]  "insert a line"
			ifFalse: [
				y _ self createBlock: blockOrSym atPosition: x@y onPage: bin]].

	^ bin
! !

!ScriptableScratchMorph methodsFor: 'blocks' stamp: 'jens 12/18/2009 04:45'!
wholeBlockSpecForSelector: aSymbol
	"Answer a block specification string (in English) for the give selector or nil if there is no spec that has the given selector."

	self class blockSpecs do: [:spec |
		((spec isKindOf: Array) and: [(spec at: 3) = aSymbol])
			ifTrue: [^ spec]].

	^ nil
! !


!ScriptableScratchMorph methodsFor: 'dropping/grabbing' stamp: 'jm 12/30/2008 18:37'!
justDroppedInto: newOwner event: evt
	"If I'm dropped into any submorph of a ScratchFrameMorph, reject the drop unless it is onto the work pane. For developers, accept drops into other morphs (e.g. the World). Otherwise, reject the drop."

	| sFrame |
	(sFrame _ newOwner ownerThatIsA: ScratchFrameMorph) ifNotNil: [
		newOwner = sFrame viewerPane pageViewer contents ifTrue: [
			self undoableDeleteSprite.
			sFrame libraryPane step.
			^ self].

		newOwner = sFrame workPane ifTrue: [^ self]. "allow drops onto the work pane"
		^ self rejectDropEvent: evt].

	Preferences noviceMode ifTrue: [^ self rejectDropEvent: evt].
! !

!ScriptableScratchMorph methodsFor: 'dropping/grabbing' stamp: 'jm 8/3/2003 13:21'!
rejectDropEvent: evt
	"Reject being dropped by the given event."

	evt hand rejectDropMorph: self event: evt.
! !


!ScriptableScratchMorph methodsFor: 'event handling' stamp: 'jm 11/28/2007 15:07'!
click: evt
	"Start or stop all my clickable scripts."

	| h clickEvt |
	h _ World activeHand.
	h toolType ifNotNil: [^ self handleTool: h toolType hand: h].

	clickEvt _ ScratchEvent new
		name: 'Scratch-MouseClickEvent'
		argument: 0.
	self eventReceived: clickEvt.
! !

!ScriptableScratchMorph methodsFor: 'event handling' stamp: 'jm 10/7/2005 15:56'!
doubleClick: evt
	"Show my viewer and script editor."
	
	| hand |
	hand _ self world activeHand.
	hand toolType ifNotNil: [
		^ self handleTool: hand toolType hand: hand].

	self viewBlocksAndScripts.
! !

!ScriptableScratchMorph methodsFor: 'event handling' stamp: 'tis 12/10/2006 23:50'!
handleTool: toolName hand: hand

	| scaleFactor |
	toolName = 'CopyTool' ifTrue: [
		Sensor shiftPressed ifFalse: [hand toolType: nil].
		(self isKindOf: ScratchStageMorph) ifFalse: [
			^ self duplicate]].

	toolName = 'CutTool' ifTrue: [
		Sensor shiftPressed ifFalse: [hand toolType: nil].
		(self isKindOf: ScratchStageMorph) ifFalse: [
			^ self undoableDeleteSprite]].

	"exit now if I am not scalable"
	(self respondsTo: #multiplySizeBy:) ifFalse: [
		self beep.
		hand toolType: nil.
		^ self].

	scaleFactor _ hand lastEvent shiftPressed ifTrue: [1.2] ifFalse: [1.03].
	toolName = 'ZoomInTool' ifTrue: [^ self multiplySizeBy: scaleFactor].
	toolName = 'ZoomOutTool' ifTrue: [^ self multiplySizeBy: 1.0 / scaleFactor].
! !

!ScriptableScratchMorph methodsFor: 'event handling' stamp: 'jm 6/2/2009 11:44'!
handlesMouseDown: evt

	^ self isVisible
! !

!ScriptableScratchMorph methodsFor: 'event handling' stamp: 'jm 11/27/2007 16:04'!
mouseDown: evt
	"Handle a mouse click. Left button either drags or performs click action. Right button brings up a menu."

	evt hand newKeyboardFocus: nil.

	evt hand toolType ifNotNil: [
		self handleTool: evt hand toolType hand: evt hand.
		^ self].

	evt rightButtonPressed
		ifTrue: [Sensor waitNoButton. ^ self rightButtonMenu]
		ifFalse:	[evt hand waitForClicksOrDrag: self event: evt].
! !

!ScriptableScratchMorph methodsFor: 'event handling' stamp: 'jm 12/19/2008 17:19'!
mouseHold: evt

	self rightButtonMenu.
! !

!ScriptableScratchMorph methodsFor: 'event handling' stamp: 'jm 8/3/2003 23:42'!
startDrag: evt
	"This is a drag gesture; pick me up."

	| rootForGrab |
	rootForGrab _ owner rootForGrabOf: self.
	rootForGrab ifNil: [^ self].
	rootForGrab position: evt hand position + (self topLeft - evt cursorPoint).
	evt hand grabMorph: rootForGrab.
! !


!ScriptableScratchMorph methodsFor: 'right button menu' stamp: 'jens 2/9/2011 10:50'!
duplicateNoAttach
	"Duplicate this sprite, but do not attach to the hand."

	| newSprite frame |
	newSprite _ self fullCopy.
	newSprite undeleteAllAttributes.
	newSprite unhinge; unhingeAll; initializeNodes.
	newSprite position: (newSprite position + 20).
	frame _ self ownerThatIsA: ScratchFrameMorph.
	frame ifNotNil: [
		frame workPane addMorphFront: newSprite.
		frame workPane sprites addLast: newSprite].
	^ newSprite
! !

!ScriptableScratchMorph methodsFor: 'right button menu' stamp: 'jm 8/2/2004 21:43'!
editDrawing
	"Edit my current form with the paint editor."

	self editDrawingOldCostumeName: nil deleteOnCancel: false.
! !

!ScriptableScratchMorph methodsFor: 'right button menu' stamp: 'jm 3/3/2008 11:42'!
editDrawingOldCostumeName: oldCostumeName deleteOnCancel: aBoolean
	"Edit my original form with the paint editor."

	| sFrame paintEditor |
	costume isMovie ifTrue: [^ self beep].
	(sFrame _ self ownerThatIsA: ScratchFrameMorph)
		ifNotNil: [
			sFrame paintingInProgress ifTrue: [^ self beep].
			sFrame stopAll.
			sFrame paintingInProgress: true].

	paintEditor _ PaintFrame new.
	paintEditor
		withStartingObject: self;
		scratchFrame: sFrame;
		oldCostumeName: oldCostumeName deleteOnCancel: aBoolean.

	oldCostumeName ifNotNil: [
		"When an oldCostumeName is supplied, it means I'm making a new drawing. Clear the initial rotation center."
		paintEditor clearRotationCenter].

	(paintEditor isKindOf: DialogBoxMorph)
		ifTrue: [paintEditor getUserResponse]
		ifFalse: [
			World addMorphFront: paintEditor.
			World startSteppingSubmorphsOf: paintEditor].
! !

!ScriptableScratchMorph methodsFor: 'right button menu' stamp: 'jens 3/3/2011 10:21'!
exportObject

	| fName dir f objToExport |
	fName _ ScratchFileChooserDialog
		chooseNewFileDefault: objName
		title: 'Export Sprite'
		type: #sprite.
	fName = #cancelled ifTrue: [^ self].
	fName size = 0 ifTrue: [^ self].
"	(fName endsWith: '.sprite') ifFalse: [fName _ fName, '.sprite']."
	(fName endsWith: '.ysp') ifFalse: [fName _ fName, '.ysp'].
	fName _ FileDirectory localNameFor: fName.  "ignore path, if any; save in default directory"

	dir _ ScratchFileChooserDialog getLastFolderForType: #sprite.
	(dir fileExists: fName) ifTrue: [
		(DialogBoxMorph ask: 'Overwrite existing ', fName, '?') ifFalse: [^ self].
		dir deleteFileNamed: fName].


	f _ nil.
	[	f _ (dir newFileNamed: fName) binary.
		objToExport _ self copyForExport.
		objToExport objName: fName.

		objToExport firstSubmorph allSubsprites do: [:eachSub |
			eachSub owner ifNil: [objToExport addMorphBack: eachSub ]].

		ObjStream new storeObj: objToExport on: f showProgress: true.
		f close.
		dir setMacFileNamed: fName type: 'STyp' creator: 'BYOB'.

	] ifError: [
		f ifNotNil: [f close].
		self inform: 'Could not write file' withDetails: 'Export failed' localized].

! !

!ScriptableScratchMorph methodsFor: 'right button menu' stamp: 'jens 3/22/2011 11:25'!
makeVisible
	"Make sure that I am entirely on the screen and visible."

	self isHidden ifTrue: [self isHidden: false].
	visibility < 30 ifTrue: [self setGraphicEffect: 'ghost' to: 100].
	self scale < 10 ifTrue: [self setSizeTo: 100].
	(owner notNil and: [owner bounds containsPoint: self center]) ifFalse: [
		self gotoX: 0 y: 0 ].
	self comeToFront.
	World displayWorldSafely.

"	self viewBlocksAndScriptsQuickly."
! !

!ScriptableScratchMorph methodsFor: 'right button menu' stamp: 'jm 5/25/2004 14:18'!
rightButtonMenu
	"This default implementation does nothing."
! !


!ScriptableScratchMorph methodsFor: 'media' stamp: 'tis 8/20/2006 22:45'!
addMediaItem: aScratchMedia
	"Add the given media item to my media."

	aScratchMedia mediaName: (self unusedMediaNameFromBaseName: aScratchMedia mediaName).
	media addLast: aScratchMedia.
	aScratchMedia isSound ifFalse: [self lookLike: aScratchMedia mediaName].
	self updateMediaCategory.! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 6/8/2009 10:23'!
costumeNames
	"Answer a list of my costume (costume = non-sound media object) names."

	| result nm |
	result _ OrderedCollection new.
	media do: [:el |
		el isSound ifFalse: [
			nm _ el mediaName.
			(result includes: nm) ifFalse: [result add: nm]]].

	result _ result asArray.
	CameraPlugin cameraIsAvailable ifTrue: [
		result _ result copyWith: '*** camera ***'].
	^ result
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 8/7/2008 13:16'!
defaultImageMedia
	"Placeholder image media."

	^ ImageMedia new
		form: (Form extent: 8@8 depth: 8) fillWhite;
		mediaName: ('costume' localized, '1')
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 23:23'!
deleteMedia: itemToDelete
	"Delete the given media item."

	| oldIndex costumesBefore costumesAfter newCostume |
	oldIndex _ media indexOf: itemToDelete.
	media remove: itemToDelete ifAbsent: [].
	itemToDelete isSound ifTrue: [itemToDelete sound pause].

	itemToDelete == costume ifTrue: [
		"select the costume just before or after the costume being deleted"
		costumesBefore _ (media copyFrom: 1 to: oldIndex - 1) select: [:item | item isSound not].
		costumesAfter _ (media copyFrom: oldIndex to: media size) select: [:item | item isSound not].
		costumesBefore size > 0
			ifTrue: [newCostume _ costumesBefore last]
			ifFalse: [
				costumesAfter size > 0
					ifTrue: [newCostume _ costumesAfter first]
					ifFalse: [media addLast: (newCostume _ itemToDelete)]].
		self lookLike: newCostume mediaName].

	self updateMediaCategory.

	itemToDelete isSound 
		ifTrue: [
			self undeleteAttribute: #sounds.
			self propagateSounds]
		ifFalse: [
			self undeleteAttribute: #costumes.
			self propagateCostumes]
		
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 22:58'!
drawNewCostume

	| oldCostumeName newName newImage |
	oldCostumeName _ costume mediaName.
	newImage _ ImageMedia new form: (Form extent: 4@4 depth: 8).
	newName _ (self unusedMediaNameFromBaseName: self defaultImageMedia mediaName).
 	newImage mediaName: newName.
	media addLast: newImage.
	self lookLike: newImage mediaName.
	self updateMediaCategory.
	self editDrawingOldCostumeName: oldCostumeName deleteOnCancel: false.

	self undeleteAttribute: #costumes.
	self propagateCostumes

! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 23:24'!
duplicateMedia: itemToDuplicate
	"Duplicate the given media item."

	| dup |
	itemToDuplicate isSound ifTrue: [itemToDuplicate pausePlaying].
	dup _ itemToDuplicate copy.
	dup mediaName: (self unusedMediaNameFromBaseName: itemToDuplicate mediaName).
	media addLast: dup.
	self updateMediaCategory.

	itemToDuplicate isSound 
		ifTrue: [
			self undeleteAttribute: #sounds.
			self propagateSounds]
		ifFalse: [
			self undeleteAttribute: #costumes.
			self propagateCostumes]! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 22:40'!
editedForm: aForm textBox: aMultilineTextMorph

	| newImage |
	(costume isKindOf: ImageMedia) ifFalse: [
		newImage _ ImageMedia new
			form: aForm;
			mediaName: (self unusedMediaNameFromBaseName: costume mediaName).
		media addLast: newImage.
		self lookLike: newImage mediaName].

	costume form: aForm.  "replace the current costume"
	costume textBox: aMultilineTextMorph.
	self lookLike: costume mediaName.
	self viewBlocksAndScripts.
	self updateMediaCategory.

	self undeleteAttribute: #costumes.
	self propagateCostumes

! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 22:09'!
importImage
	"Import a new image from a file and add it to my media (concatenating the name if it is greater than 16 characters long). If the file is an animated gif, import all frames of the gif as separate costumes."

	| title result el ext fList isFirst newName type |
	(self isKindOf: ScratchStageMorph)
		ifTrue: [type _ #background. title _ 'Import Background']
		ifFalse: [type _ #costume. title _ 'Import Costume'].
	result _ ScratchFileChooserDialog
		chooseImageFileType: type
		title: title.
	result = #cancelled ifTrue: [^ self].

	fList _ OrderedCollection new.
	ext _ FileDirectory extensionFor: result asLowercase.
	ext = 'gif'
		ifTrue: [[fList _ (GIFReadWriter new on: (FileStream readOnlyFileNamed: result)) nextImageSet] ifError: [^ self]]
		ifFalse: [[fList addLast: (Form fromFileNamed: result)] ifError: [^ self]].

	isFirst _ true.
	fList do: [:f |
		el _ ImageMedia new form: (ScratchFrameMorph scaledFormForPaintEditor: f).
		newName _ self mediaNameFromFileName: result default: 'costume'.
		el mediaName: (self unusedMediaNameFromBaseName: (UTF8 withAll: newName)).
		media addLast: el.
		isFirst ifTrue: [isFirst _ false. self lookLike: el mediaName.]].

	self updateMediaCategory.

	self undeleteAttribute: #costumes.
	self propagateCostumes
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 23:21'!
importMedia: fileName
	"Import a new image from a file and add it to my media."

	| extension elList baseName fList isFirst |
	extension _ FileDirectory extensionFor: fileName asLowercase.

	elList _ OrderedCollection new.

	(#(aif aiff wav mp3) includes: extension) ifTrue: [
		baseName _ self mediaNameFromFileName: fileName default: 'sound'.
		[elList addLast: (SoundMedia new loadFile: fileName)] ifError: [^ self]].

	(#(jpg jpeg gif bmp png) includes: extension) ifTrue: [
		baseName _ self
			mediaNameFromFileName: fileName
			default: self defaultImageMedia mediaName.
		fList _ OrderedCollection new.
		extension = 'gif' 
			ifTrue: 
				[[fList _ (GIFReadWriter new on: (FileStream oldFileNamed: fileName)) nextImageSet] ifError: [^ self]]
			ifFalse: 
				[[fList addLast: (Form fromFileNamed: fileName)] ifError: [^ self]].
		fList do: [:f | 
			elList addLast: (ImageMedia new form: (ScratchFrameMorph scaledFormForPaintEditor: f))]].

	elList isEmpty ifTrue: [^ self].  "unknown file type; ignore"

	isFirst _ true.
	elList do: [:el | 
		el mediaName: (self unusedMediaNameFromBaseName: baseName).
		media addLast: el.
		isFirst ifTrue: [
			isFirst _ false. 
			el isSound 
				ifTrue: [
					self undeleteAttribute: #sounds.
					self propagateSounds
					]
				ifFalse: [
					self lookLike: el mediaName.
					self undeleteAttribute: #costumes.
					self propagateCostumes]]].
	
	self updateMediaCategory.

! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 23:22'!
importSound
	"Import a new sound from a file and add it to my media."

	| result el newName |
	result _ ScratchFileChooserDialog
		chooseExistingFileType: #sound
		extensions: #(aif aiff au wav mp3)
		title: 'Import Sound'.

	result = #cancelled ifTrue: [^ self].

	el _ [SoundMedia new loadFile: result]
		ifError: [:err :rcvr |
			DialogBoxMorph warn: err.
			nil].
	el ifNil: [^ self].

	newName _ self mediaNameFromFileName: result default: 'sound'.
	el mediaName: (UTF8 withAll: (self unusedMediaNameFromBaseName: newName)).
	media addLast: el.
	self updateMediaCategory.

	self undeleteAttribute: #sounds.
	self propagateSounds! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 23:23'!
insertMedia: aScratchMedia before: targetOrNil
	"Shuffle my media list so that the given media item comes immediately before the target media item, or at the end of the list if targetScratchMedia is nil. Do nothing if the given item is the same as the target item."

	| mediaItem |
	aScratchMedia == targetOrNil ifTrue: [^ self].

	mediaItem _ aScratchMedia.
	(media includes: aScratchMedia) ifFalse: [
		"dropping an undeleted media item"
		mediaItem _ mediaItem copy.
		mediaItem mediaName: (self unusedMediaNameFromBaseName: mediaItem mediaName).
		media addLast: mediaItem].

	media remove: mediaItem.
	targetOrNil
		ifNil: [media addLast: mediaItem]
		ifNotNil: [media add: mediaItem before: targetOrNil].
	self updateMediaCategory.

	aScratchMedia isSound 
		ifTrue: [
			self undeleteAttribute: #sounds.
			self propagateSounds]
		ifFalse: [
			self undeleteAttribute: #costumes.
			self propagateCostumes]
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 9/7/2006 17:23'!
mediaNameFromFileName: fileName default: defaultName
	"Answer a name for the given media item. If the existing name is '$$squeak$$' then the media was copied via windows drag-and-drop; use the given default name instead."

	| result |
	result _ (FileDirectory baseNameFor: (FileDirectory localNameFor: fileName)).
	(result beginsWith: '$$squeak$$') ifTrue: [result _ defaultName].
	result size > 16 ifTrue: [result _ result copyFrom: 1 to: 16].
	^ result
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 12/1/2005 20:04'!
onlyCostume: aForm
	"Remove all my costumes, then make a new costume using the given Form."

	| el |
	media _ media select: [:m | m isSound].

	el _ ImageMedia new form: aForm.
	el mediaName: 'costume'.
	media addLast: el.
	self lookLike: el mediaName.
	self updateMediaCategory.
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 8/3/2007 08:00'!
recordSound

	| frame |
	frame _ self ownerThatIsA: ScratchFrameMorph.
	frame ifNil: [^ self beep].
	frame stopAll.
	World submorphs do: [:m |
		(m isKindOf: ScratchSoundRecorderDialogMorph) ifTrue: [m delete]].

	ScratchSoundRecorderDialogMorph forClient: self.

! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 22:07'!
revertToCostume: oldCostumeName
	"Sent by the paint editor if editing of a newly-created costume is cancelled. Delete the new costume and revert to the old costume with the given name."

	| newlyCreatedCostume |
	newlyCreatedCostume _ costume.
	self lookLike: oldCostumeName.
	media remove: newlyCreatedCostume ifAbsent: [].
	self updateMediaCategory.

	self undeleteAttribute: #costumes.
	self propagateCostumes
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 23:02'!
savePhoto: aForm

	| n |
	n _ self unusedMediaNameFromBaseName: 'costume' localized, '1'.
	self addMediaItem: (ImageMedia new mediaName: n; form: aForm).

	self undeleteAttribute: #costumes.
	self propagateCostumes


! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jens 2/23/2011 23:24'!
saveSound: aSampledSound name: baseName

	| sndItem |
	sndItem _ SoundMedia new.
	sndItem mediaName: (self unusedMediaNameFromBaseName: baseName).
	media addLast: sndItem.

	sndItem sound: aSampledSound.
	self updateMediaCategory.

	self undeleteAttribute: #sounds.
	self propagateSounds
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 5/12/2004 19:52'!
setMedia: mediaCollection
	"Set my media to the given collection when copying."

	media _ mediaCollection.
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 12/18/2006 10:38'!
soleCostume: imageMedia
	"Make the given image my only costume."

	media _ media select: [:item | item isImage not].
	self addMediaItem: imageMedia.
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 4/25/2008 15:58'!
soundNames
	"Answer a list of my sound names. Suppress duplicates (ignoring case differences)."

	| result nm |
	result _ OrderedCollection new.
	media do: [:el |
		el isSound ifTrue: [
			nm _ el mediaName.
			(result anySatisfy: [:s | s caseInsensitiveEqual: nm])
				ifFalse: [result add: nm]]].
	result addLast: '-'.
	result addLast: 'record' localized, ScratchTranslator ellipsesSuffix.
	^ result asArray
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 4/30/2009 22:53'!
takePhoto
	"Take a photo."

	ScratchCameraDialog new
		client: self;
		openInWorld;
		openCamera.
! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'tis 8/20/2006 22:47'!
unusedMediaNameFromBaseName: baseName
	"Answer an unused name for a new media item with the given base name. Strip off the file extension, if any."

	^ self unusedMediaNameFromBaseName: baseName forMedia: nil! !

!ScriptableScratchMorph methodsFor: 'media' stamp: 'jm 6/22/2009 16:06'!
unusedMediaNameFromBaseName: baseName forMedia: aMedia
	"Answer an unused name for a new media item with the given base name. Strip off the file extension, if any.  med is the sound or costume media which is currently being renamed."

	| nm i existingNames greatestNum |
	nm _ baseName.
	i _ nm indexOf: $..
	i > 1 ifTrue: [nm _ nm copyFrom: 1 to: i - 1].

	nm size = 0 ifTrue: [
		aMedia
			ifNil: [nm _ 'new' localized asUTF8, '1']
			ifNotNil: [
				aMedia isImage
					ifTrue: [nm _ self defaultImageMedia mediaName]
					ifFalse: [nm _ 'sound' localized asUTF8, '1']]].

	existingNames _ Set new.
	media do: [:m | m = aMedia ifFalse: [existingNames add: (UTF8 withAll: m mediaName)]].

	(nm size > 0 and: [nm last isDigit]) ifFalse: [
		(existingNames includes: (UTF8 withAll: nm)) ifFalse: [^ nm]].

	"remove trailing digits, if any"
	i _ nm size.
	[i > 1 and: [(nm at: i) isDigit]] whileTrue: [i _ i - 1].
	[i > 1 and: [(nm at: i) = Character space]] whileTrue: [i _ i - 1].
	nm _ nm copyFrom: 1 to: i.

	greatestNum _ 0.
	existingNames do: [:n |
		i _ n size.
		[i > 1 and: [(n at: i) isDigit]] whileTrue: [i _ i - 1].
		(n copyFrom: 1 to: i) = nm ifTrue: [
			greatestNum _ ((n copyFrom: i+1 to: n size) asNumber) max: greatestNum]].

	^ nm, (greatestNum+1) printString
! !


!ScriptableScratchMorph methodsFor: 'stepping' stamp: 'jm 1/8/2006 18:06'!
step

	costume mediaStep ifTrue: [self costumeChanged].
! !

!ScriptableScratchMorph methodsFor: 'stepping' stamp: 'jm 5/14/2004 12:22'!
stepTime

	^ 0
! !


!ScriptableScratchMorph methodsFor: 'object i/o' stamp: 'jens 3/2/2010 20:24'!
initFieldsFrom: anObjStream version: classVersion

	| fields |

	fields _ #(
		objName
		vars
		blocksBin
		isClone
		media
		costume
	).

	self class currentEncoding = #byob
		ifTrue: [
	fields _ #(
		objName
		vars
		blocksBin
		customBlocks
		isClone
		media
		costume
	) ].

	super initFieldsFrom: anObjStream version: classVersion.
	self initFieldsNamed: fields from: anObjStream.
! !

!ScriptableScratchMorph methodsFor: 'object i/o' stamp: 'jens 11/12/2009 01:07'!
storeFieldsOn: anObjStream

	| oldBlockBinOwner |
	super storeFieldsOn: anObjStream.
	(blocksBin isKindOf: Morph) ifTrue: [
		oldBlockBinOwner _ blocksBin owner.
		blocksBin delete].

	self purgeVarsAndLists.

	self storeFieldsNamed: #(
		objName
		vars
		blocksBin
		customBlocks
		isClone
		media
		costume
	) on: anObjStream.

	oldBlockBinOwner ifNotNil: [oldBlockBinOwner addMorph: blocksBin].
! !


!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 12/15/2006 11:48'!
clearMediaAndCostume
	"Private!! Used when exporting an empty stage."

	media _ OrderedCollection new.
	costume _ nil.
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jens 8/10/2009 15:23'!
copyForExport
	"Answer a copy of me for exporting."

	| objToExport |
	objToExport _ self fullCopy.
	objToExport objName: objName.
	objToExport prepareForExport.
	^ objToExport
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 6/4/2008 19:45'!
copyListsFor: aSprite
	"Answer a deep copy of my list variables dictionary."

	| result oldList copiedList |
	result _ lists species new.
	lists associationsDo: [:assoc |
		oldList _ assoc value.
		copiedList _ ScratchListMorph new
			listName: oldList listName target: aSprite;
			newContents: oldList listContents.
		result at: assoc key put: copiedList].
	^ result

! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jens 8/12/2009 23:15'!
copyRecordingIn: dict
	"Copy my fields and scripts."

	| newCopy newBlocksBin |
	(self respondsTo: #sayNothing) ifTrue: [self sayNothing].  "remove talk bubble before copying"
	newCopy _ super copyRecordingIn: dict.
	newCopy renewFilterPack.
	newBlocksBin _ blocksBin fullCopy.
	newBlocksBin allMorphsDo: [:m |
		(m isKindOf: HatBlockMorph) ifTrue: [m scriptOwner: newCopy].
		(m isKindOf: CommandBlockMorph) ifTrue: [m mapReceiver: self to: newCopy]].
	newCopy vars: vars copy lists: (self copyListsFor: newCopy) blocksBin: newBlocksBin.
	newCopy blockDefinition: (self copyBlockDefinitionsFor: newCopy).
	newCopy objName: self nextInstanceName.
	newCopy setMedia: (media collect: [:el | el copy]).
	newCopy lookLike: costume mediaName.

	"for nested sprites:"
	(self isKindOf: ScratchSpriteMorph) ifTrue: [
		newCopy refPos: self referencePosition.
		newCopy privateSubsprites: (self subsprites collect: [:sub |
			(sub copyRecordingIn: dict)
				privateOwnerSprite: newCopy ])].

	^ newCopy
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 11/22/2004 13:43'!
costumeChanged

	costumeChangeMSecs _ Time millisecondClockValue.
	filterPack ifNotNil: [filterPack clearFilterCaches].
	self layoutChanged.
	self keepOnScreen.
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jens 3/22/2011 23:29'!
deleteSprite
	"Delete the sprite and all watchers that are associated with it."

	| frame sprites i presenter instances |
	frame _ self ownerThatIsA: ScratchFrameMorph. 
	frame ifNil: [
		presenter _ World findA: ScratchPresenterMorph.
		presenter ifNil: [^ self delete].
		frame _ presenter frame].

	frame deleteWatchersForSprite: self.
	instances _ self instances.

	frame workPane updateSpritesList.
	sprites _ frame workPane sprites.
	i _ sprites indexOf: self.  "remember my index"
	sprites remove: self ifAbsent: [].

	self delete.
	instances do: [:each |
		each prototype: nil].

	frame libraryPane fixLayout.

	"delete my thumbnail, and re-focus on the thumbnail right after me or the stage if there are no sprites"
	i > sprites size ifTrue: [i _ i - 1].
	i < 1 
		ifTrue: [frame view: frame workPane tab: 'Scripts' category: 'motion'] 
		ifFalse: [frame view: (sprites at: i) tab: 'Scripts' category: 'motion'].	
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 3/14/2009 17:22'!
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

!ScriptableScratchMorph methodsFor: 'private' stamp: 'JM 11/22/2011 15:24'!
nextInstanceName
	"Answer a name for a new instance. For sprites, an attempt is made to create a unique name of the form 'spriteN'."

	| stage lastN digits |
	self = ScratchStageMorph ifTrue: [^ 'Canvas' localized].

	(stage _ self ownerThatIsA: ScratchStageMorph) ifNil: [^ 'Sprite' localized asUTF8, 1 printString].
	lastN _ 0.
	stage sprites ifNotNil: [
		stage sprites do: [:m |
			(m isKindOf: ScratchSpriteMorph) ifTrue: [
				digits _ m objName trailingDigits.
				((digits size > 0) and: [m objName beginsWith: ('Sprite' localized)])
					ifTrue: [lastN _ lastN max: digits asNumber]]]].

	^ 'Sprite' localized asUTF8, (lastN + 1) printString
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 5/12/2006 14:02'!
printSummaryOn: aStream

	| costumes snds stacks hats otherStacks |
	aStream nextPutAll: 'Sprite: ', self objName; crlf.

	costumes _ media select: [:item | item isImage].
	aStream nextPutAll: '  Costumes (', costumes size printString, '):'; crlf.
	costumes do: [:item |
		aStream nextPutAll: '    ', item mediaName, ' (', item infoString, ')'; crlf].

	snds _ media select: [:item | item isSound].
	aStream nextPutAll: '  Sounds (', snds size printString, '):'; crlf.
	snds do: [:item |
		aStream nextPutAll: '    ', item mediaName, ' (', item infoString, ')'; crlf].

	stacks _ blocksBin submorphs select: [:m | m isKindOf: BlockMorph].
	stacks size = 0 ifTrue: [
		aStream nextPutAll: '  No stacks.'; crlf; crlf.
		^ self].
	aStream nextPutAll: '  Stacks (', stacks size printString, '):'; crlf.

	hats _ stacks select: [:m | m isKindOf: HatBlockMorph].
	otherStacks _ stacks select: [:m | (m isKindOf: HatBlockMorph) not].

	hats, otherStacks do: [:item |
		item printCodeOn: aStream indent: 1.
		(item isKindOf: ReporterBlockMorph) ifTrue: [aStream crlf].
		aStream crlf].

! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 11/13/2003 20:44'!
projectDirectory
	"Answer the directory containing this Scratch project or the default directory."

	| frame |
	(frame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ FileDirectory default].
	^ frame projectDirectory
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 5/11/2009 11:08'!
spriteNameInUse: aString

	| s |
	(s _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		s submorphs do: [:m |
			m == self ifFalse: [
				((m isKindOf: ScriptableScratchMorph) and:
				 [m objName caseInsensitiveEqual: aString]) ifTrue: [
					^ true]]]].

	^ false
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 5/28/2008 16:05'!
stopPlaying
	"Stop playing all movies and sounds."

	| firstCostume |
	costume stopPlaying.
	self filterReset.
	self setVolumeTo: 100.  "reset volume"

	"exit camera mode"
	(costume isKindOf: CameraMedia) ifTrue: [
		firstCostume _ media detect: [:el | el isImage] ifNone: [^ self].
		self lookLike: firstCostume mediaName].
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jens 8/12/2009 23:16'!
undoableDeleteSprite
	"Delete the sprite and store it in the clipboard in case of an undo."

	self notEditingBlock ifFalse: [^self].
	self unhinge; unhingeAll.
	ScratchFrameMorph putInClipboard: self.
	self deleteSprite.
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 1/28/2009 10:42'!
updateMediaCategory
	"Update the media category in the viewer, if it is showing."

	| sFrame |
	sFrame _ self ownerThatIsA: ScratchFrameMorph.
	sFrame ifNotNil: [
		sFrame projectModified.
		sFrame updateMediaCategoryFor: self.
		sFrame viewerPane refresh].

! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 11/17/2006 17:39'!
vars: varsDict blocksBin: aBlocksBin
	"Private!! Set my variables and blocks bin. Used by copyRecordingIn:."

	vars _ varsDict.
	blocksBin _ aBlocksBin.
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jm 6/4/2008 19:34'!
vars: varsDict lists: listsDict blocksBin: aBlocksBin
	"Private!! Set my variables and blocks bin. Used by copyRecordingIn:."

	vars _ varsDict.
	lists _ listsDict.
	blocksBin _ aBlocksBin.
! !

!ScriptableScratchMorph methodsFor: 'private' stamp: 'jens 3/9/2011 22:48'!
zoomRectFrom: startRect to: finalRect

	| steps r p1 p2 |

	steps _ 8.
	r _ startRect.
	Display border: r width: 2 rule: Form reverse fillColor: Color gray.
	Display forceDisplayUpdate.
	0 to: steps do: [:i |
		Delay waitMSecs: 35.
		Display border: r width: 2 rule: Form reverse fillColor: Color gray.
		Display forceDisplayUpdate.
		p1 _ startRect origin + ((i * (finalRect origin - startRect origin)) // steps).
		p2 _ startRect corner + ((i * (finalRect corner - startRect corner)) // steps).
		r _ p1 corner: p2.
		Display border: r width: 2 rule: Form reverse fillColor: Color gray.
		Display forceDisplayUpdate].
	Delay waitMSecs: 35.
	Display border: r width: 2 rule: Form reverse fillColor: Color gray.
	Display forceDisplayUpdate.
! !


!ScriptableScratchMorph methodsFor: 'BYOB OOP message passing' stamp: 'jens 1/24/2011 23:43'!
attribute: attr of: anObject
	"Answer the variable or built-in attribute value for the given sprite. Answer zero if the given sprite does not have a built-in attribute or variable of the given name."

	| aSpriteOrStage |
	aSpriteOrStage _ self coerceSpriteArg: anObject.

	(aSpriteOrStage isKindOf: ScriptableScratchMorph) ifFalse: [^ 0].
	^ aSpriteOrStage attribute: attr
! !

!ScriptableScratchMorph methodsFor: 'BYOB OOP message passing' stamp: 'jens 1/25/2011 00:09'!
blockForSelector: aSymbol
	"Answer a block for the give selector or nil"

	| cat |

	self class blockSpecs do: [:spec |
		((spec isKindOf: Symbol) not and: [spec isKindOf: String])
			ifTrue: [cat _ spec].

		((spec isKindOf: Array) and: [(spec at: 3) = aSymbol])
			ifTrue: [^ self blockFromSpec: spec color: (self class blockColorFor: cat)]].

	^ nil


! !

!ScriptableScratchMorph methodsFor: 'BYOB OOP message passing' stamp: 'jens 1/25/2011 00:12'!
blockLike: aBlockMorph

	aBlockMorph selector = #doCustomBlock
		ifTrue: [^ self lambda: aBlockMorph id].
	^ (self blockForSelector: aBlockMorph selector) asLambda
! !

!ScriptableScratchMorph methodsFor: 'BYOB OOP message passing' stamp: 'jens 1/26/2011 00:40'!
getVarOrListNamed: varName

	| value |

	"first let's try to find a variable"

	(vars includesKey: varName)
		ifFalse: [ value _ (self ownerThatIsA: ScratchStageMorph) vars at: varName asString ifAbsent: [
			(self prototype notNil and: [self prototype varNames includes: varName])
				ifTrue:[self prototype getVar: varName]
				ifFalse: [nil]]].
	value _ vars at: varName asString ifAbsent: [nil].

	"if none is found check for a named list"

	value ifNil: [
		value _ self listNamed: varName ifNone: [
			self error: 'no such variable or list'. nil]].

	^ value
			! !


!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 7/27/2010 17:23'!
addCustomBlock
	|ans def sf|
	(sf _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^self].
	BlockDialog isOpen ifTrue: [^ self].
	ans _ BlockDialog ask: 'Make a block' localized.
	(ans = #cancelled) ifTrue: [^self ].

	def _ (CustomBlockDefinition new 
		userSpec: (ans at: 1);
		category: (ans fourth = #other ifTrue: [#none] ifFalse: [ans fourth])).
	(ans at: 2)	
		ifTrue: [ (ans at: 3) 
			ifTrue: [def type: #boolean]
			ifFalse: [def type: #any]]
		ifFalse: [def type: #none; isAtomic: false].
	def isGlobal: (ans at: 5) not.

	(self existsBlockId: (CustomBlockDefinition idFromSpec: (ans at: 1)) global: (ans at: 5))
			ifTrue: [^DialogBoxMorph warn: 'a custom block with this label already exists' localized].

	self ensureCustomBlockExists: def global: def isGlobal.

	sf projectModified. 
	sf viewerPane categoryChanged: 'variables'.
	#none = def category ifFalse: [
		sf viewerPane categoryChanged: def category asString ].
	self editScriptId: (CustomBlockDefinition idFromSpec: (ans at: 1)).! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 1/13/2011 23:14'!
addCustomBlocksTo: page y: startY

	| addButton  x y b cdefs inherited all |
	addButton _ ScratchFrameMorph
		buttonLabel: 'Make a block' localized
		selector: #addCustomBlock.

	x _ 13.
	y _ startY + 10.
	page addMorph: (addButton target: self; position: x@y).
	y _ addButton bottom + 5.

	"add custom blocks (jens)"
	inherited _ self inheritedBlocks select: [:def |
		def category = #none].

	customBlocks 
		ifNil: [cdefs _ Set new]
		ifNotNil: [ cdefs _ customBlocks select: [:def | 
			def category = #none]].

	all _ inherited, cdefs.
	all isEmpty ifFalse: [
		all _ all asSortedCollection: [:first :second | first id <= second id].
		all do: [:eachDef|
			b _ self newCustomBlockFor: eachDef.
			page addMorph: (b position: (x@y)).
			y _ y + b height + 3 ]].! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/11/2011 01:45'!
addVariable
	"Ask the user for a variable name, then add a user variable of that name. This version is for sprites and supports the option of making the variable specific to the sprite (i.e. local)."

	| sFrame result varName varOwner w |
	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self beep].

	result _ NewVariableDialog ask: 'Variable name?'.
	result = #cancelled ifTrue: [^ self].
	varName _ result first asUTF8.
	varOwner _ result second ifTrue: [self] ifFalse: [sFrame workPane].
	(varOwner variableNameInUse: varName) ifTrue: [
		self beep.
		DialogBoxMorph warn: 'That variable name is already in use'.
		^ self].

	varOwner addVariable: varName.
	sFrame viewerPane categoryChanged: 'variables'.
	self addWatcherForNewVariable: varName withScope: varOwner.

	w _ sFrame watcherForBlock: (VariableBlockMorph new receiver: self; commandSpec: varName; yourself).
	w ifNotNil: [w setCategoryColor: (ScriptableScratchMorph blockColorFor: 'variables')].

! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 8/5/2010 10:13'!
allInstancesOf: aCustomBlockId

	| objects stage all |
	(self isKindOf: ScratchStageMorph)
		ifTrue: [stage _ self]
		ifFalse: [stage _ self owner].
	objects _ {stage}, stage sprites.
	all _ OrderedCollection new.
	objects do: [:obj|
		all addAll: (obj instancesOf: aCustomBlockId)].
	^ all! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 7/7/2010 02:43'!
asciiCodeOf: aString

	| str |
	str _ aString asMacRoman.
	str size = 1 ifFalse: [
		^ 0 ].
	^ str first asciiValue! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 7/7/2010 02:44'!
asciiLetter: anInteger

	| code |
	code _ anInteger asNumberNoError.

"
	(code isKindOf: Integer) ifFalse: [
		^ self error: 'expecting an integer'].
	(code < 0 or: [code > 255]) ifTrue: [
		^ self error: 'expecting a number between 0 and 255'].
"

	^ String with: (Character value: code)! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 9/29/2008 17:02'!
blockDefinition: anOrderedList
	customBlocks _ anOrderedList
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 3/2/2010 22:24'!
blockIds
	customBlocks ifNil: [customBlocks _ OrderedCollection new].
	^ (customBlocks select: [:eachDef | eachDef isGlobal not ])
		collect: [:eachDef | eachDef id]! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/24/2011 20:06'!
clearVariables

	self varNames do: [:vn |
		self setVar: vn to: 0].

	self listVarNames do: [:ln |
		(self listNamed: ln) clear]! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 9/29/2008 16:27'!
closeBlockEditor
	| sf |
	sf _ self ownerThatIsA: ScratchFrameMorph.
	sf ifNil: [^self].
	^sf closeBlockEditor! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'JM 11/22/2011 15:24'!
convertListVarReferencesToTuples

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

	| obj ref rcvr |

	self varNames do: [:varName |
		obj _ self getVar: varName.

		(obj isKindOf: BlockMorph) ifTrue: [
			(obj receiver isKindOf: ScriptableScratchMorph)
				ifTrue: [(obj receiver isKindOf: ScratchStageMorph)
					ifTrue: [rcvr _ 'Canvas']
					ifFalse: [rcvr _ obj receiver objName]]
				ifFalse: [ rcvr _ '' ].
			vars at: varName put: (Array with: #block with: rcvr with: obj tupleSequence) ].

		(obj isKindOf: ScratchListMorph) ifTrue: [
			ref _ obj asReferenceTuple. 
			(ref first = #variableList) & ({objName. 'Canvas'} includes: ref second ) & (ref third = varName)
				ifTrue: [obj convertStacksToTuples]
				ifFalse: [ vars at: varName put: ref]].

		(obj isKindOf: ScriptableScratchMorph) ifTrue: [
			ref _ obj asReferenceTuple. 
			vars at: varName put: ref]].

! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 9/14/2010 23:14'!
convertTuplesToDefinitions

	customBlocks ifNil: [^ self].
	customBlocks do: [:eachDef |
		eachDef body ifNotNil: [ 
			(eachDef body isKindOf: Array) ifTrue: [
				eachDef body: (self stackFromTupleList: eachDef body receiver: self)]].
		eachDef answer ifNotNil: [ 
			(eachDef answer isKindOf: Array)
				ifTrue: [eachDef answer: (self stackFromTupleList: eachDef answer receiver: self)]].
		eachDef migrateBlockVars].
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'JM 11/22/2011 15:24'!
convertVarTuplesToListReferences

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

	| obj rcvr stage block |

	self varNames do: [:varName |
		obj _ self getVar: varName.
	
		(obj isKindOf: ScratchListMorph) ifTrue: [
			obj convertTuplesToStacks ].

		(obj isKindOf: Array) ifTrue: [
			stage _ self ownerThatIsA: ScratchStageMorph.
			obj second = 'Canvas'
				ifTrue: [rcvr _ stage ]
				ifFalse: [rcvr _ stage coerceSpriteArg: obj second ].



			#block = obj first ifTrue: [
				block _ stage stackFromTupleList: obj third receiver: rcvr.
				varName ifNotNil: [	vars at: varName put: block ]].
				
			#namedList = obj first ifTrue: [
				vars at: varName put: (stage listNamed: obj third targetName: obj second)].

			#variableList = obj first ifTrue: [
				vars at: varName put: (stage listInVarNamed: obj third targetName: obj second)].

			#stage = obj first ifTrue: [
				vars at: varName put: stage].	

			#sprite = obj first ifTrue: [
				vars at: varName put: (stage coerceSpriteArg: obj second)]]].
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 9/29/2008 17:09'!
copyBlockDefinitionsFor: aSprite
	"Answer a deep copy of my custom block definition list"

	|result|
	result _ customBlocks deepCopy.
	result ifNil: [^nil].
	result do: [:def|
	 def body ifNotNil: [
			def body allMorphs do: [:m|
				((m isKindOf: BlockMorph) and: [
				m receiver = self]) ifTrue: [m receiver: aSprite]]]].
	^ result
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 6/18/2010 02:30'!
copyOfList: aList

	aList ifNil: [^ ScratchListMorph on: #()].
	^ ScratchListMorph on: aList asArray
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 3/1/2010 17:18'!
customBlocks
	^ customBlocks! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 1/14/2010 22:00'!
customBlocksContaining: aBlock
	"for error feedback"
	| def |
	customBlocks ifNil: [^Array empty].
	def _ customBlocks detect: [ :each |
		each allBlocks includes: aBlock ] ifNone: [nil].
	def ifNil: [^Array empty].
	^self instancesOf: def id
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 1/27/2011 03:12'!
definitionFor: anId

	| all inherited def |
	inherited _ self inheritedBlocks.
	customBlocks ifNil: [customBlocks _ OrderedCollection new].
	all _ inherited, customBlocks.
	def _ all reversed detect: [:eachDef|
		eachDef id = anId]
		ifNone: [^nil].
	(def body isKindOf: BlockMorph) ifTrue: [
		def body newScriptOwnerPrivate: self].
	^ def! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/26/2010 02:17'!
deleteDefinitionId: id

	| stage def |
	def _ self definitionFor: id.
	def isGlobal  ifFalse: [
		^ self deleteLocalDefinitionId: id].

	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNil: [^ self deleteLocalDefinitionId: id].

	stage sprites, {stage} do: [:obj |
		obj deleteLocalDefinitionId: id]
	! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/11/2011 01:12'!
deleteLocalDefinitionId: id
	| affected sf def cat |
	sf _ self ownerThatIsA: ScratchFrameMorph.
	sf ifNil: [^self].
	sf notEditingBlock ifFalse: [^self].
	affected _ self instancesOf: id.
	def _ self definitionFor: id.
	def ifNil: [^ self].
	cat _ def category.
	customBlocks remove: def ifAbsent: [].
	((self inheritedBlocks collect: [:b |
		b id]) includes: id) ifFalse: [
		affected do: [:eachBlock|
			eachBlock remove]].
	sf viewerPane categoryChanged: 'variables'.
	#none = cat ifFalse: [
		sf viewerPane categoryChanged: cat asString]! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/11/2011 00:40'!
editScriptId: id
	|sf def|

	sf _ self ownerThatIsA: ScratchFrameMorph.
"	sf ifNil: [^self]."
	def _ self definitionFor: id.
"	def ifNil: [^self]."
	sf editBlockDefinition: def for: self! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 9/13/2010 21:05'!
editSpecId: id
	"let the user change the category (color) of a custom block"

	| stage ans def sf bd oldCat inst newType |
	sf _ self ownerThatIsA: ScratchFrameMorph.
	sf ifNil: [^self].
	stage _ self ownerThatIsA: ScratchStageMorph.
	def _ self definitionFor: id.
	newType _ def type.

	BlockDialog isOpen ifTrue: [^ self].

	bd _ BlockDialog new.
	bd
		title: '?';
		withButtonsForYes: false no: false okay: true cancel: true;
		message: 'Custom block category';
		setUserSpec: def userSpec;
		setCategory: def category;
		setType: def type;
		updateTypeSelection.

	inst _ self instancesOf: id. 
	def isGlobal ifTrue: [
		inst _ OrderedCollection new.
		stage isNil ifFalse: [
			stage sprites, {stage} do: [:obj |
				inst addAll: (obj instancesOf: id) ]]].
		
	inst isEmpty
		ifTrue: [bd disableAllButCategoryAndShape]
		ifFalse: [bd disableAllButCategory].

	bd updateInitialSettings.
	ans _ bd getUserResponse. 

	(ans = #cancelled) ifTrue: [^self ].
	ans first isEmpty ifTrue: [^self].

	((self existsBlockId: (CustomBlockDefinition idFromSpec: ans first)) and: [def userSpec asUTF8 ~= ans first])
			ifTrue: [ ^DialogBoxMorph warn: 'a custom block with this label already exists' localized].
	(def varNames includesAnyOf: (def parameterNamesInSpec: ans first))
		ifTrue: [^DialogBoxMorph warn: 'a block variable with the same name as a parameter already exists'].

	ans = def userSpec ifTrue: [^self].
	ans isEmpty ifTrue: [^self].
	(self existsBlockId: (CustomBlockDefinition idFromSpec: ans)) ifTrue: [
		^DialogBoxMorph warn: 'a custom block with this label already exists'].
	(def varNames includesAnyOf: (def parameterNamesInSpec: ans first))
		ifTrue: [^DialogBoxMorph warn: 'a block variable with the same name as a parameter already exists'].

	inst isEmpty ifTrue: [
		(ans at: 2)	
			ifTrue: [ (ans at: 3) 
				ifTrue: [newType _ #boolean]
				ifFalse: [newType _ #any]]
			ifFalse: [newType _ #none]].

	def type = newType ifFalse: [
		def type: newType ].

	oldCat _ def category.
	def category: (ans fourth = #other ifTrue: [#none] ifFalse: [ans fourth]).
	#none = oldCat ifFalse: [
		sf viewerPane categoryChanged: oldCat asString ].

	def isGlobal ifFalse: [
		^ self updateLocalId: id withSpec: ans first].

	stage ifNil: [^ self updateId: id withSpec: ans first ].

	stage sprites, {stage} do: [:obj |
		obj
			updateCustomBlockDefinitionId: id with: def;
			updateLocalId: id withSpec: ans first ]
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 1/27/2011 02:46'!
ensureCustomBlockExists: aBlockDef

	| def bod |
 	aBlockDef ifNil: [^ self].
	(self definitionFor: aBlockDef id) ifNil: [
		def _ aBlockDef deepCopy.
		customBlocks add: def.
		bod _ aBlockDef body.
		bod ifNotNil: [def body: (bod fullCopy newScriptOwner: self) ]]! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 3/1/2010 21:26'!
ensureCustomBlockExists: aBlockDef global: bool

	| stage |

	stage _ self ownerThatIsA: ScratchStageMorph.

	(bool = false or: [stage isNil]) ifTrue: [
		^ self ensureCustomBlockExists: aBlockDef].

	stage sprites, {stage} do: [:obj |
		obj ensureCustomBlockExists: aBlockDef]
	! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/11/2011 01:07'!
ensureOwnBlockExists: aBlockDef

	| def bod defId |

 	aBlockDef ifNil: [^ self].
	defId _ aBlockDef id.
	customBlocks ifNil: [customBlocks _ OrderedCollection new].
	customBlocks detect: [:eachDef|
		eachDef id = defId]
		ifNone: [
			def _ aBlockDef deepCopy.
			bod _ aBlockDef body.
			bod ifNotNil: [def body: (bod fullCopy newScriptOwner: self)].
			customBlocks add: def]
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/26/2010 00:19'!
existsBlockId: id

	customBlocks ifNil: [customBlocks _ OrderedCollection new].
	customBlocks detect: [:def|
		def id = id ] ifNone: [^false].
	^true! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 4/27/2010 20:04'!
existsBlockId: id global: bool

	| stage |

	bool ifTrue: [
		^self existsBlockId: id].

	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNil: [^ self existsBlockId: id].

	stage sprites, {stage} do: [:obj |
		(obj existsBlockId: id) ifTrue: [
			^ true]].

	^ false

! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 12/1/2009 00:22'!
getFalse
	^false! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 12/1/2009 00:22'!
getTrue
	^true! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 6/30/2010 23:25'!
installGlobalBlocks

	| stage |

	stage _ self ownerThatIsA: ScratchStageMorph.	
	stage ifNil: [^ self].
	"add imported global custom block definitions"


	customBlocks ifNotNil: [

		'installing globals...' 
			displayProgressAt: self center - (32@5)  "Sensor cursorPoint"
			from: 0 to: customBlocks size
			during: [:bar | | i | i _ 0.

		customBlocks do: [:eachDef | 
			i _ i + 1. bar value: i.
			eachDef isGlobal ifTrue: [
				stage sprites, {stage} do: [:obj |
					obj
						updateCustomBlockDefinitionId: eachDef id with: eachDef;
						updateLocalId: eachDef id withSpec: eachDef userSpec]]]]].

! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 6/11/2010 00:44'!
instancesOf: aCustomBlockId

	| sf ans visible invisible blx |
	invisible _ self invisibleInstancesOf: aCustomBlockId.
	visible _ blocksBin allMorphs select: [ :m|
		((m isKindOf: CustomCommandBlockMorph) or:[
			m isKindOf: CustomReporterBlockMorph]) and: [m id = aCustomBlockId]].
	sf _ self ownerThatIsA: ScratchFrameMorph.
	sf ifNotNil: [
		sf blockEditors do: [:be |
			blx _ be allBlocksFor: aCustomBlockId.
			blx size > 0 ifTrue: [
				visible addAll: blx ]]].

	ans _ visible, invisible.
	^ans! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 8/6/2010 12:52'!
invisibleInstancesOf: aCustomBlockId

	| ans |
	ans _ Set new.
	customBlocks ifNil: [^ ans].
	customBlocks do: [:eachDef|
		eachDef body ifNotNil: [
			ans addAll: (eachDef body allMorphs select: [:m|
				((m isKindOf: CustomCommandBlockMorph) or: [
					m isKindOf: CustomReporterBlockMorph]) and: [
				m id = aCustomBlockId ]])].

		eachDef answer ifNotNil: [
			(eachDef answer isKindOf: BlockMorph) ifTrue: [
				ans addAll: (eachDef answer allMorphs select: [:m|
					((m isKindOf: CustomReporterBlockMorph) or: [
						m isKindOf: CustomReporterBlockMorph]) and: [
					m id = aCustomBlockId ]])]]].

	^ans asOrderedCollection! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 5/16/2011 23:07'!
isObject: object type: type

	'object' "localized" = type ifTrue: [
		^ object isKindOf: ScriptableScratchMorph].

	'number' "localized" = type ifTrue: [
		object isNumber ifTrue: [^true].
		(object isKindOf: Morph) ifTrue: [^ false].
		(object isKindOf: Boolean) ifTrue: [^ false].
		object isEmpty ifTrue: [^ false].
		object asMacRoman do: [:c | 
			c isDigit ifFalse: [(#($0 $. $-) includes: c) ifFalse: [^ false]]].
		^ true].

	'text' "localized" = type ifTrue: [
		object isNumber ifTrue: [^ false].
		(object isKindOf: Morph) ifTrue: [^ false].
		(object isKindOf: Boolean) ifTrue: [^ false].
		object isEmpty ifTrue: [^ true].
		object asMacRoman do: [:c | 
			c isDigit ifFalse: [(#($0 $. $-) includes: c) ifFalse: [^ true]]].
		^ false].

	'boolean' "localized" = type ifTrue: [
		^ object isKindOf: Boolean].

	'list' "localized" = type ifTrue: [
		^ object isKindOf: ScratchListMorph]. 

	'command' "localized" = type ifTrue: [
		(object isKindOf: LambdaBlockMorph) ifFalse: [^ false].
		^ object isFunction not].

	'reporter' "localized" = type ifTrue: [
		(object isKindOf: LambdaBlockMorph) ifFalse: [^ false].
		object isBooleanFunction ifTrue: [^ false].
		^ object isFunction].

	'predicate' "localized" = type ifTrue: [
		(object isKindOf: LambdaBlockMorph) ifFalse: [^ false].
		^ object isBooleanFunction].

	^ false


! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 9/16/2010 16:01'!
lambda: aCustomBlockId

	"used for the getAttribute block menu"

	| def block |
	
	aCustomBlockId isEmpty ifTrue: [^nil].

	def _ self definitionFor: aCustomBlockId.
	(def isNil or: [#none = def type])
		ifTrue: [block _ CustomCommandBlockMorph new receiver: self]
		ifFalse: [
			block _ CustomReporterBlockMorph new receiver: self.
			block isBoolean: def type = #boolean].

	block
		userSpec: def userSpec;
		isSpecialForm: true;
		selector: #doCustomBlock.

	block argMorphs do: [:arg |
		arg defaultValue: ''].

	^ block
	! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 1/13/2011 09:47'!
localBlocks

	^ self inheritedBlocks, (customBlocks ifNil: [#()]) select: [:eachDef | 
		eachDef isGlobal not].
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 6/14/2010 20:43'!
newCustomBlockFor: aDefinition

	| b |

	#none = aDefinition type
		ifTrue: [b _ CustomCommandBlockMorph new receiver: self]
		ifFalse: [
			b _ CustomReporterBlockMorph new receiver: self.
			b isBoolean: (aDefinition type = #boolean)].
	b userSpec: aDefinition userSpec.
	b isSpecialForm: true.
	b selector: #doCustomBlock.
	b setDefaultArgs.
	^ b
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/23/2010 01:10'!
newList: aScratchListMorph
	^aScratchListMorph! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 9/29/2008 16:13'!
notEditingBlock
	| sf |
	sf _ self ownerThatIsA: ScratchFrameMorph.
	sf ifNil: [^true].
	^sf notEditingBlock! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 8/16/2010 23:35'!
purgeVarsAndLists

	vars keysDo: [:each |
		((vars at: each) isKindOf: BlockMorph)
			ifTrue: [vars at: each put: '']].

"
	vars keysDo: [:each |
		(((vars at: each) isKindOf: ScratchListMorph) or: [(vars at: each) isKindOf: BlockMorph ])
			ifTrue: [vars at: each put: '']].

"! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 6/9/2010 00:29'!
stopAllScriptsFor: eventName

	| stage |
	(stage _ self ownerThatIsA: ScratchStageMorph) ifNotNil: [
		stage stopAllScriptsFor: eventName].
! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 6/9/2010 00:15'!
stopScriptsFor: eventName
	"Stop all my running stacks with an EventHat matching the given event name."

	((eventName = 'Scratch-KeyPressedEvent') | (eventName = 'Scratch-MouseClickEvent'))
		ifFalse: [ self scripts do: [:s |
			((s class == EventHatMorph) and: [s eventName caseInsensitiveEqual: eventName])
				ifTrue: [s stop]]]! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 8/5/2010 10:42'!
unloadUnusedCustomBlocks

	customBlocks ifNil: [^ self].
	customBlocks do: [:block |
		(self allInstancesOf: block id) isEmpty ifTrue: [
			self deleteDefinitionId: block id]]! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 1/13/2011 01:22'!
updateCustomBlockDefinitionId: id with: newDef

	| oldDef |

	oldDef _ self definitionFor: id.
	customBlocks removeAll: {oldDef. newDef}.
	self ensureCustomBlockExists: newDef.

	self prototype ifNotNil: [
		(self prototype definitionFor: newDef id) ifNotNil: [
			self ensureOwnBlockExists: newDef]]! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 1/13/2011 01:21'!
updateLocalId: id withSpec: newUserSpec

	"a userSpec has been changed by way of drag'n'drop"

	| def affected sf |
	sf _ self ownerThatIsA: ScratchFrameMorph.
	sf ifNil: [^self].
	affected _ self instancesOf: id.
	def _ self definitionFor: id. 
	def ifNil: [self error: 'block definition not found'. ^ self ].
	def userSpec: newUserSpec.
	affected do: [:eachBlock|
		eachBlock
			color: def blockColor;

			privateSetUserSpec: newUserSpec;
			commandSpec: def commandSpec;
"			userSpec: newUserSpec;"

			addLabel].
	sf blockEditors do: [:be |
		be definition id = id ifTrue: [
			be definition: def
"			be template color: def blockColor.
			be buildVariables "]].

	sf viewerPane categoryChanged: 'variables'.
	#none = def category ifFalse: [
		sf viewerPane categoryChanged: def category asString ].

	WatcherMorph allInstancesDo: [:inst | inst step].! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 8/5/2010 22:49'!
updateOnlyLocalId: id withSpec: newUserSpec

	"a userSpec has been changed by way of drag'n'drop
	don't update block editors"

	| def affected sf |
	sf _ self ownerThatIsA: ScratchFrameMorph.
	sf ifNil: [^self].
	affected _ self instancesOf: id.
	def _ self definitionFor: id. 
	def userSpec: newUserSpec.
	affected do: [:eachBlock|
		eachBlock
			color: def blockColor;

			privateSetUserSpec: newUserSpec;
			commandSpec: def commandSpec;
			addLabel].

	sf viewerPane categoryChanged: 'variables'.
	#none = def category ifFalse: [
		sf viewerPane categoryChanged: def category asString ].

	WatcherMorph allInstancesDo: [:inst | inst step].! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 2/3/2010 20:08'!
vars
	^vars! !

!ScriptableScratchMorph methodsFor: 'byob' stamp: 'jens 3/9/2011 22:15'!
viewBlocksAndScriptsQuickly

	| sFrame viewer tabs |
	self isClone ifTrue: [^ self].

	(sFrame _ self ownerThatIsA: ScratchFrameMorph) ifNil: [^ self].
	viewer _ sFrame viewerPane.
	tabs _ sFrame scriptsPane tabPane.
	sFrame view: self tab: tabs currentTab category: viewer currentCategory.

"
	self world ifNotNil: [
		self zoomRectFrom: self bounds to: editor bounds].

"! !


!ScriptableScratchMorph methodsFor: 'nesting' stamp: 'jens 7/17/2009 00:05'!
spread
	"overridden by my subclasses. Default is to do nothing"! !


!ScriptableScratchMorph methodsFor: 'networking' stamp: 'jens 8/17/2009 08:39'!
serialized
	"Answer a ByteArray containing this Scratch object in serialized form."

	| s objToExport |
	s _ WriteStream on: (ByteArray new: 100000).
	objToExport _ self copyForExport.
	objToExport firstSubmorph allSubsprites do: [:eachSub |
		eachSub owner ifNil: [objToExport addMorphBack: eachSub ]].
	ObjStream new storeObj: objToExport on: s showProgress: false.
	^ s contents

! !

!ScriptableScratchMorph methodsFor: 'networking' stamp: 'jens 9/16/2008 09:25'!
shareObject
	"send this object to all peers"

	| server |
	server _ (self ownerThatIsA: ScratchStageMorph) scratchServer.
	server ifNil: [^self].
	server sendSprite: self
! !


!ScriptableScratchMorph methodsFor: 'debug and other' stamp: 'jens 6/21/2010 01:32'!
inspect: anObject
	anObject inspect! !


!ScriptableScratchMorph methodsFor: 'byob easter egg fun' stamp: 'jens 4/15/2010 22:44'!
callMe

	^ (ReporterBlockMorph new
		color: Color random;
		receiver: self;
		commandSpec: 'Wow, you''re a smart one. Now call ME %s !!';
		selector: #callMeWith:) asLambda
		! !

!ScriptableScratchMorph methodsFor: 'byob easter egg fun' stamp: 'jens 4/15/2010 22:44'!
callMeWith: anArg

	((anArg isKindOf: String) and: [anArg isEmpty not])
		ifFalse: [^ 'call me with ''please'', please!!'].

	anArg asLowercase = 'please' ifTrue: [
		(self isKindOf: ScratchStageMorph) ifTrue: [
			^'first drag me from the stage into a sprite, then call me again!!'].

		^ (CommandBlockMorph new
			color: Color random;
			receiver: self;
			commandSpec: 'Cool!! Now RUN me %s !!';
			selector: #runMeWith:;
			yourself) asLambda ].

	^ 'come on, call me with ''please''!!'

! !

!ScriptableScratchMorph methodsFor: 'byob easter egg fun' stamp: 'jens 4/15/2010 22:28'!
runMeWith: arg

	(self isKindOf: ScratchSpriteMorph) ifTrue: [
		((arg isKindOf: String) and: [arg isEmpty not]) ifFalse: [^ self say: 'Run me with your name!!'].
		^self say: 'Hi, ', arg, '!! Nice talking to you :-) Congratulations for figuring out this little riddle. You are now a certified lambdaist!!']! !


!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:46'!
blurEffect

	| att |
	att _ #blur.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ [filterPack blur] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 14:16'!
blurEffect: aNumber

	self undeleteAttribute: #blur.
	self passiveBlurEffect: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:26'!
brightnessEffect

	| att |
	att _ #brightness.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ [filterPack brightnessShift] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 01:02'!
brightnessEffect: aNumber

	self undeleteAttribute: #brightness.
	self passiveBrightnessEffect: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:50'!
colorEffect

	| att |
	att _ #color.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ [filterPack hueShift] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:52'!
colorEffect: aNumber

	self undeleteAttribute: #color.
	self passiveColorEffect: aNumber
! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 16:35'!
comeToFront

	super comeToFront.
	self setLayerTo: 1! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/23/2011 12:35'!
costumes
	"this will at some future time answer first class costumes,
	for now it's just the costume names"

	^ ScratchListMorph on: ((media select: [:m | 
		m isSound not]) collect: [:c | c mediaName])! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:24'!
fisheyeEffect

	| att |
	att _ #fisheye.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ [filterPack fisheye] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:55'!
fisheyeEffect: aNumber

	self undeleteAttribute: #fisheye.
	self passiveFisheyeEffect: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/24/2011 02:49'!
inheritCostumesNow

	| att idx |
	att _ #costumes.
	self prototype ifNil: [^ self].
	(self deletedAttributes includes: att) ifFalse: [^ self].

	idx _ self costumeIndex.
	media _ media reject: [:item |
		item isSound not].

	self prototype media do: [:item |
		item isSound ifFalse: [
			media addLast: item copy]].

	self passiveLookLike: idx.
	self updateMediaCategory.

	self propagateCostumes! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/23/2011 23:14'!
inheritSoundsNow

	| att |
	att _ #sounds.
	self prototype ifNil: [^ self].
	(self deletedAttributes includes: att) ifFalse: [^ self].

	media _ media reject: [:item |
		item isSound].

	self prototype media do: [:item |
		item isSound ifTrue: [
			media addLast: item copy]].

	self updateMediaCategory.

	self propagateSounds! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:28'!
isHidden

	| att |
	att _ #isHidden.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ super isHidden

! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:29'!
layer

	| att |
	att _ #layer.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ owner submorphs indexOf: self! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:26'!
mosaicEffect

	| att |
	att _ #mosaic.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ [filterPack mosaicCount] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 01:01'!
mosaicEffect: aNumber

	self undeleteAttribute: #mosaic.
	self passiveMosaicEffect: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 14:16'!
passiveBlurEffect: aNumber

	self privateSetGraphicEffect: 'blur' to: aNumber asNumberNoError.
	self propagate: #blur! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 14:15'!
passiveBrightnessEffect: aNumber

	self privateSetGraphicEffect: 'brightness' to: aNumber asNumberNoError.
	self propagate: #brightness! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:51'!
passiveColorEffect: aNumber

	self privateSetGraphicEffect: 'color' to: aNumber asNumberNoError.
	self propagate: #color! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:52'!
passiveFisheyeEffect: aNumber

	self privateSetGraphicEffect: 'fisheye' to: aNumber asNumberNoError.
	self propagate: #fisheye! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:53'!
passiveMosaicEffect: aNumber

	self privateSetGraphicEffect: 'mosaic' to: aNumber asNumberNoError.
	self propagate: #mosaic
! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:54'!
passivePixelateEffect: aNumber

	self privateSetGraphicEffect: 'pixelate' to: aNumber asNumberNoError.
	self propagate: #pixelate! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:45'!
passiveSetHideFlagTo: aBool

	(aBool isKindOf: Boolean) 
		ifFalse: [^ self error: 'expecting a Boolean'].
	self isHidden: aBool.
	self spread.
	self propagate: #isHidden! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:46'!
passiveSetLayerTo: aNumber

	self layer: aNumber asNumberNoError truncated.
	self spread.
	self propagate: #layer! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:57'!
passiveTransparencyEffect: aNumber

	self privateSetGraphicEffect: 'transparency' to: aNumber asNumberNoError.
	self propagate: #ghost! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 15:57'!
passiveWhirlEffect: aNumber

	self privateSetGraphicEffect: 'whirl' to: aNumber asNumberNoError.
	self propagate: #whirl! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:25'!
pixelateEffect

	| att |
	att _ #pixelate.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ [filterPack pixelateCount] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 01:00'!
pixelateEffect: aNumber

	self undeleteAttribute: #pixelate.
	self passivePixelateEffect: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/4/2011 01:37'!
pointillizeEffect
	^ [filterPack pointillizeSize] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/3/2011 21:38'!
pointillizeEffect: aNumber
	self setGraphicEffect: 'pointillize' to: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 14:01'!
privateSetGraphicEffect: effect to: aNumber
	"Set the given graphic effect to the given value."

	filterPack ifNil: [filterPack _ FilterPack new].

	'blur' = effect ifTrue: [filterPack blur: aNumber].
	'brightness' = effect ifTrue: [filterPack brightnessShift: aNumber].
	'fisheye' = effect ifTrue: [filterPack fisheye: aNumber].
	'color' = effect ifTrue: [filterPack hueShift: aNumber].
	'mosaic' = effect ifTrue: [filterPack mosaicCount: aNumber].
	'pixelate' = effect ifTrue: [filterPack pixelateCount: aNumber].
	'pointillize' = effect ifTrue: [filterPack pointillizeSize: aNumber].
	'saturation' = effect ifTrue: [filterPack saturationShift: aNumber].
	('transparency' = effect) | ('ghost' = effect) ifTrue: [self transparency: aNumber].
	'water ripple' = effect ifTrue: [filterPack waterRippleRate: aNumber].
	'whirl' = effect ifTrue: [filterPack whirl: aNumber].

	costumeChangeMSecs _ Time millisecondClockValue.
	self changed.
	self spread! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/23/2011 21:59'!
propagateCostumes

	self instances do: [:child |
		child inheritCostumesNow]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/23/2011 23:14'!
propagateSounds

	self instances do: [:child |
		child inheritSoundsNow]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/4/2011 01:38'!
saturationEffect
	^ [filterPack saturationShift] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/3/2011 21:39'!
saturationEffect: aNumber
	self setGraphicEffect: 'saturation' to: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 01:05'!
setHideFlagTo: aBool

	self undeleteAttribute: #isHidden.
	self passiveSetHideFlagTo: aBool! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 01:06'!
setLayerTo: aNumber

	self undeleteAttribute: #layer.
	self passiveSetLayerTo: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/23/2011 12:36'!
sounds
	"this will at some future time answer first class sounds,
	for now it's just the sound names"

	^ ScratchListMorph on: ((media select: [:m | 
		m isSound]) collect: [:c | c mediaName])! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:27'!
transparencyEffect

	| att |
	att _ #ghost.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ self transparency! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 01:03'!
transparencyEffect: aNumber

	self undeleteAttribute: #ghost.
	self passiveTransparencyEffect: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/4/2011 01:38'!
waterRippleEffect
	^ [filterPack waterRippleRate] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/3/2011 21:40'!
waterRippleEffect: aNumber
	self setGraphicEffect: 'water ripple' to: aNumber! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:24'!
whirlEffect

	| att |
	att _ #whirl.
	self prototype ifNotNil: [
		(self deletedAttributes includes: att) ifTrue: [
			^ self prototype get: att]].

	^ [filterPack whirl] ifError: [0]! !

!ScriptableScratchMorph methodsFor: 'BYOB attributes' stamp: 'jens 2/9/2011 00:56'!
whirlEffect: aNumber

	self undeleteAttribute: #whirl.
	self passiveWhirlEffect: aNumber! !


!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 2/24/2011 21:39'!
allSprites

	| stage |
	stage _ self ownerThatIsA: ScratchStageMorph.
	stage ifNil: [^ ScratchListMorph new].
	^ ScratchListMorph on: stage sprites! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 2/23/2011 22:28'!
deleteAttribute: aSymbol

	| cat sf oi block w |
	self prototype ifNil: [
		^ self error: 'cannot delete attribute without prototype'].

	oi _ self objectInterface.
	((oi at: aSymbol) at: 5) = #- ifTrue: [
		^ self error: 'undeletable attribute'].

	"special case for media"
	(#(costumes sounds) includes: aSymbol) ifFalse: [
		self perform: (oi at: aSymbol) third with: (self prototype perform: (oi at: aSymbol) second)].

	deletedAttributes ifNil: [
		deletedAttributes _ Set new].
	deletedAttributes add: aSymbol.

	#costumes = aSymbol ifTrue: [
		self inheritCostumesNow].

	"update palette"

	sf _ self scratchFrame.
	sf ifNil: [^ self].
	cat _ (oi at: aSymbol) first.
	sf viewerPane categoryChanged: cat.

	"update watchers"

	block _ self blockForSelector: ((oi at: aSymbol) second).

	block ifNil: [^ self].
	w _ sf watcherForBlock: block.
	w ifNil: [^ self].
	w setCategoryColor: block color twiceLighter.
	! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 2/9/2011 10:47'!
deleteAttributes: aCollection

	"use this when duplicating a sprite"

	self undeleteAllAttributes.
	aCollection do:[:attrib |
		self deleteAttribute: attrib ]	! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 2/23/2011 00:42'!
deleteObject: anObject

	| oi obj att block sel rcv |
	(anObject isKindOf: ScratchSpriteMorph)
		ifTrue: [^ self deleteSprite: anObject].

	(anObject isKindOf: CommandScriptBlockMorph) ifTrue: [
		oi _ self objectInterface.
		obj _ anObject receiver.
		(obj isKindOf: ScratchSpriteMorph) ifFalse: [
			^ self error: 'cannot delete attributes of non-Sprites'].
		block _ anObject body argMorphs first.

		(block isKindOf: VariableBlockMorph) ifTrue: [
			rcv _ block receiver.
			rcv ifNil: [^ self].
			^ rcv deleteVariable: block variable].
			
		block selector = #get: 
			ifTrue: [sel _ (oi at: (block argMorphs first choice)) second]
			ifFalse: [sel _ block selector].
		att _ oi keys detect: [:key |
			(oi at: key) second  = sel] ifNone: [
				^ self error: 'no attribute found for selector: ', anObject selector].
		^ obj deleteAttribute: att ].

	self error: 'cannot delete this'.! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 2/3/2011 23:32'!
deletedAttributes
	^ deletedAttributes ifNil: [ 
		deletedAttributes _ Set new]! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 4/19/2011 15:32'!
get: anObject

	| oi sel obj att block |

	anObject = #null
		ifTrue: [^nil].

	oi _ self objectInterface.

	(anObject isKindOf: Symbol) ifTrue: [
		sel _ oi at: anObject ifAbsent: [^ self error: 'unknown attribute: ', anObject asString ].
		sel second = #- ifTrue: [
			^ self error: 'cannot read this attribute'].
		^ self perform: sel second ].
		
	(anObject isKindOf: CommandScriptBlockMorph) ifTrue: [
		obj _ anObject receiver.
		(obj isKindOf: ScriptableScratchMorph) ifFalse: [
			^ self error: 'cannot get attributes of non-Sprites/Stage'].
		block _ anObject body argMorphs first.
		att _ oi keys detect: [:key |
			(oi at: key) second  = block selector] ifNone: [
				^ self error: 'no attribute found for selector: ', anObject selector].
		^ obj get: att ].

	^ anObject! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 2/23/2011 21:11'!
objectInterface

	^ Dictionary new addAll:


	{	"attribute					category		getter				setter				menu string			inheritable"

		#name				->	#(	sprite			objName 			objName:			'name'				-			).
		#isDraggable		->	#(	sprite			getIsDraggable		draggable:			'draggable?'			+			).
		#rotationStyle		->	#(	sprite			getRotationStyle 	setRotationStyle:		'rotation style'		+			).
		#rotateWithOwner	->	#(	sprite			rotateWithOwner 	rotateWithOwner:	'synchronous?'		+			).

		#xPosition			->	#(	motion			xpos 				xpos:				'x position'			+ 			).
		#yPosition			->	#(	motion			ypos 				ypos:				'y position'			+			).
		#heading			->	#(	motion			heading 			heading:			'direction'			+			).

		#costumes			->	#(	looks			costumes			-					'costumes'			+			).
		#costumeIndex		->	#(	looks			costumeIndex		lookLike:			'costume #'			+			).
		#size				->	#(	looks			scale				setSizeTo:			'size'				+			).
		#isHidden			->	#(	looks			isHidden				setHideFlagTo:		'hidden?'			+			).
		#layer				->	#(	looks			layer				setLayerTo:			'layer'				+			).

		#color				->	#(	effects			colorEffect			colorEffect:			'color effect'		+			).
		#fisheye			->	#(	effects			fisheyeEffect		fisheyeEffect:		'fisheye effect'		+			).
		#whirl				->	#(	effects			whirlEffect			whirlEffect:			'whirl effect'		+			).
		#pixelate			->	#(	effects			pixelateEffect		pixelateEffect:		'pixelate effect'		+			).
		#mosaic				->	#(	effects			mosaicEffect		mosaicEffect:		'mosaic effect'		+			).
		#brightness			->	#(	effects			brightnessEffect		brightnessEffect:	'brightness'			+			).
		#ghost				->	#(	effects			transparencyEffect	transparencyEffect:	'ghost effect'		+			).

		#sounds				->	#(	sound			sounds				-					'sounds'				+			).
		#instrument			->	#(	sound			-					midiInstrument:		'instrument'			-			).
		#volume			->	#(	sound			volume				setVolumeTo:		'volume'			+			).
		#tempo				->	#(	sound			tempo				setTempoTo:			'tempo'				+			).

		#penDown			->	#(	pen				penDown			penDown:			'pen down?'			+			).
		#penColor			->	#(	pen				penHue				setPenHueTo:		'pen color'			+			).
		#penShade			->	#(	pen				penShade			setPenShadeTo:		'pen shade'			+			).
		#penSize			->	#(	pen				penSize				penSize:				'pen size'			+			).

		#prototype			->	#(	relationship		prototype			prototype:			'parent'				-			).
		#instances			->	#(	relationship		children			-					'children'			-			).
		#anchor			->	#(	relationship		ownerSprite			stickTo:				'anchor'			+			).
		#parts				->	#(	relationship		parts				-					'parts'				-			).

	}; yourself! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 5/19/2011 12:23'!
set: anObject to: aValue

	| oi sel obj att block arg |

	oi _ self objectInterface.

	(anObject isKindOf: Symbol) ifTrue: [
		sel _ oi at: anObject ifAbsent: [^ self error: 'unknown attribute: ', anObject asString ].
		sel third = #- ifTrue: [
			^ self error: 'cannot set r/o attribute'].
		^ self perform: sel third with: aValue ].
		
	(anObject isKindOf: String) ifTrue: [
		^ self setVar: anObject to: aValue].

	(anObject isKindOf: CommandScriptBlockMorph) ifTrue: [
		obj _ anObject receiver.
		(obj isKindOf: ScriptableScratchMorph) ifFalse: [
			^ self error: 'cannot get attributes of non-Sprites/Stage'].
		block _ anObject body argMorphs first.
		(block isKindOf: VariableBlockMorph) ifTrue: [
			^ obj setVar: block variable to: aValue].
		#get: = block selector 
			ifTrue: [ 
				arg _ block argumentAt: 1.
				(arg isKindOf: ChoiceArgMorph)
					ifTrue: [ att _ (block argumentAt: 1) choice ]
					ifFalse: [ att _ (block argumentAt: 1) evaluate ]]
			ifFalse: [
				att _ oi keys detect: [:key |
					(oi at: key) second  = block selector] ifNone: [
						^ self error: 'no attribute found for selector: ', anObject selector]].
		^ obj set: att to: aValue ].

	self error: ['cannot set this value']! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 2/3/2011 23:36'!
undeleteAllAttributes

	deletedAttributes _ nil! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 3/22/2011 23:26'!
undeleteAllBlocks

	self inheritedBlocks do: [:eachDef |
		self ensureOwnBlockExists: eachDef]! !

!ScriptableScratchMorph methodsFor: 'BYOB object interface' stamp: 'jens 2/11/2011 12:03'!
undeleteAttribute: aSymbol

	| oi sf cat block w |
	deletedAttributes ifNil: [
		deletedAttributes _ Set new].
	deletedAttributes remove: aSymbol ifAbsent: [^ nil].

	"update palette"
	
	oi _ self objectInterface.
	sf _ self scratchFrame.
	sf ifNil: [^ self].
	cat _ (oi at: aSymbol) first.
	sf viewerPane categoryChanged: cat.

	"update watchers"

	block _ self blockForSelector: ((oi at: aSymbol) second).
	block ifNil: [^ self].
	w _ sf watcherForBlock: block.
	w ifNil: [^ self].
	w setCategoryColor: block color! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScriptableScratchMorph class
	instanceVariableNames: ''!

!ScriptableScratchMorph class methodsFor: 'class initialization' stamp: 'jm 5/14/2008 18:48'!
initialize
	"self initialize"

	Experimental _ false.
	ScratchOrigin _ 0@0.
	RandomGen _ Random new.
	TimerStartMSecs _ Time millisecondClockValue.
	ListBlockColor _ Color h: 18 s: 0.92 v: 0.85.
! !


!ScriptableScratchMorph class methodsFor: 'block specs' stamp: 'jm 8/23/2006 12:58'!
blockColorDict

	^ BlockColorDict
! !

!ScriptableScratchMorph class methodsFor: 'block specs' stamp: 'jens 6/8/2010 22:41'!
blockColorFor: aCategory
	"Answer the block color for the given category."

	'control' = aCategory ifTrue: [^ (Color h: 41 s: 0.85 v: 0.9)].
	'motion' = aCategory ifTrue: [^ (Color h: 225 s: 0.65 v: 0.83)].
	'motor' = aCategory ifTrue: [^ (Color h: 220 s: 0.85 v: 0.725)].
	'looks' = aCategory ifTrue: [^ (Color h: 264 s: 0.62 v: 0.89)].
	'pen' = aCategory ifTrue: [^ (Color h: 165 s: 1 v: 0.63)].
	'operators' = aCategory ifTrue: [^ (Color h: 93 s: 0.9 v: 0.76)].
	'sound' = aCategory ifTrue: [^ (Color h: 296 s: 0.66 v: 0.85)].
	'sensing' = aCategory ifTrue: [^ (Color h: 200 s: 0.98 v: 0.86)].
	'variables' = aCategory ifTrue: [^ (Color h: 25 s: 0.88 v: 0.95)].
	'list' = aCategory ifTrue: [^ ListBlockColor].
	(#('none' 'other') includes: aCategory) ifTrue: [^ Color lightGray ].

	^ (Color h: 0 s: 0.81 v: 0.83)  "a shade of red"
! !

!ScriptableScratchMorph class methodsFor: 'block specs' stamp: 'jm 5/26/2005 17:02'!
blockSpecDict
	"Answer my block specification dictionary."

	BlockSpecDict ifNil: [self buildBlockSpecDictionary].
	^ BlockSpecDict

! !

!ScriptableScratchMorph class methodsFor: 'block specs' stamp: 'jens 3/21/2011 00:37'!
blockSpecs
	"Answer a collection of block specifications for the blocks that are common to all objects. Block specificatons (Arrays) are interspersed with category names (Strings). A block specification is an Array of the form: (<block spec string> <block type> <selector> [optional initial argument values]).

	Explanation of flags:
		-	no flags
		b	boolean reporter
		c	c-shaped block containing a sequence of commands (always special form)
		r	reporter
		R	special form reporter with its own evaluation rule
		s	special form command with its own evaluation rule
		t	timed command, like wait or glide
		E	message event hat
		K	key event hat
		M	mouse-click event hat
		S	start event hat
		W	when <condition> hat (obsolete)"

	| blocks |
	blocks _ #(
		'control'
			('when %m clicked'				S	-)
			('when %k key pressed'			K	-)
			('when %m clicked'				M	-)
			-
			('wait %n secs'					t	wait:elapsed:from: 1)
			-
			('forever'						c	doForever)
			('repeat %n'						c	doRepeat 10)
			-
			('broadcast %e'					-	broadcast:)
			('broadcast %e and wait'			s	doBroadcastAndWait)
			('when I receive %e'			E	-)
			-
			('forever if %b'					c	doForeverIf)
			('if %b'							c	doIf)
			('if %b'							c	doIfElse)
			('wait until %b'					s	doWaitUntil)
			('repeat until %b'				c	doUntil)
			-
"			('stop all scripts for %e'			-	stopAllScriptsFor:)"
			('stop script'					s	doReturn)
			('stop all'						-	stopAll)
"			-
			('self'							r	objName)"
			=
			('run %o'						u	doRun)
			('run %o %A %s'				u	doRunBlockWithArgs)
			('run %o %A %t'					u	doRunBlockWithArgList)
			('launch %o'					u	doFork)
			('launch %o %A %s'				u	doForkBlockWithArgs)
			('launch %o %A %t'				u	doForkBlockWithArgList)
			('call %r'						d	doReport)
			('call %r %A %s'					d	doCallBlockWithArgs)
			('call %r %A %t'					d	doCallBlockWithArgList)
			-
			('report %s'						s	doAnswer)
			('stop block'						s	doStopBlock)
			-
			('debug'							s	doPauseThread)
			('debug %s'						R	doPauseThreadReporter)
		'operators'
			('%n + %n'						r	+ - -)
			('%n - %n'						r	- - -)
			('%n * %n'						r	* - -)
			('%n / %n'						r	/ - -)
			-
			('pick random %n to %n'		r	randomFrom:to: 1 10)
			-
			('%s < %s'						b	< '' '')
			('%s = %s'						b	= '' '')
			('%s > %s'						b	> '' '')
			-
			('%b and %b'					b	&)
			('%b or %b'						b	|)
			('not %b'						b	not)
			-
			('true'							b	getTrue)
			('false'							b	getFalse)
			-
			('join %s %s'					r	concatenate:with: 'hello ' 'world')
			('letter %n of %s'				r	letter:of: 1 'world')
			('length of %s'					r	stringLength: 'world')
			-
			('ascii code of %s'				r	asciiCodeOf: 'a')
			('ascii %n as letter'				r	asciiLetter: '65')
			-
			('%n mod %n'					r	\\ - -)
			('round %n'						r	rounded -)
			-
			('%f of %n'						r	computeFunction:of: 'sqrt' 10)
			-
			('is %s a %F ?'					b	isObject:type:)
			=
			('the script'						q	procedure)
			('the script. Input names: %s'			q	procedureWithArgs)
			('the %Z block'					Q	function)
			('the %Z block. Input names: %s'		Q	functionWithArgs)
			-
			('clone'							r	spawn)
"			('set %a to %s'					- 	set:to:)"
"			('delete %m'						-	deleteObject:)"

		'sound'
			('play sound %S'				-	playSound:)
			('play sound %S until done'		s	doPlaySoundAndWait)
			('stop all sounds'				-	stopAllSounds)
			-
			('play drum %D for %n beats'	t 	drum:duration:elapsed:from: 48 0.2)
			('rest for %n beats'				t 	rest:elapsed:from: 0.2)
			-
			('play note %N for %n beats'	t	noteOn:duration:elapsed:from: 60 0.5)
			('set instrument to %I'			- 	midiInstrument: 1)
			-
			('change volume by %n'		- 	changeVolumeBy: -10)
			('set volume to %n%'			- 	setVolumeTo: 100)
			('volume'						r 	volume)
			-
			('change tempo by %n'			- 	changeTempoBy: 20)
			('set tempo to %n bpm'			- 	setTempoTo: 60)
			('tempo'							r 	tempo)
		'motor'
			('motor on for %n secs'			t	motorOnFor:elapsed:from: 1)
			('motor on'						-	allMotorsOn)
			('motor off'						-	allMotorsOff)
			('motor power %n'				-	startMotorPower: 100)
			('motor direction %W'			-	setMotorDirection: 'this way')
		'variables'
			('show variable %v'				-	showVariable:)
			('hide variable %v'				-	hideVariable:)
			('delete %r'						-	deleteObject:)
"			('variable named %s'			r	getVarOrListNamed:)"
		'list'
			('list %X'						r	newList:)
			-
			('add %s to %L'					-	append:toList: 'thing')
			('delete %y of %L'				-	deleteLine:ofList: 1)
			('insert %s at %i of %L'			-	insert:at:ofList: 'thing' 1)
			('replace item %i of %L with %s'		-	setLine:ofList:to: 1 'list' 'thing')
			-
			('item %i of %L'					r	getLine:ofList: 1)
			('length of %L'					r	lineCountOfList:)
			('%L contains %s'				b	list:contains: 'list' 'thing')
			('%L as text'						r	contentsOfList: )
			-
			('copy of %t'					r	copyOfList: )
	).

	^ blocks, self obsoleteBlockSpecs
! !

!ScriptableScratchMorph class methodsFor: 'block specs' stamp: 'jm 4/1/2005 07:25'!
buildBlockSpecDictionary
	"self buildBlockSpecDictionary"

	| blockColor sel |
	BlockSpecDict _ IdentityDictionary new: 250.
	BlockColorDict _ IdentityDictionary new: 250.

	self withAllSubclassesDo: [:cl |
		blockColor _ Color blue.
		cl blockSpecs do: [:spec |
			((spec isKindOf: String) and: [spec size > 1]) ifTrue: [
				"set color  for this category"
				blockColor _ self blockColorFor: spec].
			(spec isMemberOf: Array) ifTrue: [
				sel _ spec at: 3.
				BlockSpecDict at: sel put: spec.
				BlockColorDict at: sel put: blockColor]]].
! !

!ScriptableScratchMorph class methodsFor: 'block specs' stamp: 'jm 5/14/2008 18:49'!
listBlockColor

	^ ListBlockColor
! !

!ScriptableScratchMorph class methodsFor: 'block specs' stamp: 'ee 3/28/2009 15:32'!
obsoleteBlockSpecs
	"Answer a list of specifications for the graphic filter blocks."

	^ #(
	'obsolete number blocks'
		('abs %n'							r	abs -)
		('sqrt %n'							r	sqrt -)
	'obsolete sound blocks'
		('rewind sound %S'					-	rewindSound:)
	'obsolete sprite motion blocks'
		('point away from edge'				-	turnAwayFromEdge)
		('glide x:%n y:%n in %n secs'		t	gotoX:y:duration:elapsed:from: 50 50 1)
	'obsolete sprite looks blocks'
		('change costume by %n'			-	changeCostumeIndexBy: 1)
		('change background by %n' 		-	changeBackgroundIndexBy: 1)
		-
		('change stretch by %n'				-	changeStretchBy:)
		('set stretch to %n%'					-	setStretchTo: 100)
		-
		('say nothing'						-	sayNothing)
		-
		('change visibility by %n'			-	changeVisibilityBy: -10)
		('set visibility to %n%'				-	setVisibilityTo: 100)
	'obsolete image effects'
		('change color-effect by %n'		-	changeHueShiftBy: 25)
		('set color-effect to %n'				-	setHueShiftTo: 0)
		-
		('change fisheye by %n'			-	changeFisheyeBy: 10)
		('set fisheye to %n'					-	setFisheyeTo: 0)
		~
		('change whirl by %n'				-	changeWhirlBy: 30)
		('set whirl to %n'					-	setWhirlTo: 0)
		-
		('change pixelate by %n'			- 	changePixelateCountBy: 1)
		('set pixelate to %n'					- 	setPixelateCountTo: 1)
		~
		('change mosaic by %n'				- 	changeMosaicCountBy: 1)
		('set mosaic to %n'					- 	setMosaicCountTo: 1)
		-
		('change brightness-shift by %n'	-	changeBrightnessShiftBy: 10)
		('set brightness-shift to %n'			-	setBrightnessShiftTo: 0)
		~
		('change saturation-shift by %n'	-	changeSaturationShiftBy: 10)
		('set saturation-shift to %n'			-	setSaturationShiftTo: 0)
		-
		('change pointillize drop by %n'		-	changePointillizeSizeBy: 5)
		('set pointillize drop to %n'			-	setPointillizeSizeTo: 0)
		~
		('change water ripple by %n'		-	changeWaterRippleBy: 5)
		('set water ripple to %n'				-	setWaterRippleTo: 0)
		-
		('change blur by %n'				-	changeBlurBy: 1)
		('set blur to %n'						-	setBlurTo: 0)
	)
! !


!ScriptableScratchMorph class methodsFor: 'forms/sounds/icons' stamp: 'jm 11/4/2005 12:36'!
defaultBackgroundForm

	(DefaultBackgroundForm isNil or:
	 [DefaultBackgroundForm extent ~= ScratchFrameMorph workpaneExtent]) ifTrue: [
		DefaultBackgroundForm _ (Form extent: ScratchFrameMorph workpaneExtent depth: 1).
		DefaultBackgroundForm fillWhite].

	^ DefaultBackgroundForm
! !

!ScriptableScratchMorph class methodsFor: 'forms/sounds/icons' stamp: 'jm 5/5/2007 12:57'!
meowSound
	"MeowSound _ SampledSound fromFileNamed: ((FileDirectory default directoryNamed: 'ScratchSkin') fullNameFor: 'kitten.wav')"

	^ MeowSound
! !

!ScriptableScratchMorph class methodsFor: 'forms/sounds/icons' stamp: 'jm 5/8/2007 11:03'!
oldMeowPrefixReversed

	^ OldMeowPrefixReversed
! !

!ScriptableScratchMorph class methodsFor: 'forms/sounds/icons' stamp: 'jm 12/12/2004 11:54'!
popSound

	^ PopSound
! !


!ScriptableScratchMorph class methodsFor: 'translation support' stamp: 'ee 10/24/2007 09:31'!
blockSpecsArrayForTranslation
	"Answer an array that lists all the blocks and categories to be used as a guide to block translation."
	"self blockSpecDictForTranslation"

	| blocks all obsolete currentSpecs |
	currentSpecs _ Set new.
	ScratchSpriteMorph new blockCategories sort collect: [:cat |
		blocks _  (ScratchSpriteMorph new blocksFor: cat)
			select: [:b | b isKindOf: CommandBlockMorph].
		all _ blocks collect: [:b | b commandSpec].
		obsolete _ ScriptableScratchMorph obsoleteBlockSpecs collect: [:o | o first].
		all _  all select: [:p | (obsolete indexOf: p) = 0].
		(cat beginsWith: 'obsolete') ifFalse:[currentSpecs add: cat].
		currentSpecs addAll: all].
	currentSpecs _ currentSpecs asArray sort.
	^ currentSpecs
! !

!ScriptableScratchMorph class methodsFor: 'translation support' stamp: 'jm 11/29/2007 13:20'!
blockSpecsForTranslation
	"Answer a collection blocks for translation. Obsolete blocks are removed."

	| allSpecs |
	allSpecs _ Set new.
	(ScriptableScratchMorph blockSpecs,
	 ScratchSpriteMorph blockSpecs,
	 ScratchStageMorph blockSpecs) do: [:el |
		(el isKindOf: Array)
			ifTrue: [allSpecs add: el first]
			ifFalse: [((el beginsWith: 'obsolete') or:[#('-' '~') includes: el])
				ifFalse:[allSpecs add: el]]].
	ScriptableScratchMorph obsoleteBlockSpecs do: [:el |
		(el isKindOf: Array) ifTrue: [allSpecs remove: el first ifAbsent: []]].
	allSpecs
		add: 'else';
		add: 'variables';
		add: 'set %v to %n';
		add: 'change %v by %n'.
	^ allSpecs asArray sort
! !

!ScriptableScratchMorph class methodsFor: 'translation support' stamp: 'ee 10/23/2007 13:49'!
blockSpecsStringForTranslation
	"Answer a String that lists all the blocks and categories to be used as a guide to block translation."

	| out blocks pairs key |
	out _ WriteStream on: (String new: 10000).
	ScratchSpriteMorph new blockCategories sort collect: [:cat |
		out nextPutAll: '-	', cat; cr.
		blocks _  (ScratchSpriteMorph new blocksFor: cat)
			select: [:b | b isKindOf: CommandBlockMorph].
		pairs _ blocks collect: [:b |
			key _ b selector collect: [:ch | ch = $: ifTrue: [$_] ifFalse: [ch]].
			Array with: key with: b commandSpec].
		pairs sort: [:p1 :p2 | p1 first < p2 first].
		pairs do: [:p | out nextPutAll: p first; tab; nextPutAll: p last; cr]].
	^ out contents
! !


!ScriptableScratchMorph class methodsFor: 'other' stamp: 'jm 10/21/2005 11:20'!
doubleSize: aBoolean

	DoubleSize _ aBoolean.
! !

!ScriptableScratchMorph class methodsFor: 'other' stamp: 'jm 8/13/2003 17:07'!
fromUser
	"Go into a mode asking the user to select an instance of me, displaying a crossHair cursor while in this mode. The mode ends with the next mouse click. If the click is over an instance of me, return it. Otherwise, return nil. Keep running the world while waiting for the mouse click."

	| result p m mList |
	World ifNil: [^ self].  "not in morphic"
	result _ nil.
	Cursor crossHair showWhile: [
		[Sensor anyButtonPressed] whileFalse: [World doOneCycleNoInput].
		p _ Sensor cursorPoint.
		m _ (World rootMorphsAt: p) first.
		(m isKindOf: ScratchFrameMorph) ifTrue: [
			mList _ m workPane rootMorphsAt: p.
			mList size > 0 ifTrue: [
				m _ (m workPane rootMorphsAt: p) first]].
		(m isKindOf: self) ifTrue: [result _ m].
		Sensor waitNoButton].
	^ result
! !

!ScriptableScratchMorph class methodsFor: 'other' stamp: 'jm 3/17/2009 15:28'!
isSpriteSpecificTarget: anObject selector: selector
	"I determine whether the given selector is specific to a particular Sprite. ."

	| i |
	(anObject isKindOf: ScratchSpriteMorph) ifFalse: [^ false].
	i _ selector asString
		findAnySubStr: #('answer' 'key' 'Loud' 'mouse' 'sensor' 'soundLevel' 'tempo' 'timer')
		startingAt: 1.
	^ i > selector asString size
! !

!ScriptableScratchMorph class methodsFor: 'other' stamp: 'jm 10/23/2007 12:48'!
randomInit

	RandomGen initialize.
! !

!ScriptableScratchMorph class methodsFor: 'other' stamp: 'tis 7/31/2006 16:04'!
resetTimer

	TimerStartMSecs _ Time millisecondClockValue.
! !

!ScriptableScratchMorph class methodsFor: 'other' stamp: 'jm 10/21/2005 11:21'!
scratchOrigin: aPoint
	"Set the origin for the Scratch coordinate system."

	ScratchOrigin _ aPoint.
! !

!ScriptableScratchMorph class methodsFor: 'other' stamp: 'jm 5/10/2006 11:22'!
soundRecorder
	"Return the shared Scratch SoundRecorder. Create and start it, if necessary."

	Recorder ifNil: [
		Recorder _ SoundRecorder new.
		Recorder startRecording].
	Recorder isActive ifFalse: [Recorder startRecording].
	^ Recorder
! !

!ScriptableScratchMorph class methodsFor: 'other' stamp: 'jm 5/12/2006 10:58'!
stopSoundRecorder
	"Stop the shared sound recorder."
	"self stopSoundRecorder"

	Recorder ifNotNil: [Recorder stopRecording; clearRecordedSound].

! !


!ScriptableScratchMorph class methodsFor: 'byob legacy support' stamp: 'jens 6/13/2009 22:25'!
currentEncoding
		^ObjEncoding ifNil: [^#scratch ]! !

!ScriptableScratchMorph class methodsFor: 'byob legacy support' stamp: 'jens 6/13/2009 22:23'!
decodeAsByob
		ObjEncoding _ #byob ! !

!ScriptableScratchMorph class methodsFor: 'byob legacy support' stamp: 'jens 6/13/2009 22:23'!
decodeAsScratch
		ObjEncoding _ #scratch ! !


!ScriptableScratchMorph class methodsFor: 'byob' stamp: 'jens 11/18/2009 00:24'!
doMakeNewList
	^nil! !

!ScriptableScratchMorph class methodsFor: 'byob' stamp: 'jens 2/10/2010 00:41'!
keepOnStage
	^KeepOnStage ifNil: [true ]! !

!ScriptableScratchMorph class methodsFor: 'byob' stamp: 'jens 11/2/2009 23:41'!
keepOnStage: aBool
	KeepOnStage _ aBool! !


ScriptableScratchMorph initialize!
