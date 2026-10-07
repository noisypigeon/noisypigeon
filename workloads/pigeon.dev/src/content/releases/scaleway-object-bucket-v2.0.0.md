+++
title = "scaleway/object-bucket v2.0.0"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-object-bucket-v2.0.0"
description = "Fix object-bucket endpoint output to use the regional host, not the bucket vhost"
+++

The \`endpoint\` output previously returned \`scaleway_object_bucket.bucket.endpoint\`, which Scaleway's provider resolves to a bucket-specific virtual-hosted URL (bucket name baked into the host). Every known consumer of this output (e.g. the \`rclone\` wiring in \`scaleway/compute-instance\`) expects a bare regional S3 endpoint, with the bucket name supplied separately — so the old value didn't actually work for that use case.

This output is now computed directly from \`scaleway_object_bucket.bucket.region\` instead, returning \`https://s3.<region>.scw.cloud\`.

Any consumer that was relying on the bucket name being embedded in this URL will need to append it themselves going forward.

[#135](https://github.com/noisypigeon/noisypigeon/pull/135)
