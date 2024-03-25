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
		'generatedFiles',
		'formatter',
		'sourceDirectory',
		'withSuiteOptimization'
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
	^ self new runAsJob
]

{ #category : #running }
ModestTestGenerator class >> runLocal [

	<script>
	^ self new beLocal runAsJob
]

{ #category : #accessing }
ModestTestGenerator >> beLocal [
	"Whether to get traces locally, otherwise fetch them from a remote server."

	isLocal := true
]

{ #category : #accessing }
ModestTestGenerator >> beWithSuiteOptimization [
	"Whether to run the test suite optimization step."

	withSuiteOptimization := true
]

{ #category : #running }
ModestTestGenerator >> buildUnitTests [
	"Define how to construct the test model from the traces and values."

	"The spans are given from oldest to newest to maintain this order for the generated tests."
	testModel := self newUnitTestImporter fromOpenTelemetrySpans:
		             traceModel allSpans reversed.

	"Make a suite with all generated test cases"
	(testModel newSuiteNamed: 'ModestSuite') cases:
		(testModel allWithType: FamixUTCase)
]

{ #category : #accessing }
ModestTestGenerator >> coverageDirectory [

	^ (self tempDirectory / 'coverage') ensureCreateDirectory
]

{ #category : #running }
ModestTestGenerator >> exportAST [
	"Define how the unit test AST model is exported into actual tests integrated into the tested application."

	self subclassResponsibility
]

{ #category : #accessing }
ModestTestGenerator >> exportDirectory [

	^ self sourceDirectory
]

{ #category : #running }
ModestTestGenerator >> exportUnitTests [
	"Export the unit test model to AST."

	testASTModel := self newUnitTestExporter export: testModel
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

{ #category : #running }
ModestTestGenerator >> formatFiles [

	self formatter formatFiles: generatedFiles
]

{ #category : #accessing }
ModestTestGenerator >> formatter [

	^ formatter ifNil: [ formatter := ModestNilFormatter new ]
]

{ #category : #utilities }
ModestTestGenerator >> generateZip [
	"Make a zip archive of the generated tests."

	| zipName |
	zipName := 'tests.' , DateAndTime now asFileNameCompatibleString
	           , '.zip'.
	LibC resultOfCommand:
		'cd "' , self sourceDirectory pathString , '" && zip ' , zipName
		, ' "' , ('" "' join: (self generatedFiles collect: [ :e |
				  (e relativeTo: self sourceDirectory) pathString ])) , '" && mv '
		, zipName , ' "' , self localDirectory pathString , '"'.
	^ self localDirectory / zipName
]

{ #category : #accessing }
ModestTestGenerator >> generatedFiles [

	^ generatedFiles
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

	isLocal := false.
	withSuiteOptimization := false
]

{ #category : #accessing }
ModestTestGenerator >> libDirectory [

	^ (self localDirectory / 'lib') ensureCreateDirectory
]

{ #category : #accessing }
ModestTestGenerator >> localDirectory [

	^ localDirectory ifNil: [
		  localDirectory := 'pharo-local' asFileReference / 'modest' ]
]

{ #category : #accessing }
ModestTestGenerator >> localDirectory: aPath [

	localDirectory := aPath asFileReference
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
	  / (DateAndTime now truncated asFileNameCompatibleString , '.'
		   , self famixModel name) , 'json'
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

{ #category : #'instance creation' }
ModestTestGenerator >> newUnitTestExporter [
	"Return a specific and configured subclass of FamixUTAbstractExporter."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestTestGenerator >> newUnitTestImporter [

	^ FamixUTImporter new
]

{ #category : #running }
ModestTestGenerator >> optimizeSuite [
	"### Problem
We generate a lot of tests from traces, but we don't know if all of them are relevant.
Multiple tests for the same method may have overlapping coverage, such as adding a user but with a different name.
We want to maximize coverage **AND** minimize the coverage per test, without having redundant tests.
This leads to a combinatorial problem with N tests for each tested method.
We aim to identify the test combination that maximizes both coverage and the number of tests, while excluding redundant tests.

### Solution
For each tested method, obtain the coverage of each of its tests, and of all of their possible combinations.

| combination | instructions | branch | line |
| t1          |         2988 |     30 | 1128 |
| t2          |         2966 |     30 | 1124 |
| t3          |         2981 |     30 | 1128 |
| t1_2        |         2988 |     32 | 1128 |
| t1_3        |         3003 |     34 | 1132 | <- maximal, solution
| t2_3        |         2981 |     32 | 1128 |
| t1_2_3      |         3003 |     34 | 1132 | <- maximal but 2 is redundant

Tools are required to obtain the coverage of each test (t1, t2...), and scripts can be used to merge coverage data to create the combination coverage data (t1_2, t1_3...)."

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
	"Execute the whole unit test generation pipeline."

	self getCodebaseModel.
	self importTraces.
	self importTraceValues.
	self buildUnitTests.
	self exportUnitTests.
	self refactorAST.
	self exportAST.
	withSuiteOptimization ifTrue: [ self optimizeSuite ].
	^ generatedFiles
]

{ #category : #running }
ModestTestGenerator >> runAsJob [

	[ :job |
	job max: (withSuiteOptimization
			 ifTrue: [ 8 ]
			 ifFalse: [ 7 ]).
	job title: 'Running ' , self className.

	job title: 'Getting codebase model...'.
	self getCodebaseModel.
	job increment.

	job title: 'Importing traces...'.
	self importTraces.
	job increment.

	job title: 'Importing trace values...'.
	self importTraceValues.
	job increment.

	job title: 'Building unit test model...'.
	self buildUnitTests.
	job increment.

	job title: 'Building unit test AST...'.
	self exportUnitTests.
	job increment.

	job title: 'Refactoring AST...'.
	self refactorAST.
	job increment.

	job title: 'Exporting tests...'.
	self exportAST.
	job increment.

	withSuiteOptimization ifTrue: [
		job title: 'Optimizing Suite...'.
		self optimizeSuite.
		job increment ].

	job title: self className , ' done!'.
	3 asDuration wait ] asJob run.
	^ generatedFiles
]

{ #category : #accessing }
ModestTestGenerator >> sourceDirectory [

	^ sourceDirectory ifNil: [
		  sourceDirectory := self famixModel ifNotNil: [ :model |
			                     model rootFolder ] ]
]

{ #category : #accessing }
ModestTestGenerator >> tempDirectory [

	^ (self localDirectory / 'temp') ensureCreateDirectory
]

{ #category : #accessing }
ModestTestGenerator >> testASTModel [

	^ testASTModel
]

{ #category : #accessing }
ModestTestGenerator >> testASTModel: aFASTModel [

	testASTModel := aFASTModel
]

{ #category : #accessing }
ModestTestGenerator >> testModel [

	^ testModel
]

{ #category : #accessing }
ModestTestGenerator >> testModel: aFamixUTModel [

	testModel := aFamixUTModel
]

{ #category : #accessing }
ModestTestGenerator >> traceModel [

	^ traceModel
]

{ #category : #accessing }
ModestTestGenerator >> traceModel: aFamixOTModel [

	traceModel := aFamixOTModel
]

{ #category : #accessing }
ModestTestGenerator >> tracesDirectory [

	^ (self localDirectory / 'traces') ensureCreateDirectory
]
