output "id" {
  description = "Scaleway project ID — hand-copy into ../state/bucket/bucket_definition.tf and ../blog/bucket/bucket_definition.tf after applying this leaf"
  value       = module.project.id
}
