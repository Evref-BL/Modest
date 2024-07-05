"
I am an abstract test generator.
I use traces, represented by [Famix-OpenTelemetry](https://github.com/moosetechnology/Famix-OpenTelemetry), and the serialized values they contain, represented by [Famix-Value](https://github.com/moosetechnology/Famix-Value), to generate a unit test model represented by [Famix-UnitTest](https://github.com/moosetechnology/Famix-UnitTest).
This model is then exported into test suite ASTs, which can finally be exported into actual unit tests.

My subclasses must define the importers and exporters specific to the target language and libraries.
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
		'withSuiteOptimization',
		'generatedContent'
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
ModestTestGenerator >> buildUnitTests [

	testModel := FamixUTImporter new fromOpenTelemetrySpans:
		             traceModel allSpans.

	"Make a suite with all generated test cases"
	(testModel newSuiteNamed: 'ModestSuite') cases:
		(testModel allWithType: FamixUTCase)
]

{ #category : #running }
ModestTestGenerator >> cleanUp [
	"Clean up after the tests have been generated."

	self tempDirectory deleteAll
]

{ #category : #accessing }
ModestTestGenerator >> codeFormatter [
	"By default, do not format."

	^ ModestNilFormatter new
]

{ #category : #running }
ModestTestGenerator >> exportAST [

	self subclassResponsibility
]

{ #category : #exporting }
ModestTestGenerator >> exportJavaASTTo: exportDirectory [

	generatedContent := (testASTModel allWithType:
		                     FASTJavaCompilationUnit) collect: [ :ast |
		                    | file contents |
		                    file := (exportDirectory
		                             /
			                             (ast packageDeclaration qualifiedName
				                              name copyReplaceAll: '.' with: '/')
		                             / ast classDeclarations first name
		                             , 'java') ensureDelete ensureCreateFile.
		                    contents := FASTJavaExportVisitor new export:
			                                ast.
		                    file writeStreamDo: [ :stream |
			                    stream nextPutAll: contents ].
		                    file ].
	self formatTestCode
]

{ #category : #running }
ModestTestGenerator >> exportUnitTests [
	"Export the unit test model to AST."

	self subclassResponsibility
]

{ #category : #running }
ModestTestGenerator >> formatTestCode [

	self codeFormatter formatFiles: generatedContent
]

{ #category : #accessing }
ModestTestGenerator >> generatedContent [

	^ generatedContent
]

{ #category : #running }
ModestTestGenerator >> getCodebaseModel [

	self subclassResponsibility
]

{ #category : #running }
ModestTestGenerator >> importTraceValues [

	self subclassResponsibility
]

{ #category : #running }
ModestTestGenerator >> importTraces [

self halt.

	traceModel := FamixOTelValueModel new.
	OpenTelemetryImporter new
		extractor: self newTraceExtractor;
		loader: (self newTraceLoader model: traceModel);
		transformers: self newTraceTransformers;
		import
]

{ #category : #initialization }
ModestTestGenerator >> initialize [

	withSuiteOptimization := false
]

{ #category : #accessing }
ModestTestGenerator >> localDirectory [

	self subclassResponsibility
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

{ #category : #running }
ModestTestGenerator >> refactorAST [

	self subclassResponsibility
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
	self cleanUp
]

{ #category : #running }
ModestTestGenerator >> runAsJob [

	[ :mainJob |
	[ :job |
	job title: 'Getting codebase model...'.
	self getCodebaseModel.
	mainJob increment.

	job title: 'Importing traces...'.
	self importTraces.
	mainJob increment.

	job title: 'Importing trace values...'.
	self importTraceValues.
	mainJob increment.

	job title: 'Building unit test model...'.
	self buildUnitTests.
	mainJob increment.

	job title: 'Building unit test AST...'.
	self exportUnitTests.
	mainJob increment.

	job title: 'Refactoring AST...'.
	self refactorAST.
	mainJob increment.

	job title: 'Exporting tests...'.
	self exportAST.
	mainJob increment.

	withSuiteOptimization ifTrue: [
			job title: 'Optimizing Suite...'.
			self optimizeSuite.
			mainJob increment ].

	job title: 'Cleaning up...'.
	self cleanUp.
	mainJob increment ] asJob run ] asJob
		title: 'Running ' , self className;
		max: (withSuiteOptimization
				 ifTrue: [ 9 ]
				 ifFalse: [ 8 ]);
		run
]

{ #category : #accessing }
ModestTestGenerator >> tempDirectory [

	^ (self localDirectory / 'temp') ensureCreateDirectory
]
