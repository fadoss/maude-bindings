import maude

maude.init(advise=False)
maude.load('smt')

cnv = maude.getModule('CONVERSION')
smt = maude.getModule('REAL-INTEGER')

def print_conversions(t):
	print(int(t))
	print(float(t))
	t.reduce()
	print(int(t))
	print(float(t))


print_conversions(cnv.parseTerm('12.34'))
print_conversions(cnv.parseTerm('567'))
print_conversions(cnv.parseTerm('-135'))
print_conversions(smt.parseTerm('89'))
print_conversions(smt.parseTerm('34/12'))
print_conversions(smt.parseTerm('false'))
print_conversions(cnv.parseTerm('s(N:Nat)'))
print_conversions(cnv.parseTerm('1 + 2'))
print_conversions(cnv.parseTerm('1.2 + 4.5'))
