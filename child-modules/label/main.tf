locals {
  tags_str      = "${var.module}${var.delimiter}${var.app}${var.delimiter}${var.stage}"
  name          = lower(local.tags_str)
  module        = lower(var.module)
  app           = lower(var.app)
  stage         = lower(var.stage)
  domain_prefix = "${lower(local.stage)}-${lower(local.app)}"

  # Merge input tags with our tags.
  # Note: `Name` has a special meaning in AWS and we need to disamgiuate it by using the computed `id`
  tags = {
    "Module" = local.module
    "App" = local.app
    "Stage" = local.stage
    "Terraform" = true
  }
}
