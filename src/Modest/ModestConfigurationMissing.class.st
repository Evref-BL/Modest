"
Thrown when the configuration file or a required configuration item is missing.
"
Class {
	#name : 'ModestConfigurationMissing',
	#superclass : 'ModestConfigurationError',
	#category : 'Modest-Configuration',
	#package : 'Modest',
	#tag : 'Configuration'
}

{ #category : 'signalling' }
ModestConfigurationMissing class >> signalFor: aKey [

	self new
		messageText:
			'Configuration is missing the required key `' , aKey , '`.';
		signal
]

{ #category : 'accessing' }
ModestConfigurationMissing >> messageText [
	"Return an exception's message text."

	^ messageText ifNil: [
		  messageText := 'Configuration file not found. Its path can be given as the first CLI argument or with the MODEST_CONFIGURATION environment variable. Falls back to the default location: ./pharo-local/modest/modest.json.' ]
]
