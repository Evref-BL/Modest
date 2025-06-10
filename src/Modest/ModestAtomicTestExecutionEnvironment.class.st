Class {
	#name : 'ModestAtomicTestExecutionEnvironment',
	#superclass : 'TestExecutionEnvironment',
	#instVars : [
		'codeCoverage',
		'exportDirectory'
	],
	#category : 'Modest-SuiteReduction',
	#package : 'Modest',
	#tag : 'SuiteReduction'
}

{ #category : 'instance creation' }
ModestAtomicTestExecutionEnvironment class >> exportingTo: aDirectory [

	^ self new exportDirectory: aDirectory
]

{ #category : 'accessing' }
ModestAtomicTestExecutionEnvironment >> codeCoverage: aSCICodeCoverage [

	codeCoverage := aSCICodeCoverage
]

{ #category : 'controlling' }
ModestAtomicTestExecutionEnvironment >> exportCoverage [
	"Ask SmalltalkCI to export its coverage, which must be inside the Tonel directory"

	codeCoverage exportResultsIn: (exportDirectory / 'ci') pathString.

	"Uniquely identify the coverage file using the test name"
	exportDirectory / 'ci/coverage/lcov.info' copyTo: exportDirectory
		/ (testCase className , '.' , testCase selector , '.info')
]

{ #category : 'accessing' }
ModestAtomicTestExecutionEnvironment >> exportDirectory [

	^ exportDirectory
]

{ #category : 'accessing' }
ModestAtomicTestExecutionEnvironment >> exportDirectory: aFileReference [

	exportDirectory := aFileReference
]

{ #category : 'controlling' }
ModestAtomicTestExecutionEnvironment >> runTestCase: aTestCase [

	[ aTestCase className , '#' , aTestCase selector ] record.
	super runTestCase: aTestCase.

	codeCoverage finishUp.
	self exportCoverage.
	codeCoverage startUp
]
