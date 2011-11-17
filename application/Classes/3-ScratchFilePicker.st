ImageFrameMorph subclass: #ScratchFilePicker
	instanceVariableNames: 'directoryBarMorph contentsPaneMorph feedbackMorph scratchInfoClient currentDir extensions fetchInProgress showThumbnails thumbnailFetchProcess scratchServers scratchProjectFetcher lastUpMSecs wasSelected isDoubleClick sound finalSelection freezeFocus topBarMorph directoryBarArrowMorph '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Scratch-UI-Dialogs'!
!ScratchFilePicker commentStamp: 'jm 3/9/2005 11:40' prior: 0!
Allows the user to navigate through files and folders to select a file.
!


!ScratchFilePicker methodsFor: 'initialization' stamp: 'ee 6/19/2008 11:50'!
buildContentsPane
	"Build a scroll pane to hold the directory contents."

	contentsPaneMorph _ ScrollFrameMorph2 new
		color: self color;
		contents: (Morph new color: self color);
		showHorizontalScrollbar: false;
		hBarInset: 18;
		vBarInset: 18.

	self addMorphBack: contentsPaneMorph.
! !

!ScratchFilePicker methodsFor: 'initialization' stamp: 'ee 2/5/2009 16:22'!
initialize

	super initialize.
	self initFromForm: (ScratchFrameMorph skinAt: #filePickerFrame).
	fetchInProgress _ false.
	showThumbnails _ false.
	finalSelection _ false.
	feedbackMorph _ StringMorph new.  "used to show a remote directory fetch in progress"
	freezeFocus _ false.

	self buildButtons.
	self buildContentsPane.

	self extent: 380@310.
	self currentDirectory: FileDirectory default.
! !


!ScratchFilePicker methodsFor: 'accessing' stamp: 'tis 12/6/2006 17:24'!
contentsPaneMorph

	^ contentsPaneMorph
! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'jm 3/9/2005 11:43'!
currentDirectory
	"Answer the directory that is currently being viewed."

	^ currentDir
! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'ee 7/3/2008 15:05'!
currentDirectory: aDirectoryOrString
	"Set my current directory to the given FileDirectory or path String."

	| s truncated w eWidth |
	(currentDir isKindOf: ScratchServerDirectory) ifTrue: [
		fetchInProgress _ false.
		currentDir stopFetching].

	(aDirectoryOrString isKindOf: String)
		ifTrue: [currentDir _ FileDirectory on: aDirectoryOrString]
		ifFalse: [currentDir _ aDirectoryOrString].

	currentDir pathParts isEmpty
		ifTrue: [s _ '/']
		ifFalse: [s _ currentDir pathParts last].

	"trim directory name to fit button, if necessary"
	truncated _ false.
	eWidth _ (ScratchTranslator stringExtent: '...' font: directoryBarMorph label font) x.
	w _ 190 - eWidth.
	[((ScratchTranslator stringExtent: s font: directoryBarMorph label font) x) > w] whileTrue: [
		truncated _ true.
		s _ s copyFrom: 1 to: s size - 1].
	truncated ifTrue: [s _ s, '...'].
	s = '/' ifTrue: [s _ 'Computer'].
	directoryBarMorph label: (UTF8 withAll: s) font: (ScratchFrameMorph getFont: #FilePickerDirectoryName).
	directoryBarMorph
		width: contentsPaneMorph width - 160.
	directoryBarArrowMorph right: directoryBarMorph right - 9.
	lastUpMSecs _ 0.
	self getDirectoryContents.
! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'jm 3/9/2005 11:50'!
extensions: anArrayOfStringsOrNil
	"Set the set of extensions used to select which files to display. For example, extensions might be set to #(gif bmp png jpg) to show only files containing images. No filtering is done if extensions is nil, as it is by default."

	extensions _ anArrayOfStringsOrNil.
	extensions ifNotNil: [
		extensions _ extensions asArray collect: [:s | s asString asLowercase]].
! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'md 3/10/2005 14:37'!
isFinalSelection

	^ finalSelection! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'jm 5/22/2005 21:12'!
projectFetcher

	| fullPath |
	fullPath _ currentDir path, self selectedFile, '.scratch'.

	scratchProjectFetcher ifNotNil: [  "try to use the existing fetcher"
		(scratchProjectFetcher serverName = currentDir serverName and:
		 [scratchProjectFetcher path = fullPath])
			ifTrue: [^ scratchProjectFetcher]
			ifFalse: [
				scratchProjectFetcher stopDownload.
				scratchProjectFetcher _ nil]].

	"make a new fetcher"
	^ HTTPFetcher new
		startDownload: fullPath
		fromServer: currentDir serverName.

! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'jm 5/20/2005 16:18'!
scratchInfoClient: anObject
	"Set the object to be informed when a Scratch project file with an info dictionary is selected. The client will be sent the message #scratchInfo: once each time such a file is selected, allowing the project thumbnail and other project information to be displayed."

	scratchInfoClient _ anObject.
! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'jm 3/9/2005 11:54'!
selectedFile
	"Answer the local name of the currently selected file or nil if there is no file selected."

	contentsPaneMorph contents submorphsDo: [:m |
		(m isHighlit & m entryIsDirectory not) ifTrue: [^ m entryName]].
	^ nil
! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'jm 3/9/2005 18:04'!
showThumbnails: aBoolean
	"If true, generate and layout my contents as thumbnails."

	showThumbnails _ aBoolean.
! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'jm 1/2/2007 18:50'!
startPlayingSound: fullName
	"Attempt to play the sound with given name."

	self stopPlayingSound.

	(fullName asLowercase endsWith: '.mp3')
		ifTrue: [sound _ [StreamingMP3Sound onFileNamed: fullName] ifError: [nil]]
		ifFalse: [sound _ [SampledSound fromFileNamed: fullName] ifError: [nil]].

	sound ifNotNil: [
		(sound respondsTo: #volume:) ifTrue: [sound volume: 1.0].
		sound play].
! !

!ScratchFilePicker methodsFor: 'accessing' stamp: 'jm 1/2/2007 18:40'!
stopPlayingSound
	"If I am playing a sound, stop it."

	sound ifNotNil: [sound pause].
	sound _ nil.
! !


!ScratchFilePicker methodsFor: 'geometry' stamp: 'ee 6/28/2008 18:36'!
extent: aPoint
	"Resize my contents pane when I am resized."

	super extent: aPoint.
	contentsPaneMorph ifNotNil: [
		contentsPaneMorph
			bounds: ((self topLeft + (9@50)) corner: (self bottomRight - 7)).
		topBarMorph width: contentsPaneMorph width].
! !


!ScratchFilePicker methodsFor: 'event handling' stamp: 'jm 3/6/2005 12:12'!
handlesMouseDown: evt

	^ true
! !

!ScratchFilePicker methodsFor: 'event handling' stamp: 'jm 5/18/2005 12:53'!
highlightEntryAt: aPoint
	"Highlight the entry at the given point, if any, and unhighlight all other entries. Answer true if the selected entry was already highlit, which means this is the second click on that entry."

	| secondClick |
	secondClick _ false.
	contentsPaneMorph contents submorphsDo: [:m |
		(m isKindOf: ScratchFilePickerEntry) ifTrue: [
			(m containsPoint: aPoint)
				ifTrue: [secondClick _ m isHighlit. m highlight: true]
				ifFalse: [m highlight: false]]].

	^ secondClick
! !

!ScratchFilePicker methodsFor: 'event handling' stamp: 'jm 5/28/2009 21:21'!
keyStroke: evt
	"Handle up/down arrow keys."

	| ch m entry |
	freezeFocus ifTrue: [^ self].

	ch _ evt keyValue.

	ch = 9 ifTrue: [  "tab"
		(m _ self ownerThatIsA: DialogBoxMorph) ifNotNil: [m tabToNextField: evt].
		^ self].

	ch = 27 ifTrue: [  "escape key"
		(m _ self ownerThatIsA: DialogBoxMorph) ifNotNil: [m escapeKeyPressed: evt].
		^ self].

	((ch = 1) | (ch = 11)) ifTrue: [ "home or page up"
		self selectedEntryOrNil ifNotNil: [self selectedEntryOrNil highlight: false].
		^ self highlightAndScrollToEntry: contentsPaneMorph contents submorphs first].

	((ch = 4) | (ch = 12)) ifTrue: [ "end or page down"
		self selectedEntryOrNil ifNotNil: [self selectedEntryOrNil highlight: false].
		^ self highlightAndScrollToEntry: contentsPaneMorph contents submorphs last].

	((ch = 8) | (ch = 127)) ifTrue: [ "delete key"
		self deleteDirectory].

	((ch = 10) | (ch = 13)) ifTrue: [  "cr, lf, or enter key"
		(entry _ self selectedEntryOrNil) ifNil: [^ self].
		(entry entryIsDirectory and:
		 [(owner isKindOf: ScratchFileChooserDialog)])
			ifTrue: [self currentDirectory: (currentDir directoryNamed: entry entryName)]
			ifFalse: [(self ownerThatIsA: ScratchFileChooserDialog) yes].
		^ self].

	(ch = 28) ifTrue: [^ self changeSelectionIndexBy: -1].	"left"
	(ch = 29) ifTrue: [^ self changeSelectionIndexBy: 1].	"right"
	(ch = 30) ifTrue: [  "up"
		showThumbnails
			ifTrue: [^ self changeSelectionIndexBy: -4]
			ifFalse: [^ self changeSelectionIndexBy: -1]].
	(ch = 31) ifTrue: [  "down"
		showThumbnails
			ifTrue: [^ self changeSelectionIndexBy: 4]
			ifFalse: [^ self changeSelectionIndexBy: 1]].

	((ch between: $a asciiValue and: $z asciiValue) or:
	 [ch between: $A asciiValue and: $Z asciiValue])
		ifTrue: [^ self scrollToFileStartingWith: ch asCharacter asLowercase].
! !

!ScratchFilePicker methodsFor: 'event handling' stamp: 'jens 8/4/2008 09:18'!
mouseDown: evt
	"Record whether the mouse went down in the currently highlit entry (wasSelected) and if it should be considered a double-click. See mouseUp: for details."

	evt hand newKeyboardFocus: self.
	wasSelected _ self highlightEntryAt: evt cursorPoint.
	isDoubleClick _
		(wasSelected and:
		 [lastUpMSecs notNil and:
		 [(Time millisecondClockValue - lastUpMSecs) < 1000]]).
	self selectedEntryOrNil ifNil: [
		contentsPaneMorph grabContentsAt: evt cursorPoint ]
! !

!ScratchFilePicker methodsFor: 'event handling' stamp: 'jens 8/4/2008 09:19'!
mouseMove: evt
	"If the user drags away from the original selection and comes back, don't consider it a virtual double-click."

	contentsPaneMorph isBeingDragged ifTrue: [
		^contentsPaneMorph dragContentsTo: evt cursorPoint ].

	(self highlightEntryAt: evt cursorPoint)
		ifFalse: [isDoubleClick _ false].

	scratchInfoClient ifNotNil: [self reportScratchProjectInfo].
! !

!ScratchFilePicker methodsFor: 'event handling' stamp: 'jens 8/4/2008 09:19'!
mouseUp: evt
	"Handle a mouse up. If the mouse went down on an entry that was already selected, open that entry. (Like a double-click, but not sensitive to timing.) If the entry 'double-clicked' was a directory, open that directory. If it was a file, set finalSelection to true to cause the dialog to open the file."

	| singleClickOpensDirs playSelectedSound entry ext |
	singleClickOpensDirs _ false.
	playSelectedSound _ true.

	lastUpMSecs _ Time millisecondClockValue.

	contentsPaneMorph isBeingDragged ifTrue: [
		^contentsPaneMorph dropContents ].

	(sound notNil and: [sound isPlaying]) ifTrue: [
		self stopPlayingSound.
		isDoubleClick _ false.
		wasSelected ifTrue: [playSelectedSound _ false]].

	entry _ contentsPaneMorph contents submorphs
		detect: [:m | m containsPoint: evt cursorPoint]
		ifNone: [^ self].

	entry entryIsDirectory ifTrue: [
		singleClickOpensDirs | isDoubleClick ifTrue: [
			self currentDirectory: (currentDir directoryNamed: entry entryName)].
		^ self].

	ext _ FileDirectory extensionFor: entry entryName asLowercase.
	playSelectedSound _
		(playSelectedSound & extensions notNil) and: [extensions includes: 'wav'].

	playSelectedSound & isDoubleClick not ifTrue: [
		(extensions includes: ext) ifTrue: [
			self startPlayingSound: (currentDir fullNameFor: entry entryName)]].

	finalSelection _ isDoubleClick.
	finalSelection ifTrue: [(self ownerThatIsA: ScratchFileChooserDialog) yes].
! !


!ScratchFilePicker methodsFor: 'stepping' stamp: 'jm 5/22/2005 20:50'!
step
	"If I am showing thumbnails, poll my contents for thumbnails that are ready for display."

	showThumbnails ifTrue: [
		Delay waitMSecs: 10.
		contentsPaneMorph contents submorphsDo: [:m |
			m thumbnailReady ifTrue: [m clearThumbnailReady]]].

	fetchInProgress ifTrue: [
		currentDir fetchInProgress ifFalse: [
			self getFetchedServerDirectoryContents.
			fetchInProgress _ false]].

	scratchProjectFetcher ifNotNil: [
		self checkForScratchInfoFetchDone].
! !

!ScratchFilePicker methodsFor: 'stepping' stamp: 'jm 4/4/2005 22:43'!
stepTime

	^ 50
! !


!ScratchFilePicker methodsFor: 'private-thumbnails' stamp: 'jm 4/4/2005 22:20'!
startThumbnailFetchProcess
	"Start a background process to fetch thumbnails. This process runs at lower priority than the UI thread. The step method looks for thumbnails that have become ready and updates the display."

	thumbnailFetchProcess ifNotNil: [thumbnailFetchProcess terminate].
	thumbnailFetchProcess _ [self thumbnailFetchLoop] newProcess.
	thumbnailFetchProcess priority: Processor userBackgroundPriority.
	thumbnailFetchProcess resume.
! !

!ScratchFilePicker methodsFor: 'private-thumbnails' stamp: 'jm 4/4/2005 21:14'!
stopThumbnailFetchProcess

	thumbnailFetchProcess ifNotNil: [
		thumbnailFetchProcess terminate.
		thumbnailFetchProcess _ nil].
! !

!ScratchFilePicker methodsFor: 'private-thumbnails' stamp: 'jm 12/7/2005 12:38'!
thumbnailFetchLoop

	contentsPaneMorph contents submorphs do: [:m |
		self isInWorld ifFalse: [^ self].
		m computeThumbnail.
		Delay waitMSecs: 100].

	thumbnailFetchProcess _ nil.
	Processor terminateActive.  "stop myself--nothing after here will execute"
! !


!ScratchFilePicker methodsFor: 'private' stamp: 'jm 3/17/2009 22:00'!
addDriveShortcuts: menu
	"Add shortcuts to the file picker menu."

	| drives visible |

	"Include drives"
	menu addLine.
	(FileDirectory default isKindOf: WinFileDirectory)
		ifTrue: [  "Windows"
			drives _ (FileDirectory on: '') directoryNames.
			drives _ drives copyWithout: 'Network'.
			drives _ drives copyWithout: 'automount/Servers'.
			(visible _ ScratchFrameMorph visibleDrives) ifNotNil: [
				drives _ drives select: [:drive | visible includes: drive asUppercase]].
			drives do: [:drive | menu add: drive action: drive]]
		ifFalse: [  "Mac OS X"
			drives _ (FileDirectory on: '/Volumes') directoryNames.
			(visible _ ScratchFrameMorph visibleDrives) ifNotNil: [
				drives _ drives select: [:drive | visible includes: drive asUppercase]].
			drives _ drives do: [:drive |
				menu add: drive action: '/Volumes/', drive]].
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'tis 12/18/2006 16:38'!
addShortcut: dir named: name toMenu: menu
	"Adds one of the Scratch default folders to the file picker menu, if it is not the current directory."

	dir ifNil: [^ self].
	(currentDir isKindOf: ScratchServerDirectory) "keep this check separate since a ScratchServerDirectory does not respond to pathName"
		ifTrue: [^ menu add: name action: dir pathName].
	(dir pathName ~= currentDir pathName)
		ifTrue: [^ menu add: name action: dir pathName].
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'ee 7/3/2008 16:21'!
buildButtons
	"Build my directory bar, parent buttons, and new folder button."

	| b f |
	topBarMorph _ AlignmentMorph newRow
		hResizing: #spaceFill;
		vResizing: #rigid;
		centering: #center;
		color: Color transparent.
	directoryBarArrowMorph _ ImageMorph new form: (ScratchFrameMorph skinAt: #directoryBarArrow).
	directoryBarMorph _ ResizableToggleButton2 new
		offForm: (ScratchFrameMorph skinAt: #directoryBar)
		onForm: (ScratchFrameMorph skinAt: #directoryBar);
		padding: 3@5.
	directoryBarMorph
		target: self;
		actionSelector: #directoryMenu;
		actWhen: #buttonUp.
	topBarMorph
		addMorphBack: (Morph new extent: (5@5); color: Color transparent);
		addMorphBack: directoryBarMorph.

	b _ ToggleButton
		onForm: (ScratchFrameMorph skinAt: #parentDirectoryButtonOn)
		offForm: (ScratchFrameMorph skinAt: #parentDirectoryButton).
	b
		target: self;
		actionSelector: #showParentDirectory;
		actWhen: #buttonUp;
		isMomentary: true.
	topBarMorph
		addMorphBack: (Morph new extent: (5@5); color: Color transparent);
		addMorphBack: (b position: self position + (252@16)).

	f _ ToggleButton
		onForm: (ScratchFrameMorph skinAt: #newFolderIconSelected)
		offForm: (ScratchFrameMorph skinAt: #newFolderIcon).
	f
		target: self;
		actionSelector: #newDirectory;
		actWhen: #buttonUp;
		isMomentary: true.
	topBarMorph
		addMorphBack: (Morph new extent: (5@5); color: Color transparent);
		addMorphBack: (f position: self position + (274@16)).

	directoryBarMorph
		label: (UTF8 withAll: '<directory>') font: (ScratchFrameMorph getFont: #FilePickerDirectoryName);
		leftJustifyInset: 9.

	self addMorphFront: (directoryBarArrowMorph position: self topLeft + ((b left - 32)@((50 - directoryBarArrowMorph height) // 2))).
	self addMorphBack: (topBarMorph position: self topLeft + (5@5)).
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 1/2/2007 18:41'!
changeSelectionIndexBy: anInteger

	| entries e newI |
	self stopPlayingSound.

	entries _ contentsPaneMorph contents submorphs.
	entries size = 0 ifTrue: [^ self].

	1 to: entries size do: [:i |
		e _ entries at: i.
		e isHighlit ifTrue: [
			e highlight: false.
			newI _ i + anInteger.
			newI > entries size ifTrue: [newI _ (i + 1) min: entries size].
			newI < 1 ifTrue: [newI _ (i - 1) max: 1].
			self highlightAndScrollToEntry: (entries at: newI).
			^ self]].

	entries first highlight: true.
	scratchInfoClient ifNotNil: [self reportScratchProjectInfo].
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 7/30/2008 17:09'!
checkForScratchInfoFetchDone
	"Try to retrieve info for the currently selected Scratch project and, if successful, report it to our client."
	"Details: The fetcher is allowed to keep running even after the info dictionary is retrieved. Thus if the user decides to open this project, we'll have a head start on fetching it."

	| data s version infoSize infoDict |
	scratchProjectFetcher ifNil: [^ self].

	data _ scratchProjectFetcher bodyData.
	data size >= 14 ifTrue: [
		s _ ReadStream on: data.
		version _ ObjStream scratchFileVersionFrom: (s next: 10) asString.
		(version = 1) | (version = 2)
			ifTrue: [
				infoSize _ s uint32.
				infoSize <= (s size - s position) ifTrue: [
					infoDict _ [ObjStream new readObjFrom: s] ifError: [Dictionary new].
					scratchInfoClient scratchInfo: infoDict]]
			ifFalse: [
				scratchInfoClient scratchInfo: Dictionary new]].

! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 12/22/2006 21:52'!
deleteDirectory
	"Delete the directory or file that is currently highlit."

	| entries selectedDir dirEntries response |
	entries _ contentsPaneMorph contents submorphs.
	selectedDir _ entries detect: [:e | e isHighlit & e entryIsDirectory] ifNone: [^ self].

	dirEntries _ (self currentDirectory directoryNamed: selectedDir entryName) entries.
	dirEntries size > 0 ifTrue: [^ self].  "do nothing if selectedDir is not empty"

	freezeFocus _ true.
	response _ DialogBoxMorph ask: 
		'Are you sure you want to delete the empty folder ''' , selectedDir entryName , '''?'.
	freezeFocus _ false.

	response ifTrue: [
		[self currentDirectory deleteDirectory: e entryName]
			ifError: [^ DialogBoxMorph warn: 'Could not delete folder.'].
		^ self currentDirectory: self currentDirectory].
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jens 5/12/2010 00:51'!
directoryMenu
	"Present a drop-down menu of all directories in my current path."

	| menu pathParts prefix n serverEntries choice s serverPath |
	self navigationForbidden ifTrue: [^ self].

	menu _ CustomMenu new.
	pathParts _ currentDir pathParts.
	prefix _ ''.
	n _ 1.
	pathParts do: [:part |
		menu add: (prefix asUTF8, part) asMacRoman action: n.
		prefix _ prefix ,'  '.
		n _ n + 1].
	pathParts isEmpty ifTrue: [menu add: 'Computer' action: (FileDirectory on: '') pathName].

	self addDriveShortcuts: menu.

	"if opening a Scratch project, allow access to servers"
	scratchInfoClient ifNotNil: [
		serverEntries _ ScratchFrameMorph scratchServers.
		serverEntries size > 0 ifTrue: [
			menu addLine.
			serverEntries do: [:entry |
				menu add: entry first action: n.
				n _ n + 1]]].

	choice _ menu
		startUp: nil
		withCaption: nil
		at: (directoryBarMorph right - 117)@(directoryBarMorph top + 8).
	choice ifNil: [^ self].

	(choice isKindOf: String) ifTrue: [
		choice = 'Computer'
			ifTrue: [^ self currentDirectory: '']
			ifFalse: [^ self currentDirectory: choice contents]].

	choice > pathParts size ifTrue: [
		entry _ serverEntries at: choice - pathParts size.
		^ self currentDirectory: (ScratchServerDirectory new
			serverName: (entry at: 2);
			path: (entry at: 3))].

	s _ WriteStream on: String new.
	1 to: choice do: [:i |
		s nextPutAll: (pathParts at: i).
		i < choice ifTrue: [s nextPut: currentDir pathNameDelimiter]].

	(currentDir isKindOf: ScratchServerDirectory)
		ifTrue: [
			serverPath _ '/', s contents.
			(serverPath endsWith: '/') ifFalse: [serverPath _ serverPath, '/'].
			self currentDirectory: (currentDir copy path: serverPath)]
		ifFalse: [
			self currentDirectory: s contents].
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 1/2/2007 17:11'!
getDirectoryContents
	"Generate and layout the morphs in my contents pane from the files and folder in the current directory."

	feedbackMorph delete.

	(currentDir isKindOf: FileDirectory)
		ifTrue: [^ self getLocalDirectoryContents].

	"remote case: start fetching directory contents and give feedback that fetch is started"
	feedbackMorph
		contents: 'Reading from ', currentDir serverName, '...';
		position: self topLeft + (20@60).

	contentsPaneMorph contents removeAllMorphs.
	contentsPaneMorph vScrollRelative: 0.
	self addMorphFront: feedbackMorph.
	fetchInProgress _ true.
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'JM 11/17/2011 11:53'!
getFetchedServerDirectoryContents
	"Generate and layout the morphs in my contents pane for the files and folder in the recently server directory contents. If the fetch generated an error, display the error."
	"Assume that the page morph exists already."

	| page m morphsToAdd x y nm isDir |
	page _ contentsPaneMorph contents.

	currentDir fetchSucceeded ifFalse: [
		m _ StringMorph contents: 'Failed: ', currentDir fetchFailureReason.
		page addMorph: (m position: page topLeft + (10@30)).
		^ self].

	morphsToAdd _ OrderedCollection new: 1000.
	x _ page left + 7.
	y _ page top + 5.
	currentDir allNames do: [:n |
		nm _ n.
		isDir _ true.
		(n asLowercase endsWith: '.scratch') ifTrue: [
			nm _ n copyFrom: 1 to: n size - '.scratch' size.
			isDir _ false].
		(n asLowercase endsWith: '.sb') ifTrue: [
			nm _ n copyFrom: 1 to: n size - '.sb' size.
			isDir _ false].
		(n asLowercase endsWith: '.ypr') ifTrue: [
			nm _ n copyFrom: 1 to: n size - '.ypr' size.
			isDir _ false].
		(n asLowercase endsWith: '.srb') ifTrue: [
			nm _ n copyFrom: 1 to: n size - '.srb' size.
			isDir _ false].
		m _ ScratchFilePickerEntry new
			name: nm dir: currentDir isDirectory: isDir;
			width: self width - 60;
			color: self color.
		morphsToAdd add: (m position: x@y).
		y _ y + m height].

	feedbackMorph delete.
	page removeAllMorphs.
	page addAllMorphs: morphsToAdd.
	self changeSelectionIndexBy: 1.
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 10/29/2007 09:36'!
getLocalDirectoryContents
	"Generate and layout the morphs in my contents pane from the files and folder in the current local directory."

	| allNames fileNames dirNames ext page |
	"make an alphabetized list of all files and directory names"
	fileNames _ currentDir fileNames.
	extensions ifNotNil: [  "filter out files without a matching extension"
		fileNames _ fileNames select: [:n |
			extensions includes: (FileDirectory extensionFor: n) asLowercase]].
	fileNames _ fileNames sort: [:n1 :n2 | n1 caseInsensitiveLessOrEqual: n2].
	dirNames _ self getLocalDirectoryNames.
	dirNames _ dirNames sort: [:n1 :n2 | n1 caseInsensitiveLessOrEqual: n2].
	allNames _ dirNames , fileNames.
	allNames _ allNames reject: [:n | n endsWith: '_th.gif'].					"suppress Scratch project thumbnails"
	allNames _ allNames reject: [:n | n beginsWith: '.'].						"suppress hidden files on Mac OS X and Unix"
	allNames _ allNames reject: [:n |
		ext _ (FileDirectory extensionFor: n) asLowercase.
		#(app dll exe ini image changes) includes: ext].
	allNames _ allNames reject: [:n | ScratchPlugin isHidden: (currentDir fullNameFor: n)].	"suppress hidden files/folders on Win32"

	currentDir pathName = FileDirectory default pathName ifTrue: [
		allNames _ allNames reject: [:fn |
			#(help icons 'license.txt' locale plugins 'scratch.app' ) includes: fn asLowercase]].

	showThumbnails
		ifTrue: [page _ self thumbnailStylePageFor: allNames]
		ifFalse: [page _ self listStylePageFor: allNames].
	contentsPaneMorph contents: page.

	showThumbnails ifTrue: [self startThumbnailFetchProcess].
	self changeSelectionIndexBy: 1.
! !

!ScratchFilePicker methodsFor: 'private'!
getLocalDirectoryNames
	"Answer the directories in currentDir. Suppress hidden volumes."

	| dirNames visible |
	dirNames _ currentDir directoryNames.
	(visible _ ScratchFrameMorph visibleDrives) ifNil: [^ dirNames].

	Smalltalk isMacOSX
		ifTrue: [currentDir pathName = '/Volumes' ifFalse: [^ dirNames]]
		ifFalse: [currentDir pathName = '' ifFalse: [^ dirNames]].

	^ dirNames select: [:dir | visible includes: dir asUppercase]
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 7/30/2008 17:10'!
getScratchInfoFromFile
	"Answer the project info dictionary for the currently selected file. Answer the empty dictionary if no file is selected or if the file does not include a project info dictionary (e.g. if it is in an older Scratch file format)."

	| result fullName f version buf |
	result _ Dictionary new.

	self selectedFile ifNil: [^ result].

	fullName _ currentDir fullNameFor: self selectedFile.
	(FileDirectory default fileExists: fullName) ifFalse: [^ result].
	[f _ (FileStream readOnlyFileNamed: fullName) binary] ifError: [^ result].

	[
		version _ ObjStream scratchFileVersionFrom: (f next: 10) asString.
		(version = 1) | (version = 2) ifTrue: [
			buf _ f next: f uint32.
			result _ ObjStream new readObjFrom: (ReadStream on: buf)].
	] ifError: [].
	f close.

	^ result
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'tis 12/7/2006 18:50'!
highlightAndScrollToEntry: e

	e highlight: true.
	contentsPaneMorph scrollSubmorphIntoView: e.
	scratchInfoClient ifNotNil: [self reportScratchProjectInfo].
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'ee 6/27/2008 15:39'!
listStylePageFor: allNames
	"Answer a new contents page as a column of list style entries."

	| page dirNames morphsToAdd x y m |
	page _ Morph new
		color: self color;
		width: self width - 20.

	dirNames _ currentDir directoryNames asSet.
	morphsToAdd _ OrderedCollection new: 1000.
	x _ page left + 7.
	y _ page top + 5.
	allNames do: [:n |
		m _ ScratchFilePickerEntry new
			name: n dir: currentDir isDirectory: (dirNames includes: n);
			width: self width - 60;
			color: self color;
			borderWidth: 0;
			useRoundedCorners.
		morphsToAdd add: (m position: x@y).
		y _ y + m height].

	page addAllMorphs: morphsToAdd.
	^ page
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 3/25/2009 17:17'!
navigationForbidden
	"Answer true if navigating the file hierarch is forbidden because there is a visibledrives entry in the Scratch.ini file."

	| thisDrive pathParts |
	ScratchFrameMorph visibleDrives ifNil: [^ false].

	thisDrive _ ''.
	pathParts _ currentDir pathParts.
	pathParts size > 0 ifTrue: [thisDrive _ pathParts first asUppercase].
	Smalltalk isMacOSX ifTrue: [
		((thisDrive = 'volumes') and: [pathParts size > 1]) ifTrue: [
			thisDrive _ pathParts second asUppercase]].

	(ScratchFrameMorph visibleDrives includes: thisDrive) ifTrue: [^ false].

	self beep.
	^ true
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'ee 6/27/2008 17:45'!
newDirectory
	"Create a new directory."

	| name |
	name _ StringDialog askWithCancel: 'New folder name:'.
	name = '' ifTrue: [^ self].
	[self currentDirectory createDirectory: name] ifError: [:err :rcvr |
		^ DialogBoxMorph warn: 'Could not create folder.'].
	self currentDirectory: self currentDirectory.
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 1/2/2007 16:42'!
reportScratchProjectInfo
	"Try to retrieve info for the currently selected Scratch project and, if successful, report it to our client."

	| fullPath |
	scratchInfoClient ifNil: [^ self].

	scratchProjectFetcher ifNotNil: [
		scratchProjectFetcher stopDownload.
		scratchProjectFetcher _ nil].

	self selectedFile ifNil: [scratchInfoClient scratchInfo: nil. ^ self].

	(currentDir isKindOf: FileDirectory) ifTrue: [
		^ scratchInfoClient scratchInfo: self getScratchInfoFromFile].

	"directory is on a server: start a fetcher to get the project info"
	fullPath _ currentDir path, self selectedFile, '.scratch'.
	scratchProjectFetcher ifNil: [scratchProjectFetcher _ HTTPFetcher new].

	((scratchProjectFetcher serverName ~= currentDir serverName) |
	 (scratchProjectFetcher path ~= fullPath)) ifTrue: [
		"start fetching from the new path"
		scratchProjectFetcher
			startDownload: fullPath 
			fromServer: currentDir serverName].

	Delay waitMSecs: 50.
	self checkForScratchInfoFetchDone.
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 1/2/2007 18:40'!
scrollToFileStartingWith: aCharacter

	| entries possibilities currentlyHighlightedIndex |
	self stopPlayingSound.

	entries _ contentsPaneMorph contents submorphs.
	entries size = 0 ifTrue: [^ self].

	"get all folders and files starting with aCharacter"
	possibilities _ entries select: [:e | e entryName asLowercase beginsWith: (String with: aCharacter)].
	possibilities isEmpty ifTrue: [^ self].

	"Find the currentlyHighlightedIndex"
	1 to: entries size do: [:i |
		e _ entries at: i.
		e isHighlit ifTrue: [
			e highlight: false. 
			currentlyHighlightedIndex _ i]].

	"Find the next file or folder (after the currentlyHighlightedIndex) starting with aCharacter"
	currentlyHighlightedIndex ifNotNil: [
		(currentlyHighlightedIndex + 1) to: entries size do: [:i |
			e _ entries at: i.
			(e entryName asLowercase beginsWith: (String with: aCharacter)) ifTrue: [
				^ self highlightAndScrollToEntry: e]]].

	"If all else fails, highlight the first file or folder starting with aCharacter"
	^ self highlightAndScrollToEntry: possibilities first
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 6/23/2005 16:19'!
selectedEntryOrNil

	^ contentsPaneMorph contents submorphs
		detect: [:m | m isHighlit]
		ifNone: [^ nil]
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'jm 2/22/2009 22:40'!
showParentDirectory
	"Go to my parent directory."

	self navigationForbidden ifTrue: [^ self].

	self currentDirectory: currentDir parentDirectory.
! !

!ScratchFilePicker methodsFor: 'private' stamp: 'ee 6/27/2008 18:37'!
thumbnailStylePageFor: allNames
	"Answer a new contents page as tableau of thumbnails."

	| page dirNames morphsToAdd leftMargin rightMargin x y m thumbnailCache f |
	page _ Morph new
		color: self color;
		width: self width - 20.

	dirNames _ currentDir directoryNames asSet.
	thumbnailCache _ ThumbnailCache new directory: currentDir.
	thumbnailCache readThumbnailFile; updateThumbnails.
	morphsToAdd _ OrderedCollection new: 1000.
	leftMargin _ page left + 7.
	rightMargin _ page width - 75.
	x _ leftMargin.
	y _ page top + 5.
	allNames do: [:n |
		m _ ScratchFilePickerImageEntry new
			name: n dir: currentDir isDirectory: (dirNames includes: n).
		m
			borderWidth: 0;
			useRoundedCorners.
		f _ thumbnailCache thumbnailFor: n.
		f ifNotNil: [m thumbnailForm: f].
		morphsToAdd add: (m position: x@y).
		x _ x + m width.
		x > rightMargin ifTrue: [
			x _ leftMargin.
			y _ y + m height]].

	page addAllMorphs: morphsToAdd.
	^ page
! !
