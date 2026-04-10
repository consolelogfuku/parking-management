data "aws_ssm_parameter" "db_password" {
  name= "/parking-management/rds/master-password"
  with_decryption = true # KMSで暗号化されているため、復号化する
}

resource "aws_security_group" "rds_sg" {
  name = "parking-management-rds-sg"
  description = "Security group for RDS"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "parking-management-rds-sg"
  }
}

resource "aws_security_group_rule" "rds_sg_rule_inbound_rds" {
  # RDSへの接続を許可
  type = "ingress"
  from_port = 5432
  to_port = 5432 # RDSのポート
  protocol = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id # EC2からのみ接続を許可
  security_group_id = aws_security_group.rds_sg.id
}

resource "aws_security_group_rule" "rds_sg_rule_outbound" {
  # すべてのアウトバウンドを許可
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_sg.id
}

resource "aws_db_subnet_group" "main" {
  name = "parking-management-rds-subnet-group"
  description = "Subnet group for RDS"
  # AZ冗長を前提に設計されているため、複数のサブネットを指定できる
  # 指定したサブネットのうちどれかに配置される
  subnet_ids = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1c.id]
  tags = {
    Name = "parking-management-rds-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "parking-management-db"
  db_name    = "parking_management_production"
  allocated_storage = 20
  engine = "postgres"
  engine_version = "17.4"
  instance_class = "db.t4g.micro"
  username = "parking_management" # database.ymlで設定したユーザー名
  password = data.aws_ssm_parameter.db_password.value
  storage_encrypted = true # ストレージを暗号化する
  skip_final_snapshot = true # 削除時にバックアップをとらなくてもRDSを削除できる
  publicly_accessible = false # RDSをインターネットに公開しない
  multi_az = false # 単一AZで運用する
  port = 5432 # RDSのポート
  storage_type = "gp3"
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "parking-management-db"
  }
}
