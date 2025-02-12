#!/usr/bin/bash
# build C script
PREFIX=${PREFIX:-/usr}
gcc -I$PREFIX/include/lua5.1 c/doris.c -c -fPIC
gcc doris.o -shared -o doris.so

#in lua directory: lua/doris/?.lua
#doris = loadlib("../../doris.so", "luaopen_doris")

gcc c/audio.c -o audio -lm
