#!/bin/bash

# this file is to scan a directory and check the sha1sum of each dat file
# it accepts a directory which has dat directory, 256 sub directories
# if it has garbage directory, it will also scan this directory

set -e

NUMDIR=256
MAXDEPTH=2
mismatch_times=0
datadir=
is_resume=1
is_fast=false
progress_file=/var/tmp/scrubber_progress.txt
log_file=/var/tmp/scrubber_log_`date +%s`

function log2log() {
    message="$@"
    echo $message
    echo $message >> $log_file
}

function log2progress() {
    message="$@"
    echo $message >> $progress_file
}

function parsedir() {
    local dirname file filepath filenames orig_sha1 calc_sha1
    dirname=$1
    for file in $(ls $dirname); do
        filepath=$dirname/$file
        if test -f $filepath; then
            orig_sha1=`echo $file | tr '.' ' ' | awk '{print $1}'`
            calc_sha1=`sha1sum -b $filepath | awk '{print $1}'`
            if [ "$orig_sha1" != "$calc_sha1" ]; then
                mismatch_times=`expr $mismatch_times + 1`
                log2log "ERROR: orig sha1 $orig_sha1,
                        calc sha1 $calc_sha1 for file $filepath"
            fi
            if [ "$is_fast" == "false" ]; then
                sleep 1s
            fi
        else
            log2log "ERROR $filepath is not a file"
        fi
    done
}

function scandir() {
    local cur_dir workdir depth next_depth numdirs dirlist
    workdir=$1
    depth=$2
    cd ${workdir}
    if [ ${workdir} = "/" ]; then
        cur_dir=""
    else
        cur_dir=$(pwd)
    fi

    numdirs=`ls -l $cur_dir | wc | awk '{print $1;}'`
    if [ $numdirs -lt $NUMDIR ]; then
        log2log "ERROR: directory $cur_dir seems not \
                have less than $NUMDIR directories"
        # ignore here
    fi

    log2log "scan directory $cur_dir, depth $depth"
    for dirlist in $(ls $cur_dir); do
        if test -d $dirlist; then
            if [ $depth == $MAXDEPTH ]; then
                cur_scan_dir=$cur_dir/$dirlist
                log2log "now check the data files in dir $cur_scan_dir"
                if (( $is_resume == 1 )) && \
                   [[ `grep $cur_scan_dir $progress_file` ]]; then
                    log2log "skip dir $cur_scan_dir"
                    continue
                fi
                parsedir $cur_scan_dir
                log2progress $cur_scan_dir
            else
                next_depth=`expr $depth + 1`
                scandir ${cur_dir}/${dirlist} $next_depth
            fi
        fi
    done
}

function usage() {
    log2log "Usage: ./offline_scrubber.sh -d <dir> -n -f -h"
    log2log "-d|--dir <dir containing dat>: the directory to scan"
    log2log "-n|--new: to start a new scan;"
    log2log "          default is to resume from previous progress"
    log2log "-f|--fast: fast mode, not sleep after scanning an object;"
    log2log "           default is to sleep 1s"
    log2log "-h|--help: usage"
}

function checkDataDir() {
    if [ "$datadir" == "" ]; then
        log2log "you have to provide a directory"
        exit 1
    fi
}

while [ "$1" != "" ]; do
    case $1 in
        -d | --dir )            shift
                                datadir=$1
                                checkDataDir
                                ;;
        -n | --new )            is_resume=0
                                ;;
        -f | --fast )           is_fast=true
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

checkDataDir

if test -d $datadir; then
    log2log "Starting the scan at " `date`
    if test -e $progress_file; then
        if test ! -f $progress_file; then
            log2log "The progress file $progress_file is not a file"
            log2log "please remove it first"
            exit 1
        fi
    else
        dir=`dirname $progress_file`
        mkdir -p $dir && touch $progress_file
        log2log "Create progress file $progress_file"
    fi

    if (( $is_resume == 0 )); then
        log2log "This scan is a new scan, empty file $progress_file"
        mv $progress_file ${progress_file}.backup
        touch $progress_file
    else
        log2log "This scan will use the previous progress file $progress_file"
    fi

    start_time=$(($(date +%s%N)/1000000))
    # first check the dat directory
    datdir=$datadir/dat
    log2log "Starting to check dat directory $datdir"
    if test -d $datdir; then
        scandir $datdir 1
    else
        log2log "ERROR: $datdir is not directory"
    fi

    # then check garbage directory
    gcdir=$datadir/garbage
    log2log "Starting to check garbage directory $gcdir"
    if test -d $gcdir; then
        for dirlist in $(ls $gcdir); do
            gcsub=$gcdir/$dirlist
            gcsubdat=${gcsub}/dat
            if test -d $gcsub && test -d $gcsubdat; then
                scan $gcsubdat 1
            fi
        done
    else
        log2log "ERROR: $gcdir is not directory"
    fi

    end_time=$(($(date +%s%N)/1000000))
    log2log "In the end, $mismatch_times files have mismatches SHA values"
    log2log "The scan lasts " `expr $end_time - $start_time` " microseconds"
elif test -f $1; then
    log2log "you input a file but not a directory,pls reinput and try again"
    exit 1
else
    log2log "the Directory isn't exist which you input,pls input a new one!!"
    exit 1
fi
exit 0
