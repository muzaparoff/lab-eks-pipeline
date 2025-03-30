resource "aws_ecr_repository" "frontend" {
  name                 = "my-app-frontend"
  image_scanning_configuration { scan_on_push = true }
  image_tag_mutability = "IMMUTABLE"
}
resource "aws_ecr_repository" "backend" {
  name                 = "my-app-backend"
  image_scanning_configuration { scan_on_push = true }
  image_tag_mutability = "IMMUTABLE"
}