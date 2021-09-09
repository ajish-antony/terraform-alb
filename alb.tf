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
      values = [var.domain1]
    }
  }
}


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
      values = [var.domain2]
    }
  }
}