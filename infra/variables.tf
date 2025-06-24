variable "env" {
  description = "Environment name (dev/prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "db_username" {
  type    = string
  default = "tatto"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "allowed_cidrs" {
  description = "Inbound CIDR blocks for MySQL (Step 7 で自動更新予定)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # 最初は自宅回線や GHA CIDR を手で書く
}
