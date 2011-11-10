ReadWriteStream subclass: #FileStream
	instanceVariableNames: 'rwmode '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Files'!
!FileStream commentStamp: '<historical>' prior: 0!
I represent a Stream that accesses a FilePage from a File. One use for my instance is to access larger "virtual Strings" than can be stored contiguously in main memory. I restrict the objects stored and retrieved to be Integers or Characters. An end of file pointer terminates reading; it can be extended by writing past it, or the file can be explicitly truncated.
	
To use the file system for most applications, you typically create a FileStream. This is done by sending a message to a FileDirectory (file:, oldFile:, newFile:, rename:newName:) which creates an instance of me. Accesses to the file are then done via my instance.

*** An existing file cannot be shortened!! ***  To overwrite a file with a shorter one, first delete the old file ((deleteFileNamed:, then write your new, shorter version.
!


!FileStream methodsFor: 'accessing'!
contentsOfEntireFile
	"Read all of the contents of the receiver."

	| s binary |
	self readOnly.
	binary _ self isBinary.
	self reset.	"erases knowledge of whether it is binary"
	binary ifTrue: [self binary].
	s _ self next: self size.
	self close.
	^s! !

!FileStream methodsFor: 'accessing'!
next

	(position >= readLimit and: [self atEnd])
		ifTrue: [^nil]
		ifFalse: [^collection at: (position _ position + 1)]! !

!FileStream methodsFor: 'accessing'!
next: anInteger

	| newCollection howManyRead increment |
	newCollection _ collection species new: anInteger.
	howManyRead _ 0.
	[howManyRead < anInteger] whileTrue:
		[self atEnd ifTrue:
			[(howManyRead + 1) to: anInteger do: [:i | newCollection at: i put: (self next)].
			^newCollection].
		increment _ (readLimit - position) min: (anInteger - howManyRead).
		newCollection replaceFrom: (howManyRead + 1)
			to: (howManyRead _ howManyRead + increment)
			with: collection
			startingAt: (position + 1).
		position _ position + increment].
	^newCollection! !

!FileStream methodsFor: 'accessing'!
nextPut: aByte
	"1/31/96 sw: subclassResponsibility"

	self subclassResponsibility! !

!FileStream methodsFor: 'accessing'!
nextPutAll: aCollection
	"1/31/96 sw: made subclass responsibility"

	self subclassResponsibility! !

!FileStream methodsFor: 'accessing'!
size
	"Answer the size of the file in characters.
	 1/31/96 sw: made subclass responsibility"

	self subclassResponsibility! !


!FileStream methodsFor: 'testing'!
atEnd
	"Answer true if the current position is >= the end of file position.
	 1/31/96 sw: subclassResponsibility"

	self subclassResponsibility! !


!FileStream methodsFor: 'positioning'!
position
	"Answer the current character position in the file.
	 1/31/96 sw: subclassResponsibility"

	self subclassResponsibility! !

!FileStream methodsFor: 'positioning'!
position: pos
	"Set the current character position in the file to pos.
	 1/31/96 sw: made subclassResponsibility"

	self subclassResponsibility! !

!FileStream methodsFor: 'positioning'!
reset
	"Set the current character position to the beginning of the file.
	 1/31/96 sw: subclassResponsibility"

	self subclassResponsibility! !

!FileStream methodsFor: 'positioning'!
setToEnd
	"Set the current character position to the end of the File. The same as
	self position: self size.  1/31/96 sw: made subclassResponsibility"

	self subclassResponsibility! !

!FileStream methodsFor: 'positioning'!
skip: n
	"Set the character position to n characters from the current position.
	Error if not enough characters left in the file
	1/31/96 sw: made subclassResponsibility."
 
	self subclassResponsibility! !


!FileStream methodsFor: 'printing'!
printOn: aStream

	super printOn: aStream.
	aStream nextPutAll: ' on '.
	self file printOn: aStream! !


!FileStream methodsFor: 'editing' stamp: 'di 5/20/1998 23:20'!
edit
	"Create and schedule an editor on this file."

	FileList openEditorOn: self editString: nil.
! !


!FileStream methodsFor: 'file open/close' stamp: 'jm 9/21/1998 13:02'!
close
	"Close this file."

	self subclassResponsibility
! !

!FileStream methodsFor: 'file open/close' stamp: 'jm 9/21/1998 13:02'!
closed
	"Answer true if this file is closed."

	self subclassResponsibility
! !

!FileStream methodsFor: 'file open/close' stamp: 'jm 9/21/1998 13:03'!
flush
	"When writing, flush the current buffer out to disk."

	self subclassResponsibility
! !

!FileStream methodsFor: 'file open/close' stamp: 'jm 9/21/1998 13:04'!
reopen
	"Ensure that the receiver is open, re-open it if necessary."
	"Details: Files that were open when a snapshot occurs are no longer valid when the snapshot is resumed. This operation re-opens the file if that has happened."

	self subclassResponsibility
! !


!FileStream methodsFor: 'file modes' stamp: 'jm 9/21/1998 13:01'!
ascii
	"Set this file to ascii (text) mode."

	self subclassResponsibility
! !

!FileStream methodsFor: 'file modes' stamp: 'jm 9/21/1998 12:59'!
binary
	"Set this file to binary mode."

	self subclassResponsibility
! !

!FileStream methodsFor: 'file modes' stamp: 'jm 9/21/1998 12:59'!
readOnly
	"Set this file's mode to read-only."

	self subclassResponsibility
! !

!FileStream methodsFor: 'file modes' stamp: 'jm 9/21/1998 13:01'!
text
	"Set this file to text (ascii) mode."

	self ascii.
! !


!FileStream methodsFor: 'file accessing'!
file
	"Answer the file for the page the receiver is streaming over.
	 1/31/96 sw: made subclass responsibility"

	self subclassResponsibility! !

!FileStream methodsFor: 'file accessing' stamp: 'jm 12/5/97 12:53'!
localName

	^ FileDirectory localNameFor: self name
! !

!FileStream methodsFor: 'file accessing'!
name
	"Answer the name of the file for the page the receiver is streaming over.  1/31/96 sw: made subclassResponsibility"

	self subclassResponsibility! !


!FileStream methodsFor: 'fileIn/Out' stamp: 'sw 11/19/1998 16:42'!
fileIn
	"Guarantee that the receiver is readOnly before fileIn for efficiency and
	to eliminate remote sharing conflicts."

	self readOnly.
	self fileInAnnouncing: 'Loading ', self localName! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FileStream class
	instanceVariableNames: ''!

!FileStream class methodsFor: 'instance creation' stamp: 'jm 12/6/2005 14:48'!
droppedFiles
	"Poll for a dropped file event. If there is such an event, answer an array containing the drop point followed by one or more FileStream's for the dropped files. Otherwise, answer the empty array."
	"Note: File dropping does not work on versions of the Squeak VM before the DropPlugin and event primitive. This method can still be called, but it will always answer an empty array."

	| p result i f |
	"check for a file drop event?"
	p _ Sensor fileDropPoint.
	p ifNil: [^ #()].  "no file drop event"

	"get streams on all dropped files"
	result _ OrderedCollection with: p.
	i _ 1.
	[(f _ StandardFileStream new requestDropStream: i) notNil] whileTrue: [
		result addLast: f.
		i _ i + 1].

	^ result asArray
! !

!FileStream class methodsFor: 'instance creation'!
fileNamed: fileName 
	^ self concreteStream fileNamed: (self fullName: fileName)! !

!FileStream class methodsFor: 'instance creation'!
fullName: fileName
	^ FileDirectory default fullNameFor: fileName! !

!FileStream class methodsFor: 'instance creation' stamp: 'TPR 8/26/1999 10:49'!
isAFileNamed: fName
	"return whether a file exists with the given name"
	^self concreteStream isAFileNamed: (self fullName: fName)! !

!FileStream class methodsFor: 'instance creation' stamp: 'di 2/15/98 14:03'!
new
	^ self basicNew! !

!FileStream class methodsFor: 'instance creation'!
newFileNamed: fileName 
	^ self concreteStream newFileNamed: (self fullName: fileName)! !

!FileStream class methodsFor: 'instance creation'!
oldFileNamed: fileName 
	^ self concreteStream oldFileNamed: (self fullName: fileName)! !

!FileStream class methodsFor: 'instance creation' stamp: 'jm 5/8/1998 21:53'!
oldFileOrNoneNamed: fileName
	"If the file exists, answer a read-only FileStream on it. If it doesn't, answer nil."

	| fullName |
	fullName _ self fullName: fileName.
	(self concreteStream isAFileNamed: fullName)
		ifTrue: [^ self concreteStream readOnlyFileNamed: fullName]
		ifFalse: [^ nil].
! !

!FileStream class methodsFor: 'instance creation'!
readOnlyFileNamed: fileName 
	^ self concreteStream readOnlyFileNamed: (self fullName: fileName)! !

!FileStream class methodsFor: 'instance creation' stamp: 'jm 11/8/2007 11:03'!
readOnlyFileNamedOrNil: fileName
	"Attempt to open the file with the given name read-only. If the file does not exist, return nil."

	^ self concreteStream new open: (self fullName: fileName) forWrite: false
! !


!FileStream class methodsFor: 'concrete classes' stamp: 'ls 7/11/1998 02:58'!
concreteStream
	"Who should we really direct class queries to?  "
	^ StandardFileStream  "may change this to CrLfFileStream"! !


!FileStream class methodsFor: 'as yet unclassified' stamp: 'JM 11/10/2011 12:13'!
fileIn: fullName
	"File in the entire contents of the file specified by the name provided"

	(self readOnlyFileNamed: fullName) fileIn; close.! !
