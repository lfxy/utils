#!/bin/bash


function usage() {
cat << EOF
Deploy master or nodes.

Usage: $PROG [options]

Options:
  -h,--help      Show this help message and exit
  -t,--type=type
                 Deploy type (required)
  -d,--dest=ip
                 Deploy perpose ip list (required)


Examples:

  Deploy to node 10.209.216.20:
    $PROG -t 10.209.216.20

EOF

    return 0
}


function deploy_etcd() {
    mkdir -p /var/lib/etcd/default.etcd
    mount --bind /var/lib/etcd/default.etcd /var/lib/etcd/default.etcd
    mount --make-shared /var/lib/etcd/default.etcd

    etcd
    docker run -d \
        --volume=/var/lib/etcd/default.etcd:/var/lib/etcd/default.etcd:rw,shared \
        --net=host \
        --pid=host \
        --name=etcd \
        10.213.42.254:10500/huangyujun6/etcd-amd64:2.2.5 \
        /usr/local/bin/etcd --name=default --data-dir=/var/lib/etcd/default.etcd

    dockerid=`docker ps -q -f=name=etcd -n=-1`
    etcd_health=`docker exec $dockerid etcdctl cluster-health`
    ret=1
    [[ $etcd_health =~ "cluster is healthy" ]] && ret=0
    return ret
}

function deploy_apiserver() {
    mkdir /var/log/kubernetes
    sudo mount --bind /var/log/kubernetes /var/log/kubernetes
    sudo mount --make-shared /var/log/kubernetes

    apiserver
    docker run -d \
        --volume=/var/log/kubernetes/:/var/log/kubernetes:rw \
        --net=host \
        --pid=host \
        --name=apiserver \
        10.213.42.254:10500/root/hyperkube:v1.4.5 \
        /hyperkube apiserver \
        --etcd_servers=http://127.0.0.1:2379 \
        --insecure-bind-address=0.0.0.0 \
        --insecure-port=8080 \
            --service-cluster-ip-range=169.169.0.0/16 \
        --service-node-port-range=1-65535 \
        --admission_control=AlwaysAdmit,SecurityContextDeny,NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota \
        --logtostderr=false --log-dir=/var/log/kubernetes —v=0

    apiserver_health=`docker ps -q -f=name=apiserver`
	if [ ${#apiserver_health} -eq 0 ]; then
        return 1
    else
        return 0
    fi
}


function deploy_manager_scheduler() {
    controller-manager
    docker run -d \
        --volume=/var/log/kubernetes/:/var/log/kubernetes:rw \
        --net=host \
        --pid=host \
        --name=controller-manager \
        10.213.42.254:10500/root/hyperkube:v1.4.5 \
        /hyperkube controller-manager \
        --master=http://localhost:8080 \
        --log-dir=/var/log/kubernetes —v=0

    scheduler
    docker run -d \
        --volume=/var/log/kubernetes/:/var/log/kubernetes:rw \
        --net=host \
        --pid=host \
        --name=scheduler \
        10.213.42.254:10500/root/hyperkube:v1.4.5 \
        /hyperkube scheduler \
        --master=http://localhost:8080 \
        --logtostderr=false \
        --log-dir=/var/log/kubernetes —v=0

    return 0
}

function deploy_master() {
    deploy_etcd || exit $?
    deploy_apiserver || exit $?
    deploy_manager_schedul || exit $?

    return 0
}

function deploy_kubelet() {

    return 1
}

function deploy_proxy() {

    return 0
}

function deploy_node() {
#deploy_kubelet || exit $?
#deploy_proxy || exit $?
    deploy_kubelet || echo "1111" 
    deploy_proxy || exit "00000"

    return 0
}
if [ $# == 0 ]; then
	usage && exit 0
fi

ip=""
type="node"
while getopts ":t:d:" opt
do
	case $opt in
		h) 
			usage && exit 0;;
		t) 
            type=$OPTARG;;
		d) 
            ip=$OPTARG;;
        ?) 
            usage && exit 1
            ;;
	esac
done

if test -z ip ; then
    echo "error without ip" 
fi

echo $type
echo $ip
if  [ $type = "master" ]; then
    echo "start deploy master..."
    deploy_master
elif  [ $type = "node" ]; then
    echo "start deploy node..."
    deploy_node
fi
