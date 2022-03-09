resource "aws_security_group" "bastion" {
  name        = "bastion_sg"
  description = "Allow required traffic to the bastion server"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "SSH from outside"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bastion_sg"
  }
}

resource "aws_security_group" "k8s_workers" {
  name        = "k8s_workers_sg"
  description = "K8s worker nodes security group"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                                        = "k8s_workers_sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group" "k8s_master" {
  name        = "k8s_master_sg"
  description = "Master node security group"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name                                        = "k8s_master_sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}
resource "aws_security_group_rule" "api_traffic_from_lb" {
  type              = "ingress"
  description       = "API traffic from the load balancer is allowed"
  from_port         = 6443
  to_port           = 6443
  protocol          = "TCP"
  security_group_id = aws_security_group.k8s_master.id
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "traffic_from_workers_to_the_master" {
  type                     = "ingress"
  description              = "Traffic from the worker nodes to the master is allowed"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.k8s_master.id
  source_security_group_id = aws_security_group.k8s_workers.id
}
resource "aws_security_group_rule" "traffic_from_bastion_to_the_master" {
  type                     = "ingress"
  description              = "Traffic from the bastion node to the master node is allowed"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  security_group_id        = aws_security_group.k8s_master.id
  source_security_group_id = aws_security_group.bastion.id
}
resource "aws_security_group_rule" "master_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_master.id
}