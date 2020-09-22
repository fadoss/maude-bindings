/**
 * Helper functions to make the usage of the Maude Javascript bindings easier.
 *
 * Ideally, the prototypes of the represented Maude objects should be extended
 * with the functions below, but these do not seem to be accessible without
 * creating those objects.
 */

/**
 * Make the return value of Term.srewrite iterable
 * (given such an object or its prototype)
 */
function makeSrewriteIterable(thing) {
	thing[Symbol.iterator] = function () {
		return {
			it: this,
			next: function () {
				var elem = this.it.__next()
				return elem ? { done: false, value: [elem, this.it.getRewriteCount()] }
					    : { done: true }
			}
		}
	}
}

/**
 * Get the path from the initial to the given state from a search state.
 */
function pathTo(search, stateNr) {
	var parent = search.getStateParent(stateNr)

	if (parent < 0)
		path = [search.getStateTerm(stateNr)]
	else {
		path = pathTo(search, parent)

		path.push(search.getRule(stateNr))
		path.push(search.getStateTerm(stateNr))
	}

	return path
}

/**
 * Make the return value of Term.search iterable
 * (given such an object or its prototype)
 */
function makeSearchIterable(thing) {
	thing[Symbol.iterator] = function () {
		return {
			it: this,
			next: function () {
				var it = this.it
				var elem = it.__next()

				return elem ? { done: false, value: [elem, it.getSubstitution(),
				                                     function () { return pathTo(it, it.getStateNr()); },
				                                     it.getRewriteCount()] }
					    : { done: true }
			}
		}
	}
}

module.exports = {
	makeSrewriteIterable: makeSrewriteIterable,
	makeSearchIterable: makeSearchIterable
}
