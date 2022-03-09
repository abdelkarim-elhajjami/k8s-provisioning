resource "aws_key_pair" "sshkey" {
  public_key = var.ssh_public_key
  key_name   = "mysshkey"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.sshkey.key_name
  subnet_id              = aws_subnet.public_subnet.id
  root_block_device {
    volume_size = 20
  }
  tags = {
    Name = "bastion.${var.cluster_name}"
  }
}

resource "aws_lb" "k8s_api" {
  name               = "${var.cluster_name}-api"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]
  tags = {
    KubernetesCluster                           = var.cluster_name
    Name                                        = "${var.cluster_name}-api"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}
resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.k8s_api.arn
  port              = "6443"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.control_plane.arn
  }
}
resource "aws_lb_target_group" "control_plane" {
  name     = "control-plane"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_launch_configuration" "k8s_master_local" {
  name_prefix          = "master.${var.cluster_name}"
  image_id             = var.ami
  instance_type        = var.master_instance_type
  key_name             = aws_key_pair.sshkey.key_name
  iam_instance_profile = aws_iam_instance_profile.k8s_master_instance_profile.id
  security_groups      = [aws_security_group.k8s_master.id]
  user_data            = <<EOT
#!/bin/bash
hostnamectl set-hostname --static "$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)"
EOT
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
}

resource "aws_autoscaling_group" "k8s_master_autoscaling_gp" {
  name                 = "${var.cluster_name}_master"
  launch_configuration = aws_launch_configuration.k8s_master_local.id
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.private_subnet.id]
  target_group_arns    = [aws_lb_target_group.control_plane.arn]

  tags = [{
    key                 = "KubernetesCluster"
    value               = var.cluster_name
    propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "master.${var.cluster_name}"
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/role/master"
      value               = "1"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster_name}"
      value               = "1"
      propagate_at_launch = true
    }
  ]
}

resource "aws_launch_configuration" "k8s_worker_nodes_local" {
  name_prefix          = "workers.${var.cluster_name}."
  image_id             = var.ami
  instance_type        = var.worker_instance_type
  key_name             = aws_key_pair.sshkey.key_name
  iam_instance_profile = aws_iam_instance_profile.k8s_worker_instance_profile.id
  security_groups      = [aws_security_group.k8s_workers.id]
  user_data            = <<EOT
#!/bin/bash
hostnamectl set-hostname --static "$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)"
EOT
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
}
resource "aws_autoscaling_group" "worker_nodes_autoscaling_gp" {
  name                 = "${var.cluster_name}_workers"
  launch_configuration = aws_launch_configuration.k8s_worker_nodes_local.id
  max_size             = var.worker_nodes_max_size
  min_size             = var.worker_nodes_min_size
  vpc_zone_identifier  = [aws_subnet.private_subnet.id]
  tags = [
    {
      key                 = "KubernetesCluster"
      value               = var.cluster_name
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "nodes.${var.cluster_name}"
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/role/node"
      value               = "1"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster_name}"
      value               = "1"
      propagate_at_launch = true
    }
  ]
}