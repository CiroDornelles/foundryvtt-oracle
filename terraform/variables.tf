variable "tenancy_ocid" {
  description = "O OCID da sua tenancy OCI."
  type        = string
}

variable "user_ocid" {
  description = "O OCID do seu usuário OCI."
  type        = string
}

variable "fingerprint" {
  description = "O fingerprint da sua chave de API OCI."
  type        = string
}

variable "private_key_path" {
  description = "O caminho para a sua chave privada da API OCI."
  type        = string
}

variable "region" {
  description = "A região da OCI para criar os recursos."
  type        = string
}

variable "compartment_ocid" {
  description = "O OCID do compartimento para criar os recursos."
  type        = string
}
