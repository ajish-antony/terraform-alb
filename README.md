# ALB & Infrastructure Creation Using Terraform

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

Here is a project with the requirement was to create an Application Load balancer and also an infrastructure for the same. Here there were two domains, consider as "one.example.com and "two.example.com". While browsing these domains as per the host header the traffic should forward into different servers via ALB. The website files are fetched from the central repository GitHub and the database for the application is from Amazon RDS. The infrastructure should be highly available and fault-tolerant. These requirements have been completely deployed using the terraform as IaC in AWS.

The basic overview of the terraform code, as I have customized the environment for this infrastructure. Initially created a VPC with 3 public subnets and  3 private subnets configured via NAT gateway. Then created a security group for the bastion server for accessing the instances, also security groups for the  DB and website.  Next, the database for the website application as mentioned here is RDS, so proceeds with the creation of the same. Then further created Auto scaling groups via Launch Configuration and deployed the instance as per the required count. While launching the instances, I have provided a sample user-data script to fetch both the RDS endpoint and the files from the Github repository. For fetching these details in the user-data, I have managed to create an IAM Role for the instance and RDS with the necessary privileges. To that environment, I have launched the Application Load balancer with the two target groups to distribute the load. Moreover created a host header-based routing that will forward the requests to the right server based on the request Host-header. All these complete infrastructures mentioned have been deployed using terraform as IaC, where the user end needs main custom edits required in "terraform.tfvars" and also can update with necessary user-data changes. A detailed explanation of the project is given below.

## Resources Created

- Amazon VPC (with 3 public Subnets and 3 private Subnet)
- NAT gateway
- Security groups
- RDS
- Launch Configuration
- Auto Scaling Group
- Application Load Balancer (Host-Based Routing)
- Listener Rules
- Target groups
- IAM Role
- EC2 instances

## Features

- Easy to use and customize. Moreover, the whole process is automated makes the job easier
- Better fault tolerance via configured Autoscaling
- IAM Role for the permissions.
- Instance Refresh enables automatic deployments of instances in Auto Scaling Groups
- Host-based Routing forwards the traffic according to the requirements
- VPC configuration can be deployed in any region and will be fetching the available zones in that region automatically using data source AZ.
- Every subnet CIDR block has been calculated automatically using cidrsubnet function

## Prerequisite

- IAM user with necessary privileges
- Basic Knowledge in AWS services and terraform

