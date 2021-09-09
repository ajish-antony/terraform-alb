#################################################
        # RDS Creation
#################################################

resource "aws_db_instance" "default" {
  identifier_prefix           = "${var.project}-main"
  engine                      = "mysql"
  engine_version              = "5.7"
  name                        = "mydb"
  username                    = "admin"
  password                    = "admin1234"
  backup_retention_period     = 1
  allow_major_version_upgrade = false
  apply_immediately           = false
  vpc_security_group_ids      = [ aws_security_group.sg.id ]
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