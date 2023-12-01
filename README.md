# monitor zfs from nagios/NRPE or cron on FreeBSD

## Synopsis

Simple check-script for nrpe/nagios to get the status of various zpool volumes in a box, and output the failed volumes if any such exist.

## Syntax

``` bash
check_zpool.sh [email] [email]
```

If no arguments are specified, the script will assume its run for NRPE. If one or more email addresses are specified, the script will send an email in case an array reports an error.

## Output

`tank: DEGRADED / data: rebuilding / system: ok`

Failed/rebuilding volumes will always be first in the output string, to help diagnose the problem when recieving the output via pager/sms.

## Output examples

| output | description |
| -- | -- |
| ok | The device is reported as ok by zpool |
| DEGRADED | The RAID volume is degraded, it's still working but without the safety of RAID, and in some cases with severe performance loss. |
| rebuilding | The RAID is rebuilding, will return to OK when done |
| unknown state | Volume is in an unknown state. Please report this as an issue on [GitHub](https://github.com/Klintrup/check_zpool/issues) |

## Compability

Should work on all versions of FreeBSD with zfs.

Tested on FreeBSD 8.0-9.0