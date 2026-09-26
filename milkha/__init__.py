"""Milkha: A FastAPI-compatible web framework for Mojo.

This package provides the Milkha framework source files (.mojo) for
use with the Mojo language. Install via pip to get the source, then
use with the Mojo toolchain.

For full functionality, you need:
    pixi install
    pixi run mojo <your-script>.mojo
"""

__version__ = "0.1.0"
__author__ = "Niranjan Anandkumar"
__email__ = "nirunitk@gmail.com"
__license__ = "MPL-2.0"

# This Python shim allows the package to be installed via pip/PyPI.
# The actual framework code is in the .mojo files which require the
# Mojo toolchain to compile and run.
