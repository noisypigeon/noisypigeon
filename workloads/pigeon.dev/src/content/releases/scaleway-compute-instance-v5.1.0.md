+++
title = "scaleway/compute-instance v5.1.0"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-compute-instance-v5.1.0"
description = "Compose iam-policy and iam-api-key inside compute-instance"
+++

\`compute-instance\` gains an optional \`iam_config\` input that composes \`scaleway/iam-policy\` and \`scaleway/iam-api-key\` internally, exposing the resulting API key as new \`access_key_id\`/\`secret_key\` outputs.

A census of every real \`compute-instance\` consumer finds exactly one pairing with IAM, ever — \`pigeon-cli/job\` — and it always wires the same project-scoped policy + API key 1:1 with the same instance, composing them externally and passing the outputs through by hand. This is the same shape ADR-0120 found for \`block-volume\`, so this extends that same narrow exception to the "no internal composition" principle (ADR-0081/ADR-0085) to this pairing too.

\`iam_config\` is deliberately scoped to project-level grants only (\`project_ids\`/\`project_permission_sets\`), matching what the one real consumer actually uses — organization-scoped grants stay available only via external composition, same as \`block-volume\` remains independently callable for any caller not wanting it folded into \`compute-instance\`.

Unlike \`block-volume\`'s first landing, this composition pins released tags (\`iam-policy/v4.0.0\`, \`iam-api-key/v0.1.0\`) from the start rather than a relative path — ADR-0121 already root-caused why a relative \`source\` breaks once \`compute-instance\` itself is fetched over HTTP via its short URL.

This is purely additive: a new optional input defaulting to \`null\`, two new outputs. No existing consumer's behavior changes.

See ADR-0122 for the full decision record.

[#167](https://github.com/noisypigeon/noisypigeon/pull/167)
