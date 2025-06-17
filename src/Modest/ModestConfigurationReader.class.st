"
I consume a configuration file located at the specified path from one of the following sources, in order of highest to lowest priority:
- first CLI argument
- `MODEST_CONFIGURATION` environment variable
- the default location, `./pharo-local/modest/modest.json`
"
Class {
	#name : 'ModestConfigurationReader',
	#superclass : 'Object',
	#instVars : [
		'configuration',
		'registry',
		'rawConfiguration'
	],
	#category : 'Modest-Configuration',
	#package : 'Modest',
	#tag : 'Configuration'
}

{ #category : 'enumerating' }
ModestConfigurationReader class >> findConfigurationFile [
	"Can be given as first CLI argument or with the MODEST_CONFIGURATION environment variable.
	Falls back to the default location: ./pharo-local/modest/config.json."

	^ (Smalltalk arguments
		   ifNotEmpty: [ :arguments | arguments first ]
		   ifEmpty: [
			   OSEnvironment current
				   at: 'MODEST_CONFIGURATION'
				   ifAbsent: [ "Default location"
					   (Smalltalk imageDirectory / 'pharo-local/modest') children
						   detect: [ :file | file basename asLowercase = 'modest.json' ]
						   ifNone: [ ModestConfigurationMissing signal ] ] ])
		  asFileReference ifAbsent: [ ModestConfigurationMissing signal ]
]

{ #category : 'configuration' }
ModestConfigurationReader class >> readConfiguration [

	^ self readConfigurationFromFile: self findConfigurationFile
]

{ #category : 'configuration' }
ModestConfigurationReader class >> readConfigurationFrom: aDictionary [

	^ self new readConfigurationFrom: aDictionary
]

{ #category : 'configuration' }
ModestConfigurationReader class >> readConfigurationFromFile: aConfigurationFile [

	^ self new readConfigurationFromFile: aConfigurationFile
]

{ #category : 'enumerating' }
ModestConfigurationReader >> configurationAt: key [

	^ self configurationAt: key required: true
]

{ #category : 'enumerating' }
ModestConfigurationReader >> configurationAt: key default: aBlockOrNil [
	"The key can be made of subkeys separated by a dot, e.g. `traces.loader.type`"

	| subKeys data |
	data := rawConfiguration.
	(subKeys := $. split: key) allButLastDo: [ :subKey |
		data := data at: subKey ifAbsent: [
			        ModestConfigurationError signal:
				        'Failed to resolve `' , subKey , '` in `' , key , '`.' ] ].
	data := data
		        at: subKeys last
		        ifPresent: [ :rawData | self parseValue: rawData ]
		        ifAbsent: aBlockOrNil.
	data ifNil: [ ModestConfigurationMissing signalFor: key ].
	^ data
]

{ #category : 'accessing' }
ModestConfigurationReader >> configurationAt: key required: isRequired [

	^ self
		  configurationAt: key
		  default: (isRequired ifFalse: [ [ ^ nil ] ])
]

{ #category : 'enumerating' }
ModestConfigurationReader >> existingDirectoryAt: key default: aBlock [
	"Find a directory that must already exist.
	In case the default is used, update the raw config to enable references."

	| path |
	path := self configurationAt: key default: [
		        rawConfiguration
			        at: key
			        put:
			        (path := aBlock value asAbsolute canonicalize) pathString.
		        path ].
	^ path asFileReference ifAbsent: [
		  ModestConfigurationMissingDirectory signalFor: key path: path ]
]

{ #category : 'initialization' }
ModestConfigurationReader >> initialize [

	self initializeRegistry.
	configuration := ModestConfiguration new
]

{ #category : 'initialization' }
ModestConfigurationReader >> initializeRegistry [

	| traceRegistry valueRegistry testRegistry |
	registry := Dictionary new.

	"=== TRACES ==="
	traceRegistry := registry at: 'traces' put: Dictionary new.
	self
		registerSubclassesOf: OTelAbstractExtractor
		in: (traceRegistry at: 'extractor' put: Dictionary new).
	self
		registerSubclassesOf: OTelAbstractLoader
		in: (traceRegistry at: 'loader' put: Dictionary new).
	self
		registerSubclassesOf: OTelAbstractTransformer
		in: (traceRegistry at: 'transformers' put: Dictionary new).

	"=== VALUES ==="
	valueRegistry := registry at: 'values' put: Dictionary new.
	self
		registerSubclassesOf: FamixValueAbstractImporter
		in: (valueRegistry at: 'importer' put: Dictionary new).
	valueRegistry at: 'exporter' at: 'pharo' put: FamixValue2PharoVisitor.
	valueRegistry
		at: 'exporter'
		at: 'java'
		put: FamixValue2FASTJavaVisitor.
	self
		registerSubclassesOf: FamixValueAbstractObjectExportStrategy
		in: (valueRegistry
				 at: 'exporter'
				 at: 'objectExportStrategy'
				 put: Dictionary new).

	"=== TESTS ==="
	testRegistry := registry at: 'tests' put: Dictionary new.
	self
		registerSubclassesOf: FamixUTAbstractExporter
		in: (testRegistry at: 'exporter' put: Dictionary new).
	self
		registerSubclassesOf: FamixUTAbstractJavaAssertionStrategy
		in: (testRegistry
				 at: 'exporter'
				 at: 'assertionStrategy'
				 put: Dictionary new).
	self
		registerSubclassesOf: FamixUTAbstractSetUpStrategy
		in: (testRegistry
				 at: 'exporter'
				 at: 'methodSetUpStrategy'
				 put: Dictionary new).
	self
		registerSubclassesOf: FamixUTAbstractPatch
		in: (testRegistry at: 'exporter' at: 'patches' put: Dictionary new).
	self
		registerSubclassesOf: ModestAbstractFormatter
		in: (testRegistry at: 'codeFormatter' put: Dictionary new).
	self
		registerSubclassesOf: ModestAbstractSuiteReducer
		in: (testRegistry at: 'suiteReducer' put: Dictionary new).
	self
		registerSubclassesOf: ModestAbstractTestRunner
		in:
		(testRegistry
			 at: 'suiteReducer'
			 at: 'testRunner'
			 put: Dictionary new).
	self
		registerSubclassesOf: FamixUnitCoverageAbstractImporter
		in: (testRegistry
				 at: 'suiteReducer'
				 at: 'coverageImporter'
				 put: Dictionary new)
]

{ #category : 'enumerating' }
ModestConfigurationReader >> loadAt: key [

	^ self loadAt: key required: true
]

{ #category : 'enumerating' }
ModestConfigurationReader >> loadAt: key default: aBlockOrNil [

	^ self
		  loadAt: key
		  withConfiguration:
		  (self configurationAt: key default: [ ^ aBlockOrNil value ])
]

{ #category : 'enumerating' }
ModestConfigurationReader >> loadAt: key required: isRequired [

	^ self loadAt: key withConfiguration: (self
			   configurationAt: key
			   default: (isRequired ifFalse: [ [ ^ nil ] ]))
]

{ #category : 'enumerating' }
ModestConfigurationReader >> loadAt: key withConfiguration: config [
	"Instantiate the configured type(s) and set their fields."

	| aRegistry |
	aRegistry := self
		             resolve: key
		             in: registry
		             ifAbsent: [ :subKey :resolved |
			             ModestConfigurationRegistryError
				             signalFor: subKey
				             in: resolved ].

	"Resolves to a single item"
	config isDictionary ifTrue: [
		^ self
			  loadFrom: aRegistry
			  at: (config
					   at: '@type'
					   ifAbsent: [
					   ModestConfigurationMissing signalFor: key , '.@type' ])
			  withConfiguration: config ].

	"Must resolve to a list of items"
	config isArray ifFalse: [
		ModestConfigurationError signal:
			'Expected a dictionary or an array at `' , key , '`' ].

	^ config withIndexCollect: [ :itemConfig :index |
		  self
			  loadFrom: aRegistry
			  at: (itemConfig at: '@type' ifAbsent: [
					   ModestConfigurationMissing signalFor:
						   key , '[' , index asString , '].@type' ])
			  withConfiguration: itemConfig ]
]

{ #category : 'enumerating' }
ModestConfigurationReader >> loadFrom: aRegistry at: key withConfiguration: aConfiguration [
	"Instantiate the configured type(s) and set their fields."

	| instance |
	instance := (aRegistry at: key asLowercase ifAbsent: [
		             ModestConfigurationRegistryError
			             signalFor: key asLowercase
			             in: aRegistry ]) new.
	aConfiguration keysAndValuesDo: [ :field :value |
		field = '@type' ifFalse: [ "Load objects, can be of another type from a subregistry"
			instance perform: field asSymbol asMutator with: (self
					 loadFrom: (aRegistry at: field ifAbsent: [ aRegistry ])
					 parseValue: value) ] ].
	^ instance
]

{ #category : 'enumerating' }
ModestConfigurationReader >> loadFrom: aRegistry parseValue: value [

	value isArray ifTrue: [
		^ value collect: [ :elem |
			  self loadFrom: aRegistry parseValue: elem ] ].
	^ (value isDictionary and: [ value includesKey: '@type' ])
		  ifFalse: [ "Regular value" self parseValue: value ]
		  ifTrue: [ "Instantiate another type"
			  self
				  loadFrom: aRegistry
				  at: (value at: '@type')
				  withConfiguration: value ]
]

{ #category : 'instance creation' }
ModestConfigurationReader >> newTraceDistinctQuery [

	^ OTelDistinctQuery selector: [ :span |
		  | tags |
		  tags := span tags.
		  ((tags
			    at: configuration traceReceiverKey
			    ifPresent: [ :receiver | { receiver } ]
			    ifAbsent: [ {  } ]) , {
			   (tags at: configuration traceClassKey).
			   (tags at: configuration traceMethodKey).
			   (tags at: configuration traceArgumentsKey).
			   (tags at: configuration traceResultKey) }) hash ]
]

{ #category : 'instance creation' }
ModestConfigurationReader >> newTraceTransformers [

	^ {
		  [ :traceModel |
		  [ 'Loaded ' , traceModel allSpans size asString , ' spans.' ]
			  record.
		  traceModel ].

		  self newTraceDistinctQuery.

		  [ :traceModel |
		  [
		  'Keeping ' , traceModel allSpans size asString , ' unique spans.' ]
			  record.
		  traceModel ] }
]

{ #category : 'enumerating' }
ModestConfigurationReader >> optionalDirectoryAt: key default: aBlockOrNil [

	^ rawConfiguration
		  at: key
		  ifPresent: [ :path |
			  (self parseString: path) asFileReference
				  ifExists: [ :dir | dir asAbsolute canonicalize ]
				  ifAbsent: [
				  ModestConfigurationMissingDirectory signalFor: key path: path ] ]
		  ifAbsent: [ "Missing configuration, no problem"
			  aBlockOrNil value ifNotNil: [ :directory |
				  directory
					  ifExists: [ "Register in rawConfig to allow references"
						  rawConfiguration
							  at: key
							  put: directory absolutePath canonicalize pathString ]
					  ifAbsent: [ nil ] ] ]
]

{ #category : 'parsing' }
ModestConfigurationReader >> parseEvaluatedString: str [

	^ [ OpalCompiler new evaluate: (self parseRegularString: str) ]
		  on: Error
		  do: [ :error |
			  ModestConfigurationError signal:
				  'Error evaluating code string `' , str , '` resulting in: '
				  , error printString ]
]

{ #category : 'parsing' }
ModestConfigurationReader >> parseFileString: str [
	"The string references a file whose contents are read."

	(self parseRegularString: str) asFileReference ifExists: [ :file |
		^ file contents ].
	ModestConfigurationError signal:
		'File at `' , str , '` does not exist.'
]

{ #category : 'parsing' }
ModestConfigurationReader >> parseRegularString: str [
	"The string may reference other values in the configuration by giving their path in braces."

	^ str copyWithRegex: '\{[^}]*\}' matchesTranslatedUsing: [ :match |
		  | value |
		  value := self
			           resolve: (match copyFrom: 2 to: match size - 1)
			           in: rawConfiguration
			           ifAbsent: [ :key :config |
				           ModestConfigurationError signal:
					           'Failed to resolve `' , key
					           , '` in string reference `' , match
					           , '` within the value `' , str , '`.' ].
		  value isString ifFalse: [
			  ModestConfigurationError signal:
				  'String reference `' , match , '` within the value `' , str
				  , '` must resolve to a string.' ].
		  self parseString: value ]
]

{ #category : 'parsing' }
ModestConfigurationReader >> parseString: str [
	"String values can either:
	- evaluate Pharo code,
	- read the contents of a file,
	- read an environment variable,
	- interpolate references to other values from the configuration."

	| firstChar |
	str ifEmpty: [ ^ str ].
	firstChar := str at: 1.
	firstChar == $= ifTrue: [
		^ self parseEvaluatedString: str allButFirst ].
	firstChar == $< ifTrue: [ ^ self parseFileString: str allButFirst ].
	firstChar == $$ ifTrue: [
		^ self parseVariableString: str allButFirst ].
	^ self parseRegularString: str
]

{ #category : 'parsing' }
ModestConfigurationReader >> parseValue: value [

	value isString ifTrue: [ ^ self parseString: value ].
	value isArray ifTrue: [
		^ value collect: [ :elem | self parseValue: elem ] ].
	value isDictionary ifTrue: [
		^ value associations
			  collect: [ :assoc |
				  (self parseValue: assoc key) -> (self parseValue: assoc value) ]
			  as: Dictionary ].
	^ value "Number or boolean or nil"
]

{ #category : 'parsing' }
ModestConfigurationReader >> parseVariableString: str [

	^ OSEnvironment current
		  at: (self parseRegularString: str)
		  ifAbsent: [
			  ModestConfigurationError signal:
				  'Environment variable named `' , str , '` not found.' ]
]

{ #category : 'configuration' }
ModestConfigurationReader >> readAdditionalConfiguration [
	"Depending on the current state of the configuration, read additional entries."

	configuration language = 'java' ifTrue: [ self readJavaConfiguration ]
]

{ #category : 'configuration' }
ModestConfigurationReader >> readBaseConfiguration [
	"Read application name and language, then find the corresponding model in the image."

	| name |
	configuration name:
		(name := (self configurationAt: 'name') asLowercase).
	configuration language:
		(self configurationAt: 'language') asLowercase.

	configuration famixModel:
		(FamixModel root
			 detect: [ :m | m name asLowercase = name ]
			 ifNone: [
				 ModestConfigurationError signal:
					 'Unable to find application model named `' , name , '`.' ])
]

{ #category : 'configuration' }
ModestConfigurationReader >> readConfiguration [
	"Order is important because of lookups, e.g. referencing the export directory."

	self readBaseConfiguration.
	self readDirectoryConfiguration.
	self readAdditionalConfiguration.
	self readTraceConfiguration.
	self readValueConfiguration.
	self readTestConfiguration.
	^ configuration
]

{ #category : 'configuration' }
ModestConfigurationReader >> readConfigurationFrom: aDictionary [

	rawConfiguration := aDictionary.
	^ self readConfiguration
]

{ #category : 'configuration' }
ModestConfigurationReader >> readConfigurationFromFile: aFile [

	^ self readConfigurationFrom:
		  (aFile asFileReference readStreamDo: [ :s | STON fromStream: s ])
]

{ #category : 'configuration' }
ModestConfigurationReader >> readDirectoryConfiguration [

	configuration localDirectory: (self
			 existingDirectoryAt: 'localDirectory'
			 default: [ 'pharo-local' asFileReference / 'modest' ]).

	configuration sourceDirectory: (self
			 existingDirectoryAt: 'sourceDirectory'
			 default: [ configuration famixModel rootFolder ]).
	self updateSourceAnchors.

	configuration exportDirectory:
		(self configurationAt: 'exportDirectory') asFileReference.

	"Additional directories"
	configuration tracesDirectory: (self
			 optionalDirectoryAt: 'tracesDirectory'
			 default: [
			 (configuration localDirectory / 'traces') ensureCreateDirectory ]).
	configuration libDirectory: (self
			 optionalDirectoryAt: 'libDirectory'
			 default: [
			 (configuration localDirectory / 'lib') ensureCreateDirectory ]).
	(self optionalDirectoryAt: 'coverageTargetDirectory' default: nil)
		ifNotNil: [ :coverageTargetDirectory |
			configuration coverageTargetDirectory: coverageTargetDirectory ]
]

{ #category : 'configuration' }
ModestConfigurationReader >> readJavaConfiguration [

	configuration classpath: (self configurationAt: 'classpath').

	configuration codeFormatter:
		(self loadAt: 'tests.codeFormatter' required: false).

	configuration refactorer: FASTRJava new.

	(self configurationAt: 'testDependencies' required: false) ifNotNil: [
		:classpath | "For generated test dependencies, TODO compute it automatically based on exporters and strategies"
		configuration testDependencies: classpath ]
]

{ #category : 'configuration' }
ModestConfigurationReader >> readTestConfiguration [

	configuration testExporter: ((self loadAt: 'tests.exporter')
			 valueExporter: configuration valueExporter;
			 initializeWith: configuration entityFinder).

	(self
		 loadAt: 'tests.codeExporter'
		 default: [
		 ModestAbstractCodeExporter defaultFor: configuration language ])
		ifNotNil: [ :codeExporter |
		configuration codeExporter: codeExporter ].

	configuration testSuiteReducer:
		(self loadAt: 'tests.suiteReducer' required: false)
]

{ #category : 'configuration' }
ModestConfigurationReader >> readTraceConfiguration [

	configuration traceClassKey:
		(self configurationAt: 'traces.classKey').
	configuration traceMethodKey:
		(self configurationAt: 'traces.methodKey').
	configuration traceReceiverKey:
		(self configurationAt: 'traces.receiverKey' required: false).
	configuration traceArgumentsKey:
		(self configurationAt: 'traces.argumentsKey').
	configuration traceResultKey:
		(self configurationAt: 'traces.resultKey').

	configuration traceExtractor: (self loadAt: 'traces.extractor').
	configuration traceLoader: (self loadAt: 'traces.loader').
	"always use a distinct query"
	configuration traceTransformers:
		((self loadAt: 'traces.transformers' required: false)
			 ifNil: [ self newTraceTransformers ]
			 ifNotNil: [ :transformers |
			 self newTraceTransformers , transformers ])
]

{ #category : 'configuration' }
ModestConfigurationReader >> readValueConfiguration [

	| entityFinder |
	entityFinder := (configuration language = 'java'
		                 ifTrue: [ FamixJavaEntityFinder ]
		                 ifFalse: [ FamixEntityFinder ]) new
		                model: configuration famixModel;
		                replacements: (self
				                 configurationAt: 'values.replacements'
				                 default: [ Dictionary new ]).

	configuration entityFinder: entityFinder.

	configuration valueImporter:
		((self loadAt: 'values.importer') entityFinder: entityFinder).

	"the type of the exporter depends on the language"
	configuration valueExporter: (self
			 loadAt: 'values.exporter'
			 withConfiguration:
				 ((self
					   configurationAt: 'values.exporter'
					   default: [ Dictionary new ])
					  at: '@type' put: configuration language;
					  yourself))
]

{ #category : 'initialization' }
ModestConfigurationReader >> registerSubclassesOf: aClass in: aRegistry [

	| affixes prefix suffix |
	affixes := aClass name findBetweenSubstrings: #( 'Abstract' ).
	prefix := affixes first.
	suffix := affixes last.
	aClass allSubclassesDo: [ :subclass |
		subclass isAbstract ifFalse: [
			| name |
			name := (name := subclass name)
				        copyFrom: prefix size + 1
				        to: ((name endsWith: suffix)
						         ifTrue: [ name size - suffix size ]
						         ifFalse: [ name size ]).
			aRegistry at: name asLowercase put: subclass ] ]
]

{ #category : 'enumerating' }
ModestConfigurationReader >> resolve: key in: dictionary ifAbsent: block [

	| value |
	value := dictionary.
	($. split: key) do: [ :subKey |
		value := value
			         at: subKey
			         ifAbsent: [ block cull: subKey cull: value ] ].
	^ value
]

{ #category : 'updating' }
ModestConfigurationReader >> updateSourceAnchors [
	"Update all file source anchors in the model according to the configuration."

	| newPath |
	newPath := configuration sourceDirectory absolutePath canonicalize
		           pathString.
	configuration famixModel rootFolder: newPath.
	((configuration famixModel allUsing: FamixTFileAnchor) groupedBy: [
		 :anchor | anchor fileName ]) do: [ :anchors |
		self updateSourceAnchors: anchors with: newPath ]
]

{ #category : 'updating' }
ModestConfigurationReader >> updateSourceAnchors: anchors with: newPath [
	"Update all file source anchors of a common file, according to the configuration."

	| oldPath prefixSize fileName |
	oldPath := anchors anyOne fileName.
	((oldPath beginsWith: newPath) and: [ oldPath asFileReference exists ])
		ifTrue: [ ^ self ].

	prefixSize := 0.
	[ "cut down oldPath from the root and prefix newPath until it exists"
	(prefixSize := oldPath indexOf: $/ startingAt: prefixSize + 1) = 0
		ifTrue: [
			ModestConfigurationSourceNotFound
				signalFor: anchors anyOne
				in: newPath ].

	(fileName := newPath , (oldPath allButFirst: prefixSize - 1))
		asFileReference ifExists: [ :file |
		^ anchors do: [ :anchor | anchor fileName: fileName ] ] ] repeat
]
