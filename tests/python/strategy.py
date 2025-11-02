import maude

maude.init(advise=False)

maude.input('''smod EXAMPLE is
	protecting BOOL .
	protecting FLOAT .
	sort Foo .
	op f : Bool Bool -> Foo [ctor] .
	op g : Foo -> Foo [ctor] .

	vars P Q : Bool .
	var  X   : Foo .

	rl [swap] : f(P, Q) => f(Q, P) .
	rl [unwrap] : g(X) => X .

	strat swapif : Bool @ Foo .
	sd swapif(P) := swap[P <- P] .
endsm
''')

m = maude.getCurrentModule()

# Strategy constants
s = m.parseStrategy('idle')
print(s.getResult())
s = m.parseStrategy('fail')
print(s.getResult())

# Tests
s = m.parseStrategy('match P s.t. P')
print(s.getPattern())
print(s.getCondition())
print(s.getDepth())
s = m.parseStrategy('amatch X')
print(s.getDepth() > 0)

# Rule application
s = m.parseStrategy('swap')
print(s.getLabel())
print(s.getTop())
print(s.getSubstitution())
print(s.getStrategies())
s = m.parseStrategy('top(swap[P <- true]{idle, fail})')
print(s.getLabel())
print(s.getTop())
print(s.getSubstitution())
print(s.getStrategies())

# Disjunction
s = m.parseStrategy('swap | unwrap')
print(*s.getStrategies())
print(s.getStrategies()[0].getLabel())

# Concatenation
s = m.parseStrategy('swap ; unwrap ; idle')
print(*s.getStrategies())

# One
s = m.parseStrategy('one(unwrap)')
print(s, s.getStrategy())

# Iteration strategy
s = m.parseStrategy('swap *')
print(s.getStrategy())
print(s.getZeroAllowed())

s = m.parseStrategy('unwrap +')
print(s.getStrategy())
print(s.getZeroAllowed())

# Call strategy
s = m.parseStrategy('swapif(true)')
print(s.getStrategy())
# Construction and evaluation of call strategies
sf = s.getStrategy()(m.parseTerm('false'))
print(sf)
t = m.parseTerm('f(false, true)')
print(*t.srewrite(sf))
t = m.parseTerm('f(true, false)')
print(list(t.srewrite(sf)))

# Subterm rewriting strategy
s = m.parseStrategy('matchrew g(X) by X using swap')
print(s.getPattern(), s.getDepth(), s.getCondition())
print(s.getSubterms())
print(s.getStrategies())

s = m.parseStrategy('xmatchrew f(P, Q) s.t. Q = false by P using idle, Q using fail')
print(s.getPattern(), s.getDepth(), s.getCondition())
print(s.getSubterms())
print(s.getStrategies())

# Conditional strategy
cond_types = {
	maude.CONDITIONAL: '?:', maude.OR_ELSE: 'or-else',
	maude.NORMALIZATION: '!', maude.TEST: 'test',
	maude.TRY: 'try', maude.NOT: 'not'
}

for txt in ('swap ? swap : unwrap', 'swap or-else unwrap',
            'unwrap !', 'test(swap)', 'try(swap)', 'not(swap)'):
	s = m.parseStrategy(txt)
	print(cond_types[s.getType()])
	print(s.getInitialStrategy(), s.getSuccessStrategy(), s.getFailureStrategy())

# Choice strategy (probabilistic)
s = m.parseStrategy('choice(1.0 : swap, 2.0 : unwrap)')
print(s.getStrategies())
print(s.getWeights())

# Sample strategy (probabilistic)
s = m.parseStrategy('sample F:Float := bernoulli(0.4) in swap[P <- F:Float == 1.0]')
print(s.getVariable(), s.getStrategy())
print(s.getDistributionName(), s.getArguments())

s = m.parseStrategy('sample F:Float := norm(0.0, 1.0) in idle')
print(s.getVariable(), s.getStrategy())
print(s.getDistributionName(), s.getArguments())

# Weighted subterm rewriting strategy (probabilistic)
s = m.parseStrategy('matchrew f(P, Q) s.t. Q = false with weight if P then 1.0 else 2.0 fi by P using idle, Q using fail')
print(s.getPattern(), s.getDepth(), s.getCondition())
print(s.getSubterms(), s.getStrategies())
print(s.getWeight())
