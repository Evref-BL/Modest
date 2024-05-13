Class {
	#name : #ModestHardCodedTestGenerator,
	#superclass : #ModestTestGenerator,
	#instVars : [
		'isLocal',
		'localDirectory',
		'sourceDirectory',
		'codeFormatter'
	],
	#category : #'Modest-TestGenerator'
}

{ #category : #testing }
ModestHardCodedTestGenerator class >> isAbstract [

	^ self == ModestHardCodedTestGenerator
]

{ #category : #running }
ModestHardCodedTestGenerator class >> runLocal [

	<script>
	^ self new beLocal runAsJob
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> beLocal [
	"Whether to get traces locally, otherwise fetch them from a remote server."

	isLocal := true
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> beWithSuiteOptimization [
	"Whether to run the test suite optimization step."

	withSuiteOptimization := true
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> codeFormatter [

	^ codeFormatter ifNil: [ codeFormatter := ModestNilFormatter new ]
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> coverageDirectory [

	^ (self tempDirectory / 'coverage') ensureCreateDirectory
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> exportDirectory [

	^ self sourceDirectory
]

{ #category : #running }
ModestHardCodedTestGenerator >> exportUnitTests [

	testASTModel := self newUnitTestExporter export: testModel
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> famixModel [

	^ famixModel ifNil: [
		  famixModel := MooseModel root detect: [ :model |
			                model name = self famixModelName ] ]
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> famixModel: aFamixModel [

	famixModel := aFamixModel
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> famixModelName [

	self subclassResponsibility
]

{ #category : #utilities }
ModestHardCodedTestGenerator >> generateArchive [
	"Make a zip archive of the generated tests."

	| zipName |
	zipName := 'tests.' , DateAndTime now asFileNameCompatibleString
	           , '.zip'.
	LibC resultOfCommand:
		'cd "' , self sourceDirectory pathString , '" && zip ' , zipName
		, ' "' , ('" "' join: (self generatedContent collect: [ :e |
				  (e relativeTo: self sourceDirectory) pathString ])) , '" && mv '
		, zipName , ' "' , self localDirectory pathString , '"'.
	^ self localDirectory / zipName
]

{ #category : #running }
ModestHardCodedTestGenerator >> getCodebaseModel [
	"Assume the model is already loaded in the image."

	famixModel := MooseModel root detect: [ :model |
		              model name = self famixModelName ].
	entityFinder := self newEntityFinder model: famixModel
]

{ #category : #running }
ModestHardCodedTestGenerator >> importTraceValues [
	"Extract the values from the traces."

	self newTraceValueLinker value: traceModel
]

{ #category : #running }
ModestHardCodedTestGenerator >> importTraces [
	"Import the application traces into a model."

	traceModel := FamixOTelValueModel new.
	OpenTelemetryImporter new
		extractor: self newTraceExtractor;
		loader: (self newTraceLoader model: traceModel);
		transformers: self newTraceTransformers;
		import
]

{ #category : #initialization }
ModestHardCodedTestGenerator >> initialize [

	super initialize.
	isLocal := false
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> libDirectory [

	^ (self localDirectory / 'lib') ensureCreateDirectory
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> localDirectory [

	^ localDirectory ifNil: [
		  localDirectory := 'pharo-local' asFileReference / 'modest' ]
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> localDirectory: aPath [

	localDirectory := aPath asFileReference
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newASTRefactorer [
	"Answer an object capable of doing AST refactorings, such as a subclass of FASTRefactor."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newEntityFinder [
	"Answer an object capable of finding application model elements.
	It should be a FamixEntityFinder or a subclass."

	^ FamixEntityFinder new
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newTraceExtractor [

	^ isLocal
		  ifTrue: [ self newTraceLocalExtractor ]
		  ifFalse: [
		  self newTraceRemoteExtractor outputFilename: self newTraceFilename ]
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newTraceFilename [

	^ self tracesDirectory
	  / (DateAndTime now truncated asFileNameCompatibleString , '.'
		   , self famixModel name) , 'json'
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newTraceLoader [
	"Answer an object capable of loading trace entities from raw trace data.
	It should be a subclass of OTelAbstractLoader, such as OTelZipkinLoader."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newTraceLocalExtractor [
	"Answer an object capable of extracting traces from a local source.
	It should be a subclass of OTelAbstractExtractor, such as OTelJSONFileExtractor."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newTraceRemoteExtractor [
	"Answer an object capable of extracting traces from a remote source.
	It should be a subclass of OTelAbstractExtractor, such as OTelZipkinExtractor."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newTraceTransformers [
	"Answer a collection of objects capable of transforming trace entities.
	They should be a subclass of OTelAbstractTransformer, such as OTelSpanTransformer."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newTraceValueLinker [
	"Return a configured OTelFamixValueLinker."

	self subclassResponsibility
]

{ #category : #'instance creation' }
ModestHardCodedTestGenerator >> newUnitTestExporter [
	"Return a specific and configured subclass of FamixUTAbstractExporter."

	self subclassResponsibility
]

{ #category : #running }
ModestHardCodedTestGenerator >> optimizeSuite [
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
ModestHardCodedTestGenerator >> refactorAST [

	[
	self newASTRefactorer
		model: testASTModel;
		inlineLiterals;
		removeRedundantSetters ]
		on: MessageNotUnderstood
		do: [ :e | self flag: #TODO. e resume ]
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> sourceDirectory [

	^ sourceDirectory ifNil: [
		  sourceDirectory := self famixModel ifNotNil: [ :model |
			                     model rootFolder ] ]
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> testASTModel [

	^ testASTModel
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> testASTModel: aFASTModel [

	testASTModel := aFASTModel
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> testModel [

	^ testModel
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> testModel: aFamixUTModel [

	testModel := aFamixUTModel
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> traceModel [

	^ traceModel
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> traceModel: aFamixOTModel [

	traceModel := aFamixOTModel
]

{ #category : #accessing }
ModestHardCodedTestGenerator >> tracesDirectory [

	^ (self localDirectory / 'traces') ensureCreateDirectory
]
