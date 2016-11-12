#/usr/bin

cd /etc/sysconfig/network-scripts/
if [ $# == 0 ]; then
    echo "change to comp env"
    mv ifcfg-enp0s3 home-ifcfg-enp0s3
    mv comp-ifcfg-enp0s3 ifcfg-enp0s3
elif [ "$1" == "home" ]; then
    echo "change to home env"
    mv ifcfg-enp0s3 comp-ifcfg-enp0s3
    mv home-ifcfg-enp0s3 ifcfg-enp0s3
else
    echo "change to comp env"
    mv ifcfg-enp0s3 home-ifcfg-enp0s3
    mv comp-ifcfg-enp0s3 ifcfg-enp0s3
fi
