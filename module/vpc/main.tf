# VPCの作成
resource "aws_vpc" "vpc" {
    cidr_block           = var.cidr_vpc
    instance_tenancy     = "default"
    enable_dns_hostnames = true
    tags = {
        Name = "${var.env}-vpc"
    }
}

#####----- Publicサブネット Start -----#####
# IGWの作成
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags   = {
        Name = "${var.env}-igw"
    }
}

# Publicサブネットの作成
# AZは、var.azで記載したものが順に割り当てられる
resource "aws_subnet" "public" {
    count             = length(var.az)
    vpc_id            = aws_vpc.vpc.id
    cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+1)
    availability_zone = var.az[count.index]
    tags = {
        Name = "${var.env}-public_subnet${count.index + 1}"
    }
}

# Public用ルートテーブルの作成
resource "aws_route" "public" {
	route_table_id = aws_route_table.public.id
	gateway_id = aws_internet_gateway.igw.id
	destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${var.env}-public_routetable"
    }
}
resource "aws_route_table_association" "public" {
    count          = length(var.az)
    subnet_id      = element(aws_subnet.public.*.id, count.index)
    route_table_id = aws_route_table.public.id
}
#####----- Publicサブネット END -----#####

#####----- NAT-GW Start -----#####
# ElasticIPの取得（Nat-GW用）
resource "aws_eip" "natgw" {
    count          = length(var.az)
    vpc            = true
}

# Nat-GWの作成
resource "aws_nat_gateway" "natgw" {
    count          = length(var.az)
    allocation_id  = element(aws_eip.natgw.*.id, count.index)
    subnet_id      = element(aws_subnet.public.*.id, count.index)
    tags = {
        Name = "${var.env}-natgw${count.index + 1}"
    }
    depends_on = [aws_internet_gateway.igw,aws_eip.natgw]
}
#####----- NAT-GW END -----#####

#####----- Privateサブネット Start -----#####
# Privateサブネットの作成
# "cidr_private"の個数分のサブネットを作成する
# AZは、リージョン内のものが順に割り当てられる
# Nat-GWを経由してグローバルへのアウトバンド通信の経路を持つ
resource "aws_subnet" "private" {
    count             = length(var.az)
    vpc_id            = aws_vpc.vpc.id
    cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+11)
    availability_zone = var.az[count.index]
    tags = {
        Name = "${var.env}-private_subnet${count.index + 1}"
    }
}


# PrivateSubnet用の[Private]ルートテーブルの作成
# CIDR_Privateの個数分のルートテーブルを作成する（Nat-GWはAZ単位で作成されるので、冗長化対策のため）

# Nat-GWへのルート作成
resource "aws_route" "private" {
    count      = length(var.az)
	route_table_id = element(aws_route_table.private.*.id, count.index)
	gateway_id = element(aws_nat_gateway.natgw.*.id, count.index)
	destination_cidr_block = "0.0.0.0/0"
}
# ルートテーブルの作成
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.vpc.id
    count      = length(var.az)
    tags = {
        Name = "${var.env}-private_routetable${count.index + 1}"
    }
}
# ルートの割り当てPrivate
resource "aws_route_table_association" "private" {
    count          = length(var.az)
    subnet_id      = element(aws_subnet.private.*.id, count.index)
    route_table_id = element(aws_route_table.private.*.id, count.index)
}
#####----- Privateサブネット END -----#####


#####----- dbサブネット Start -----#####
# DBサブネットの作成
resource "aws_subnet" "db" {
    count             = length(var.az)
    vpc_id            = aws_vpc.vpc.id
    cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index+101)
    availability_zone = var.az[count.index]
    tags = {
        Name = "${var.env}-db_subnet${count.index + 1}"
    }
}

resource "aws_route_table" "db" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${var.env}-db_routetable"
    }
}
resource "aws_route_table_association" "db" {
    count          = length(var.az)
    subnet_id      = element(aws_subnet.db.*.id, count.index)
    route_table_id = element(aws_route_table.db.*.id, count.index)
}
#####----- DBサブネット END -----#####