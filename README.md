# Serverless Webapp

_For Terraform "~> 0.11"_

Please note that creating the certificates can take anywhere from a few minutes to 45 minutes. The
wait is determined by how fast AWS approves the certificates. If install fails after 45 minutes due
to one or more certificates, simply run the apply step again.

Please also note, the the step that creates the CloudFront distribution will usually take between 30
and 60 minutes. Be patient.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| back\_end\_name | The subdomain name used for the back-end | string | `"api"` | no |
| deploy\_website | If true, the contents of '${lambda_source_dir}' are copied to the front-end bucket after creation | string | `"true"` | no |
| front\_end\_name | The subdomain name used for the front-end | string | `"www"` | no |
| frontend\_source\_dir | The absolute path of a folder containing the (transpiled/bundled) front-end | string | n/a | yes |
| lambda\_handler | The Lambda entry point | string | `"lambda.handler"` | no |
| lambda\_runtime | The Lambda runtime | string | `"nodejs10.x"` | no |
| lambda\_source\_dir | The absolute path of a folder containing the (compiled/transpiled) back-end | string | n/a | yes |
| zone\_name | The top level domain that will host the subdomains used for the front- and back-end | string | n/a | yes |

