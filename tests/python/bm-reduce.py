#
# Benchmark reducing a constant with the Maude library and two other approaches
#

import os
import socket
import subprocess
import time
import timeit

import maude


def reduce_io():
	"""Reduce 0 by input/output interaction with a Maude interpreter process"""

	p.stdin.write(b'red 0 .\n')
	p.stdin.flush()

	answer = p.stdout.readline()

	return answer[answer.index(b':') + 1:].strip().decode('ascii')


def reduce_lib():
	"""Reduce 0 using the maude language bindings"""

	t = m.parseTerm('0')
	t.reduce()
	return str(t)


def reduce_socket():
	"""Reduce 0 using a Maude-based reducer server"""

	sock.write('0\n')
	sock.flush()
	return sock.readline().strip()


if __name__ == '__main__':

	# Maude binary to be used
	maude_binary = os.getenv('MAUDE_BIN')

	if not maude_binary:
		maude_binary = 'maude'

	# The maude library
	maude.init()
	m = maude.getCurrentModule()

	print('lib', timeit.timeit('reduce_lib()', setup='from __main__ import reduce_lib'))

	# The I/O approach
	p = subprocess.Popen([maude_binary, '-no-banner', '-no-wrap'],
	                     stdin=subprocess.PIPE, stdout=subprocess.PIPE)

	p.stdin.write(b'\nset show command off . set show stats off .\n')
	p.stdin.flush()

	print('io', timeit.timeit('reduce_io()', setup='from __main__ import reduce_io'))

	# The Maude-based server approach
	p.stdin.write(b'\nsload bm-reduce\nquit .\n')
	p.stdin.flush()

	time.sleep(2)  # Wait for the server to be started

	raw_sock = socket.create_connection(('127.0.0.1', 1234))
	sock = raw_sock.makefile('rw')

	print('socket', timeit.timeit('reduce_socket()', setup='from __main__ import reduce_socket'))

	sock.write('c\n')
	sock.close()
	raw_sock.close()
	p.wait()
