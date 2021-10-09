import es.ucm.maude.bindings.*;

public class BuildTerm {
	static {
		System.loadLibrary("maudejni");
	}

	public static void main(String[] args) {
		maude.init();

		var mod  = maude.getModule("NAT");
		var natk = mod.findSort("Nat").kind();

		KindVector natk2 = new KindVector(2);

		natk2.set(0, natk);
		natk2.set(1, natk);

		Symbol splus  = mod.findSymbol("_+_", natk2, natk);
		Symbol stimes = mod.findSymbol("_*_", natk2, natk);

		// Constructs 4 + (3 * (1 + 2))
		TermVector onetwo = new TermVector();
		TermVector three  = new TermVector();
		TermVector whole  = new TermVector();

		onetwo.add(mod.parseTerm("1"));
		onetwo.add(mod.parseTerm("2"));
		three.add(mod.parseTerm("3"));
		three.add(splus.makeTerm(onetwo));
		whole.add(mod.parseTerm("4"));
		whole.add(stimes.makeTerm(three));

		Term expr = splus.makeTerm(whole);

		System.out.println(expr.getSort() + " : " + expr);
		expr.reduce();
		System.out.println(expr);

		// Constructs a variable by parsing
		Term variable = mod.parseTerm("N:Nat");

		System.out.println(String.format("%s %s %s", variable, variable.isVariable(), variable.getVarName()));
		System.out.println(String.format("%s %s %s", expr, expr.isVariable(), expr.getVarName()));
	}
}
