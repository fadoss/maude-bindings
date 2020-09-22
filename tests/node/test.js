var maude = require('maude')
var helper = require('./maude_helpers')

maude.init()
maude.load('../example.maude')

example = maude.getCurrentModule()
nat = maude.getModule('NAT')

////////

var t = nat.parseTerm('1 + (3 * 5 + 7) * 11 + 13')
var t0 = t.copy()
t.reduce()
console.log(t0.toString(), '=', t.toString())

////////

var ans = example.parseTerm('f(a, b)')
ans.rewrite()
console.log(ans.toString())

////////

ans = example.parseTerm('f(a, a)')
ans.frewrite(1)
console.log(ans.toString())

////////

var fbb = example.parseTerm('f(b, b)')
var {first: ans, second: nrew} = fbb.erewrite()
console.log(fbb.toString(), '->', ans.toString(), 'in', nrew, 'rewrites')

////////

ans = example.parseTerm('f(a, b)')
var it = ans.srewrite(example.parseStrategy('swap *'))

helper.makeSrewriteIterable(it)

for ([sol, nrew] of it)
	console.log(sol.toString(), 'in', nrew, 'rewrites')

////////

var initial = example.parseTerm('f(a, a)')
var pattern = example.parseTerm('f(c, X:Symbol)')
it = initial.search(maude.ANY_STEPS, pattern)

helper.makeSearchIterable(Object.getPrototypeOf(it))

for ([sol, subs, path, nrew] of it) {
	var printablePath = path().map(function (x) { return x.toString() })
	console.log(sol.toString(), 'with', subs.toString(), 'by', printablePath)
}
