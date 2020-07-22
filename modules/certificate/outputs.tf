output "certificate_arn" {
  description = "The validated certificates ARN"
  value       = "${element(coalescelist(aws_acm_certificate_validation.cert-us.*.certificate_arn, aws_acm_certificate_validation.cert.*.certificate_arn),0)}"
}
