resource "aws_security_group" "ec2_sg" {
  name = "parking-management-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "parking-management-ec2-sg"
  }
}

resource "aws_security_group_rule" "ec2_sg_rule_inbound_ssh" {
  # 自分のIPからのSSH接続を許可
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["175.177.46.137/32"]
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "ec2_sg_rule_inbound_nginx" {
  # Nginxのポート80への接続を許可
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "ec2_sg_rule_outbound" {
  # すべてのアウトバウンドを許可
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

# EC2のIAMロールを作成する(パラメータストアからパスワードを取得するため)
resource "aws_iam_role" "ec2_role" {
  name = "parking-management-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# EC2のIAMロールにSSMのパラメータストアへのアクセス権限を付与する
resource "aws_iam_role_policy" "ec2_ssm_policy" {
  name = "parking-management-ec2-ssm-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:ap-northeast-1:136317661937:parameter/parking-management/rds/master-password",
          "arn:aws:ssm:ap-northeast-1:136317661937:parameter/parking-management/rails/master-key",
          "arn:aws:ssm:ap-northeast-1:136317661937:parameter/parking-management/rds/host"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}

# EC2のインスタンスプロファイルを作成する(IAMロールを紐づけるため)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "parking-management-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_1a" {
  ami = "ami-05284d16d6b516ace"
  instance_type = "t3.medium"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id = aws_subnet.public_subnet_1a.id
  # IAMロールを紐づける
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name = "Sample"
  tags = {
    Name = "parking-management-app-1a"
  }
}

# resource "aws_instance" "app_1c" {
#   ami = "ami-05284d16d6b516ace"
#   instance_type = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.ec2_sg.id]
#   subnet_id = aws_subnet.public_subnet_1c.id
#   tags = {
#     Name = "parking-management-app-1c"
#   }
# }
