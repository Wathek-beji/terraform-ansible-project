terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.11"
    }
  }
}
variable "VM_COUNT" {
  default = 4
  type = number
}

variable "VM_USER" {
  default = "tico"
  type = string
}

variable "VM_HOSTNAME" {
  default = "wathekbeji"
  type = string
}

variable "VM_IMG_URL" {
  default = "/osmedia/CentOS-7-x86_64-GenericCloud.qcow2"
  type = string
}

variable "VM_IMG_FORMAT" {
  default = "qcow2"
  type = string
}

variable "VM_CIDR_RANGE" {
  default = "10.0.0.0/24"
  type = string
}

variable "VM_TASK" {
  default = ["dns", "loadbalancer", "webserver1", "webserver2"]
  type = list(string)
}


# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    VM_USER = var.VM_USER
  }
}


resource "libvirt_pool" "vm" {
  name = "${var.VM_HOSTNAME}_pool"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool"
}

resource "libvirt_volume" "vm" {
  count  = var.VM_COUNT
  name   = "${var.VM_HOSTNAME}-${count.index}_volume.${var.VM_IMG_FORMAT}"
  pool   = libvirt_pool.vm.name
  source = var.VM_IMG_URL
  format = var.VM_IMG_FORMAT
}

resource "libvirt_network" "vm_public_network" {
   name = "${var.VM_HOSTNAME}_network"
   mode = "nat"
   domain = "${var.VM_HOSTNAME}.local"
   addresses = ["${var.VM_CIDR_RANGE}"]
   dhcp {
    enabled = false
   }
   dns {
    enabled = true
   }
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "${var.VM_HOSTNAME}_cloudinit.iso"
  user_data      = data.template_file.user_data.rendered
  pool           = libvirt_pool.vm.name
}

resource "random_string" "vm-name" {
  length = 6
  upper  = false
  number = false
  lower  = true
  special = false
}

resource "libvirt_domain" "vm" {
  count  = var.VM_COUNT
  name   = "${var.VM_HOSTNAME}-${var.VM_TASK[count.index]}"
  memory = "1024"
  vcpu   = 1

  cloudinit = "${libvirt_cloudinit_disk.cloudinit.id}"

  network_interface {
    network_id = "${libvirt_network.vm_public_network.id}"
    #network_id = "6d8e2494-835d-4baf-a14f-3a5c705febcc"
    #network_name = "vm_docker_network"
    network_name = "${libvirt_network.vm_public_network.name}"
    addresses      = ["10.0.0.${count.index+100}"]
  }
  
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = "${libvirt_volume.vm[count.index].id}"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
