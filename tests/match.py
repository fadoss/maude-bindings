import maude
import os.path

maude.init()
maude.load(os.path.join(os.path.dirname(__file__), 'example.maude'))

m = maude.getCurrentModule()

print('Using', m, 'module')

#####

pattern = m.parseTerm('f(X:Symbol, Y:Symbol)')
t = m.parseTerm('f(a, g(b))')

print(pattern, '<=?', t)

for match in t.match(pattern):
	print(match)

#####

pattern = m.parseTerm('X:Symbol ; Y:Symbol')
t = m.parseTerm('b ; c')

print(pattern, '<=?', t)

for match in t.match(pattern):
	print(match)

#####

pattern = m.parseTerm('X:Symbol ; Y:Symbol')
t = m.parseTerm('b ; c')

print(pattern, '<=?', t)

for match in t.match(pattern, [maude.EqualityCondition(m.parseTerm('X:Symbol'), m.parseTerm('Y:Symbol'))]):
	print(match)

#####

cond = [maude.EqualityCondition(m.parseTerm('X:Symbol'), m.parseTerm('Y:Symbol'))]

pattern = m.parseTerm('f(X:Symbol, g(Y:Symbol))')
t = m.parseTerm('f(a, g(a))')

print(pattern, '<=?', t)

for match in t.match(pattern, cond):
	print(match)

#####

pattern = m.parseTerm('X:Symbol Y:Symbol')
t = m.parseTerm('a b c g(b) f(a, b)')

print(pattern, '<=?', t)

for match in t.match(pattern, maude.Term.NO_CONDITION, True):
	print(match, 'inside', match.matchedPortion())
