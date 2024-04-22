# monitor zfs from Cron/Zabbix/NRPE/Nagios

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/af682a2e5ff34d13b4fba76798eb37a8)](https://app.codacy.com/gh/Klintrup/check_zpool/dashboard)
[![License Apache 2.0](https://img.shields.io/github/license/Klintrup/check_zpool)](https://github.com/Klintrup/check_zpool/blob/main/LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/Klintrup/check_zpool)](https://github.com/Klintrup/check_zpool/releases)
[![Contributors](https://img.shields.io/github/contributors-anon/Klintrup/check_zpool)](https://github.com/Klintrup/check_zpool/graphs/contributors)
[![Issues](https://img.shields.io/github/issues/Klintrup/check_zpool)](https://github.com/Klintrup/check_zpool/issues)
[![build](https://img.shields.io/github/actions/workflow/status/Klintrup/check_zpool/shellcheck.yml)](https://github.com/Klintrup/check_zpool/actions/workflows/shellcheck.yml)

## Synopsis

Simple check-script for Cron/Zabbix/NRPE/Nagios to get the status of all zpool volumes
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

| output        | exit code | description                                                                                                               |
| ------------- | --------- | ------------------------------------------------------------------------------------------------------------------------- |
| ONLINE        | 0         | The device is online and functioning normally.                                                                            |
| DEGRADED      | 1         | The device is experiencing a non-fatal fault, which may be causing degraded performance.                                  |
| FAULTED       | 2         | An unrecoverable error has occurred. The device cannot be opened.                                                         |
| OFFLINE       | 2         | The device has been taken offline by the administrator.                                                                   |
| REMOVED       | 2         | The device was physically removed while the system was running.                                                           |
| UNAVAIL       | 2         | The device cannot be opened because the system is currently running a resilvering or scrubbing operation.                 |
| SUSPENDED     | 2         | The device is inaccessible, possibly because the system is in the process of resilvering or scrubbing the device.         |
| UNKNOWN STATE | 3         | Volume is in an unknown state. Please report this as an issue on [GitHub](https://github.com/Klintrup/check_zpool/issues) |

## Compatibility

Compatible with all versions of FreeBSD and Linux that support ZFS.

Specifically tested on FreeBSD 8.0+ and Ubuntu 22.04 LTS
