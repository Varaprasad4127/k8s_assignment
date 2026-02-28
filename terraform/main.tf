resource "aws_instance" "k8s_node" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = aws_key_pair.test_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_role_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = file("../bash/userdata.sh")
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }
  tags = {
    Name = "terraform-k8s-node-delete-me"
  }
}



resource "aws_security_group" "ec2_sg" {
  name        = "terraform-ec2-sg-delete-me"
  description = "Allow SSH, HTTP, HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["115.98.166.19/32"] # Replace with your IP for secure SSH access
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["115.98.18.104/32"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["115.98.18.104/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-ec2-sg-delete-me"
  }
}

resource "aws_key_pair" "test_key" {
  key_name   = "test_key_pair_delete_me"
  public_key = var.public_key
}


resource "aws_eip" "k8s_node_eip" {
  domain = "vpc"
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "minikube-eip-delete-me"
  }
}

resource "aws_eip_association" "eip_association" {
  instance_id   = aws_instance.k8s_node.id
  allocation_id = aws_eip.k8s_node_eip.id
}