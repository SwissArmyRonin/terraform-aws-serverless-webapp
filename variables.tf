variable "front_end_name" {
  description = "The subdomain name used for the front-end"
  default     = "www"
}

variable "back_end_name" {
  description = "The subdomain name used for the back-end"
  default     = "api"
}

variable "deploy_website" {
  description = "If true, the contents of '${lambda_source_dir}' are copied to the front-end bucket after creation"
  default     = true
}

variable "zone_name" {
  description = "The top level domain that will host the subdomains used for the front- and back-end"
  type        = "string"
}

variable "lambda_source_dir" {
  description = "The absolute path of a folder containing the (compiled/transpiled) back-end"
  type        = "string"
}

variable "lambda_handler" {
  description = "The Lambda entry point"
  default     = "lambda.handler"
}

variable "lambda_runtime" {
  description = "The Lambda runtime"
  default     = "nodejs10.x"
}
