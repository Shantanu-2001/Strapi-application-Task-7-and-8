resource "aws_db_subnet_group" "strapi_db_subnet_group" {
  name       = "strapi-db-subnet-group-shantanu"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "strapi_rds_sg" {
  name   = "strapi-rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "strapi_rds" {
  identifier          = "strapi-db"
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "strapi"
  password            = "strapi123"
  db_name             = "strapi_db"
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.strapi_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.strapi_rds_sg.id]
}
