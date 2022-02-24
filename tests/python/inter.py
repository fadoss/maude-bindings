#
# Toy interactive rewriting interface using the maude library
# for "Maude as a library: an efficient all-purpose programming interface"
#

import cmd
import subprocess
import sys
import tempfile

import maude


def print_tree(term, indent=''):
	"""Print a term as a tree"""

	print(f'{indent}{term.symbol()} : {term.getSort()}')

	indent = indent + '  '

	for argument in term.arguments():
		print_tree(argument, indent)


def count_symbols(term, count):
	"""Count occurrences of symbols"""

	count[term.symbol()] = 1 + count.get(term.symbol(), 0)
	for argument in term.arguments():
		count_symbols(argument, count)


def find_vars(term, varset):
	"""Get all variables in term"""

	if term.isVariable():
		varset.add(term)
	else:
		for argument in term.arguments():
			find_vars(argument, varset)


def needs_term(func):
	"""Check that a term exists"""

	def func2(self, *args):
		if self.term:
			func(self, *args)
		else:
			print('Error: no current term.')

	# Copy function's documentation
	func2.__doc__ = func.__doc__

	return func2


def needs_module(func):
	"""Check that a term exists"""

	def func2(self, *args):
		if self.module:
			func(self, *args)
		else:
			print('Error: no current module.')

	# Copy function's documentation
	func2.__doc__ = func.__doc__

	return func2


