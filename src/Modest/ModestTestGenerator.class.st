"
I am an abstract test generator.
I use traces, represented by [Famix-OpenTelemetry](https://github.com/moosetechnology/Famix-OpenTelemetry), and the serialized values they contain, represented by [Famix-Value](https://github.com/moosetechnology/Famix-Value), to generate a unit test model represented by [Famix-UnitTest](https://github.com/moosetechnology/Famix-UnitTest).
This model is then exported into test suite ASTs, which can finally be exported into actual unit tests.

My subclasses must define the importers and exporters specific to the target language and libraries.

When running, I generate a report which can be found in the image's `pharo-local/modest/reports` folder by default.
"
Class {
	#name : #ModestTestGenerator,
	#superclass : #Object,
	#instVars : [
		'famixModel',
		'traceModel',
		'testModel',
		'testASTModel',
		'entityFinder',
		'isLocal',
		'localDirectory'
	],
	#category : #'Modest-TestGenerator'
}

{ #category : #testing }
ModestTestGenerator class >> isAbstract [

	^ self == ModestTestGenerator
]

{ #category : #running }
ModestTestGenerator class >> run [

	<script>
	^ self new run
]

{ #category : #running }
ModestTestGenerator class >> runLocal [

	<script>
	^ self new beLocal run
]

{ #category : #accessing }
ModestTestGenerator >> beLocal [
	"Whether to get traces locally, otherwise fetch them from a remote server."

	isLocal := true
]

{ #category : #running }
ModestTestGenerator >> buildUnitTests [
	"Define how to construct the test model from the traces and values."

	testModel := FamixUTImporter new fromOpenTelemetrySpans:
		             traceModel allSpans.

	"Make a suite with all generated test cases"
	(testModel newSuiteNamed: 'ModestSuite') cases:
		(testModel allWithType: FamixUTCase)
]

{ #category : #running }
ModestTestGenerator >> exportAST [
	"Define how the unit test AST model is exported into actual tests integrated into the tested application."

	self subclassResponsibility
]

{ #category : #running }
ModestTestGenerator >> exportUnitTests [
	"Export the unit test model to AST."

	self subclassResponsibility
]

{ #category : #accessing }
ModestTestGenerator >> famixModel [

	^ famixModel
]

{ #category : #accessing }
ModestTestGenerator >> famixModel: aFamixModel [

	famixModel := aFamixModel
]

{ #category : #accessing }
ModestTestGenerator >> famixModelName [

	self subclassResponsibility
]

{ #category : #accessing }
ModestTestGenerator >> formattersDirectory [

	^ self localDirectory , 'formatters/'
]

{ #category : #running }
ModestTestGenerator >> getCodebaseModel [
	"Assume the model is already loaded in the image."

	famixModel := MooseModel root detect: [ :model |
		              model name = self famixModelName ].
	entityFinder := self newEntityFinder model: famixModel
]

{ #category : #running }
ModestTestGenerator >> importTraceValues [
	"Extract the values from the traces."

	self newTraceValueLinker value: traceModel
]

{ #category : #running }
ModestTestGenerator >> importTraces [
	"Import the application traces into a model."

	traceModel := FamixOTelValueModel new.
	OpenTelemetryImporter new
		extractor: self newTraceExtractor;
		loader: (self newTraceLoader model: traceModel);
		transformers: self newTraceTransformers;
		import
]

{ #category : #initialization }
ModestTestGenerator >> initialize [

	isLocal := false
]

{ #category : #accessing }
ModestTestGenerator >> localDirectory [

	^ localDirectory ifNil: [ localDirectory := 'pharo-local/modest/' ]
]

{ #category : #accessing }
ModestTestGenerator >> localDirectory: aPathString [

	localDirectory := aPathString
]

{ #category : #'instance creation' }
ModestTestGenerator >> newASTRefactorer [
	"Answer an object capable of doing AST refactorings, such as a subclass of FASTRefactor."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestTestGenerator >> newEntityFinder [
	"Answer an object capable of finding application model elements.
	It should be a FamixEntityFinder or a subclass."

	^ FamixEntityFinder new
]

{ #category : #'instance creation' }
ModestTestGenerator >> newTraceExtractor [

	^ isLocal
		  ifTrue: [ self newTraceLocalExtractor ]
		  ifFalse: [
		  self newTraceRemoteExtractor outputFilename: self newTraceFilename ]
]

{ #category : #'instance creation' }
ModestTestGenerator >> newTraceFilename [

	^ self tracesDirectory
	  , (DateAndTime now truncated asString replaceAll: $: with: $_)
	  , '-' , self famixModel name , '.json'
]

{ #category : #'instance creation' }
ModestTestGenerator >> newTraceLoader [
	"Answer an object capable of loading trace entities from raw trace data.
	It should be a subclass of OTelAbstractLoader, such as OTelZipkinLoader."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestTestGenerator >> newTraceLocalExtractor [
	"Answer an object capable of extracting traces from a local source.
	It should be a subclass of OTelAbstractExtractor, such as OTelJSONFileExtractor."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestTestGenerator >> newTraceRemoteExtractor [
	"Answer an object capable of extracting traces from a remote source.
	It should be a subclass of OTelAbstractExtractor, such as OTelZipkinExtractor."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestTestGenerator >> newTraceTransformers [
	"Answer a collection of objects capable of transforming trace entities.
	They should be a subclass of OTelAbstractTransformer, such as OTelSpanTransformer."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestTestGenerator >> newTraceValueLinker [
	"Return a configured OTelFamixValueLinker."

	self subclassResponsibility
]

{ #category : #running }
ModestTestGenerator >> refactorAST [

	self newASTRefactorer
		model: testASTModel;
		inlineLiterals;
		removeRedundantSetters
]

{ #category : #running }
ModestTestGenerator >> run [

	self getCodebaseModel.
	self importTraces.
	self importTraceValues.
	self buildUnitTests.
	self exportUnitTests.
	self refactorAST.
	^ self exportAST
]

{ #category : #accessing }
ModestTestGenerator >> tracesDirectory [

	^ self localDirectory , 'traces/'
]
