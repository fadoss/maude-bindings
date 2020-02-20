project('maude-bindings', 'cpp', version: '0.1')

#
## Dependencies

# Uses https://github.com/fadoss/maudesmc
maude_proj = subproject('maudesmc', default_options: ['with-ltsmin=disabled', 'with-smt=no'])
libmaude_dep = maude_proj.get_variable('libmaude_dep')

# Simplified Wrapper and Interface Generator (http://www.swig.org/)
swig = find_program('swig')
swig_gen = generator(swig,
	output: ['@BASENAME@_wrap.cxx'],
	arguments: ['-c++', '-python', '-outdir', '.',
		    '-o', '@OUTPUT@', '-MMD', '@INPUT@'],
	depfile: '@BASENAME@.d'
)

# Python 3 (https://www.python.org/)
python = dependency('python3')


#
## Python library

# Use the same configuration set as Maude
libmaude_conf = maude_proj.get_variable('conf')
configure_file(output: 'config.h', configuration: libmaude_conf)

add_project_arguments('-Wno-non-virtual-dtor', language : 'cpp')
add_project_arguments('-DHAVE_CONFIG_H', language : 'cpp')

pybind_swig = swig_gen.process('swig/maude.i')

pybind_source = [
	'src/maude_wrappers.cc',
	'src/easyTerm.cc'
]
pybind = shared_module('_maude', pybind_source, pybind_swig,
		       include_directories: include_directories('src'),
		       dependencies: [python, libmaude_dep], name_prefix: '')
