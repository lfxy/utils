#!/bin/bash
#
# Clone triton-qa-automation.git repository and run the restAPI test cases
# This script is supposed to run in top-level of ctriton source directory

TDS_HOST=${1:-"tds01"}
MAJOR_RELEASE=${2:-"1.6.1"}
SITE=${3:-'qa'}
USER_PASSWORD=${4:-'test123'}

if [ -e triton-qa-automation ] ; then
    rm -rf triton-qa-automation
fi

# clone the source code, git doesn't support multiple SCM
git clone git@labs.dechocorp.com:triton-qa-automation triton-qa-automation
if [ $? -ne 0 ] ; then
    "[ERROR] Clone gerrit.dechocorp.com:triton-qa-automation failed!"
    exit 1
fi

# get the triton-qa-automation git code and run the tests
pushd triton-qa-automation/testcases2/rest_api/
if [[ -n ${MAJOR_RELEASE} ]]; then
    git checkout "tds-$MAJOR_RELEASE"
fi

# The result will be generated in triton-qa-automation/testcases2/rest_api/smoke_final.xml
# in JUnit format
./rest_api_smoke.sh $SITE $TDS_HOST $USER_PASSWORD
ret=$?
popd
exit $ret
