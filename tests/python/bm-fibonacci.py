#
# Benchmark the iterative reduction of a term using the Maude library and
# two alternative approaches
#

fib_maude = '''fmod FIBONACCI is
	protecting LIST{Nat} .

	op next : List{Nat} -> List{Nat} .

	var N M : Nat .
	var L   : List{Nat} .

	eq next(N M L) = (N + M) N M L .
endfm'''

sock_maude = r'''sload socket

mod FIBONACCI-SOCK is
	protecting FIBONACCI .
	protecting SOCKET .
	protecting CONVERSION .
	protecting (META-LEVEL + LEXICAL) * (
		op nil to eil, op __ to _#_,
		op append to $append,
		op head to $head,
		op tail to $tail,
		op last to $last,
		op front to $front,
		op occurs to $occurs,
		op reverse to $reverse,
		op $reverse to $$reverse,
		op size to $size,
		op $size to $$size
	) .

	op Fib : -> Cid [ctor] .
	op fib : -> Oid [ctor] .

	sort State .
	ops start wait-server wait-client active end : -> State [ctor] .

	op state:_ : State -> Attribute [ctor] .
	op l:_ : List{Nat} -> Attribute [ctor] .
	op ssock:_ : Oid -> Attribute [ctor] .
	op sock:_ : Oid -> Attribute [ctor] .

	vars S C : Oid .
	vars N M : Nat .
	var  T   : String .
	var  L   : List{Nat} .

	rl
		< fib : Fib | state: start >
	=>
		< fib : Fib | state: wait-server >
		createServerTcpSocket(socketManager, fib, 1234, 1)
	.

	rl
		< fib : Fib | state: wait-server >
		createdSocket(fib, socketManager, S)
	=>
		< fib : Fib | state: wait-client, ssock: S >
		acceptClient(S, fib)
	.

	rl
		< fib : Fib | state: wait-client, ssock: S >
		acceptedClient(fib, S, T, C)
	=>
		< fib : Fib | state: wait-client, ssock: S, sock: C >
		receive(C, fib)
	.

	crl
		< fib : Fib | state: wait-client, ssock: S, sock: C >
		received(fib, C, T)
	=>
		< fib : Fib | state: wait-client, ssock: S, sock: C, l: L >
		send(C, fib, "-\n")

	if L := downTerm(getTerm(metaParse(['FIBONACCI], tokenize(T), 'List`{Nat`})), nil) .

	rl
		< fib : Fib | state: wait-client, ssock: S, sock: C, l: L >
		sent(fib, C)
	=>
		< fib : Fib | state: active, ssock: S, sock: C, l: L >
		receive(C, fib)
	.

	rl
		< fib : Fib | state: active, ssock: S, sock: C, l: (N M L) >
		received(fib, C, "n\n")
	=>
		< fib : Fib | state: active, ssock: S, sock: C, l: ((N + M) N M L) >
		send(C, fib, string(N + M, 10) + "\n")
	.

	rl
		< fib : Fib | state: active, ssock: S, sock: C, l: L >
		sent(fib, C)
	=>
		< fib : Fib | state: active, ssock: S, sock: C, l: L >
		receive(C, fib)
	.

	rl
		< fib : Fib | state: active, ssock: S, sock: C, l: L >
		received(fib, C, "c\n")
	=>
		< fib : Fib | state: active, ssock: S, sock: C >
		closeSocket(C, fib)
	.

	rl
		< fib : Fib | state: active, ssock: S, sock: C >
		closedSocket(fib, C, T)
	=>
		< fib : Fib | state: active, ssock: S >
		closeSocket(S, fib)
	.

	rl
		< fib : Fib | state: active, ssock: S >
		closedSocket(fib, S, T)
	=>
		< fib : Fib | state: end >
	.
endm
'''


def spiral_maude():
	import maude

	maude.init()
	maude.input(fib_maude)
	cm = maude.getCurrentModule()

	x = cm.parseTerm(f'1 0')

	nat_kind = cm.findSort('Nat').kind()

	next_symb = cm.findSymbol('next', (nat_kind, ), nat_kind)

	while True:
		yield int(str(next(x.arguments())))
		x = next_symb(x)
		x.reduce()


def maude_reduce(p, term):
	p.stdin.write(f'red {term} .\n'.encode('ascii'))
	p.stdin.flush()

	answer = p.stdout.readline()

	return answer[answer.index(b':') + 1:].strip().decode('ascii')


def spiral_popen():
	import os
	import subprocess

	p = subprocess.Popen([os.getenv('MAUDE_BIN') or 'maude', '-no-banner', '-no-wrap'],
	                     stdin=subprocess.PIPE, stdout=subprocess.PIPE)

	p.stdin.write(fib_maude.encode('ascii'))
	p.stdin.write(b'\nset show command off . set show stats off .\n')
	p.stdin.flush()

	x = f'1 0'

	while True:
		yield int(x.split()[0])
		x = maude_reduce(p, f'next({x})')


def spiral_socket():
	import os
	import socket
	import subprocess

	p = subprocess.Popen([os.getenv('MAUDE_BIN') or 'maude', '-no-banner'],
	                     stdin=subprocess.PIPE, stdout=subprocess.DEVNULL)
	p.stdin.write(fib_maude.encode('ascii') + b'\n' + sock_maude.encode('ascii')
	              + b'\nerew <> < fib : Fib | state: start > .\nquit .\n')
	p.stdin.flush()

	# Connect to the port opened by Maude
	raw_sock = None

	while raw_sock is None:
		try:
			raw_sock = socket.create_connection(('127.0.0.1', 1234))

		except ConnectionRefusedError:
			pass

	x = '1 0\n'

	with raw_sock.makefile('rw') as sock:
		sock.write(x)
		sock.flush()
		sock.readline()

		while True:
			yield int(x.split()[0])
			sock.write('n\n')
			sock.flush()
			x = sock.readline()

		# sock.write('c\n')
		# sock.flush()

	# raw_sock.close()
	# p.wait()


if __name__ == '__main__':
	import argparse
	import itertools

	parser = argparse.ArgumentParser(description='Spiral generator')
	parser.add_argument('--draw', help='Draw the spiral', action='store_true')
	parser.add_argument('--eps', help='Epsilon for the module', type=float, default=1e-3)
	parser.add_argument('imp', help='Implementation', choices=['lib', 'io', 'socket', 'py'], default='lib')
	parser.add_argument('index', help='Index of the series to compute', type=int)

	args = parser.parse_args()

	imp = {'lib': spiral_maude, 'io': spiral_popen, 'socket': spiral_socket}[args.imp]

	for f in itertools.islice(imp(), args.index):
		print(f)
