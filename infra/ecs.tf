# ECSクラスター
resource "aws_ecs_cluster" "main" {
  name = "parking-checker"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "parking-checker"
  }
}

# ECSタスクのログ出力先
resource "aws_cloudwatch_log_group" "ecs" {
  name = "parking-checker"
}

# ECSのセキュリティグループ
resource "aws_security_group" "ecs_sg" {
  name        = "parking-checker-ecs-sg"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "parking-checker-ecs-sg"
  }
}

resource "aws_security_group_rule" "ecs_sg_inbound" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id # ALBからのみ接続を許可
  security_group_id        = aws_security_group.ecs_sg.id
}

resource "aws_security_group_rule" "ecs_sg_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # すべてのアウトバウンドを許可(ECRからイメージ取得、RDSへの接続、外部API通信等に必要)
  security_group_id = aws_security_group.ecs_sg.id
}

# appタスク定義
resource "aws_ecs_task_definition" "app" {
  family                   = "parking-checker-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  task_role_arn            = aws_iam_role.ecs_task_role.arn # タスク内のコンテナが実行中に使う権限
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # タスクが起動時に使う権限

  container_definitions = templatefile("${path.root}/task_definitions/app.json", {
    repository_url = aws_ecr_repository.app.repository_url # ECRのリポジトリURL(app.json内で、タスクがどのDockerイメージを使うかを指定しているから渡す必要あり)
    awslogs_group  = aws_cloudwatch_log_group.ecs.name # CloudWatch Logsのグループ名
  })
}

# db-migrateタスク定義(run-taskで起動するため、サービスは不要)
resource "aws_ecs_task_definition" "db_migrate" {
  family                   = "parking-checker-db-migrate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = templatefile("${path.root}/task_definitions/db_migrate.json", {
    repository_url = aws_ecr_repository.app.repository_url # ECRのリポジトリURL(app.json内で、タスクがどのDockerイメージを使うかを指定しているから渡す必要あり)
    awslogs_group  = aws_cloudwatch_log_group.ecs.name # CloudWatch Logsのグループ名
  })
}

# ECSサービス（appコンテナ1台を常時稼働）
resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn # これはタスク定義のリビジョン1を指す
  desired_count   = 1 # タスク1台を常に維持
  launch_type     = "FARGATE"
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1c.id] # プライベートサブネットに配置
    assign_public_ip = false
  }

  # サービスがタスクを起動・停止する時に、ALBのターゲットグループにも自動で登録・解除してくれる設定
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn # どのターゲットグループに紐づけるか(ALBのtg)
    container_name   = "app" # タスク定義を元に立ち上がるどのコンテナに紐づけるか(app.json内のappコンテナ)
    container_port   = 3000 # どのポートに紐づけるか(appコンテナの3000ポート)
  }

  lifecycle {
    ignore_changes = [
      task_definition, # これがないとapplyした時に、タスク定義のリビジョン1が必ず使われてしまう
      desired_count # オートスケールしてタスクの台数が増えた時に、これがないとapplyした時に、タスクの台数が1台に戻ってしまう
    ]
  }
}