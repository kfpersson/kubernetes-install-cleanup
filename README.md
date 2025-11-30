# kubernetes-install-cleanup — README

This repository contains a helper script to remove previous Kubernetes/container runtime state and install Kubernetes components on a node.

## Purpose
- Clean old kube/k8s/container runtime state (packages, data directories, iptables rules).
- Install containerd and kubeadm/kubelet/kubectl.
- Initialize a control-plane (master) or join a worker node (using kubeadm join).

## Prerequisites
- Ubuntu 18.04 / 20.04 / 22.04 (tested).
- SSH access or direct console to each node.
- Internet access for apt package downloads.
- Ensure swap is disabled on all nodes (the script will also attempt to disable it).
- Edit host and cluster config files in the config directory if needed:
  - config/hosts.txt
  - config/k8s-config.yaml
- Optional: run the prerequisites script first:
  scripts/prerequisites.sh

## Usage
1. Make the script executable:
   sudo chmod +x install_and_cleanup.sh

2. Initialize the first control-plane (run on the node you choose as first master):
   sudo ./install_and_cleanup.sh --role master [--k8s-version 1.27.0] [--pod-cidr 192.168.0.0/16]

   - The script runs kubeadm init and applies a Flannel CNI manifest by default.
   - It prints a worker join command (kubeadm join ...) — copy this for worker joins.
   - For additional control-plane nodes (HA), follow the kubeadm output and run the control-plane join command (includes --control-plane and --certificate-key).

3. Join worker nodes (run on each worker or via SSH):
   sudo ./install_and_cleanup.sh --role worker --join-cmd "kubeadm join <API:PORT> --token <token> --discovery-token-ca-cert-hash sha256:<hash>"

## Options
- --role master|worker  (required)
- --k8s-version X.Y.Z   (default in script; installs kubeadm/kubelet/kubectl of this version)
- --pod-cidr CIDR       (defaults in script; used during kubeadm init)
- --join-cmd "..."      (required for role=worker)

## Post-install verification
- On the control-plane (after exporting kubeconfig or using $HOME/.kube/config):
  kubectl get nodes
  kubectl get pods -A

## Notes / Caveats
- The script is destructive: it removes /etc/kubernetes, /var/lib/etcd and other runtime data. Back up anything you need before running.
- For production HA with multiple control-planes, use a load-balancer in front of API servers or follow kubeadm HA docs for stacked control-planes.
- The script applies Flannel by default. Replace the CNI manifest in the script if you prefer Calico/Weave/etc.
- Tokens expire; if a token expires, generate a new worker join command on the master:
  sudo kubeadm token create --print-join-command

## Support
- Repo layout / scripts are in: rv-kubernetes/kubernetes-install and rv-kubernetes/multinode-kubernetes
- Contributions are welcome for automated multi-master join or a remote-run wrapper (SSH/parallel).