resource "oci_database_autonomous_database" "autonomous_db_tf" {
  compartment_id = var.compartment_ocid
  display_name   = "autonomous-db-tf-github"
  db_name        = "MYADBTF"
  db_workload    = "OLTP"

  admin_password = var.adb_admin_password
  is_free_tier   = true
}

resource "oci_database_autonomous_database_wallet" "adb_wallet" {
  autonomous_database_id = oci_database_autonomous_database.autonomous_db_tf.id
  password               = var.wallet_password
  base64_encode_content  = true
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "tf_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "terraform-wallet-bucket"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}

resource "oci_objectstorage_object" "wallet_upload" {
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  bucket         = oci_objectstorage_bucket.tf_bucket.name
  object         = "wallet.zip"
  content = base64decode(
    oci_database_autonomous_database_wallet.adb_wallet.content
  )
}

resource "oci_objectstorage_preauthrequest" "wallet_par" {
  namespace    = data.oci_objectstorage_namespace.ns.namespace
  bucket       = oci_objectstorage_bucket.tf_bucket.name
  name         = "wallet-par"
  access_type  = "ObjectRead"
  object_name  = "wallet.zip"
  time_expires = "2030-12-31T23:59:59Z"
}

output "wallet_par_url" {
  value = "https://objectstorage.ap-sydney-1.oraclecloud.com${oci_objectstorage_preauthrequest.wallet_par.access_uri}"
}