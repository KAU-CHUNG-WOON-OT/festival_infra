terraform {
  backend "s3" {
    bucket         = "festival-terraform-state-236451048000-apne2"
    key            = "festival/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "festival-terraform-lock"
    encrypt        = true
  }
}
