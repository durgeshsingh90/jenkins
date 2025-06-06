provider "aws" {
  region = "eu-west-1"
  # profile = "switches"  # <-- your IAM user in account 253490766231

}

resource "aws_instance" "jenkins" {
  ami                    = "ami-03400c3b73b5086e9"
  instance_type          = "t2.micro"
  subnet_id              = "subnet-0681ffca4e21a8ec7"
  vpc_security_group_ids = ["sg-09f12074f89a273a0"]
  key_name               = "MSI"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y

              # Create user jenkins
              sudo useradd jenkins
              echo 'jenkins:admin' | sudo chpasswd
              sudo usermod -aG wheel jenkins

              # Python
              sudo yum install -y python3
              sudo alternatives --install /usr/bin/python python /usr/bin/python3 1

              # Docker
              sudo yum install -y docker
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker jenkins

              # Jenkins
              sudo docker pull jenkins/jenkins:lts
              sudo docker run -d --name jenkins \
                -p 8080:8080 -p 50000:50000 \
                -v jenkins_home:/var/jenkins_home \
                jenkins/jenkins:lts

              sleep 30
              sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword > /home/jenkins/jenkins_password.txt
              sudo chown jenkins:jenkins /home/jenkins/jenkins_password.txt
              EOF

  tags = {
    Name = "jenkins"
  }
}


output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "ssh_hint" {
  value = "ssh jenkins@${aws_instance.jenkins.public_ip} (password: admin)"
}

output "jenkins_password_hint" {
  value = "cat /home/jenkins/jenkins_password.txt"
}