locals {
  exact_name = "pigeon.dev"
  # Copied by hand from `terragrunt output id` in ../project after that
  # leaf's first apply — this repo has no Terragrunt `dependency` blocks
  # anywhere (ADR-0124), so cross-leaf references are wired by hand.
  project_id = "<project leaf's id output, filled in after it's applied>"
}
