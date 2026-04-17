# Task Execution Role（ECSがコンテナ起動時に使う権限）
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "parking-checker-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# AWSが用意した既存のポリシー（ECRイメージ取得、CloudWatch Logs書き込み）
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# カスタムポリシー(SSM Parameter Storeからシークレット取得用)
resource "aws_iam_role_policy" "ecs_task_execution_ssm" {
  name = "parking-checker-ecs-task-execution-ssm"
  role = aws_iam_role.ecs_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:ap-northeast-1:*:parameter/parking-checker/*"
      }
    ]
  })
}

# Task Role（コンテナ内のアプリが実行中に使う権限）
resource "aws_iam_role" "ecs_task_role" {
  name = "parking-checker-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ECS Exec用（コンテナにSSH的に接続）
resource "aws_iam_role_policy" "ecs_task_ssm_messages" {
  name = "parking-checker-ecs-task-ssm-messages"
  role = aws_iam_role.ecs_task_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# GitHub Actions OIDC プロバイダー
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com" # OIDCトークンの発行元
  client_id_list  = ["sts.amazonaws.com"] # トークンの宛先(受け取り手)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # トークンの発行元のURLのSSL証明書のフィンガープリント(githubが公式に出している)
}

# GitHub Actions用IAMロールの箱
resource "aws_iam_role" "github_actions" {
  name = "parking-checker-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity" # OIDCトークンを使って、GitHub Actionsが、このIAMロールを使うことを許可する
        Condition = {
          StringEquals = { # 完全一致
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" # トークンがSTS向け(audは宛先)に発行されたことを確認する
          }
          StringLike = { # ワイルドカードで一致を確認する
            "token.actions.githubusercontent.com:sub" = "repo:consolelogfuku/parking-management:*" # このリポジトリからのみ許可
          }
        }
      }
    ]
  })
}

# ECRへのプッシュ権限(GitHub Actions用IAMロールの箱に紐づける)
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "parking-checker-github-actions-ecr"
  role = aws_iam_role.github_actions.name # IAMロールの箱に紐づける

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}

# ECSデプロイ権限(GitHub Actions用IAMロールの箱に紐づける)
resource "aws_iam_role_policy" "github_actions_ecs" {
  name = "parking-checker-github-actions-ecs"
  role = aws_iam_role.github_actions.name # IAMロールの箱に紐づける

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeServices"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.ecs_task_role.arn,
          aws_iam_role.ecs_task_execution_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = "ecs:UpdateService"
        Resource = "arn:aws:ecs:ap-northeast-1:*:service/parking-checker/*"
      },
      {
        Effect = "Allow"
        Action = "ecs:RunTask"
        Resource = "arn:aws:ecs:ap-northeast-1:*:task-definition/parking-checker-*"
      }
    ]
  })
}