Extension { #name : #OTelAbstractExtractor }

{ #category : #'*Modest-Report' }
OTelAbstractExtractor >> reportOn: report [

	outputFilename ifNotNil: [
		report <@ 'outputFilename' => outputFilename ]
]
