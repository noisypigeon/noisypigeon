locals {
  job_name     = "import"
  bucket_alias = "poisoned-mega-storage-consolidation"
  source_bucket_name = local.import_backblaze_bucket_name
}
