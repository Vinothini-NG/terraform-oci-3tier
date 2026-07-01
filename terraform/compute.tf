#CREATE BASTION HOST
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.E5.Flex"

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_instance" "bastion_host" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "bastion-host-tf-github"
  shape               = "VM.Standard.E5.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 12
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    assign_public_ip = true
    display_name     = "bastion-vnic"
    hostname_label   = "bastionhost"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    }
}

#CREATING APPLICATION NODE1
resource "oci_core_instance" "application_node1" {
  availability_domain = "eaWm:AP-SYDNEY-1-AD-1"
  compartment_id      = var.compartment_ocid
  display_name        = "application-node1-tf-github"
  shape               = "VM.Standard.E5.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 12
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.private_subnet.id
    assign_public_ip       = false
    display_name           = "application-vnic"
    hostname_label         = "appnode1"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    }
}