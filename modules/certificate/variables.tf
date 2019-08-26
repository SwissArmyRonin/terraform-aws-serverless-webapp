variable "us-provider" {
  description = "If true, the certificate will be created in us-east-1"
  default     = false
}

variable "environment" {
  description = "An environment tag applied to certificates"
}

variable "domain_name" {
  description = "The domain name for the SSL certificate"
}

variable "zone_id" {
  description = "The top-level zone id for the domain_name"
}
