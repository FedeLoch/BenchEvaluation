Class {
	#name : 'BenchAnalysis',
	#superclass : 'Object',
	#instVars : [
		'benchmarkConfigs',
		'mutants',
		'time',
		'maxCases'
	],
	#category : 'BenchEvaluation-Analysis',
	#package : 'BenchEvaluation',
	#tag : 'Analysis'
}

{ #category : 'as yet unclassified' }
BenchAnalysis class >> performExperimentsByCounOfCases: cases [

	^ cases collect: [ :amount | self new countOfCases: amount; analyze ]
]

{ #category : 'as yet unclassified' }
BenchAnalysis class >> performExperimentsWithTimes: times [

	^ times collect: [ :time | self new time: time; analyze ]
]

{ #category : 'as yet unclassified' }
BenchAnalysis class >> performExperimentsWithTimes: times threshold: aThreshold [

	^ times collect: [ :time | self new time: time; threshold: aThreshold; analyze ]
]

{ #category : 'running' }
BenchAnalysis class >> run [

	^ self new analyze
]

{ #category : 'as yet unclassified' }
BenchAnalysis >> allMethodsOfPackage: package inTag: atag [

	^ (RPackageOrganizer default packageNamed: package) definedClasses inject: OrderedCollection new into: [ :acc :className |
		(className packageTag name = atag) ifTrue: [
			acc addAll: className methods
		].
	acc
]
]

{ #category : 'private' }
BenchAnalysis >> analyze [

	| result |
	self setUpBenchmarks.
	
	result := (BenchAnalysisResult new title: 'Result running ', self criteriaLabel, ' each configuration ') start.

	mutants do: [ :mutant |
		mutant install.
		benchmarkConfigs do: [ :config |
			result detect: (self run: config for: self time untilSatisfiesFor: result) from: config forMutant: mutant.
		].
		mutant uninstall.
		result.
	].

	^ result end.
]

{ #category : 'initialization' }
BenchAnalysis >> benchmarkConfigs [

	self subclassResponsibility
]

{ #category : 'accessing' }
BenchAnalysis >> classesToMutate [

	self subclassResponsibility
]

{ #category : 'as yet unclassified' }
BenchAnalysis >> countOfCases [

	^ maxCases 
]

{ #category : 'as yet unclassified' }
BenchAnalysis >> countOfCases: anAmount [

	maxCases := anAmount 
]

{ #category : 'private' }
BenchAnalysis >> criteriaLabel [

	^ self subclassResponsibility 
]

{ #category : 'initialization' }
BenchAnalysis >> initialize [

	super initialize.
	mutants := self mutants.
]

{ #category : 'initialization' }
BenchAnalysis >> methodsToMutate [

	^ self subclassResponsibility 
]

{ #category : 'initialization' }
BenchAnalysis >> mutants [

	^ (MTManualMutatedMethodGenerationStrategy new targetMethods: self methodsToMutate) mutationsFor: PBTPerformanceOperations
]

{ #category : 'private' }
BenchAnalysis >> run: config for: aTime untilSatisfiesFor: result [

	^ config runWithCriteria: [ :tests :elapsedTime :coverage |
		tests isEmpty or: [
			((self shouldStop: tests in: elapsedTime) or: [ result testSatisfy: tests last for: config ]) not
		]
	].


]

{ #category : 'initialization' }
BenchAnalysis >> setUpBenchmarks [

	benchmarkConfigs := self benchmarkConfigs.
	benchmarkConfigs do: [ :config | config generateTests ]
]

{ #category : 'private' }
BenchAnalysis >> shouldStop: tests in: elapsedTime [

	^ time
		  ifNil: [ tests size >= maxCases ]
		  ifNotNil: [ (Duration milliSeconds: time) >= elapsedTime ]
]

{ #category : 'accessing' }
BenchAnalysis >> time [
	
	^ time
]

{ #category : 'accessing' }
BenchAnalysis >> time: aTime [

	time := aTime 
]
