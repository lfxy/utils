#!/bin/bash


function usage() {
cat << EOF
Deploy master or nodes.

Usage: deploy [options]

Options:
  -h,--help      Show this help message and exit
  -t,--type=type
                 Deploy type (required)
  -d,--dest=ip
                 Deploy perpose ip list (required)


Examples:

  Deploy to node 10.209.216.20:
    ./deploy_kube.sh -t node -d 10.209.216.20 -m 10.209.216.18

EOF

    return 0
}

function prepare_environment() {
	if [[ "$USER" != "root" ]]; then
        echo "Current user is not root"
        return 1
    fi

	yum update -y
	yum install -y docker
	systemctl restart docker
    cp ./docker /etc/sysconfig/docker
	return 0
}

function deploy_etcd() {
    mkdir -p /var/lib/etcd/default.etcd
    mount --bind /var/lib/etcd/default.etcd /var/lib/etcd/default.etcd
    mount --make-shared /var/lib/etcd/default.etcd

    docker run -d \
        --volume=/var/lib/etcd/default.etcd:/var/lib/etcd/default.etcd:rw \
        --net=host \
        --pid=host \
        --name=etcd \
        10.213.42.254:10500/huangyujun6/etcd-amd64:2.2.5 \
        /usr/local/bin/etcd --name=default --data-dir=/var/lib/etcd/default.etcd

    for loop in 1 2 3
    do
        dockerid=`docker ps -q -f=name=etcd -n=-1`
        etcd_health=`docker exec $dockerid etcdctl cluster-health`
        echo $etcd_health | grep 'cluster is healthy'
        if [ $? -eq 0 ]; then
            echo "deploy_etcd success"
            return 0
        else
            echo "deploy_etcd $loop times, and will retry"
            sleep 2
        fi
    done
    echo "deploy_etcd error"
    return 1
}

function deploy_apiserver() {
    mkdir /var/log/kubernetes
    sudo mount --bind /var/log/kubernetes /var/log/kubernetes
    sudo mount --make-shared /var/log/kubernetes

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
        echo "deploy_apiserver error"
        return 1
    else
        echo "deploy_apiserver success"
        return 0
    fi
}


function deploy_manager_scheduler() {
    docker run -d \
        --volume=/var/log/kubernetes/:/var/log/kubernetes:rw \
        --net=host \
        --pid=host \
        --name=controller-manager \
        10.213.42.254:10500/root/hyperkube:v1.4.5 \
        /hyperkube controller-manager \
        --master=http://localhost:8080 \
        --log-dir=/var/log/kubernetes —v=0

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
    docker rm -f etcd apiserver controller-manager scheduler
    deploy_etcd || exit $?
    deploy_apiserver || exit $?
    deploy_manager_scheduler || exit $?

    return 0
}

function deploy_kubelet() {
	docker run -d \
		--volume=/:/rootfs:ro \
		--volume=/sys:/sys:rw \
		--volume=/var/lib/docker/:/var/lib/docker:rw \
		--volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
		--volume=/var/run:/var/run:rw \
		--net=host \
		--pid=host \
		--privileged \
		--name=kubelet \
		--restart=always \
		10.213.42.254:10500/root/hyperkube:v1.4.5 \
		/hyperkube kubelet \
			--containerized \
            --hostname-override=$node_ip \
			--api-servers=http://$master_ip:8080 \
			--config=/etc/kubernetes/manifests \
			--allow-privileged -v=0

    return 0
}

function deploy_proxy() {
	docker run -d \
		--volume=/:/rootfs:ro \
		--volume=/sys:/sys:rw \
		--volume=/var/lib/docker/:/var/lib/docker:rw \
		--volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
		--volume=/var/run:/var/run:rw \
		--net=host \
		--pid=host \
		--privileged \
		--restart=always \
		--name=proxy \
		10.213.42.254:10500/root/hyperkube:v1.4.5 \
		/hyperkube proxy \
		--master=http://$master_ip:8080 -v=0

    return 0
}

function deploy_node() {
    docker rm -f kubelet proxy
    mkdir -p /var/lib/kubelet
    mount --bind /var/lib/kubelet /var/lib/kubelet
    mount --make-shared /var/lib/kubelet

	deploy_kubelet || exit $?
	deploy_proxy || exit $?

    return 0
}
if [ $# == 0 ]; then
	usage && exit 0
fi

node_ip=""
type="node"
master_ip=""
while getopts ":t:d:m:" opt
do
	case $opt in
		h) 
			usage && exit 0;;
		t) 
            type=$OPTARG;;
		d) 
            node_ip=$OPTARG;;
		m) 
            master_ip=$OPTARG;;
        ?) 
            usage && exit 1
            ;;
	esac
done

if [[ -z "$node_ip" || -z "$master_ip" ]] ; then
    echo "error without node_ip or master_ip" 
fi

echo $type
echo $node_ip
echo $master_ip
prepare_environment || exit 1
if  [ $type = "master" ]; then
    echo "start deploy master..."
    deploy_master
elif  [ $type = "node" ]; then
    echo "start deploy node..."
    deploy_node
fi
