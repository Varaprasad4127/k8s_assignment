output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.k8s_node.public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.k8s_node.private_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.k8s_node.id
}