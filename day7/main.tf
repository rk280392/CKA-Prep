data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostname
  tags = {
    "Name" = "${var.vpc_tag_name}",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


resource "aws_subnet" "vpc_subnet" {
  count = var.subnet_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "Terraform eks test"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "int_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "Terraform eks test"
  }
}

resource "aws_route_table" "rt_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.route_cidr  
    gateway_id = aws_internet_gateway.int_gateway.id
  }
}

resource "aws_route_table_association" "rt_assoc" {
  count = var.subnet_count
  subnet_id = aws_subnet.vpc_subnet.*.id[count.index]
  route_table_id = aws_route_table.rt_table.id
}

resource "aws_iam_role" "eks-tf-role-node" {
  name = var.cluster_name
  assume_role_policy = <<POLICY
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "tf-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks-tf-role-node.name
}

resource "aws_iam_role_policy_attachment" "tf-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.eks-tf-role-node.name
}

resource "aws_security_group" "eks-tf-security-gp" {
  name = "${var.cluster_name}-sg"
  description = "Cluster communication with worker nodes"
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags = {
    "Name" = "Terraform-EKS-testing"
  }
}

resource "aws_security_group_rule" "eks-tf-sg-rule" {
  cidr_blocks = [var.sg-rule-cidr]
  description = "Allow workstation to communicate with the cluster API Server"
  from_port = var.sg-rule-from-port
  protocol = "tcp"
  security_group_id = aws_security_group.eks-tf-security-gp.id
  to_port = var.sg-rule-to-port
  type = "ingress"
}

resource "aws_eks_cluster" "eks-cluster" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks-tf-role-node.arn

  vpc_config {
    security_group_ids = [aws_security_group.eks-tf-security-gp.id]
    subnet_ids = aws_subnet.vpc_subnet.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.tf-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.tf-AmazonEKSServicePolicy,
  ]
}

locals {
  kubeconfig = <<KUBECONFIG

apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks-cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks-cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster_name}"
KUBECONFIG
}

output "kubeconfig" {
  value = local.kubeconfig
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks-tf-role-node.name
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.eks-tf-role-node.name
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks-tf-role-node.name
}

resource "aws_iam_instance_profile" "eks-node" {
  name = "terraform-eks"
  role = aws_iam_role.eks-tf-role-node.name
}

resource "aws_security_group" "eks-node-sg" {
  name = var.aws_iam_ip 
  description = "Security group for all nodes in the cluster"
  vpc_id = aws_vpc.vpc.id 
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
     "Name" = "terraform-eks-demo-node"
   }
}

resource "aws_security_group_rule" "eks-node-ingress-self" {
  description = "Allow node to communicate with each other"
  from_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.eks-node-sg.id
  source_security_group_id = aws_security_group.eks-node-sg.id
  to_port = 65535
  type = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-cluster" {
  description = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port = 1025
  protocol = "tcp"
  security_group_id = aws_security_group.eks-node-sg.id
  source_security_group_id = aws_security_group.eks-tf-security-gp.id
  to_port = 65535
  type = "ingress"
}

resource "aws_security_group_rule" "demo-cluster-ingress-node-https" {
  description = "Allow pods to communicate with the cluster API Server"
  from_port = 443
  protocol = "tcp"
  security_group_id = aws_security_group.eks-node-sg.id
  source_security_group_id = aws_security_group.eks-tf-security-gp.id
  to_port = 443
  type = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name = "name"
    values = [
      "amazon-eks-node-${aws_eks_cluster.eks-cluster.version}-v*"]
  }

  most_recent = true
  owners = [
    "602401143452"]
}

data "aws_region" "current" {}

locals {
  eks-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-cluster.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

resource "aws_launch_configuration" "demo" {
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.eks-node.name
  image_id = data.aws_ami.eks-worker.id
  instance_type = "m4.large"
  name_prefix = "terraform-eks-demo"
  security_groups = [
    aws_security_group.eks-node-sg.id]
  user_data_base64 = base64encode(local.eks-node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "demo" {
  desired_capacity = 2
  launch_configuration = aws_launch_configuration.demo.id
  max_size = 2
  min_size = 1
  name = "terraform-eks-demo"
  vpc_zone_identifier = aws_subnet.vpc_subnet.*.id

  tag {
    key = "Name"
    value = "terraform-eks"
    propagate_at_launch = true
  }

  tag {
    key = "kubernetes.io/cluster/${var.cluster_name}"
    value = "owned"
    propagate_at_launch = true
  }
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks-tf-role-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}
