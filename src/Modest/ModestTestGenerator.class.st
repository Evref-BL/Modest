"
I am an abstract test generator.
I use traces, represented by [Famix-OpenTelemetry](https://github.com/moosetechnology/Famix-OpenTelemetry), and the serialized values they contain, represented by [Famix-Value](https://github.com/moosetechnology/Famix-Value), to generate a unit test model represented by [Famix-UnitTest](https://github.com/moosetechnology/Famix-UnitTest).
This model is then exported into test suite ASTs, which can finally be exported into actual unit tests.

My subclasses must define the importers and exporters specific to the target language and libraries.
"
Class {
	#name : 'ModestTestGenerator',
	#superclass : 'Object',
	#instVars : [
		'famixModel',
		'traceModel',
		'testModel',
		'testASTModel',
		'generatedContent'
	],
	#category : 'Modest-TestGenerator',
	#package : 'Modest',
	#tag : 'TestGenerator'
}

{ #category : 'testing' }
ModestTestGenerator class >> isAbstract [

	^ self == ModestTestGenerator
]

{ #category : 'running' }
ModestTestGenerator class >> run [

	<script>
	^ self new runWithLogging
]

{ #category : 'running' }
ModestTestGenerator >> buildUnitTests [

	testModel := FamixUTImporter new fromOpenTelemetrySpans:
		             traceModel allSpans.

	"Make a suite with all generated test cases"
	(testModel newSuiteNamed: 'ModestSuite') cases:
		(testModel allWithType: FamixUTCase)
]

{ #category : 'running' }
ModestTestGenerator >> cleanUp [
	"Clean up after the tests have been generated."

	self tempDirectory deleteAll
]

{ #category : 'utilities' }
ModestTestGenerator >> clearCaches [
	"Some properties for test generation are cached in the Famix entities.
	Call this method to clear these caches.
	This is only necessary if the computation for one of these properties has changed."

	self subclassResponsibility
]

{ #category : 'accessing' }
ModestTestGenerator >> codeFormatter [
	"By default, do not format."

	^ ModestNilFormatter new
]

{ #category : 'accessing' }
ModestTestGenerator >> configuration [
	"Allows configuration to be hard-coded as methods in subclasses."

	^ self
]

{ #category : 'running' }
ModestTestGenerator >> exportAST [

	self subclassResponsibility
]

{ #category : 'running' }
ModestTestGenerator >> exportUnitTests [
	"Export the unit test model to AST."

	self subclassResponsibility
]

{ #category : 'accessing' }
ModestTestGenerator >> famixModel [

	^ famixModel
]

{ #category : 'accessing' }
ModestTestGenerator >> famixModel: aFamixModel [

	famixModel := aFamixModel
]

{ #category : 'running' }
ModestTestGenerator >> formatTestCode [

	self codeFormatter formatFiles: generatedContent
]

{ #category : 'accessing' }
ModestTestGenerator >> generatedContent [

	^ generatedContent
]

{ #category : 'running' }
ModestTestGenerator >> getCodebaseModel [

	self subclassResponsibility
]

{ #category : 'running' }
ModestTestGenerator >> importTraceValues [

	self subclassResponsibility
]

{ #category : 'running' }
ModestTestGenerator >> importTraces [
	"Import the application traces into a model."

	self subclassResponsibility
]

{ #category : 'accessing' }
ModestTestGenerator >> localDirectory [

	self subclassResponsibility
]

{ #category : 'running' }
ModestTestGenerator >> reduceSuite [
	"### Problem
We generate a lot of tests from traces, but we don't know if all of them are relevant.
Multiple tests for the same method may have overlapping coverage, such as adding a user but with a different name.
We want to maximize coverage **AND** minimize the coverage per test, without having redundant tests.
This leads to a combinatorial problem with N tests for each tested method.
We aim to identify the test combination that maximizes both coverage and the number of tests, while excluding redundant tests.

### Solution
For each tested method, obtain the coverage of each of its tests, and of all of their combinations.

| combination | instructions | branch | line |
| t1          |         2988 |     30 | 1128 |
| t2          |         2966 |     30 | 1124 |
| t3          |         2981 |     30 | 1128 |
| t1_2        |         2988 |     32 | 1128 |
| t1_3        |         3003 |     34 | 1132 | <- maximal, solution
| t2_3        |         2981 |     32 | 1128 |
| t1_2_3      |         3003 |     34 | 1132 | <- maximal but 2 is redundant

Tools are required to obtain the coverage of each test (t1, t2, t3).
Scripts can be used to merge coverage data to create the combination coverage data (t1_2, t1_3, t2_3, t1_2_3)."

	self subclassResponsibility
]

{ #category : 'running' }
ModestTestGenerator >> refactorAST [

	self subclassResponsibility
]

{ #category : 'running' }
ModestTestGenerator >> run [
	"Execute the whole unit test generation pipeline."

	self getCodebaseModel.
	self importTraces.
	self importTraceValues.
	self buildUnitTests.
	self exportUnitTests.
	self refactorAST.
	self exportAST.
	self reduceSuite.
	self cleanUp
]

{ #category : 'running' }
ModestTestGenerator >> runWithLogging [

	TinyCurrentLogger value
		ensureFileLoggerNamed: 'modest.log';
		clearLog;
		record: 'Running ' , self className.

	'Getting codebase model...' record.
	self getCodebaseModel.

	'Importing traces...' record.
	self importTraces.

	self
		execute: [ self importTraceValues ]
		recordedAs: 'Importing trace values...'.

	'Building unit test model...' record.
	self buildUnitTests.

	self
		execute: [ self exportUnitTests ]
		recordedAs: 'Building unit test AST...'.

	'Refactoring AST...' record.
	self refactorAST.

	'Exporting tests...' record.
	self exportAST.

	self execute: [ self reduceSuite ] recordedAs: 'Reducing Suite...'.

	'Cleaning up...' record.
	self cleanUp.

	'All done!' record
]

{ #category : 'accessing' }
ModestTestGenerator >> tempDirectory [

	^ (self localDirectory / 'temp') ensureCreateDirectory
]

{ #category : 'accessing' }
ModestTestGenerator >> testASTModel [

	^ testASTModel
]

{ #category : 'accessing' }
ModestTestGenerator >> testASTModel: aFASTModel [

	testASTModel := aFASTModel
]

{ #category : 'accessing' }
ModestTestGenerator >> testModel [

	^ testModel
]

{ #category : 'accessing' }
ModestTestGenerator >> testModel: aFamixUTModel [

	testModel := aFamixUTModel
]

{ #category : 'accessing' }
ModestTestGenerator >> traceModel [

	^ traceModel
]

{ #category : 'accessing' }
ModestTestGenerator >> traceModel: aFamixOTModel [

	traceModel := aFamixOTModel
]
