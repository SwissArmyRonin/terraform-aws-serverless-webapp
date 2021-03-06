# Certificate

Helper module that creates validated certificates in the current region and certificates
specifically in "us-east-1" for use with CloudFront.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| domain\_name | The domain name for the SSL certificate | string | n/a | yes |
| environment | An environment tag applied to certificates | string | n/a | yes |
| us-provider | If true, the certificate will be created in us-east-1 | string | `"false"` | no |
| zone\_id | The top-level zone id for the domain_name | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| certificate\_arn | The validated certificates ARN |

