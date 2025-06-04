Class {
	#name : 'ModestAbstractTestRunner',
	#superclass : 'Object',
	#category : 'Modest-SuiteReduction',
	#package : 'Modest',
	#tag : 'SuiteReduction'
}

{ #category : 'testing' }
ModestAbstractTestRunner class >> isAbstract [

	^ self == ModestAbstractTestRunner
]

{ #category : 'running' }
ModestAbstractTestRunner >> getTestCoverageFor: aTestGenerator [

	self subclassResponsibility
]
