output "dev_ip" {
    value = aws_instance.dev_node.public_ip
}

output "dev_instance_state" {
    value = aws_instance.dev_node.instance_state
}