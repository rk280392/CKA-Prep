variable "cluster_name" {
  default = "terraform-eks"
  type = string
}

variable "cidr_block" {
  default = "10.0.0.0/16"
  type = string
}

variable "enable_dns_hostname" {
  default = true
  type = bool
}

variable "vpc_tag_name" {
  default = "terraform-eks-test"
  type = string
}

variable "subnet_count" {
  default = 3
  type = number
}

variable "route_cidr" {
  default = "0.0.0.0/0"
  type = string
}

variable "sg-rule-cidr" {
  default = "0.0.0.0/0"
  type = string
}

variable "sg-rule-from-port" {
  default = 443
  type = number
}
variable "sg-rule-to-port" {
  default = 443
  type = number
}

variable "aws_iam_ip" {
  default = "tf-instance-profile"
  type = string
}
