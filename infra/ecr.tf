resource "aws_ecr_repository" "app" {
  name = "parking-checker"

  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "parking-checker"
  }
}