variable "system" {}
variable "env" {}
variable "cidr_vpc" {}
variable "az" {
    type    = list(string)
    default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}