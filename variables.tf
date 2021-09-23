variable "project_name" {
  description = "Name of your project"
  type        = string
}

variable "image_uri" {
  description = "Uri of image docker for lambda function"
  type        = string
}

variable "region" {
  description = "Region of aws"
  type        = string
}

variable "availability_zone_names" {
  type    = list(string)
}

variable "database" {
  type    = object({
    username = string
    password = string
  })
}
