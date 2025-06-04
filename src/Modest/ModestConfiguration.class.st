"
I represent the configuration data read from a configuration file by `ModestConfigurationReader`.
I serve as the central repository for storing all parameters and settings required for running `ModestConfigurableTestGenerator`.
"
Class {
	#name : 'ModestConfiguration',
	#superclass : 'Object',
	#instVars : [
		'additionalConfiguration',
		'name',
		'language',
		'famixModel',
		'entityFinder',
		'traceClassKey',
		'traceMethodKey',
		'traceReceiverKey',
		'traceArgumentsKey',
		'traceResultKey',
		'localDirectory',
		'sourceDirectory',
		'exportDirectory',
		'tracesDirectory',
		'traceExtractor',
		'traceLoader',
		'traceTransformers',
		'valueImporter',
		'valueExporter',
		'testExporter',
		'refactorer',
		'testSuiteReducer'
	],
	#classVars : [
		'Current'
	],
	#category : 'Modest-Configuration',
	#package : 'Modest',
	#tag : 'Configuration'
}

{ #category : 'accessing' }
ModestConfiguration class >> current [

	^ Current
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> classpath [

	^ additionalConfiguration at: 'classpath' ifAbsent: [ nil ]
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> classpath: aString [

	additionalConfiguration at: 'classpath' put: aString
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> codeFormatter [

	^ additionalConfiguration at: 'codeFormatter' ifAbsent: [ nil ]
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> codeFormatter: aFormatter [

	additionalConfiguration at: 'codeFormatter' put: aFormatter
]

{ #category : 'accessing - computed' }
ModestConfiguration >> coverageDirectory [

	^ self tempDirectory / 'coverage'
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> coverageTargetDirectory [

	^ additionalConfiguration
		  at: 'coverageTargetDirectory'
		  ifAbsent: [ nil ]
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> coverageTargetDirectory: aFile [

	additionalConfiguration at: 'coverageTargetDirectory' put: aFile
]

{ #category : 'accessing' }
ModestConfiguration >> entityFinder [

	^ entityFinder
]

{ #category : 'accessing' }
ModestConfiguration >> entityFinder: aFamixEntityFinder [

	entityFinder := aFamixEntityFinder
]

{ #category : 'accessing' }
ModestConfiguration >> exportDirectory [

	^ exportDirectory
]

{ #category : 'accessing' }
ModestConfiguration >> exportDirectory: aFile [

	exportDirectory := aFile
]

{ #category : 'accessing' }
ModestConfiguration >> famixModel [

	^ famixModel
]

{ #category : 'accessing' }
ModestConfiguration >> famixModel: anObject [

	famixModel := anObject
]

{ #category : 'initialization' }
ModestConfiguration >> initialize [

	Current := self.
	additionalConfiguration := SmallDictionary new
]

{ #category : 'accessing' }
ModestConfiguration >> language [

	^ language
]

{ #category : 'accessing' }
ModestConfiguration >> language: aString [

	language := aString
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> libDirectory [

	^ additionalConfiguration at: 'libDirectory' ifAbsent: [ nil ]
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> libDirectory: aFile [

	additionalConfiguration at: 'libDirectory' put: aFile
]

{ #category : 'accessing' }
ModestConfiguration >> localDirectory [

	^ localDirectory
]

{ #category : 'accessing' }
ModestConfiguration >> localDirectory: aFile [

	localDirectory := aFile
]

{ #category : 'accessing' }
ModestConfiguration >> name [

	^ name
]

{ #category : 'accessing' }
ModestConfiguration >> name: anObject [

	name := anObject
]

{ #category : 'accessing' }
ModestConfiguration >> refactorer [

	^ refactorer
]

{ #category : 'accessing' }
ModestConfiguration >> refactorer: anObject [

	refactorer := anObject
]

{ #category : 'accessing' }
ModestConfiguration >> sourceDirectory [

	^ sourceDirectory
]

{ #category : 'accessing' }
ModestConfiguration >> sourceDirectory: anObject [

	sourceDirectory := anObject
]

{ #category : 'accessing - computed' }
ModestConfiguration >> tempDirectory [

	^ self localDirectory / 'temp'
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> testDependencies [

	^ additionalConfiguration at: 'testDependencies' ifAbsent: [ nil ]
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> testDependencies: aString [

	additionalConfiguration at: 'testDependencies' put: aString
]

{ #category : 'accessing' }
ModestConfiguration >> testExporter [

	^ testExporter
]

{ #category : 'accessing' }
ModestConfiguration >> testExporter: anObject [

	testExporter := anObject
]

{ #category : 'tests' }
ModestConfiguration >> testSuiteReducer [

	^ testSuiteReducer
]

{ #category : 'tests' }
ModestConfiguration >> testSuiteReducer: aTestSuiteReducer [

	testSuiteReducer := aTestSuiteReducer
]

{ #category : 'accessing' }
ModestConfiguration >> traceArgumentsKey [

	^ traceArgumentsKey
]

{ #category : 'accessing' }
ModestConfiguration >> traceArgumentsKey: aString [

	traceArgumentsKey := aString
]

{ #category : 'accessing' }
ModestConfiguration >> traceClassKey [

	^ traceClassKey
]

{ #category : 'accessing' }
ModestConfiguration >> traceClassKey: aString [

	traceClassKey := aString
]

{ #category : 'accessing' }
ModestConfiguration >> traceExtractor [

	^ traceExtractor
]

{ #category : 'accessing' }
ModestConfiguration >> traceExtractor: anObject [

	traceExtractor := anObject
]

{ #category : 'accessing' }
ModestConfiguration >> traceLoader [

	^ traceLoader
]

{ #category : 'accessing' }
ModestConfiguration >> traceLoader: anObject [

	traceLoader := anObject
]

{ #category : 'accessing' }
ModestConfiguration >> traceMethodKey [

	^ traceMethodKey
]

{ #category : 'accessing' }
ModestConfiguration >> traceMethodKey: aString [

	traceMethodKey := aString
]

{ #category : 'accessing' }
ModestConfiguration >> traceReceiverKey [

	^ traceReceiverKey
]

{ #category : 'accessing' }
ModestConfiguration >> traceReceiverKey: aString [

	traceReceiverKey := aString
]

{ #category : 'accessing' }
ModestConfiguration >> traceResultKey [

	^ traceResultKey
]

{ #category : 'accessing' }
ModestConfiguration >> traceResultKey: aString [

	traceResultKey := aString
]

{ #category : 'accessing' }
ModestConfiguration >> traceTransformers [

	^ traceTransformers
]

{ #category : 'accessing' }
ModestConfiguration >> traceTransformers: anObject [

	traceTransformers := anObject
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> tracesDirectory [

	^ tracesDirectory
]

{ #category : 'accessing - other properties' }
ModestConfiguration >> tracesDirectory: aFile [

	tracesDirectory := aFile
]

{ #category : 'accessing' }
ModestConfiguration >> valueExporter [

	^ valueExporter
]

{ #category : 'accessing' }
ModestConfiguration >> valueExporter: anObject [

	valueExporter := anObject
]

{ #category : 'accessing' }
ModestConfiguration >> valueImporter [

	^ valueImporter
]

{ #category : 'accessing' }
ModestConfiguration >> valueImporter: anObject [

	valueImporter := anObject
]
