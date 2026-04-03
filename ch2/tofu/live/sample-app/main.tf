provider "aws" {
  region = "ap-southeast-2"
}

module "sample_app_1" {
  source = "../../g

  name = "sample-app-tofu-1"

}

module "sample_app_2" {
  source = "../../modules/ec2-instance"

  name = "sample-app-tofu-2"

}

module "sample_app_3" {
  source = "../../modules/ec2-instance"

  name = "sample-app-tofu-3"

}
