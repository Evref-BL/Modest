Class {
	#name : #BaselineOfModest,
	#superclass : #BaselineOf,
	#category : #BaselineOfModest
}

{ #category : #baselines }
BaselineOfModest >> baseline: spec [

	<baseline>
	spec for: #common do: [ 
		self dependencies: spec.
		self packages: spec ]
]

{ #category : #baselines }
BaselineOfModest >> dependencies: spec [

	spec
		baseline: 'FamixOpenTelemetry' with: [ "loads Famix-Value"
			spec
				repository:
					'github://moosetechnology/Famix-OpenTelemetry:main/src';
				loads: 'all' ];
		baseline: 'FamixUnitTest'
		with: [ 
		spec repository: 'github://moosetechnology/Famix-UnitTest:main/src' ];
		baseline: 'FASTRefactor'
		with: [ 
		spec repository: 'github://moosetechnology/FASTRefactor:main/src' ]
]

{ #category : #baselines }
BaselineOfModest >> packages: spec [

	spec
		package: 'Modest';
		package: 'Modest-Report'
]
