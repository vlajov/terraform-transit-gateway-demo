variable "access_key" {
  description = "Access key to AWS console"
  sensitive   = true
}
variable "secret_key" {
  description = "Secret key to AWS console"
  sensitive   = true
}
variable "region" {
  description = "AWS region"
}
