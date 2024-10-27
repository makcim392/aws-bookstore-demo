# variables.tf
variable "environment" {
  default = "dev"
}

variable "db_password" {
  description = "RDS database password"
  sensitive   = true
}

# networking.tf
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-bookstore-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-private-${count.index + 1}"
  }
}

# database.tf
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-bookstore-db"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "main" {
  identifier        = "${var.environment}-bookstore-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"  # Free tier eligible
  allocated_storage = 20

  db_name  = "bookstore"
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  skip_final_snapshot = true  # For development only

  tags = {
    Environment = var.environment
  }
}

# security.tf
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
}

# application.tf
resource "aws_elastic_beanstalk_application" "bookstore" {
  name        = "${var.environment}-bookstore"
  description = "Bookstore Demo Application"
}

resource "aws_elastic_beanstalk_environment" "bookstore_env" {
  name                = "${var.environment}-bookstore-env"
  application         = aws_elastic_beanstalk_application.bookstore.name
  solution_stack_name = "64bit Amazon Linux 2 v5.8.0 running Node.js 18"  # Update as needed

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"  # Free tier eligible
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

# outputs.tf
output "database_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "application_url" {
  value = aws_elastic_beanstalk_environment.bookstore_env.cname
}