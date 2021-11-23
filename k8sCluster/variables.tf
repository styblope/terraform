# vsphere variables
variable "allow_unverified_ssl" {
  description = "Communication with vsphere server with self signed certificate"
  default     = "true"
}

variable "vcenter_host" {
  description = "vCenter host"
  default = ""
}

variable "vcenter_user" {
  description = "vCenter user name"
  default = ""
}

variable "vcenter_password" {
  description = "vCenter user password"
  default = ""
}

# virtual machine variables
variable "vm_1_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "vm_1_domain" {
  description = "Domain Name of virtual machine"
}

variable "vm_1_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default     = "2"
}

variable "vm_1_name" {
  type        = string
  description = "Generated"
  default     = "vm_1"
}

variable "vm_1_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default     = "2048"
}

variable "vm_1_cluster" {
  description = "Target vSphere cluster to host the virtual machine"
  default = ""
}

variable "vm_1_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine. Leave empty for default resource pool"
  default = ""
}

variable "vm_1_dns_suffixes" {
  type        = list(string)
  description = "Name resolution suffixes for the virtual network adapter"
  default = []
}

variable "vm_1_dns_servers" {
  type        = list(string)
  description = "DNS servers for the virtual network adapter"
  default = []
}

variable "vm_1_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "vm_1_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
  default = ""
}

variable "vm_1_ipv4_address" {
  description = "Starting IPv4 address for vNIC configuration. If left blank, DHCP is used. "
  default = ""
}

variable "vm_1_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
  default = "32"
}

variable "vm_1_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default     = "vmxnet3"
}

variable "vm_1_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "vm_1_root_disk_type" {
  type        = string
  description = "Type of template disk volume"
  default     = "eager_zeroed"
}

variable "vm_1_root_disk_controller_type" {
  type        = string
  description = "Type of template disk controller"
  default     = "scsi"
}

variable "vm_1_root_disk_keep_on_remove" {
  type        = string
  description = "Delete template disk volume when the virtual machine is deleted"
  default     = "false"
}

variable "vm_1_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default     = "20"
}

variable "vm_1_image" {
  description = "Operating system image name / template that should be used when creating the virtual image"
}

variable "vm_1_proxy" {
  description = "HTTP proxy url, e.g. http://proxy:3128"
  default = ""
  }

# ssh connection variables
variable "vm_os_user" {
  description = "SSH user"
  default = "root"
  }

variable "vm_os_password" {
  description = "SSH user password"
  }

# kubernetes cluster variables
variable "node_count" {
  description = "Number of provisioned virtual machines in the cluster"
  default = "3"
}

variable "cluster_name" {
  description = "Kubernetes cluster id"
  default     = "mycluster"
}

