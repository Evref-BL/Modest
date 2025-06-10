Class {
	#name : 'ModestAbstractCodeExporter',
	#superclass : 'Object',
	#category : 'Modest',
	#package : 'Modest'
}

{ #category : 'instance creation' }
ModestAbstractCodeExporter class >> defaultFor: aLanguageName [

	self subclassesDo: [ :subclass |
		(subclass isDefaultFor: aLanguageName) ifTrue: [ ^ subclass new ] ].
	^ nil
]

{ #category : 'testing' }
ModestAbstractCodeExporter class >> isAbstract [

	^ self == ModestAbstractCodeExporter
]

{ #category : 'testing' }
ModestAbstractCodeExporter class >> isDefaultFor: aLanguageName [

	^ false
]

{ #category : 'exporting' }
ModestAbstractCodeExporter >> exportFor: aTestGenerator [

	self subclassResponsibility
]
