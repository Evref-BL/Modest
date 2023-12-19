Class {
	#name : #ModestGoogleJavaFormatter,
	#superclass : #Object,
	#instVars : [
		'jarPath'
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
	java -jar /path/to/google-java-format-${GJF_VERSION?}-all-deps.jar --replace [files...]"

	| command |
	command := String streamContents: [ :stream |
		           stream nextPutAll: 'java -jar "'.
		           stream nextPutAll: jarPath.
		           stream nextPutAll: '" --replace'.
		           files do: [ :file |
			           stream nextPutAll: ' "'.
			           file absolutePath printPathOn: stream.
			           stream nextPut: $" ] ].
	LibC runCommand: command
]

{ #category : #accessing }
ModestGoogleJavaFormatter >> jarPath: aString [

	jarPath := aString
]
