import maude
import itertools

maude.init(advise=False)

def print_solution(*args):
	print(('              state = {}\n'
	       '  acc. substitution = {}\n'
	       '    variant unifier = {}').format(*args))

##### From Maude 3.0 manual, §15.6

maude.input('''mod NARROWING-VENDING-MACHINE is
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
	rl [buy-c] : < M $ > => < M c > [narrowing] .
	rl [buy-a] : < M $ > => < M a q > [narrowing] .
	eq [change] : q q q q M = $ M [variant] .
endm''')

nvmach = maude.getModule('NARROWING-VENDING-MACHINE')

nvmach_initial1 = nvmach.parseTerm('< M:Money >')
nvmach_target1  = nvmach.parseTerm('< a c >')
nvmach_initial2 = nvmach.parseTerm('< C1:Coin C2:Coin C3:Coin C4:Coin >')
nvmach_target2  = nvmach.parseTerm('< M:Money a c >')

print(nvmach_initial1, '=>*', nvmach_target1)

for term, subs, unifier in itertools.islice(nvmach_initial1.vu_narrow(maude.ANY_STEPS, nvmach_target1), 1):
	print_solution(term, subs, unifier)

print(nvmach_initial1, '=>!', nvmach_target1, 'with depth bound to 5')

for term, subs, unifier in nvmach_initial1.vu_narrow(maude.NORMAL_FORM, nvmach_target1, 5):
	print_solution(term, subs, unifier)

print(nvmach_initial2, '=>!', nvmach_target2, 'with depth bound to 10')

for term, subs, unifier in nvmach_initial2.vu_narrow(maude.NORMAL_FORM, nvmach_target2, 10):
	print_solution(term, subs, unifier)

print(nvmach_initial1, '=>*', nvmach_target1, 'with folding')

for solution in itertools.islice(nvmach_initial1.vu_narrow(maude.ANY_STEPS, nvmach_target1, -1, True), 1):
	print_solution(*solution)


##### From §15.7

maude.input('''mod FOLDING-NARROWING-VENDING-MACHINE is
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
	rl [buy-c] : < M $ c > => < M > [narrowing] .
	rl [buy-a] : < M $ a > => < M q > [narrowing] .
	eq [change] : q q q q M = $ M [variant] .
endm''')

fnvmach = maude.getModule('FOLDING-NARROWING-VENDING-MACHINE')

fnvmach_initial  = fnvmach.parseTerm('< M:Marking a c >')
fnvmach_initial2 = fnvmach.parseTerm('< M:Money a c >')
fnvmach_target   = fnvmach.parseTerm('< empty >')

print(fnvmach_initial, '=>*', fnvmach_target, 'with folding')

for solution in fnvmach_initial.vu_narrow(maude.ANY_STEPS, fnvmach_target, -1, True):
	print_solution(*solution)

print(fnvmach_initial2, '=>*', fnvmach_target)

for solution in fnvmach_initial2.vu_narrow(maude.ANY_STEPS, fnvmach_target):
	print_solution(*solution)
