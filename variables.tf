variable "aws_region" {
  description = "The region the cluster will be created in"
  default = "us-east-1"
}

variable "vpc_id" {
  description = "Id of the VPC used to create the cluster in"
  default = "vpc-6b86db0c"
}

variable "subnets" {
  description = "List of subnet configs for availability zones"
  default = {
    zones     = "c,d,e",
    prv_cidrs = "172.29.11.0/26,172.29.11.64/26,172.29.11.128/26",
    pub_cidrs = "172.29.10.0/26,172.29.10.64/26,172.29.10.128/26"
  }
}

variable "ssh_user" {
  description = "The user for connecting to an instance"
  default = "devops"
}

variable "ssh_key_private_file" {
  description = "The location for the private key for the ssh user"
  default = "~/.ssh/qa.key"
}