terraform {
    # Terraformのバージョン指定
    required_version = "~> 1.2.3"
    # AWSプロバイダーのバージョン指定
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.8.0"
        }   
    }
}

# リージョンの指定
provider "aws" {
    region = "ap-northeast-1"
}

variable "env_name" {
    default = "develop"
}

## モジュールへ渡す変数値のサンプル ##
module "vpc" {
    source   = "../../module/vpc"
    env = var.env_name
    # VPCのCIDR
    cidr_vpc = "10.255.0.0/16"
}
