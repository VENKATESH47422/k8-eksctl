# DATA BLOCK: Fetch the latest CentOS 8 AMI
data "aws_ami" "centos8" {
  most_recent = true
  owners      = ["973714476881"]  # DevOps practice AMI owner

  filter {
    name   = "name"
    values = ["Centos-8-DevOps-Practice"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# SECURITY GROUP: Allow all inbound and outbound (for lab/demo)
# resource "aws_security_group" "allow_eksctl" {
#   name        = "allow_eksctl"
#   description = "Security group for EKS workstation"
#   vpc_id      = "vpc-xxxxxxxx"  # 🔴 RECOMMENDED: Add this for clarity and to avoid ambiguity
#   tags = {
#     Name = "allow_eksctl"
#   }

  ingress {
    description = "Allow all inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # 🔴 WARNING: This is insecure in production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 INSTANCE: EKS Workstation using terraform-aws-ec2-instance module
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"  # ✅ Good practice: Lock module version

  name           = "workstation-eksctl"
  ami            = data.aws_ami.centos8.id
  instance_type  = "t2.micro"
  key_name       = "user1"  # 🔴 Uncomment and ensure this key pair exists
  subnet_id      = "subnet-089f37245d3204e86"  # 🔴 Replace with valid subnet ID in your region
  vpc_security_group_ids = [aws_security_group.allow_eksctl.id]

  user_data = file("workstation.sh")  # ✅ Ensure this file is in the same folder or provide full path

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
