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
		'localDirectory',
		'report'
	],
	#category : #Modest
}

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
ModestTestGenerator >> exportUnitTests [

	"Define how the unit test AST model is exported into actual tests integrated into the tested application."

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
ModestTestGenerator >> formattersDirectory [

	^ self localDirectory , 'formatters/'
]

{ #category : #importing }
ModestTestGenerator >> importTraces [

	traceModel := FamixOTelValueModel new.
	OpenTelemetryImporter new
		extractor: self newTraceExtractor;
		loader: (self newTraceLoader model: traceModel);
		transformers: self newTraceTransformers;
		import;
		reportOn: report
]

{ #category : #initialization }
ModestTestGenerator >> initialize [

	entityFinder := self newEntityFinder model: self famixModel.
	isLocal := false.
	report := ModestReport about: self
]

{ #category : #accessing }
ModestTestGenerator >> localDirectory [

	^ localDirectory ifNil: [ localDirectory := 'pharo-local/modest/' ]
]

{ #category : #accessing }
ModestTestGenerator >> localDirectory: aPathString [

	localDirectory := aPathString
]

{ #category : #transforming }
ModestTestGenerator >> makeUnitTests [

	"Define how to construct the test model from the traces and values."

	self subclassResponsibility
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
ModestTestGenerator >> newLocalTraceExtractor [

	"Answer an object capable of extracting traces from a local source.
	It should be a subclass of OTelAbstractExtractor, such as OTelJSONFileExtractor."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestTestGenerator >> newRemoteTraceExtractor [

	"Answer an object capable of extracting traces from a remote source.
	It should be a subclass of OTelAbstractExtractor, such as OTelZipkinExtractor."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestTestGenerator >> newTraceExtractor [

	^ isLocal
		  ifTrue: [ self newLocalTraceExtractor ]
		  ifFalse: [ 
		  self newRemoteTraceExtractor outputFilename: self newTraceFilename ]
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
ModestTestGenerator >> newTraceTransformers [

	"Answer a collection of objects capable of transforming trace entities.
	They should be a subclass of OTelAbstractTransformer, such as OTelSpanTransformer.
	Most importantly, it one of these transformers must be an instance of OTelFamixValueLinker."

	self subclassResponsibility
]

{ #category : #transforming }
ModestTestGenerator >> refactorAST [

	self newASTRefactorer
		model: testASTModel;
		inlineLiterals;
		removeRedundantSetters
]

{ #category : #running }
ModestTestGenerator >> run [

	| result |
	report start.
	self importTraces.
	self makeUnitTests.
	self refactorAST.
	result := self exportUnitTests.
	report end.
	^ result
]

{ #category : #accessing }
ModestTestGenerator >> tracesDirectory [

	^ self localDirectory , 'traces/'
]
