provider "aws" {
  region = "ap-southeast-2"
}

module "repo" {
  source  = "brikis98/devops/book//modules/ecr-repo"
  version = "1.0.0"

  name = "sample-app"
}
