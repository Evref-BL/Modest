"
I am a report about the execution of a `ModestTestGenerator`.
I log data concerning the importers, exporters and models that are used.
By default, the reports can be found in the image's `pharo-local/modest/reports` folder.
"
Class {
	#name : #ModestReport,
	#superclass : #Object,
	#instVars : [
		'stream',
		'testGenerator',
		'start',
		'indent',
		'indentSize'
	],
	#category : #'Modest-Report'
}

{ #category : #'instance creation' }
ModestReport class >> about: aTestGenerator [

	^ self new testGenerator: aTestGenerator
]

{ #category : #streaming }
ModestReport >> <- aString [
	"add a new list element with the given value"

	self indent.
	stream
		nextPutAll: '- ';
		nextPutAll: aString;
		nextPut: Character lf
]

{ #category : #streaming }
ModestReport >> <-@ aKeyString [
	"add a new dictionary in the current list, starting with the given key"

	self indent.
	stream
		nextPutAll: '- ';
		nextPutAll: aKeyString;
		nextPut: $:.
	self indentPlus
]

{ #category : #streaming }
ModestReport >> <=- aString [
	"add a list element in the parent dictionary with the given value"

	self indentMinus <- aString
]

{ #category : #streaming }
ModestReport >> <=@ aKeyString [
	"start an entry in the parent dictionary with the given key"

	self indentMinus <@ aKeyString
]

{ #category : #streaming }
ModestReport >> <@ aKeyString [
	"start an entry in the current dictionary with the given key"

	self indent.
	stream
		nextPutAll: aKeyString;
		nextPut: $:
]

{ #category : #streaming }
ModestReport >> => aValue [
	"set a unique dictionary value at the previously defined key"

	stream nextPut: Character space.
	aValue printOn: stream.
	stream nextPut: Character lf
]

{ #category : #streaming }
ModestReport >> =>- aString [
	"start a new child list with the given element"

	stream nextPut: Character lf.
	self indentPlus <- aString
]

{ #category : #streaming }
ModestReport >> =>@ aKeyString [
	"start a new child dictionary with the given key"

	stream nextPut: Character lf.
	self indentPlus <@ aKeyString
]

{ #category : #actions }
ModestReport >> end [

	self writeStatistics.
	self writeToFile.
	stream := nil
]

{ #category : #streaming }
ModestReport >> indent [

	indent * indentSize timesRepeat: [ stream nextPut: Character space ]
]

{ #category : #streaming }
ModestReport >> indentMinus [

	indent := indent - 1
]

{ #category : #streaming }
ModestReport >> indentPlus [

	indent := indent + 1
]

{ #category : #accessing }
ModestReport >> indentSize [

	^ indentSize
]

{ #category : #accessing }
ModestReport >> indentSize: anInteger [

	indentSize := anInteger
]

{ #category : #initialization }
ModestReport >> initialize [

	indent := 0.
	indentSize := 2
]

{ #category : #actions }
ModestReport >> start [

	stream := String new writeStream.
	start := DateAndTime now
]

{ #category : #accessing }
ModestReport >> stream [

	^ stream
]

{ #category : #accessing }
ModestReport >> stream: aStream [

	stream := aStream
]

{ #category : #accessing }
ModestReport >> testGenerator [

	^ testGenerator
]

{ #category : #accessing }
ModestReport >> testGenerator: aTestGenerator [

	testGenerator := aTestGenerator
]

{ #category : #writing }
ModestReport >> writeAbout: actor [

	| oldIndent |
	oldIndent := indent.
	self =>@ 'class' => actor className.
	actor reportOn: self.
	indent := oldIndent
]

{ #category : #writing }
ModestReport >> writeList: aCollection [
	"make a list with the given reportable elements"

	| listIndent |
	listIndent := indent.
	aCollection do: [ :each |
		self <-@ 'class' => each className.
		each reportOn: self.
		indent := listIndent ]
]

{ #category : #writing }
ModestReport >> writeSection: aKeyString about: actor [

	self <@ aKeyString.
	self writeAbout: actor
]

{ #category : #writing }
ModestReport >> writeSection: aKeyString with: aBlock [

	| oldIndent |
	oldIndent := indent.
	self <@ aKeyString.
	stream nextPut: Character lf.
	self indentPlus.
	aBlock value.
	indent := oldIndent
]

{ #category : #writing }
ModestReport >> writeStatistics [

	| end |
	end := DateAndTime now.
	self <@ 'statistics' =>@ 'duration' => (end - start) asString
	<@ 'start' => start asString <@ 'end' => end asString
]

{ #category : #writing }
ModestReport >> writeToFile [

	(testGenerator localDirectory / 'reports'
	 /
		 ((start truncated asString replaceAll: $: with: $_)
		  , '-ModestReport-' , testGenerator famixModel name , '.yaml'))
		ensureCreateFile writeStreamDo: [ :fileStream |
		fileStream nextPutAll: stream contents ]
]
