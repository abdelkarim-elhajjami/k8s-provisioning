provider "aws" {
  region  = "eu-west-3"
}

module "kubernetes" {
  source = "./k8s"
  region = "eu-west-3"
  vpc_cidr_block = "10.25.0.0/16"
  vpc_name = "k8s-vpc"
  private_subnet_netnum = "1"
  public_subnet_netnum = "2"
  cluster_name = "k8s-cluster"
  ami = "# configured AMI w/ Docker kuebctl kubeadm and kubelet"
  master_instance_type = "t3.small"
  worker_instance_type = "t3.small"
  worker_nodes_min_size = 1
  worker_nodes_max_size = 2
  ssh_public_key = "# public SSH key"
}