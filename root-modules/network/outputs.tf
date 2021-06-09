output "bucket_policy_arn" {
  description = "The ARN of a policy allowing read access to the bucket."
  value       = module.bucket.access_policy_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}