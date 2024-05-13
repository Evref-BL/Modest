"
I represent the configuration data read from a configuration file by `ModestConfigurationReader`.
I serve as the central repository for storing all parameters and settings required for running `ModestConfigurableTestGenerator`.
"
Class {
	#name : #ModestConfiguration,
	#superclass : #Object,
	#instVars : [
		'additionalConfiguration',
		'name',
		'language',
		'famixModel',
		'traceClassKey',
		'traceMethodKey',
		'traceArgumentsKey',
		'traceResultKey',
		'localDirectory',
		'sourceDirectory',
		'exportDirectory',
		'traceExtractor',
		'traceLoader',
		'traceTransformers',
		'valueImporter',
		'valueExporter',
		'testExporter',
		'refactorer'
	],
	#category : #'Modest-Configuration'
}

{ #category : #'accessing - other properties' }
ModestConfiguration >> classpath [

	^ additionalConfiguration at: 'classpath' ifAbsent: [ nil ]
]

{ #category : #'accessing - other properties' }
ModestConfiguration >> classpath: aString [

	additionalConfiguration at: 'classpath' put: aString
]

{ #category : #'accessing - other properties' }
ModestConfiguration >> codeFormatter [

	^ additionalConfiguration at: 'codeFormatter' ifAbsent: [ nil ]
]

{ #category : #'accessing - other properties' }
ModestConfiguration >> codeFormatter: aFormatter [

	additionalConfiguration at: 'codeFormatter' put: aFormatter
]

{ #category : #'accessing - other properties' }
ModestConfiguration >> coverageTargetDirectory [

	^ additionalConfiguration
		  at: 'coverageTargetDirectory'
		  ifAbsent: [ nil ]
]

{ #category : #'accessing - other properties' }
ModestConfiguration >> coverageTargetDirectory: aFile [

	additionalConfiguration at: 'coverageTargetDirectory' put: aFile
]

{ #category : #'reflective operations' }
ModestConfiguration >> doesNotUnderstand: aMessage [
	"Add or get additional configuration."

	super doesNotUnderstand: aMessage
	"^ aMessage selector last == $:
		  ifTrue: [
			  additionalConfiguration
				  at: aMessage selector allButLast
				  put: aMessage arguments first ]
		  ifFalse: [
			  additionalConfiguration at: aMessage selector ifAbsent: [
				  ModestConfigurationError signal:
					  'No configuration found for `' , aMessage selector , '`.' ] ]"
]

{ #category : #accessing }
ModestConfiguration >> exportDirectory [

	^ exportDirectory
]

{ #category : #accessing }
ModestConfiguration >> exportDirectory: anObject [

	exportDirectory := anObject
]

{ #category : #accessing }
ModestConfiguration >> famixModel [

	^ famixModel
]

{ #category : #accessing }
ModestConfiguration >> famixModel: anObject [

	famixModel := anObject
]

{ #category : #initialization }
ModestConfiguration >> initialize [

	additionalConfiguration := SmallDictionary new
]

{ #category : #accessing }
ModestConfiguration >> language [

	^ language
]

{ #category : #accessing }
ModestConfiguration >> language: aString [

	language := aString
]

{ #category : #'accessing - other properties' }
ModestConfiguration >> libDirectory [

	^ additionalConfiguration at: 'libDirectory' ifAbsent: [ nil ]
]

{ #category : #'accessing - other properties' }
ModestConfiguration >> libDirectory: aFile [

	additionalConfiguration at: 'libDirectory' put: aFile
]

{ #category : #accessing }
ModestConfiguration >> localDirectory [

	^ localDirectory
]

{ #category : #accessing }
ModestConfiguration >> localDirectory: anObject [

	localDirectory := anObject
]

{ #category : #accessing }
ModestConfiguration >> name [

	^ name
]

{ #category : #accessing }
ModestConfiguration >> name: anObject [

	name := anObject
]

{ #category : #accessing }
ModestConfiguration >> refactorer [

	^ refactorer
]

{ #category : #accessing }
ModestConfiguration >> refactorer: anObject [

	refactorer := anObject
]

{ #category : #accessing }
ModestConfiguration >> sourceDirectory [

	^ sourceDirectory
]

{ #category : #accessing }
ModestConfiguration >> sourceDirectory: anObject [

	sourceDirectory := anObject
]

{ #category : #accessing }
ModestConfiguration >> testExporter [

	^ testExporter
]

{ #category : #accessing }
ModestConfiguration >> testExporter: anObject [

	testExporter := anObject
]

{ #category : #accessing }
ModestConfiguration >> traceArgumentsKey [

	^ traceArgumentsKey
]

{ #category : #accessing }
ModestConfiguration >> traceArgumentsKey: anObject [

	traceArgumentsKey := anObject
]

{ #category : #accessing }
ModestConfiguration >> traceClassKey [

	^ traceClassKey
]

{ #category : #accessing }
ModestConfiguration >> traceClassKey: anObject [

	traceClassKey := anObject
]

{ #category : #accessing }
ModestConfiguration >> traceExtractor [

	^ traceExtractor
]

{ #category : #accessing }
ModestConfiguration >> traceExtractor: anObject [

	traceExtractor := anObject
]

{ #category : #accessing }
ModestConfiguration >> traceLoader [

	^ traceLoader
]

{ #category : #accessing }
ModestConfiguration >> traceLoader: anObject [

	traceLoader := anObject
]

{ #category : #accessing }
ModestConfiguration >> traceMethodKey [

	^ traceMethodKey
]

{ #category : #accessing }
ModestConfiguration >> traceMethodKey: anObject [

	traceMethodKey := anObject
]

{ #category : #accessing }
ModestConfiguration >> traceResultKey [

	^ traceResultKey
]

{ #category : #accessing }
ModestConfiguration >> traceResultKey: anObject [

	traceResultKey := anObject
]

{ #category : #accessing }
ModestConfiguration >> traceTransformers [

	^ traceTransformers
]

{ #category : #accessing }
ModestConfiguration >> traceTransformers: anObject [

	traceTransformers := anObject
]

{ #category : #accessing }
ModestConfiguration >> valueExporter [

	^ valueExporter
]

{ #category : #accessing }
ModestConfiguration >> valueExporter: anObject [

	valueExporter := anObject
]

{ #category : #accessing }
ModestConfiguration >> valueImporter [

	^ valueImporter
]

{ #category : #accessing }
ModestConfiguration >> valueImporter: anObject [

	valueImporter := anObject
]