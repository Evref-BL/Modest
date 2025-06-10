"
Abstract class for test suite reducers.
Subclasses have the responsibility of reducing a suite based on their own criteria, such as coverage.
"
Class {
	#name : 'ModestAbstractSuiteReducer',
	#superclass : 'Object',
	#category : 'Modest-SuiteReduction',
	#package : 'Modest',
	#tag : 'SuiteReduction'
}

{ #category : 'testing' }
ModestAbstractSuiteReducer class >> isAbstract [

	^ self == ModestAbstractSuiteReducer
]

{ #category : 'reducing' }
ModestAbstractSuiteReducer >> reduceTestSuiteFor: aTestGenerator [
	"Reduce a generated test suite.
	Eliminated test methods are removed from their class in the test AST model."

	self subclassResponsibility
]

{ #category : 'removing' }
ModestAbstractSuiteReducer >> removeTests: testsToRemove for: aTestGenerator [

	testsToRemove ifEmpty: [
		'No tests to remove.' record.
		^ self ].

	[
	String streamContents: [ :s |
		s nextPutAll: 'Removed: '.
		testsToRemove
			do: [ :test | test printOn: s ]
			separatedBy: [ s nextPutAll: ', ' ] ] ] record.

	self
		removeTests: testsToRemove
		fromMapping: aTestGenerator testASTModel mapping.

	"After removing elements from the AST, it needs to be re-exported"
	aTestGenerator exportAST
]

{ #category : 'removing' }
ModestAbstractSuiteReducer >> removeTests: testsToRemove fromMapping: mapping [

	testsToRemove do: [ :test |
		| classData |
		classData := mapping atClassNamed: test case name.
		(classData at: #methods) removeKey: test name.

		"TODO Delete the helper class if it is empty.
		Can that happen? That means a test with no helper won against one with some.
		I suppose it can happen, but removing a class is not as easy as a method, wait till it happens."
		self assert: (classData at: #methods) isNotEmpty ]
]
