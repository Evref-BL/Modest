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
ModestAbstractTestRunner >> collectCoverage [
	"Map test method names to their coverage data.
	The goal is to prevent clients from relying on file extensions.
	Instead, they should rely on the properties of the involved test entities.
	By default, assume the data is in files named after the qualified test name."

	^ self buildDirectory files
		  collect: [ :file | file basenameWithoutExtension -> file ]
		  as: Dictionary
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
	^ self collectCoverage
]
