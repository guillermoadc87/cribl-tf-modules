variable "module" {
  description = "The group of services having a common high-level purpose, e.g. `network`, `eks` etc"
  type        = string
}

variable "app" {
  description = "App, e.g. `filemanager`"
  type        = string
}

variable "stage" {
  description = "Stage, e.g. `prod`, `staging`, `dev`, or `test`"
  type        = string
}

variable "delimiter" {
  description = "Delimiter to be used between `app`, `environment`, `stage`, `name` and `attributes`"
  type        = string
  default     = "-"
}

variable "tags" {
  description = "Additional tags (e.g. `map(`BusinessUnit`,`XYZ`)"
  type        = map
  default     = {}
}