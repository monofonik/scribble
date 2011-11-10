Object subclass: #FileDirectory
	instanceVariableNames: 'pathName '
	classVariableNames: 'DefaultDirectory DirectoryClass '
	poolDictionaries: ''
	category: 'System-Files'!
!FileDirectory commentStamp: '<historical>' prior: 0!
A FileDirectory represents a folder or directory in the underlying platform's file system. It carries a fully-qualified path name for the directory it represents, and can enumerate the files and directories within that directory.

A FileDirectory can be thought of as a Dictionary whose keys are the local names of files in that directory, and whose values are directory "entries". Each entry is an array of five items:

	<name> <creationTime> <modificationTime> <dirFlag> <fileSize>

The times are given in seconds, and can be converted to a time and date via Time>dateAndTimeFromSeconds:. See the comment in lookupEntry:... which provides primitive access to this information.
!


!FileDirectory methodsFor: 'path access' stamp: 'tk 5/18/1998 22:29'!
on: fullPath
	"Return another instance"

	^ self class on: fullPath! !

!FileDirectory methodsFor: 'path access' stamp: 'jm 12/5/97 12:18'!
pathName
	"Return the path from the root of the file system to this directory."

	^ pathName
! !

!FileDirectory methodsFor: 'path access' stamp: 'jm 12/5/97 12:19'!
pathNameDelimiter
	"Return the delimiter character for this kind of directory. This depends on the current platform."

	^ self class pathNameDelimiter
! !

!FileDirectory methodsFor: 'path access' stamp: 'jm 12/5/97 12:17'!
pathParts
	"Return the path from the root of the file system to this directory as an array of directory names."

	^ pathName findTokens: self pathNameDelimiter asString
! !

!FileDirectory methodsFor: 'path access' stamp: 'ar 12/18/1999 00:36'!
slash
	^self class slash! !


!FileDirectory methodsFor: 'file stream creation' stamp: 'tk 5/19/1998 09:03'!
fileNamed: localFileName
	"Open the file with the given name in this directory for writing."

	^ FileStream concreteStream fileNamed: (self fullNameFor: localFileName)
! !

!FileDirectory methodsFor: 'file stream creation' stamp: 'tk 5/19/1998 09:03'!
newFileNamed: localFileName
	"Create a new file with the given name in this directory."

	^ FileStream concreteStream newFileNamed: (self fullNameFor: localFileName)
! !

!FileDirectory methodsFor: 'file stream creation' stamp: 'tk 5/19/1998 09:03'!
oldFileNamed: localFileName
	"Open the existing file with the given name in this directory."

	^ FileStream concreteStream oldFileNamed: (self fullNameFor: localFileName)
! !

!FileDirectory methodsFor: 'file stream creation' stamp: 'tk 5/18/1998 16:19'!
oldFileOrNoneNamed: fileName
	"If the file exists, answer a read-only FileStream on it. If it doesn't, answer nil."

	| fullName |
	fullName _ FileStream fullName: fileName.
	(FileStream concreteStream isAFileNamed: fullName)
		ifTrue: [^ FileStream concreteStream readOnlyFileNamed: fullName]
		ifFalse: [^ nil].
! !

!FileDirectory methodsFor: 'file stream creation' stamp: 'tk 5/19/1998 09:03'!
readOnlyFileNamed: localFileName
	"Open the existing file with the given name in this directory for read-only access."

	^ FileStream concreteStream readOnlyFileNamed: (self fullNameFor: localFileName)
! !


!FileDirectory methodsFor: 'enumeration' stamp: 'jm 12/4/2003 12:51'!
allFileNamesDo: aBlock
	"Evaluate the given block with the full file name of every file in this entire directory tree. Answer an array with the total number of directories and files visited."

	| dirs files todo p fullName |
	dirs _ files _ 0.
	todo _ OrderedCollection with: pathName.
	[todo isEmpty] whileFalse: [
		p _ todo removeFirst.
		(self directoryEntriesFor: p) do: [:entry |
			fullName _ p, self pathNameDelimiter asString, entry name.
			entry isDirectory
				ifTrue: [
					todo addLast: fullName.
					dirs _ dirs + 1]
				ifFalse: [
					aBlock value: fullName.
					files _ files + 1]]].

	^ Array with: dirs with: files
! !

!FileDirectory methodsFor: 'enumeration' stamp: 'jm 12/5/97 15:46'!
directoryNamed: localFileName
	"Return the subdirectory of this directory with the given name."

	^ FileDirectory on: (self fullNameFor: localFileName)
