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

# Variable for Networking
variable "availability_zones" {
  description = "List of AZs use if wanted to manually specify it"
  type        = list
  default     = []
}

variable "cidr" {
  description = "Primary VPC CIDR"
  type        = string
}
