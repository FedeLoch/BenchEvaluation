Class {
	#name : 'BenchAnalysisResult',
	#superclass : 'Object',
	#instVars : [
		'comparisons',
		'fixedThreshold',
		'mutants',
		'title',
		'initialTime',
		'elapsedTime',
		'baselines'
	],
	#category : 'BenchEvaluation-Analysis',
	#package : 'BenchEvaluation',
	#tag : 'Analysis'
}

{ #category : 'adding' }
BenchAnalysisResult >> detect: benchResult from: config forMutant: mutant [

	comparisons at: config title ifAbsentPut: Dictionary new.
	
	mutants at: mutant operator title update: [ :val | val + 1 ] initial: 0.
	
	(comparisons at: config title)
		at: mutant operator title
		update: [ :val | val + ((self detected: benchResult from: config) ifTrue: [ 1 ] ifFalse: [ 0 ]) ]
		initial: 0
]

{ #category : 'adding' }
BenchAnalysisResult >> detected: benchResult from: config [

	| threshold |
	threshold := self thresholdOf: config.
	
	^ benchResult tests anySatisfy: [ :test | self testSatisfy: test with: threshold ]
]

{ #category : 'accessing' }
BenchAnalysisResult >> end [

	elapsedTime := Duration milliSeconds: (Smalltalk highResClock) - initialTime. 
]

{ #category : 'adding' }
BenchAnalysisResult >> initialize [ 

	super initialize.
	comparisons := Dictionary new.
	baselines := Dictionary new.
	mutants := Dictionary new.
	
]

{ #category : 'private - inspector accessing' }
BenchAnalysisResult >> plotBaselines [

	| canvas |
	
	canvas := RSCanvas new @ RSCanvasController.
	canvas addAll: (baselines collect: #boxPlot).
	
	RSHorizontalLineLayout new alignBottom; on: canvas shapes.
	
	^ canvas
]

{ #category : 'private - inspector accessing' }
BenchAnalysisResult >> plotBenchmarksEffectiveness [

	| heatMap values |
	
	heatMap := RSHeatmap new.
	heatMap colorPalette: (NSScale linear range: { Color white . Color red }).
	heatMap shape extent: 60@40.
	
	values := comparisons keys inject: OrderedCollection new into: [ :matrix :strategy | | localValues |
		localValues := (self sortedMutantsAt: strategy) collect: [ :mutant |
			Fraction numerator: (comparisons at: strategy at: mutant) denominator: (mutants at: mutant)
		].
		
		matrix add: localValues.
		matrix
	].
	
	heatMap objectsX: (self sortedMutantsAt: comparisons keys first).
	heatMap objectsY: comparisons keys.
   heatMap dataMatrix: values.
	
	^ heatMap open
]

{ #category : 'private - inspector accessing' }
BenchAnalysisResult >> sortedMutantsAt: aStrategy [

	^ (comparisons at: aStrategy) keys sort: [ :m1 :m2 | (m1 splitOn: ' ') first asInteger > (m2 splitOn: ' ') first asInteger ]
]

{ #category : 'accessing' }
BenchAnalysisResult >> start [

	initialTime := Smalltalk highResClock.
]

{ #category : 'tests' }
BenchAnalysisResult >> testSatisfy: aTest for: aConfig [

	^ self testSatisfy: aTest with: (self thresholdOf: aConfig) 
	
]

{ #category : 'tests' }
BenchAnalysisResult >> testSatisfy: aTest with: threshold [

	^ aTest time asMilliSeconds >= threshold
	
]

{ #category : 'adding' }
BenchAnalysisResult >> thresholdOf: config [

	| stdevs baseline |
	stdevs := 1.
	
	baselines at: config title ifAbsentPut: config baseline.
	baseline := baselines at: config title.

	^ baseline median + (stdevs * baseline stdev)
]

{ #category : 'adding' }
BenchAnalysisResult >> title: aTitle [

	title := aTitle 
]
