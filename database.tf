resource "aws_db_instance" "postgres_db" {
  allocated_storage      = 100
  engine                 = "postgres"
  engine_version         = "9.5.4"
  instance_class         = "db.t3.micro"
  identifier             = "mydb1"
  name                   = "mydb1"
  username               = "postgres"
  password               = "postgres"
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.db_sn_group.name
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
}

resource "aws_elasticache_cluster" "redis_db" {
  cluster_id           = "cluster-example"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  security_group_ids   = [aws_security_group.redis_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.elasticache_sg.name
}
