+++
title = "scaleway/pigeon-cluster v0.2.0"
date = 2026-10-07T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v0.2.0"
description = "Give pigeon-cluster jobs their own IAM policy/key and a dictionary keyring"
+++

Each job in a `pigeon-cluster` fleet already got its own `iam-application`, but the policy and API key it actually ran with were composed two layers down inside `compute-instance`, purely to power that instance's self-delete call -- invisible to `pigeon-cluster` itself. In practice, that meant every keyring entry's `access_key_id`/`secret_key` had to be hand-supplied by the caller, usually by wiring in one shared key from outside the module.

`pigeon-cluster` now composes its own `iam-policy`/`iam-api-key` directly, one pair per job, scoped to that job's `extra_permission_sets` plus a new cluster-wide `shared_permission_sets`. That key becomes the default credential for any `kind = "bucket"` keyring entry that doesn't specify its own -- an entry can still override it explicitly to reach a bucket under a different, pre-existing auth stack.

`keyring` itself changes from a list to a map keyed by alias (the `alias` field is gone -- the map key is the alias now), which lets `job_commands` reference an entry by name instead of a hand-typed, unchecked literal: `"--source '${keyring.fastmail.alias}:'"` instead of `"--source 'fastmail:'"`. If the alias doesn't exist in that job's merged keyring, `terraform plan` fails outright instead of silently drifting. `cluster_config` also gains a `shared_keyring`, so a bucket every job needs (a shared `reports` destination, say) only needs declaring once.

One side effect worth calling out: `compute-instance`'s own internally-composed key (used solely for `self_delete_on_exit`) now carries only the instance-management permission it needs for that, instead of also carrying the job's full work permissions -- a smaller blast radius per key, split across two keys instead of one doing both jobs.

No changes to `compute-instance` or any `iam-*` module -- this is entirely a composition change inside `pigeon-cluster`. See ADR-0144 for the full design, including the circular-reference constraint that requires the new key to be minted inside `pigeon-cluster` rather than inside `compute-instance` (a module can't default its own input from its own output).

This PR intentionally does not migrate any real job leaf onto the new interface -- that's a separate, not-yet-opened change.

[#241](https://github.com/noisypigeon/noisypigeon/pull/241)
