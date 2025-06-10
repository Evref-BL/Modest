Class {
	#name : 'ModestAbstractTestRunner',
	#superclass : 'Object',
	#instVars : [
		'buildDirectory'
	],
	#category : 'Modest-SuiteReduction',
	#package : 'Modest',
	#tag : 'SuiteReduction'
}

{ #category : 'testing' }
ModestAbstractTestRunner class >> isAbstract [

	^ self == ModestAbstractTestRunner
]

{ #category : 'accessing' }
ModestAbstractTestRunner >> buildDirectory [

	^ buildDirectory
]

{ #category : 'accessing' }
ModestAbstractTestRunner >> buildDirectory: aDirectory [

	buildDirectory := aDirectory
]

{ #category : 'coverage' }
ModestAbstractTestRunner >> generateTestCoverageFor: aTestGenerator [
	"Generate coverage data in the coverageDirectory of the generator."

	self subclassResponsibility
]

{ #category : 'running' }
ModestAbstractTestRunner >> prepareToRunFor: aTestGenerator [

	self subclassResponsibility
]

{ #category : 'running' }
ModestAbstractTestRunner >> runTestCoverageFor: aTestGenerator [
	"Run the tests and return the coverage reports."

	self prepareToRunFor: aTestGenerator.
	self generateTestCoverageFor: aTestGenerator.

	"Map test method names to their coverage data file.
	The goal is to not let clients depend on the .java file extension,
	but instead rely on the properties of the involved test entities."
	^ aTestGenerator configuration coverageDirectory files
		  collect: [ :file | file basenameWithoutExtension -> file ]
		  as: Dictionary
]
