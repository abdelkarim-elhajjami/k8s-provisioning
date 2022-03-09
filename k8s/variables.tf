variable "region" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "private_subnet_netnum"{
    type = string
}

variable "public_subnet_netnum"{
    type = string
}

variable "cluster_name" {
  type = string
}

variable "master_instance_type" {
  type = string
}

variable "worker_instance_type" {
  type = string
}

variable "ami" {
  type = string
}

variable "worker_nodes_max_size" {
  type = number
}

variable "worker_nodes_min_size" {
  type = number
}

variable "ssh_public_key" {
  type = string
}
