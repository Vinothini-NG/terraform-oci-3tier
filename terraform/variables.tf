variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "compartment_ocid" {}
variable "fingerprint" {}
variable "private_key" {
  sensitive = true
}
variable "region" {}
variable "ssh_public_key" {
  description = "SSH public key for Bastion Host"
  type        = string
}
variable "ssh_private_key" {
  description = "SSH private key"
  type        = string
  sensitive   = true
}