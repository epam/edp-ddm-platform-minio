resource "vsphere_virtual_disk" "virtual_disk" {
  size               = var.vsphere_minio_volume_size
  type               = "thin"
  vmdk_path          = "${var.vsphere_folder}-platform-minio/${var.cluster_name}-platform-minio-volume.vmdk"
  create_directories = true
  datacenter         = data.vsphere_datacenter.dc.name
  datastore          = data.vsphere_datastore.datastore.name
}

resource "vsphere_virtual_machine" "vm" {
  name                       = "${var.cluster_name}-platform-minio"
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  folder                     = "${var.vsphere_datacenter}/vm/${var.vsphere_folder}"
  num_cpus                   = 4
  memory                     = 8192
  guest_id                   = data.vsphere_virtual_machine.template.guest_id
  wait_for_guest_net_timeout = -1
  scsi_type                  = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    unit_number      = 0
    label            = "disk0"
    size             = var.vsphere_minio_volume_os_size
    thin_provisioned = true
  }

  disk {
    attach       = true
    unit_number  = 1
    label        = "disk1"
    path         = vsphere_virtual_disk.virtual_disk.vmdk_path
    datastore_id = data.vsphere_datastore.datastore.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "${var.cluster_name}-platform-minio"
        domain    = var.baseDomain
      }

      network_interface {
        ipv4_address = var.vsphere_minio_instance_ip
        ipv4_netmask = 24
      }

      ipv4_gateway = var.vsphere_network_gateway
    }
  }
}

resource "null_resource" "minio_userdata" {
  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    type        = "ssh"
    user        = "mdtuddm"
    private_key = "${file("./packer/private.key")}"
    host        = var.vsphere_minio_instance_ip
  }

  provisioner "file" {
    source      = "./scripts/userdata.sh"
    destination = "/tmp/userdata.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export minio_root_password=${random_password.password.result}",
      "export minio_root_user=${var.minio_root_user}",
      "export minio_url=${var.minio_url}",
      "export minio_volume_path=${var.minio_volume_path}",
      "export minio_local_mount_path=${var.minio_local_mount_path}",
      "export bucket_name=${var.backup_bucket_name}",
      "chmod +x /tmp/userdata.sh",
      "sudo -E /tmp/userdata.sh"
    ]
  }

  depends_on = [vsphere_virtual_machine.vm]
}

resource "null_resource" "minio_init" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command     = var.wait_for_cluster_cmd
    interpreter = var.wait_for_cluster_interpreter
    environment = {
      ENDPOINT = "http://${var.vsphere_minio_instance_ip}:9001"
    }
  }
  depends_on = [null_resource.minio_userdata]
}
