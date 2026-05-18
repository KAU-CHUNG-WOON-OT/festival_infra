resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Festival RDS subnet group"

  tags = { Name = "${var.name_prefix}-db-subnet-group" }
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.name_prefix}-mysql80"
  family      = "mysql8.0"
  description = "Festival MySQL 8.0 parameters"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "general_log"
    value = "0"
  }

  tags = { Name = "${var.name_prefix}-mysql80" }
}

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t4g.small"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "festival"
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.sg_db_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az            = false
  publicly_accessible = false

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name_prefix}-db-final-snapshot"
  deletion_protection       = false

  backup_retention_period = var.backup_retention_period
  backup_window           = "02:00-03:00"
  maintenance_window      = "Mon:03:00-Mon:04:00"

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  tags = { Name = "${var.name_prefix}-db" }

  lifecycle {
    ignore_changes = [password]
  }
}
