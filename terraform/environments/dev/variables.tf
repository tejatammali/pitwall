variable "aws_region" {
  description = "AWS region to deploy all Pitwall resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment — dev, staging, or prod"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project identifier used in resource names and tags"
  type        = string
  default     = "pitwall"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_count" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 4
}