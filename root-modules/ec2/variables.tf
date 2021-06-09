variable "region" {
  description = "AWS region"
  type        = string
}

variable "app" {
  type = string
}

variable "stage" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "disk_size" {
  description = "Disk size (GiB) to allocate for bastion instances"
  type        = number
  default     = 8
}

variable "public" {
  description = "Make the EC2 publicly accesible or not"
  type        = bool
  default     = true
}

variable "state_bucket" {
  type        = string
}

variable "state_region" {
  type        = string
}

variable "sg_ingress_rules" {
  description = "Ingress rules for the EC2"
  type        = list(map(any))
  default     = []
}

variable "ssh_public_key" {
  description = "SSH public key for worker nodes"
  type        = string
}