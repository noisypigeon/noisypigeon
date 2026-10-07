+++
title = "scaleway/iam-policy v2.0.1"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-iam-policy-v2.0.1"
description = "Shorten iam-policy generated application name suffix"
+++

Changes the generated \`scaleway_iam_application\` name from \`${var.name}-application\` to \`${var.name}-app\`, keeping names shorter and more consistent with other modules' naming conventions.

This updates the application's \`name\` attribute for every existing consumer of this module on next apply — no input or output changes.

[#134](https://github.com/noisypigeon/noisypigeon/pull/134)
