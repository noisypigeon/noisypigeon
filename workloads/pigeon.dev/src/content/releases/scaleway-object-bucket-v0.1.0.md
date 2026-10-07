+++
title = "scaleway/object-bucket v0.1.0"
date = 2026-09-26T12:00:00-07:00
slug = "scaleway-object-bucket-v0.1.0"
description = "Consolidate as terraform/modules/scaleway/object-bucket 0.1.0"
+++

A Scaleway Object Storage bucket (`scaleway_object_bucket`) with a
namespaced, randomized name (`{namespace}-{random}-{name}`, matching
`standard-storage-bucket`'s scheme), a versioning toggle
(`enable_versioning`), and a `storage_class` input (`standard`/`glacier`,
implemented via an immediate `lifecycle_rule` transition when set to
`glacier`). See
[ADR-0044](../../../../docs/adr/0044-add-scaleway-object-bucket-module.md)
and
[ADR-0045](../../../../docs/adr/0045-scaleway-object-bucket-namespaced-naming.md)
for the full set of decisions behind this module's design.

Consolidates this module's prior `pigeon-tf` version history (`v0.1.0`,
`v1.0.0`) into a single 0.1.0 release as part of merging `pigeon-tf` into
this repo — see
[ADR-0037](../../../../docs/adr/0037-merge-pigeon-tf-terraform-modules.md)
for the merge.
