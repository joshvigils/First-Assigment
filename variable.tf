variable "loc" {
    description = "Azure Region"
    default = "eastus"
}
variable "tags" {
    default = {
        source = "terraform-labs"
        env = "training"
    }
}

