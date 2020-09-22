import maude
import itertools

maude.init(advise=False)

def print_variant(term, subs):
	print('{:>28} -- {}'.format(str(term), subs))

##### From Maude 3.0 manual, §14.1 and 14.3

maude.input('''fmod EXCLUSIVE-OR is
	sorts Nat NatSet .
	op 0 : -> Nat [ctor] .
	op s : Nat -> Nat [ctor] .

	subsort Nat < NatSet .
	op mt : -> NatSet [ctor] .
	op _*_ : NatSet NatSet -> NatSet [ctor assoc comm] .

	vars X Y Z : [NatSet] .
	eq [idem] :
	X * X = mt [variant] .
	eq [idem-Coh] : X * X * Z = Z [variant] .
	eq [id] :
	X * mt = X [variant] .
endfm''')

xor  = maude.getModule('EXCLUSIVE-OR')
xory = xor.parseTerm('X * Y')

print('Irredundant variants of', xory)

for term, subs in xory.get_variants(True):
	print_variant(term, subs)

print('\nIrredundant variants of', xory, 'such that', xory, 'irreducible')

for term, subs in xory.get_variants(True, [xory]):
	print_variant(term, subs)


##### From Maude 3.0 manual, §14.1 and 14.5

maude.input('''fmod NAT-VARIANT is
	sort Nat .
	op 0 : -> Nat [ctor] .
	op s : Nat -> Nat [ctor] .
	op _+_ : Nat Nat -> Nat .
	vars X Y : Nat .
	eq [base] : 0 + Y = Y [variant] .
	eq [ind] : s(X) + Y = s(X + Y) [variant] .
endfm''')

natv = maude.getModule('NAT-VARIANT')
onex = natv.parseTerm('s(0) + X:Nat')
xone = natv.parseTerm('X:Nat + s(0)')

print('\nVariants of', onex)

for term, subs in onex.get_variants():
	print_variant(term, subs)

print('\n10 variants of', xone)

for term, subs in itertools.islice(xone.get_variants(), 10):
	print_variant(term, subs)
