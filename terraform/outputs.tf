output "load_balancer_public_ip" {
  value = oci_load_balancer_load_balancer.load_balancer_tf.ip_address_details[0].ip_address
}

output "wallet_par_url" {
  value = "https://objectstorage.ap-sydney-1.oraclecloud.com${oci_objectstorage_preauthrequest.wallet_par.access_uri}"
}