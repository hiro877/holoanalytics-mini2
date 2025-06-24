# 1. S3 バケット（CSV 保存用）
# ---------------------------------------------------------------------------
# 1-B. S3 バケット（生データ Raw 保存用）
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "raw" {
  bucket        = "holoanalytics-raw"
  force_destroy = true # 学習なので削除しやすく
}

# ① バージョニング
resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ② 暗号化 (SSE)
resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ③ ライフサイクル (90日で削除)
resource "aws_s3_bucket_lifecycle_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id
  rule {
    id     = "keep-90days-raw"
    status = "Enabled"
    filter { prefix = "" } # すべてのオブジェクト
    expiration { days = 90 }
  }
}

# S3バケットとは、Amazon S3 (Simple Storage Service) でデータを保存する場所を指すコンテナのようなものです。S3バケットは、オブジェクト（ファイルやデータ）を格納するための論理的なコンテナとして機能し、グローバルに一意な名前を持つ必要があります。﻿

# 2. Subnet グループ（default VPC 利用で簡略）
data "aws_availability_zones" "available" {}

resource "aws_db_subnet_group" "default" {
  name        = "holoanalytics-${var.env}-subnetgrp"
  subnet_ids  = data.aws_subnets.default.ids
  description = "Default VPC subnets"
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id] # デフォルト VPC に属するもの全部
  }
}

data "aws_vpc" "default" {
  default = true
}

# 3. Security Group
resource "aws_security_group" "mysql_sg" {
  name        = "holoanalytics-${var.env}-mysql-sg"
  description = "Inbound MySQL from allowed CIDRs"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. RDS MySQL (Free Tier 相当)
resource "aws_db_instance" "mysql" {
  identifier                 = "holoanalytics-${var.env}"
  engine                     = "mysql"
  engine_version             = "8.0"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  storage_type               = "gp2"
  db_subnet_group_name       = aws_db_subnet_group.default.name
  vpc_security_group_ids     = [aws_security_group.mysql_sg.id]
  username                   = var.db_username
  password                   = var.db_password
  skip_final_snapshot        = true
  publicly_accessible        = true # 後で Private にしても可
  deletion_protection        = false
  auto_minor_version_upgrade = true
}
