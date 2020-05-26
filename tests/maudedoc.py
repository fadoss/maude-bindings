import maude
import sys

def printElements(name, elems):
	if len(elems) == 0:
		return

	print('<h2>', name, '</h2>')
	print('<ul>')

	for elem in elems:
		print('<li>', elem)

	print('</ul>')

MODULE_TYPE_NAMES = {
	maude.Module.FUNCTIONAL_MODULE: "fmod",
	maude.Module.SYSTEM_MODULE: "smod",
	maude.Module.STRATEGY_MODULE: "smod",
	maude.Module.FUNCTIONAL_THEORY: "fth",
	maude.Module.SYSTEM_THEORY: "th",
	maude.Module.STRATEGY_THEORY: "sth"
}


if __name__ == "__main__":

	maude.init(advise=False)

	# Get the current module if a module name has not been
	# given in the first argument
	if len(sys.argv) >= 2:
		m = maude.getModule(sys.argv[1])
	else:
		m = maude.getCurrentModule()

	print("""<!DOCTYPE HTML>
	<html>
	<head>
		<meta charset="utf-8" />
	</head>
	<body>
	""")

	print("<h1>", MODULE_TYPE_NAMES[m.getModuleType()], m, "</h1>")

	printElements('Sorts', m.getSorts())
	printElements('Operators', m.getSymbols())
	printElements('Membership axioms', m.getMembershipAxioms())
	printElements('Equations', m.getEquations())
	printElements('Rules', m.getRules())
	printElements('Strategies', m.getStrategies())
	printElements('Strategy definitions', m.getStrategyDefinitions())

	print("""</body>
</html>""")
