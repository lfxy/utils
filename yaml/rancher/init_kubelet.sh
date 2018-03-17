#! /bin/bash

kubelet_id=""
while getopts ":i:" opt
do
    case $opt in
        i)
            kubelet_id=$OPTARG
            rm -rf /etc/kubernetes /etc/cni /opt/cni /opt/az /opt/loopback /var/run/calico /var/lib/cni /var/lib/etcd
            docker cp $kubelet_id:/etc/kubernetes /etc/
	    docker cp $kubelet_id:/etc/cni /etc/
	    docker cp $kubelet_id:/opt/cni /opt
	    docker cp $kubelet_id:/opt/az /opt
	    docker cp $kubelet_id:/opt/loopback /opt
	    docker cp $kubelet_id:/var/run/calico /var/run/
	    docker cp $kubelet_id:/var/lib/cni /var/lib/
	    docker cp $kubelet_id:/usr/bin/kubelet /usr/local/bin
	    #docker cp $kubelet_id:/var/lib/etcd /var/lib/etcd
            ;;
        ?)
            echo "error" && exit 1
            ;;
    esac
done
