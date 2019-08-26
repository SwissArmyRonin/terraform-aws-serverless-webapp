module "serverless-webapp" {
  source = "../.."

  zone_name           = "${var.zone_name}"
  lambda_source_dir   = "${path.module}/server"
  frontend_source_dir = "${path.module}/client"
}
