# Rede Virtual Cloud (VCN)
resource "oci_core_vcn" "foundry_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "foundry-vcn"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "foundryvcn"
}

# Gateway de Internet
resource "oci_core_internet_gateway" "foundry_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.foundry_vcn.id
  display_name   = "foundry-igw"
}

# Tabela de Rota para tráfego público
resource "oci_core_route_table" "foundry_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.foundry_vcn.id
  display_name   = "foundry-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.foundry_igw.id
  }
}

# Sub-rede Pública
resource "oci_core_subnet" "foundry_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.foundry_vcn.id
  display_name   = "foundry-public-subnet"
  cidr_block     = "10.0.1.0/24"
  dns_label      = "foundrysubnet"
  route_table_id = oci_core_route_table.foundry_rt.id
  security_list_ids = [oci_core_security_list.foundry_sl.id]
}

# Lista de Segurança para permitir tráfego
resource "oci_core_security_list" "foundry_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.foundry_vcn.id
  display_name   = "foundry-security-list"

  // Permite tráfego SSH de qualquer lugar
  ingress_security_rules {
    protocol  = "6" // TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  // Permite tráfego para o Foundry VTT de qualquer lugar
  ingress_security_rules {
    protocol  = "6" // TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 30000
      max = 30000
    }
  }

  // Permite tráfego HTTP/HTTPS para o Caddy
  ingress_security_rules {
    protocol  = "6" // TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol  = "6" // TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 443
      max = 443
    }
  }

  // Permite todo o tráfego de saída
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

# Busca o primeiro Domínio de Disponibilidade
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

# Busca a imagem mais recente do Ubuntu
data "oci_core_images" "ubuntu_image" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Instância de Computação (VM)
resource "oci_core_instance" "foundry_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "foundry-vtt-server"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.foundry_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_id   = data.oci_core_images.ubuntu_image.images[0].id
    source_type = "image"
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
  }
}
