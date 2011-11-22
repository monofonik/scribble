Object subclass: #ObjStream
	instanceVariableNames: 'objects objectIndex stream firstPass fields fieldIndex toDo '
	classVariableNames: 'FirstPointerClassID FloatClassID IDToClassEntry NameToClassEntry ObjectReferenceID '
	poolDictionaries: ''
	category: 'Scratch-Object IO'!
!ObjStream commentStamp: '<historical>' prior: 0!
I can serialize a collection of inter-connected objects onto a binary stream or reconstruct the original object network from its serialized form. This allows object structures to be saved in files, transmitted over a network, etc.

I support user class evolution via class version numbers, making it possible to detect and, if so desired, convert old object formats.

The format consists of a table of serialized objects. The first object in this table is the "root" object that was serialized; the rest of the objects in the table are objects reachable from this root object. Inter-object references are stored as indices into this table. These indices are mapped to actual object references when the structure is deserialized.

Object storage formats fall into one of these categories:
  a. immediate values: the constants nil, true, false, integers, and floats
  b. fixed-format objects whose serialization is handled by this class
  c. objects that handle their own serialization and whose formats may change over time

Objects in the first category are encoded in-line; they do not appear in the object table and thus cannot be shared. Integers that small enough to be represented in 16 bits have their own format. Objects in the second catetory are assumed to have stable storage formats, so they do not have a class version number. In the unlikely event that the storage format of any of these classes changes, the file format version must be incremented.

Objects in the last category support user-defined serialization. They are expected to implement the three instance methods storeFieldsOnXX:, initializeFromFieldsXX:, and objStreamVersion, where XX is the class version number. In general, any change to the serialization format of an object requires adding new versions of the methods storeFieldsOnXX: and initializeFromFieldsXX:, then incrementing the version number returned by objStreamVersion.

The class of every object in this category must appear in the class ID table. To ensure that old object files can be read, once an object has been assigned an ID that ID can't be changed and even if the class is deleted, it's ID must not used for another class.

Maximums:
  Object types (i.e., classes): 255
  User-defined class fields: 255
  Number of objects: 2^24 - 1
  Indexable object size: 2^32 - 1
!


!ObjStream methodsFor: 'entry points' stamp: 'jm 7/8/2008 05:58'!
nextField
	"Answer the next field and advance to the next field. This method should only be called from initFieldsFrom:version: during deserialization."
	"Note: If class versions are managed correctly, it should not be necessary to check that fieldIndex is in bounds. However, sometimes during development, we store a project that has objects with an extra field that is later removed. The check on fields size allows us to fail more gracefully in such cases."

	fieldIndex _ fieldIndex + 1.
	fieldIndex > fields size ifTrue: [^ nil]. "fail gracefully"
	^ fields at: fieldIndex
! !

!ObjStream methodsFor: 'entry points' stamp: 'jm 5/14/2005 11:44'!
objects

	^ objects
! !

!ObjStream methodsFor: 'entry points' stamp: 'jm 9/28/2003 12:07'!
putField: anObject
	"Put the given object. If the given object is nil, true, false, an integer, or a float, it is stored directly. Otherwise, it is stored as an object reference and the object will be stored exactly once no matter how many other objects refer to it."

	| entry classID putSelector |
	entry _ self classEntryFor: anObject.
	classID _ entry at: 1.
	putSelector _ entry at: 4.

 	firstPass ifTrue: [fields addLast: anObject].
	fieldIndex _ fieldIndex + 1.

	classID <= FloatClassID ifTrue: [  "store the value directly inline"
		firstPass ifFalse: [self perform: putSelector with: anObject with: classID].
		^ self].
	
	firstPass
		ifTrue: [self recordObject: anObject id: classID]
		ifFalse: [self writeObjRef: (fields at: fieldIndex)].
! !

!ObjStream methodsFor: 'entry points' stamp: 'jm 5/15/2005 09:12'!
readObjFrom: aStream
	"Read the root object from the given binary stream."

	^ self readObjFrom: aStream showProgress: false
! !

