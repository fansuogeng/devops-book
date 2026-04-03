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

  #region agent log
  provisioner "shell-local" {
    command = "python3 -c \"import json,time;open('/Users/mike/audit/devops-book/.cursor/debug-c66563.log','a').write(json.dumps({'sessionId':'c66563','runId':'pre-fix','hypothesisId':'H0','location':'sample-app.pkr.hcl:build.pre_shell','message':'Entering remote shell provisioner','data':{'source_ami':'${data.amazon-ami.amazon-linux.id}','region':'ap-southeast-2'},'timestamp':int(time.time()*1000)})+'\\\\n')\""
  }
  #endregion

  provisioner "shell" {
    script            = "install-node.sh"
    expect_disconnect = true
  }

  #region agent log
  provisioner "shell-local" {
    command = "python3 -c \"import json,time;open('/Users/mike/audit/devops-book/.cursor/debug-c66563.log','a').write(json.dumps({'sessionId':'c66563','runId':'pre-fix','hypothesisId':'H3','location':'sample-app.pkr.hcl:build.post_shell','message':'Remote shell provisioner completed and control returned','data':{'provisioner':'install-node.sh'},'timestamp':int(time.time()*1000)})+'\\\\n')\""
  }
  #endregion

  provisioner "file" {
    source      = "app.js"
    destination = "/home/ec2-user/app.js"
  }

  #region agent log
  provisioner "shell-local" {
    command = "python3 -c \"import json,time;open('/Users/mike/audit/devops-book/.cursor/debug-c66563.log','a').write(json.dumps({'sessionId':'c66563','runId':'pre-fix','hypothesisId':'H4','location':'sample-app.pkr.hcl:build.post_file_upload','message':'File upload provisioner completed','data':{'file':'app.js'},'timestamp':int(time.time()*1000)})+'\\\\n')\""
  }
  #endregion
}