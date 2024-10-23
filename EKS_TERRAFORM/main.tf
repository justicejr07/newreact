# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main-igw"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a security group allowing HTTP and SSH traffic
resource "aws_security_group" "allow_http_ssh" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "allow_http_ssh"
  }
}

# Create an EC2 instance
resource "aws_instance" "web_instance" {
  ami                    = "ami-0866a3c8686eaeeba" # Ubuntu AMI
  instance_type         = "t2.micro"
  subnet_id             = aws_subnet.public_subnet.id
  key_name              = "DevOps" # Replace with your own key pair

  # Correctly reference the security group using its resource name
  vpc_security_group_ids = [aws_security_group.allow_http_ssh.id]

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install docker.io -y
    systemctl start docker
    systemctl enable docker
    docker run -d -p 80:80 your-dockerhub-image
  EOF

  tags = {
    Name = "web-server"
  }
}

# Output the public IP address of the instance
output "instance_public_ip" {
  value = aws_instance.web_instance.public_ip
}
