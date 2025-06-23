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

{ #category : 'logging' }
ModestAbstractSuiteReducer >> logInitialTestsToRemove: testsToRemove [

	self
		logRemoval: testsToRemove
		subject: 'initially redundant test'
		forMethod: nil
]

{ #category : 'removing' }
ModestAbstractSuiteReducer >> logRemoval: testsToRemove subject: subjectString forMethod: testedMethod [

	[
	| count |
	count := testsToRemove size.
	String streamContents: [ :s |
		s nextPutAll: 'Removed '.
		count printOn: s.
		s space nextPutAll: subjectString.
		count = 1 ifFalse: [ s nextPut: $s ].
		testedMethod ifNotNil: [
			s << ' about ' << testedMethod parentType fullyQualifiedName << '#'
			<< testedMethod signature ].
		count = 0 ifFalse: [
			s nextPutAll: ': '.
			testsToRemove
				do: [ :test | test printOn: s ]
				separatedBy: [ s nextPutAll: ', ' ] ] ] ] record
]

{ #category : 'removing' }
ModestAbstractSuiteReducer >> logTestsToRemove: testsToRemove [

	self logRemoval: testsToRemove subject: 'test' forMethod: nil
]

{ #category : 'logging' }
ModestAbstractSuiteReducer >> logTestsToRemove: testsToRemove forMethod: testedMethod [

	self
		logRemoval: testsToRemove
		subject: 'test'
		forMethod: testedMethod
]

{ #category : 'reducing' }
ModestAbstractSuiteReducer >> reduceTestSuiteFor: aTestGenerator [
	"Reduce a generated test suite.
	Eliminated test methods are removed from their class in the test AST model."

	self subclassResponsibility
]

{ #category : 'removing' }
ModestAbstractSuiteReducer >> removeTests: testsToRemove for: aTestGenerator [

	self logTestsToRemove: testsToRemove.
	testsToRemove ifEmpty: [ ^ self ].

	self
		removeTests: testsToRemove
		fromMapping: aTestGenerator configuration testExporter mapping.

	"After removing elements from the AST, it needs to be re-exported"
	aTestGenerator exportAST
]

{ #category : 'removing' }
ModestAbstractSuiteReducer >> removeTests: testsToRemove fromMapping: mapping [

	testsToRemove do: [ :test |
		| hadHelpers classMapping |
		classMapping := mapping atClass: test case.
		hadHelpers := (classMapping methods flatCollect: #helpers)
			              isNotEmpty.

		classMapping removeMethod: test.

		"TODO Delete the helper class if it is empty.
		Can that happen? That means a test with no helper won against one with some.
		I suppose it can happen, but removing a class is not as easy as a method, wait till it happens."
		hadHelpers ifTrue: [
			self assert:
				(classMapping methods flatCollect: #helpers) isNotEmpty ] ]
]
