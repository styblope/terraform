# TODO:
# - folder creation vs permissions
# - define cam json variables
# - passwordless ssh, ssh-key-gen
# - test in CAM
# - output kubeconfig and setup external connection to cluster
# - coredns issues

#########################################################
# vsphere provider 
#########################################################
provider "vsphere" {
  allow_unverified_ssl = var.allow_unverified_ssl
  version              = "~> 1.3, < 1.16.0"
  user                 = var.vcenter_user == "" ? null : var.vcenter_user
  password             = var.vcenter_password == "" ? null : var.vcenter_password
  vsphere_server       = var.vcenter_host == "" ? null : var.vcenter_host
}

data "vsphere_datacenter" "vm_1_datacenter" {
  name = var.vm_1_datacenter
}

data "vsphere_datastore" "vm_1_datastore" {
  name          = var.vm_1_root_disk_datastore
  datacenter_id = data.vsphere_datacenter.vm_1_datacenter.id
}

data "vsphere_compute_cluster" "vm_1_compute_cluster" {
  count         = var.vm_1_cluster == "" ? 0 : 1
  name          = var.vm_1_cluster
  datacenter_id = data.vsphere_datacenter.vm_1_datacenter.id
}

data "vsphere_resource_pool" "vm_1_resource_pool" {
  count         = var.vm_1_resource_pool == "" ? 0 : 1
  name          = var.vm_1_resource_pool
  datacenter_id = data.vsphere_datacenter.vm_1_datacenter.id
}

data "vsphere_network" "vm_1_network" {
  name          = var.vm_1_network_interface_label
  datacenter_id = data.vsphere_datacenter.vm_1_datacenter.id
}

data "vsphere_virtual_machine" "vm_1_template" {
  name          = var.vm_1_image
  datacenter_id = data.vsphere_datacenter.vm_1_datacenter.id
}
#########################################################
# folder resource: folder
#########################################################
resource "vsphere_folder" "folder" {
  path          = "${var.cluster_name}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.vm_1_datacenter.id}"
}

#########################################################
# vm resource: vm_1
#########################################################
locals {
  ip_addr_split = split(".", var.vm_1_ipv4_address)
    }

resource "vsphere_virtual_machine" "vm_1" {
  count            = var.node_count
  name             = "${var.vm_1_name}-${count.index}"
  folder           = var.cluster_name
  num_cpus         = var.vm_1_number_of_vcpu
  memory           = var.vm_1_memory
  resource_pool_id = var.vm_1_cluster != "" ? (var.vm_1_resource_pool == "" ? data.vsphere_compute_cluster.vm_1_compute_cluster[0].resource_pool_id : data.vsphere_resource_pool.vm_1_resource_pool[0].id) : data.vsphere_resource_pool.vm_1_resource_pool[0].id
  datastore_id     = var.vm_1_cluster != "" ? null : data.vsphere_datastore.vm_1_datastore.id
  guest_id         = data.vsphere_virtual_machine.vm_1_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.vm_1_template.scsi_type

  clone {
    template_uuid = data.vsphere_virtual_machine.vm_1_template.id

    customize {
      linux_options {
        domain    = var.vm_1_domain
        host_name = "${var.vm_1_name}-${count.index}"
      }

      network_interface {
        ipv4_address = var.vm_1_ipv4_address == "" ? null : join(".", [local.ip_addr_split[0], local.ip_addr_split[1], local.ip_addr_split[2], local.ip_addr_split[3]+count.index])
        ipv4_netmask = var.vm_1_ipv4_address == "" ? null : var.vm_1_ipv4_prefix_length
      }

      ipv4_gateway    = var.vm_1_ipv4_address == "" ? null : var.vm_1_ipv4_gateway
      dns_suffix_list = var.vm_1_dns_suffixes == "" ? null : var.vm_1_dns_suffixes
      dns_server_list = var.vm_1_dns_servers  == "" ? null : var.vm_1_dns_servers
    }
  }

  network_interface {
    network_id   = data.vsphere_network.vm_1_network.id
    adapter_type = var.vm_1_adapter_type
  }

  disk {
    label          = "${var.vm_1_name}-${count.index}-0.vmdk"
    size           = var.vm_1_root_disk_size
    keep_on_remove = var.vm_1_root_disk_keep_on_remove
    datastore_id   = data.vsphere_datastore.vm_1_datastore.id
  }

# Specify the connection
  connection {
    host        = self.default_ip_address
    type        = "ssh"
    user        = var.vm_os_user
    password    = var.vm_os_password
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "test ${var.vm_1_proxy} && echo 'http_proxy=${var.vm_1_proxy}' >> /etc/environment",
      "test ${var.vm_1_proxy} && echo 'https_proxy=${var.vm_1_proxy}' >> /etc/environment",
      "test ${var.vm_1_proxy} && echo 'no_proxy=localhost,127.0.0.1,127.0.1.1,.${var.vm_1_domain}' >> /etc/environment"
    ]
  }
} # end of vsphere_virtual_machine resource

