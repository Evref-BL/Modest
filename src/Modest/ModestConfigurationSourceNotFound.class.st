"
Thrown when updating the codebase source directory but failing to find an existing file.
"
Class {
	#name : 'ModestConfigurationSourceNotFound',
	#superclass : 'ModestConfigurationError',
	#category : 'Modest-Configuration',
	#package : 'Modest',
	#tag : 'Configuration'
}

{ #category : 'signalling' }
ModestConfigurationSourceNotFound class >> signalFor: source in: path [

	self new
		messageText: (String streamContents: [ :s |
					 s << 'Failed to adopt `sourceDirectory`: The file `'
					 << (source fileName copyAfterLast: $/)
					 << '` could not be found in `' << path
					 << '` using any suffix of the path `'
					 << (source fileName copyUpToLast: $/) << '` as a subpath.' ]);
		signal
]
