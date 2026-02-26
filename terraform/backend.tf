resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = "backend-s3-delete-me"
  acl    = "private"

  tags = {
    Name        = "TerraformStateBuckeT"
  }
}