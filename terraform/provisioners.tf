resource "null_resource" "bastion_to_private_test" {

  depends_on = [
    oci_core_instance.bastion_host
  ]

  connection {
    type        = "ssh"
    user        = "opc"
    host        = oci_core_instance.bastion_host.public_ip
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "hostname",
      "whoami",
      "ping -c 1 google.com",
      "mkdir -p ~/.ssh"
    ]
  }
}