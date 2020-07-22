variable "region" {
  description = "The AWS target region"
  default     = "eu-west-1"
}

variable "zone_name" {
  description = "The top level domain that will host the subdomains used for the front- and back-end"
  default     = "isntall.net"
}
