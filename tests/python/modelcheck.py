import maude
import sys

BAR         = '\033[1;31m|\033[0m'	# A bar in red
ARROW       = '\033[1;31m∨\033[0m'	# An arrow in red
CYCLE_BAR   = '\033[1;31m| |\033[0m'	# Two bars in red
CYCLE_ARR   = '\033[1;31m| ∨\033[0m'	# A bar and an arrow in red
CYCLE_END   = '\033[1;31m< ∨\033[0m'	# Two bars in red
SOLUTION    = '\033[1;32mX\033[0m'	# An X in green
EDGE_FMT    = '\033[3m\033[36m'		# Format for edges
RESET_FMT   = '\033[0m'			# Reset format

def print_smc_trans(trans):
	return {
		maude.StrategyRewriteGraph.RULE_APPLICATION: trans.getRule(),
		maude.StrategyRewriteGraph.OPAQUE_STRATEGY : trans.getStrategy(),
		maude.StrategyRewriteGraph.SOLUTION: ''
	}[trans.getType()]

def print_smc(sgraph, result):
	"""Print the result of model checking"""

	if result.holds:
		print('The property holds.')
	else:
		print('The property does not hold.')

		# Lead-in to the cycle
		for i in range(0, len(result.leadIn)):
			next_state = result.leadIn[i+1] if i+1 < len(result.leadIn) else result.cycle[0]
			trans = sgraph.getTransition(result.leadIn[i], next_state)

			print(BAR, sgraph.getStateTerm(result.leadIn[i]))
			print(ARROW, EDGE_FMT, print_smc_trans(trans), RESET_FMT)

		# Cycle
		for i in range(0, len(result.cycle)):
			next_state = result.cycle[i+1] if i+1 < len(result.cycle) else result.cycle[0]
			trans = sgraph.getTransition(result.cycle[i], next_state)

			if trans.getType() == maude.StrategyRewriteGraph.SOLUTION:
				print(SOLUTION, sgraph.getStateTerm(result.cycle[i]))
			else:
				print(CYCLE_BAR, sgraph.getStateTerm(result.cycle[i]))
				print(CYCLE_ARR, EDGE_FMT, print_smc_trans(trans), RESET_FMT)

		if (sgraph.getTransition(result.cycle[-1], result.cycle[0]).getType()
			!= maude.StrategyRewriteGraph.SOLUTION):
			print(CYCLE_END)


def print_mc(graph, result):
	if result.holds:
		print('The property holds.')
	else:
		print('The property does not hold.')

		# Path to the cycle
		for i in range(0, len(result.leadIn)):
			next_state = result.leadIn[i+1] if i+1 < len(result.leadIn) else result.cycle[0]

			print(BAR, graph.getStateTerm(result.leadIn[i]))
			print(ARROW, EDGE_FMT, graph.getRule(result.leadIn[i], next_state), RESET_FMT)

		# Cycle
		for i in range(0, len(result.cycle)):
			next_state = result.cycle[i+1] if i+1 < len(result.cycle) else result.cycle[0]
			rule = graph.getRule(result.cycle[i], next_state)

			if rule is None:
				print(SOLUTION, graph.getStateTerm(result.cycle[i]))
			else:
				print(CYCLE_BAR, graph.getStateTerm(result.cycle[i]))
				print(CYCLE_ARR, EDGE_FMT, rule, RESET_FMT)

		if graph.getRule(result.cycle[-1], result.cycle[0]) is not None:
			print(CYCLE_END)


if __name__ == '__main__':

	if len(sys.argv) < 4 or len(sys.argv) > 7:
		print('Pretty-printer for the Maude model checker results')
		print(sys.argv[0], '<file> <initial term> <LTL formula> [<strategy>]')
		sys.exit(0)

	filename, initial, formula = sys.argv[1:4]

	maude.init(advise=False)
	if not maude.load(filename):
		print('Error loading file.')
		sys.exit(1)

	mod = maude.getCurrentModule()

	# Parse the initial term
	t = mod.parseTerm(initial)

	if t is None:
		print('The initial term cannot be parsed.')
		sys.exit(2)

	# Parse the LTL formula
	f = mod.parseTerm(formula)

	if f is None:
		print('The LTL formula cannot be parsed.')
		sys.exit(3)

	# If model checking with strategy
	if len(sys.argv) > 4:
		# Parse the strategy expression
		s = mod.parseStrategy(sys.argv[4])

		if s is None:
			print('The strategy expression cannot be parsed.')
			sys.exit(4)

		print('Model checking', f, 'from', initial, 'using', s, 'in module', mod)

		sgraph = maude.StrategyRewriteGraph(t, s)
		result = sgraph.modelCheck(f)

		print_smc(sgraph, result)

	else:
		print('Model checking', f, 'from', initial, 'in module', mod)

		graph = maude.RewriteGraph(t)
		result = graph.modelCheck(f)

		print_mc(graph, result)
