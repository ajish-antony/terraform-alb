#################################################
        # Bastion Security Group
#################################################
resource "aws_security_group" "bastion" {
    
  name_prefix       = "${var.project}-bsg--"
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

#################################################
        # Application Security Group
#################################################

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
    
    from_port        = 3306
    to_port          = 3306
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


