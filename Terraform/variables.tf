# variables.tf
variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "root_password" {
  description = "Root password for the droplet"
  type        = string
  sensitive   = true
}
