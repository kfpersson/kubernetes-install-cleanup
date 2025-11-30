#!/bin/bash

set -e

# Function to display usage
usage() {
    echo "Usage: $0 --role master|worker [options]"
    echo "Options:"
    echo "  --k8s-version X.Y.Z   Specify Kubernetes version (default: latest)"
    echo "  --pod-cidr CIDR       Specify Pod CIDR (default: 192.168.0.0/16)"
    echo "  --join-cmd '...'      Join command for worker nodes (required for role=worker)"
    exit 1
}

# Function to cleanup previous installations
cleanup() {
    echo "Cleaning up previous Kubernetes installation..."
    sudo kubeadm reset -f || true
    sudo apt-get purge -y kubelet kubeadm kubectl
    sudo apt-get autoremove -y
    sudo rm -rf /etc/kubernetes /var/lib/etcd /var/lib/kubelet /var/run/kubernetes
    sudo iptables -F
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
}

# Function to install Kubernetes components
install_kubernetes() {
    echo "Installing Kubernetes components..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet="$K8S_VERSION-00" kubeadm="$K8S_VERSION-00" kubectl="$K8S_VERSION-00"
    sudo apt-mark hold kubelet kubeadm kubectl
}

# Parse command line arguments
ROLE=""
K8S_VERSION="1.27.0-00"
POD_CIDR="192.168.0.0/16"
JOIN_CMD=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --role) ROLE="$2"; shift ;;
        --k8s-version) K8S_VERSION="$2"; shift ;;
        --pod-cidr) POD_CIDR="$2"; shift ;;
        --join-cmd) JOIN_CMD="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

if [[ -z "$ROLE" ]]; then
    usage
fi

# Cleanup previous installations
cleanup

# Install Kubernetes components
install_kubernetes

if [[ "$ROLE" == "master" ]]; then
    echo "Initializing Kubernetes control-plane..."
    sudo kubeadm init --pod-network-cidr="$POD_CIDR"
    echo "Applying Flannel CNI..."
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel.yml
    echo "Kubernetes control-plane initialized."
    echo "To start using your cluster, run:"
    echo "  mkdir -p \$HOME/.kube"
    echo "  sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
    echo "  sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
    echo "Join command for worker nodes:"
    kubeadm token create --print-join-command
elif [[ "$ROLE" == "worker" ]]; then
    if [[ -z "$JOIN_CMD" ]]; then
        echo "Join command is required for worker nodes."
        exit 1
    fi
    echo "Joining Kubernetes cluster..."
    eval "$JOIN_CMD"
    echo "Worker node joined the cluster."
else
    echo "Invalid role specified."
    exit 1
fi