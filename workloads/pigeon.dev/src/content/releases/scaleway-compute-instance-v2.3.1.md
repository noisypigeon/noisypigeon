+++
title = "scaleway/compute-instance v2.3.1"
date = 2026-10-03T12:00:00-07:00
slug = "scaleway-compute-instance-v2.3.1"
description = "Fix alloy install failing on a dpkg conffile prompt in compute-instance"
+++

ADR-0102's `cockpit` wiring (v2.3.0) writes `/etc/alloy/config.alloy` via cloud-init `write_files` before `runcmd` installs the `alloy` package. The `alloy` `.deb` also ships `/etc/alloy/config.alloy` as a conffile, so `dpkg` detects the pre-existing file and tries to prompt interactively asking whether to keep it or take the package's default. cloud-init's `runcmd` script has no attached stdin, so dpkg hits EOF on the prompt and aborts configuring the package — `alloy.service` is left half-installed and fails to start (`Result: resources`), confirmed live against a real applied test-bed instance (`cloud-init status --long` showed `Runparts: 1 failures (runcmd)`, and `/var/log/cloud-init-output.log` showed the exact `*** config.alloy (Y/I/N/O/D/Z)` prompt followed by `end of file on stdin at conffile prompt`).

Fix: pass dpkg's `--force-confold` option (keep the already-present file, don't prompt) to the `alloy` install, plus `DEBIAN_FRONTEND=noninteractive` for good measure. This is exactly the outcome we want, since the whole point of pre-writing the file was to have our rendered config win over the package's default.

Patch release — no input/output/behavior change beyond fixing a previously-broken case.

[#130](https://github.com/noisypigeon/noisypigeon/pull/130)
