Class {
	#name : 'ModestPharoImageCodeExporter',
	#superclass : 'ModestAbstractCodeExporter',
	#category : 'Modest',
	#package : 'Modest'
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
ModestPharoImageCodeExporter >> compileMethod: methodData inClass: class usingMapping: classData [

	| methodAST helpers |
	methodAST := methodData at: #ast.

	[ class compile: methodAST formattedCode classified: 'tests' ]
		on: self compilationErrors
		do: [ :e |
			[
			String streamContents: [ :s |
				s << 'Failed to compile `' << class className << '#'
				<< methodAST selector << '` because: ' << e asString ] ] record.

			"Remove the method from the mapping, not yet installed on class"
			^ (classData at: #methods) removeKey: methodAST selector ].

	"Export helpers if there are any"
	helpers := methodData at: #helpers ifAbsent: [ ^ self ].
	helpers do: [ :helperAST |
		[ class compile: helperAST formattedCode classified: 'tests' ]
			on: self compilationErrors
			do: [ :e |
				[
				String streamContents: [ :s |
					s << 'Failed to compile `' << class className << '#'
					<< helperAST selector << '` because: ' << e asString ] ] record.

				"Remove the test method and helpers from the class and mapping"
				1 to: (helpers indexOf: helperAST) do: [ :helper | "TODO not always in same class as test class"
					class removeSelector: helper selector ].
				class removeSelector: methodAST selector.
				^ (classData at: #methods) removeKey: methodAST selector ] ]
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
	mapping do: [ :classData |
		| class |
		class := self overwriteTestClass: (classData at: #model).

		classData
			at: #comment
			ifPresent: [ :comment | class comment: comment ].

		(classData at: #methods) do: [ :methodData |
			exported add:
				(self
					 compileMethod: methodData
					 inClass: class
					 usingMapping: classData) ] ].
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
