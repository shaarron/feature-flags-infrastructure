#### Shared variables across modules
variable "common_tags" {
  default = {
    owner     = "SharonK"
    managedBy = "terraform"
    app_name  = "feature-flags"
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string

}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}


#### Network
variable "availability_zones" {
  type        = number
  description = "Amount of availability zones to use for the VPC"
}

variable "single_nat_gateway" {
  description = "Provision a single NAT Gateway"
  type        = bool
  default     = false
}

variable "vpc_cidrs" {
  description = "vpc cidrs"
  type        = string
}


#### Domain
variable "web_app_domain_name" {
  description = "Domain name for the web application"
  type        = string
}

variable "cert_domain_name" {
  description = "Domain name for the SSL certificate (for CloudFront)"
  type        = string

}


#### S3
variable "s3_force_destroy" {
  description = "Force destroy the S3 bucket and its contents"
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool

}

variable "block_public_access" {
  description = "Block public access to the S3 bucket"
  type        = bool

}

variable "force_ssl_policy" {
  description = "Force SSL for S3 bucket access"
  type        = bool
}

variable "server_side_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
}


#### CloudFront
variable "origin_access_control_origin_type" {
  description = "Origin access control origin type (e.g., s3)"
  type        = string
}

variable "origin_domain_name" {
  type    = string
  default = ""
}

variable "origin_id" {
  type    = string
  default = "nlb-origin"
}

variable "origin_protocol_policy" {
  description = "Protocol policy for the custom origin"
  type        = string
  default     = "https-only"
}

variable "origin_ssl_protocols" {
  description = "SSL protocols for the custom origin"
  type        = list(string)
  default     = ["TLSv1.2"]
}

variable "default_cache_behavior" {
  description = "Default cache behavior settings for CloudFront distribution"
  type = object({
    allowed_methods        = list(string)
    cached_methods         = list(string)
    target_origin_id       = string
    viewer_protocol_policy = string
    cache_policy_optimized = bool
  })

}

variable "ordered_cache_behavior" {
  description = "Defines additional path-based cache behaviors, evaluated in order before the default behavior (optional)."
  type = list(object({
    target_origin_id       = string
    allowed_methods        = list(string)
    cached_methods         = list(string)
    viewer_protocol_policy = string
    path_pattern           = string
    cache_policy_optimized = bool # use the optimized cache policy (true) or caching disabled (false).
  }))
  default = []
}

variable "geo_restriction_type" {
  description = "Type of geo restriction for CloudFront distribution"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be one of: none, whitelist, blacklist."
  }
}

variable "default_root_object" {
  description = "Default root object for CloudFront distribution"
  type        = string
  default     = "index.html"
}

variable "cf_aliases" {
  description = "List of aliases to associate with the CloudFront distribution"
  type        = list(string)
  default     = []

}


#### EKS
variable "cluster_version" {
  type = string
}

variable "kms_key_arn" {
  description = "The kms key arn for the eks cluster"
  type        = string
}

variable "node_type" {
  description = "EC2 instance type for the EKS node group"
  type = string
}

variable "node_group_desired_size" {
  description = "Desired size of the EKS node group"
  type        = number
  
}

variable "node_group_min_size" {
  description = "Minimum size of the EKS node group"
  type        = number
  
}

variable "node_group_max_size" {
  description = "Maximum size of the EKS node group"
  type        = number
  
}