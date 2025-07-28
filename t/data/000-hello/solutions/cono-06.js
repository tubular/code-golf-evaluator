#!/usr/bin/env node
process.stdin.on('data',d=>d.toString().split('\n').filter(l=>l).forEach(l=>console.log('hello, '+l)))
