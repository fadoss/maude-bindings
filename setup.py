from skbuild import setup

with open("build/PythonPkgDescription.md", "r") as fh:
    long_description = fh.read()

setup(
    name='maude',
    version='1.0.1',
    author='ningit',
    author_email='ningit@users.noreply.github.com',
    description='Python bindings for Maude',
    long_description=long_description,
    url='https://github.com/fadoss/maude-bindings',
    project_urls={
        'Bug Tracker'   : 'https://github.com/fadoss/maude-bindings/issues',
        'Documentation' : 'https://fadoss.github.io/maude-bindings',
        'Source Code'   : 'https://github.com/fadoss/maude-bindings'
    },
    long_description_content_type="text/markdown",
    license='GPLv2',
    packages=['maude'],
    classifiers=[
         'Development Status :: 3 - Alpha',
         'Intended Audience :: Science/Research',
         'Programming Language :: Python',
         'Programming Language :: Python :: 3',
         'Topic :: Scientific/Engineering',
         'Operating System :: OS Independent',
     ]
)
