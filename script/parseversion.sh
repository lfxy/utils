#!/bin/bash

# parserversion.sh target_file [ input_files ... ]
# finds newest input_file which newer than target_file and updates target_file with
# parse of input_file. Does nothing if none of input_files are newer than
# target_file.

target=$1
newest=$2
shift 2

until [ -z "$1" ]
do
    if [[ $1 -nt "$newest" ]] ; then
        newest=$1
    fi
    shift
done

tmp_target=$target.tmp
if [[ -n "$newest" && "$newest" -nt "$target" ]] ; then
    version_info=(`sed -n '1 s/.\+(\(.*\)).\+/\1/p' $newest | sed 's/[^0-9\.-]//g' | sed -e 's/-/ /g' -e 's/\./ /g'`)
    major=${version_info[0]}
    minor=${version_info[1]}
    release=${version_info[2]}
    build=${version_info[3]}
    echo "#define CURRENT_PROTOCOL_VERSION MAKEVERSION(${major:-0},${minor:-0},${release:-0},${build:-0})" > $tmp_target
    if diff -q $tmp_target $target &>/dev/null ; then
        rm -f $tmp_target
    else
        # replace target file only if file content changes, so to avoid unnecessary file mtime change
        mv -f $tmp_target $target
    fi
fi
