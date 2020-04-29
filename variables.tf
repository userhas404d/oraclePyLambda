variable "project_name" {
  type        = string
  default     = "oracle-test"
  description = "Name to assign to the project"
}

variable "vpc_id" {
  description = "ID of the VPC hosting your Simple AD instance"
  type        = string
}

variable "log_level" {
  default     = "Info"
  description = "Log level of the lambda output, one of: Debug, Info, Warning, Error, or Critical"
  type        = string
}

variable "tags" {
  default     = {}
  description = "Map of tags to assign to this module's resources"
  type        = map(string)
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of target subnet ids in which to place the lambda function"
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Map of values to assing as environment vars to the lambda function"
}