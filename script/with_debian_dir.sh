#!/bin/bash

if [ -e debian ]; then
    mv debian debian_moved_out_of_the_way_$$
fi

ln -s $1 debian
eval $2
rc=$?
unlink debian

if [ -e debian_moved_out_of_the_way_$$ ]; then
    mv debian_moved_out_of_the_way_$$ debian
fi

exit $rc
