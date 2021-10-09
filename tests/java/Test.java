import es.ucm.maude.bindings.*;

public class Test {
	static {
		System.loadLibrary("maudejni");
	}

	private static void printPath(RewriteSequenceSearch search) {
		System.out.print("[");
		printPath(search, search.getStateNr());
		System.out.print("]");
	}

	private static void printPath(StrategySequenceSearch search) {
		System.out.print("[");
		printPath(search, search.getStateNr());
		System.out.print("]");
	}

	private static void printPath(RewriteSequenceSearch search, int stateNr) {

		int parent = search.getStateParent(stateNr);

		if (parent < 0) {
			System.out.print(search.getStateTerm(stateNr));
		}
		else {
			printPath(search, parent);
			System.out.print(", " + search.getRule(stateNr) + ", " + search.getStateTerm(stateNr));
		}
	}

	private static void printPath(StrategySequenceSearch search, int stateNr) {

		int parent = search.getStateParent(stateNr);

		if (parent < 0) {
			System.out.print(search.getStateTerm(stateNr));
		}
		else {
			printPath(search, parent);
			System.out.print(", " + search.getTransition(stateNr) + ", " + search.getStateTerm(stateNr));
		}
	}

	public static void main(String[] args) {
		maude.init();
		maude.load("../example.maude");

		var example = maude.getCurrentModule();
		var nat = maude.getModule("NAT");

		////////

		Term t = nat.parseTerm("1 + (3 * 5 + 7) * 11 + 13");
		Term t0 = t.copy();
		t.reduce();
		System.out.println(t0 + " = " + t);

		////////

		t = example.parseTerm("f(a, b)");
		t.rewrite();
		System.out.println(t);

		////////

		t = example.parseTerm("f(a, a)");
		t.frewrite(1);
		System.out.println(t);

		////////

		t = example.parseTerm("f(b, b)");
		TermIntPair pair = t.erewrite();
		System.out.println(t + " -> " + pair.getFirst() + " in " + pair.getSecond() + " rewrites");

		////////

		t = example.parseTerm("f(a, b)");

		var results = t.srewrite(example.parseStrategy("swap *"));

		for (var result : results)
			System.out.println(result + " in " + results.getRewriteCount() + " rewrites");

		///////


		Term initial = example.parseTerm("f(a, a)");
		Term pattern = example.parseTerm("f(c, X:Symbol)");

		{
			var sresults = initial.search(SearchType.ANY_STEPS, pattern);

			for (var result : sresults) {
				System.out.print(result + " with " + sresults.getSubstitution().toString() + " by ");
				printPath(sresults);
				System.out.println();
			}
		}

		StrategyExpression s = example.parseStrategy("ab ; bc ; ab");

		{
			var sresults = initial.search(SearchType.ANY_STEPS, pattern, s);

			for (var result : sresults) {
				System.out.print(String.format("%s with %s by ", result, sresults.getSubstitution()));
				printPath(sresults);
				System.out.println(" before applying " + sresults.getStrategyContinuation());
			}
		}
	}
};