!ObjStream methodsFor: 'entry points' stamp: 'jens 6/30/2010 23:29'!
readObjFrom: aStream showProgress: showProgress
	"Read the root object from the given binary stream. If showProgress is true, display a progress bar."

	| objCount tenPercent |
	objects _ OrderedCollection new.
	stream _ aStream.
	self readFileHeader.

	firstPass _ true.
	objCount _ stream uint32.
	showProgress
		ifTrue: [
			tenPercent _ objCount // 10.
			('Reading...' localized, ScratchTranslator ellipsesSuffix)
				displayProgressAt: Display center - (32@5)  "Sensor cursorPoint"
				from: 0 to: objCount + tenPercent
				during: [:progressBar |
					1 to: objCount do: [:i |
						objects addLast: self readObjectRecord.
						progressBar value: i].

					firstPass _ false.
					objects do: [:rec | self fixReferencesForObjectRecord: rec].
					progressBar value: objCount + (tenPercent // 2).
					objects do: [:rec | self initializeUserDefinedFields: rec].

					progressBar value: objCount + tenPercent.
					Delay waitMSecs: 200]]
		ifFalse: [
			objCount timesRepeat: [objects addLast: self readObjectRecord].
			firstPass _ false.
			objects do: [:rec | self fixReferencesForObjectRecord: rec].
			objects do: [:rec | self initializeUserDefinedFields: rec]].

	^ objects first first
! !

!ObjStream methodsFor: 'entry points' stamp: 'jm 6/14/2005 10:08'!
readObjsFrom: aStream
	"For testing. Answer the entire objects table from the given stream."

	| objCount |
	objects _ OrderedCollection new.
	stream _ aStream.
	self readFileHeader.

	firstPass _ true.
	objCount _ stream uint32.
	objCount timesRepeat: [objects addLast: self readObjectRecord].
	firstPass _ false.
	objects do: [:rec | self fixReferencesForObjectRecord: rec].
	objects do: [:rec | self initializeUserDefinedFields: rec].

	^ objects

! !

!ObjStream methodsFor: 'entry points' stamp: 'jm 5/14/2005 11:23'!
storeObj: anObject on: aStream
	"Write the given object and all the objects that can be reached from it on the given binary stream. Do not display a progress bar."

	self storeObj: anObject on: aStream showProgress: false.
! !

!ObjStream methodsFor: 'entry points' stamp: 'jm 12/3/2003 07:18'!
storeObj: anObject on: aStream showProgress: showProgress
	"Write the given object and all the objects that can be reached from it on the given binary stream. If showProgress is true, display a progress bar."

	| sortedObjEntries i obj |
	objects _ IdentityDictionary new.
	objectIndex _ 1.

	"collect objects"
	stream _ nil.
	firstPass _ true.
	toDo _ OrderedCollection new.
	self recordObject: anObject id: (self classEntryFor: anObject) first.
	[toDo size > 0] whileTrue: [self recordFieldsOf: toDo removeFirst].

	"write object table"
	stream _ aStream.
	firstPass _ false.
	sortedObjEntries _ objects asArray sort: [:e1 :e2 | e1 first < e2 first].
	self writeFileHeader.
	stream uint32: sortedObjEntries size.
	showProgress
		ifTrue: [
			i _ 0.  "object counter for progress bar"
			'Saving...'
				displayProgressAt: Sensor cursorPoint
				from: 0 to: sortedObjEntries size
				during:  [:progressBar |
					sortedObjEntries do: [:objEntry |
						progressBar value: (i _ i + 1).
						obj _ objEntry at: 2.
						self writeObject: obj objEntry: objEntry]]]
		ifFalse: [
			sortedObjEntries do: [:objEntry |
				obj _ objEntry at: 2.
				self writeObject: obj objEntry: objEntry]].
! !


!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/23/2003 20:16'!
putArray: anObject id: classID

	self putCollection: anObject id: classID.
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/23/2003 16:49'!
putBigInt: anObject id: classID

	firstPass ifTrue: [^ self].
	stream nextPut: classID.
	stream uint16: anObject digitLength.
	1 to: anObject digitLength do: [:i | stream nextPut: (anObject digitAt: i)].
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 10/10/2003 09:06'!
putBitmap: anObject id: classID

	firstPass ifTrue: [^ self].
	stream nextPut: classID.
	stream uint32: anObject size.
	anObject do: [:el | stream uint32: el].
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/22/2003 18:42'!
putBytes: anObject id: classID

	firstPass ifTrue: [^ self].
	stream nextPut: classID.
	stream uint32: anObject size.
	stream nextPutAll: anObject asByteArray.
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/23/2003 20:15'!
putCollection: anObject id: classID

	firstPass ifFalse: [
		stream nextPut: classID.
		stream uint32: anObject size].
	anObject do: [:el | self putField: el].
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/23/2003 16:48'!
putColor: anObject id: classID

	| a |
	firstPass ifTrue: [^ self].
	stream nextPut: classID.
	stream uint32: anObject privateRGB.
	anObject class = TranslucentColor ifTrue: [
		a _ (anObject privateAlpha asInteger min: 255) max: 0.
		stream nextPut: a].
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/22/2003 18:31'!
putConst: anObject id: classID

	firstPass ifTrue: [^ self].
	stream nextPut: classID.
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/22/2003 18:57'!
putDict: anObject id: classID

	firstPass ifFalse: [
		stream nextPut: classID.
		stream uint32: anObject size].
	anObject associationsDo: [:assoc |
		self putField: assoc key.
		self putField: assoc value].
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/28/2003 11:48'!
putFloat: anObject id: classID

	firstPass ifTrue: [^ self].
	stream nextPut: classID.
	stream uint32: (anObject basicAt: 1).
	stream uint32: (anObject basicAt: 2).
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/24/2003 12:16'!
putForm: anObject id: classID

	firstPass ifFalse: [stream nextPut: classID].
	anObject hibernate.
	self putField: anObject width.
	self putField: anObject height.
	self putField: anObject depth.
	self putField: anObject privateOffset.
	self putField: anObject bits.
	(anObject class = ColorForm) ifTrue: [self putField: anObject colors].
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/22/2003 18:55'!
putPoint: anObject id: classID

	firstPass ifFalse: [
		stream nextPut: classID].
	self putField: anObject x.
	self putField: anObject y.
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/22/2003 18:56'!
putRect: anObject id: classID

	firstPass ifFalse: [
		stream nextPut: classID].
	self putField: anObject left.
	self putField: anObject top.
	self putField: anObject right.
	self putField: anObject bottom.
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 9/23/2003 13:55'!
putSmallInt: anObject id: classID

	firstPass ifTrue: [^ self].
	((-32768 <= anObject) and: [anObject <= 32767])
		ifTrue: [  "optimization for integers that fit into 16 bits"
			stream nextPut: classID + 1.
			stream int16: anObject]
		ifFalse: [
			stream nextPut: classID.
			stream int32: anObject].
! !

!ObjStream methodsFor: 'fixed format-writing' stamp: 'jm 3/20/2007 22:44'!
putSoundBuf: anObject id: classID

	firstPass ifTrue: [^ self].
	stream nextPut: classID.
	stream uint32: anObject size.
	anObject storeBigEndianOn: stream stereo: false.

! !


!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/28/2003 11:56'!
getArray: anObject id: classID

	| sz result |
	firstPass ifTrue: [
		sz _ stream uint32.
		result _ Array new: sz.
		1 to: sz do: [:i | result at: i put: self readField].
		^ result].

	"fix references"
	self fixRefsInArray: anObject.
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/28/2003 11:39'!
getBigInt: anObject id: classID

	| digitCount result |
	digitCount _ stream uint16.
	result _ (self classForID: classID) new: digitCount.
	1 to: digitCount do: [:i | result digitAt: i put: stream next].
	^ result
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 10/10/2003 09:07'!
getBitmap: anObject id: classID

	| count result |
	count _ stream uint32.
	result _ Bitmap new: count.
	1 to: count do: [:i | result at: i put: stream uint32].
	^ result
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 6/12/2008 09:48'!
getBytes: anObject id: classID

	| byteCount result |
	byteCount _ stream uint32.
	result _ stream next: byteCount.
	classID = 9 ifTrue: [^ result asString].
	classID = 10 ifTrue: [^ result asString asSymbol].
	classID = 14 ifTrue: [^ UTF8 withAll: result].
	^ result
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/28/2003 11:56'!
getCollection: anObject id: classID

	| sz result newContents |
	firstPass ifTrue: [
		sz _ stream uint32.
		result _ (self classForID: classID) new: sz.
		sz timesRepeat: [result add: self readField].
		^ result].

	"fix references"
	newContents _ anObject asArray.
	self fixRefsInArray: newContents.
	anObject removeAll: anObject copy; addAll: newContents.
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/23/2003 17:30'!
getColor: anObject id: classID

	| rgb |
	firstPass ifFalse: [^ anObject].
	rgb _ stream uint32.
	(self classForID: classID) = TranslucentColor
		ifTrue: [^ TranslucentColor basicNew setRgb: rgb alpha: stream next]
		ifFalse: [^ Color basicNew setRgb: rgb].
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/23/2003 16:35'!
getConst: anObject id: classID

	classID = 1 ifTrue: [^ nil].
	classID = 2 ifTrue: [^ true].
	classID = 3 ifTrue: [^ false].
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/28/2003 11:57'!
getDict: anObject id: classID

	| sz result key value newContents |
	firstPass ifTrue: [
		sz _ stream uint32.
		result _ (self classForID: classID) new: sz.
		sz timesRepeat: [
			key _ self readField.
			value _ self readField.
			result at: key put: value].
		^ result].

	"fix references"
	newContents _ OrderedCollection new: anObject size.
	anObject copy associationsDo: [:assoc |
		newContents add: ((self targetObjectFor: assoc key) -> (self targetObjectFor: assoc value)).
		anObject removeKey: assoc key].
	anObject size = 0 ifFalse: [self error: 'should be empty!!'].
	anObject addAll: newContents.
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/24/2003 09:58'!
getFloat: anObject id: classID

	| result |
	result _ Float new: 2.
	result basicAt: 1 put: stream uint32.
	result basicAt: 2 put: stream uint32.
	^ result
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/24/2003 12:43'!
getForm: anObject id: classID

	| w h d offset bits result |
	firstPass ifTrue: [
		w _ self readField.
		h _ self readField.
		d _ self readField.
		offset _ self readField.
		bits _ self readField.
		result _ (self classForID: classID) basicNew
			setExtent: w@h depth: d bits: bits;
			offset: offset.
		(result class = ColorForm) ifTrue: [result privateColors: self readField].
		^ result].

	"fix references"
	anObject bits: (self targetObjectFor: anObject bits).
	anObject offset: (self targetObjectFor: anObject privateOffset).
	(anObject class = ColorForm) ifTrue: [anObject privateColors: (self targetObjectFor: anObject privateColors)].

! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/24/2003 14:13'!
getPoint: anObject id: classID

	| x y |
	firstPass ifTrue: [
		x _ self readField.
		y _ self readField.
		^ Point x: x y: y].

	"fix references"
	anObject
		setX: (self targetObjectFor: anObject x)
		setY: (self targetObjectFor: anObject y).
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/24/2003 14:13'!
getRect: anObject id: classID

	| x1 y1 x2 y2 |
	firstPass ifTrue: [
		x1 _ self readField.
		y1 _ self readField.
		x2 _ self readField.
		y2 _ self readField.
		^ (Point x: x1 y: y1) corner: (Point x: x2 y: y2)].

	"fix references"
	anObject origin
		setX: (self targetObjectFor: anObject origin x)
		setY: (self targetObjectFor: anObject origin y).
	anObject corner
		setX: (self targetObjectFor: anObject corner x)
		setY: (self targetObjectFor: anObject corner y).
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 9/23/2003 16:52'!
getSmallInt: anObject id: classID

	classID = 4 ifTrue: [^ stream int32].
	classID = 5 ifTrue: [^ stream int16].
! !

!ObjStream methodsFor: 'fixed format-reading' stamp: 'jm 2/13/2004 09:35'!
getSoundBuf: anObject id: classID

	| sampleCount result |
	sampleCount _ stream uint32.
	result _ SoundBuffer newMonoSampleCount: sampleCount.
	(stream isKindOf: FileStream)
		ifTrue: [
			stream next: (sampleCount // 2) into: result startingAt: 1.  "size is in 32-bit words"
			Smalltalk isBigEndian ifFalse: [result reverseEndiannessStereo: false]]
		ifFalse: [
			1 to: sampleCount do: [:i | result at: i put: stream int16]].

	^ result
! !


!ObjStream methodsFor: 'private-writing' stamp: 'jm 9/23/2003 14:15'!
classEntryFor: anObject
	"Answer the entry containing the class id and read/write selectors for the given object's class. Raise an error if the class is not registered."

	^ NameToClassEntry at: anObject class name
		ifAbsent: [self error: 'Unknown class ',  anObject class name]
! !

!ObjStream methodsFor: 'private-writing' stamp: 'jm 9/23/2003 14:16'!
putUserObj: anObject id: ignored
	"Ask the given user-defined object to write it's fields."

	anObject storeFieldsOn: self.
! !

!ObjStream methodsFor: 'private-writing' stamp: 'jm 9/23/2003 15:19'!
recordFieldsOf: anObject
	"Record the fields of the given object."
	"Details: Sometimes a user-defined class creates an object dynamically in a call to putField:. To preserve object identity between passes one and two, the objects passed to all calls to putField: are recorded during the first pass (i.e., by this method) and those exact same objects are used in the second pass."

	| entry classID putSelector |
	entry _ self classEntryFor: anObject.
	classID _ entry at: 1.
	putSelector _ entry at: 4.

	fields _ OrderedCollection new.
	fieldIndex _ 0.
	self perform: putSelector with: anObject with: classID.
	(objects at: anObject) at: 4 put: fields asArray.
! !

!ObjStream methodsFor: 'private-writing' stamp: 'jm 9/28/2003 12:26'!
recordObject: anObject id: classID
	"Assign an ID for the given object, add it to the list of objects to be stored in the object table, and add it to the toDo list. Do nothing if this object has already been recorded."

	(objects includesKey: anObject) ifTrue: [^ self].
	objects at: anObject put: (Array with: objectIndex with: anObject with: classID with: nil).
	toDo addLast: anObject.
	objectIndex _ objectIndex + 1.
! !

!ObjStream methodsFor: 'private-writing' stamp: 'jm 9/23/2003 15:08'!
writeFileHeader
	"Write the file header on my stream."

	stream nextPutAll: 'ObjS' asByteArray.
	stream nextPut: 1.
	stream nextPutAll: 'Stch' asByteArray.
	stream nextPut: 1.
! !

!ObjStream methodsFor: 'private-writing' stamp: 'jm 2/3/2009 14:14'!
writeObjRef: anObject
	"Write a reference to the given object to my output stream. The object must have an entry in the object dictionary."

	| objEntry objIndex |
	objEntry _ objects at: anObject ifAbsent: [self error: 'object not in dictionary'].  "should never happen"
	objIndex _ objEntry at: 1.
	stream nextPut: ObjectReferenceID.
	stream uint24: objIndex.
! !

!ObjStream methodsFor: 'private-writing' stamp: 'jm 9/24/2003 15:37'!
writeObject: anObject objEntry: objEntry
	"Write the object described by the given entry."

	| entry classID putSelector |
	entry _ self classEntryFor: anObject.
	classID _ entry at: 1.
	putSelector _ entry at: 4.

	fields _ objEntry at: 4.
	fieldIndex _ 0.

	putSelector = #putUserObj:id: ifTrue: [
		stream nextPut: classID.
		stream nextPut: anObject fieldsVersion.
		stream nextPut: fields size].

	self perform: putSelector with: anObject with: classID.
! !


!ObjStream methodsFor: 'private-reading' stamp: 'jm 9/23/2003 16:51'!
classForID: classID
	"Answer the class for the given class ID."

	^ Smalltalk at: (IDToClassEntry at: classID) second
! !

!ObjStream methodsFor: 'private-reading' stamp: 'jm 9/28/2003 15:27'!
fixReferencesForObjectRecord: objectRecord
	"After reading all the objects in the objects table, this method is called on each object record to replace all its object references with pointers to the actual object in the object table. The fields for user-defined objects are still held in an array in the object table record. Fixed-format objects are processed by calling their read selector a second time and, since firstPass is now false, this read method fixes any object references."

	| obj classEntry classID readSelector |
	obj _ objectRecord first.
	classEntry _ self classEntryFor: obj.
	classID _ classEntry first.

	classID >= FirstPointerClassID ifTrue: [
		classID > ObjectReferenceID
			ifTrue: [  "user defined class"
				self fixRefsInArray: (objectRecord at: 4)]
			ifFalse: [  "fixed format class"
				readSelector _ classEntry at: 3.
				self perform: readSelector with: obj with: classID]].
! !

!ObjStream methodsFor: 'private-reading' stamp: 'jm 10/21/2003 10:36'!
fixRefsInArray: anArray
	"Replace any ObjRefRecord objects in the given array with references to the actual objects."

	| el |
	1 to: anArray size do: [:i |
		el _ anArray at: i.
		el class = ObjRefRecord ifTrue: [
			el objectID > objects size
				ifTrue: [anArray at: i put: #badObjRef]
				ifFalse: [anArray at: i put: (objects at: el objectID) first]]].
! !

!ObjStream methodsFor: 'private-reading' stamp: 'jens 4/28/2010 03:59'!
initializeUserDefinedFields: objectRecord
	"If the given object record designates a user-defined object, ask that object to initialiize itself from its fields list. Otherwise, do nothing."

	| obj classID classVersion |
	obj _ objectRecord at: 1.
	classID _ objectRecord at: 2.
	classID > ObjectReferenceID ifTrue: [  "user defined class"
		classVersion _ objectRecord at: 3.
		fields _ objectRecord at: 4.
		fieldIndex _ 0.
		obj initFieldsFrom: self version: classVersion].
! !

!ObjStream methodsFor: 'private-reading' stamp: 'jm 9/23/2003 18:30'!
readField
	"Read a single object field. The result may be an object or an object reference."

	| classID readSelector |
	classID _ stream next.
	classID = ObjectReferenceID ifTrue: [
		^ ObjRefRecord new objectID: stream uint24].

	readSelector _ (IDToClassEntry at: classID) at: 3.
	^ self perform: readSelector with: nil with: classID
! !

!ObjStream methodsFor: 'private-reading' stamp: 'jm 9/23/2003 15:11'!
readFileHeader
	"Read the file header on my stream."

	(((stream next: 4) asString = 'ObjS') &
	 (stream next = 1) &
	 ((stream next: 4) asString = 'Stch') &
	 (stream next = 1)) ifFalse: [
		self error: 'bad header'].
! !

!ObjStream methodsFor: 'private-reading' stamp: 'jm 9/28/2003 12:15'!
readObjectRecord
	"Read the next object record. Answer an array of the form (<obj> <class ID> [<version> <fieldsArray>]). The version and fields array are supplied only for user-defined objects."

	| classID obj classVersion fieldCount fieldList readSelector |
	classID _ stream next.
	classID > ObjectReferenceID
		ifTrue: [  "user defined object"
			obj _ (self classForID: classID) new.
			classVersion _ stream next.
			fieldCount _ stream next.
			fieldList _ (1 to: fieldCount) collect: [:i | self readField].
			^ Array with: obj with: classID with: classVersion with: fieldList]
		ifFalse: [  "fixed format object"
			readSelector _ (IDToClassEntry at: classID) at: 3.
			obj _ self perform: readSelector with: nil with: classID.
			^ Array with: obj with: classID].
! !

!ObjStream methodsFor: 'private-reading' stamp: 'jm 9/23/2003 18:33'!
targetObjectFor: anObject
	"If the argument is an ObjRefRecord, answer the object that it refers to. Otherwise, just answer the argument."

	anObject class = ObjRefRecord
		ifTrue: [^ (objects at: anObject objectID) first]
		ifFalse: [^ anObject].
! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ObjStream class
	instanceVariableNames: ''!

!ObjStream class methodsFor: 'class initialization' stamp: 'jm 10/3/2007 14:11'!
fixedFormatClasses
	"Answer an array of records for fixed-format classes."

	^ #(
		"id	class					read selector		write selector"
		(1	UndefinedObject			getConst:id:			putConst:id:)
		(2	True					getConst:id:			putConst:id:)
		(3	False					getConst:id:			putConst:id:)
		(4	SmallInteger			getSmallInt:id:		putSmallInt:id:)
		(5	SmallInteger16			getSmallInt:id:		putSmallInt:id:)  "optimization for ints that fit into 16 bits"
		(6	LargePositiveInteger		getBigInt:id:			putBigInt:id:)
		(7	LargeNegativeInteger	getBigInt:id:			putBigInt:id:)
		(8	Float					getFloat:id:			putFloat:id:)
		(9	String					getBytes:id:			putBytes:id:)
		(10	Symbol					getBytes:id:			putBytes:id:)
		(11	ByteArray				getBytes:id:			putBytes:id:)
		(12	SoundBuffer			getSoundBuf:id:		putSoundBuf:id:)
		(13	Bitmap					getBitmap:id:		putBitmap:id:)
		(14	UTF8					getBytes:id:			putBytes:id:)
	"12-19 reserved for additional non-pointer objects"
		(20	Array					getArray:id:			putArray:id:)
		(21	OrderedCollection		getCollection:id:		putCollection:id:)
		(22	Set						getCollection:id:		putCollection:id:)
		(23	IdentitySet				getCollection:id:		putCollection:id:)
		(24	Dictionary				getDict:id:			putDict:id:)
		(25	IdentityDictionary		getDict:id:			putDict:id:)
	"26-29 reserved for additional collections"
		(30	Color					getColor:id:			putColor:id:)
		(31	TranslucentColor		getColor:id:			putColor:id:)
		(32	Point					getPoint:id:			putPoint:id:)
		(33	Rectangle				getRect:id:			putRect:id:)
		(34	Form					getForm:id:			putForm:id:)
		(35	ColorForm				getForm:id:			putForm:id:)
	"99 reserved for object references"
	"100-255 reserved for user-defined classes"
	)
! !

!ObjStream class methodsFor: 'class initialization' stamp: 'jm 9/28/2003 15:39'!
initialize
	"self initialize"

	ObjectReferenceID _ 99.
	IDToClassEntry _ Dictionary new.
	NameToClassEntry _ Dictionary new.

	self fixedFormatClasses do: [:entry |
		(IDToClassEntry includesKey: entry first) ifTrue: [self error: 'duplicate fixed class ID'].
		IDToClassEntry at: entry first put: entry.
		NameToClassEntry at: entry second put: entry].

	self userClasses do: [:pair |
		entry _ pair, #(unused putUserObj:id:).
		(IDToClassEntry includesKey: entry first) ifTrue: [self error: 'duplicate user class ID'].
		IDToClassEntry at: entry first put: entry.
		NameToClassEntry at: entry second put: entry].

	FloatClassID _ (NameToClassEntry at: #Float) first.
	FirstPointerClassID _ (NameToClassEntry at: #Array) first.
! !

!ObjStream class methodsFor: 'class initialization' stamp: 'jens 7/7/2010 02:16'!
userClasses
	"Answer an array of (<class id>, <class name>) records for all version numbered user classes."
	"The following finds obsolete user classes:"
	"self initialize. self userClasses reject: [:rec | Smalltalk includesKey: rec second]"

	^ #(
		"id		class"
		(100		Morph)
		(101		BorderedMorph)
		(102		RectangleMorph)
		(103		EllipseMorph)
		(104		AlignmentMorph)
		(105		StringMorph)
		(106		UpdatingStringMorph)
		(107		SimpleSliderMorph)
		(108		SimpleButtonMorph)
		(109		SampledSound)
		(110		ImageMorph)
		(111		SketchMorph)

		"(120	SpriteMorph)"
		"(121		SoundMorph)"
		"(122	ImageBoxMorph)"
		(123		SensorBoardMorph)
		(124		ScratchSpriteMorph)
		(125		ScratchStageMorph)

		(140		ChoiceArgMorph)
		(141		ColorArgMorph)
		(142		ExpressionArgMorph)
		"(143	ParameterReferenceMorph)"
		"(144	PositionArgMorph)"
		(145		SpriteArgMorph)
		"(146	VariableArgMorph)"
		(147		BlockMorph)
		(148		CommandBlockMorph)
		(149		CBlockMorph)
		"(150	MethodCallBlockMorph)"
		(151		HatBlockMorph)
		"(152	ScratchButtonMorph)"
		(153		ScratchScriptsMorph)
		(154		ScratchSliderMorph)
		(155		WatcherMorph)
		"(156	ParameterMorph)"
		(157		SetterBlockMorph)
		(158		EventHatMorph)
		"(159	EventArgMorph)"
		(160		VariableBlockMorph)
		"(161		IACTHatBlock)"
		(162		ImageMedia)
		(163		MovieMedia)
		(164		SoundMedia)
		(165		KeyEventHatMorph)
		(166		BooleanArgMorph)
		(167		EventTitleMorph)
		(168		MouseClickEventHatMorph)
		(169		ExpressionArgMorphWithMenu)
		(170		ReporterBlockMorph)
		(171		MultilineStringMorph)
		(172		ToggleButton)
		(173		WatcherReadoutFrameMorph)
		(174		WatcherSliderMorph)
		(175		ScratchListMorph)
		(176		ScrollingStringMorph)

		(180		ScrollFrameMorph2)
		(181		ListMultilineStringMorph)
		(182		ScratchScrollBar)

		(200		CustomCommandBlockMorph)
		(201		CustomBlockDefinition)
		(202		CommandScriptBlockMorph)
		(203		ReporterScriptBlockMorph)
		(204		ListMakerBlockMorph)
		(205		VariableFrame)
		(206		CustomReporterBlockMorph)

		(207		CReporterSlotMorph)

		(300		StringFieldMorph)
		(301		MultiArgReporterBlockMorph)

	)

! !


!ObjStream class methodsFor: 'testing' stamp: 'jm 9/24/2003 12:19'!
equalityTest: inObj
	"For testing. Serialize and deserialize the given object and compare the result for equality with the original object."

	| outObj |
	outObj _ self serializeAndDeserialize: inObj.
	outObj class == inObj class ifFalse: [self error: 'output class is not equal to input class'].
	outObj = inObj ifFalse: [self error: 'output is not equal to input'].
! !

!ObjStream class methodsFor: 'testing' stamp: 'jm 6/12/2008 09:42'!
fixedFormatClassTests
	"Test conversions for fixed-format objects."
	"self initialize; fixedFormatClassTests"

	| shared |
	self equalityTest: #().
	self equalityTest: #(1 2 3).
	self equalityTest: (Array with: nil with: true with: false).
	self equalityTest: #(123 -123 123456 -123456 123456789000 -123456789000 3.14159).
	self equalityTest: 'hello'.
	self equalityTest: 'hello' asSymbol.
	self equalityTest: #(1 2 3) asByteArray.
	self equalityTest: (UTF8 withAll: 'hello').

	self equalityTest: (SoundBuffer fromArray: #(1 2 3 4)).
	self equalityTest: (Bitmap withAll: #(0 1 2 2147483647 2147483648 4294967295)).

	self equalityTest: #(1 2 3) asOrderedCollection.
	self equalityTest: #(1 2 3) asSet.
	self equalityTest: (IdentitySet new addAll: #(1 2 3); yourself).
	self equalityTest: (Dictionary new at: 1 put: 'a'; at: 'b' put: 2; yourself).
	self equalityTest: (IdentityDictionary new at: 1 put: 'a'; at: 'b' put: 2; yourself).

	self equalityTest: (Color gray: 0.3).
	self equalityTest: (Color red alpha: 0.5).
	self equalityTest: 2 @ 3.14159.
	self equalityTest: (0@0 extent: 2.5).
	self formEqualityTest: (Form fromDisplay: (0@0 extent: 10)).
	self formEqualityTest: ((Form fromDisplay: (0@0 extent: 10)) colorReduced).

	shared _ #Shared.
	self equalityTest: (Point x: shared y: shared).
	self equalityTest: ((Point x: shared y: shared) corner: (Point x: shared y: shared)).
	self equalityTest: (OrderedCollection with: shared with: shared).
	self equalityTest: (Array with: shared with: (Set new add: shared; yourself)).
	self equalityTest: (Dictionary new at: shared put: shared; at: 'b' put: shared; yourself).
	self equalityTest: (IdentityDictionary new at: shared put: shared; at: 'b' put: shared; yourself).

	self inform: 'Fixed-format tests passed.'.
! !

!ObjStream class methodsFor: 'testing' stamp: 'jm 9/28/2003 12:42'!
formEqualityTest: inForm
	"For testing. Serialize and deserialize the given form and compare the result for equality with the original."

	| outForm |
	outForm _ self serializeAndDeserialize: inForm.
	outForm class == inForm class ifFalse: [self error: 'output class is not equal to input class'].
	((outForm extent = inForm extent) &
	 (outForm depth = inForm depth) &
	 (outForm bits = inForm bits) &
	 (outForm offset = inForm offset))
		 ifFalse: [self error: 'output Form is not equal to input Form'].
	(inForm isKindOf: ColorForm) ifTrue: [
		inForm colors = outForm colors
			ifFalse: [self error: 'output colors are not equal to input colors']].
! !

!ObjStream class methodsFor: 'testing' stamp: 'jens 6/13/2009 22:35'!
scratchFileVersionFrom: aString
	"Answer the Scratch file version number from the given string. If the string is of the form: 'ScratchVxx', were xx is a two-digit integer, answer the value of xx. Otherwise, answer 0."
	"self scratchFileVersionFrom: 'ScratchV01'"

	"changed for the BYOB-prototype -Jens"

	(aString beginsWith: 'BloxExpV') 
		ifTrue: [ScriptableScratchMorph decodeAsByob]
		ifFalse: [ScriptableScratchMorph decodeAsScratch].

	((aString beginsWith: 'BloxExpV') 
		or: [aString beginsWith: 'ScratchV']) ifFalse: [^ 0].
	^ (aString copyFrom: 9 to: aString size) asNumberNoError
! !

!ObjStream class methodsFor: 'testing' stamp: 'jm 7/30/2008 17:19'!
scratchObjectsFrom: aFileName
	"Read a Scratch project from the file with the given name and answer the objects array."

	| f version objects |
	f _ (FileStream readOnlyFileNamed: aFileName) binary.
	version _ self scratchFileVersionFrom: (f next: 10) asString.
	version = 0 ifTrue: [
		f position: 0.
		objects _ ObjStream new readObjFrom: f].
	(version = 1) | (version = 2) ifTrue: [
		f skip: f uint32.  "skip header"
		objects _ ObjStream new readObjsFrom: f].
	f close.
	^ objects
! !

!ObjStream class methodsFor: 'testing' stamp: 'jm 12/3/2003 07:14'!
serializeAndDeserialize: anObject
	"For testing. Serialize and de-serialize the given object and answer the result."

	| stream |
	stream _ WriteStream on: ByteArray new.
	ObjStream new storeObj: anObject on: stream showProgress: false.
	^ ObjStream new readObjFrom: (ReadStream on: stream contents)
! !

!ObjStream class methodsFor: 'testing' stamp: 'JM 11/17/2011 11:51'!
tallyScratchObjectsFrom: aDirectory
	"Tally the object class ID's for all Scratch projects in the given directory into the given array."
	"self tallyScratchObjectsFrom: FileDirectory default"

	| classIDCounts objTable id result count cName |
	classIDCounts _ Array new: 256 withAll: 0.
	aDirectory fileNames do: [:fn |
		((fn endsWith: '.sb') | (fn endsWith: '.ypr') | (fn endsWith: '.srb')) ifTrue: [
			objTable _ self scratchObjectsFrom: (aDirectory fullNameFor: fn).
			objTable do: [:entry |
				id _ entry at: 2.
				classIDCounts at: id put: (classIDCounts at: id) + 1]]].

	result _ WriteStream on: String new.
	1 to: classIDCounts size do: [:i |
		count _ classIDCounts at: i.
		count > 0 ifTrue: [
			cName _ (IDToClassEntry at: i) at: 2.
			result nextPutAll: cName, '	', count printString; cr]].
	^ result contents
! !

!ObjStream class methodsFor: 'testing' stamp: 'jm 12/15/2006 10:50'!
tallyScratchObjectsFromFile: aFileName
	"Read the Scratch project from the file with the given name and tally it's object class IDs."

	| classIDCounts objTable id result count cName |
	classIDCounts _ Array new: 256 withAll: 0.
	objTable _ self scratchObjectsFrom: aFileName.
	objTable do: [:entry |
		id _ entry at: 2.
		classIDCounts at: id put: (classIDCounts at: id) + 1].

	result _ WriteStream on: String new.
	1 to: classIDCounts size do: [:i |
		count _ classIDCounts at: i.
		count > 0 ifTrue: [
			cName _ (IDToClassEntry at: i) at: 2.
			result nextPutAll: cName, '	', count printString; cr]].
	^ result contents

! !

!ObjStream class methodsFor: 'testing' stamp: 'jm 8/21/2006 14:24'!
userClassTests
	"Test conversions for fixed-format objects."
	"self initialize; userClassTests"

	| userClassList suspectClasses |
	userClassList _ self userClasses collect: [:rec | Smalltalk at: rec second].
	userClassList _ userClassList reject: [:cl | (cl inheritsFrom: BlockMorph) | (cl inheritsFrom: ArgMorph)].
	userClassList do: [:cl | self serializeAndDeserialize: cl new].

	suspectClasses _ userClassList select: [:cl |
		(cl includesSelector: #fieldsVersion) not and: [cl instVarNames size > 0]].
	suspectClasses size > 0 ifTrue: [^ self error: 'not all classes implement #fieldsVersion'].

	self inform: 'User class tests passed.'.

! !

!ObjStream class methodsFor: 'testing' stamp: 'jm 8/29/2006 11:28'!
writeTestFile
	"self writeTestFile"

	| all objects s |
	all _ OrderedCollection new.
	all add: true.
	all add: false.
	all add: 12345.
	all add: 123.
	all add: 123456789123456789.
	all add: -123456789123456789.
	all add: 123.546.
	all add: 'This is a string.'.
	all add: #thisIsASymbol.
	all add: #(100 101 102 253 254 255) asByteArray.
	all add: ScriptableScratchMorph popSound samples.
	all add: (ImageMorph defaultForm asFormOfDepth: 32) bits.
	all add: (Array with: 1 with: 2 with: 3).
	all add: (Array with: 1 with: 2 with: 3) asOrderedCollection.
	all add: (Array with: 1 with: 2 with: 3) asSet.
	all add: (IdentitySet withAll: (Array with: 1 with: 2 with: 3)).
	all add: (Dictionary new at: 'John' put: 'Maloney'; at: 'Lise' put: 'Kreps'; yourself).
	all add: (IdentityDictionary new at: #John put: 'Maloney'; at: #Lise put: 'Kreps'; yourself).
	all add: (Color gray: 0.5).
	all add: (Color red alpha: 0.5).
	all add: 1@2.0.
	all add: (9.5@20 extent: 30@40).
	all add: (ImageMorph defaultForm asFormOfDepth: 32).
	all add: ImageMorph defaultForm.

	objects _ (Array with: nil), all asArray.
	s _ (FileStream newFileNamed: 'test.obj') binary.
	self new storeObj: objects on: s.
	s close.
! !


ObjStream initialize!