## Basic Architecture
![
alt_txt
](https://i.ibb.co/2v8jbv5/Untitled-Diagram-4.jpg)

## How It Can Be Configured

#### VPC  Creation

- Initially created the VPC with 6 public subnets for the networking part. In which consisting of 3 public and 3 private subnets. Here subnets will be calculated using the cidrsubnet function and also the availability zones will be fetched automatically by the data source. This makes the complete VPC creation process easy to handle.

```sh
##########################################################
        # Collecting Availability Zones 
##########################################################

data "aws_availability_zones" "az" {
  state = "available"
}

##########################################################
        # VPC Creation 
##########################################################

resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr
  instance_tenancy      = "default"
  enable_dns_support    = "true"
  enable_dns_hostnames  = "true"

  tags                  = {
    Name                = "${var.project}-vpc"
  }
}
```
- Then Proceeds with the creation of IGW, Subntes, Route table, and Route table association. Here I have provided short summary of the code.
```sh
##########################################################
        # Internet GateWay Creation 
##########################################################
resource "aws_internet_gateway" "igw" {
  vpc_id    = aws_vpc.main.id

  tags      = {
    Name    = "${var.project}-igw"
  }
}

##########################################################
        # Public Subnet - Creation
##########################################################
resource "aws_subnet" "public1" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,0)
  availability_zone                 = data.aws_availability_zones.az.names[0]
  map_public_ip_on_launch           = true 
  tags                              = {
    Name                            = "${var.project}-public1"
  }
}

##########################################################
        # Private Subnet - 1
##########################################################

resource "aws_subnet" "private1" {
  vpc_id                            = aws_vpc.main.id
  cidr_block                        = cidrsubnet(var.vpc_cidr,var.subnetcidr,3)
  availability_zone                 = data.aws_availability_zones.az.names[0]
  tags                              = {
    Name                            = "${var.project}-private1"
  }
}

##########################################################
        # Route Table Public Creation
##########################################################
resource "aws_route_table" "route-public" {
  vpc_id            = aws_vpc.main.id
  route {
      cidr_block    = "0.0.0.0/0"
      gateway_id    = aws_internet_gateway.igw.id
  }
  tags = {
      Name          = "${var.project}-public"
  }
  }

########################################################## 
        # Route Table Association Public 
##########################################################
  resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.route-public.id
}
```
- Then proceeds with the creation of a Security Group for the Instances. Here I have configured a security group for the bastion server with access to 22 ports and another security group with access to 80, 443, 3306, and ssh access from the bastion server.

- Bastion Security Group
```sh
resource "aws_security_group" "bastion" {
    
  name_prefix       = "${var.project}-sg--"
  description       = "allows 22"
  vpc_id            = aws_vpc.main.id
  
  ingress {
    
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   
  egress {
    
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
    

  tags = {
    Name = "${var.project}-bastion"
  }
}   
```
- Application Security Group
```sh
resource "aws_security_group" "sg" {
    
  name_prefix       = "${var.project}-sg--"
  description       = "allows 80 443 22"
  vpc_id            = aws_vpc.main.id

  ingress {
    
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [ aws_security_group.bastion.id ]
  }

   ingress {
    
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   
  egress {
    
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
    

  tags               = {
    Name = "${var.project}-sg"
  }


}
```
- RDS has been used in the database for the application. Initially created the RDS for the whole infrastructure. 

```sh
resource "aws_db_instance" "default" {
  engine                      = "mysql"
  engine_version              = "5.7"
  name                        = "mydb"
  username                    = "admin"
  password                    = "admin1234"
  backup_retention_period     = 1
  allow_major_version_upgrade = false
  apply_immediately           = false
  vpc_security_group_ids      = [ aws_security_group.db-sg.id ]
  instance_class              = "db.t2.micro"
  allocated_storage           = 20
  publicly_accessible         = true
  db_subnet_group_name        = aws_db_subnet_group.default.id 
  skip_final_snapshot         = true
  delete_automated_backups    = true
  final_snapshot_identifier   = true
}

resource "aws_db_subnet_group" "default" {
  name       = aws_vpc.main.id
  subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Name = "${var.project}-main"
  }
}
```
- Further to the creation of the two Launch Configurations, Here  It has been created with instance, its volume, and the details of the security group currently created. The life cycle policy has been updated to confirm the creation before the deletion of the resource. Here user-data has been provided for the instance.
Consider the below given as a sample for the user-data, in which it will fetching the files from Github and also updating the RDS endpoint in the application. As per the requirement update the user-data.

```sh
#!/bin/bash

echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
echo "LANG=en_US.utf-8" >> /etc/environment
echo "LC_ALL=en_US.utf-8" >> /etc/environment
service sshd restart

echo "password123" | passwd root --stdin
sed  -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
service sshd restart


yum install httpd  php php-mysqlnd.x86_64 -y
service httpd restart
chkconfig httpd on

sudo mkdir -p /root/.aws
cat <<EOF > /root/.aws/config
[default]
output = json
region = us-east-1
EOF

echo "Health Check" > /var/www/html/check.php

wget https://raw.githubusercontent.com/ajish-antony/sample-website/main/index.php -P /var/www/html/ 2>/dev/null

end=`aws rds describe-db-instances --filters "Name=engine,Values=mysql" --query "*[].[Endpoint.Address]" | grep "[a-z]" | sed 's/[" ]//g'`
sed -i "s/localhost/$end/g" /var/www/html/index.php
```
- With the above mentioned details, further proceeds with the creation of the Launch Configuration for the instanceses. 

- Launch Configuration -1

```sh
resource "aws_launch_configuration" "lc1" {

  name_prefix                   = "${var.project}-lc1--"
  image_id                      = var.ami
  instance_type                 = var.type
  key_name                      = var.key
  associate_public_ip_address   = true
  security_groups               = [ aws_security_group.sg.id ]
  user_data                     = file("userdata.sh")
  root_block_device            {
  volume_type                   = "gp2"
  volume_size                   = var.vol_size
  }
  iam_instance_profile          = "terraform"

  lifecycle                         {
    create_before_destroy       = true
  }
}
```

- Launch Configuration -2

```sh
resource "aws_launch_configuration" "lc2" {

  name_prefix                   = "${var.project}-lc2--"
  image_id                      = var.ami
  instance_type                 = var.type
  key_name                      = var.key
  security_groups               = [ aws_security_group.sg.id ]
  user_data                     = file("userdata.sh")
  root_block_device            {
  volume_type                   = "gp2"
  volume_size                   = var.vol_size
  }
  iam_instance_profile          = "terraform"


  lifecycle                         {
    create_before_destroy       = true
  }
}
```
- With the above-created Launch Configuration, move forwards with the creation of Auto scaling groups. It has been configured with ceratin features such as Instance refresh that enables automatic deployments of instances in Auto Scaling Groups (ASGs). Provides with the termination policy as such to delete the oldest instances. Also as above, a life cycle policy has been provided to create before the deletion of the resource.

- Auto-scaling Group - 1

```sh
resource "aws_autoscaling_group" "asg1" {
  name_prefix               = "${var.project}-asg1--"
  launch_configuration      = aws_launch_configuration.lc1.id
  target_group_arns         = [aws_lb_target_group.tg1.arn]
  max_size                  = var.min
  min_size                  = var.max
  desired_capacity          = var.desired
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  vpc_zone_identifier       = [ aws_subnet.public1.id, aws_subnet.public2.id, aws_subnet.public3.id ]
  termination_policies      = [ "OldestInstance" ]
 
  instance_refresh          { 
       strategy              = "Rolling"
        preferences {
      min_healthy_percentage = 50
        }
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project}-01"
    propagate_at_launch = true
  }
  
  lifecycle                         {
    create_before_destroy       = true
  }

  depends_on = [ aws_db_instance.default ]
}
```
- Auto-scaling Group - 2

```sh
resource "aws_autoscaling_group" "asg2" {
  name_prefix               = "${var.project}-asg2--"
  launch_configuration      = aws_launch_configuration.lc2.id
  target_group_arns         = [aws_lb_target_group.tg2.arn]
  max_size                  = var.min
  min_size                  = var.max
  desired_capacity          = var.desired
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  vpc_zone_identifier       = [ aws_subnet.public1.id, aws_subnet.public2.id, aws_subnet.public3.id ]
  termination_policies      = [ "OldestInstance" ]
 
  instance_refresh          { 
       strategy              = "Rolling"
        preferences {
      min_healthy_percentage = 50
        }       
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project}-02"
    propagate_at_launch = true
  }

  lifecycle                         {
    create_before_destroy       = true
  }

  depends_on = [ aws_db_instance.default ]

}
```
- Along with the same bastion server is created for accessing these Instances.

```sh
resource "aws_instance" "bastion" {
  ami                         = var.ami
  instance_type               = var.type
  associate_public_ip_address = true
  availability_zone           = data.aws_availability_zones.az.names[0]
  key_name                    = var.key
  subnet_id                   = aws_subnet.public1.id
  vpc_security_group_ids      = [ aws_security_group.bastion.id ]
  tags                         = {
    Name                      = "${var.project}-bastion"
  }

  root_block_device            {
  volume_type                   = "gp2"
  volume_size                   = var.vol_size
  }
}
```

- Next for the ALB,  target groups are created and the target groups are created with the necessary health checks. Hereafter the creation of the target groups has been updated with the Autoscaling group. 

- Target Group - 1

```sh
resource "aws_lb_target_group" "tg1" {
  name_prefix                   = "tg1-"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = aws_vpc.main.id
  load_balancing_algorithm_type = "round_robin"
  target_type                   = "instance"
  health_check  {
      enabled                   = true
      healthy_threshold         = 2
      unhealthy_threshold       = 2
      interval                  = 60
      matcher                   = 200
       port                      = 80
      protocol                  = "HTTP"
      path                      = "/check.php"
      timeout                   = 50
  }
  stickiness {
    enabled                     = false
    type                        = "lb_cookie"
    cookie_duration             = 120
  }
   
   tags                          = {
    Env                          = "${var.project}-tg1"
  }

}
```

- Target Group - 2

```sh
resource "aws_lb_target_group" "tg2" {
  name_prefix                   = "tg2--"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = aws_vpc.main.id
  load_balancing_algorithm_type = "round_robin"
  target_type                   = "instance"
  health_check  {
      enabled                   = true
      healthy_threshold         = 2
      unhealthy_threshold       = 2
      interval                  = 60
      matcher                   = 200
      port                      = 80
      protocol                  = "HTTP"
      path                      = "/check.php"
      timeout                   = 50
  }
  stickiness {
    enabled                     = false
    type                        = "lb_cookie"
    cookie_duration             = 120
  }
   tags                          = {
    Env                          = "${var.project}-tg2"
  }
}
```
- With these whole details, movies forward with the creation of Application Load balancer. Here it has been created with the listener and the default action.  
```sh
resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id, aws_subnet.public3.id]

  enable_deletion_protection = false

  tags              = {
    Name            = "${var.project}-alb"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
  type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Error"
      status_code  = "200"
    }
}
}
```
- As the requirement was to redirect the traffic based on the host header, here I have configured a routing policy with "host header rule" in the ALB. As per the rule, based on the host header the traffic will be forwarded to the target group-1 and target group-2. 

- First Rule to forward the connection towards the domain, consider as an example:- one.example.com
```sh
resource "aws_lb_listener_rule" "host_based_weighted_routing-1" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
  }

  condition {
    host_header {
      values = [var.domain1]
    }
  }
}
```
- Second Rule to forward the connection towards the other domain, consider as an example:- two.example.com
 
```sh
resource "aws_lb_listener_rule" "host_based_weighted_routing-2" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg2.arn
  }

  condition {
    host_header {
      values = [var.domain2]
    }
  }
}
```
- At the same time for fetching of these details, necessary permissions are required. In that case, provided with the IAM Role has been provided with the policy attached for both the EC2 and RDS.

- IAM Role Creation

```sh
resource "aws_iam_role" "terraform_role" {
  name = "terraform_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
```
- IAM Role Attachhment 
```sh
resource "aws_iam_instance_profile" "terraform_profile" {
  name = "terraform_profile"
  role = "${aws_iam_role.terraform_role.name}"
}
```
- Policy

```sh
resource "aws_iam_role_policy" "terraform_policy" {
  name = "terraform"
  role = "${aws_iam_role.terraform_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "terraform_policy2" {
  name = "terraform2"
  role = "${aws_iam_role.terraform_role.id}"

policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
```

- For the whole, infrastructure certain variables have been created for easy customizations. And the variables have been declared in the file variables.tf.  At the same time, the values for the variables are provided in the terraform.tfvars for user customization. 

- variables.tf
```sh
#################################################
        # Provider & Project Details
#################################################

variable "region"     {}

variable "project"    {}

variable "access_key" {}

variable "secret_key" {}

#################################################
        # VPC Requiremnet
#################################################

variable "vpc_cidr"   {}

variable "subnetcidr" {}

#################################################
        # EC2 Requirement 
#################################################

variable  "ami"      {}

variable  "type"     {}

variable  "vol_size" {}

variable  "key"      {}

#################################################
        # ASG Requirement
#################################################

variable  "min"     {}

variable  "max"     {}

variable  "desired" {}


#################################################
        # Listner Rule 
#################################################

variable "domain1" {}   
variable "domain2" {}    
```
## User Instructions
- Clone the git repo and proceeds with the installation of the terraform if it has not been installed, otherwise ignore this step. Change the permission of the script - install.sh to executable and execute the bash script for the installation. The output is shown below.
-![
alt_txt
](https://i.ibb.co/QbB5dfF/install.jpg)

- For Manual Proccedure 

- For Downloading - [Terraform](https://www.terraform.io/downloads.html) 

- Installation Steps - [Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started)

### User Customisation

- The user needs to update the required values for the variables in the terraform.tfvars to make updations to the whole infrastructure and the userdata according to the requirement. Consider the example values given below. 

```sh
#################################################
        # Provider Details
#################################################
region      = "us-east-1"
access_key  = "Mention-Your-Access-Key"
secret_key  = "Mention-Your-Secret-Key"
#################################################
        # VPC Requirement
#################################################
vpc_cidr    = "172.18.0.0/16"
project     = "ajish"
subnetcidr  = "3"
#################################################
        # EC2 Requirement 
#################################################
ami         = "ami-0c2b8ca1dad447f8a"
type        = "t2.micro"
vol_size    = "8"
key         = "terraform"
#################################################
        # ASG Requirement
#################################################
min         = 2
max         = 2
desired     = 2
```

- After completing these,  initialize the working directory for Terraform configuration using the below command
```sh
terraform init
```
- Validate the terraform file using the command given below.
```sh 
terraform validate
```
- After successful validation, plan the build architecture 
```sh
terraform plan 
```
Confirm the changes and Apply the changes to the AWS architecture
```sh 
terraform apply
```

## Conclusion

Here I have deployed a complex architecture in AWS using the terraform as IaC in a simpler and efficient way. The whole automated process will make the jobs simpler and can be made available to deploy in any region with required fewer custom edits.

### ⚙️ Connect with Me

<p align="center">
<a href="mailto:ajishantony95@gmail.com"><img src="https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white"/></a>
<a href="https://www.linkedin.com/in/ajish-antony/"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white"/></a>
