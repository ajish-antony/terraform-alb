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
