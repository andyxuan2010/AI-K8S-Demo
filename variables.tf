variable "common_tags" {
  type = map(any)
  default = {
    managed_by_terraform = "true"
    terraform_project    = "https://github.com/andyxuan2010/AIonK8sDemo"
    owner_group          = "TBD"
    cost_center          = "TBD"
    technical_contact    = "andyxuan2010@gmail.com"
    tenant_owner         = "andyxuan2010@gmail.com"
    creation_date        = "2023-07-02"
    project              = "azure-k8s-demo"
    region               = "westeurope"
    purpose              = "demo"
    resource_group_name  = "challenge2-rg"
  }
}



variable "location" {
  default     = "westeurope"
  description = "The Azure Region in which all resources in this example should be created."
}

variable "environment" {
  type        = string
  default     = "sbx"
  description = "Environment, the environment name such as 'stg', 'prd', 'dev'"
  validation {
    condition     = var.environment == null ? true : contains(["prod", "nprod", "dev", "test", "sbx", "lab"], var.environment)
    error_message = "Only a valid azure names are expected here such as prod."
  }
}

variable "vm_os_family" {
  type        = string
  default     = "ubuntu"
  description = "Linux distribution family for the tools VM: ubuntu or redhat (RHEL 9)."

  validation {
    condition     = contains(["ubuntu", "redhat"], var.vm_os_family)
    error_message = "vm_os_family must be either 'ubuntu' or 'redhat'."
  }
}

variable "emachine-pub-key" {
  default = <<EOT
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIqfriZJbopqGHXo1gVfxo7LNF7rx+Yq1qSFpLeojDS4DWr/a8v2dpevDf95Xku/BGLZ16eRQFlW4/YFfhpPIy1sYVlaJQVOiALN8sk1R5OuGjLXy2e22SRVgH0LQehHCLwmszjuLhbmDO8qjNnzm0JIYHmv4+VkZ56LI8rTiPozHmKGxgKfhKhV1vh9NzdCnj7Nh/iQWAU82X5UzYU6J6t7Ape1bp4C74yPH3NOcVcV51qKZXiamfM2PfPnU11I+Wd7Ho8l1yvpUUZe0FdSBZtp7oWya+oPy5AXJlfuMCq5WjVUO9LCvpZMsJWQDhocMFuDRiNw4+0G/XnathEiRP root@emachine
EOT
}
variable "vm-pub-key" {
  default = <<EOT
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjoftGI4Wgwc6YHGgbbUfAkMm2k4JQIkMXmlHrs24bnSa+CxNeC4eL7cFWZHgLxn6pBfqRCijsCbLpzUhlIJKMMxv2WB0TtHpezD9oUX1/9K7rC3RB4EcKmZ3vDWSsR4UBn9aVCZkQBnr+hfk39lj+Hk2qAMGloVFD0bM10j1Hhv5uMaT8lcClWK/TCcgKH8NQF3hZDqX8YADCYczvZ7B3hA+xpAZwOOZKChOv5Y2ABduD8KPcV6Uc1VLO6+xMlkDZc0MB6HkYlGZSbeMkstgPo+275SKHWVJ7B2nWMvOAyOtjU5OqHwYoNrsCX1TP380DUhQqqAqjzqDP8C0z76Gj root@vm
EOT
}


