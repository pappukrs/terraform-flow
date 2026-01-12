output "ec2_ip" {
  value = aws_instance.app.public_ip
}