! !

!FileDirectory methodsFor: 'enumeration' stamp: 'jm 11/18/2003 09:13'!
directoryNames
	"Return a collection of names for the subdirectories of this directory."
	"FileDirectory default directoryNames"

	^ (self entries select: [:entry | entry isDirectory])
		collect: [:entry | entry name]
! !

!FileDirectory methodsFor: 'enumeration' stamp: 'jm 11/18/2003 09:49'!
entries
	"Answer an array of DirectoryEntry objects for the files and directories in this directory."
	"FileDirectory default entries"

	^ self directoryEntriesFor: pathName
! !

!FileDirectory methodsFor: 'enumeration' stamp: 'jm 11/18/2003 09:13'!
fileAndDirectoryNames
	"FileDirectory default fileAndDirectoryNames"

	^ self entries collect: [:entry | entry name]
! !

!FileDirectory methodsFor: 'enumeration' stamp: 'jm 11/18/2003 09:14'!
fileNames
	"Return a collection of names for the files (but not directories) in this directory."
	"FileDirectory default fileNames"

	^ (self entries select: [:entry | entry isDirectory not])
		collect: [:entry | entry name]
! !

!FileDirectory methodsFor: 'enumeration' stamp: 'jm 12/5/97 15:39'!
keysDo: nameBlock
	"Evaluate the given block for each file or directory name in this directory."

	^ self fileAndDirectoryNames do: nameBlock
! !

!FileDirectory methodsFor: 'enumeration' stamp: 'jm 3/5/2005 20:46'!
parentDirectory
	"Answer the directory containing this directory."

	^ FileDirectory on: (FileDirectory dirPathFor: pathName)
! !

!FileDirectory methodsFor: 'enumeration' stamp: 'jm 11/18/2003 10:08'!
statsForDirectoryTree: rootedPathName
	"Return the size statistics for the entire directory tree starting at the given root. The result is a three element array of the form: (<number of folders><number of files><total bytes in all files>). This method also serves as an example of how recursively enumerate a directory tree."
	"Note: The total file bytes does not include the storage space required for the directories in the tree."
	"FileDirectory default statsForDirectoryTree: FileDirectory default pathName"

	| dirs files bytes todo p |
	Cursor wait showWhile: [
		dirs _ files _ bytes _ 0.
		todo _ OrderedCollection with: rootedPathName.
		[todo isEmpty] whileFalse: [
			p _ todo removeFirst.
			(self directoryEntriesFor: p) do: [:entry |
				entry isDirectory
					ifTrue: [
						todo addLast: (p, self pathNameDelimiter asString, entry name).
						dirs _ dirs + 1]
					ifFalse: [
						bytes _ bytes + entry fileSize.
						files _ files + 1]]]].

	^ Array with: dirs with: files with: bytes
! !


!FileDirectory methodsFor: 'testing' stamp: 'di 11/21/1999 20:16'!
directoryExists: filenameOrPath
	"Answer true if a directory of the given name exists. The given name may be either a full path name or a local directory within this directory."
	"FileDirectory default directoryExists: FileDirectory default pathName"

	| fName dir |
	FileDirectory splitName: filenameOrPath to:
		[:filePath :name |
			fName _ name.
			filePath isEmpty
				ifTrue: [dir _ self]
				ifFalse: [dir _ FileDirectory on: filePath]].

	self isCaseSensitive 
		ifTrue:[^dir directoryNames includes: fName]
		ifFalse:[^dir directoryNames anySatisfy: [:name| name sameAs: fName]].
! !

!FileDirectory methodsFor: 'testing' stamp: 'jm 8/26/2008 09:45'!
fileExists: filenameOrPath
	"Answer true if a file of the given name exists. The given name may be either a full path name or a local file within this directory."
	"FileDirectory default fileExists: Smalltalk sourcesName"

	| fName dir |
	FileDirectory splitName: filenameOrPath to: [:filePath :name |
		fName _ name.
		filePath isEmpty
			ifTrue: [dir _ self]
			ifFalse: [dir _ FileDirectory on: filePath]].

	fName isUnicode ifTrue: [fName _ String withAll: fName asUTF8].
	self isCaseSensitive 
		ifTrue: [^ dir fileNames includes: fName]
		ifFalse: [^ dir fileNames anySatisfy: [:name| name sameAs: fName]].	! !

