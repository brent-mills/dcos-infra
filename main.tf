provider "aws" {
  region     = "${var.aws_region}"
}

data "aws_ami" "centos7" {
  most_recent = true
  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS ENA 1805_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e*"]
  }
  owners = ["679593333241"] # Canonical
}

resource "null_resource" "subnets" {
  count = "${length(split(",",var.subnets["zones"]))}"
  triggers {
    zone    = "${element(split(",", var.subnets["zones"]), count.index)}"
    prv_cidr  = "${element(split(",", var.subnets["prv_cidrs"]), count.index)}"
    pub_cidr  = "${element(split(",", var.subnets["pub_cidrs"]), count.index)}"
  }
}

resource "aws_subnet" "dcos-prv" {
 count             = "${length(null_resource.subnets.*.triggers.zone)}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(null_resource.subnets.*.triggers.prv_cidr, count.index)}"
  availability_zone = "${var.aws_region}${element(null_resource.subnets.*.triggers.zone, count.index)}"
  tags {
    Name        = "DCOS Prv ${upper(element(null_resource.subnets.*.triggers.zone, count.index))}",
    Cost_Alloc  = "DCOS"
  }
}

resource "aws_subnet" "dcos-pub" {
  count             = "${length(null_resource.subnets.*.triggers.zone)}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(null_resource.subnets.*.triggers.pub_cidr, count.index)}"
  availability_zone = "${var.aws_region}${element(null_resource.subnets.*.triggers.zone, count.index)}"
  tags {
    Name        = "DCOS Pub ${upper(element(null_resource.subnets.*.triggers.zone, count.index))}",
    Cost_Alloc  = "DCOS"
  }
}

resource "aws_lb_target_group" "dcos-master-80" {
  count    = 1
  name     = "DCOS-Master-80"
  port     = 80
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb" "dcos-master" {
  name                      = "DCOS-Master"
  internal                  = true
  load_balancer_type        = "application"
  security_groups           = ["sg-03118bb393f33a162"]
  subnets                   = ["${aws_subnet.dcos-prv.*.id}"]
  tags {
    Cost_Alloc = "DCOS"
  }
}

resource "aws_instance" "dcos-master" {
    count                         = 3
    ami                           = "${data.aws_ami.centos7.id}"
    instance_type                 = "r4.xlarge"
    vpc_security_group_ids        = ["sg-58523722"]
    subnet_id                     = "${element(aws_subnet.dcos-prv.*.id, count.index)}"
    associate_public_ip_address   = "false"
    key_name                      = "DevOps"
    iam_instance_profile          = "DCOS"
    user_data                     = "${file("./user-data.yml")}"
    tags {
        Name        = "DCOS Master ${count.index}",
        Cost_Alloc  = "DCOS"
    }
    root_block_device {
        volume_type = "gp2"
        volume_size = "50"
    }
    provisioner "remote-exec" {
        inline = ["echo connected"]

        connection {
            type        = "ssh"
            user        = "${var.ssh_user}"
            private_key = "${file(var.ssh_key_private_file)}"
        }
    }
    provisioner "local-exec" {
        command = "ansible-playbook -u ${var.ssh_user} -i '${self.private_ip},' --private-key ${var.ssh_key_private_file} --extra-vars 'install_url=${var.install_url}' provision.yml" 
    }
}

resource "aws_instance" "dcos-slave-generic" {
    count                         = 2
    ami                           = "${data.aws_ami.centos7.id}"
    instance_type                 = "m5.4xlarge"
    vpc_security_group_ids        = ["sg-58523722"]
    subnet_id                     = "${element(aws_subnet.dcos-prv.*.id, count.index)}"
    associate_public_ip_address   = "false"
    key_name                      = "DevOps"
    iam_instance_profile          = "DCOS"
    user_data                     = "${file("./user-data.yml")}"
    tags {
        Name        = "DCOS Slave Generic ${count.index}",
        Cost_Alloc  = "DCOS"
    }
    root_block_device {
        volume_type = "gp2"
        volume_size = "50"
    }
    provisioner "remote-exec" {
        inline = ["echo connected"]

        connection {
            type        = "ssh"
            user        = "${var.ssh_user}"
            private_key = "${file(var.ssh_key_private_file)}"
        }
    }
    provisioner "local-exec" {
        command = "ansible-playbook -u ${var.ssh_user} -i '${self.private_ip},' --private-key ${var.ssh_key_private_file} --extra-vars 'install_url=${var.install_url}' provision.yml" 
    }
}