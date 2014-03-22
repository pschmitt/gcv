#!/usr/bin/env sh

[[ $1 == "-b" ]] && {
    make clean
    make
    shift
}
make run -- $*
