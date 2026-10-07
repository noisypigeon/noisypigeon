+++
title = "scaleway/project v0.2.1"
date = 2026-09-30T12:00:00-07:00
slug = "scaleway-project-v0.2.1"
description = "Fix scaleway/project ssh_key to scope to the created project"
+++

`scaleway/project`'s `scaleway_iam_ssh_key` resource (added in v0.2.0) was missing `project_id`, so it registered the SSH key against the Scaleway provider's default project rather than the project this module just created. This adds `project_id = scaleway_account_project.project.id` so the key is correctly scoped to the module's own project.

No input or output changes — this only fixes the behavior of the existing `ssh_key` input.

[#107](https://github.com/noisypigeon/noisypigeon/pull/107)
