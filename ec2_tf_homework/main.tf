terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "ec2-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["eu-central-1a"]
    public_subnets  = ["10.0.101.0/24"]
}

resource "aws_security_group" "ec2-sg-tf" {
    name = "ec2-sg-tf"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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

module "ec2" {
    source = "terraform-aws-modules/ec2-instance/aws"

    name = "ec2-podinfo-instance"
    ami = "ami-0f7204385566b32d0"
    instance_type = "t2.micro"

    vpc_security_group_ids = [aws_security_group.ec2-sg-tf.id]
    subnet_id = module.vpc.public_subnets[0]

    associate_public_ip_address = true

    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install docker -y
                service docker start
                usermod -a -G docker ec2-user
                chkconfig docker on
                docker pull stefanprodan/podinfo
                docker run -d -p 80:9898 stefanprodan/podinfo
                EOF
}

output "azs" {
    description = "Availability zones"
    value = module.vpc.azs
}

output "vpcid" {
    description = "ID of the created VPC"
    value = module.vpc.vpc_id
}

output "public_ip" {
    description = "Public IP of EC2 instance"
    value = module.ec2.public_ip
}