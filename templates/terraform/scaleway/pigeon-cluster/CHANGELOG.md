# Changelog

All notable changes to this module are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-10-07

### Add pigeon-cluster module

New module: composes one `scaleway/iam-application` + one `scaleway/compute-instance` (with `self_delete_on_exit = true`) per entry in `var.jobs`, scaling the fleet to however many jobs are pending instead of one hand-wired leaf per job. Each job gets its own IAM scope (`extra_permission_sets`) and its own `keyring`, isolated from every other job in the same cluster -- a compromised or misbehaving job instance's blast radius never extends to a sibling job's credentials.

This is a broader use of the "modules don't compose modules, except..." exception ADR-0122 already carved out narrowly for `compute-instance` composing `block-volume`/`iam-policy`/`iam-api-key` (always 1:1) -- here one module composes N copies of another. Acknowledged explicitly rather than silently reused at a different scale.

Removing an entry from `var.jobs` and re-applying is how a finished job's Terraform state gets reconciled after its instance self-deletes -- this module does not automatically detect or prune completed jobs.

See ADR-0138 (`Status: Exploration`).
