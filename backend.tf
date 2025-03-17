terraform {
  backend "s3" {
    bucket = "seunadio-tfstate"
    key    = "bootstrap/infra.tfstate"
    region = "eu-west-2"
  }
}
