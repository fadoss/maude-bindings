import maude

maude.init(advise=False)

maude.load('../example.maude')
maude.load('tests/example.maude')
maude.input('fmod TESTS is endfm')
maude.input('fmod TESTS is endfm')
maude.load('../example.maude')
maude.input('fmod TESTS is endfm')


m = maude.getModule('NAT')
seven = m.parseTerm('7')

print(seven)
maude.input('set print number off .')
print(seven)
