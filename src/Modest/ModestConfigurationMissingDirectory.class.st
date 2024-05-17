"
Thrown when a configured directory that is required to exist is missing.
"
Class {
	#name : #ModestConfigurationMissingDirectory,
	#superclass : #ModestConfigurationError,
	#category : #'Modest-Configuration'
}

{ #category : #signalling }
ModestConfigurationMissingDirectory class >> signalFor: directory path: path [

	self new
		messageText: 'Unable to find ' , directory , ' at '
			, path asFileReference absolutePath canonicalize pathString , '.';
		signal
]
