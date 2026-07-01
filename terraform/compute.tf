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

#CREATE CUSTOM IMAGE FOR APPLICATION NODE1
resource "oci_core_image" "application_node1_custom_image" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.application_node1.id
  display_name   = "application-node1-custom-image-tf-github"

  launch_mode = "NATIVE"

  timeouts {
    create = "60m"
  }
}

#CREATING APPLICATION NODE2 TF
resource "oci_core_instance" "application_node2" {

  compartment_id = var.compartment_ocid
  availability_domain = "eaWm:AP-SYDNEY-1-AD-1"
  display_name = "application-node2-tf-github"
  shape = "VM.Standard.E5.Flex"
  shape_config {
    ocpus         = 1
    memory_in_gbs = 12
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private_subnet.id
    assign_public_ip = false
    display_name     = "app-node2-vnic"
    hostname_label   = "appnode2"
  }

  source_details {
    source_type = "image"

    source_id = oci_core_image.application_node1_custom_image.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    }

  depends_on = [
    oci_core_image.application_node1_custom_image
  ]
}

# ADD APPLICATION NODE2 AS BACKEND
resource "oci_load_balancer_backend" "lb_backend_node2" {
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer_tf.id
  backendset_name  = oci_load_balancer_backend_set.lb_backend_set.name

  ip_address = oci_core_instance.application_node2.private_ip
  port       = 80

  backup  = false
  drain   = false
  offline = false
  weight  = 1
}