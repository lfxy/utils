#! /bin/bash

PROG=$(basename $0)
short_optstring="c:,h?,T:,m:,n:,t:"
long_optstring=" -l config:,help,release_type:,major_version:,build_number:,target:"
short_long_opt_mapping="c:config,h:help,T:release_type,m:major_version,n:build_number,t:target"

usage()
{
    cat << EOF
Deploy TDN onto target machine

Usage: $PROG [options]

Options:
  -c,--config   The config file to be deployed
  -h,--help     Show this help mesasge and exit
  -T,--relase_type=<RELEASE_TYPE>
                Release type of the package deployed, "debug"(default) (optional)
  -m,--major_version=<MAJOR_VERSION>
                The major version deployed to target machine (required)
  -n,--build_number=<BUILD_NUMBER>
                The build number of the package (required)
                Combined with <MAJOR_VERSION> the package version can be determined
                If not given, read from environment variable \$BUILD_NUMBER
   -t,--target=<Server IP>
                Server Target (required), only one Server IP needed

Examples:
  Deploy TDN 1.6.4-448 to node 192.168.2.79
  $PROG -m 1.6.4 -n 448 -t 192.168.2.79

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
    local parsed_params=$(getopt -n "$PROG" $long_optstring -- "$short_optstring" "$@")
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

    if [ -z "$opt_target" ] ; then
        echo "--target is required!" && return 1
    fi

    if [[ -n "$opt_config" && ! -f "$opt_config" ]] ; then
        echo "invalid $opt_config file!" && return 1
    fi
    return 0

}

get_os_name()
{
    local target=$1
    # only deploy on the debian system, include 5.0 and 6.0
    local os_version=`ssh $target "cat /etc/debian_version"`
    echo $os_version|grep -q '^5\.[0-9]\+' && os_name="lenny"
    echo $os_version|grep -q '^6\.[0-9]\+' && os_name="squeeze"
    echo $os_name
}

install_package()
{
    local target=$1
    local os_name="$(get_os_name $target)"
    local binary="/usr/sbin/c-py-tdn"
    local script="/etc/init.d/c-py-tdn"
    local yaml_file="/etc/triton/ctriton.yml"
    local package="ctdn-debug-${opt_major_version}"

    local full_name
    full_name="${package}=${opt_major_version}.${opt_build_number}-${os_name}1"

    # execute following commands on target machine
    ssh -l root -o 'BatchMode=yes' $target <<EOF
echo "Stop service ..."
if test -x $script ; then
    echo "Stop TDN ..."
    $script stop
else
    killall -9 $binary
fi
dpkg -P $package
rm -f $yaml_file
apt-get update
apt-get install -y --force-yes $full_name
EOF
}

dispatch_ctdn_yml()
{
    local target=$1
    local nodeId=`ssh $target "ip addr"| grep "inet "| grep -v 127.0.0.1| grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"| head -n1| awk '{split($0,a,"." ); print a[4]}'`
    if [[ -n "$opt_config" ]] ; then
        scp "$opt_config" root@$target:/etc/triton/ctriton.yml
        return
    fi
    # deploy default config file on one node
    local tmp_file=`mktemp`
    cat >$tmp_file <<EOF
tdn default:
       hashlists: &tdn_hashlists
         check_interval: 86400
         retry_interval: 86400
         retry_connect_interval: 86400
         enabled: false
         buddy:
            enabled: false
tdn:
    $nodeId:
       iface: eth0
       ip: $target
       port: 2001
       group: 100
       bin:
         bcast:
           enabled: 0
       diskmgr:
         root: /data
       hashlists: *tdn_hashlists
EOF
    scp $tmp_file root@$target:/etc/triton/ctriton.yml
    rm -f $tmp_file

}

start_service()
{
    local target=$1
    local script='/etc/init.d/c-py-tdn'
    ssh -l root -o 'BatchMode=yes' $target <<EOF
echo "Start service ..."
if test -x $script ; then
    echo "Start TDN ..."
    $script start
else
    echo "[ERROR] Start service on $target Failed!"
fi

exit
EOF
}

check_alive()
{
    local target=$1
    local max_waiting=$2
    local waiting=0
    local is_ready=0
    while true
    do
        alive_disks_cnt=`echo -e "status_disks\n"| nc $target 2001 |grep 'READ_WRITE'| wc -l`
        if [[ $alive_disks_cnt -ge 1 ]]; then
            let is_ready=1
        fi
        if [[ $is_ready -eq 0 ]]; then
            sleep_sec=10
            echo "Will check again after $sleep_sec seconds ..."
            sleep $sleep_sec
            ((waiting+=sleep_sec))
            if [ $waiting -gt $max_waiting ] ; then
                echo "Wait enough long time, break ..."
                return 1
            fi
        else
            echo "Got $alive_disks_cnt disks, good, allons-y"
            echo "check alive OK"
            break
        fi
    done
    return 0
}

deploy_package()
{
    local target=$1
    local timeout=$2

    install_package $target
    ret=$?
    if [ $ret -ne 0 ] ; then
        echo "[ERROR] install package failed!"
        return $ret
    fi

    dispatch_ctdn_yml $target
    ret=$?
    if [ $ret -ne 0 ] ; then
        echo "[ERROR] dispatch yml file failed!"
        return $ret
    fi

    start_service $target
    ret=$?
    if [ $ret -ne 0 ] ; then
        echo "[ERROR] restart service failed!"
        return $ret
    fi

    # wait the process up, then test the connectivity
    echo "[INFO] Test service connection ..."
    check_alive $target $timeout
}

main()
{
    target=$opt_target
    local timeout=120
    deploy_package $target $timeout || {
        echo "[ERROR] Deploy package on $target Failed!"
        return 1
    }
    return 0
}

load_default_options && parse_options "$@" &&
    short_opt_to_long_opt && check_option && main
