provider "aws" {
  region     = "us-east-1"
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

resource "aws_instance" "dcos-slave" {
    ami                           = "${data.aws_ami.centos7.id}"
    instance_type                 = "m5.large"
    vpc_security_group_ids        = ["sg-58523722"]
    subnet_id                     = "subnet-37f7327f"
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