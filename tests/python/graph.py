import maude
import os.path

def exploreAndGraph(graph, stateNr):
	print(stateNr, '[label="' + str(graph.getStateTerm(stateNr)) + '"];')

	index = 0
	nextState = graph.getNextState(stateNr, index)

	while nextState >= 0:
		print(stateNr, '->', nextState, ';')

		if nextState > stateNr:
			exploreAndGraph(graph, nextState)

		index = index + 1
		nextState = graph.getNextState(stateNr, index)

maude.init(advise=False)
maude.load(os.path.join(os.path.dirname(__file__), '..', 'example.maude'))

example = maude.getModule('EXAMPLE')
initial = example.parseTerm('f(a, a)')
graph = maude.RewriteGraph(initial)

print('digraph {')
exploreAndGraph(graph, 0)
print('}')
