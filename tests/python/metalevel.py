import maude

maude.init(advise=False)

nat = maude.getModule('NAT')
meta = maude.getModule('META-LEVEL')

zero = nat.parseTerm('0')
one  = nat.parseTerm('1')

t1 = meta.parseTerm("match '0.Zero s.t. nil")

s = nat.downStrategy(t1)

t2 = meta.upStrategy(s)

print(t1, '->', s, '->', t2)
print('Applied to', zero, '->', list(zero.srewrite(s)))
print('Applied to', one, '->', list(one.srewrite(s)))

#####

t = meta.parseTerm("'_+_['0.Zero, 'N:Nat]")

s1 = nat.downTerm(t)
s2 = meta.downTerm(t)

print(t, '->', s1, 'in NAT, ', s2, 'in META-LEVEL')

#####

t1 = nat.parseTerm("(1 + 2) * 3 + J:Nat")
t2 = nat.parseTerm("(1 + 2) * 3 + J:Nat")

s1 = meta.upTerm(t1)
s2 = meta.upTerm(t2)

print(t1, '->', s1)
print(t2, '->', s2)

print(s1 == s2)

#####

print(nat.upTerm(t1), nat.downTerm(t1))
