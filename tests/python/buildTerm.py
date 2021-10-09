import maude

maude.init(advise=False)

mod = maude.getModule('NAT')
natk = mod.findSort('Nat').kind()

splus  = mod.findSymbol('_+_', [natk, natk], natk)
stimes = mod.findSymbol('_*_', [natk, natk], natk)

onetwo = [mod.parseTerm('1'), mod.parseTerm('2')]
three  = mod.parseTerm('3')

# Constructs 4 + (3 * (1 + 2))
expr = splus.makeTerm((mod.parseTerm('4'),
                      stimes.makeTerm([three,
                                      splus.makeTerm(onetwo)])))

print(expr.getSort(), ':', expr)
expr.reduce()
print(expr)

# Constructs a variable by parsing
var = mod.parseTerm('N:Nat')

print(var, var.isVariable(), var.getVarName())
print(expr, expr.isVariable(), expr.getVarName())
