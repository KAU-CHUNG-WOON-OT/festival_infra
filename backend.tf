terraform {
  backend "s3" {
    # TODO: 실제 버킷명/테이블명으로 교체 후 terraform init -reconfigure 실행
    bucket         = "PLACEHOLDER-festival-terraform-state"
    key            = "festival/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "PLACEHOLDER-festival-terraform-lock"
    encrypt        = true
  }
}
