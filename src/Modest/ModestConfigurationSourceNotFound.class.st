"
Thrown when updating the codebase source directory but failing to find an existing file.
"
Class {
	#name : #ModestConfigurationSourceNotFound,
	#superclass : #ModestConfigurationError,
	#category : #'Modest-Configuration'
}

{ #category : #signalling }
ModestConfigurationSourceNotFound class >> signalFor: source in: path [

	self new
		messageText: 'Failed to adopt `sourceDirectory`: file `'
			, (source fileName copyAfterLast: $/) , '` not found in `' , path
			, '` with any suffix of `' , source fileName , '` as subpath.';
		signal
]
