output "access_policy_arn" {
  description = "The ARN of a policy allowing read access to the bucket."
  value       = aws_iam_policy.access_bucket.arn
}