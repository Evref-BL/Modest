Extension { #name : #FamixValueAbstractImporter }

{ #category : #'*Modest-Report' }
FamixValueAbstractImporter >> reportOn: report [

	report <@ 'entityFinder' => entityFinder className.
	report writeSection: 'application' about: entityFinder model
]
