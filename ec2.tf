resource "aws_instance" "example" {
  ami             = "ami-006f82a1d5a27da54"
  instance_type   = "t3.micro"
  key_name        = "webserver-key"
  security_groups = ["terraform-group"]

  tags = {
    Name = "sjit-devops"
    team = "sjit"
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

output "public_ip" {
  value = aws_instance.example.public_ip
}
