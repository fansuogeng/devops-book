packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-ami" "amazon-linux" {                    
  filters = {
    name = "al2023-ami-2023.*-x86_64"
  }
  owners      = ["amazon"]
  most_recent = true
  region      = "ap-southeast-2"
}

source "amazon-ebs" "amazon-linux" {                  
  ami_name        = "sample-app-packer-${uuidv4()}"
  ami_description = "Amazon Linux AMI with a Node.js sample app."
  instance_type   = "t2.micro"
  region          = "ap-southeast-2"
  source_ami      = data.amazon-ami.amazon-linux.id
  ssh_username    = "ec2-user"
  ssh_timeout     = "10m"
  ssh_keep_alive_interval = "5s"

  # Prevent cloud-init from running background dnf updates that compete
  # for locks and restart sshd (killing Packer's SSH session).
  user_data = <<EOF
#cloud-config
package_update: false
package_upgrade: false
EOF
}

build {                                               
  sources = ["source.amazon-ebs.amazon-linux"]

  provisioner "shell" {
    script            = "install-node.sh"
    expect_disconnect = true
  }

  provisioner "file" {
    source      = "app.js"
    destination = "/home/ec2-user/app.js"
  }
}