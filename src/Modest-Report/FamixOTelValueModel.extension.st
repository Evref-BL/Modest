Extension { #name : #FamixOTelValueModel }

{ #category : #'*Modest-Report' }
FamixOTelValueModel >> reportOn: report [

	report <@ 'entities' =>@ 'spans'
	=> (self allWithType: FamixOTelSpan) size <@ 'traces'
	=> (self allWithType: FamixOTelTrace) size <@ 'contexts'
	=> (self allWithType: FamixOTelContext) size
]
