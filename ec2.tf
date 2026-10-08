resource "aws_instance" "instance1" {
  ami                    = "ami-006f82a1d5a27da54"
  instance_type          = "t3.micro"
  key_name               = "webserver-key"
  subnet_id              = aws_subnet.pub_sub1.id
  vpc_security_group_ids = [aws_default_security_group.default.id]

  tags = {
    Name = "devops-project-instance-1"
    team = "devops-project"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker
    usermod -aG docker ubuntu
    docker run -d --name test --restart always -p 8080:80 httpd:2.4
  EOF
}

resource "aws_instance" "instance2" {
  ami                    = "ami-006f82a1d5a27da54"
  instance_type          = "t3.micro"
  key_name               = "webserver-key"
  subnet_id              = aws_subnet.pub_sub2.id
  vpc_security_group_ids = [aws_default_security_group.default.id]

  tags = {
    Name = "devops-project-instance-2"
    team = "devops-project"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker
    usermod -aG docker ubuntu
    docker run -d --name test --restart always -p 8080:80 httpd:2.4
  EOF
}

output "instance1_public_ip" {
  value = aws_instance.instance1.public_ip
}

output "instance2_public_ip" {
  value = aws_instance.instance2.public_ip
}
