# monitor zfs from nagios/NRPE or cron on FreeBSD

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/af682a2e5ff34d13b4fba76798eb37a8)](https://app.codacy.com/gh/Klintrup/check_zpool/dashboard)
[![License Apache 2.0](https://img.shields.io/github/license/Klintrup/check_zpool)](https://github.com/Klintrup/check_zpool/blob/main/LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/Klintrup/check_zpool)](https://github.com/Klintrup/check_zpool/releases)
[![Contributors](https://img.shields.io/github/contributors-anon/Klintrup/check_zpool)](https://github.com/Klintrup/check_zpool/graphs/contributors)
[![Issues](https://img.shields.io/github/issues/Klintrup/check_zpool)](https://github.com/Klintrup/check_zpool/issues)
[![build](https://img.shields.io/github/actions/workflow/status/Klintrup/check_zpool/shellcheck.yml)](https://github.com/Klintrup/check_zpool/actions/workflows/shellcheck.yml)

## Synopsis

Simple check-script for NRPE/nagios to get the status of various zpool volumes
in a box, and output the failed volumes if any such exist.

## Syntax

```bash
check_zpool.sh [email] [email]
```

If no arguments are specified, the script will assume its run for NRPE. If one
or more email addresses are specified, the script will send an email in case an
array reports an error.

## Output

`tank: DEGRADED / data: rebuilding / system: ok`

Failed/rebuilding volumes will always be first in the output string, to help
diagnose the problem when receiving the output via pager/sms.

## Output examples

| output        | description                                                                                                                     |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| ok            | The device is reported as ok by zpool                                                                                           |
| DEGRADED      | The RAID volume is degraded, it's still working but without the safety of RAID, and in some cases with severe performance loss. |
| rebuilding    | The RAID is rebuilding, will return to OK when done                                                                             |
| unknown state | Volume is in an unknown state. Please report this as an issue on [GitHub](https://github.com/Klintrup/check_zpool/issues)       |

## Compatibility

Should work on all versions of FreeBSD with zfs.

Tested on FreeBSD 8.0-10.1
