variable "region" {
  default     = "us-east-2"
  description = "The region to deploy in"
  type        = string
}

variable "hosted_zone_name" {
  default     = "cechols.com"
  description = "The name of the hosted zone in Route 53"
  type        = string
}

variable "domain_name" {
  default     = "blog.cechols.com"
  description = "The domain name of the website"
  type        = string
}
