import maude
import itertools

maude.init(advise=False)

##### From Maude 3.1 manual, §13.4

maude.input('''fmod UNIFICATION-EX1 is
	protecting NAT .
	op f : Nat Nat -> Nat .
	op f : NzNat Nat -> NzNat .
	op f : Nat NzNat -> NzNat .
endfm''')

uex1 = maude.getModule('UNIFICATION-EX1')

uex1_t1 = uex1.parseTerm('f(X:Nat, Y:Nat) ^ B:NzNat')
uex1_t2 = uex1.parseTerm('A:NzNat ^ f(Y:Nat, Z:Nat)')

print('Unifiers for', uex1_t1, 'and', uex1_t2)

for unifier in uex1.unify([(uex1_t1, uex1_t2)]):
	print('Unifier', unifier)
	print('X =', unifier.find('X'))
	print('T =', unifier.find('T'))
	print('B:NzNat =', unifier.find('B', uex1.findSort('NzNat')))
	print('X:NzNat =', unifier.find('X', uex1.findSort('NzNat')))

	print('σ({}) = {}'.format(uex1_t1, unifier.instantiate(uex1_t1)))
	print('σ(3) =', unifier.instantiate(uex1.parseTerm('3')))

#####

uex1_p1 = uex1.parseTerm('f(X:Nat, Y:NzNat)'), uex1.parseTerm('f(Z:NzNat, U:Nat)')
uex1_p2 = uex1.parseTerm('V:NzNat'), uex1.parseTerm('f(X:Nat, U:Nat)')

print('Unifier for equations', uex1_p1, 'and', uex1_p2)

for unifier in uex1.unify([uex1_p1, uex1_p2]):
	print(unifier)

#####

maude.input('''fmod UNIFICATION-EX3 is
	protecting NAT .
	op f : Nat Nat -> Nat [idem] .
endfm''')

uex3 = maude.getModule('UNIFICATION-EX3')

print('Unsupported unification')

result = uex3.unify([(uex3.parseTerm('f(f(X:Nat, Y:Nat), Z:Nat)'), uex3.parseTerm('f(A:Nat, B:Nat)'))])


##### From Maude 3.1 manual, §13.4.4

maude.input('''mod UNIF-VENDING-MACHINE is
	sorts Coin Item Marking Money State .
	subsort Coin < Money .
	op empty : -> Money .
	op __ : Money Money -> Money [assoc comm id: empty] .
	subsort Money Item < Marking .
	op __ : Marking Marking -> Marking [assoc comm id: empty] .
	op <_> : Marking -> State .
	ops $ q : -> Coin .
	ops a c : -> Item .
	var M : Marking .
	rl [buy-c] : < M $ > => < M c > .
	rl [buy-a] : < M $ > => < M a q > .
	eq [change]: q q q q = $ .
endm''')

uvmachine = maude.getModule('UNIF-VENDING-MACHINE')
uvm_p1    = uvmachine.parseTerm('< q q X:Marking >'), uvmachine.parseTerm('< $ Y:Marking >')

print('Unify', uvm_p1)

for unifier in uvmachine.unify([uvm_p1]):
	print(unifier)

print('Irredudant unify', uvm_p1)

for unifier in uvmachine.unify([uvm_p1], True):
	print(unifier)

print('Variant unify', uvm_p1)

for unifier in uvmachine.variant_unify([uvm_p1]):
	print(unifier)

##### From Maude 3.1 manual, §14.3

maude.input('''mod VARIANT-VENDING-MACHINE is
	sorts Coin Item Marking Money State .
	subsort Coin < Money .
	op empty : -> Money .
	op __ : Money Money -> Money [assoc comm id: empty] .
	subsort Money Item < Marking .
	op __ : Marking Marking -> Marking [assoc comm id: empty] .
	op <_> : Marking -> State .
	ops $ q : -> Coin .
	ops a c : -> Item .
	var M : Marking .
	rl [buy-c] : < M $ > => < M c > .
	rl [buy-a] : < M $ > => < M a q > .
	eq [change] : q q q q M = $ M [variant] .
endm''')

vvmachine = maude.getModule('VARIANT-VENDING-MACHINE')
vvm_p1    = vvmachine.parseTerm('< q q X:Marking >'), vvmachine.parseTerm('< $ Y:Marking >')

##### From §14.8

print('Variant unify', vvm_p1)

for unifier in vvmachine.variant_unify([vvm_p1]):
	print(unifier)

print('Filtered variant unify', vvm_p1)

for unifier in vvmachine.variant_unify([vvm_p1], filtered=True):
	print(unifier)

##### From §14.9

print('Variant unify', vvm_p1, 'with constraints')

irreducible = list(map(vvmachine.parseTerm, ['q q X:Marking', 'q X:Marking', 'X:Marking']))

for unifier in vvmachine.variant_unify([vvm_p1], irreducible):
	print(unifier)

##### From §14.12

print('Variant match', vvm_p1)

for matcher in vvmachine.variant_match([vvm_p1]):
	print(matcher)

print('Variant match', vvm_p1, 'with constraints')

for matcher in vvmachine.variant_match([vvm_p1], irreducible):
	print(matcher)


##### From Maude manual 3.1, §14.1 and 14.10

maude.input('''fmod NAT-VARIANT is
	sort Nat .
	op 0 : -> Nat [ctor] .
	op s : Nat -> Nat [ctor] .
	op _+_ : Nat Nat -> Nat .
	vars X Y : Nat .
	eq [base] : 0 + Y = Y [variant] .
	eq [ind] : s(X) + Y = s(X + Y) [variant] .
endfm''')

natv  = maude.getModule('NAT-VARIANT')
onex  = natv.parseTerm('s(0) + X:Nat')
xone  = natv.parseTerm('X:Nat + s(0)')
three = natv.parseTerm('s(s(s(0)))')

print('Variant unify', (onex, three))

for unifier in natv.variant_unify([(onex, three)]):
	print(unifier)

print('Variant unify', (onex, three))

for unifier in itertools.islice(natv.variant_unify([(xone, three)]), 1):
	print(unifier)
