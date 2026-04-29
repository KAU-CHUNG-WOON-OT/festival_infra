# ── ECS Cluster ───────────────────────────────────────────────
resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${var.name_prefix}-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ── CloudWatch Log Groups ─────────────────────────────────────
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project_name}-main"
  retention_in_days = 14

  tags = { Name = "/ecs/${var.project_name}-main" }
}

resource "aws_cloudwatch_log_group" "vote" {
  name              = "/ecs/${var.project_name}-vote"
  retention_in_days = 14

  tags = { Name = "/ecs/${var.project_name}-vote" }
}

resource "aws_cloudwatch_log_group" "ticket_query" {
  name              = "/ecs/${var.project_name}-ticket-query"
  retention_in_days = 14
  tags = { Name = "/ecs/${var.project_name}-ticket-query" }
}


# ── IAM: Execution Role ───────────────────────────────────────
resource "aws_iam_role" "execution" {
  name = "${var.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.name_prefix}-ecs-execution-role" }
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_ssm" {
  name = "${var.name_prefix}-ecs-execution-ssm"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = "arn:aws:ssm:*:*:parameter/${var.project_name}/*"
    }]
  })
}

# ── IAM: Task Role ────────────────────────────────────────────
resource "aws_iam_role" "task" {
  name = "${var.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.name_prefix}-ecs-task-role" }
}

resource "aws_iam_role_policy" "task_cloudwatch" {
  name = "${var.name_prefix}-ecs-task-cloudwatch"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:PutMetricData"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "task_dynamodb" {
  name = "${var.name_prefix}-ecs-task-dynamodb"
  role = aws_iam_role.task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem"]
      Resource = "arn:aws:dynamodb:ap-northeast-2:236451048000:table/festival-ticketing-ticket"
    }]
  })
}
