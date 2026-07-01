resource "null_resource" "bastion_to_private_test" {

  depends_on = [
    oci_core_instance.bastion_host,
    oci_core_instance.application_node1
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
      "mkdir -p ~/.ssh",
      "cat > ~/.ssh/private_key <<'EOF'\n${var.ssh_private_key}\nEOF",
      "chmod 600 ~/.ssh/private_key",
      "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'echo CONNECTED && hostname && date && ping -c 3 google.com' > /tmp/connectivity_result.txt 2>&1; echo $? > /tmp/connectivity_exit_code.txt",
    ]
  }
}