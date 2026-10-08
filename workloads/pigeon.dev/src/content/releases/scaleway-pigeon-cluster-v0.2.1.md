+++
title = "scaleway/pigeon-cluster v0.2.1"
date = 2026-10-07T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v0.2.1"
description = "Fix pigeon-cluster job_policy name colliding with compute-instance's internal policy"
+++

`v0.2.0` (ADR-0144) gave each `pigeon-cluster` job its own \`job_policy\`, named \`"\${name_prefix}-\${job}-iam-policy"\`. That's the exact same formula `compute-instance`'s own internal self-delete \`iam_policy\` composition already uses for the same job -- both resolve to the identical final Scaleway policy name once `iam-policy`'s own \`-policy\` suffix is applied. Scaleway rejects the second create with a 409 (\`resource policy: resource already exists\`), confirmed live against a real \`terragrunt apply\` of \`v0.2.0\`.

\`job_policy\`'s name now gets a distinct \`-work-\` segment so the two policies -- one scoped to the job's actual work permissions (object storage, etc.), one scoped to just self-delete -- coexist without colliding.

No interface change, no consumer update needed beyond bumping the version pin.

[#242](https://github.com/noisypigeon/noisypigeon/pull/242)
