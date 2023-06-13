
// VPC (the network), essentially all of the resources will live
// within here. VPC = Network (kinda)
resource "aws_vpc" "the_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = "dev-vpc"
  }
}

// Subnets are used for faster data transfer between nodes
// as well as an additional layer of security
// 4 Types of subnets...
// Public
// Private
// VPN-only
// Isolated 
resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = aws_vpc.the_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    name = "dev-public"
  }

}

// An internet gateway provides a target for the routing table
// to allow internet traffic to flow within the VPC.
// If VPC is configured with IPv4, it performs the NAT
// (Network Address Translation) auto, IPv6 does not need NAT
resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.the_vpc.id

  tags = {
    name = "dev-igw"
  }

}

// A resource that directs traffic within the VPC
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.the_vpc.id

  tags = {
    name = "dev-route-table"
  }

}

// The "road" between the route table and internet gateway.
// We can see that with would logically need both variables
// to connect them together. 
// "0.0.0.0/0" Allows the subnet to access the internet
// via the internet gateway
resource "aws_route" "my_route" {
  route_table_id         = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_internet_gateway.id

}

// This is creating an association between our subnet
// and our routing table. This can actually happen by default,
// but here we are declaring it explicitly.
resource "aws_route_table_association" "my_route_association" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.my_route_table.id

}


// Security groups are pretty much firewalls. You can create 
// multiple security groups, but the less you have the better.
// Ingress = incoming, Egress = exiting
resource "aws_security_group" "my_sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.the_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

// Resource to locate the local ssh keypair
resource "aws_key_pair" "my_keypair" {
  key_name   = "my_keypair"
  public_key = file("~/.ssh/vpckey.pub")

}

// The acutal EC2 instance. This is the host within the network
// where the acutal work will be performed. Can be loaded up 
// with scripts such as Docker containers to host API or
// databases for storing data
resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.my_keypair.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id              = aws_subnet.my_public_subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    name = "dev node"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/vpckey"
    })

    interpreter = ["bash", "-c"]
  }

}