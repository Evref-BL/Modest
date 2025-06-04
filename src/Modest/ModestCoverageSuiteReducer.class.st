"
I reduce test suites based on coverage data modeled using the `Famix-Coverage-Unit` package.
"
Class {
	#name : 'ModestCoverageSuiteReducer',
	#superclass : 'ModestAbstractSuiteReducer',
	#instVars : [
		'testRunner',
		'coverageImporter'
	],
	#category : 'Modest-SuiteReduction',
	#package : 'Modest',
	#tag : 'SuiteReduction'
}

{ #category : 'accessing' }
ModestCoverageSuiteReducer >> coverageImporter [

	^ coverageImporter
]

{ #category : 'accessing' }
ModestCoverageSuiteReducer >> coverageImporter: aCoverageImporter [

	coverageImporter := aCoverageImporter
]

{ #category : 'reducing' }
ModestCoverageSuiteReducer >> getTestCoverageFor: aTestGenerator [

	| coverageFiles |
	coverageFiles := testRunner getTestCoverageFor: aTestGenerator.

	"Set up the coverage data importer to find the covered classes in the code model"
	coverageImporter entityFinder:
		aTestGenerator configuration entityFinder.

	"Build a list of FamixUnitCoverageReports, one per test method"
	^ (aTestGenerator testModel allWithType: FamixUTMethod)
		  collect: [ :test |
			  | coverageFile |
			  coverageFile := coverageFiles at:
				                  test testedMethod parentType typeContainer
					                  mooseNameWithDots , '.' , test case name , '.'
				                  , test name.
			  coverageImporter importCoverage: coverageFile ofMethod: test ]
		  as: OrderedCollection
]

{ #category : 'logging' }
ModestCoverageSuiteReducer >> logInitialTestsToRemove: testsToRemove [

	(String streamContents: [ :s |
		 s nextPutAll: 'Initial redundant tests to remove: '.
		 testsToRemove ifEmpty: [ s nextPutAll: 'none' ] ifNotEmpty: [
			 testsToRemove
				 do: [ :test | test printOn: s ]
				 separatedBy: [ s nextPutAll: ', ' ] ] ]) record
]

{ #category : 'logging' }
ModestCoverageSuiteReducer >> logTestsToRemove: testsToRemove forMethod: testedMethod [

	String streamContents: [ :s |
		testedMethod printOn: s.
		s nextPutAll: ': '.
		testsToRemove
			ifEmpty: [ s nextPutAll: 'no tests to remove' ]
			ifNotEmpty: [
				testsToRemove
					do: [ :test | test printOn: s ]
					separatedBy: [ s nextPutAll: ', ' ] ] ]
]

{ #category : 'reducing' }
ModestCoverageSuiteReducer >> processReports: coverageReports on: testsToRemove [
	"Each report is about a specific test method. Group reports by their tested method.
	Remove tests that have equivalent coverage to another that was already processed.
	Finally, keep only reports for a tested method if there are at least two of them."

	| groupedReports |
	groupedReports := Dictionary new.

	coverageReports do: [ :report |
		groupedReports
			at: report rootMethod testedMethod
			ifPresent: [ :reports | "Do not include tests with equivalent coverage"
				(reports noneSatisfy: [ :otherReport |
					 report coverageEquals: otherReport ])
					ifTrue: [ reports add: report ]
					ifFalse: [ testsToRemove add: report rootMethod ] ]
			ifAbsentPut: [ OrderedCollection with: report ] ].

	"Reduction is only applicable when multiple tests cover the same method"
	^ groupedReports select: [ :tests | tests size > 1 ]
]

{ #category : 'reducing' }
ModestCoverageSuiteReducer >> reduceTestSuiteFor: aTestGenerator [
	"First we need to obtain coverage data, then we can use it to reduce the suite."

	| coverageReports |
	'Generating test coverage...' record.
	coverageReports := self getTestCoverageFor: aTestGenerator.

	self
		execute: [
			self
				reduceTestSuiteFromCoverage: coverageReports
				for: aTestGenerator ]
		recordedAs: 'Applying coverage-based suite reduction...'
]

{ #category : 'reducing' }
ModestCoverageSuiteReducer >> reduceTestSuiteFromCoverage: coverageReports for: aTestGenerator [
	"Apply test suite reduction using the given coverage reports.
	A list of the tests to remove is computed, before finally applying the removals."

	| testsToRemove groupedReports |
	testsToRemove := OrderedCollection new.

	"Group reports by tested methods and eliminate those of equivalent coverage"
	groupedReports := self
		                  processReports: coverageReports
		                  on: testsToRemove.
	self logInitialTestsToRemove: testsToRemove.

	"Apply backward-elimination for groups of tests about the same method"
	groupedReports keysAndValuesDo: [ :testedMethod :reports |
		| removed |
		reports size >= 20 ifTrue: [
			Warning signal:
				'Prohibitively large set of tests, proceeding may lock resources for a long time!' ].
		removed := self
			           reduceTestsForMethod: testedMethod
			           usingReports: reports.
		self logTestsToRemove: removed forMethod: testedMethod.
		testsToRemove addAll: removed ].

	"We know what to remove, now it's time to apply the changes in the generated tests"
	self removeTests: testsToRemove for: aTestGenerator
]

{ #category : 'reducing' }
ModestCoverageSuiteReducer >> reduceTestsForMethod: testedMethod usingReports: reports [
	"Compute a redundancy-elimination (backward-elimination) reduction of all tests (FamixUTMethod)
	that target the same testedMethod. Each report in `reports` is a FamixUnitCoverageReport,
	whose #rootMethod is a FamixUTMethod, and whose #coverageData is a Dictionary
	mapping each covered coveredClass -> a FamixUnitCoverageData
	(which knows its #probeCount and supports #probeAt: to check coverage at a local index).

	At the end, `removedTests` will contain the list of all FamixUTMethod
	instances that can be dropped without losing any coverage.  The tests *not* in `removedTests`
	form one maximally-reduced suite (i.e. no remaining test can be removed without sacrificing coverage)."

	<precondition:
	'reports size >= 2 and: [ reports allSatisfy: [ :r | reports first rootMethod testedMethod == r rootMethod testedMethod ] ]'>
	| allClasses globalOffsets "Dictionary mapping coveredClass to base offset into the global probe index" totalProbes "Integer N = total # of (class,probe) across all classes" coverageCount "Array of ints, length = totalProbes" testReportsByMethod "Dictionary mapping FamixUTMethod to FamixUnitCoverageReport" remainingTests "OrderedCollection of FamixUTMethod still in the suite" removedTests "OrderedCollection of FamixUTMethod removed from the suite" |
	"1. Gather every coveredClass and record its probeCount.
	We traverse each report's coverageData dictionary.
	allClasses keys = all instrumented classes across all reports,
	allClasses at: coveredClass = that class's probeCount."
	allClasses := Dictionary new.
	reports do: [ :report |
		report coverageData keysAndValuesDo: [ :coveredClass :coverageData |
			(allClasses includesKey: coveredClass) ifFalse: [
				allClasses at: coveredClass put: coverageData probeCount ] ] ].

	"2. Assign each coveredClass a contiguous block of global indices.
	(globalOffsets at: coveredClass) = the starting offset for that class in [0..totalProbes-1]."
	globalOffsets := Dictionary new.
	totalProbes := 0.
	allClasses keysAndValuesDo: [ :coveredClass :probeCount |
		globalOffsets at: coveredClass put: totalProbes.
		totalProbes := totalProbes + probeCount ].
	"Now totalProbes = sum(probeCount for each class)."

	"3. Initialize coverageCount := an Array of totalProbes zeros."
	(coverageCount := Array new: totalProbes) atAllPut: 0.

	"4. Build a dictionary from each FamixUTMethod -> its coverage report.
	remainingTests is the OrderedCollection of all FamixUTMethods to consider."
	testReportsByMethod := Dictionary new.
	reports do: [ :report |
		testReportsByMethod at: report rootMethod put: report ].
	remainingTests := testReportsByMethod keys asOrderedCollection.

	"5. Populate coverageCount by scanning each report's covered bits:
	For each (coveredClass, coverageData), for each localIdx in 1..(coverageData probeCount),
	if coverageData probeAt: localIdx = true, then
		globalIdx := (globalOffsets at: coveredClass) + localIdx.
		increment coverageCount at: globalIdx by 1."
	testReportsByMethod valuesDo: [ :coverageReport |
		coverageReport coverageData keysAndValuesDo: [
			:coveredClass
			:coverageData |
			| baseOffset globalIdx |
			baseOffset := globalOffsets at: coveredClass.
			1 to: coverageData probeCount do: [ :localIdx |
				(coverageData probeAt: localIdx) ifTrue: [
					globalIdx := baseOffset + localIdx.
					coverageCount
						at: globalIdx
						put: (coverageCount at: globalIdx) + 1 ] ] ] ].

	"6. Now repeatedly drop any test whose removal would not lose coverage.
	A test is removable iff none of the probes it covers has coverageCount = 1.
	We collect all removable tests in the removed list, then decrement coverageCount
	for each of their covered bits, remove them from remainingTests, and add them
	to removedTests. Repeat until no further test can be removed."
	removedTests := OrderedCollection new.
	[
	| removed |
	removed := remainingTests reject: [ :aTest |
		           | report covDict |
		           report := testReportsByMethod at: aTest.
		           covDict := report coverageData.

		           "Check whether aTest covers any probe whose coverageCount = 1.
		           If false, then none of the bits this test covers has count=1 -> we can drop it."
		           covDict associations anySatisfy: [ :coverage |
			           | coveredClass coverageData baseOffset |
			           coveredClass := coverage key.
			           coverageData := coverage value.
			           baseOffset := globalOffsets at: coveredClass.
			           "Within this coveredClass, see if any localIdx is covered by aTest AND has count=1."
			           (1 to: coverageData probeCount) anySatisfy: [ :localIdx |
				           (coverageData probeAt: localIdx) and: [
					           (coverageCount at: baseOffset + localIdx) = 1 ] ] ] ].

	"If no test was found removable in this pass, we're done."
	removed ifEmpty: [ "At this point, `removedTests` holds every FamixUTMethod we dropped.
		The tests still in `remainingTests` form one maximally-reduced suite
		that preserves exactly the same coverage as the original collection of reports."
		^ removedTests ].

	"Otherwise, actually remove each test in the removed list."
	removed do: [ :aTest |
		| report covDict |
		report := testReportsByMethod at: aTest.
		covDict := report coverageData.

		"Decrement coverageCount for every probe that aTest had covered."
		covDict keysAndValuesDo: [ :coveredClass :coverageData |
			| baseOffset |
			baseOffset := globalOffsets at: coveredClass.
			1 to: coverageData probeCount do: [ :localIdx |
				(coverageData probeAt: localIdx) ifTrue: [
					| globalIdx oldCount |
					globalIdx := baseOffset + localIdx.
					oldCount := coverageCount at: globalIdx.
					coverageCount at: globalIdx put: oldCount - 1 ] ] ].

		"Remove aTest from remainingTests and from the dictionary; record it in removedTests."
		remainingTests remove: aTest.
		testReportsByMethod removeKey: aTest.
		removedTests add: aTest ] ] repeat
]

{ #category : 'tests' }
ModestCoverageSuiteReducer >> testRunner [

	^ testRunner
]

{ #category : 'accessing' }
ModestCoverageSuiteReducer >> testRunner: aTestRunner [

	testRunner := aTestRunner
]
