#Start with terraform init
#This is an example based on the excercise from this url https://www.youtube.com/watch?v=SLB_c_ayRMo
#I added a policy to enable ssm management
provider "aws" {
    region = "us-east-1"
    profile = "my-aws-profile" #add the name of your aws local profile
}

# 1. Create a VPC
resource "aws_vpc" "test-vpc" {
  cidr_block =  "10.0.0.0/16"
  tags = {
    Name = "terraform-test-vpc"
  }
}

# 2. Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.test-vpc.id

}

# 3. Create Custom route table
resource "aws_route_table" "terraform-test-rt" {
  vpc_id = aws_vpc.test-vpc.id
  depends_on  = [aws_internet_gateway.gw]

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }

  tags = {
    Name = "terraform-test-rt"
  }
}

# 4. Create a Subnet
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "terraform-test-subnet-1"
  }
}

# 5. Associate subnet with route table 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.terraform-test-rt.id
}

# 6. create security group to allow port 22,80,443 from myip
resource "aws_security_group" "allow_myip" {
  name        = "allow_myip"
  description = "Allow specific inbound traffic from my ip"
  vpc_id      = aws_vpc.test-vpc.id
  
  ingress {
      description      = "SSH from vpc"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.test-vpc.cidr_block] 
    }

  ingress {
      description      = "SSH from my IP"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["x.x.x.x/32"] #For testing you can add your public IP <public-ip>/32
    }

  ingress {
      description      = "HTTPS from VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["x.x.x.x/32"] #For testing you can add your public IP <public-ip>/32
    }

  ingress {
      description      = "HTTP from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["x.x.x.x/32"] #For testing you can add your public IP <public-ip>/32
    }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  tags = {
    Name = "allow_traffic_from_my_IP"
  }
}

# 7. Create a network interface with an ip in the subnet that was created on step 4
resource "aws_network_interface" "test-network-int" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"] #you can select any ip address
  security_groups = [aws_security_group.allow_myip.id]

}

# 8. Assign an elastic IP to the network interface created on step 7
resource "aws_eip" "one-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.test-network-int.id
  associate_with_private_ip = "10.0.1.50"
  #EIP depends on the internet gateway so it must be deployed firs, but terraform by default cannot handle that
  depends_on = [aws_internet_gateway.gw, aws_instance.web-server-test]
}

# 9. Create ubuntu server and install/enable apache2
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#Code to add the instance profile
resource "aws_iam_role" "test_role" {
  name = "test_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.test_role.name
}

resource "aws_iam_role_policy" "test_policy" {
    name = "test_policy"
    role = aws_iam_role.test_role.id
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ssm:DescribeAssociation",
                    "ssm:GetDeployablePatchSnapshotForInstance",
                    "ssm:GetDocument",
                    "ssm:DescribeDocument",
                    "ssm:GetManifest",
                    "ssm:GetParameter",
                    "ssm:GetParameters",
                    "ssm:ListAssociations",
                    "ssm:ListInstanceAssociations",
                    "ssm:PutInventory",
                    "ssm:PutComplianceItems",
                    "ssm:PutConfigurePackageResult",
                    "ssm:UpdateAssociationStatus",
                    "ssm:UpdateInstanceAssociationStatus",
                    "ssm:UpdateInstanceInformation"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ssmmessages:CreateControlChannel",
                    "ssmmessages:CreateDataChannel",
                    "ssmmessages:OpenControlChannel",
                    "ssmmessages:OpenDataChannel"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2messages:AcknowledgeMessage",
                    "ec2messages:DeleteMessage",
                    "ec2messages:FailMessage",
                    "ec2messages:GetEndpoint",
                    "ec2messages:GetMessages",
                    "ec2messages:SendReply"
                ],
                "Resource": "*"
            }
        ]
    })
}
#End of the code to add the instance profile


resource "aws_instance" "web-server-test" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  availability_zone = "us-east-1a"
  key_name = "test-key"
  iam_instance_profile = aws_iam_instance_profile.test_profile.name

  network_interface {
    device_index = 0 #this is the first network interface
    network_interface_id = aws_network_interface.test-network-int.id
  }

  user_data = "${file("install_apache.sh")}"

  tags = {
    Name = "web-server-terraform-test"
  }
}