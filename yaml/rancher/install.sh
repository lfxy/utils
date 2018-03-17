#! /bin/bash

docker load -i heapster-amd64.tar 
docker load -i heapster-influxdb.tar
docker load -i k8s-dns-kube-dns-amd64.tar
docker load -i kubernetes-dashboard-amd64.tar
docker load -i tiller.tar
docker load -i heapster-grafana-amd64.tar
docker load -i k8s-dns-dnsmasq-nanny-amd64.tar
docker load -i k8s-dns-sidecar-amd64.tar
docker load -i pause3.tar
