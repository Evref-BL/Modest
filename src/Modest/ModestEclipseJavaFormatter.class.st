"
I format using the Eclipse formatter.
To be used, Eclipse must be installed, and the following data is required:
- path to the Eclipse executable, can be automatically detected to some extent,
- path to a configuration file, can be automatically detected from the root directory of the Java project of the first file to be formatted, defaults to `.settings/org.eclipse.jdt.core.prefs`,
- path to a temporary directory to be used as the Eclipse workspace, it may not exist.

Optionally, you can specify the path to a Java VM.
"
Class {
	#name : 'ModestEclipseJavaFormatter',
	#superclass : 'ModestAbstractFormatter',
	#instVars : [
		'eclipsePath',
		'vmPath',
		'configPath',
		'tempDirectory'
	],
	#category : 'Modest-Formatters',
	#package : 'Modest',
	#tag : 'Formatters'
}

{ #category : 'accessing' }
ModestEclipseJavaFormatter >> configPath [

	^ configPath
]

{ #category : 'accessing' }
ModestEclipseJavaFormatter >> configPath: aPathString [

	configPath := aPathString
]

{ #category : 'accessing' }
ModestEclipseJavaFormatter >> eclipsePath [

	^ eclipsePath ifNil: [
		  (eclipsePath := self findEclipsePath) ifNil: [
			  ModestConfigurationError signal:
				  'Unable to locate Eclipse application. Please ensure the `eclipsePath` is correct and try again.' ] ]
]

{ #category : 'accessing' }
ModestEclipseJavaFormatter >> eclipsePath: aPathString [

	eclipsePath := aPathString
]

{ #category : 'enumerating' }
ModestEclipseJavaFormatter >> findConfigPathFrom: aFileToFormat [
	"Find the default Eclipse configuration file located in `.settings/org.eclipse.jdt.core.prefs` relative to a project's root folder."

	| fs directory |
	fs := FileSystem disk.
	directory := aFileToFormat parent.
	[
	fs directoryNamesAt: directory do: [ :dirName |
		dirName = '.settings' ifTrue: [
			fs filesAt: directory / dirName do: [ :path |
				path basename = 'org.eclipse.jdt.core.prefs' ifTrue: [
					^ configPath := path pathString ] ] ] ].
	(directory := directory parent) isRoot ] whileFalse.

	ModestConfigurationError signal:
		'Unable to locate Eclipse formatter configuration file, ensure the `configPath` is correct and try again.'
]

{ #category : 'enumerating' }
ModestEclipseJavaFormatter >> findEclipsePath [
	"Try to find the path to the Eclipse executable."

	OSPlatform current isMacOS ifTrue: [ ^ self findEclipsePathInMacOS ].
	OSPlatform current isWindows ifTrue: [
		^ self findEclipsePathInWindows ].
	^ nil
]

{ #category : 'enumerating' }
ModestEclipseJavaFormatter >> findEclipsePathInMacOS [
	"First search in /Applications, then try to find it in $PATH."

	self findEclipsePathInMacOSApplications ifNotNil: [ :path |
		^ path , '/Contents/MacOS/eclipse' ].
	"try to use `which`, only works if eclipse is in $PATH"
	(LibC resultOfCommand: 'which eclipse') ifNotEmpty: [ :path |
		^ path trimRight ].
	^ nil
]

{ #category : 'enumerating' }
ModestEclipseJavaFormatter >> findEclipsePathInMacOSApplications [
	"Search the /Applications directory and handle aliases."

	| aliasRegex aliasEncoder |
	aliasRegex := 'file\://[^' , (Character value: 0) asString , '-'
	              , (Character value: 31) asString , ']*Eclipse.app'.
	aliasEncoder := ZnSimplifiedByteEncoder new
		                byteToUnicode: Dictionary new;
		                beLenient.
	'/Applications' asFileReference children do: [ :app |
		app basename = 'Eclipse' ifTrue: [
			app extension = 'app' ifTrue: [ ^ app pathString ].
			"might be an alias, then we can find the actual path in its contents"
			app isFile ifTrue: [ "read as extended ascii"
				((app binaryReadStreamDo: [ :s |
					  (ZnCharacterReadStream on: s)
						  encoder: aliasEncoder;
						  contents ]) allRegexMatches: aliasRegex) ifNotEmpty: [ :refs |
					^ refs first allButFirst: 'file://' size ] ] ] ].
	^ nil
]

{ #category : 'enumerating' }
ModestEclipseJavaFormatter >> findEclipsePathInWindows [

	^ FileLocator home directories
		  detect: [ :dir | dir basename = 'eclipse' ]
		  ifFound: [ :installs | "choose the latest valid installation"
			  (installs directories sort: [ :a :b |
				   a modificationTime > b modificationTime ]) do: [ :install |
				  install / 'eclipse' / 'eclipse.exe' ifExists: [ :exe |
					  ^ exe pathString ] ].
			  nil ]
		  ifNone: [ nil ]
]

{ #category : 'formatting' }
ModestEclipseJavaFormatter >> formatFiles: files [
	"eclipse -application org.eclipse.jdt.core.JavaCodeFormatter [ OPTIONS ] -config <configFile> <files>"

	| command |
	command := WriteStream with: (OSPlatform current isWindows
			            ifTrue: [ "run the command in another terminal, not sure why but required"
				            'cmd /c start "" "' ]
			            ifFalse: [ '"' ]).
	command << self eclipsePath
	<< '" -application org.eclipse.jdt.core.JavaCodeFormatter -config "'
	<< (configPath ifNil: [ self findConfigPathFrom: files first ])
	<< '" -data "' << self tempDirectory pathString << '"'.
	vmPath ifNotNil: [ command << ' -vm "' << vmPath << '"' ].
	files do: [ :file |
		command nextPutAll: ' "'.
		file absolutePath canonicalize printPathOn: command.
		command nextPut: $" ].
	LibC runCommand: command contents
]

{ #category : 'accessing' }
ModestEclipseJavaFormatter >> tempDirectory [

	^ tempDirectory ifNil: [
		  tempDirectory := ModestConfiguration current tempDirectory ]
]

{ #category : 'accessing' }
ModestEclipseJavaFormatter >> tempDirectory: aPathString [

	tempDirectory := aPathString
]

{ #category : 'accessing' }
ModestEclipseJavaFormatter >> vmPath [

	^ vmPath
]

{ #category : 'accessing' }
ModestEclipseJavaFormatter >> vmPath: aPathString [

	vmPath := aPathString
]
