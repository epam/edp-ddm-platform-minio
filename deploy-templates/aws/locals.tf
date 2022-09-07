locals {
  tags = merge(var.tags, {
    "user:tag" = var.cluster_name
  })
}