#!/bin/bash

RUN_TESTS_BINS=`find c-py-tdn -name run_tests | grep -v '.libs'`
if [ -z "$RUN_TESTS_BINS" ] ; then
    echo "Can't find any 'run_tests' program, abort!"
    exit 1
fi

mkdir -p test-results
# don't abort the test if assertion failed
export BDS_TEST_ABORTONFAILURE=0
testsuite=1
for test_bin in $RUN_TESTS_BINS
do
    outfile=test-results/ctriton-${testsuite}-unittest.xml
    echo "[INFO] run unit test with '$test_bin --test:xmlout=$outfile ..."
    $test_bin $@ --test:xmlout=$outfile
    ret=$?
    if [ "$ret" -ne 0 ] ; then
        echo "[ERR] unit test failed with exit code: '$ret'!"
        if [ $ret -ne 1 ] ; then
            # test case failure should exit with exitcode 1
            # non-one exit means unexpected ending of program
            echo  "[ERR] unit test program exits abnormally. Aborted!"
            # remove all the unittest output
            rm -f test-results/*-unittest.xml
            exit $ret
        fi
    fi
    if [ ! -s "$outfile" ] ; then
        echo "[INFO] Remove empty output file $outfile"
        rm -f $outfile
    fi
    ((testsuite = testsuite + 1))
done
exit 0
