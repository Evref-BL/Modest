Extension { #name : #FamixJavaModel }

{ #category : #'*Modest-Report' }
FamixJavaModel >> reportOn: report [

	report <@ 'size' => self size <@ 'rootFolder' => self rootFolder
]
