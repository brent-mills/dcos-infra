variable "ssh_user" {
	description	= "The user for connecting to an instance"
	default		= "devops"
}

variable "ssh_key_private_file" {
	description = "The location for the private key for the ssh user"
	default = "~/.ssh/qa.key"
}