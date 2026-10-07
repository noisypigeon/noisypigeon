+++
title = "scaleway/object-bucket v0.2.0"
date = 2026-09-30T12:00:00-07:00
slug = "scaleway-object-bucket-v0.2.0"
description = "Add force_destroy input to object-bucket"
+++

Adds a `force_destroy` input to the `scaleway/object-bucket` module, wired straight through to `scaleway_object_bucket`'s `force_destroy` argument. When set to `true`, this allows Terraform to delete all objects in the bucket (including locked objects) as part of destroying the bucket itself, rather than failing because the bucket isn't empty.

Defaults to `false`, matching the underlying provider's default, so existing callers of this module are unaffected unless they opt in.

[#101](https://github.com/noisypigeon/noisypigeon/pull/101)
