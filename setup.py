from skbuild import setup

with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name='maude',
    version='0.2',
    author='ningit',
    author_email='ningit@users.noreply.github.com',
    description='Experimental Python bindings for Maude',
    long_description=long_description,
    url='https://github.com/fadoss/maude-bindings',
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
