#! /usr/bin/env -S python

import sys

for line in sys.stdin:
    print("hello, "+line.rstrip('\r\n'))
