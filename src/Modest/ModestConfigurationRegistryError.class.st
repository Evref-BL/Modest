"
Thrown when a configuration item refers to a type that does not exist.
"
Class {
	#name : 'ModestConfigurationRegistryError',
	#superclass : 'ModestConfigurationError',
	#category : 'Modest-Configuration',
	#package : 'Modest',
	#tag : 'Configuration'
}

{ #category : 'signalling' }
ModestConfigurationRegistryError class >> signalFor: key in: registry [

	self new
		messageText: (String streamContents: [ :s |
					 s << 'Class for `' << key
					 << '` not found in registry, expected one of: '.
					 registry keys do: [ :k | s << k ] separatedBy: [ s << ', ' ].
					 s nextPut: $. ]) contents;
		signal
]
