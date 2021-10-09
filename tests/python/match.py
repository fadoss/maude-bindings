import maude
import os.path

maude.init(advise=False)
maude.load(os.path.join(os.path.dirname(__file__), '..', 'example.maude'))

m = maude.getCurrentModule()

print('Using', m, 'module')

#####

pattern = m.parseTerm('f(X:Symbol, Y:Symbol)')
t = m.parseTerm('f(a, g(b))')

print(pattern, '<=?', t)

for match, _ in t.match(pattern):
	print(match)

#####

pattern = m.parseTerm('X:Symbol ; Y:Symbol')
t = m.parseTerm('b ; c')

print(pattern, '<=?', t)

for match, _ in t.match(pattern):
	print(match)

#####

pattern = m.parseTerm('X:Symbol ; Y:Symbol')
t = m.parseTerm('b ; c')

print(pattern, '<=?', t)

for match, _ in t.match(pattern, [maude.EqualityCondition(m.parseTerm('X:Symbol'), m.parseTerm('Y:Symbol'))]):
	print(match)

#####

cond = [maude.EqualityCondition(m.parseTerm('X:Symbol'), m.parseTerm('Y:Symbol'))]

pattern = m.parseTerm('f(X:Symbol, g(Y:Symbol))')
t = m.parseTerm('f(a, g(a))')

print(pattern, '<=?', t)

for match, _ in t.match(pattern, cond):
	print(match)

#####

pattern = m.parseTerm('X:Symbol Y:Symbol')
t = m.parseTerm('a b c g(b) f(a, b)')

print(pattern, '<=?', t)

for match, _ in t.match(pattern, maude.Term.NO_CONDITION, withExtension=True):
	print(match, 'inside', match.matchedPortion())

#####

pattern = m.parseTerm('f(X:Symbol, g(Y:Symbol))')
t = m.parseTerm('f(a, g(b))')

for match, _ in t.match(pattern):
	print('Substitution', match)
	print('X =', match.find('X'))
	print('Y =', match.find('Y'))
	print('X:Symbol =', match.find('X', m.findSort('Symbol')))
	print('Y:Nat =', match.find('Y', m.findSort('Nat')))
	print('σ(c) =', match.instantiate(m.parseTerm('c')))
	print('σ(f(g(Y), g(X))) =', match.instantiate(m.parseTerm('f(g(Y:Symbol), g(X:Symbol))')))

#####

pattern = m.parseTerm('f(X:Symbol, Y:Symbol)')
t = m.parseTerm('f(f(g(a), a), f(b, c))')
h = m.parseTerm('%hole:Symbol')

for match, ctx in t.match(pattern, maxDepth=maude.UNBOUNDED):
	print(match, '---', ctx(h), '---', ctx(m.parseTerm('a')))

for match, ctx in t.match(pattern, minDepth=1, maxDepth=2):
	print(match)
