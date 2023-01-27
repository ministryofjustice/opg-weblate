module "shared" {
  source             = "../../modules/shared"
  network_cidr_block = "9.0.0.0/16"

  providers = {
    aws.region     = aws.eu_west_1
    aws.global     = aws.global
    aws.management = aws.management_eu_west_1
  }
}
