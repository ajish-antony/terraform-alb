# ALB & Infrastructure Creation Using Terraform

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

Here is a project with the requirement was to create an Application Load balancer with certain conditions. Here there were two domains, consider as "one.example.com and "two.example.com". While browsing these domains as per the host header the traffic should split into different servers via ALB. Also, the infrastructure should be highly available and fault-tolerant. These requirements have been completely deployed using the terraform as IaC in AWS

The basic overview of the terraform code, as I have customized the environment for this infrastructure. Initially created a VPC with 3 public subnets and a security group for the infra. Then further created Auto scaling groups via Launch Configuration and deployed the instance as per the required count. In that environment, I have launched the Application Load balancer with the two target groups to distribute the load. Moreover created a host header-based routing that will forward the requests to the right server based on the request Host-header. All these complete infrastructures mentioned have been deployed using terraform as IaC, where the user end needs only custom edits required in "terraform.tfvars" which can be updated easily. A detailed explanation of the project is given below.

## Resources Created

- Amazon VPC (with 3 public Subnets)
- Security groups
- Launch Configuration
- Auto Scaling Group
- Application Load Balancer (Host-Based Routing)
- Listener Rules
- Target groups
- EC2 instances

## Features

- Easy to use and customize. Moreover, the whole process is automated makes the job easier
- Better fault tolerance via configured Autoscaling
- Instance Refresh enables automatic deployments of instances in Auto Scaling Groups
- Host-based Routing forwards the traffic according to the requirements
- VPC configuration can be deployed in any region and will be fetching the available zones in that region automatically using data source AZ.
- Every subnet CIDR block has been calculated automatically using cidrsubnet function

## Prerequisite

- IAM user with necessary privileges
- Knowledge in AWS service includes ALB, Auto Scaling VPC, EC2

## Basic Overview Diagram
![
alt_txt
](https://i.ibb.co/yNvc7bL/Untitled-Diagram-2.jpg)

## How It Can Be Configured

#### VPC  Creation

- Initially created the VPC with 3 public subnets for the networking part. In which subnets will be calculated using the cidrsubnet function and also the availability zones will be fetched automatically by the data source. This makes the complete VPC creation process easy to handle.

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

output "vpc" {
  value = aws_vpc.main.id
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
- Then proceeds with the creation of a Security Group for the Instances. Here I have configured a security group with access to 22, 80, 443

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
    Name = "${var.project}-sg"
  }
}

output "Security_Group" {
  value = aws_security_group.sg.id
}
```
- Further to the creation of the two Launch Configurations, Here  It has been created with instance, its volume, and the details of the security group currently created. The life cycle policy has been updated to confirm the creation before the deletion of the resource. Here user-data has been provided for the instance. Consider the below given as an example for the user-data, in which it will be showing the hostname to identify the change. As per the requirement update the user-data.

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


yum install httpd  php -y
service httpd restart
chkconfig httpd on

cat <<EOF > /var/www/html/index.php
<?php
\$output = shell_exec('echo $HOSTNAME');
echo "<h1><center><pre>\$output</pre></center></h1>";
echo "<h1><center> My Project </center></h1>"
?>
EOF
```

- Launch Configuration -1

```sh
#################################################
        # Launch Configuration - 1 
#################################################
resource "aws_launch_configuration" "lc1" {

  name_prefix                   = "${var.project}-lc1--"
  image_id                      = var.ami
  instance_type                 = var.type
  key_name                      = var.key
  associate_public_ip_address   = true
  security_groups               = [ aws_security_group.sg.id ]
  user_data                     = file("user-data.sh")
  root_block_device            {
  volume_type                   = "gp2"
  volume_size                   = var.vol_size
  }

  lifecycle                         {
    create_before_destroy       = true
  }
}
```

- Launch Configuration -2

```sh
#################################################
        # Launch Configuration - 2
#################################################

resource "aws_launch_configuration" "lc2" {

  name_prefix                   = "${var.project}-lc2--"
  image_id                      = var.ami
  instance_type                 = var.type
  key_name                      = var.key
  associate_public_ip_address   = true
  security_groups               = [ aws_security_group.sg.id ]
  user_data                     = file("user-data.sh")
  root_block_device            {
  volume_type                   = "gp2"
  volume_size                   = var.vol_size
  }

  lifecycle                         {
    create_before_destroy       = true
  }
}
```
- With the above-created Launch Configuration, move forwards with the creation of Auto scaling groups. It has been configured with ceratin features such as Instance refresh that enables automatic deployments of instances in Auto Scaling Groups (ASGs). Provides with the termination policy as such to delete the oldest instances. Also as above, a life cycle policy has been provided to create before the deletion of the resource.

- Auto-scaling Group - 1

```sh
#################################################
        # Auto Scaling Group - 1
#################################################

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
}
```
- Auto-scaling Group - 2

```sh
#################################################
        # Auto Scaling Group - 2
#################################################

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
}
```
- Next for the ALB,  target groups are created and the target groups are created with the necessary health checks. Hereafter the creation of the target groups has been updated with the Autoscaling group. 

- Target Group - 1

```sh
#################################################
        # Target Group - 1
#################################################

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
      path                      = "/"
      timeout                   = 10
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
#################################################
        # Target Group - 2
#################################################

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
      path                      = "/"
      timeout                   = 10
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
#################################################
        # Application LoadBalancer 
#################################################
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
output "alb-endpoint" {
  value = aws_lb.alb.dns_name
} 
```
- As the requirement was to redirect the traffic based on the host header, here I have configured a routing policy with "host header rule" in the ALB. As per the rule, based on the host header the traffic will be forwarded to the target group-1 and target group-2. 

- First Rule to forward the connection towards the domain, consider as an example:- one.example.com
```sh
#################################################
        # ALB Host Routing Rule -1
#################################################

resource "aws_lb_listener_rule" "host_based_weighted_routing-1" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
  }

  condition {
    host_header {
      values = ["one.example.com"]
    }
  }
}
```
- Second Rule to forward the connection towards the other domain, consider as example:- two.example.com
 
```sh
#################################################
        # ALB Host Routing Rule -2
#################################################

resource "aws_lb_listener_rule" "host_based_weighted_routing-2" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg2.arn
  }

  condition {
    host_header {
      values = ["two.example.com"]
    }
  }
}
```
- For the whole, infrastructure certain variables have been created for easy customizations. And the variables have been declared in the file variables.tf.  At the same time, the values for the variables are provided in the terraform.tfvars for user customization. 

- variables.tf
```sh
#################################################
        # Provider & Project Details
#################################################
variable "region"     {}
variable "access_key" {}
variable "secret_key" {}
variable "project"    {}
#################################################
        # VPC Requirements
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

- The user needs to update the required values for the variables in the terraform.tfvars to make updations to the whole infrastructure. Consider the example values given below. 

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
subnetcidr  = "2"
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

Here I have deployed a complex architecture in AWS using the terraform as IaC in a simpler and efficient way.
