data "aws_subnets" "eccsubnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.myvpc.id]
  }
}

data "aws_vpc" "myvpc" {
  default = true
}

data "aws_subnets" "albsubnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.myvpc.id]
  }
}