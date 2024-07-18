# Define authentification configuration
provider "vsphere" {
  # If you use a domain set your login like this "Domain\\User"
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

#### RETRIEVE DATA INFORMATION FROM VCENTER ####

# Retrieve datacenter information from vCenter
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

# Retrieve compute cluster information from vCenter
data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve datastore information from vsphere
data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve network information from vsphere
data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve template information from vsphere
data "vsphere_virtual_machine" "template" {
  name          = "OctopusTemplate"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#### VM CREATION ####

# Generate a random id for the hostname
resource "random_id" "id" {
	  byte_length = 4
}

#Define local variables
locals {
  vm_name    = "Octopus-${random_id.id.hex}"
}

# Define VM parameters
resource "vsphere_virtual_machine" "octopus_node" {
  name             = "${local.vm_name}"
  num_cpus         = var.num_cpus
  memory           = var.memory
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  tags = ["Noeud","Non configuré"]

  # Set network parameters
  network_interface {
    network_id = data.vsphere_network.network.id
  }

  # Use a predefined vmware template as main disk
  disk {
    label = "Octopus.vmdk"
    size = "32"     #A discuter
  }

guest_id = "debian11_64Guest"

# Clone from a template
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

#### ANSIBLE CREATION AND USAGE ####

#Create a local file for Ansible inventory 
resource "local_file" "ansible-inventory" {
  content = templatefile(
    "${path.module}/ansible-inventory.tftpl",
    {
      octopus-ip = vsphere_virtual_machine.octopus_node.default_ip_address
    }
  )
  filename = "${path.module}/ansible/inventory.ini"
  file_permission = "0644"

    #Define SSH Connection
    connection {
      type     = "ssh"
      user     = "${var.user}"
      password = "${var.ssh_password}"
      host     = vsphere_virtual_machine.octopus_node.default_ip_address
    }
  # Define remote-exec provisioner for update VM packages
  provisioner "remote-exec" {
    inline = [
	"sudo -s apt-get upgrade && sudo -s apt-get -qq install python3 -y",
	"mkdir -p ~/.ssh"
]
  }
# Run ansible fil
  provisioner "local-exec" {
    command = "ansible-playbook -i ansible/inventory.ini -u octopus ansible/playbook.yaml"
    }

}

#### ADD VM INFORMATIONS FOR PROMETHEUS ####

# Define connection for add information on prometheus file
resource "null_resource" "prometheus" {
connection {
      type     = "ssh"
      user     = "root"
      password = var.vsphere_password
      host     = "10.255.0.32"
    }

  provisioner "remote-exec" {
    inline = [
	"echo '        -  \"${vsphere_virtual_machine.octopus_node.default_ip_address}:9100\"' >> prometheus/prometheus.yml",
  "docker container restart prometheus"
]
  }
}

#### OUTPUT ####

# Output the IP address of the VM
output "vm_ip" {
  value = vsphere_virtual_machine.octopus_node.default_ip_address
}
# Output the name of the VM
output "vm_name" {
  value = "${local.vm_name}"
}
