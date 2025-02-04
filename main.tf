resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "mtc_public_subnet" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_internet_gateway.id
}

resource "aws_route_table_association" "mtc_public_assoc" {
  subnet_id      = aws_subnet.mtc_public_subnet.id
  route_table_id = aws_route_table.mtc_public_rt.id
}

resource "aws_security_group" "mtc_sg" {
  name        = "dev_sg"
  description = "Dev Security Group"
  vpc_id      = aws_vpc.mtc_vpc.id

  # Allow SSH traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.host_public_ip] # Change to restrict IPs for security (IPV4)
    #ipv6_cidr_blocks  = [var.host_public_ip] # Change to restrict IPs for security (IPV6)
  }

  # For restrictive egress, remove the egress block entirely.
  # This will DENY all outbound traffic unless you explicitly allow it.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "mtc_auth" {
  key_name   = "mtckey"
  public_key = file("~/.ssh/mtckey.pub")
}

resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.mtc_auth.id
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  subnet_id              = aws_subnet.mtc_public_subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev_node"
  }

  provisioner "local-exec" {
    # Operating_System_Setting variable
    command = templatefile("./ssh-config/${var.host_os}.tpl", {
      hostname = self.public_ip,
      user     = "ubuntu",
      identityfile = "~/.ssh/mtckey"
    })
    # Operating_System_Setting variable
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }
}

# resource "null_resource" "test" {
#   provisioner "local-exec" {
#     # Operating_System_Setting variable
#     command = templatefile("./ssh-config/${var.host_os}.tpl", {
#       hostname = "123.123.123.123",
#       user     = "ubuntu",
#       identityfile = "~/.ssh/mtckey"
#     })
#     # Operating_System_Setting variable
#     interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
#   }
# }