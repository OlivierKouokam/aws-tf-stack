output "key_name" {
  value = aws_key_pair.this.key_name
}

output "key_path" {
  value = local_file.this.filename
}