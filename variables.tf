# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "datacenter" {
  description = "vSphere data center"
  type        = string
}

variable "cluster" {
  description = "vSphere cluster"
  type        = string
}

variable "datastore" {
  description = "vSphere datastore"
  type        = string
}

variable "network_name" {
  description = "vSphere network name"
  type        = string
}

variable "num_cpus" {
  description = "number of Cpus"
  type        = string
}

variable "memory" {
  description = "RAM"
  type        = string
}

variable "user" {
  description = "Nom de l'utilisateur"
  type        = string
}

variable "ssh_key_public" {
  description = "clé publique ssh"
  type        = string
}

variable "ssh_passwd_user" {
  description = "passwd octopus"
  type        = string
  sensitive   = true
}

variable "ssh_password" {
  description = "password octopus"
  type        = string
  sensitive   = true
}