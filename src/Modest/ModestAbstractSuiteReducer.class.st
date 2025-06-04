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
ModestAbstractSuiteReducer >> removeTestMethods: testsToRemove inASTModel: testASTModel [

	| testClasses |
	"Create a mapping of the AST test classes and methods"
	testClasses := (testASTModel allWithType: FASTJavaClassDeclaration)
		               collect: [ :class |
			               class name
			               ->
				               (class
				                -> ((class declarations select: [ :declaration |
						                  declaration isMethodEntity ])
						                 collect: [ :declaration |
						                 declaration name -> declaration ]
						                 as: Dictionary)) ]
		               as: Dictionary.

	testsToRemove do: [ :test |
		| classAndMethods testClass testMethod |
		classAndMethods := testClasses at: test case name.
		testClass := classAndMethods key.
		testMethod := classAndMethods value at: test name.

		"Remove the test method from its class"
		testClass declarations remove: testMethod.

		"Let's also remove the helpers for this method.
		The helper relations are not modeled: there's no mapping from test classes and methods to their helpers.
		That would be ideal, but not yet implemented, so it's based on naming conventions.
		This is fragile, but that will do for now..."
		classAndMethods := testClasses at: test case name , 'Helper'.
		testClass := classAndMethods key.
		classAndMethods value do: [ :helper |
			(helper name endsWith: test name) ifTrue: [
				testClass declarations remove: helper ] ].

		"TODO Delete the helper class if it is empty.
		Can that happen? That means a test with no helper won against one with some.
		I suppose it can happen, but removing a class is not as easy as a method, wait till it happens."
		self assert: testClass declarations isNotEmpty ]
]

{ #category : 'removing' }
ModestAbstractSuiteReducer >> removeTests: testsToRemove for: aTestGenerator [

	testsToRemove ifEmpty: [
		'No tests to remove.' record.
		^ self ].

	(String streamContents: [ :s |
		 s nextPutAll: 'Removed: '.
		 testsToRemove
			 do: [ :test | test printOn: s ]
			 separatedBy: [ s nextPutAll: ', ' ] ]) record.

	self
		removeTestMethods: testsToRemove
		inASTModel: aTestGenerator testASTModel.

	"After removing elements from the AST, it needs to be re-exported"
	aTestGenerator exportAST
]
