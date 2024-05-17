"
I format using a jar of [Google's Java formatter](https://github.com/google/google-java-format).
"
Class {
	#name : #ModestGoogleJavaFormatter,
	#superclass : #ModestAbstractFormatter,
	#instVars : [
		'jarPath',
		'options'
	],
	#category : #'Modest-Formatters'
}

{ #category : #'instance creation' }
ModestGoogleJavaFormatter class >> findJarInDirectory: directory [

	^ directory files
		  detect: [ :file |
			  (file basename beginsWith: 'google-java-format') and: [
				  file extension = 'jar' ] ]
		  ifOne: [ :file | self new jarPath: file pathString ]
]

{ #category : #formatting }
ModestGoogleJavaFormatter >> formatFiles: files [
	"See https://github.com/google/google-java-format. The command is:
	java -jar /path/to/google-java-format-${GJF_VERSION?}-all-deps.jar -replace <options> [files...]"

	LibC resultOfCommand: (String streamContents: [ :stream |
			 stream << 'java -jar "' << jarPath << '" -replace'.
			 options ifNotNil: [ stream << ' ' << options ].
			 files do: [ :file |
				 stream nextPutAll: ' "'.
				 file absolutePath printPathOn: stream.
				 stream nextPut: $" ] ])
]

{ #category : #accessing }
ModestGoogleJavaFormatter >> jarPath [

	^ jarPath
]

{ #category : #accessing }
ModestGoogleJavaFormatter >> jarPath: aPathString [

	jarPath := aPathString
]

{ #category : #accessing }
ModestGoogleJavaFormatter >> options [

	^ options
]

{ #category : #accessing }
ModestGoogleJavaFormatter >> options: aString [
	"Expect a string containing the options as if given on the command line:
	--aosp, -aosp, -a
	  Use AOSP style instead of Google Style (4-space indentation)
	--fix-imports-only
	  Fix import order and remove any unused imports, but do no other formatting.
	--skip-sorting-imports
	  Do not fix the import order. Unused imports will still be removed.
	--skip-removing-unused-imports
	  Do not remove unused imports. Imports will still be sorted.
	--length, -length
	  Character length to format.
	--lines, -lines, --line, -line
	  Line range(s) to format, like 5:10 (1-based; default is all).
	--offset, -offset
	  Character offset to format (0-based; default is all).
	
	The --lines, --offset, and --length flags may be given more than once.
	The --offset and --length flags must be given an equal number of times.
	If --lines, --offset, or --length are given, only one file (or -) may be given."

	options := aString
]
