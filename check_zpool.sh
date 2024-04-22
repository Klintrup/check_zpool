#!/bin/sh
# NRPE check for zpool
# Written by: Søren Klintrup <github at klintrup.dk>
# Get your copy from https://github.com/Klintrup/check_zpool

PATH="/sbin:/bin:/usr/sbin:/usr/bin"
ERR="0"
unset ERRORSTRING
unset OKSTRING

validate_email() {
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

set_error_code() {
  current_error_code="${1}"
  new_error_code="${2}"
  if [ -z "${current_error_code}" ] || [ -z "${new_error_code}" ]; then
    echo "No error code or new error code given" >&2
    exit 1
  fi
  case "${new_error_code}" in
    ok)
      new_error_code=0
      ;;
    warning)
      new_error_code=1
      ;;
    error)
      new_error_code=2
      ;;
    unknown)
      new_error_code=3
      ;;
    [0-3])
      ;;
    *)
      echo "Invalid error code: ${new_error_code}" >&2
      exit 1
      ;;
  esac
  
  if [ "${new_error_code}" -eq 3 ]; then
    if [ "${current_error_code}" -eq 0 ]; then
      echo "${new_error_code}"
    else
      echo "${current_error_code}"
    fi
  elif [ "${current_error_code}" -lt "${new_error_code}" ]; then
    echo "${new_error_code}"
  else
    echo "${current_error_code}"
  fi
}

if [ -x "/sbin/zpool" ]; then
  DEVICES="$(zpool list -H -o name)"
else
  ERRORSTRING="zpool binary does not exist on system"
  ERR=3
fi

for DEVICE in ${DEVICES}; do
  DEVICESTRING="$(zpool list -H -o health "${DEVICE}")"
  if [ "$(echo "${DEVICESTRING}" | tr '[:upper:]' '[:lower:]' | sed -Ee 's/.*(degraded|faulted|suspended|offline|online|removed|unavail).*/\1/')" = "" ]; then
    ERRORSTRING="${ERRORSTRING} / ${DEVICE}: unknown state"
    ERR=$(set_error_code "${ERR}" "unknown")
  else
    case $(echo "${DEVICESTRING}" | tr '[:upper:]' '[:lower:]' | sed -Ee 's/.*(degraded|faulted|suspended|offline|online|removed|unavail).*/\1/') in
      degraded)
        ERR=$(set_error_code "${ERR}" "warning")
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: DEGRADED"
        ;;
      faulted)
        ERR=$(set_error_code "${ERR}" "error")
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: FAULTED"
        ;;
      offline)
        ERR=$(set_error_code "${ERR}" "error")
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: OFFLINE"
        ;;
      suspended)
        ERR=$(set_error_code "${ERR}" "error")
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: SUSPENDED"
        ;;
      removed)
        ERR=$(set_error_code "${ERR}" "error")
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: REMOVED"
        ;;
      unavail)
        ERR=$(set_error_code "${ERR}" "error")
        ERRORSTRING="${ERRORSTRING} / ${DEVICE}: UNAVAIL"
        ;;
      online)
        ERR=$(set_error_code "${ERR}" "ok")
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
    exit "${ERR}"
  else
    echo no zpool volumes found
    exit 3
  fi
fi
