# Package

version     = "0.0.2"
author      = "tadashibashi"
description = "TBM to MOD converter"
license     = "MIT"
srcDir      = "src"
binDir      = "bin"
bin         = @["tbm2mod"]

requires "https://github.com/stoneface86/libtrackerboy#v0.8.3"
requires "https://github.com/planety/fsnotify"

# Dependencies
requires "nim >= 2.0.0"
