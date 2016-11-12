#!/bin/bash
#
# This script is supposed to run in top-level of ctriton source directory

TMS_HOST=${1:-"tms01"}
TMS_REPLICAS=${2:-"tms02"}

pushd protobufs

protoc --python_out=. *.proto
ruby-protoc *.proto

popd

pushd c-py-tdn/systests
if [ -e test/reports/ ] ; then
    rm -rf test/reports/
fi
./run_mdb_tests.py --host $TMS_HOST --replicas $TMS_REPLICAS --output xml

popd
