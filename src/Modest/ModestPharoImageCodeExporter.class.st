Class {
	#name : 'ModestPharoImageCodeExporter',
	#superclass : 'ModestAbstractCodeExporter',
	#category : 'Modest-CodeExporters',
	#package : 'Modest',
	#tag : 'CodeExporters'
}

{ #category : 'testing' }
ModestPharoImageCodeExporter class >> isDefaultFor: aLanguageName [

	^ aLanguageName = 'pharo'
]

{ #category : 'compiling' }
ModestPharoImageCodeExporter >> compilationErrors [

	^ CodeError , NewUndeclaredWarning
]

{ #category : 'compiling' }
ModestPharoImageCodeExporter >> compileMethod: methodMapping inClass: class usingMapping: classMapping [

	| methodAST helpers |
	methodAST := methodMapping ast.

	[ class compile: methodAST formattedCode classified: 'tests' ]
		on: self compilationErrors
		do: [ :e |
			[
			String streamContents: [ :s |
				s << 'Failed to compile `' << class className << '#'
				<< methodAST selector << '` because: ' << e asString ] ] record.

			"Remove the method from the mapping, not yet installed on class"
			^ classMapping removeMethod: methodMapping ].

	"Export helpers if there are any"
	helpers := methodMapping helpers ifNil: [ ^ self ].
	helpers do: [ :helperAST |
		[ class compile: helperAST formattedCode classified: 'tests' ]
			on: self compilationErrors
			do: [ :e |
				[
				String streamContents: [ :s |
					s << 'Failed to compile `' << class className << '#'
					<< helperAST selector << '` because: ' << e asString ] ] record.

				"Remove the test method and helpers from the class and mapping"
				self shouldBeImplemented. "Iterate from first to current included"
				1 to: (helpers indexOf: helperAST) do: [ :helper | "Always in same class as test?"
					class removeSelector: helper selector ].
				class removeSelector: methodAST selector.
				^ classMapping removeMethod: methodMapping ] ]
]

{ #category : 'compiling' }
ModestPharoImageCodeExporter >> compileMethod: methodModel withAST: methodAST inClass: class [

	[ class compile: methodAST formattedCode classified: 'tests' ]
		on: self compilationErrors
		do: [ :e |
			[
			String streamContents: [ :s |
				s << 'Failed to compile `' << class className << '#'
				<< methodAST selector << '` because: ' << e asString ] ] record.

			"Remove the method from the class and the model"
			class removeSelector: methodAST selector.
			methodModel removeFromModel case: nil ]
]

{ #category : 'exporting' }
ModestPharoImageCodeExporter >> exportFor: aTestGenerator [

	EpMonitor disableDuring: [
		^ self exportMapping: aTestGenerator testASTModel mapping ]
]

{ #category : 'exporting' }
ModestPharoImageCodeExporter >> exportMapping: mapping [

	| exported |
	exported := OrderedCollection new.
	mapping do: [ :classMapping |
		| class |
		class := self overwriteTestClass: classMapping model.

		classMapping comment ifNotNil: [ :comment | class comment: comment ].

		"Iterate over a copy so the mapping can be modified"
		classMapping methods values do: [ :methodMapping |
			exported add: (self
					 compileMethod: methodMapping
					 inClass: class
					 usingMapping: classMapping) ] ].
	^ exported
]

{ #category : 'compiling' }
ModestPharoImageCodeExporter >> overwriteTestClass: classModel [
	"Build the class, overwriting any previous class with the same name.
	The installer will create the package if necessary."

	self class environment
		at: classModel name
		ifPresent: [ :class | class removeFromSystem ].
	^ self class classInstaller make: [ :builder |
		  builder
			  name: classModel name;
			  superclass: TestCase;
			  package:
				  classModel testedClass parentPackage name asString , '-Tests' ]
]
