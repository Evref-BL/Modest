Extension { #name : #OTelJSONFileExtractor }

{ #category : #'*Modest-Report' }
OTelJSONFileExtractor >> reportOn: report [

	super reportOn: report.
	report <@ 'filename' => filename
]
