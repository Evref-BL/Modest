Extension { #name : #OTelFamixValueLinker }

{ #category : #'*Modest-Report' }
OTelFamixValueLinker >> reportOn: report [

	super reportOn: report.
	report <@ 'argsKey' => argsKey <@ 'resultKey' => resultKey
	<@ 'shouldLinkResultFirst' => shouldLinkResultFirst
	<@ 'shouldResetImporter' => shouldResetImporter
]
