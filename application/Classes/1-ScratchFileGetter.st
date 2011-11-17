Object subclass: #ScratchFileGetter
	instanceVariableNames: 'server baseDir subdirs '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Network-HTML'!

!ScratchFileGetter methodsFor: 'all' stamp: 'jm 1/3/2005 18:04'!
getFileNamed: aString
	"Get the contents of the Scratch file in the current directory."

	| fullURL |
	fullURL _ aString.
	((aString size < 5) or:
	 [(aString copyFrom: 1 to: 5) asLowercase ~= 'http:'])
		ifTrue: [
			fullURL _ 'http://', server, '/', baseDir.
			subdirs do: [:s | fullURL _ fullURL, '/', s].
			fullURL _ fullURL, '/', aString].

	^ HTTPSocket httpGet: fullURL
! !

!ScratchFileGetter methodsFor: 'all' stamp: 'jm 10/7/2004 21:50'!
getHtml
	"Get the contents of the page for base URL with the list of subdirectories concatenated onto it."

	| fullURL |
	fullURL _ 'http://', server, '/', baseDir.
	subdirs do: [:s | fullURL _ fullURL, '/', s].
	^ HTTPSocket httpGet: fullURL
! !

!ScratchFileGetter methodsFor: 'all' stamp: 'jm 10/7/2004 21:49'!
getScratchFileFromBaseURL: baseURLString
	"Answer a ByteArray containing a Scratch file from the given base URL or nil if the user doesn't select any file. The use is presented with a sequence of menus that can be used to navigate to a particular Scratch project."

	| urlParts |
	urlParts _ HtmlChunker parseURL: baseURLString.
	server _ urlParts at: #server.
	baseDir _ urlParts at: #locator.
	subdirs _ #().
	^ self invokeMenu
! !

!ScratchFileGetter methodsFor: 'all' stamp: 'JM 11/17/2011 11:53'!
invokeMenu
	"Answer a ByteArray containing a Scratch file from the base URL or nil if the user doesn't select any file."

	| htmlString refs files links menu choice dir newKey |

	htmlString _ self getHtml contents.
	refs _ HtmlChunker linksFrom: htmlString.
	refs size = 0 ifTrue: [^ nil].
	refs _ refs asArray collect: [:assoc |
		newKey _ assoc key collect: [:ch |
			(ch asciiValue = 10) | (ch asciiValue = 13)
				ifTrue: [Character space]
				ifFalse: [ch]].
		newKey -> assoc value].

	files _ refs select: [:assoc | (assoc value asLowercase endsWith: '.scratch') | (assoc value asLowercase endsWith: '.sb') | (assoc value asLowercase endsWith: '.ypr') | (assoc value asLowercase endsWith: '.srb')].
	links _ refs select: [:assoc | ((assoc value asLowercase endsWith: '.scratch') not) & ((assoc value asLowercase endsWith: '.sb') not) & ((assoc value asLowercase endsWith: '.ypr') not) & ((assoc value asLowercase endsWith: '.srb') not)].

	menu _ CustomMenu new.
	links do: [:assoc |
		(assoc value includes: $:)
			ifTrue: [menu add: assoc key action: (#fullUrl -> assoc value)]
			ifFalse: [menu add: assoc key action: (#subdir -> assoc value)]].
	menu addLine.
	files do: [:assoc | menu add: assoc key action: (#file -> assoc value)].

	choice _ menu startUp.
	choice ifNil: [^ nil].
	choice key = # file ifTrue: [^ self getFileNamed: choice value].
	choice key = # fullUrl ifTrue: [^ self getScratchFileFromBaseURL: choice value].
	choice key = # subdir ifTrue: [
		dir _ choice value.
		(dir beginsWith: '/')
			ifTrue: [
				baseDir _ dir copyFrom: 2 to: dir size.
				subdirs _ #()]
			ifFalse: [
				subdirs _ subdirs copyWith: dir].
		^ self invokeMenu].
! !
