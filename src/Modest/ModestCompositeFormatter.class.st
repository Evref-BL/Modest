"
I format using a collection of other formatters executed consecutively.
"
Class {
	#name : #ModestCompositeFormatter,
	#superclass : #ModestAbstractFormatter,
	#instVars : [
		'formatters'
	],
	#category : #'Modest-Formatters'
}

{ #category : #accessing }
ModestCompositeFormatter >> addFormatter: aFormatter [

	self formatters add: aFormatter
]

{ #category : #formatting }
ModestCompositeFormatter >> formatFiles: files [

	self formatters do: [ :formatter | formatter formatFiles: files ]
]

{ #category : #accessing }
ModestCompositeFormatter >> formatters [

	^ formatters ifNil: [ formatters := OrderedCollection new ]
]

{ #category : #accessing }
ModestCompositeFormatter >> formatters: aCollection [

	formatters := aCollection
]
