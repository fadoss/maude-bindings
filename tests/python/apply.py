import maude
import os.path

maude.init(advise=False)
maude.load(os.path.join(os.path.dirname(__file__), '..', 'example.maude'))

m = maude.getCurrentModule()

print('Using', m, 'module')

#####

t = m.parseTerm('f(a, a)')
v = m.parseTerm('H:Symbol')

for r, sb, ctx, rl in t.apply('ab'):
	print(r, 'with', rl, 'in context', ctx(v))

for r, sb, ctx, rl in t.apply('bc'):
	print(r, 'with', rl, 'in context', ctx(v))

#####

t = m.parseTerm('f(a, b)')

for r, sb, ctx, rl in t.apply('ab'):
	print(r, 'with', rl, 'in context', ctx(v))

	for s, sb, ctx, rl in r.apply('bc'):
		print(s, 'with', rl, 'in context', ctx(v))

for r, sb, ctx, rl in t.apply(None):
	print(r, 'with', rl, 'in context', ctx(v))

#####

for r, sb, ctx, rl in t.apply('swap'):
	print(r, 'with', rl, 'in context', ctx(v), 'and substitution', sb)

#####

t = m.parseTerm('f(f(a, g(a)), f(b, c))')
sb = maude.Substitution({m.parseTerm('X'): m.parseTerm('b')})

for r, *_ in t.apply('swap', minDepth=1):
	print(r)

for r, *_ in t.apply('swap', maxDepth=-1):
	print(r)

for r, *_ in t.apply('swap', substitution=sb):
	print(r)

#####

swap = next(rl for rl in m.getRules() if rl.getLabel() == 'swap')

def apply_rule(t, rl, maxDepth=maude.UNBOUNDED):
	"""Apply a rule"""

	return [ctx(match.instantiate(rl.getRhs())) for match, ctx in t.match(rl.getLhs(), maxDepth=maxDepth)]

print(apply_rule(t, swap))
print(apply_rule(t, swap, maxDepth=0))

#####

def apply_rule2(t, rl, substitution=None, maxDepth=maude.UNBOUNDED):
	"""Apply a rule with an optional initial substitution"""

	lhs = rl.getLhs()
	rhs = rl.getRhs()
	condition = list(rl.getCondition())

	if substitution:
		lhs = substitution.instantiate(lhs)
		rhs = substitution.instantiate(rhs)

		for k, cf in enumerate(condition):
			if isinstance(cf, maude.SortTestCondition):
				condition[k] = maude.SortTestCondition(substitution.instantiate(cf.getLhs()), cf.getSort())
			else:
				condition[k] = type(cf)(substitution.instantiate(cf.getLhs()),
				                        substitution.instantiate(cf.getRhs()))

	return [ctx(match.instantiate(rhs)) for match, ctx in t.match(lhs, condition=condition, maxDepth=maxDepth)]

print(apply_rule2(t, swap))
print(apply_rule2(t, swap, substitution=sb))