!FileDirectory methodsFor: 'testing' stamp: 'di 11/21/1999 20:17'!
includesKey: localName
	"Answer true if this directory includes a file or directory of the given name. Note that the name should be a local file name, in contrast with fileExists:, which takes either local or full-qualified file names."
	"(FileDirectory on: Smalltalk vmPath) includesKey: 'SqueakV2.sources'"
	self isCaseSensitive
		ifTrue:[^ self fileAndDirectoryNames includes: localName]
		ifFalse:[^ self fileAndDirectoryNames anySatisfy: [:str| str sameAs: localName]].! !

!FileDirectory methodsFor: 'testing' stamp: 'ar 5/1/1999 01:51'!
isCaseSensitive
	"Return true if file names are treated case sensitive"
	^self class isCaseSensitive! !


!FileDirectory methodsFor: 'file operations' stamp: 'wod 11/5/1998 18:41'!
copyFileNamed: fileName1 toFileNamed: fileName2
	"Copy the contents of the existing file with the first name into a new file with the second name. Both files are assumed to be in this directory."
	"FileDirectory default copyFileNamed: 'todo.txt' toFileNamed: 'todocopy.txt'"

	| file1 file2 buffer |
	file1 _ (self readOnlyFileNamed: fileName1) binary.
	file2 _ (self newFileNamed: fileName2) binary.
	buffer _ String new: 50000.
	[file1 atEnd] whileFalse:
		[file2 nextPutAll: (file1 nextInto: buffer)].
	file1 close.
	file2 close.
! !

!FileDirectory methodsFor: 'file operations' stamp: 'jm 12/4/97 22:55'!
createDirectory: localFileName
	"Create a directory with the given name in this directory. Fail if the name is bad or if a file or directory with that name already exists."

 	self primCreateDirectory: (self fullNameFor: localFileName).
! !

!FileDirectory methodsFor: 'file operations' stamp: 'jm 4/9/1999 18:02'!
deleteDirectory: localDirName
	"Delete the directory with the given name in this directory. Fail if the path is bad or if a directory by that name does not exist."

 	self primDeleteDirectory: (self fullNameFor: localDirName).
! !

!FileDirectory methodsFor: 'file operations' stamp: 'jm 12/5/97 16:33'!
deleteFileNamed: localFileName
	"Delete the file with the given name in this directory."

	self deleteFileNamed: localFileName ifAbsent: [].
! !

!FileDirectory methodsFor: 'file operations' stamp: 'ar 3/21/98 18:08'!
deleteFileNamed: localFileName ifAbsent: failBlock
	"Delete the file of the given name if it exists, else evaluate failBlock.
	If the first deletion attempt fails do a GC to force finalization of any lost references. ar 3/21/98 17:53"
	(self 
		retryWithGC:[self primDeleteFileNamed: (self fullNameFor: localFileName)]
		until:[:result| result notNil]) == nil
			ifTrue: [^failBlock value].
! !

