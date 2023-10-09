Extension { #name : #OTelFamixLinker }

{ #category : #'*Modest-Report' }
OTelFamixLinker >> reportOn: report [

	report writeSection: 'importer' about: importer.
	report <@ 'classKey' => classKey <@ 'methodKey' => methodKey
]
