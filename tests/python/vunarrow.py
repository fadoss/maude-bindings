import maude
import itertools

maude.init(advise=False)

def print_solution(*args):
	print(('              state = {}\n'
	       '  acc. substitution = {}\n'
	       '    variant unifier = {}').format(*args))

##### From Maude 3.0 manual, §15.6

maude.input(r'''mod NARROWING-VENDING-MACHINE is
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
nvmach_initial3 = nvmach.parseTerm('< $ q q q M1:Money >')
nvmach_target3  = nvmach.parseTerm('< a c M2:Money >')

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

print(nvmach_initial3, '=>*', nvmach_target3, 'with depth bound to 2')

for solution in nvmach_initial3.vu_narrow(maude.ANY_STEPS, nvmach_target3, depth=2):
	print_solution(*solution)

print(nvmach_initial3, '=>*', nvmach_target3, 'with depth bound to 5 and filter')

for solution in nvmach_initial3.vu_narrow(maude.ANY_STEPS, nvmach_target3, depth=5, flags=maude.FILTER):
	print_solution(*solution)

print(nvmach_initial3, '=>*', nvmach_target3, 'with depth bound to 5 and delay')

for solution in nvmach_initial3.vu_narrow(maude.ANY_STEPS, nvmach_target3, depth=5, flags=maude.DELAY | maude.FILTER):
	print_solution(*solution)

##### From §15.7

maude.input(r'''mod FOLDING-NARROWING-VENDING-MACHINE is
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

for solution in fnvmach_initial.vu_narrow(maude.ANY_STEPS, fnvmach_target, -1, maude.FOLD):
	print_solution(*solution)

print(fnvmach_initial2, '=>*', fnvmach_target)

for solution in fnvmach_initial2.vu_narrow(maude.ANY_STEPS, fnvmach_target):
	print_solution(*solution)


##### New commands from Maude 3.5

vu_narrow_it = nvmach_initial1.vu_narrow(maude.ANY_STEPS, nvmach_target1, 3, maude.FOLD)

list(vu_narrow_it) # read the sequence

print('show most general states', nvmach_initial1, '=>*', nvmach_target1)

for state in vu_narrow_it.getMostGeneralStates():
	print(state)

print('show frontier states', nvmach_initial1, '=>*', nvmach_target1)

for state in vu_narrow_it.getFrontierStates():
	print(state)

vu_narrow_it = nvmach_initial2.vu_narrow(maude.NORMAL_FORM, nvmach_target2)

list(vu_narrow_it) # read the sequence

print('show frontier states', nvmach_initial2, '=>!', nvmach_target2)

for state in vu_narrow_it.getFrontierStates():
	print(state)

print('vu-narrow from multiple initial terms')

vu_narrow_it = fnvmach.vu_narrow([
	fnvmach.parseTerm('< M1:Marking a c >'),
	fnvmach.parseTerm('< M2:Marking a a >'),
	fnvmach.parseTerm('< M3:Marking c c >')], maude.ANY_STEPS, fnvmach.parseTerm('< empty >'), flags=maude.FOLD)

for solution in vu_narrow_it:
	print_solution(*solution)

for state in vu_narrow_it.getFrontierStates():
	print(state)

for state in vu_narrow_it.getMostGeneralStates():
	print(state)
