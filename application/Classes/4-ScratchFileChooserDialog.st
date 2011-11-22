DialogBoxMorph subclass: #ScratchFileChooserDialog
	instanceVariableNames: 'scratchFrame list choosingFolder newFileTitle newFileName thumbnailFrameMorph thumbnailMorph authorLabelMorph authorMorph commentLabelMorph commentMorph readingScratchFile type newTitleBin '
	classVariableNames: 'LastFolderForType UserHomeFolder '
	poolDictionaries: ''
	category: 'Scratch-UI-Dialogs'!
!ScratchFileChooserDialog commentStamp: '<historical>' prior: 0!
I am a File Chooser dialog box for Scratch. My submorphs vary according to my function. For example, I may show a project thumbnail, I may have a typein field to allow the user to enter a new file name, or I may have buttons to create or paint a new sprite.

You can also use me to select an existing or create a new file or folder. Some examples:

  ScratchFileChooserDialog chooseFile
  ScratchFileChooserDialog chooseFile: FileDirectory default enableNew: false
!


!ScratchFileChooserDialog methodsFor: 'initialization' stamp: 'jm 5/8/2009 10:03'!
addShortcutButtons
	"Add shortcut buttons for my type to the shortcutColumn."

	| spacer |
	spacer _ Morph new extent: 5@5; color: Color transparent.
	shortcutColumn removeAllMorphs.

	shortcutColumn addMorphBack: (self shortcutButtonLabel: 'Computer' action: #myComp icon: #folderDiscsIcon).
	shortcutColumn addMorphBack: spacer fullCopy.

	shortcutColumn addMorphBack: (self shortcutButtonLabel: self labelForHomeFolder action: #myHome icon: #folderHouseIcon).
	shortcutColumn addMorphBack: spacer fullCopy.

	shortcutColumn addMorphBack: (self shortcutButtonLabel: 'Desktop' action: #myDesktop icon: #folderIcon).
	shortcutColumn addMorphBack: spacer fullCopy.

	#background = self type ifTrue: [
		shortcutColumn addMorphBack:
			(self shortcutButtonLabel: 'Backgrounds' action: #scratchBackgrounds icon: #folderCatIcon)].

	#costume = self type ifTrue: [
		shortcutColumn addMorphBack:
			(self shortcutButtonLabel: 'Costumes' action: #scratchCostumes icon: #folderCatIcon)].

	#project = self type ifTrue: [
		shortcutColumn addMorphBack:
			(self shortcutButtonLabel: 'Examples' action: #sampleProjects icon: #folderCatIcon).
		shortcutColumn addMorphBack: spacer fullCopy.
		shortcutColumn addMorphBack:
			(self shortcutButtonLabel: 'My Projects' action: #userProjects icon: #folderIcon)].

	#sound = self type ifTrue: [
		shortcutColumn addMorphBack:
			(self shortcutButtonLabel: 'Sounds' action: #scratchSounds icon: #folderCatIcon)].

! !

!ScratchFileChooserDialog methodsFor: 'initialization' stamp: 'JM 11/17/2011 13:19'!
createScratchFileChooserFor: aScratchFrameMorph saving: savingFlag
	"Create a Scratch file chooser dialog box with a project thumbnail and info box."

	| labelFont contentsFont commentFont thumbnailHolder |
	scratchFrame _ aScratchFrameMorph.
	readingScratchFile _ savingFlag not.

	list _ ScratchFilePicker new extensions: #(scratch sb ypr srb).
	self removeAllMorphs.
	bottomSpacer delete.
	bottomSpacer _ nil.
	mainColumn addMorphBack: list.

	savingFlag ifFalse: [
		self title: 'Open Project'.
		list scratchInfoClient: self].

	labelFont _ (ScratchFrameMorph getFont: #FileChooserLabel).
	contentsFont _ (ScratchFrameMorph getFont: #FileChooserContents).
	commentFont _ (ScratchFrameMorph getFont: #FileChooserComment).

	savingFlag ifTrue: [
		self title: 'Save Project'.
		newFileTitle _ StringMorph contents: ('New Filename:' localized, ' ') font: labelFont.
		newFileTitle color: (Color gray: 0.3).
		newFileName _ StringFieldMorph new
			contents: scratchFrame projectName;
			client: self;
			font: contentsFont;
			color: (Color r: (211/255) g: (214/255) b: (216/255));
			width: 180.
		tabFields add: newFileName.
		newTitleBin
			addMorphBack: newFileTitle;
			addMorphBack: (Morph new extent: (5@5); color: Color transparent);
			addMorphBack: newFileName;
			addMorphBack: (AlignmentMorph newSpacer: Color transparent).
		ScratchTranslator isRTL
			ifTrue: [newTitleBin submorphs reversed do: [:m |
				m delete.
				newTitleBin addMorphBack: m]]].
	mainColumn
		addMorphBack: (Morph new extent: (5@9); color: Color transparent);
		addMorphBack: newTitleBin.

	thumbnailHolder _ AlignmentMorph newColumn
		centering: #center;
		color: Color transparent.
	thumbnailFrameMorph _ ImageFrameMorph new
		initFromForm: (ScratchFrameMorph skinAt: #dialogThumbnailFrame).
	thumbnailFrameMorph extent: (170@130).
	thumbnailHolder addMorph: thumbnailFrameMorph.
	fileInfoColumn
		addMorphBack: thumbnailHolder;
		addMorphBack: (Morph new extent: (5@6); color: Color transparent). "spacer"
	thumbnailMorph _ ImageMorph new form: (Form extent: 160@120 depth: 1).
	thumbnailFrameMorph addMorphFront: (thumbnailMorph position: ((thumbnailFrameMorph position) + (5@5))).

	authorLabelMorph _ StringMorph contents: 'Project author:' localized font: labelFont.
	authorLabelMorph color: (Color gray: 0.3).
	fileInfoColumn addMorphBack: authorLabelMorph.
	savingFlag
		ifTrue: [authorMorph _ StringFieldMorph new
			useStringFieldFrame;
			contents: '';
			font: contentsFont.
			tabFields add: authorMorph]
		ifFalse: [fileInfoColumn addMorphBack: (Morph new extent: (5@6); color: Color transparent). "spacer"
			authorMorph _ StringFieldMorph new
				color: Color transparent;
				borderWidth: 0;
				contents: '';
				isEditable: false;
				font: contentsFont].
	fileInfoColumn
		addMorphBack: authorMorph;
		addMorphBack: (Morph new extent: (5@6); color: Color transparent). "spacer"

	commentLabelMorph _ StringMorph contents: 'About this project:' localized font: labelFont.
	commentLabelMorph color: authorLabelMorph color.
	fileInfoColumn addMorphBack: commentLabelMorph.
	commentMorph _ ScrollingStringMorph new
		borderWidth: 0;
		contents: '';
		font: commentFont;
		extent: (210@110).
	savingFlag
		ifTrue: [commentMorph backForm: (ScratchFrameMorph skinAt: #stringFieldFrame).
			tabFields add: commentMorph]
		ifFalse: [commentMorph isEditable: false].
	fileInfoColumn addMorphBack: commentMorph.

	fileInfoColumn addMorphBack: buttonRow.
	self
		addMorphBack: shortcutColumn;
		addMorphBack: mainColumn;
		addMorphBack: fileInfoColumn.

	savingFlag ifTrue: [
		self scratchInfo: scratchFrame projectInfo.
		thumbnailMorph form: scratchFrame workPane thumbnailForm.
		"default author field to login name if known; else author"
		(aScratchFrameMorph loginName size > 0)
			ifTrue: [authorMorph contents: aScratchFrameMorph loginName]
			ifFalse: [authorMorph contents: aScratchFrameMorph author]].
! !

!ScratchFileChooserDialog methodsFor: 'initialization' stamp: 'ee 4/30/2009 11:52'!
getUserResponse
	"Wait for the user to respond, then answer the full path name of the chosen file or #cancelled if the user cancels the operation. If opening a remote file for reading, answer a HTTPFetcher on the remote file."
	"Details: This is invoked synchronously from the caller. In order to keep processing inputs and updating the screen while waiting for the user to respond, this method has its own version of the World's event loop."

	| w |
	self openInWorld.
	w _ self world.
	w activeHand newKeyboardFocus: (tabFields at: 1).
	self centerOnScreen.
	newFileName ifNotNil: [w activeHand newKeyboardFocus: newFileName].
	list getDirectoryContents.

	response _ #cancelled.  "default response"
	done _ false.
	[done or: [list isFinalSelection]] whileFalse: [w doOneCycle].
	self delete.
	w doOneCycle.  "erase myself from the screen"

	((response = #cancelled) and: [list isFinalSelection not]) ifTrue: [^ #cancelled].
	list selectedFile ifNil: [^ #cancelled].

	(thumbnailMorph notNil & readingScratchFile not) ifTrue: [  "save info in project"
		scratchFrame author: authorMorph contents withBlanksTrimmed.
		scratchFrame projectComment: commentMorph contents].

	(list currentDirectory isKindOf: ScratchServerDirectory)
		ifTrue: [^ list projectFetcher]
		ifFalse: [^ list currentDirectory fullNameFor: list selectedFile].
! !

!ScratchFileChooserDialog methodsFor: 'initialization' stamp: 'ee 6/29/2008 13:28'!
initialize
	"Create the file chooser dialog box"

	super initialize.
	choosingFolder _ false.
	scratchFrame _ nil.
	readingScratchFile _ false.

	newTitleBin _ AlignmentMorph newRow
		centering: #center;
		color: Color transparent.
	buttonRow hResizing: #spaceFill.

	self withButtonsForYes: false no: false okay: true cancel: true.
! !


!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'jm 5/12/2006 13:41'!
choosingFolder: aBoolean

	choosingFolder _ aBoolean.
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'ee 7/3/2008 14:33'!
createFileChooserLayout: allowNewFile
	"Create the file chooser dialog box."

	list _ ScratchFilePicker new.
	self removeAllMorphs.
	bottomSpacer delete.
	bottomSpacer _ nil.
	mainColumn addMorphBack: list.

	self title: 'Open'.
	allowNewFile ifTrue: [
		self title: 'Save As'.
		newFileTitle _ StringMorph new
			contents: 'New Filename:' localized, ' ';
			color: (Color gray: 0.3);
			font: (ScratchFrameMorph getFont: #FileChooserNewFileTitle).
		newFileName _ StringFieldMorph new
			font: (ScratchFrameMorph getFont: #FileChooserNewFilename);
			color: (Color r: (211/255) g: (214/255) b: (216/255));
			width: 180.
		newTitleBin
			addMorphBack: newFileTitle;
			addMorphBack: (Morph new extent: (5@5); color: Color transparent);
			addMorphBack: newFileName;
			addMorphBack: (AlignmentMorph newSpacer: Color transparent).
			ScratchTranslator isRTL
		ifTrue: [newTitleBin submorphs reversed do: [:m |
			m delete.
			newTitleBin addMorphBack: m]]].

	mainColumn
		addMorphBack: newTitleBin;
		addMorphBack: buttonRow.

	self
		addMorphBack: shortcutColumn;
		addMorphBack: mainColumn;
		addMorphBack: fileInfoColumn.
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'jm 5/12/2006 11:38'!
defaultName: aString
	"Set the default file name."

	newFileName ifNotNil: [newFileName contents: aString].
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'jm 5/14/2005 14:16'!
extensions: anArray

	list extensions: anArray.
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'ee 6/29/2008 12:45'!
listExtent: anExtent
	
	list extent: anExtent.
	self changed.
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'jm 5/20/2009 14:04'!
redirectSavesToSampleFolder
	"Check to see if we are about to save into the Sample projects directory. If so, change the default location to the user's project folder."

	(ScratchFileChooserDialog lastFolderIsSampleProjectsFolder) ifTrue: [
		self setDirectory: ScratchFileChooserDialog userScratchProjectsDir].
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'jm 5/20/2005 15:31'!
scratchFrame: aScratchFrameMorph

	scratchFrame _ aScratchFrameMorph.
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'jm 5/15/2005 00:02'!
setDirectory: anObject
	"Set the currently selected directory. The argument may be either a FileDirectory or a string."

	(anObject isKindOf: FileDirectory)
		ifTrue: [list currentDirectory: anObject]
		ifFalse:	[list currentDirectory: (list currentDirectory directoryNamed: anObject)].
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'jm 5/20/2005 16:31'!
showThumbnails: aBoolean

	list showThumbnails: aBoolean.
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'tis 12/10/2006 17:43'!
type
	"Return the type of thing being opened/saved in the file dialog box, in order to include the appropriate shortcuts.  Possible types include
	#costume
	#background
	#sound
	#sprite
	#stageShot
	#project"

	^ type
! !

!ScratchFileChooserDialog methodsFor: 'accessing' stamp: 'jm 5/21/2009 10:29'!
type: t
	"Set the type of thing being opened/saved in the file dialog box, in order to include the appropriate shortcuts.  Then add relevant shortcut buttons and set the directory. Types include:
	#background
	#costume
	#list
	#project
	#projectSummary
	#scriptSnapshot
	#sound
	#sprite
	#stageShot"

	type _ t.
	self addShortcutButtons.
	self setDirectory: (ScratchFileChooserDialog getLastFolderForType: type).
! !


!ScratchFileChooserDialog methodsFor: 'interaction' stamp: 'ee 4/30/2009 11:52'!
getUserResponseForFolder
	"Wait for the user to respond, then answer the full path name of the chosen directory or #cancelled if the user cancels the operation. To make a FileDirectory from the response string use the method: FileDirectory on: <reponse>."
	"Details: This is invoked synchronously from the caller. In order to keep processing inputs and updating the screen while waiting for the user to respond, this method has its own version of the World's event loop."

	| w |
	self openInWorld.
	w _ self world.
	w activeHand newKeyboardFocus: (tabFields at: 1).
	self extent: self extent.  "force layout"
	self position: w center - (self extent // 2) + (0@5).  "center on screen but disregard the shadow on the bottom"
	list getDirectoryContents.

	response _ #cancelled.  "default response"
	done _ false.
	[done "or: [list model isFinalSelection]"] whileFalse: [w doOneCycle].
	self delete.
	w doOneCycle.  "erase myself from the screen"

	response = #cancelled
		ifTrue: [^ #cancelled]
		ifFalse: [^ list currentDirectory].
! !

!ScratchFileChooserDialog methodsFor: 'interaction' stamp: 'ee 4/30/2009 11:52'!
getUserResponseForNewFile
	"Wait for the user to respond, then answer the full path name of the new file or #cancelled if the user cancels the operation."
	"Details: This is invoked synchronously from the caller. In order to keep processing inputs and updating the screen while waiting for the user to respond, this method has its own version of the World's event loop."

	| w fn |
	self openInWorld.
	w _ self world.
	w activeHand newKeyboardFocus: (tabFields at: 1).
	self extent: self extent.  "force layout"
	self position: w center - (self extent // 2) + (0@5).  "center on screen but disregard the shadow on the bottom"
	newFileName ifNotNil: [w activeHand newKeyboardFocus: newFileName].
	list getDirectoryContents.

	[true] whileTrue: [
		done _ false.
		[done] whileFalse: [w doOneCycle].

		response = #cancelled ifTrue: [^ #cancelled].

		thumbnailMorph ifNotNil: [  "save info in project"
			scratchFrame author: authorMorph contents withBlanksTrimmed.
			scratchFrame projectComment: commentMorph contents].

		fn _ newFileName contents withBlanksTrimmed.
		fn size > 0 ifTrue: [
			fn _ fn collect: [:ch | ('\/:' includes: ch) ifTrue: [$-] ifFalse: [ch]].  "replace directory delimiters with dashes"
			^ list currentDirectory pathName, FileDirectory pathNameDelimiter asString, fn].

		newFileTitle color: Color red.
		self openInWorld.
		w activeHand newKeyboardFocus: newFileName].
! !

!ScratchFileChooserDialog methodsFor: 'interaction' stamp: 'tis 12/16/2006 14:33'!
yes
	"Yes button was pressed."

	| entry |
	entry _ list selectedEntryOrNil.
	(entry notNil and: [entry entryIsDirectory]) ifTrue: [
		(newFileName isNil or: [newFileName contents size = 0]) ifTrue: [
			self setDirectory: entry entryName.
			choosingFolder ifTrue: [super yes].
			^ self]].
	ScratchFileChooserDialog setLastFolderTo: list currentDirectory forType: self type.
	^ super yes
! !


!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'jens 5/11/2010 08:42'!
labelForHomeFolder
	"Answer the name to use for the home folder. This is the user name unless the home folder location has been overridden by an entry in the Scratch.ini file."

	| home delimiter |
	UserHomeFolder notNil ifTrue: [^ 'Home' localized].

	home _ ScratchPlugin primGetFolderPathOrNil: 1.
	home ifNil: [^ 'Home' localized].
	delimiter _ FileDirectory pathNameDelimiter asString.

	^ UTF8 withAll: (home findTokens: delimiter) last
! !

!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'jm 9/27/2007 15:33'!
myComp
	"My Computer button was pressed."

	list currentDirectory:
		(Smalltalk isMacOSX
			ifTrue: [FileDirectory on: '/Volumes']
			ifFalse: [FileDirectory on: ''])
! !

!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'jm 5/20/2009 14:02'!
myDesktop
	"My desktop button was pressed."

	list currentDirectory: (FileDirectory on: (ScratchPlugin primGetFolderPath: 2))
! !

!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'jm 2/22/2009 22:23'!
myHome
	"My Home button was pressed."

	list currentDirectory: self class homeDir.
! !

!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'jm 2/22/2009 23:35'!
sampleProjects
	"Sample Projects button was pressed."

	(FileDirectory default directoryExists: 'Projects') ifTrue: [
		list currentDirectory:
			(FileDirectory default directoryNamed: 'Projects')].
! !

!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'tis 12/16/2006 14:58'!
scratchBackgrounds
	"Scratch Backgrounds button was pressed."

	| backgrounds |
	backgrounds _ ScratchFileChooserDialog getDefaultFolderForType: #background.
	backgrounds ifNotNil: [list currentDirectory: backgrounds].
! !

!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'tis 12/16/2006 14:58'!
scratchCostumes
	"Scratch Costumes button was pressed."

	| costumes |
	costumes _ ScratchFileChooserDialog getDefaultFolderForType: #costume.
	costumes ifNotNil: [list currentDirectory: costumes].
! !

!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'tis 12/16/2006 14:58'!
scratchSounds
	"Scratch Sounds button was pressed."

	| sounds |
	sounds _ ScratchFileChooserDialog getDefaultFolderForType: #sound.
	sounds ifNotNil: [list currentDirectory: sounds].
! !

!ScratchFileChooserDialog methodsFor: 'shortcuts' stamp: 'jm 2/24/2009 17:52'!
userProjects
	"My Projects button was pressed."

	list currentDirectory: self class userScratchProjectsDir.
! !


!ScratchFileChooserDialog methodsFor: 'other' stamp: 'jm 7/26/2006 11:22'!
delete

	super delete.
	(list isKindOf: ScratchFilePicker) ifTrue: [list stopPlayingSound].
! !

!ScratchFileChooserDialog methodsFor: 'other' stamp: 'jm 2/28/2009 14:52'!
scratchInfo: infoDict
	"Update the Scratch project thumbnail and info display."

	| s |
	infoDict ifNil: [  "clear thumbnail and info"
		thumbnailMorph form: (Form extent: thumbnailMorph extent depth: 1) fillWhite.
		authorMorph contents: ''.
		commentMorph contents: ''.
		^ self].

	((infoDict includesKey: 'thumbnail') and: [thumbnailMorph notNil])
		ifTrue: [thumbnailMorph form: (infoDict at: 'thumbnail')]
		ifFalse: [thumbnailMorph form: (Form extent: thumbnailMorph extent depth: 1) fillBlack].

	authorMorph contents: ''.
	((infoDict includesKey: 'author') and: [authorMorph notNil]) ifTrue: [
		authorMorph contents: (infoDict at: 'author')].

	s _ ''.
	readingScratchFile
		ifTrue: [
			(infoDict includesKey: 'comment') ifTrue: [s _ infoDict at: 'comment']]
		ifFalse: [
			s _ scratchFrame projectCommentOrTemplate].
	commentMorph contents: s; changed.

! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScratchFileChooserDialog class
	instanceVariableNames: ''!

!ScratchFileChooserDialog class methodsFor: 'class initialization' stamp: 'jm 5/8/2009 10:05'!
clearFolderCache
	"Clear all folder caches."
	"ScratchFileChooserDialog clearFolderCache"

	UserHomeFolder _ nil.
	LastFolderForType _ Dictionary new.
! !

!ScratchFileChooserDialog class methodsFor: 'class initialization' stamp: 'jm 5/8/2009 09:52'!
initialize

	self clearFolderCache.
! !


!ScratchFileChooserDialog class methodsFor: 'instance creation' stamp: 'ee 6/29/2008 12:49'!
chooseExistingFileType: type extensions: anArrayOrNil title: titleString

	| m |
	ScratchFileChooserDialog deleteDuplicates.
	m _ self new
		createFileChooserLayout: false;
		type: type;
		extensions: anArrayOrNil;
		title: titleString.

	^ m getUserResponse
! !

!ScratchFileChooserDialog class methodsFor: 'instance creation' stamp: 'ee 6/29/2008 12:49'!
chooseFolder: aDirectory

	| m |
	ScratchFileChooserDialog deleteDuplicates.
	m _ self new
		createFileChooserLayout: false;
		choosingFolder: true;
		setDirectory: aDirectory;  "initial directory"
		extensions: '!!';  "do not show files in the directories"
		title: 'Choose a folder'.

	^ m getUserResponseForFolder
! !

!ScratchFileChooserDialog class methodsFor: 'instance creation' stamp: 'jm 5/11/2009 20:11'!
chooseImageFileType: type title: aString
	"ScratchFileChooserDialog chooseImageFileType: #costume title: 'Costume'"

	| m |
	ScratchFileChooserDialog deleteDuplicates.
	m _ self new
		createFileChooserLayout: false;
		showThumbnails: true;
		type: type;
		extensions: #(gif jpeg jpg bmp png);
		title: aString;
		listExtent: 550@300.

	"allow sprites to be imported into the paint editor:"
	aString = 'Import Image' ifTrue: [
		m extensions: #(gif jpeg jpg bmp png sprite)].

	^ m getUserResponse
! !

!ScratchFileChooserDialog class methodsFor: 'instance creation' stamp: 'ee 1/30/2009 11:56'!
chooseNewFileDefault: defaultName title: titleString type: type

	| m |
	ScratchFileChooserDialog deleteDuplicates.
	m _ self new
		createFileChooserLayout: true;
		type: type;
		defaultName: defaultName;
		title: titleString;
		listExtent: 400@280.

	^ m getUserResponseForNewFile
! !

!ScratchFileChooserDialog class methodsFor: 'instance creation' stamp: 'jens 5/4/2010 01:16'!
chooseSpriteCostumeFor: aScratchFrameMorph
	"ScratchFileChooserDialog chooseSpriteCostumeFor: nil"

	| m |
	ScratchFileChooserDialog deleteDuplicates.
	m _ self new
		createFileChooserLayout: false;
		title: 'New Sprite';
		showThumbnails: true;
		type: #costume;
		extensions: #(gif jpeg jpg bmp png sprite ysp);
		scratchFrame: aScratchFrameMorph;
		listExtent: 550@300.

	^ m getUserResponse
! !

!ScratchFileChooserDialog class methodsFor: 'instance creation' stamp: 'tis 12/18/2006 14:50'!
deleteDuplicates
	"If another file chooser dialog box is already opened, delete it"

	World submorphs do: [:i | 
		(i isKindOf: ScratchFileChooserDialog) ifTrue: [i delete]].
! !

!ScratchFileChooserDialog class methodsFor: 'instance creation' stamp: 'ee 6/29/2008 11:55'!
openScratchFileFor: aScratchFrameMorph
	"Choose a Scratch project file for reading. Answer:
		nil, if no file is selected
		the full file name, if a local file is selected
		a ByteArray containing the project data, if a remote file is selected.
	As the user selects files in the file picker, preview the project thumbnail and info string for the selected project. If the file 'servers.txt' is found in the Scratch folder, then allow browsing and selecting of Scratch projects on a remote HTTP server."
	"ScratchFileChooserDialog openScratchFileFor: nil"

	| m response s |
	ScratchFileChooserDialog deleteDuplicates.
	m _ self new
		createScratchFileChooserFor: aScratchFrameMorph saving: false;
		type: #project.

	response _ m getUserResponse.
	response = #cancelled ifTrue: [^ nil].

	(response isKindOf: String) ifTrue: [^ response].  "answer the full name of a local file"

	"get contents of a remote file, giving the user the option of aborting"
	self assert: [response isKindOf: HTTPFetcher].
	self waitForCompletionOrCancelOfFetch: response.
	response succeeded ifFalse: [response stopDownload. ^ nil].

	s _ (response path findTokens: '/') last.
	aScratchFrameMorph projectName: (aScratchFrameMorph nameFromFileName: s).

	^ response bodyData
! !

!ScratchFileChooserDialog class methodsFor: 'instance creation' stamp: 'JM 11/17/2011 11:52'!
saveScratchFileFor: aScratchFrameMorph
	"Choose a file for saving the current Scratch project file. Display the thumbnail and info string for the current project and allow the info string to be edited. Answer the full name of the file in which to save the project or #cancelled if the operation is cancelled."
	"ScratchFileChooserDialog saveScratchFileFor: nil"

	| m result |
	ScratchFileChooserDialog deleteDuplicates.
	m _ self new
		createScratchFileChooserFor: aScratchFrameMorph saving: true;
		type: #project;
		redirectSavesToSampleFolder.

	result _ m getUserResponseForNewFile.
	result = #cancelled ifTrue: [^ result].

"	(result asLowercase endsWith: '.sb') ifFalse: [result _ result, '.sb']."
"	(result asLowercase endsWith: '.ypr') ifFalse: [result _ result, '.ypr']."
	(result asLowercase endsWith: '.srb') ifFalse: [result _ result, '.srb'].
	^ result
! !


!ScratchFileChooserDialog class methodsFor: 'accessing' stamp: 'jm 5/8/2009 09:49'!
getDefaultFolderForType: type

	| mediaDir |
	(type = #project) ifTrue: [^ self userScratchProjectsDir].

	(FileDirectory default directoryExists: 'Media') ifTrue: [
		mediaDir _ FileDirectory default directoryNamed: 'Media'.
		#background = type ifTrue: [
			(mediaDir directoryExists: 'Backgrounds') ifTrue: [
				^ mediaDir directoryNamed: 'Backgrounds']].
		(#(costume sprite) includes: type) ifTrue: [
			(mediaDir directoryExists: 'Costumes') ifTrue: [
				^ mediaDir directoryNamed: 'Costumes']].
		#sound = type ifTrue: [
			(mediaDir directoryExists: 'Sounds') ifTrue: [
				^ mediaDir directoryNamed: 'Sounds']]].

	^ self homeDir
! !

!ScratchFileChooserDialog class methodsFor: 'accessing' stamp: 'jm 5/8/2009 09:36'!
getLastFolderForType: type
	"Return the last used folder for the given type. If this is the first time the type has been used, return the default folder for that type."

	| dir |
	dir _ LastFolderForType at: type ifAbsent: [nil].
	dir ifNotNil: [
		(dir isKindOf: FileDirectory) 
			ifTrue: [(dir parentDirectory directoryExists: dir pathName) ifTrue: [^ dir]]].

	^ ScratchFileChooserDialog getDefaultFolderForType: type
! !

!ScratchFileChooserDialog class methodsFor: 'accessing' stamp: 'jm 5/20/2009 14:28'!
homeDir
	"Return the home directory for this user. By default, this is either provided by the OS via primGetFolderPath: but it can be overridden by adding a 'homedir=path' entry to the Scratch.ini folder."

	| homeDir |
	UserHomeFolder ifNotNil: [^ UserHomeFolder]. "provided by Scratch.ini"

	"try in order: documents folder, user home folder, Scratch folder"
	homeDir _ FileDirectory on: (ScratchPlugin primGetFolderPath: 3).  "documents"
	(FileDirectory default directoryExists: homeDir pathName) ifFalse: [
		homeDir _ FileDirectory on: (ScratchPlugin primGetFolderPath: 1)].  "home"
	(FileDirectory default directoryExists: homeDir pathName) ifFalse: [
		homeDir _ FileDirectory default].  "Scratch folder (last resort)"

	^ homeDir
! !

!ScratchFileChooserDialog class methodsFor: 'accessing' stamp: 'jm 5/20/2009 16:52'!
lastFolderIsSampleProjectsFolder
	"Return true if the last projects folder is the sample projects folder."

	| lastDirPath sampleProjectDirPath |
	lastDirPath _ (self getLastFolderForType: #project) pathName.
	sampleProjectDirPath _ (FileDirectory default directoryNamed: 'Projects') pathName.
	^ lastDirPath beginsWith: sampleProjectDirPath
! !

!ScratchFileChooserDialog class methodsFor: 'accessing' stamp: 'jm 5/8/2009 09:55'!
setHomeDir: aStringOrNil
	"Set the home directory for this user. If the user name contains an asterisk, replace it with the name of logged in user."
	"self setHomeDir: '/Users/*/Documents'"

	| path root |
	UserHomeFolder _ nil.
	aStringOrNil ifNotNil: [
		path _ self replaceAsteriskWithUserName: aStringOrNil.
		root _ FileDirectory on: ''.
		(root directoryExists: path) ifTrue: [
			UserHomeFolder _ root on: path]].
! !

!ScratchFileChooserDialog class methodsFor: 'accessing' stamp: 'jm 5/8/2009 09:37'!
setLastFolderTo: dir forType: type
	"Remember the given dir as the last folder used for the given type of file."

	(dir isKindOf: ScratchServerDirectory) ifTrue: [^ self].
	LastFolderForType at: type put: dir.

! !

!ScratchFileChooserDialog class methodsFor: 'accessing' stamp: 'JM 11/17/2011 11:20'!
userScratchProjectsDir
	"Return the path to the user's 'Scratch' project folder, usually located inside the user's 'Documents' folder. If the folder does not already exists, attempt to create it. If the .ini file specifies an alternate home directory, create the folder there. If the directory can't be created, return the user's home folder."

	| scratchFolderName homeDir |
	scratchFolderName _ 'Scribble Projects'.  "if this were localized a user could get multiple project folders for different languages..."

	homeDir _ self homeDir.

	"try to create Scratch Projects folder in the user's homeDir"
	(homeDir directoryExists: scratchFolderName) ifFalse: [
		[homeDir createDirectory: scratchFolderName] ifError: []].

	^ (homeDir directoryExists: scratchFolderName)
		ifTrue: [homeDir directoryNamed: scratchFolderName]
		ifFalse: [homeDir]
! !


!ScratchFileChooserDialog class methodsFor: 'utilities' stamp: 'JM 11/17/2011 11:51'!
confirmFileOverwriteIfExisting: aFilename
	"If the given file exists, ask the user if they want to overwrite it or pick a different file name."

	| response fName |
	fName _ aFilename.
"	(fName endsWith: '.sb') ifFalse: [fName _ fName, '.sb']."
"	(fName endsWith: '.ypr') ifFalse: [fName _ fName, '.ypr']."
	(fName endsWith: '.srb') ifFalse: [fName _ fName, '.srb'].
	(FileDirectory default fileExists: fName) ifFalse: [^ aFilename].

	response _ DialogBoxMorph
		askWithCancel: 'The file name already exists. Overwrite existing file?'.
	response = #cancelled ifTrue: [^ #cancelled].
	response ifTrue: [^ fName] ifFalse: [^ false].
! !

!ScratchFileChooserDialog class methodsFor: 'utilities' stamp: 'jm 2/22/2009 23:35'!
replaceAsteriskWithUserName: aString
	"If the given string includes an asterisk, replace it with the name of the current user. Otherwise, return the string."
	"self replaceAsteriskWithUserName: '/Users/*/Documents'"

	| i home delimiter userName |
	(i _ aString indexOf: $*) = 0 ifTrue: [^ aString].
	home _ ScratchPlugin primGetFolderPathOrNil: 1.
	home ifNil: [^ aString].
	delimiter _ FileDirectory pathNameDelimiter asString.
	userName _ (home findTokens: delimiter) last.
	^ (aString copyFrom: 1 to: i - 1), userName, (aString copyFrom: i + 1 to: aString size).
! !

!ScratchFileChooserDialog class methodsFor: 'utilities' stamp: 'jm 1/15/2006 09:24'!
waitForCompletionOrCancelOfFetch: anHTTPFetcher
	"Put up dialog box until the given fetch completes, fails, or is cancelled by the user."
	"self waitForCompletionOrCancelOfFetch: nil"

	| dialogBox total |
	dialogBox _ DialogBoxMorph new
		title: 'Downloading...';
		withButtonsForYes: false no: false okay: false cancel: true;
		extent: 200@150;
		percentDone: 0.

	dialogBox center: World center.
	dialogBox openInWorld.

	total _ nil.
	[dialogBox isDone not & anHTTPFetcher inProgress] whileTrue: [
		Delay waitMSecs: 100.
		total ifNil: [total _ anHTTPFetcher contentLength].
		total ifNotNil: [
			dialogBox percentDone: (100 * anHTTPFetcher bytesDownloaded) // total].
		World doOneCycle].  "wait for user to press a button"

	anHTTPFetcher succeeded ifFalse: [
		dialogBox message: 'Failed: ', anHTTPFetcher failureReason.
		[dialogBox isDone not] whileTrue: [World doOneCycle]].

	dialogBox delete.
	World doOneCycle.
! !


ScratchFileChooserDialog initialize!