!FileDirectory methodsFor: 'file operations' stamp: 'tk 3/31/2000 21:09'!
rename: oldFileName toBe: newFileName
	| selection |
	"Rename the file of the given name to the new name. Fail if there is no file of the old name or if there is an existing file with the new name."
	"Modified for retry after GC ar 3/21/98 18:09"

	(self retryWithGC:[self primRename: (self fullNameFor: oldFileName)
						to: (self fullNameFor: newFileName)]
		until:[:result| result notNil]) ~~ nil ifTrue:[^self].
	(self fileExists: oldFileName) ifFalse:[
		^self error:'Attempt to rename a non-existent file'.
	].
	(self fileExists: newFileName) ifTrue:[
		selection _ (PopUpMenu labels:
'delete old version
cancel')
				startUpWithCaption: 'Trying to rename a file to be
', newFileName , '
and it already exists.'.
		selection = 1 ifTrue:
			[self deleteFileNamed: newFileName.
			^ self rename: oldFileName toBe: newFileName]].
	^self error:'Failed to rename file'.! !

!FileDirectory methodsFor: 'file operations' stamp: 'jm 3/27/98 06:40'!
setMacFileNamed: fileName type: typeString creator: creatorString
	"Set the Macintosh file type and creator info for the file with the given name. Fails if the file does not exist or if the type and creator type arguments are not strings of length 4. Does nothing on other platforms (where the underlying primitive is a noop)."
	"FileDirectory default setMacFileNamed: 'foo' type: 'TEXT' creator: 'ttxt'"

 	self primSetMacFileNamed: (self fullNameFor: fileName)
		type: typeString
		creator: creatorString.
! !


!FileDirectory methodsFor: 'version control' stamp: 'JM 11/10/2011 12:13'!
fileInContents
	"Given a directory with files named like '1-Object.st', files in all .st files in numerical order"

	| filesToFileIn filesInOrder index |

	"Grab the names of all files that look like they can be filed in"
	filesToFileIn _ self fileNamesMatching: '*.st'.

	"File in classes based in the order corresponding to the number in front of the file name
	(so that base classes are filed in before subclasses)"

	filesInOrder _ filesToFileIn asSortedCollection sortBlock: [:a :b | a asNumber < b asNumber].

	index _ 1.
	'Importing source code ...' 
		displayProgressAt: Sensor cursorPoint 
		from: 1 to: filesInOrder size
		during: [:bar |
			filesInOrder do: [:name | 
				CrLfFileStream fileIn: (self fullNameFor: name). 
				bar value: index.
				index _ index + 1]].



! !

!FileDirectory methodsFor: 'version control' stamp: 'JM 11/9/2011 17:15'!
fileOutClassesChangedSince: aDate

	"Goes through all classes to find ones that have changed since a given date, and files those out within the directory.  Filenames are prepended with a number representing the depth in the class heirarchy, so that they can be filed in in the correct order by 'fileInContents'"

	| allClasses classesToExport reallyOldDate index |

	reallyOldDate _ '01/01/78' asDate.

	"Get a list of all classes (but not metaclasses)"
	allClasses _ Object selectSubclasses: [ :aClass | (aClass isMeta) not ].

	"Prune the list to only those that have changed since the given date"
	index _ 1.
	'Searching for modified classes...' 
		displayProgressAt: Sensor cursorPoint
		from: 1 to: allClasses size
		during: 
			[:bar |
				classesToExport _ allClasses 
					select: [ :aClass | 
						| latestChange |
						index _ index + 1.
						bar value: index.
						latestChange _ 
							((Utilities dateOfLatestChangeToClass: aClass) ifNil: [ reallyOldDate ])
							max:
							((Utilities dateOfLatestChangeToClass: aClass class) ifNil: [ reallyOldDate ]).
						latestChange > aDate ]].
	
	index _ 1.
	'Exporting modified classes...'
		displayProgressAt: Sensor cursorPoint
		from: 1 to: classesToExport size
		during: [:bar |
			classesToExport do: [ :aClass |
				"Files are named as follows: depth-class.st 
				(where depth is a number representing how deep 
				the class is in the class heirarchy"

				| depth filename filestream |

				depth _ aClass allSuperclasses size.
				filename _ depth asString, '-', aClass name , FileDirectory dot, 'st'.
				self deleteFileNamed: filename.		"Ensure we can overwrite the file"
				filestream _ CrLfFileStream defaultToCRLF newFileNamed: (self fullNameFor: filename).

				filestream header. "timeStamp."	"Omit the timestamp!!"
		
				aClass fileOutOn: filestream moveSource: false toFile: 0.
				filestream trailer; close. 

				index _ index + 1.
				bar value: index.]]

			

		! !


!FileDirectory methodsFor: 'file name utilities' stamp: 'jm 12/4/97 21:01'!
fileNamesMatching: pat
	"FileDirectory default fileNamesMatching: '*'"

	^ self fileNames select: [:name | pat match: name]
! !

!FileDirectory methodsFor: 'file name utilities' stamp: 'jm 3/9/2005 15:07'!
fullNameFor: fileName
	"Answer the full name (i.e. a path from the root of the file system) for the given file name. If the given name contains a delimiter character, assume it is already a full path. Otherwise, prefix it with the path from the root to this directory."
	"Details: Note that relative paths, such as '../foo' are not supported."

	| local prefix |
	self class splitName: fileName to:
		[:filePath :localName |
			local _ localName.
			filePath isEmpty
				ifTrue: [prefix _ pathName]
				ifFalse: [prefix _ filePath]].

	prefix size = 0 ifTrue: [^ local].
	prefix last = self pathNameDelimiter
		ifTrue:[^ prefix, local]
		ifFalse:[^ prefix, self pathNameDelimiter asString, local]
! !

!FileDirectory methodsFor: 'file name utilities' stamp: 'jm 11/21/2003 19:03'!
fullToRelativePath: fullPathString
	"Answer the path relative to this directory for the file or directory with the given full path. See the comment in relativeToFullPath: for a description of the relative path syntax."

	| currentPath fullPath minSize indexOfDiff result |
	currentPath _ self pathParts.
	fullPath _ fullPathString findTokens: self pathNameDelimiter asString.
	minSize _ currentPath size min: fullPath size.
	indexOfDiff _ (1 to: minSize)
		detect: [:i | (currentPath at: i) ~= (fullPath at: i)]
		ifNone: [minSize + 1].

	result _ WriteStream on: (String new: 100).
	currentPath size - (indexOfDiff - 1) timesRepeat: [result nextPutAll: '../'].
	indexOfDiff to: fullPath size do: [:i |
		result nextPutAll: (fullPath at: i), '/'].
	result position > 0 ifTrue: [result skip: -1].
	^ result contents
! !

!FileDirectory methodsFor: 'file name utilities' stamp: 'jm 3/5/2005 08:46'!
nextNameFor: baseFileName extension: extension
	"Assumes a file name includes a version number encoded as '.' followed by digits preceding the file extension. Increment the version number and answer the new file name. If a no file with the given base name is found, use version 1."

	| files splits version |
	files _ self fileNamesMatching: (baseFileName,'*', self class dot, extension).
	splits _ (files collect: [:file | self splitNameVersionExtensionFor: file])
				select: [:split | (split at: 1) = baseFileName].
	splits _ splits asSortedCollection: [:a :b | (a at: 2) < (b at: 2)].
	splits isEmpty 
		ifTrue: [version _ 1]
		ifFalse: [version _ (splits last at: 2) + 1].

	^ (baseFileName, '.', version asString, self class dot, extension)
! !

!FileDirectory methodsFor: 'file name utilities' stamp: 'jm 11/21/2003 18:13'!
relativeToFullPath: relativePath
	"Answer the full path name for the file or directory with the given path relative to this directory. The relative path is in Unix/URL format: the delimitor is a slash (/), a single period (.) means the current directory, and a double period (..) means the parent directory. A relative path is *always* begins with the current directory, so a leading './' is inferred."

	| currentPath relParts result |
	currentPath _ self pathParts.
	relParts _ relativePath findTokens: '/'.
	relParts do: [:s |
		(s = '.' or: [s = '..'])
			ifTrue: [
				s = '..' ifTrue: [
					currentPath size > 0 ifTrue: [
						currentPath _ currentPath copyFrom: 1 to: currentPath size - 1]]]
			ifFalse: [
				currentPath _ currentPath copyWith: s]].

	result _ WriteStream on: (String new: 100).
	currentPath do: [:s | result nextPutAll: s; nextPut: self pathNameDelimiter].
	result position > 0 ifTrue: [result skip: -1].
	^ result contents
! !

!FileDirectory methodsFor: 'file name utilities' stamp: 'djp 10/27/1999 08:58'!
splitNameVersionExtensionFor: fileName
	" answer an array with the root name, version # and extension.
	See comment in nextSequentialNameFor: for more details"

	| baseName version extension i j |

	baseName _ self class baseNameFor: fileName.
	extension _ self class extensionFor: fileName.
	i _ j _ baseName findLast: [:c | c isDigit not].
	i = 0
		ifTrue: [version _ 0]
		ifFalse:
			[(baseName at: i) = $.
				ifTrue:
					[version _ (baseName copyFrom: i+1 to: baseName size) asNumber.
					j _ j - 1]
				ifFalse: [version _ 0].
			baseName _ baseName copyFrom: 1 to: j].
	^ Array with: baseName with: version with: extension! !

!FileDirectory methodsFor: 'file name utilities' stamp: 'jm 12/1/2003 17:58'!
unusedNameStartingWith: prefix
	"Answer an unused file or directory name in this directory starting with the given prefix and ending with one or more digits."
	"FileDirectory default unusedNameStartingWith: 'tmp'"

	| usedNames i result |
	usedNames _ self fileAndDirectoryNames asSet.
	i _ 0.
	result _ prefix, '0'.
	[usedNames includes: result] whileTrue: [
		result _ prefix, (i _ i + 1) printString].
	^ pathName, self slash, result
! !


!FileDirectory methodsFor: 'printing' stamp: 'jm 12/4/97 19:41'!
printOn: aStream 
	"Refer to the comment in Object|printOn:."

	aStream nextPutAll: self class name.
	aStream nextPutAll: ' on '.
	pathName printOn: aStream.
! !


!FileDirectory methodsFor: 'private' stamp: 'jm 11/18/2003 09:55'!
directoryEntriesFor: fullPath
	"Answer an array of DirectoryEntry objects for the files and directories in the directory with the given path. If the given path is not a directory, answer an empty array. See primLookupEntryIn:index: for further details."
	"FileDirectory default directoryEntriesFor: ''"

	| entries index done entryArray |
	entries _ OrderedCollection new: 200.
	index _ 1.
	done _ false.
	[done] whileFalse: [
		entryArray _ self primLookupEntryIn: fullPath index: index.
		#badDirectoryPath = entryArray ifTrue: [^ #()].
		entryArray
			ifNil: [done _ true]
			ifNotNil: [entries addLast: (DirectoryEntry fromArray: entryArray)].
		index _ index + 1].

	^ entries asArray
! !

!FileDirectory methodsFor: 'private' stamp: 'jm 12/4/97 21:35'!
primCreateDirectory: fullPath
	"Create a directory named by the given path. Fail if the path is bad or if a file or directory by that name already exists."

 	<primitive: 160>
	self primitiveFailed
! !

!FileDirectory methodsFor: 'private' stamp: 'jm 4/9/1999 17:59'!
primDeleteDirectory: fullPath
	"Delete the directory named by the given path. Fail if the path is bad or if a directory by that name does not exist."

 	<primitive: 163>
	self primitiveFailed
! !

!FileDirectory methodsFor: 'private' stamp: 'jm 12/4/97 21:38'!
primDeleteFileNamed: aFileName
	"Delete the file of the given name. Return self if the primitive succeeds, nil otherwise."

	<primitive: 156>
	^ nil
! !

!FileDirectory methodsFor: 'private' stamp: 'jm 11/18/2003 09:58'!
primLookupEntryIn: fullPath index: index
	"Look up the index-th entry of the directory with the given fully-qualified path (i.e., starting from the root of the file hierarchy) and return an array containing:

	<name> <creationTime> <modificationTime> <dirFlag> <fileSize>

	The empty string enumerates the top-level directories, mounted volumes, or disk drives. (For example, on Unix, the empty path enumerates the root directory '/'. On Macs and PCs, it enumerates the mounted volumes/drives.)

	The creation and modification times are in seconds since the start of the Smalltalk time epoch. DirFlag is true if the entry is a directory. FileSize the file size in bytes or zero for directories. The primitive returns nil when index is past the end of the directory. It fails if the given path is bad."

 	<primitive: 162>
	^ #badDirectoryPath
! !

!FileDirectory methodsFor: 'private' stamp: 'ar 3/21/98 18:04'!
primRename: oldFileFullName to: newFileFullName 
	"Rename the file of the given name to the new name. Fail if there is no file of the old name or if there is an existing file with the new name.
	Changed to return nil instead of failing ar 3/21/98 18:04"

	<primitive: 159>
	^nil! !

!FileDirectory methodsFor: 'private' stamp: 'jm 12/5/97 15:22'!
primSetMacFileNamed: fileName type: typeString creator: creatorString
	"Set the Macintosh file type and creator info for the file with the given name. Fails if the file does not exist or if the type and creator type arguments are not strings of length 4. This primitive is Mac specific; it is a noop on other platforms."

 	<primitive: 169>
	self primitiveFailed
! !

!FileDirectory methodsFor: 'private' stamp: 'jm 12/4/97 22:44'!
setPathName: pathString

	pathName _ pathString.
! !


!FileDirectory methodsFor: 'searching' stamp: 'SIM 5/22/2000 13:33'!
withAllFilesDo: fileStreamBlock andDirectoriesDo: directoryBlock

	"For the receiver and all it's subdirectories evaluate directoryBlock.
	For a read only file stream on each file within the receiver 
	and it's subdirectories evaluate fileStreamBlock."

	| todo dir |

	todo _ OrderedCollection with: self.
	[todo size > 0] whileTrue: [
		dir _ todo removeFirst.
		directoryBlock value: dir.
		dir fileNames do: [: n | 
			fileStreamBlock value: 
				(FileStream readOnlyFileNamed: (dir fullNameFor: n))].
		dir directoryNames do: [: n | 
			todo add: (dir directoryNamed: n)]]

! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FileDirectory class
	instanceVariableNames: ''!

!FileDirectory class methodsFor: 'instance creation' stamp: 'jm 12/4/97 19:24'!
default
	"Answer the default directory."

	^ DefaultDirectory
! !

!FileDirectory class methodsFor: 'instance creation' stamp: 'ls 9/10/1998 00:59'!
forFileName: aString

	| path |
	path _ self dirPathFor: aString.
	path isEmpty ifTrue: [^ self default].
	^ self on: path
! !

!FileDirectory class methodsFor: 'instance creation' stamp: 'tk 5/6/1998 14:31'!
on: pathString
	"Return a new file directory for the given path, of the appropriate FileDirectory subclass for the current OS platform."

	| pathName |
	DirectoryClass ifNil: [DirectoryClass _ self activeDirectoryClass].
	"If path ends with a delimiter (: or /) then remove it"
	((pathName _ pathString) endsWith: self pathNameDelimiter asString) ifTrue: [
		pathName _ pathName copyFrom: 1 to: pathName size - 1].
	^ DirectoryClass new setPathName: pathName
! !

!FileDirectory class methodsFor: 'instance creation' stamp: 'jm 12/4/97 23:29'!
root
	"Answer the root directory."

	^ self on: ''
! !


!FileDirectory class methodsFor: 'name utilities' stamp: 'jm 11/14/2003 10:44'!
baseNameFor: fileName
	"Answer the given file name without its extension, if any."

	| i |
	i _ fileName findLast: [:c | c = $.].
	i = 0
		ifTrue: [^ fileName]
		ifFalse: [^ fileName copyFrom: 1 to: i - 1].
! !

!FileDirectory class methodsFor: 'name utilities' stamp: 'jm 12/5/97 13:30'!
dirPathFor: fullName
	"Return the directory part the given name."

	self
		splitName: fullName
		to: [:dirPath :localName | ^ dirPath]
! !

!FileDirectory class methodsFor: 'name utilities' stamp: 'jm 11/14/2003 10:45'!
extensionFor: fileName
	"Answer the extension of given file name, if any."

	| i |
	i _ fileName findLast: [:c | c = $.].
	i = 0
		ifTrue: [^ '']
		ifFalse: [^ fileName copyFrom: i + 1 to: fileName size].
! !

!FileDirectory class methodsFor: 'name utilities' stamp: 'jm 12/5/97 13:30'!
localNameFor: fullName
	"Return the local part the given name."

	self
		splitName: fullName
		to: [:dirPath :localName | ^ localName]
! !

!FileDirectory class methodsFor: 'name utilities' stamp: 'bf 3/22/2000 18:04'!
splitName: fullName to: pathAndNameBlock
	"Take the file name and convert it to the path name of a directory and a local file name within that directory. FileName must be of the form: <dirPath><delimiter><localName>, where <dirPath><delimiter> is optional. The <dirPath> part may contain delimiters."

	| delimiter i dirName localName |
	delimiter _ self pathNameDelimiter.
	(i _ fullName findLast: [:c | c = delimiter]) = 0
		ifTrue:
			[dirName _ String new.
			localName _ fullName]
		ifFalse:
			[dirName _ fullName copyFrom: 1 to: (i - 1 max: 1).
			localName _ fullName copyFrom: i + 1 to: fullName size].

	^ pathAndNameBlock value: dirName value: localName! !


!FileDirectory class methodsFor: 'system start up' stamp: 'jens 8/27/2009 22:55'!
openSources: sourcesName andChanges: changesName forImage: imageName 
	"Initialize the default directory to the image directory and open the  
	sources and changes files, if possible. Look for the changes file in  
	image directory. Look for the system sources (or an alias to it) first in  
	the VM directory, then in the image directory. Open the changes and  
	sources files and install them in SourceFiles."
	"Note: SourcesName and imageName are full paths; changesName is a  
	local name."
	| sources changes sourceAlias msg wmsg localSourcesName |
	msg _ 'Squeak cannot locate &fileRef.

Please check that the file is named properly and is in the
same directory as this image.  
Further explanation can found
in the startup window, ''How Squeak Finds Source Code''.'.
	wmsg _ 'Squeak cannot write to &fileRef.

Please check that you have write permission for this file.

You won''t be able to save this image correctly until you fix this.'.
	self setDefaultDirectoryFrom: imageName.
	sources _ changes _ nil.
	"look for the sources file or an alias to it in the VM's directory"
	(DefaultDirectory fileExists: sourcesName)
		ifTrue: [sources _ DefaultDirectory readOnlyFileNamed: sourcesName]
		ifFalse: 
			["look for an un-renamed Macintosh alias to the sources file"
			sourceAlias _ sourcesName , ' alias'.
			(DefaultDirectory fileExists: sourceAlias)
				ifTrue: [sources _ DefaultDirectory readOnlyFileNamed: sourceAlias]].
	sources
		ifNil: 
			["look for the sources file or an alias to it in the image directory"
			localSourcesName _ FileDirectory localNameFor: sourcesName.
			(DefaultDirectory fileExists: localSourcesName)
				ifTrue: [sources _ DefaultDirectory readOnlyFileNamed: localSourcesName]
				ifFalse: 
					["look for an un-renamed Macintosh alias to the sources  
					file"
					sourceAlias _ localSourcesName , ' alias'.
					(DefaultDirectory fileExists: sourceAlias)
						ifTrue: [sources _ DefaultDirectory readOnlyFileNamed: sourceAlias]]].
	(DefaultDirectory fileExists: changesName)
		ifTrue: 
			[changes _ DefaultDirectory oldFileNamed: changesName.
			changes isNil & Preferences noviceMode not
				ifTrue: 
					[PopUpMenu notify: (wmsg copyReplaceAll: '&fileRef' with: 'the changes file named ' , changesName).
					changes _ DefaultDirectory readOnlyFileNamed: changesName]].
	((sources == nil or: [sources atEnd])
		and: [Preferences valueOfFlag: #warnIfNoSourcesFile])
		ifTrue: 
			[PopUpMenu notify: (msg copyReplaceAll: '&fileRef' with: 'the sources file named ' , sourcesName)].

	(changes == nil and: [Preferences valueOfFlag: #warnIfNoChangesFile])
		ifTrue: [PopUpMenu notify: (msg copyReplaceAll: '&fileRef' with: 'the changes file named ' , changesName)].
	SourceFiles _ Array with: sources with: changes! !

!FileDirectory class methodsFor: 'system start up' stamp: 'jm 3/27/98 06:53'!
setDefaultDirectoryFrom: imageName
	"Initialize the default directory to the directory containing the Squeak image file. This method is called when the image starts up."

	DirectoryClass _ self activeDirectoryClass.
	DefaultDirectory _ self on: (self dirPathFor: imageName).
! !

!FileDirectory class methodsFor: 'system start up' stamp: 'di 2/4/1999 15:27'!
shutDown

	Smalltalk closeSourceFiles.
! !

!FileDirectory class methodsFor: 'system start up' stamp: 'di 2/4/1999 08:50'!
startUp
	"Establish the platform-specific FileDirectory subclass. Do any platform-specific startup."

	self setDefaultDirectoryFrom: Smalltalk imageName.
	Smalltalk openSourceFiles.
! !


!FileDirectory class methodsFor: 'platform specific' stamp: 'jm 11/14/2003 10:44'!
dot
	"Answer a one-character string containing a period character."

	^ '.'
! !

!FileDirectory class methodsFor: 'platform specific' stamp: 'ar 5/1/1999 01:48'!
isCaseSensitive
	"Return true if file names are treated case sensitive"
	^true! !

!FileDirectory class methodsFor: 'platform specific' stamp: 'jm 11/14/2003 10:50'!
pathNameDelimiter
	"Answer the active directory class's directory separator character (e.g., '/' on Unix, ':' on Macintosh)."

	^ DirectoryClass pathNameDelimiter
! !

!FileDirectory class methodsFor: 'platform specific' stamp: 'ar 4/18/1999 18:18'!
slash
	^ self pathNameDelimiter asString! !


!FileDirectory class methodsFor: 'private' stamp: 'TPR 5/10/1998 21:47'!
activeDirectoryClass
	"Return the concrete FileDirectory subclass for the platform on which we are currently running."

	FileDirectory allSubclasses do: [:class |
		class isActiveDirectoryClass ifTrue: [^ class]].

	"no responding subclass; use FileDirectory"
	^ FileDirectory
! !

!FileDirectory class methodsFor: 'private' stamp: 'TPR 5/10/1998 21:40'!
isActiveDirectoryClass
	"Does this class claim to be that properly active subclass of FileDirectory for this platform?
	Default test is whether the primPathNameDelimiter matches the one for this class. Other tests are possible"

	^self pathNameDelimiter = self primPathNameDelimiter
! !

!FileDirectory class methodsFor: 'private' stamp: 'jm 12/4/97 23:42'!
primPathNameDelimiter
	"Return the path delimiter for the underlying platform's file system."

 	<primitive: 161>
	self primitiveFailed
! !
