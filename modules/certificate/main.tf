provider "aws" {
  alias  = "us-east-1" # The certs used by CloudFront have to be in the us-east-1 region
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert-us" {
  count             = "${var.us-provider ? 1: 0}"
  provider          = "aws.us-east-1"
  domain_name       = "${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "cert_validation-us" {
  count   = "${var.us-provider ? 1: 0}"
  name    = "${aws_acm_certificate.cert-us.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert-us.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.cert-us.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert-us" {
  count                   = "${var.us-provider ? 1: 0}"
  provider                = "aws.us-east-1"
  certificate_arn         = "${aws_acm_certificate.cert-us.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation-us.fqdn}"]
}

resource "aws_acm_certificate" "cert" {
  count             = "${var.us-provider ? 0: 1}"
  domain_name       = "${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "cert_validation" {
  count   = "${var.us-provider ? 0: 1}"
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = "${var.us-provider ? 0: 1}"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
