import os
import maude

maude.init(advise=False)

maude.input('''mod HOOK-TEST is
	protecting NAT .
	protecting STRING .
	sort Foo .

	op pair : Nat Nat -> Foo [special (
		id-hook SpecialHubSymbol (pair arg1 arg2)
		term-hook falseTerm (false)
		op-hook notSymbol (not_ : Bool ~> Bool)
	)] .

	op box : Nat -> Foo [special (
		id-hook SpecialHubSymbol (norewrite)
	)] .

	op getenv : String ~> String [special (
		id-hook SpecialHubSymbol
	)] .

	var N : Nat .

	rl [pred] : s(N) => N .
endm
''')

class ShowHook(maude.Hook):
	"""Show the data associated to the special operator"""

	def run(self, term, data):
		print(term)
		print(data.getData())
		print(data.getSymbol('notSymbol'))
		print(data.getTerm('falseTerm'))

		# Term are given unreduced to callbacks, which must reduce
		# them if to appear in the result (to avoid internal errors).
		for arg in term.arguments():
			arg.reduce()

		return None

class EnvHook(maude.Hook):
	"""Query environment variables (op getenv : String -> String)"""

	def run(self, term, data):
		# Environment variable
		name_term = next(term.arguments())
		name_term.reduce()

		variable = str(name_term)[1:-1]
		value = os.getenv(variable)

		# Current module
		module = term.symbol().getModule()

		return None if value is None else \
			module.parseTerm(f'"{os.getenv(variable)}"')

def make_hook(fn):
	"""Construct a hook from a function"""

	class TempHook(maude.Hook):
		def run(self, *args):
			return fn(*args)

	return TempHook()

def swap_pair(term, data):
	"""Swap the arguments of a pair"""

	args = list(term.arguments())
	args.reverse()

	return term.symbol().makeTerm(args)

def msg_none(term, data):
	"""Show a message"""
	print('--> msg_hook')

	# Even if the top symbol is not reduced (None is returned),
	# its arguments must be.
	for arg in term.arguments():
		arg.reduce()

	return None

# Instantiate the hook classes
printer    = ShowHook()
swaper     = make_hook(swap_pair)
no_rewrite = make_hook(lambda *args: None)
msg_hook   = make_hook(msg_none)
envhook    = EnvHook()

# Connect the special operators to the Python code
maude.connectEqHook('pair', printer)
maude.connectRlHook('pair', swaper)
maude.connectRlHook('norewrite', no_rewrite)
maude.connectEqHook('getenv', envhook)

# Equational and rule rewriting
m = maude.getCurrentModule()

t = m.parseTerm('pair(sd(5, 3), 1 + 1)')
t.rewrite(3)

print(t)

# Equational returing new terms
t = m.parseTerm('getenv("LANG")')
t.reduce()

print(t)

# Hook associated with a different name, to a lambda and doing nothing
t = m.parseTerm('box(4)')
t.rewrite()

print(t)


# Disconnecting hooks and default callbacks
print('-- connected')
m.parseTerm('pair(4, 5)').reduce()

print('-- disconnected')
maude.connectEqHook('pair', None)
m.parseTerm('pair(4, 5)').reduce()

print('-- connected + default')
maude.connectEqHook('pair', printer)
maude.connectEqHook(None, msg_hook)
m.parseTerm('pair(4, 5)').reduce()

print('-- default')
maude.connectEqHook('pair', None)
m.parseTerm('pair(4, 5)').reduce()

print('-- none')
maude.connectEqHook(None, None)
m.parseTerm('pair(4, 5)').reduce()
