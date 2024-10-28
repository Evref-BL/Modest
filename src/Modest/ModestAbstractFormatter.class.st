"
My subclasses implement logic to apply formatting to source files.
"
Class {
	#name : 'ModestAbstractFormatter',
	#superclass : 'Object',
	#category : 'Modest-Formatters',
	#package : 'Modest',
	#tag : 'Formatters'
}

{ #category : 'testing' }
ModestAbstractFormatter class >> isAbstract [

	^ self == ModestAbstractFormatter
]

{ #category : 'formatting' }
ModestAbstractFormatter >> formatFiles: files [
	"Implement logic to apply formatting to source files."

	self subclassResponsibility
]
