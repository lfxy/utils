#!/bin/bash
#
# Clone triton-qa-automation.git repository and run the restAPI test cases
# This script is supposed to run in top-level of ctriton source directory

PACKAGE=${1:?"No package name given!"}
UPSTREAM_BRANCH=${2:?"No branch name given!"}

TDS_HOST="tds01"
TMS_HOST="tms01"
TMS_REPLICAS="tms02"

MAJOR_RELEASE=1.6.1
if [[ $UPSTREAM_BRANCH =~ release/.* ]] ; then
    MAJOR_RELEASE=${UPSTREAM_BRANCH#release/}
fi


case $PACKAGE in
c-py-tds)
    buildtools/tds-smoke-test.sh $TDS_HOST $MAJOR_RELEASE
    ;;

tms)
    buildtools/tms-smoke-test.sh $TMS_HOST $TMS_REPLICAS
    ;;

all)
    buildtools/tms-smoke-test.sh $TMS_HOST $TMS_REPLICAS
    buildtools/tds-smoke-test.sh $TDS_HOST $MAJOR_RELEASE
    ;;

esac
