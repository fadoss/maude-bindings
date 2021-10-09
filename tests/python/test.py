import maude
import os.path

maude.init(advise=False)
maude.load(os.path.join(os.path.dirname(__file__), '..', 'example.maude'))

example = maude.getCurrentModule()
nat = maude.getModule('NAT')

#####

t = nat.parseTerm('1 + (3 * 5 + 7) * 11 + 13')
t0 = t.copy()
t.reduce()
print(t0, '=', t)

#####

ans = example.parseTerm('f(a, b)')
ans.rewrite()
print(ans)

#####

ans = example.parseTerm('f(a, a)')
ans.frewrite(1)
print(ans)

#####

fbb = example.parseTerm('f(b, b)')
ans, nrew = fbb.erewrite()
print(fbb, '->', ans, 'in', nrew, 'rewrites')

#####

ans = example.parseTerm('f(a, b)')

for sol, nrew in ans.srewrite(example.parseStrategy('swap *')):
	print(sol, 'in', nrew, 'rewrites')

#####

initial = example.parseTerm('f(a, a)')
pattern = example.parseTerm('f(c, X:Symbol)')

for sol, subs, path, nrew in initial.search(maude.ANY_STEPS, pattern):
	print(sol, 'with', subs, 'by', path())

s = example.parseStrategy('ab ; bc ; ab')

for sol, subs, path, nexts, nrew in initial.search(maude.ANY_STEPS, pattern, s):
	print(sol, 'with', subs, 'by', path(), 'before applying', nexts)
