#!/usr/bin/bash
# monkey patch LazyVim for "object" type
# hopefully it will remain functional as a guard to no startup error
# on any error with a new LazyVim version do the "x", "I" and
# reapply this monkey patch
LAZY="$HOME/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/init.lua"
KEY="(if lazy_clipboard ~= nil)"
sed -ri "s/$KEY/\1 and type(lazy_clipboard) ~= \"object\"/" "$LAZY"
