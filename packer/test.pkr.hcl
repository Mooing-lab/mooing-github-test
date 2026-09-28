packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "app_version" {
  type        = string
  description = "mooing-github-test version tag (e.g. v1.0.3)"
}

variable "s3_bucket" {
  type    = string
  default = "mooing-deploy-artifacts"
}

# 운영(mooing-kiosk)과 분리된 prefix
variable "s3_prefix" {
  type    = string
  default = "mooing-github-test"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "base_ami" {
  type        = string
  description = "Base AMI ID"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

source "amazon-ebs" "test" {
  ami_name      = "mooing-github-test-${var.app_version}-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  instance_type = var.instance_type
  region        = var.aws_region
  source_ami    = var.base_ami
  ssh_username  = "ec2-user"
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id

  associate_public_ip_address = true
  iam_instance_profile        = "mooing-packer-build-profile"

  tags = {
    Name       = "mooing-github-test-${var.app_version}"
    Project    = "mooing"
    Component  = "github-test"
    AppVersion = var.app_version
    BuildDate  = formatdate("YYYY-MM-DD", timestamp())
  }
}

build {
  sources = ["source.amazon-ebs.test"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y java-21-amazon-corretto aws-cli"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/mooing/github-test",
      "sudo chown -R ec2-user:ec2-user /opt/mooing/github-test",
      "aws s3 cp s3://${var.s3_bucket}/${var.s3_prefix}/mooing-github-test-${var.app_version}.jar /tmp/mooing-github-test.jar",
      "sudo mv /tmp/mooing-github-test.jar /opt/mooing/github-test/mooing-github-test.jar"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "APP_VERSION=${var.app_version}",
    ]
    inline = [
      "sudo tee /etc/systemd/system/mooing-github-test.service > /dev/null <<UNIT",
      "[Unit]",
      "Description=Mooing Github Test Server",
      "After=network.target",
      "",
      "[Service]",
      "Type=simple",
      "User=ec2-user",
      "WorkingDirectory=/opt/mooing/github-test",
      "Environment=\"APP_VERSION=$APP_VERSION\"",
      "ExecStart=/usr/bin/java -Dnetworkaddress.cache.ttl=30 -jar /opt/mooing/github-test/mooing-github-test.jar",
      "Restart=on-failure",
      "RestartSec=10",
      "StandardOutput=journal",
      "StandardError=journal",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "UNIT",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable mooing-github-test"
    ]
  }
}
