output "private_ip" {
  value = aws_eip.eip.private_ip
}

output "public_ip" {
  value = aws_eip.eip.public_ip
}

output "public_dns" {
  value = aws_eip.eip.public_dns
}