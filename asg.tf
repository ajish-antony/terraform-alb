#################################################
        # IAM Role Creation
#################################################

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

#################################################
        # IAM Role Attachment
#################################################


resource "aws_iam_instance_profile" "terraform_profile" {
  name = "terraform_profile"
  role = "${aws_iam_role.terraform_role.name}"
}

#################################################
        # Polciy For IAM Role
#################################################

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

#################################################
        # Bastion Server Instance
#################################################

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
#################################################
        # Launch Configuration - 2
#################################################

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

  depends_on = [ aws_db_instance.default ]


}


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

  depends_on = [ aws_db_instance.default ]

}
