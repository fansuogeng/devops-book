provider "aws" {
  region = "ap-southeast-2"
}

module "sample_app_1" {
  #source = "../../modules/ec2-instance"
  source = "github.com/fansuogeng/devops-book//ch2/tofu/modules/ec2-instance?ref=1.0.0"

  name = "sample-app-tofu-1"

}

module "sample_app_2" {
  #source = "../../modules/ec2-instance"
  source = "github.com/fansuogeng/devops-book//ch2/tofu/modules/ec2-instance?ref=1.0.0"

  name = "sample-app-tofu-2"

}

module "sample_app_3" {
  #source = "../../modules/ec2-instance"
  source = "github.com/fansuogeng/devops-book//ch2/tofu/modules/ec2-instance?ref=1.0.0"

  name = "sample-app-tofu-3"

}
