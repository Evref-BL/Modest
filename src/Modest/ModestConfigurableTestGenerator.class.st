Class {
	#name : #ModestConfigurableTestGenerator,
	#superclass : #ModestTestGenerator,
	#instVars : [
		'configuration'
	],
	#category : #'Modest-TestGenerator'
}

{ #category : #running }
ModestConfigurableTestGenerator class >> runWith: aConfigurationFile [

	^ self new
		  configuration:
			  (ModestConfigurationReader readConfigurationFromFile:
					   aConfigurationFile);
		  runAsJob
]

{ #category : #accessing }
ModestConfigurableTestGenerator >> codeFormatter [

	^ configuration codeFormatter ifNil: [ ModestNilFormatter new ]
]

{ #category : #accessing }
ModestConfigurableTestGenerator >> configuration [

	^ configuration ifNil: [
		  configuration := ModestConfigurationReader readConfiguration ]
]

{ #category : #accessing }
ModestConfigurableTestGenerator >> configuration: aConfiguration [

	configuration := aConfiguration
]

{ #category : #running }
ModestConfigurableTestGenerator >> exportAST [

	configuration language = 'java' ifTrue: [
		^ self exportJavaASTTo: configuration exportDirectory ].
	ModestConfigurationError signal:
		'Exporting AST for the `' , configuration language
		, '` language is not (yet?) supported.'
]

{ #category : #running }
ModestConfigurableTestGenerator >> exportUnitTests [

	testASTModel := configuration testExporter export: testModel
]

{ #category : #utilities }
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

{ #category : #running }
ModestConfigurableTestGenerator >> getCodebaseModel [

	famixModel := configuration famixModel
]

{ #category : #running }
ModestConfigurableTestGenerator >> importTraceValues [

	OTelFamixValueLinker new
		importer: configuration valueImporter;
		classKey: configuration traceClassKey;
		methodKey: configuration traceMethodKey;
		argsKey: configuration traceArgumentsKey;
		resultKey: configuration traceResultKey;
		value: traceModel
]

{ #category : #running }
ModestConfigurableTestGenerator >> importTraces [

	traceModel := FamixOTelValueModel new.
	OpenTelemetryImporter new
		extractor: configuration traceExtractor;
		loader: (configuration traceLoader model: traceModel);
		transformers: configuration traceTransformers;
		import
]

{ #category : #accessing }
ModestConfigurableTestGenerator >> localDirectory [

	^ configuration localDirectory
]

{ #category : #running }
ModestConfigurableTestGenerator >> refactorAST [

	configuration refactorer ifNotNil: [ :refactorer |
		[
		refactorer
			model: testASTModel;
			inlineLiterals;
			removeRedundantSetters ]
			on: MessageNotUnderstood
			do: [ :e |
				self flag: #TODO.
				e resume ] ]
]
