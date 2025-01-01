#
# Test for the lifetime of modules
#

import maude
import gc


class ModuleLifeTest:
	# Based on https://github.com/fadoss/maude-bindings/issues/3
	MODULE_TEMPLATE = r'''smod ONE is
		protecting NAT .
		op value : -> Nat .
		eq value = {value} .
		mb false : Bool .
		crl 1 => 0 if 1 = 1 /\ 1 : Nat /\ 1 => 1 .
		strat st @ Nat .
		sd st := idle .
	endsm'''

	def __init__(self):
		self.index = 0
		maude.input(self.MODULE_TEMPLATE.format(value=0))

	def run(self, name, first, second):
		"""Run an operation on an object obtained from a garbage collected module"""

		# Make the first function generate an object in the module ONE
		obj = first(maude.getCurrentModule())
		# Input a module overwriting the module ONE
		maude.input(self.MODULE_TEMPLATE.format(value=self.index))
		self.index += 1
		# Force garbage collection (if not done yet)
		gc.collect()
		# Make the second function use the object referring to the garbage collected module
		second(obj)

		print(f'[{name}]')


maude.init(advise=False)
mlt = ModuleLifeTest()

# Basic objects
mlt.run('term', lambda m: m.parseTerm('value'), lambda t: t.reduce())
mlt.run('term', lambda m: m.parseTerm('value'), lambda t: print(t))
mlt.run('sort-findSort', lambda m: m.findSort('NzNat'), lambda s: print(s))
mlt.run('sort-getSorts', lambda m: m.getSorts()[0], lambda s: print(s))
mlt.run('sort-MbAx', lambda m: m.getMembershipAxioms()[0].getSort(), lambda s: print(s))
mlt.run('sort-getRangeSort', lambda m: m.getSymbols()[0].getRangeSort(), lambda s: print(s))
mlt.run('sort-getSubjectSort', lambda m: m.parseTerm('1 + 2').getSort(), lambda s: print(s))
mlt.run('sort-getStrategies', lambda m: m.getStrategies()[0].getSubjectSort(), lambda s: print(s))
mlt.run('kind', lambda m: m.findSort('NzNat').kind(), lambda s: print(s))
mlt.run('symbol-getSymbols', lambda m: m.getSymbols()[0], lambda s: print(s))
mlt.run('equation-getEquations', lambda m: m.getEquations()[0], lambda e: print(e))
mlt.run('MbAx-getMbAx', lambda m: m.getMembershipAxioms()[0], lambda mb: print(mb))
mlt.run('rule-getRules', lambda m: m.getRules()[0], lambda r: print(r))
mlt.run('strategy-getStrategies', lambda m: m.getStrategies()[0], lambda r: print(r))
mlt.run('sds-getSds', lambda m: m.getStrategyDefinitions()[0], lambda d: print(d))
# mlt.run('strategy', lambda m: m.parseStrategy('st'), lambda s: print(s))

# Solution iterators
mlt.run('match', lambda m: m.parseTerm('value').match(m.parseTerm('N:Nat')), lambda i: next(i))
mlt.run('search', lambda m: m.parseTerm('value').search(maude.ANY_STEPS, m.parseTerm('N:Nat')), lambda i: next(i))
mlt.run('srewrite', lambda m: m.parseTerm('value').srewrite(m.parseStrategy('idle')), lambda i: next(i))
mlt.run('ssearch', lambda m: m.parseTerm('value').search(maude.ANY_STEPS, m.parseTerm('N:Nat'), strategy=m.parseStrategy('idle')), lambda i: next(i))
mlt.run('vu_narrow', lambda m: m.parseTerm('value').vu_narrow(maude.ANY_STEPS, m.parseTerm('N:Nat')), lambda i: next(i))
mlt.run('get_variants', lambda m: m.parseTerm('1 + N:Nat').get_variants(), lambda i: next(i))
mlt.run('unify', lambda m: m.unify([(m.parseTerm('1 + N:Nat'), m.parseTerm('M:Nat + 2'))]), lambda i: next(i))
mlt.run('variant_unify', lambda m: m.variant_unify([(m.parseTerm('1 + N:Nat'), m.parseTerm('M:Nat + 2'))]), lambda i: next(i))

# Vectors
mlt.run('getSorts', lambda m: m.getSorts(), lambda sv: print(sv[0]))
mlt.run('getSymbols', lambda m: m.getSymbols(), lambda sv: print(sv[0]))
mlt.run('getKinds', lambda m: m.getKinds(), lambda kv: print(kv[0]))
mlt.run('getMembershipAxioms', lambda m: m.getMembershipAxioms(), lambda mv: print(mv[0]))
mlt.run('getEquations', lambda m: m.getEquations(), lambda ev: print(ev[0]))
mlt.run('getRules', lambda m: m.getRules(), lambda rv: print(rv[0]))
mlt.run('getStrategies', lambda m: m.getStrategies(), lambda sv: print(sv[0]))
mlt.run('getStrategyDefinitions', lambda m: m.getStrategyDefinitions(), lambda dv: print(dv[0]))
mlt.run('getOpDeclarations', lambda m: m.parseTerm('1 + 2').symbol().getOpDeclarations(), lambda dv: print(dv[0].getDomainAndRange()[0]))
mlt.run('getSupersorts', lambda m: m.getSorts()[0].getSupersorts(), lambda sv: print(sv[0]))
mlt.run('getDomainAndRange', lambda m: m.parseTerm('1 + 2').symbol().getOpDeclarations()[0].getDomainAndRange(), lambda sv: print(sv[0]))
#mlt.run('getSubsorts', lambda m: m.getSorts()[0].getSubsorts(), lambda sv: print(len(sv)))
#mlt.run('getDomain', lambda m: m.getStrategies()[0].getDomain(), lambda sv: print(len(sv)))
