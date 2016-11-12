#!/bin/bash

PROG=$(basename $0)

short_optstring="h,m:,n:,t:"
long_optstring=" -l help,major_version:,build_number:,tasks:"
short_long_opt_mapping="h:help,m:major_version,n:build_number,t:tasks"

usage()
{
    cat << EOF
Deploy triton TDS/TDN/TMS onto target machine

Usage: $PROG [options]

Options:
  -h,--help      Show this help message and exit
  -m,--major_version=<MAJOR_VERSION>
                 The major version deployed to target machine (required)
  -n,--build_number=<BUILD_NUMBER>
                 The build number of the package (required)
                 Combined with <MAJOR_VERSION> the package version can be determined
                 If not given, read from environment variable \$BUILD_NUMBER
  -t,--tasks=<TASK_LIST>
                 Deploy task list (required)
                 In the format of <host>:<component>,<host>:<component>
                 <component> can be tds,tdn,tms
                 use comma(,) to separate the tasks
                 use colon(:) to separate the host and component


Examples:

  Deploy tds 1.6-1.6.102 to smoke test node 10.135.224.72:
    $PROG -m 1.6 -n 102 -t 10.135.224.72:tds

  Deploy 1.6-1.6.103 tds and tdn to smoke test node 10.135.224.72 and 10.135.224.73:
    $PROG -m 1.6 -n 103 -t 10.135.224.72:tds,10.135.224.73:tdn

EOF

    return 0
}

load_default_options()
{
    opt_build_number=$BUILD_NUMBER
    return 0
}

short_opt_to_long_opt()
{
    for short_long in ${short_long_opt_mapping//,/ }
    do
        short_name=`echo $short_long | awk -F: '{print $1}'`
        long_name=`echo $short_long | awk -F: '{print $2}'`
        eval short_value="\$opt_${short_name}"
        if [ -n "$short_value" ] ; then
            eval "opt_${long_name}=\$short_value"
        fi
    done
    return 0
}

parse_options()
{
    parsed_params=$(getopt -n "$PROG" $long_optstring -- "$short_optstring" "$@")
    local parse_ret=$?
    [[ $parse_ret -ne 0 ]] && echo "Aborted!" && return $parse_ret

    eval set -- "$parsed_params"
    while [[ "$1" != "--" ]] ;
    do
        optind=$(echo ' ' "$1" | sed -r 's/^\s*-{1,2}//g')
        case "$optind" in
          h | help)
            usage && exit 0
            ;;

          your | option )
            # Other arguments without value
            eval opt_$optind=true
            shift
            ;;

          *)
            # '--opt value' style
            arg=$optind
            val=$2
            shift 2
            eval opt_$arg="\$val"
            ;;
        esac
    done

    # shift the '--' argument
    shift

    # Parse arguments after --
    # If you need position parameters, get them here
    [[ "$#" -ne 0 ]] && echo "Unused position arguments: $*"

    return 0
}

check_option()
{
    if [ -z "$opt_major_version" ] ; then
        echo "--major_version is required!" && return 1
    fi

    if [ -z "$opt_build_number" ] ; then
        echo "--build_number is required!" && return 1
    fi

    if [ -z "$opt_tasks" ] ; then
        echo "--tasks is required!" && return 1
    fi
    return 0
}

check_alive()
{
    local target=$1
    local host=$2
    local check_disk=$3
    if [[ $check_disk -eq 1 ]]; then
        local max_waiting=${4:-1200}
    else
        local max_waiting=${4:-60}
    fi
    local waiting=0
    local is_ready=0
    while true
    do
    if [[ $check_disk -eq 0 ]] ;then
        if echo -e 'exit\n' | nc $target $port ; then
            let is_ready=1
        fi
    else
        echo "check disk now.."
        if echo -e 'exit\n' | nc $target $port ; then
            if echo -e 'status_disks\nexit\n' | nc $target $port |grep "INITIALIZING" >/dev/null; then
                echo "TDN disk not ready yet..."
                let is_ready=0
            else
                let is_ready=1
            fi
        fi
    fi
        if [[ $is_ready -eq 0 ]]; then
            sleep_sec=10
            echo "Will check again after $sleep_sec seconds ..."
            sleep $sleep_sec
            ((waiting = waiting + sleep_sec))
            if [ $waiting -gt $max_waiting ] ; then
                echo "Wait enough long time, break ..."
                return 1
            fi
    else
        echo "check alive OK"
        break
        fi
    done
    return 0
}

deploy_packages()
{
    target=$1
    port=$2
    check_disk=$3
    shift 3
    packages=$*
    installlist=

    for p in $packages
    do
        installlist+=" $p=${opt_major_version}.${opt_build_number}-lenny1"
    done

    # execute following commands on target machine
    ssh -l root -o 'BatchMode=yes' $target <<EOF
#!/bin/bash -x
echo "Stop service ..."
if test -x /etc/init.d/c-py-tds ; then
    echo "Stop c-py-tds ..."
    /etc/init.d/c-py-tds stop
fi
if test -x /etc/init.d/c-py-tdn ; then
    echo "Stop c-py-tdn ..."
    /etc/init.d/c-py-tdn stop
fi
if test -x /etc/init.d/tms ; then
    echo "Stop tms ..."
    /etc/init.d/tms stop
fi
echo "Will wait for 20 seconds before kiling process..."
sleep 20
killall -9 c-py-tds c-py-tdn
dpkg -P $packages
apt-get update
apt-get install -y --force-yes $installlist
EOF
    ret=$?
    if [ $ret -ne 0 ] ; then
        echo "[ERROR] remote command execution failed!"
        return $ret
    fi
    # workaround, after apt-get install runs, the scripts returns, don't know why
    ssh -l root -o 'BatchMode=yes' $target <<EOF
echo "Start service ..."
if test -x /etc/init.d/c-py-tds ; then
    echo "Start c-py-tds ..."
    /etc/init.d/c-py-tds start
fi
if test -x /etc/init.d/c-py-tdn ; then
    echo "Start c-py-tdn ..."
    /etc/init.d/c-py-tdn start
fi
if test -x /etc/init.d/tms ; then
    echo "Start tms ..."
    /etc/init.d/tms start
fi
exit
EOF
    # wait the process up, then test the connectivity
    echo "[INFO] Test service connection ..."
    check_alive $target $port $check_disk ${timeout:-300}
}

do_tasks()
{
    for task in `echo $opt_tasks | tr ',' ' '`
    do
        info=(`echo $task | tr ':' ' '`)
        echo "[INFO] Doing task $task ..."
        host=${info[0]}
        component=${info[1]}
        if [ -z "$host" ] ; then
            echo "[ERRPR] Invalid task '$task', Failed!"
            return 1
        fi

        packagename=
        case "$component" in
          tds)
            packagename=ctds-debug-${opt_major_version}
            timeout=120
            port=1180
            check_disk=0
            ;;
          tdn)
            packagename=ctdn-debug-${opt_major_version}
            timeout=600
            port=2001
            check_disk=1
            ;;
          tms)
            packagename="tms-debug-${opt_major_version} manifest-sql-schema-${opt_major_version}"
            timeout=600
            port=2001
            check_disk=1
            ;;
          *)
            echo "[INFO] Nothing to do with '$component' in task '$task', return now."
            return 0
            ;;
        esac
        deploy_packages $host $port $check_disk $packagename || {
            echo "[ERROR] Deploy package Failed!"
            return 1
        }
    done
    return 0
}

load_default_options
parse_options "$@" || exit $?
short_opt_to_long_opt || exit $?
check_option || exit $?
do_tasks || exit $?
