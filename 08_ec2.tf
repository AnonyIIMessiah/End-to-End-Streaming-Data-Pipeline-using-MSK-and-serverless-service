# Public EC2 Instance
resource "aws_security_group" "public_ec2_ssh" {
  name        = "public_ec2_ssh"
  description = "public_ec2_ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public_instance" {
  ami                     = "ami-0af9569868786b23a"
  instance_type           = "t2.micro"
  key_name              = "temp-key"
  public_ip               = true
  subnet_id =   aws_subnet.Public-subnet-1.id 
  security_groups = [aws_security_group.public_ec2_ssh.name]
}

# Private EC2 Instance

resource "aws_security_group" "private_ec2" {
  name        = "private_ec2"
  description = "private_ec2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "private_instance" {
  ami                     = "ami-0af9569868786b23a"
  instance_type           = "t2.micro"
  key_name              = "temp-key"
  subnet_id =   aws_subnet.Private-subnet-1.id
  security_groups = [aws_security_group.private_ec2.name]
}