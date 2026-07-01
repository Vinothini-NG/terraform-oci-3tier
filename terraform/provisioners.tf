resource "null_resource" "bastion_to_private_test" {
  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    oci_core_instance.bastion_host,
    oci_core_instance.application_node1
  ]

  connection {
    type        = "ssh"
    user        = "opc"
    private_key = var.ssh_private_key
    host        = oci_core_instance.bastion_host.public_ip
  }

  # Provisioner 1: sensitive ops — output suppressed, expected
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/.ssh",
      "cat > ~/.ssh/private_key <<'EOF'\n${var.ssh_private_key}\nEOF",
      "chmod 600 ~/.ssh/private_key",

      # Connectivity test
      "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'echo CONNECTED && hostname && date' > /tmp/connectivity_result.txt 2>&1; echo $? > /tmp/connectivity_exit_code.txt",

      # httpd install
      "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo yum install -y httpd 2>&1' > /tmp/httpd_install.txt 2>&1; echo $? > /tmp/httpd_install_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo systemctl enable httpd 2>&1' > /tmp/httpd_enable.txt 2>&1; echo $? > /tmp/httpd_enable_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo systemctl start httpd 2>&1' > /tmp/httpd_start.txt 2>&1; echo $? > /tmp/httpd_start_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo firewall-cmd --permanent --add-port=80/tcp 2>&1' > /tmp/httpd_fw1.txt 2>&1; echo $? > /tmp/httpd_fw1_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo firewall-cmd --reload 2>&1' > /tmp/httpd_fw2.txt 2>&1; echo $? > /tmp/httpd_fw2_exit.txt",

      # Edit httpd.conf
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo sed -i \"s|<Directory \\\"/var/www/html\\\">|AddHandler cgi-script .sh\\n<Directory \\\"/var/www/html\\\">|g\" /etc/httpd/conf/httpd.conf' > /tmp/httpd_conf1.txt 2>&1; echo $? > /tmp/httpd_conf1_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo sed -i \"s|Options Indexes FollowSymLinks|Options +ExecCGI|g\" /etc/httpd/conf/httpd.conf' > /tmp/httpd_conf2.txt 2>&1; echo $? > /tmp/httpd_conf2_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo sed -i \"s|DirectoryIndex index.html|DirectoryIndex index.sh|g\" /etc/httpd/conf/httpd.conf' > /tmp/httpd_conf3.txt 2>&1; echo $? > /tmp/httpd_conf3_exit.txt",

      # Disable SELinux
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo sed -i \"s/^SELINUX=enforcing/SELINUX=disabled/\" /etc/selinux/config' > /tmp/selinux_conf.txt 2>&1; echo $? > /tmp/selinux_conf_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo setenforce 0' > /tmp/selinux_enforce.txt 2>&1; echo $? > /tmp/selinux_enforce_exit.txt",

      # Create initial index.sh
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'printf \"#!/bin/sh\\necho Content-type: text/html\\necho\\necho \\\"<html>\\\"\\necho \\\"<head><title>Application</title></head>\\\"\\necho \\\"<body>\\\"\\necho \\\"<p>This application is running on <b><u>\\$(hostname)</u></b>!</p>\\\"\\necho \\\"</body></html>\\\"\\n\" | sudo tee /var/www/html/index.sh' > /tmp/index_sh.txt 2>&1; echo $? > /tmp/index_sh_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo chmod +x /var/www/html/index.sh' > /tmp/chmod.txt 2>&1; echo $? > /tmp/chmod_exit.txt",

      # Restart httpd
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo systemctl restart httpd 2>&1' > /tmp/httpd_restart.txt 2>&1; echo $? > /tmp/httpd_restart_exit.txt",

      # Install Oracle Instant Client repo
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo yum install -y oracle-instantclient-release-el9.x86_64 2>&1' > /tmp/oci_repo.txt 2>&1; echo $? > /tmp/oci_repo_exit.txt",

      # Install Instant Client packages
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo yum install -y oracle-instantclient19.30-basic.x86_64 2>&1' > /tmp/oci_basic.txt 2>&1; echo $? > /tmp/oci_basic_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo yum install -y oracle-instantclient19.30-devel.x86_64 2>&1' > /tmp/oci_devel.txt 2>&1; echo $? > /tmp/oci_devel_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo yum install -y oracle-instantclient19.30-sqlplus.x86_64 2>&1' > /tmp/oci_sqlplus.txt 2>&1; echo $? > /tmp/oci_sqlplus_exit.txt",

      # Verify rpm install
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'rpm -qa | grep oracle-instantclient' > /tmp/oci_verify.txt 2>&1; echo $? > /tmp/oci_verify_exit.txt",

      # Set LD_LIBRARY_PATH
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo sh -c \"echo export LD_LIBRARY_PATH=/usr/lib/oracle/19.30/client64/lib:\\$LD_LIBRARY_PATH >> /etc/bashrc\"' > /tmp/ld_library.txt 2>&1; echo $? > /tmp/ld_library_exit.txt",

      # Oracle library config
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo sh -c \"echo /usr/lib/oracle/19.30/client64/lib/ > /etc/ld.so.conf.d/oracle.conf\"' > /tmp/ld_conf.txt 2>&1; echo $? > /tmp/ld_conf_exit.txt",
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo ldconfig' > /tmp/ldconfig.txt 2>&1; echo $? > /tmp/ldconfig_exit.txt",

      # Check admin directory before wallet
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'ls /usr/lib/oracle/19.30/client64/lib/network/admin' > /tmp/admin_dir.txt 2>&1; echo $? > /tmp/admin_dir_exit.txt",

      # Write wallet content directly via base64 — quoted to be safe
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'echo \"${oci_database_autonomous_database_wallet.adb_wallet.content}\" | base64 -d > /tmp/wallet.zip' > /tmp/wallet_download.txt 2>&1; echo $? > /tmp/wallet_download_exit.txt",

      # Verify downloaded file is actually a zip
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'file /tmp/wallet.zip' > /tmp/wallet_filetype.txt 2>&1; echo $? > /tmp/wallet_filetype_exit.txt",

      # Check file size
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'ls -lh /tmp/wallet.zip' > /tmp/wallet_size.txt 2>&1; echo $? > /tmp/wallet_size_exit.txt",

      # Move wallet
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo mv /tmp/wallet.zip /usr/lib/oracle/19.30/client64/lib/network/admin/' > /tmp/wallet_move.txt 2>&1; echo $? > /tmp/wallet_move_exit.txt",

      # Unzip wallet
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'cd /usr/lib/oracle/19.30/client64/lib/network/admin && sudo unzip -o wallet.zip' > /tmp/wallet_unzip.txt 2>&1; echo $? > /tmp/wallet_unzip_exit.txt",

      # Fix permissions
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo chmod 644 /usr/lib/oracle/19.30/client64/lib/network/admin/*' > /tmp/wallet_chmod.txt 2>&1; echo $? > /tmp/wallet_chmod_exit.txt",

      # Verify wallet files — tnsnames.ora must be present
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'ls -la /usr/lib/oracle/19.30/client64/lib/network/admin/' > /tmp/wallet_verify.txt 2>&1; echo $? > /tmp/wallet_verify_exit.txt",

      # Confirm tnsnames.ora exists — READ THIS OUTPUT to find the real TNS alias
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'cat /usr/lib/oracle/19.30/client64/lib/network/admin/tnsnames.ora' > /tmp/tnsnames.txt 2>&1; echo $? > /tmp/tnsnames_exit.txt",

      # Test sqlplus DB connection
      # NOTE: replace myautonomousdbtfgithub_high below with the REAL alias
      # found in /tmp/tnsnames.txt from your first run before relying on this.
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'export TNS_ADMIN=/usr/lib/oracle/19.30/client64/lib/network/admin && printf \"SELECT PROD_NAME, PROD_DESC FROM SH.PRODUCTS ORDER BY PROD_NAME;\\nEXIT\\n\" | /usr/lib/oracle/19.30/client64/bin/sqlplus -s ADMIN/${var.adb_admin_password}@myautonomousdbtfgithub_high' > /tmp/sqlplus_test.txt 2>&1; echo $? > /tmp/sqlplus_test_exit.txt",

      # Step 1: Write index.sh via Python with placeholder
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo python3 -c \"content=open(\\\"/var/www/html/index.sh\\\",\\\"w\\\");content.write(\\\"#!/bin/sh\\\\necho Content-type: text/html\\\\necho\\\\necho HOSTNAME_LINE\\\\nexport TNS_ADMIN=/usr/lib/oracle/19.30/client64/lib/network/admin\\\\nexport LD_LIBRARY_PATH=/usr/lib/oracle/19.30/client64/lib\\\\n/usr/lib/oracle/19.30/client64/bin/sqlplus -s ADMIN/${var.adb_admin_password}@myautonomousdbtfgithub_high <<EOF\\\\nSET MARKUP HTML ON ENTMAP OFF\\\\nSET FEEDBACK OFF\\\\nSET PAGESIZE 100\\\\nSELECT PROD_NAME, PROD_DESC FROM SH.PRODUCTS ORDER BY PROD_NAME;\\\\nQUIT\\\\nEOF\\\\n\\\");content.close();import os;os.chmod(\\\"/var/www/html/index.sh\\\",0o755)\"' > /tmp/index_sh_db.txt 2>&1; echo $? > /tmp/index_sh_db_exit.txt",

      # Step 2: Replace placeholder with real hostname line via sed
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo sed -i \"s|echo HOSTNAME_LINE|echo \\\"<p>This application is running on <b><u>\\$(hostname)<\\/u><\\/b><\\/p>\\\"|g\" /var/www/html/index.sh' > /tmp/sed_hostname.txt 2>&1; echo $? > /tmp/sed_hostname_exit.txt",

      # Step 3: Verify file contents
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'cat /var/www/html/index.sh' > /tmp/index_sh_verify.txt 2>&1; echo $? > /tmp/index_sh_verify_exit.txt",

      # Give execute permission
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo chmod +x /var/www/html/index.sh' > /tmp/chmod_db.txt 2>&1; echo $? > /tmp/chmod_db_exit.txt",

      # Restart httpd
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo systemctl restart httpd 2>&1' > /tmp/httpd_restart2.txt 2>&1; echo $? > /tmp/httpd_restart2_exit.txt",

      # Test curl localhost
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'curl -s http://localhost:80' > /tmp/curl_test.txt 2>&1; echo $? > /tmp/curl_test_exit.txt"
    ]
  }

  # Provisioner 2: no sensitive vars — fully visible in pipeline
  provisioner "remote-exec" {
    inline = [
      "echo '========================================='",
      "echo '     BASTION CONNECTIVITY TEST RESULT    '",
      "echo '========================================='",
      "hostname",
      "echo 'Target app node IP: ${oci_core_instance.application_node1.private_ip}'",
      "cat /tmp/connectivity_result.txt",
      "echo -n 'SSH Exit Code: '; cat /tmp/connectivity_exit_code.txt",

      "echo ''",
      "echo '========================================='",
      "echo '       HTTPD INSTALLATION RESULTS        '",
      "echo '========================================='",
      "echo '--- [1/5] yum install httpd ---'",
      "cat /tmp/httpd_install.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_install_exit.txt",

      "echo ''",
      "echo '--- [2/5] systemctl enable httpd ---'",
      "cat /tmp/httpd_enable.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_enable_exit.txt",

      "echo ''",
      "echo '--- [3/5] systemctl start httpd ---'",
      "cat /tmp/httpd_start.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_start_exit.txt",

      "echo ''",
      "echo '--- [4/5] firewall-cmd --add-port=80/tcp ---'",
      "cat /tmp/httpd_fw1.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_fw1_exit.txt",

      "echo ''",
      "echo '--- [5/5] firewall-cmd --reload ---'",
      "cat /tmp/httpd_fw2.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_fw2_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '       HTTPD.CONF EDIT RESULTS           '",
      "echo '========================================='",
      "echo '--- [1/3] AddHandler cgi-script .sh ---'",
      "cat /tmp/httpd_conf1.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_conf1_exit.txt",

      "echo ''",
      "echo '--- [2/3] Options +ExecCGI ---'",
      "cat /tmp/httpd_conf2.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_conf2_exit.txt",

      "echo ''",
      "echo '--- [3/3] DirectoryIndex index.sh ---'",
      "cat /tmp/httpd_conf3.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_conf3_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '          SELINUX RESULTS                '",
      "echo '========================================='",
      "echo '--- [1/2] selinux config disabled ---'",
      "cat /tmp/selinux_conf.txt",
      "echo -n 'Exit code: '; cat /tmp/selinux_conf_exit.txt",

      "echo ''",
      "echo '--- [2/2] setenforce 0 ---'",
      "cat /tmp/selinux_enforce.txt",
      "echo -n 'Exit code: '; cat /tmp/selinux_enforce_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '          INDEX.SH RESULTS               '",
      "echo '========================================='",
      "echo '--- create initial index.sh ---'",
      "cat /tmp/index_sh.txt",
      "echo -n 'Exit code: '; cat /tmp/index_sh_exit.txt",

      "echo ''",
      "echo '--- chmod +x index.sh ---'",
      "cat /tmp/chmod.txt",
      "echo -n 'Exit code: '; cat /tmp/chmod_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '         HTTPD RESTART 1 RESULT          '",
      "echo '========================================='",
      "cat /tmp/httpd_restart.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_restart_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '    ORACLE INSTANT CLIENT RESULTS        '",
      "echo '========================================='",
      "echo '--- [1/4] oracle-instantclient-release-el9 repo ---'",
      "cat /tmp/oci_repo.txt",
      "echo -n 'Exit code: '; cat /tmp/oci_repo_exit.txt",

      "echo ''",
      "echo '--- [2/4] oracle-instantclient19.30-basic ---'",
      "cat /tmp/oci_basic.txt",
      "echo -n 'Exit code: '; cat /tmp/oci_basic_exit.txt",

      "echo ''",
      "echo '--- [3/4] oracle-instantclient19.30-devel ---'",
      "cat /tmp/oci_devel.txt",
      "echo -n 'Exit code: '; cat /tmp/oci_devel_exit.txt",

      "echo ''",
      "echo '--- [4/4] oracle-instantclient19.30-sqlplus ---'",
      "cat /tmp/oci_sqlplus.txt",
      "echo -n 'Exit code: '; cat /tmp/oci_sqlplus_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '    ORACLE LIBRARY CONFIG RESULTS        '",
      "echo '========================================='",
      "echo '--- [1/3] LD_LIBRARY_PATH in /etc/bashrc ---'",
      "cat /tmp/ld_library.txt",
      "echo -n 'Exit code: '; cat /tmp/ld_library_exit.txt",

      "echo ''",
      "echo '--- [2/3] /etc/ld.so.conf.d/oracle.conf ---'",
      "cat /tmp/ld_conf.txt",
      "echo -n 'Exit code: '; cat /tmp/ld_conf_exit.txt",

      "echo ''",
      "echo '--- [3/3] ldconfig ---'",
      "cat /tmp/ldconfig.txt",
      "echo -n 'Exit code: '; cat /tmp/ldconfig_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '       WALLET DEPLOYMENT RESULTS         '",
      "echo '========================================='",
      "echo '--- [1/7] wallet write from base64 ---'",
      "cat /tmp/wallet_download.txt",
      "echo -n 'Exit code: '; cat /tmp/wallet_download_exit.txt",

      "echo ''",
      "echo '--- [2/7] wallet file type check ---'",
      "cat /tmp/wallet_filetype.txt",
      "echo -n 'Exit code: '; cat /tmp/wallet_filetype_exit.txt",

      "echo ''",
      "echo '--- [3/7] wallet file size ---'",
      "cat /tmp/wallet_size.txt",
      "echo -n 'Exit code: '; cat /tmp/wallet_size_exit.txt",

      "echo ''",
      "echo '--- [4/7] mv wallet.zip to admin dir ---'",
      "cat /tmp/wallet_move.txt",
      "echo -n 'Exit code: '; cat /tmp/wallet_move_exit.txt",

      "echo ''",
      "echo '--- [5/7] unzip wallet ---'",
      "cat /tmp/wallet_unzip.txt",
      "echo -n 'Exit code: '; cat /tmp/wallet_unzip_exit.txt",

      "echo ''",
      "echo '--- [6/7] chmod 644 wallet files ---'",
      "cat /tmp/wallet_chmod.txt",
      "echo -n 'Exit code: '; cat /tmp/wallet_chmod_exit.txt",

      "echo ''",
      "echo '--- [7/7] verify wallet files ---'",
      "cat /tmp/wallet_verify.txt",
      "echo -n 'Exit code: '; cat /tmp/wallet_verify_exit.txt",

      "echo ''",
      "echo '--- tnsnames.ora contents (find your real alias here) ---'",
      "cat /tmp/tnsnames.txt",
      "echo -n 'Exit code: '; cat /tmp/tnsnames_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '        SQLPLUS CONNECTION TEST          '",
      "echo '========================================='",
      "cat /tmp/sqlplus_test.txt",
      "echo -n 'Exit code: '; cat /tmp/sqlplus_test_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '      DB INDEX.SH DEPLOY RESULTS         '",
      "echo '========================================='",
      "echo '--- replace index.sh with DB version ---'",
      "cat /tmp/index_sh_db.txt",
      "echo -n 'Exit code: '; cat /tmp/index_sh_db_exit.txt",

      "echo ''",
      "echo '--- sed hostname replacement ---'",
      "cat /tmp/sed_hostname.txt",
      "echo -n 'Exit code: '; cat /tmp/sed_hostname_exit.txt",

      "echo ''",
      "echo '--- index.sh final contents ---'",
      "cat /tmp/index_sh_verify.txt",
      "echo -n 'Exit code: '; cat /tmp/index_sh_verify_exit.txt",

      "echo ''",
      "echo '--- chmod +x DB index.sh ---'",
      "cat /tmp/chmod_db.txt",
      "echo -n 'Exit code: '; cat /tmp/chmod_db_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '         HTTPD RESTART 2 RESULT          '",
      "echo '========================================='",
      "cat /tmp/httpd_restart2.txt",
      "echo -n 'Exit code: '; cat /tmp/httpd_restart2_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '           CURL LOCALHOST TEST           '",
      "echo '========================================='",
      "cat /tmp/curl_test.txt",
      "echo -n 'Exit code: '; cat /tmp/curl_test_exit.txt",

      "echo ''",
      "echo '========================================='",
      "echo '           FINAL VERIFICATION            '",
      "echo '========================================='",
      # Confirm httpd is active
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo systemctl is-active httpd && echo HTTPD IS RUNNING || echo HTTPD FAILED TO START' || true",
      # Confirm SELinux is disabled
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'getenforce' || true",
      # Confirm index.sh exists and is executable
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'ls -la /var/www/html/index.sh' || true",
      # Confirm wallet files present including tnsnames.ora
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'ls -la /usr/lib/oracle/19.30/client64/lib/network/admin/' || true",
      # Confirm Oracle packages installed
      "echo '--- Installed Oracle Instant Client packages ---'",
      "cat /tmp/oci_verify.txt",
      # Confirm LD_LIBRARY_PATH set
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'grep LD_LIBRARY_PATH /etc/bashrc' || true",
      # Confirm conf changes are present
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'grep -E \"AddHandler|ExecCGI|DirectoryIndex\" /etc/httpd/conf/httpd.conf' || true",
      "echo '========================================='",
      # Real fail-gate: only this line should actually break the apply
      "ssh -o StrictHostKeyChecking=no -i ~/.ssh/private_key opc@${oci_core_instance.application_node1.private_ip} 'sudo systemctl is-active --quiet httpd'"
    ]
  }
}