data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Create the IAM Role
resource "aws_iam_role" "ec2_role" {
  name               = "ec2-github-role-delete-me"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}


resource "aws_iam_policy" "secrets_policy" {
  name = "EC2SecretsManagerRead-delete-me"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:github-token-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}


resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = "ec2-profile-delete-me"
  role = aws_iam_role.ec2_role.name
}