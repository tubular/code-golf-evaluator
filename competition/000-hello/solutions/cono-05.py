#! /usr/bin/env -S python3

import sys

for line in sys.stdin:
    print("hello, "+line.rstrip('\r\n'))
