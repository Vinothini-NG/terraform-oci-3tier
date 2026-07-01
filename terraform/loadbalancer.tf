# CREATE LOAD BALANCER
resource "oci_load_balancer_load_balancer" "load_balancer_tf" {
  compartment_id = var.compartment_ocid
  display_name   = "load-balancer-tf-github"
  shape          = "flexible"
  is_private     = false

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }

  subnet_ids = [
    oci_core_subnet.public_subnet.id
  ]
}

# CREATE BACKEND SET
resource "oci_load_balancer_backend_set" "lb_backend_set" {
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer_tf.id
  name             = "lb-backend-set-tf-github"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "HTTP"
    port              = 80
    url_path          = "/"
    return_code       = 200
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
}

# ADD APPLICATION NODE1 AS BACKEND
resource "oci_load_balancer_backend" "lb_backend_node1" {
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer_tf.id
  backendset_name  = oci_load_balancer_backend_set.lb_backend_set.name
  ip_address       = oci_core_instance.application_node1.private_ip
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

# CREATE HTTP LISTENER
resource "oci_load_balancer_listener" "lb_listener_http" {
  load_balancer_id         = oci_load_balancer_load_balancer.load_balancer_tf.id
  name                     = "lb-listener-http-tf"
  default_backend_set_name = oci_load_balancer_backend_set.lb_backend_set.name
  port                     = 80
  protocol                 = "HTTP"

  connection_configuration {
    idle_timeout_in_seconds = 60
  }
}

# OUTPUT LOAD BALANCER PUBLIC IP
output "load_balancer_public_ip" {
  value = oci_load_balancer_load_balancer.load_balancer_tf.ip_address_details[0].ip_address
}