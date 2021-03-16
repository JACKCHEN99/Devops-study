#!/bin/bash
function ntp_time(){
    echo "echo set time"      
    apt-get update
    apt-get install ntpdate
    ntpdate cn.pool.ntp.org
    if [ $? -ne 0 ];then
        echo "#################set time fails##############"
    else
        echo "#################set time success############"
    fi
}

function set_hostnames(){
    echo "set hostnames"
    hostnamectl set-hostname dev-mul-k8s
    echo "192.168.1.181 dev-mul-k8s" >> /etc/hosts
    echo "set hostname is success"
    echo "set swap"
    s=`cat -n /etc/fstab |grep  swap|awk -F " " '{print $1}'`
    sed -i "$s s/^/#&/" /etc/fstab
    swapoff -a
}

function install_repo(){
    apt-get update && apt-get install -y apt-transport-https
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
    echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    modprobe -- ip_vs
    modprobe -- ip_vs_rr 
    modprobe -- ip_vs_wrr 
    modprobe -- ip_vs_sh 
    modprobe -- nf_conntrack_ipv4
    apt-get install ipvsadm
}

function init_kubeadm(){
    ip=`ifconfig ens160|grep "inet addr:"|awk -F":" '{print $2}'|awk '{print $1}'`
    echo $ip
    kubeadm init --apiserver-advertise-address=$ip --image-repository registry.aliyuncs.com/google_containers --service-cidr=10.1.0.0/16 --pod-network-cidr=10.244.0.0/16
    if [ $? -ne 0 ];then
        echo "####init fails#####"
    else
        echo "#####init success####"
        echo "####copy config files###"
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    fi 
}

function install_net(){
    curl https://docs.projectcalico.org/v3.7/manifests/canal.yaml -O
    kubectl apply -f canal.yaml
}

function install_metrics(){
    echo "visit https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/metrics-server"
    for i in auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml;do  wget -P /root/metrics https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/metrics-server/$i; done
    kubectl apply -f /root/metrics/
}

function install_prom(){
    clone https://github.com/iKubernetes/k8s-prom.git
        kubectl apply -f namespace.yaml
}

#ntp_time
#set_hostnames
#install_repo
#init_kubeadm
#install_net
install_metrics
