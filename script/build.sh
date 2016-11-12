#!/bin/bash -e


BUILDTYPE_ARGS=
while [[ $# -gt 0 && $1 != '--' ]] ; do
    BUILDTYPE_ARGS+=" $1"
    shift;
done

if [[ $1 == '--' ]] ; then
    shift;
    CONFIG_ARGS=$*
fi

if [ ! -x configure ]; then
    autoreconf -i
fi

eval set -- "$BUILDTYPE_ARGS"

if [ ! -f Makefile ]; then
    if [ "$1" = "debug" ]; then
        export CXXFLAGS='-g -O0 -DDEBUG'
    elif [ "$1" = "coverage" ]; then
        export CXXFLAGS='-g -O0 -fprofile-arcs -ftest-coverage'
        export LDFLAGS='-fprofile-arcs'
    else
        export CXXFLAGS='-DNDEBUG'
        ASSERTFLAGS=--disable-assert
    fi

    if [[ -f /usr/bin/g++-3.4 && -f /usr/bin/g++-4.1 ]] ; then
        # on etch OS, both g++-3.4 & g++-4.1 are available, g++-4.1
        # is the default one, but it will accidently segfault with
        # no reason and also lead to a very slow linkage. Downgrade to g++-3.4
        export CXX=g++-3.4
        export CC=gcc-3.4
    fi
    ./configure --prefix=/usr --disable-shared --enable-static $ASSERTFLAGS $CONFIG_ARGS
fi
j=$(grep processor /proc/cpuinfo | wc -l)
make -j$j && make c-py-tdn/unittests/run_tests -j$j
