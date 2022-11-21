module "frontend" {
  source = "terraform/hack"
}

module "backend-1" {
  source = "terraform/example"
}
