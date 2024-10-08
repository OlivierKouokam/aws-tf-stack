provider "aws" {
  region = "us-west-2"
  shared_credentials_files = ["../../.secrets/credentials"]
  profile                  = "default"
}
