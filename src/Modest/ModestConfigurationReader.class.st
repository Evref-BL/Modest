"
I consume a configuration file located at the specified path from one of the following sources, in order of highest to lowest priority:
- first CLI argument
- `MODEST_CONFIGURATION` environment variable
- the default location, `./pharo-local/modest/modest.json`
"
Class {
	#name : #ModestConfigurationReader,
	#superclass : #Object,
	#instVars : [
		'configuration',
		'registry',
		'rawConfiguration'
	],
	#category : #'Modest-Configuration'
}

{ #category : #enumerating }
ModestConfigurationReader class >> findConfigurationFile [
	"Can be given as first CLI argument or with the MODEST_CONFIGURATION environment variable.
	Falls back to the default location: ./pharo-local/modest/config.json."

	^ (Smalltalk arguments
		   ifNotEmpty: [ :arguments | arguments first ]
		   ifEmpty: [
			   OSEnvironment current
				   at: 'MODEST_CONFIGURATION'
				   ifAbsent: [ "default location"
					   ('pharo-local' asFileReference / 'modest') children
						   detect: [ :file | file basename asLowercase = 'modest.json' ]
						   ifNone: [ ModestConfigurationMissing signal ] ] ])
		  asFileReference ifAbsent: [ ModestConfigurationMissing signal ]
]

{ #category : #configuration }
ModestConfigurationReader class >> readConfiguration [

	^ self readConfigurationFromFile: self findConfigurationFile
]

{ #category : #configuration }
ModestConfigurationReader class >> readConfigurationFrom: aDictionary [

	^ self new readConfigurationFrom: aDictionary
]

{ #category : #configuration }
ModestConfigurationReader class >> readConfigurationFromFile: aConfigurationFile [

	^ self new readConfigurationFromFile: aConfigurationFile
]

{ #category : #enumerating }
ModestConfigurationReader >> configurationAt: key [

	^ self configurationAt: key default: nil
]

{ #category : #enumerating }
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

{ #category : #enumerating }
ModestConfigurationReader >> existingDirectoryAt: key default: aBlockOrNil [
	"Find a directory that must already exist.
	In case the default is triggered, update the raw config to enable references."

	| path directory |
	path := self configurationAt: key default: [
		        | default |
		        rawConfiguration
			        at: key
			        put: (default := aBlockOrNil value) absolutePath pathString.
		        default ].
	(directory := path asFileReference) ifAbsent: [
		ModestConfigurationMissingDirectory signalFor: key path: path ].
	^ directory
]

{ #category : #initialization }
ModestConfigurationReader >> initialize [

	self initializeRegistry.
	configuration := ModestConfiguration new
]

{ #category : #initialization }
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
		registerSubclassesOf: ModestAbstractFormatter
		in: (testRegistry at: 'codeFormatter' put: Dictionary new)
]

{ #category : #enumerating }
ModestConfigurationReader >> loadAt: key [

	^ self loadAt: key required: true
]

{ #category : #enumerating }
ModestConfigurationReader >> loadAt: key required: isRequired [

	^ self
		  loadAt: key
		  withConfiguration:
		  (self
			   configurationAt: key
			   default: [ isRequired ifFalse: [ ^ nil ] ])
]

{ #category : #enumerating }
ModestConfigurationReader >> loadAt: key withConfiguration: config [
	"Instantiate the configured type(s) and set their fields."

	| resolvedRegistry |
	resolvedRegistry := self
		                    resolve: key
		                    in: registry
		                    ifAbsent: [ :subKey :resolved |
			                    ModestConfigurationRegistryError
				                    signalFor: subKey
				                    in: resolved ].
	"resolves to a single item"
	config isDictionary ifTrue: [
		^ self
			  loadFrom: resolvedRegistry
			  at: (config
					   at: '@type'
					   ifAbsent: [
					   ModestConfigurationMissing signalFor: key , '.@type' ])
			  withConfiguration: config ].
	"resolves to a list of items"
	^ config withIndexCollect: [ :itemConfig :index |
		  self
			  loadFrom: resolvedRegistry
			  at: (itemConfig at: '@type' ifAbsent: [
					   ModestConfigurationMissing signalFor:
						   key , '[' , (index - 1) asString , '].@type' ])
			  withConfiguration: itemConfig ]
]

{ #category : #enumerating }
ModestConfigurationReader >> loadFrom: aRegistry at: key withConfiguration: aConfiguration [
	"Instantiate the configured type(s) and set their fields."

	| instance |
	instance := (aRegistry at: key asLowercase ifAbsent: [
		             ModestConfigurationRegistryError
			             signalFor: key asLowercase
			             in: aRegistry ]) new.
	aConfiguration keysAndValuesDo: [ :field :value |
		field = '@type' ifFalse: [
			instance perform: field asSymbol asMutator with: (aRegistry
					 at: field
					 ifPresent: [ :fieldRegistry | "reference another type"
						 self
							 loadFrom: fieldRegistry
							 at: (value at: '@type')
							 withConfiguration: value ]
					 ifAbsent: [ self parseValue: value ]) ] ].
	^ instance
]

{ #category : #'instance creation' }
ModestConfigurationReader >> newTraceDistinctQuery [

	^ OTelDistinctQuery selector: [ :span |
		  | tags |
		  tags := span tags.
		  {
			  (tags at: configuration traceClassKey).
			  (tags at: configuration traceMethodKey).
			  (tags at: configuration traceArgumentsKey).
			  (tags at: configuration traceResultKey) } hash ]
]

{ #category : #enumerating }
ModestConfigurationReader >> optionalDirectoryAt: key default: aBlockOrNil [

	^ rawConfiguration
		  at: key
		  ifPresent: [ :path |
			  (self parseString: path) asFileReference ifAbsent: [
				  ModestConfigurationMissingDirectory signalFor: key path: path ] ]
		  ifAbsent: [
			  aBlockOrNil value ifNotNil: [ :directory |
				  directory
					  ifExists: [ "register in rawConfig to allow references"
						  rawConfiguration
							  at: key
							  put: directory absolutePath canonicalize pathString ]
					  ifAbsent: [ nil ] ] ]
]

{ #category : #parsing }
ModestConfigurationReader >> parseEvaluatedString: str [

	^ [ (RBParser parseExpression: str) evaluate ]
		  on: Error
		  do: [ :error |
			  ModestConfigurationError signal:
				  'Error evaluating code string `' , str , '` resulting in: '
				  , error messageText ]
]

{ #category : #parsing }
ModestConfigurationReader >> parseFileString: str [
	"The string references a file whose contents are read."

	(self parseRegularString: str) asFileReference ifExists: [ :file |
		^ file contents ].
	ModestConfigurationError signal:
		'File at `' , str , '` does not exist.'
]

{ #category : #parsing }
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

{ #category : #parsing }
ModestConfigurationReader >> parseString: str [
	"String values can either:
	- evaluate Pharo code,
	- read the contents of a file,
	- read an environment variable,
	- interpolate references to other values from the configuration."

	| firstChar |
	firstChar := str at: 1.
	firstChar == $= ifTrue: [
		^ self parseEvaluatedString: str allButFirst ].
	firstChar == $< ifTrue: [ ^ self parseFileString: str allButFirst ].
	firstChar == $$ ifTrue: [
		^ self parseVariableString: str allButFirst ].
	^ self parseRegularString: str
]

{ #category : #parsing }
ModestConfigurationReader >> parseValue: value [

	value isString ifTrue: [ ^ self parseString: value ].
	value isArray ifTrue: [
		^ value collect: [ :elem | self parseValue: elem ] ].
	value isDictionary ifTrue: [
		^ value associations
			  collect: [ :assoc |
				  (self parseValue: assoc key) -> (self parseValue: assoc value) ]
			  as: Dictionary ].
	"number or boolean or nil"
	^ value
]

{ #category : #parsing }
ModestConfigurationReader >> parseVariableString: str [

	^ OSEnvironment current
		  at: (self parseRegularString: str)
		  ifAbsent: [
			  ModestConfigurationError signal:
				  'Environment variable named `' , str , '` not found.' ]
]

{ #category : #configuration }
ModestConfigurationReader >> readAdditionalConfiguration [
	"Depending on the current state of the configuration, read additional entries."

	configuration language = 'java' ifTrue: [ self readJavaConfiguration ]
]

{ #category : #configuration }
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

{ #category : #configuration }
ModestConfigurationReader >> readConfiguration [

	self readBaseConfiguration.
	self readDirectoryConfiguration.
	self readTraceConfiguration.
	self readValueConfiguration.
	self readTestConfiguration.
	self readAdditionalConfiguration.
	^ configuration
]

{ #category : #configuration }
ModestConfigurationReader >> readConfigurationFrom: aDictionary [

	rawConfiguration := aDictionary.
	^ self readConfiguration
]

{ #category : #configuration }
ModestConfigurationReader >> readConfigurationFromFile: aFile [

	^ self readConfigurationFrom:
		  (aFile asFileReference readStreamDo: [ :s | STON fromStream: s ])
]

{ #category : #configuration }
ModestConfigurationReader >> readDirectoryConfiguration [

	configuration localDirectory: (self
			 existingDirectoryAt: 'localDirectory'
			 default: [ 'pharo-local' asFileReference / 'modest' ]).
	configuration sourceDirectory: (self
			 existingDirectoryAt: 'sourceDirectory'
			 default: [ configuration model rootFolder ]).
	configuration exportDirectory:
		(self configurationAt: 'exportDirectory') asFileReference.

	"additional directories"
	(self
		 optionalDirectoryAt: 'libDirectory'
		 default: [ configuration localDirectory / 'lib' ]) ifNotNil: [
		:libDirectory |
		configuration libDirectory: libDirectory asFileReference ].
	(self optionalDirectoryAt: 'coverageTargetDirectory' default: nil)
		ifNotNil: [ :coverageTargetDirectory |
			configuration coverageTargetDirectory:
				coverageTargetDirectory asFileReference ]
]

{ #category : #configuration }
ModestConfigurationReader >> readJavaConfiguration [

	configuration classpath: (self configurationAt: 'classpath').
	configuration codeFormatter: (self loadAt: 'tests.codeFormatter').
	configuration refactorer: FASTRJava new
]

{ #category : #configuration }
ModestConfigurationReader >> readTestConfiguration [

	configuration testExporter: ((self loadAt: 'tests.exporter')
			 valueExporter: configuration valueExporter;
			 initializeWith: configuration valueImporter entityFinder)
]

{ #category : #configuration }
ModestConfigurationReader >> readTraceConfiguration [

	configuration traceClassKey:
		(self configurationAt: 'traces.classKey').
	configuration traceMethodKey:
		(self configurationAt: 'traces.methodKey').
	configuration traceArgumentsKey:
		(self configurationAt: 'traces.argumentsKey').
	configuration traceResultKey:
		(self configurationAt: 'traces.resultKey').

	configuration traceExtractor: (self loadAt: 'traces.extractor').
	configuration traceLoader: (self loadAt: 'traces.loader').
	"always use a distinct query"
	configuration traceTransformers:
		((self loadAt: 'traces.transformers' required: false)
			 ifNil: [ { self newTraceDistinctQuery } ]
			 ifNotNil: [ :transformers |
			 transformers copyWith: self newTraceDistinctQuery ])
]

{ #category : #configuration }
ModestConfigurationReader >> readValueConfiguration [

	| entityFinder |
	entityFinder := (configuration language = 'java'
		                 ifTrue: [ FamixJavaEntityFinder ]
		                 ifFalse: [ FamixEntityFinder ]) new
		                model: configuration famixModel;
		                replacements: (self
				                 configurationAt: 'values.replacements'
				                 default: [ Dictionary new ]).

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

{ #category : #initialization }
ModestConfigurationReader >> registerSubclassesOf: aClass in: aRegistry [

	| affixes prefix suffix |
	affixes := aClass name findBetweenSubstrings: { 'Abstract' }.
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

{ #category : #enumerating }
ModestConfigurationReader >> resolve: key in: dictionary ifAbsent: block [

	| value |
	value := dictionary.
	($. split: key) do: [ :subKey |
		value := value
			         at: subKey
			         ifAbsent: [ block cull: subKey cull: value ] ].
	^ value
]
