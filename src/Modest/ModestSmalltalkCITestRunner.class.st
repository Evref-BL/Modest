"
I am a test runner for Pharo.

SmalltalkCI is used to run the tests.

I can also obtain atomic coverage and export a coverage report is exported for each test method.
To do so, I modify the SmalltalkCI pipeline:
1. I set `ModestTestExecutionEnvironment` as the current execution environment, which gives access to the `runTestCase:` hook.
2. An anonymous subclass of the `SmalltalkCI currentPlatform` is created to override its `codeCoverageClass` class-side method. This method creates an anonymous subclass of the coverage class to override its `initialize` method. This method registers itself, a kind of `SCICodeCoverage`, on the current execution environment.
3. When `runTestCase:` is called, execute the case (a single test method) and export its coverage using the coverage handler from the previous step.
"
Class {
	#name : 'ModestSmalltalkCITestRunner',
	#superclass : 'ModestAbstractTestRunner',
	#category : 'Modest-SuiteReduction',
	#package : 'Modest',
	#tag : 'SuiteReduction'
}

{ #category : 'coverage' }
ModestSmalltalkCITestRunner >> actualRunnerClass [
	"SmalltalkCI uses different runners/helpers to execute the tests.
	In order to export atomic coverage, we need access to the CodeCoverage class.
	However, there's no reference to it, so we have to insert some shims to store it
	in the execution environment that runs the test cases with #runTestCase:"

	| runnerClass |
	"Get the SmalltalkCI test runner class and subclass it"
	runnerClass := SmalltalkCI platformClass newAnonymousSubclass.

	"#newInstance asks for the platformClass again, use self to keep the anonymous class"
	runnerClass class compile: 'newInstance
	^ self basicNew initialize'.

	"When getting the codeCoverageClass, return a subclass that will register a new instance
	on the CurrentExecutionEnvironment, which will be our own test environment.
	Use `superclass new` to create an instance of the original class."
	runnerClass class compile: 'codeCoverageClass
	^ super codeCoverageClass newAnonymousSubclass class
		compile: ''new
			| instance |
			instance := superclass new.
			CurrentExecutionEnvironment value codeCoverage: instance.
			^ instance'';
		instanceSide'.

	^ runnerClass
]

{ #category : 'coverage' }
ModestSmalltalkCITestRunner >> generateCISpecFor: aTestGenerator [
	"SmalltalkCI is configured using a so-called spec file in STON format.
	List the test classes to run, and the classes to cover.
	Coverage requires Tonel class files, exported to a `src` directory."

	| testClasses testedClasses |
	testClasses := (String new: 100) writeStream.
	testedClasses := (String new: 100) writeStream.

	aTestGenerator testASTModel mapping do: [ :classData |
		| testClass |
		testClass := classData at: #model.
		testClasses << ' #' << testClass name.
		testedClasses << ' #' << testClass testedClass name ].

	self specFile ensureCreateFile writeStreamDo: [ :s |
		s << 'SmalltalkCISpec {
	#loading : [
		SCIMetacelloLoadSpec {
			#directory : ''src''
		}
	],
	#testing : {
		#classes : [' << testClasses contents << ' ],
		#coverage : {
			#classes : [' << testedClasses contents << ' ],
			#format : #lcov
		}
	}
}' ]
]

{ #category : 'coverage' }
ModestSmalltalkCITestRunner >> generateTestCoverageFor: aTestGenerator [
	"Execute generated tests with SmalltalkCI and export a coverage report for each test method."

	| ciDir runner environment |
	runner := self actualRunnerClass.
	environment := ModestAtomicTestExecutionEnvironment exportingTo:
		               self buildDirectory.

	"Swap the SmalltalkCI build directory during the run"
	ciDir := OSEnvironment current at: 'SCIII_BUILD' ifAbsent: [  ].
	[
	OSEnvironment current
		at: 'SCIII_BUILD'
		put: (self buildDirectory / 'ci') pathString.

	"Read class comment for full explanation on getting atomic coverage"
	EpMonitor disableDuring: [ "Maybe creating anonymous subclasses is triggering Epicea events?
		The problem is that they happen in a TestEnvironment with no testCase yet, so it signals."
		environment beActiveDuring: [ runner test: self specFile pathString ] ] ]
		ensure: [
			ciDir
				ifNil: [ OSEnvironment current removeKey: 'SCIII_BUILD' ]
				ifNotNil: [ OSEnvironment current at: 'SCIII_BUILD' put: ciDir ] ]
]

{ #category : 'running' }
ModestSmalltalkCITestRunner >> prepareToRunFor: aTestGenerator [
	"Tonel-out covered classes, and generate SmalltalkCI spec file."

	self buildDirectory: aTestGenerator configuration coverageDirectory.
	self tonelRepositoryFor: aTestGenerator.
	self generateCISpecFor: aTestGenerator
]

{ #category : 'coverage' }
ModestSmalltalkCITestRunner >> specFile [

	^ self buildDirectory / 'ci/.smalltalk.ston'
]

{ #category : 'coverage' }
ModestSmalltalkCITestRunner >> tonelRepositoryFor: aTestGenerator [
	"Create a Tonel repository containing the tested classes."

	| sourceDirectory |
	sourceDirectory := self buildDirectory / 'ci/src'.

	(sourceDirectory / IceRepositoryProperties propertiesFileName)
		ensureCreateFile writeStreamDo: [ :ws |
		ws nextPutAll: '{#format : #tonel}' ].

	(aTestGenerator testModel allWithType: FamixUTCase) do: [ :testClass |
		| testedClass |
		testedClass := testClass testedClass sourceAnchor pharoEntity.

		(sourceDirectory / testedClass packageName / testedClass name
		 , 'class.st') ensureCreateFile writeStreamDo: [ :ws |
			TonelWriter new exportClass: testedClass on: ws ] ]
]