################################################
# kubespray cluster provisioning on node-0
################################################

resource "null_resource" "master" {
  connection {
    host        = vsphere_virtual_machine.vm_1.0.default_ip_address
    type        = "ssh"
    user        = var.vm_os_user
    password    = var.vm_os_password
    timeout     = "5m"
  }

  # https://github.com/kubernetes-sigs/kubespray
  provisioner "remote-exec" {
    inline = [
      "sudo mount -o remount,size=1G,noatime /tmp # increase /tmp size for kubespray installation",
      "cd && git clone https://github.com/kubernetes-sigs/kubespray.git",
      "cd kubespray",
      "sudo pip3 install -r requirements.txt",
      "cp -rfp inventory/sample inventory/${var.cluster_name}",
      "CONFIG_FILE=inventory/${var.cluster_name}/hosts.yaml python3 contrib/inventory_builder/inventory.py ${join(" ", vsphere_virtual_machine.vm_1.*.default_ip_address)}",
      "GROUP_VARS_ALL_FILE=inventory/${var.cluster_name}/group_vars/all/all.yml",
      "sed -ie 's|^# cloud_provider:.*$|cloud_provider: \"external\"|' $GROUP_VARS_ALL_FILE",
      "sed -ie 's|^# external_cloud_provider:.*$|external_cloud_provider: \"vsphere\"|' $GROUP_VARS_ALL_FILE",
      "test ${var.vm_1_proxy} && sed -ie 's|^# http_proxy:.*$|http_proxy: \"${var.vm_1_proxy}\"|' $GROUP_VARS_ALL_FILE",
      "test ${var.vm_1_proxy} && sed -ie 's|^# https_proxy:.*$|https_proxy: \"${var.vm_1_proxy}\"|' $GROUP_VARS_ALL_FILE",
      "test ${var.vm_1_proxy} && sed -ie 's|^# no_proxy:.*$|no_proxy: \"localhost,127.0.0.1,127.0.1.1,.${var.vm_1_domain}\"|' $GROUP_VARS_ALL_FILE",
      "# test ${var.vm_1_proxy} && sed -ie 's|^# skip_http_proxy_on_os_packages:.*$|skip_http_proxy_on_os_packages: true|' $GROUP_VARS_ALL_FILE",
      "echo 'ansible_ssh_pipelining: true' >> $GROUP_VARS_ALL_FILE",
      "echo 'ansible_ssh_common_args: \"-o ControlMaster=auto -o ControlPersist=60s\"' >> $GROUP_VARS_ALL_FILE",
      "echo 'upstream_dns_servers:' >> $GROUP_VARS_ALL_FILE",
      "echo '  - ${var.vm_1_dns_servers[0]}' >> $GROUP_VARS_ALL_FILE",
      "echo '  - 8.8.8.8' >> $GROUP_VARS_ALL_FILE"
    ]
  }

  provisioner "file" {
    destination = "kubespray/inventory/${var.cluster_name}/group_vars/all/vsphere.yml"
    content = <<EOF
## Values for the external vSphere Cloud Provider
external_vsphere_vcenter_ip: "${var.vcenter_host}"
external_vsphere_vcenter_port: "443"
external_vsphere_insecure: "true"
external_vsphere_user: "${var.vcenter_user}" # Can also be set via the `VSPHERE_USER` environment variable
external_vsphere_password: "${var.vcenter_password}" # Can also be set via the `VSPHERE_PASSWORD` environment variable
external_vsphere_datacenter: "${var.vm_1_datacenter}"
external_vsphere_kubernetes_cluster_id: "${var.cluster_name}"
EOF
  }

  provisioner "remote-exec" {
    # TODO: replace root password with password-less 
    inline = [
      "cd ~/kubespray",
      "ansible-playbook -i inventory/${var.cluster_name}/hosts.yaml  --become --become-user=root --extra-vars \"ansible_ssh_pass=${var.vm_os_password}\" cluster.yml",
      "echo ==========",
      "echo KUBECONFIG",
      "echo ==========",
      "sed -e 's|server: https.*$|server: https://${vsphere_virtual_machine.vm_1[0].default_ip_address}:6443|' $HOME/.kube/config'"
    ]
  }
}
