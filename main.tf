provider "aws" {
  region     = "${var.aws_region}"
}

data "aws_ami" "centos7" {
  most_recent = true
  filter {
    name   = "name"
    values = ["CentOS Linux 7*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["679593333241"] # Canonical
}



resource "aws_subnet" "dcos-prv" {
  count             = "${length(var.private_subnet_azs)}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${lookup(var.private_subnet_azs[count.index], "cidr")}"
  availability_zone = "${var.aws_region}${lookup(var.private_subnet_azs[count.index], "zone")}"
  tags {
    Name = "DCOS Prv ${upper(lookup(var.private_subnet_azs[count.index], "zone"))}"
  }
}

resource "aws_subnet" "dcos-pub" {
  count             = "${length(var.public_subnet_azs)}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${lookup(var.public_subnet_azs[count.index], "cidr")}"
  availability_zone = "${var.aws_region}${lookup(var.public_subnet_azs[count.index], "zone")}"
  tags {
    Name = "DCOS Pub ${upper(lookup(var.public_subnet_azs[count.index], "zone"))}"
  }
}

resource "aws_instance" "dcos-slave" {
    count                         = 1
    ami                           = "${data.aws_ami.centos7.id}"
    instance_type                 = "m5.large"
    vpc_security_group_ids        = ["sg-58523722"]
    subnet_id                     = "${element(aws_subnet.dcos-prv.*.id, count.index)}"
    associate_public_ip_address   = "false"
    key_name                      = "DevOps"
    iam_instance_profile          = "DCOS"
    user_data                     = "${file("./user-data.yml")}"
    tags {
        Name = "testing"
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
        command = "ansible-playbook -u ${var.ssh_user} -i '${self.private_ip},' --private-key ${var.ssh_key_private_file} provision.yml" 
    }
}