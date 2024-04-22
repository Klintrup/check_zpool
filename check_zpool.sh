#!/bin/sh
# NRPE check for zpool
# Written by: Søren Klintrup <github at klintrup.dk>
# Get your copy from https://github.com/Klintrup/check_zpool

PATH="/sbin:/bin:/usr/sbin:/usr/bin"
unset ERRORSTRING
unset OKSTRING
unset ERR

_validate_email() {
  if [ -n "$_validate_email__input" ]; then
    echo "_validate_email__input variable is already set" >&2
    exit 1
  fi
  for _validate_email__input in "$@"; do
    if ! echo "$_validate_email__input" | grep -qE '^[a-zA-Z0-9._%+-]{1,}@[a-zA-Z0-9.-]{1,}\.[a-zA-Z]{2,}$'; then
      echo "$_validate_email__input is not a valid email address" >&2
    else
      echo "$_validate_email__input"
    fi
  done
}

if [ -x "/sbin/zpool" ]; then
  DEVICES="$(zpool list -H -o name)"
else
  ERRORSTRING="zpool binary does not exist on system"
  ERR=3
fi

for DEVICE in ${DEVICES}; do
  DEVICESTRING="$(zpool list -H -o health "${DEVICE}")"
  if [ "$(echo "${DEVICESTRING}" | tr '[:upper:]' '[:lower:]' | sed -Ee 's/.*(degraded|faulted|offline|online|removed|unavail).*/\1/')" = "" ]; then
    ERRORSTRING="${ERRORSTRING} / ${DEVICE}: unknown state"
    if ! [ "${ERR}" = 2 ]; then ERR=3; fi
  else
    case $(echo "${DEVICESTRING}" | tr '[:upper:]' '[:lower:]' | sed -Ee 's/.*(degraded|faulted|offline|online|removed|unavail).*/\1/') in
      degraded)
        ERR=2
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: DEGRADED"
        ;;
      faulted)
        ERR=2
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: FAULTED"
        ;;
      offline)
        ERR=2
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: OFFLINE"
        ;;
      removed)
        ERR=2
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: REMOVED"
        ;;
      unavail)
        ERR=2
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: UNAVAIL"
        ;;
      online)
        OKSTRING="${OKSTRING} / ${DEVICE}: online"
        ;;
    esac
  fi
done

if [ "${1}" ]; then
  if [ "${ERRORSTRING}" ]; then
    recipients=$(validate_email "${@}")
    echo "${ERRORSTRING} ${OKSTRING}" | sed s/"^\/ "// | mail -s "$(hostname -s): ${0} reports errors" -E "${recipients}"
  fi
else
  if [ "${ERRORSTRING}" ] || [ "${OKSTRING}" ]; then
    echo "${ERRORSTRING} ${OKSTRING}" | sed -E s/"^[[:blank:]]{1,}\/ "//
    exit ${ERR}
  else
    echo no zpool volumes found
    exit 3
  fi
fi
