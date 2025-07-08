output "foundry_instance_public_ip" {
  description = "O endereço IP público da instância do Foundry VTT."
  value       = oci_core_instance.foundry_instance.public_ip
}
