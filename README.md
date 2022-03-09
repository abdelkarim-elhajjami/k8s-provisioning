# k8s-provisioning
Kubernetes cluster provisioning on AWS using Kubeadm and Terraform


**The AMI image**
For this setup to work it is expected to use an AMI that contains the following :
* Docker
* kuebctl
* kubeadm
* kubelet

**DISCLAIMER :** the described setup is NOT recommended for production environments. Kubeadm is used solely for learning purposes. For deploying production-grade Kubernetes clusters on AWS you should consider Amazon EKS or kops.
