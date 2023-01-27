module "shared" {
  source = "../../modules/shared"

  providers = {
    aws.region     = aws.eu_west_1
    aws.global     = aws.global
    aws.management = aws.management_eu_west_1
  }
}
