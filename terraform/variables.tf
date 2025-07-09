variable "tenancy_ocid" {
  description = "O OCID da sua tenancy OCI."
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "O OCID do seu usuário OCI."
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "O fingerprint da sua chave de API OCI."
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "O caminho para a sua chave privada da API OCI."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "A região da OCI para criar os recursos."
  type        = string
}

variable "compartment_ocid" {
  description = "O OCID do compartimento para criar os recursos."
  type        = string
  sensitive   = true
}

variable "ssh_public_key_secret_ocid" {
  type        = string
  description = "O OCID do Secret no OCI Vault que contém a chave SSH pública."
  sensitive   = true
}