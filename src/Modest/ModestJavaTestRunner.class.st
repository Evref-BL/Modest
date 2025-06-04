"
I am a test runner for Java.

The first step in executing Java code is to compile it.
This is done using the `javac` command.
The classpath of the tested application, including the new test dependencies, is required.

To obtain test coverage while running the tests, I use a JAR file from the [AtomicCoverageAnalyzer](https://github.com/Evref-BL/AtomicCoverageAnalyzer-Java) project.
This tool exports a coverage report for each test method.
"
Class {
	#name : 'ModestJavaTestRunner',
	#superclass : 'ModestAbstractTestRunner',
	#instVars : [
		'classpath'
	],
	#category : 'Modest-SuiteReduction',
	#package : 'Modest',
	#tag : 'SuiteReduction'
}

{ #category : 'as yet unclassified' }
ModestJavaTestRunner >> allowReflectionOn: stream [
	"Go around stricter reflection rules in Java 16 and 17+"

	"'jdk.compiler/com.sun.tools.javac.processing'
	'jdk.compiler/com.sun.tools.javac.util'
	'jdk.compiler/com.sun.tools.javac.tree'
	'jdk.compiler/com.sun.tools.javac.code'
	'jdk.compiler/com.sun.tools.javac.model'"

	#( 'java.base/java.lang' 'java.base/java.lang.reflect'
	   'java.base/java.util' 'java.base/sun.reflect' ) do: [ :entry |
		stream << ' --add-opens ' << entry << '=ALL-UNNAMED' ]
]

{ #category : 'accessing' }
ModestJavaTestRunner >> classpath [

	^ classpath
]

{ #category : 'accessing' }
ModestJavaTestRunner >> classpath: aString [

	classpath := aString
]

{ #category : 'as yet unclassified' }
ModestJavaTestRunner >> commandToCompile: javaFiles to: targetDir [

	^ String streamContents: [ :stream |
		  stream << 'javac -proc:none -d "' << targetDir pathString << '"'.
		  classpath isEmptyOrNil ifFalse: [
			  stream << ' -classpath "' << classpath << '"' ].
		  javaFiles do: [ :file | stream << ' "' << file fullName << '"' ] ]
]

{ #category : 'as yet unclassified' }
ModestJavaTestRunner >> compile: sourceDir to: targetDir [
	"Compile Java source files into class files"

	| javaFiles javacCommand result |
	"Collect all .java files in the export directory"
	javaFiles := (SelectVisitor
		              breadthFirst: sourceDir resolve
		              select: [ :entry |
		              entry isFile and: [ entry basename endsWith: '.java' ] ])
		             collect: [ :each | each reference ].
	javaFiles ifEmpty: [ ^ self ].

	"Build and run a javac command"
	javacCommand := self commandToCompile: javaFiles to: targetDir.
	result := LibC runCommand: javacCommand.
	result = 0 ifFalse: [ "Something went wrong, how to fix it?"
		self halt ]
]

{ #category : 'enumerating' }
ModestJavaTestRunner >> findRunnerJarIn: directory [
	"FileReference to the jar of the Java test runner.
	Currently using a custom runner that uses JaCoCo and exports coverage data per test method.
	See: github.com/Evref-BL/AtomicCoverageAnalyzer-Java"

	^ directory asFileReference children detect: [ :file |
		  file extension = 'jar' and: [
			  file basenameWithoutExtension beginsWith:
				  'atomic-coverage-analyzer' ] ]
]

{ #category : 'running' }
ModestJavaTestRunner >> generateTestCoverageFor: aTestGenerator [
	"Run AtomicCoverageAnalyzer and wait for the coverage data to be ready."

	| jarPath command result |
	self prepareToRunFor: aTestGenerator.

	jarPath := (self findRunnerJarIn:
		            aTestGenerator configuration libDirectory) pathString.

	command := String streamContents: [ :s |
		           s << 'cd "'
		           << aTestGenerator configuration tempDirectory pathString
		           << '" && java'.
		           self allowReflectionOn: s.
		           s << ' -classpath "' << jarPath
		           << DiskStore current separator asString << self classpath
		           << '" -javaagent:"' << jarPath
		           << '" fr.evref.modest.AtomicCoverageAnalyzer "'
		           <<
		           aTestGenerator configuration coverageDirectory pathString
		           << '" fr.evref.modest.ModestSuite' ].

	result := LibC resultOfCommand: command.

	result trimRight = 'ERROR' ifTrue: [ "What happened and how to fix it?"
		self shouldBeImplemented ]
]

{ #category : 'running' }
ModestJavaTestRunner >> getTestCoverageFor: aTestGenerator [

	self generateTestCoverageFor: aTestGenerator.

	"Map test method names to their coverage data file.
	The goal is to not let clients depend on the .java file extension,
	but instead rely on the properties of the involved test entities."
	^ aTestGenerator configuration coverageDirectory children
		  collect: [ :file | file basenameWithoutExtension -> file ]
		  as: Dictionary
]

{ #category : 'as yet unclassified' }
ModestJavaTestRunner >> prepareToRunFor: aTestGenerator [
	"Compile the test sources, and add the test classes and their dependencies to the classpath."

	| testClassesDir |
	testClassesDir := (aTestGenerator configuration tempDirectory
	                   / 'javaTestClasses') ensureCreateDirectory.

	classpath := String streamContents: [ :s | "Put newly generated tests first to avoid conflicts with existing tests if any"
		             s nextPutAll: testClassesDir pathString.
		             s nextPut: DiskStore current separator.
		             s nextPutAll:
			             aTestGenerator configuration testDependencies.
		             s nextPut: DiskStore current separator.
		             s nextPutAll: aTestGenerator configuration classpath ].

	self
		compile: aTestGenerator configuration exportDirectory
		to: testClassesDir
]
