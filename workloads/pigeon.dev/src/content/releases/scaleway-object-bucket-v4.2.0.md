+++
title = "scaleway/object-bucket v4.2.0"
date = 2026-10-10T12:00:00-07:00
slug = "scaleway-object-bucket-v4.2.0"
description = "Add optional expiration_days lifecycle rule to object-bucket"
+++

Adds an optional `expiration_days` input that deletes objects a fixed number of days after creation, for buckets holding short-lived artifacts that should not accumulate indefinitely.

```hcl
module "bucket" {
  source          = "https://pigeon.dev/modules/scaleway/object-bucket/v4.2.0"
  name_prefix     = "pigeon-cli"
  name_suffix     = "reports"
  storage_class   = "standard"
  expiration_days = 3
}
```

`null` is the default and adds no expiration rule at all, so every existing consumer is unaffected. A validation rejects anything below `1`, the API's own minimum.

**Expiration is day-granular — there is no hour-level option.** This is worth stating plainly because it is a common expectation. Confirmed against the provider schema, `lifecycle_rule.expiration` offers only `days`, `date` (an absolute midnight-UTC timestamp, not a duration), and `expired_object_delete_marker`. That is a property of the S3 lifecycle API the provider wraps rather than a provider gap, so no upgrade changes it. A 72-hour retention is therefore expressed as `expiration_days = 3`. The input is deliberately named in days rather than hours so it cannot imply a precision it does not have.

**Interaction with `storage_class`.** The rule is emitted as a second, independent `lifecycle_rule` rather than being folded into the existing glacier transition, which is gated on `storage_class == "glacier"` — a `standard` bucket asking for expiration would otherwise get no rule block at all. The existing glacier rule is unchanged, so buckets not setting `expiration_days` see no plan diff.

Note the two are independent, and a short expiration makes the glacier transition moot: `storage_class` defaults to `"glacier"`, whose transition is fixed at 90 days, so any expiration shorter than that deletes objects before the transition could ever fire. Pair a short expiration with `storage_class = "standard"`.

The new rule carries a static `id` of `expire-objects`, so changing the retention is an in-place rule update rather than a rule replacement. It is the module's first explicit rule `id`; with two rules now able to coexist, leaving both to the provider's generated-ID behavior would be a needless unknown.

Recorded in [ADR-0151](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0151-rename-enable-transcoding-and-object-bucket-expiration.md).

[#262](https://github.com/noisypigeon/noisypigeon/pull/262)
