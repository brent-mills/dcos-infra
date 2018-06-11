# DCOS-Infra

This Terraform template will bootstrap the infrastructure needed to set up a DCOS cluster.

## Description

This will create new instances using the newest CentOS 7.x AMI and configure the pre-requisites for a DCOS installation.

## Usage

1. Clone the repo.
2. Run 'terraform init' to initialize plugins.
3. Replace values in .template files with valid values and save them without the .template extension.
4. Run 'terraform apply' to create infrastructure.