Extension { #name : #OpenTelemetryImporter }

{ #category : #'*Modest-Report' }
OpenTelemetryImporter >> reportOn: report [

	report writeSection: 'open_telemetry' with: [
		report writeSection: 'extractor' about: extractor.
		report <@ 'loader' => loader className.
		transformers ifNotEmpty: [
			report
				writeSection: 'transformers'
				with: [ report writeList: transformers ] ].
		loader model reportOn: report ]
]
