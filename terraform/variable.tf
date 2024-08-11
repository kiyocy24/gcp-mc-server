variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "network_tags" {
  type = list(string)
}

variable "server_type" {
  type = string
}

variable "server_version" {
  type = string
}