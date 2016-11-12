#!/bin/bash

# append more commands here as you wish
STAT_CMDS="status_uptime status_pycmdsinfo status_rcptinfo status_tds status_disks status_threads status_ops status_queues"
LPORT=2001
TIMEOUT=2
NAME=c-py-tdn
PNAME=`which $NAME`
PID=`pgrep -u bds $NAME | awk 'END{print}'`

do_help()
{
    cat <<EOC
    Usage: $0 [OPTION]

        --backtrace, -b     print the backtrace of existing tdn process.
        --coredump, -c      generate coredump of existing tdn process.
        --runtime, -r       print runtime status of existing tdn process.
        --system, -s        print system information, e.g. CPU/Mem/Disk.
        --all, -a           run all the above.
        --help, -h          print this help message.
EOC
}

# collect runtime statistic of the tdn process
do_runtime()
{
    numinstances=`ps -ef | grep $NAME | wc | awk '{print $1}'`
    if [ $numinstances -eq 0 ]; then
        echo "number of tdn instances is zero, cannot get runtime status"
        exit 1
    fi

    hosts=`netstat -l | grep LISTEN | grep $LPORT | awk '{split($4, parts, ":"); print parts[1]}'`
    for host in $hosts; do
        # if listen on any, use localhost directly
        if test "$host" = "*"; then
            host=127.0.0.1
        fi

        echo "[host]"
        echo $host

        for cmd in $STAT_CMDS; do
            echo "[$cmd]"
            echo -e "$cmd" | nc $host $LPORT -w $TIMEOUT
        done
    done
}

# collect system information
do_sys()
{
    echo "[disk space]"
    df

    echo "[cpu]"
    top -b -n1

    echo "[memory]"
    cat /proc/meminfo

    echo "[netstat]"
    netstat -anp

    echo "[vmstat]"
    vmstat 1 8

    echo "[iostat]"
    iostat 1 8
}

# collect backtrace of the tdn process
do_bt()
{
    echo "[backtrace]"
    gdb $PNAME $PID <<EOF
        set pagination off
        info stack
        info registers
        info threads
        thread apply all bt full
        quit
EOF
}

# generate the coredump of the tdn process
do_core()
{
    # make sure have enough space for coredump
    vsz=`ps up $PID | grep $PNAME | awk '{print $5}'`
    echo -n "Need $vsz bytes to save the coredump, continue? [Y/n] "
    read c
    case $c in
        Y|y)
            corefile=$NAME-core
            gcore -o $corefile $PID

            # NOTE: gcore will append $PID in the filename
            # so the core is actually saved as $NAME-core.$PID
            corefile=$corefile.$PID
            coredir=/tmp/tdn/

            mv $corefile $coredir
            echo "$corefile is saved in $coredir."
            ;;
        *)
            echo "Skip generating coredump!"
            ;;
    esac
}

opt_bt=false
opt_core=false
opt_runtime=false
opt_sys=false

# parse options to decide what to do next
{
    while test "$#" -gt 0; do
        opt="$1"
        shift
        case $opt in
            --backtrace|-b)
                opt_bt=true
                ;;
            --coredump|-c)
                opt_core=true
                ;;
            --runtime|-r)
                opt_runtime=true
                ;;
            --system|-s)
                opt_sys=true
                ;;
            --all|-a)
                opt_bt=true
                opt_core=true
                opt_runtime=true
                opt_sys=true
                ;;
            --help|-h)
                do_help
                exit 0
                ;;
            *)
                do_help
                exit 1
                ;;
        esac
    done
}

$opt_sys && do_sys
$opt_runtime && do_runtime
$opt_bt && do_bt
$opt_core && do_core

exit 0
