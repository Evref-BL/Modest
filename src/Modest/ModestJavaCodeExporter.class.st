Class {
	#name : 'ModestJavaCodeExporter',
	#superclass : 'ModestAbstractCodeExporter',
	#category : 'Modest',
	#package : 'Modest'
}

{ #category : 'testing' }
ModestJavaCodeExporter class >> isDefaultFor: aLanguageName [

	^ aLanguageName = 'java'
]

{ #category : 'exporting' }
ModestJavaCodeExporter >> exportFor: aTestGenerator [

	| exportDirectory compilationUnits exported |
	exportDirectory := aTestGenerator exportDirectory.
	compilationUnits := aTestGenerator testASTModel allWithType:
		                    FASTJavaCompilationUnit.
	exported := OrderedCollection new: compilationUnits size.

	compilationUnits do: [ :ast |
		| file contents |
		ast classDeclarations
			ifEmpty: [ "Unsure whether to allow this to happen or not.
				Should the AST exporter ensure cleaning up empty compilation units?
				Or should this code exporter be lax and just ignore it?
				Currently, this is not supposed to happen, so it's here as a way to debug."
				Warning signal:
					'Proceed to skip compilation unit without class declaration' ]
			ifNotEmpty: [ :classDeclarations |
				file := (exportDirectory
				         / (ast packageDeclaration qualifiedName name
						          copyReplaceAll: '.'
						          with: '/') / classDeclarations first name , 'java')
					        ensureDelete ensureCreateFile.
				contents := FASTJavaExportVisitor new export: ast.
				file writeStreamDo: [ :stream | stream nextPutAll: contents ].
				exported add: file ] ].

	aTestGenerator codeFormatter formatFiles: exported.
	^ exported
]
