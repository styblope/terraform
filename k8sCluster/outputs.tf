output "node_ip_addresses" {
  description = "Configured IPv4 addresses on provisioned nodes"
  value       = [vsphere_virtual_machine.vm_1.*.default_ip_address]
  }

output "cluster_name" {
  value = var.cluster_name
}

output "cluster_config" {
  value = base64encode(local.kubeconfig)
}

output "cluster_certificate_authority" {
  #value = base64encode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  value = base64encode("TODO")
}

output "cluster_endpoint" {
  value = local.server
}

# TODO
locals {
  server = "https://${vsphere_virtual_machine.vm_1[0].default_ip_address}:6443" 
  kubeconfig = <<KUBECONFIG
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    certificate-authority-data: 
    server: ${local.server}
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    user: kubernetes-admin
  name: 
current-context: ${var.cluster_name}
users:
- name: kubernetes-admin
  user:
    client-certificate-data:
    client-key-data:
KUBECONFIG
}

