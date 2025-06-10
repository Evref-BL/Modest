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

{ #category : 'running' }
ModestJavaTestRunner >> allowReflectionOn: stream [
	"Go around stricter reflection rules in Java 16 and 17+"

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

{ #category : 'running' }
ModestJavaTestRunner >> commandToCompile: javaFiles [
	"Using the javac command: https://docs.oracle.com/javase/8/docs/technotes/tools/unix/javac.html
	Disable annotation processing with `-proc:none` because they can throw errors."

	^ String streamContents: [ :stream |
		  stream << 'javac -proc:none -d "'
		  << self buildDirectory pathString << '"'.
		  classpath isEmptyOrNil ifFalse: [
			  stream << ' -classpath "' << classpath << '"' ].
		  javaFiles do: [ :file | stream << ' "' << file fullName << '"' ] ]
]

{ #category : 'running' }
ModestJavaTestRunner >> compile: sourceDir [
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
	javacCommand := self commandToCompile: javaFiles.
	result := LibC runCommand: javacCommand.
	result = 0 ifFalse: [ "Something went wrong, how to fix it?"
		self shouldBeImplemented ]
]

{ #category : 'running' }
ModestJavaTestRunner >> findRunnerJarIn: directory [
	"FileReference to the jar of the Java test runner.
	Currently using a custom runner that uses JaCoCo and exports coverage data per test method.
	See: github.com/Evref-BL/AtomicCoverageAnalyzer-Java"

	^ directory asFileReference children detect: [ :file |
		  file extension = 'jar' and: [
			  file basenameWithoutExtension beginsWith:
				  'atomic-coverage-analyzer' ] ]
]

{ #category : 'coverage' }
ModestJavaTestRunner >> generateTestCoverageFor: aTestGenerator [
	"Run AtomicCoverageAnalyzer and wait for the coverage data to be ready."

	| jarPath command result |
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

	(result beginsWith: 'ERROR') ifTrue: [ "What happened and how to fix it?"
		self shouldBeImplemented ]
]

{ #category : 'running' }
ModestJavaTestRunner >> prepareToRunFor: aTestGenerator [
	"Compile the test sources, and add the test classes and their dependencies to the classpath."

	self buildDirectory:
		aTestGenerator configuration coverageDirectory / 'target'.

	classpath := String streamContents: [ :s | "Put newly generated tests first to avoid conflicts with existing tests if any"
		             s nextPutAll: self buildDirectory pathString.
		             s nextPut: DiskStore current separator.
		             s nextPutAll:
			             aTestGenerator configuration testDependencies.
		             s nextPut: DiskStore current separator.
		             s nextPutAll: aTestGenerator configuration classpath ].

	self compile: aTestGenerator configuration exportDirectory
]
