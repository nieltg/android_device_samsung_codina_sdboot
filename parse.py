#!/usr/bin/env python

import argparse

parser = argparse.ArgumentParser (add_help=False)

g = parser.add_argument_group ('available options')

g.add_argument ('-h', '--help', action='help', help='show this help message and exit')
g.add_argument ('mode', action='store', choices=['pre', 'post'], help="change execution mode")
g.add_argument ('base_dir', action='store', help="base directory of intermediate files")
g.add_argument ('out_link', action='store', help="link to the base directory in kernel out")

g = parser.add_argument_group ('content description')

g.add_argument ('-f', action='append', dest='file', nargs=5,
                metavar=('NAME', 'LOCATION', 'MODE', 'UID', 'GID'))
g.add_argument ('-a', action='append', dest='ln_h', nargs=2,
                metavar=('NAME', 'TARGET'))
g.add_argument ('-d', action='append', dest='dirs', nargs=4,
                metavar=('NAME', 'MODE', 'UID', 'GID'))
g.add_argument ('-n', action='append', dest='node', nargs=7,
                metavar=('NAME', 'MODE', 'UID', 'GID', 'TYPE', 'MAJ', 'MIN'))
g.add_argument ('-l', action='append', dest='ln_s', nargs=5,
                metavar=('NAME', 'TARGET', 'MODE', 'UID', 'GID'))
g.add_argument ('-p', action='append', dest='pipe', nargs=4,
                metavar=('NAME', 'MODE', 'UID', 'GID'))
g.add_argument ('-s', action='append', dest='sock', nargs=4,
                metavar=('NAME', 'MODE', 'UID', 'GID'))

argp = parser.parse_args ()

if argp.mode == 'pre':
	nlist = ""
	
	for f in argp.file:
		nlist += f[1] + " "
	
	print (nlist[:-1])
	
else: # default: post
	
	print ("TODO: unimplemented!")
	sys.exit (1)