class InteractiveRewriter(cmd.Cmd):
	"""Interactive rewriter for Maude"""

	# Introductory message
	intro = '\n     *** Interactive rewriter for Maude ***\n'
	prompt = 'IRew> '

	def __init__(self):
		super().__init__()

		# Current term
		self.term = None
		# Current module
		self.module = maude.getCurrentModule()
		# Term history
		self.history = []

		# Current metamodule (because we may add rules)
		self.metamodule = None

	def do_load(self, filename):
		"""Load a Maude file"""

		maude.load(filename)
		self.module = maude.getCurrentModule()

	def do_select(self, name):
		"""Select a module"""

		self.module = maude.getModule(name)
		self.term = None

	def do_list(self, _):
		"""List known modules"""

		for x in maude.getModules():
			print(x)

	@needs_module
	def do_start(self, text):
		"""Start with the given term"""

		self.term = self.module.parseTerm(text)

	@needs_term
	def do_show(self, _):
		"""Show the current term"""

		print('The current term is', self.term)

	@needs_term
	def do_tree(self, _):
		"""Show the current term as a tree"""

		print_tree(self.term)

	@needs_term
	def do_count(self, _):
		"""Show the number of occurrences of each symbol"""

		count = {}
		count_symbols(self.term, count)

		for symbol, times in count.items():
			print(f'{str(symbol):30} : {times}')

	@needs_term
	def do_reduce(self, _):
		"""Reduce the current term"""

		nrew = self.term.reduce()
		print(f'Reduced to {self.term} in {nrew} rewrites.')

	@needs_term
	def do_srewrite(self, text):
		"""Reduce the current term with a strategy"""

		strategy = self.module.parseStrategy(text)
		for result, nrew in self.term.srewrite(strategy):
			print(f'{result} in {nrew} rewrites')

	@needs_term
	def do_step(self, label):
		"""Take a rewriting step interactive"""

		results = []

		for k, (result, subs, ctx, rl) in enumerate(self.term.apply(label if label else None)):
			where = self.print_context(ctx, rl.getLhs())
			print(f'({k}) {result} by applying {rl} on {where} with {subs}')
			results.append(result)

		self.select_one(results)

	@needs_term
	def do_inline(self, text):
		"""Apply a inline rewrite rule"""

		arrow_index = text.index('=>')
		lhs = self.module.parseTerm(text[:arrow_index])
		rhs = self.module.parseTerm(text[arrow_index + 2:])

		results = []  # results of the inline rewriting

		for k, (subs, ctx) in enumerate(self.term.match(lhs, maxDepth=maude.UNBOUNDED)):
			result = ctx(subs.instantiate(rhs))
			where = self.print_context(ctx, lhs)

			print(f'({k}) {result} in {where} with {subs}')
			results.append(result)

		self.select_one(results)

	@needs_module
	def do_add(self, text):
		"""Add a rule to the current module"""

		arrow_index = text.index('=>')
		lhs = self.module.parseTerm(text[:arrow_index])
		rhs = self.module.parseTerm(text[arrow_index + 2:])

		ml = maude.getModule('META-LEVEL')

		if self.metamodule is None:
			self.metamodule = ml.parseTerm(f"upModule('{self.module}, false)")
			self.metamodule.reduce()

		# Find the metarule operator
		term_kind = ml.findSort('Term').kind()
		rule_kind = ml.findSort('Rule').kind()
		attr_kind = ml.findSort('Attr').kind()
		none_term = ml.parseTerm('none', attr_kind)

		rl_symb = ml.findSymbol('rl_=>_[_].', (term_kind, term_kind, attr_kind), rule_kind)

		# Generate the new rule at the metalevel
		rl_term = rl_symb.makeTerm((ml.upTerm(lhs), ml.upTerm(rhs), none_term))

		# Insert the rule into the module
		mm_args = list(self.metamodule.arguments())
		rls_symb = ml.findSymbol('__', (rule_kind, rule_kind), rule_kind)

		mm_args[7] = rls_symb(mm_args[7], rl_term)

		self.metamodule = self.metamodule.symbol().makeTerm(mm_args)

		# Update the current module
		self.module = maude.downModule(self.metamodule)

		if self.term:
			self.term = self.module.parseTerm(str(self.term))

		print('The rule has been inserted.')

	@needs_module
	def do_trs(self, _):
		"""Generate a TRS file from the rules of the current module"""

		self.make_trs(sys.stdout)

	@needs_module
	def do_termination(self, _):
		"""Check the termination of the rules in the current module"""

		with tempfile.NamedTemporaryFile('w', suffix='.trs') as tmpf:
			self.make_trs(tmpf)
			tmpf.flush()
			subprocess.run(('java', '-jar', 'aprove.jar', '-m', 'wst', tmpf.name, '-p', 'plain'))

	@needs_module
	def do_confluence(self, _):
		"""Check confluence of the rules in the current module"""

		with tempfile.NamedTemporaryFile('w', suffix='.trs') as tmpf:
			self.make_trs(tmpf)
			tmpf.flush()

			try:
				subprocess.run(('csi.sh', tmpf.name))

			except FileNotFoundError:
				print('Cannot find csi.sh from the CSI tool in the system path.\n'
				      'It can downloaded from http://cl-informatik.uibk.ac.at/software/csi/.')

	def do_EOF(self, _):
		"""Exits the interpreter"""

		print()
		return True

	def select_one(self, options):
		"""Select one of the options for the current term"""

		if not options:
			print('No rewrites are possible.')

		elif len(options) == 1:
			print('\nThere is only one option.')

			self.term = options[0]

		else:
			option = '#'

			while not option.isdecimal() or not (0 <= int(option) < len(options)):
				option = input(f'\nSelect one of the options (0-{len(options) -1}): ')

			self.term = options[int(option)]

	def print_context(self, ctx, lhs):
		"""Print the context"""
		var_name = f'<<PH>>:{lhs.getSort()}'
		var_term = self.module.parseTerm(var_name)

		ctx = ctx(var_term)

		return 'top' if ctx.isVariable() else \
		       str(ctx).replace(var_name, '\x1b[32m@\x1b[0m')

	def make_trs(self, out):
		"""Make a TRS file from the current module"""

		varset = set()

		for rl in self.module.getRules():
			lhs, rhs = rl.getLhs(), rl.getRhs()

			find_vars(lhs, varset)
			find_vars(rhs, varset)

		print_var = lambda v: f'{v.getVarName()}:{v.getSort()}'
		print('(VAR ' + ' '.join(map(print_var, varset)) + ')', file=out)
		print('(RULES', file=out)

		for rl in self.module.getRules():
			lhs, rhs = rl.getLhs(), rl.getRhs()
			print(f'\t{lhs.prettyPrint(0)} -> {rhs.prettyPrint(0)}', file=out)

		print(')', file=out)


if __name__ == '__main__':

	maude.init()

	# Command-line interface
	interface = InteractiveRewriter()

	interface.cmdloop()
