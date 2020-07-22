/**
 * # Serverless Webapp
 *
 * _For Terraform "~> 0.11"_
 * 
 * Please note that creating the certificates can take anywhere from a few minutes to 45 minutes. The
 * wait is determined by how fast AWS approves the certificates. If install fails after 45 minutes due
 * to one or more certificates, simply run the apply step again.
 * 
 * Please also note, the the step that creates the CloudFront distribution will usually take between 30
 * and 60 minutes. Be patient.
 */
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

module "frontend-certificate" {
  source      = "modules/certificate"
  us-provider = true                                        # The certs used by CloudFront have to be in the us-east-1 region
  environment = "${terraform.workspace}"
  domain_name = "${var.front_end_name}.${var.zone_name}"
  zone_id     = "${data.aws_route53_zone.selected.zone_id}"
}

module "backend-certificate" {
  source      = "modules/certificate"
  environment = "${terraform.workspace}"
  domain_name = "${var.back_end_name}.${var.zone_name}"
  zone_id     = "${data.aws_route53_zone.selected.zone_id}"
}

###############################################################################
# Back-end
################################################################################

resource "aws_iam_role" "lambda" {
  name = "${terraform.workspace}-backend-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

locals {
  lambda_filename      = "${path.module}/dist/lambda.zip"
  lambda_function_name = "${replace("${var.back_end_name}.${var.zone_name}","/[^[a-zA-Z0-9-_]/","-")}"
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${local.lambda_filename}"
  source_dir  = "${var.lambda_source_dir}"
}

resource "aws_lambda_function" "backend" {
  filename         = "${local.lambda_filename}"
  function_name    = "${local.lambda_function_name}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "${var.lambda_handler}"
  source_code_hash = "${data.archive_file.lambda.output_base64sha256}"
  runtime          = "${var.lambda_runtime}"
  timeout          = 900

  tags = {
    Environment = "${terraform.workspace}"
  }

  depends_on = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.lambda"]
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "${local.lambda_function_name}-api"
  description = "This is the entrypoint for the ${local.lambda_function_name}-lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "backend_any" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "backend" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.proxy.id}"
  http_method             = "${aws_api_gateway_method.backend_any.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.backend.arn}/invocations"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.backend.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/*"
}

resource "aws_api_gateway_deployment" "backend" {
  depends_on  = ["aws_api_gateway_method.backend_any"]
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${terraform.workspace}"
}

resource "aws_api_gateway_domain_name" "backend" {
  domain_name              = "${var.back_end_name}.${var.zone_name}"
  regional_certificate_arn = "${module.backend-certificate.certificate_arn}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "back" {
  name    = "${aws_api_gateway_domain_name.backend.domain_name}"
  type    = "A"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"

  alias {
    evaluate_target_health = true
    name                   = "${aws_api_gateway_domain_name.backend.regional_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.backend.regional_zone_id}"
  }
}

resource "aws_api_gateway_base_path_mapping" "default" {
  api_id      = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${aws_api_gateway_deployment.backend.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.backend.domain_name}"
}

###############################################################################
# Front-end
################################################################################

resource "aws_s3_bucket" "front" {
  bucket = "${terraform.workspace}-${var.front_end_name}.${var.zone_name}"
  acl    = "private"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "null_resource" "deploy_website" {
  count = "${var.deploy_website ? 1 : 0}"

  provisioner "local-exec" {
    command = "aws s3 cp --recursive ${var.frontend_source_dir} s3://${aws_s3_bucket.front.bucket}/"
  }

  depends_on = ["aws_s3_bucket.front"]
}

resource "aws_s3_bucket_policy" "public-read-policy" {
  bucket = "${aws_s3_bucket.front.id}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.front.bucket}/*"
            ]
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "logs" {
  bucket = "${terraform.workspace}-logs.${var.zone_name}"
  acl    = "private"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

locals {
  s3_origin_id = "S3-${aws_s3_bucket.front.bucket}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.front.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.logs.bucket_regional_domain_name}"
    prefix          = "${var.front_end_name}"
  }

  aliases = ["${var.front_end_name}.${var.zone_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "${terraform.workspace}"
  }

  viewer_certificate {
    acm_certificate_arn = "${module.frontend-certificate.certificate_arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "front" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${var.front_end_name}.${var.zone_name}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}
