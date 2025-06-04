Class {
	#name : 'ModestHardCodedTestGenerator',
	#superclass : 'ModestTestGenerator',
	#instVars : [
		'isLocal',
		'localDirectory',
		'sourceDirectory',
		'entityFinder',
		'codeFormatter',
		'withSuiteReduction'
	],
	#category : 'Modest-TestGenerator',
	#package : 'Modest',
	#tag : 'TestGenerator'
}

{ #category : 'testing' }
ModestHardCodedTestGenerator class >> isAbstract [

	^ self == ModestHardCodedTestGenerator
]

{ #category : 'running' }
ModestHardCodedTestGenerator class >> runLocal [

	<script>
	^ self new beLocal runWithLogging
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> beLocal [
	"Whether to get traces locally, otherwise fetch them from a remote server."

	isLocal := true
]

{ #category : 'initialization' }
ModestHardCodedTestGenerator >> beWithSuiteReduction [
	"Whether to run the test suite optimization step."

	withSuiteReduction := true
]

{ #category : 'utilities' }
ModestHardCodedTestGenerator >> clearCaches [

	famixModel allTypes do: [ :type | type entityCache empty ]
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> codeFormatter [

	^ codeFormatter ifNil: [ codeFormatter := ModestNilFormatter new ]
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> coverageDirectory [

	^ (self tempDirectory / 'coverage') ensureCreateDirectory
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> exportDirectory [

	^ self sourceDirectory
]

{ #category : 'running' }
ModestHardCodedTestGenerator >> exportUnitTests [

	testASTModel := self newUnitTestExporter export: testModel
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> famixModel [

	^ famixModel ifNil: [
		  famixModel := MooseModel root detect: [ :model |
			                model name = self famixModelName ] ]
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> famixModelName [

	self subclassResponsibility
]

{ #category : 'utilities' }
ModestHardCodedTestGenerator >> generateArchive [
	"Make a zip archive of the generated tests."

	| zipName |
	zipName := 'tests.' , DateAndTime now asFileNameCompatibleString
	           , '.zip'.
	LibC runCommand:
		'cd "' , self exportDirectory pathString , '" && zip ' , zipName
		, ' "' , ('" "' join: (self generatedContent collect: [ :e |
				  (e relativeTo: self exportDirectory) pathString ])) , '" && mv '
		, zipName , ' "' , self localDirectory pathString , '"'.
	^ self localDirectory / zipName
]

{ #category : 'running' }
ModestHardCodedTestGenerator >> getCodebaseModel [
	"Assume the model is already loaded in the image."

	famixModel := MooseModel root detect: [ :model |
		              model name = self famixModelName ].
	entityFinder := self newEntityFinder model: famixModel
]

{ #category : 'running' }
ModestHardCodedTestGenerator >> importTraceValues [
	"Extract the values from the traces."

	self newTraceValueLinker value: traceModel
]

{ #category : 'running' }
ModestHardCodedTestGenerator >> importTraces [

	traceModel := FamixOTelValueModel new.
	OpenTelemetryImporter new
		extractor: self newTraceExtractor;
		loader: (self newTraceLoader model: traceModel);
		transformers: self newTraceTransformers;
		import
]

{ #category : 'initialization' }
ModestHardCodedTestGenerator >> initialize [

	super initialize.
	withSuiteReduction := false.
	isLocal := false
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> libDirectory [

	^ (self localDirectory / 'lib') ensureCreateDirectory
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> localDirectory [

	^ localDirectory ifNil: [
		  localDirectory := 'pharo-local' asFileReference / 'modest' ]
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> localDirectory: aPath [

	localDirectory := aPath asFileReference
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newASTRefactorer [
	"Answer an object capable of doing AST refactorings, such as a subclass of FASTRefactor."

	self subclassResponsibility
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newEntityFinder [
	"Answer an object capable of finding application model elements.
	It should be a FamixEntityFinder or a subclass."

	^ FamixEntityFinder new
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newTraceExtractor [

	^ isLocal
		  ifTrue: [ self newTraceLocalExtractor ]
		  ifFalse: [
		  self newTraceRemoteExtractor outputFilename: self newTraceFilename ]
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newTraceFilename [

	^ self tracesDirectory
	  / (DateAndTime now truncated asFileNameCompatibleString , '.'
		   , self famixModel name) , 'json'
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newTraceLoader [
	"Answer an object capable of loading trace entities from raw trace data.
	It should be a subclass of OTelAbstractLoader, such as OTelZipkinLoader."

	self subclassResponsibility
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newTraceLocalExtractor [
	"Answer an object capable of extracting traces from a local source.
	It should be a subclass of OTelAbstractExtractor, such as OTelJSONFileExtractor."

	self subclassResponsibility
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newTraceRemoteExtractor [
	"Answer an object capable of extracting traces from a remote source.
	It should be a subclass of OTelAbstractExtractor, such as OTelZipkinExtractor."

	self subclassResponsibility
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newTraceTransformers [
	"Answer a collection of objects capable of transforming trace entities.
	They should be a subclass of OTelAbstractTransformer, such as OTelSpanTransformer."

	self subclassResponsibility
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newTraceValueLinker [
	"Return a configured OTelFamixValueLinker."

	self subclassResponsibility
]

{ #category : 'instance creation' }
ModestHardCodedTestGenerator >> newUnitTestExporter [
	"Return a specific and configured subclass of FamixUTAbstractExporter."

	self subclassResponsibility
]

{ #category : 'running' }
ModestHardCodedTestGenerator >> refactorAST [

	[
	self newASTRefactorer
		model: testASTModel;
		inlineLiterals;
		removeRedundantSetters ]
		on: MessageNotUnderstood
		do: [ :e | self flag: #TODO. e resume ]
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> sourceDirectory [

	^ sourceDirectory ifNil: [
		  sourceDirectory := self famixModel ifNotNil: [ :model |
			                     model rootFolder ] ]
]

{ #category : 'accessing' }
ModestHardCodedTestGenerator >> tracesDirectory [

	^ (self localDirectory / 'traces') ensureCreateDirectory
]
