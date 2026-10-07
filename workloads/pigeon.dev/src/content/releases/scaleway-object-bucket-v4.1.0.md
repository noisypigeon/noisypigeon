+++
title = "scaleway/object-bucket v4.1.0"
date = 2026-10-05T12:00:00-07:00
slug = "scaleway-object-bucket-v4.1.0"
description = "Add exact_name, website hosting, and public-read ACL to object-bucket"
+++

Adds three independent, backwards-compatible capabilities to `object-bucket`, all off by default:

- **`exact_name`**: bypasses the `name_prefix`/random-suffix/`name_suffix` naming scheme entirely for buckets whose name must match something external — most notably Scaleway bucket-website hosting, where the bucket name has to match a custom domain. A validation block enforces that you set either `exact_name`, or both `name_prefix` and `name_suffix` — never a mix. The underlying `random_string.suffix` resource moves from a singleton to a `count`-based one (only created when `exact_name` is unset), with a `moved` block so existing consumers using the prefix/suffix scheme see no plan diff.
- **`enable_website`** (plus `website_index_document`/`website_error_document`, and a new `website_endpoint` output): configures the bucket for static website hosting via `scaleway_object_bucket_website_configuration`.
- **`enable_public_read`**: grants the bucket a `public-read` ACL via `scaleway_object_bucket_acl`, needed for a website-hosting bucket's objects to actually be servable.

Also adds an optional `project_id` input (defaults to the provider's own project when unset), for buckets that need to live in a specific project.

None of this changes any existing consumer's behavior — every new input defaults to `null`/`false`, and the `moved` block keeps the `name_prefix`/`name_suffix` naming path's plan clean.

[#194](https://github.com/noisypigeon/noisypigeon/pull/194)
