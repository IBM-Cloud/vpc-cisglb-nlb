# versions

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "> 1.48.0"
    }
  }
  required_version = ">= 1.3.6"
}
