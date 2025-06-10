Class {
	#name : 'ModestConfigurableTestGenerator',
	#superclass : 'ModestTestGenerator',
	#instVars : [
		'configuration'
	],
	#category : 'Modest-TestGenerator',
	#package : 'Modest',
	#tag : 'TestGenerator'
}

{ #category : 'running' }
ModestConfigurableTestGenerator class >> runFrom: aConfigurationFile [

	^ self new
		  configuration:
			  (ModestConfigurationReader readConfigurationFromFile:
					   aConfigurationFile);
		  runWithLogging
]

{ #category : 'running' }
ModestConfigurableTestGenerator class >> runWith: aConfiguration [

	^ self new
		  configuration: aConfiguration;
		  runWithLogging
]

{ #category : 'utilities' }
ModestConfigurableTestGenerator >> clearCaches [

	configuration famixModel allTypes do: [ :type |
		type entityCache empty ]
]

{ #category : 'accessing' }
ModestConfigurableTestGenerator >> codeFormatter [

	^ configuration codeFormatter ifNil: [ ModestNilFormatter new ]
]

{ #category : 'accessing' }
ModestConfigurableTestGenerator >> configuration [

	^ configuration ifNil: [
		  configuration := ModestConfigurationReader readConfiguration ]
]

{ #category : 'accessing' }
ModestConfigurableTestGenerator >> configuration: aConfiguration [

	configuration := aConfiguration
]

{ #category : 'running' }
ModestConfigurableTestGenerator >> exportAST [

	configuration codeExporter ifNotNil: [ :codeExporter |
		generatedContent := codeExporter exportFor: self ]

	"Is this optional?
	ModestConfigurationError signal:
		'Exporting AST for the `' , configuration language
		, '` language is not (yet?) supported.'"
]

{ #category : 'running' }
ModestConfigurableTestGenerator >> exportUnitTests [

	testASTModel := configuration testExporter export: testModel
]

{ #category : 'utilities' }
ModestConfigurableTestGenerator >> generateArchive [
	"Make a zip archive of the generated tests."

	| zipName |
	zipName := 'tests.' , DateAndTime now asFileNameCompatibleString
	           , '.zip'.
	LibC runCommand:
		'cd "' , configuration exportDirectory pathString , '" && zip '
		, zipName , ' "'
		, ('" "' join: (self generatedContent collect: [ :e |
					  (e relativeTo: configuration exportDirectory) pathString ]))
		, '" && mv ' , zipName , ' "'
		, configuration localDirectory pathString , '"'.
	^ configuration localDirectory / zipName
]

{ #category : 'running' }
ModestConfigurableTestGenerator >> getCodebaseModel [

	famixModel := configuration famixModel
]

{ #category : 'running' }
ModestConfigurableTestGenerator >> importTraceValues [

	OTelFamixValueLinker new
		importer: configuration valueImporter;
		classKey: configuration traceClassKey;
		methodKey: configuration traceMethodKey;
		receiverKey: configuration traceReceiverKey;
		argsKey: configuration traceArgumentsKey;
		resultKey: configuration traceResultKey;
		value: traceModel
]

{ #category : 'running' }
ModestConfigurableTestGenerator >> importTraces [

	traceModel := FamixOTelValueModel new.
	OpenTelemetryImporter new
		extractor: configuration traceExtractor;
		loader: (configuration traceLoader model: traceModel);
		transformers: configuration traceTransformers;
		import
]

{ #category : 'accessing' }
ModestConfigurableTestGenerator >> localDirectory [

	^ configuration localDirectory
]

{ #category : 'running' }
ModestConfigurableTestGenerator >> reduceSuite [

	configuration testSuiteReducer ifNotNil: [ :reducer |
		reducer reduceTestSuiteFor: self ]
]

{ #category : 'running' }
ModestConfigurableTestGenerator >> refactorAST [

	configuration refactorer ifNotNil: [ :refactorer |
		[
		refactorer
			model: testASTModel;
			inlineLiterals;
			removeRedundantSetters ]
			on: MessageNotUnderstood
			do: [ :e | "Once upon a time (before 2024-05-13),
				FAST(Java?) changed and things broke beyond my understanding.
				But somehow, ignoring it seems to work regardless... (2025-05-28)"
				self flag: #TODO. "investigate :)"
				e resume ] ]
]
