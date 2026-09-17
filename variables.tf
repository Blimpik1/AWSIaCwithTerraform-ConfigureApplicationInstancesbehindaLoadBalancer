variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_id" {
  description = "Project identifier for resource naming and tagging"
  type        = string
}

variable "vpc_name" {
  description = "Name tag of the pre-created VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet A"
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet B"
  type        = string
}

variable "ec2_sg_name" {
  description = "Name of the EC2 SSH security group"
  type        = string
}

variable "http_sg_name" {
  description = "Name of the EC2 HTTP security group"
  type        = string
}

variable "alb_sg_name" {
  description = "Name of the ALB security group"
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the pre-created IAM instance profile"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the pre-created key pair"
  type        = string
}

variable "launch_template_name" {
  description = "Name of the Launch Template"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}