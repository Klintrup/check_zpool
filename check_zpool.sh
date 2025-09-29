#!/usr/bin/env sh
# zpool monitoring script
# Written by: Søren Klintrup <github at klintrup.dk>
# Get your copy from https://github.com/Klintrup/check_zpool

set -u
set -e

PATH="/sbin:/bin:/usr/sbin:/usr/bin"
ERR="0"
ERRORSTRING=""
WARNINGSTRING=""
OKSTRING=""

# Function to validate email addresses
#
# This function takes one or more email addresses as input and validates them
# against a regular expression pattern. It checks if the email addresses are
# in the correct format: <username>@<domain>.<tld>
#
# Parameters:
#   One or more email addresses to validate
#
# Example usage:
#   validate_email "john.doe@example.com" "jane.smith@example.com"
#
# Returns:
#   - Valid email addresses are written to stdout
#   - Invalid email addresses are written to stderr along with an error message
validate_email() {
  for _check_zpool__validate_email__input in "${@}"; do
    if ! echo "${_check_zpool__validate_email__input}" | grep -qE '^[a-zA-Z0-9._%+-]{1,}@[a-zA-Z0-9.-]{1,}\.[a-zA-Z]{2,}$'; then
      echo "${_check_zpool__validate_email__input} is not a valid email address" >&2
    else
      echo "${_check_zpool__validate_email__input}"
    fi
  done
  unset _check_zpool__validate_email__input
}

# Function to set the error code
#
# This function sets the error code based on the current error code and the new error code provided.
# It validates the new error code and assigns the corresponding numeric value to it.
#
# Parameters:
#   The current error code
#   The new error code to be set. can be either numeric or a string
#
# Exit Codes:
#   0 - ok
#   1 - warning
#   2 - error
#   3 - unknown
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


# Checks if the zpool binary exists on the system and retrieves a list of devices if it does.
# If the zpool binary does not exist, an error message is assigned to the ERRORSTRING variable and the ERR variable is set to 3.
get_zpool_devices() {
  if [ -x "/sbin/zpool" ]; then
    zpool list -H -o name
  else
    ERRORSTRING="zpool binary does not exist on system"
    ERR=3
  fi
}

# Checks the health status of each device in a ZFS pool.
# Iterates over each device obtained from the `get_zpool_devices` function,
# and retrieves the health status using the `zpool list` command.
# The health status is then evaluated and categorized into different states,
# such as "unknown", "faulted", "offline", "suspended", "removed", "unavail",
# "degraded", and "online".
# Depending on the health status, the script sets an error code and appends
# the device name to the corresponding error or warning string.
# The final error and warning strings are stored in the variables `ERRORSTRING`
# and `WARNINGSTRING`, respectively.
# The error code is stored in the `ERR` variable.
for DEVICE in $(get_zpool_devices); do
  DEVICESTRING="$(zpool list -H -o health "${DEVICE}")"
  if [ "$(echo "${DEVICESTRING}" | tr '[:upper:]' '[:lower:]' | sed -Ee 's/.*(degraded|faulted|suspended|offline|online|removed|unavail).*/\1/')" = "" ]; then
    ERRORSTRING="${ERRORSTRING} / ${DEVICE}: UNKNOWN"
    ERR=$(set_error_code "${ERR}" "unknown")
  else
    case $(echo "${DEVICESTRING}" | tr '[:upper:]' '[:lower:]' | sed -Ee 's/.*(degraded|faulted|suspended|offline|online|removed|unavail).*/\1/') in
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
      degraded)
        ERR=$(set_error_code "${ERR}" "warning")
        WARNINGSTRING="${WARNINGSTRING} / ${DEVICE}: degraded"
        ;;
      online)
        ERR=$(set_error_code "${ERR}" "ok")
        OKSTRING="${OKSTRING} / ${DEVICE}: online"
        ;;
    esac
  fi
done

# Checks the status of zpool volumes on the current host and sends an email notification if there are any errors.
# If the script is called with an argument, it assumes that it is being run from cron, and sends an email notification to the specified recipients.
# If the script is called without an argument, it assumes that it is being run from a monitoring system, prints the status of the zpool volumes to the console, and exits with the corresponding error code.
if [ "${#}" -ge "1" ]; then
  if [ "${ERRORSTRING}" ] || [ "${WARNINGSTRING}" ]; then
    if ! command -v mail >/dev/null 2>&1; then
      echo "mail command is not installed" >&2
      ERR=$(set_error_code "${ERR}" "unknown")
      exit "${ERR}"
    fi
    recipients=$(validate_email "${@}")
    (
      echo "zpool volumes on $(hostname -s) has errors:"
      echo ""
      echo "${ERRORSTRING} ${WARNINGSTRING} ${OKSTRING}" | sed s/"^\/ "// | sed -E "s%\/ %\n%g"
      echo ""
      echo "This is an automated message, do not reply."
    ) | mail -s "$(hostname -s): ${0} reports errors" -E "${recipients}"
  fi
else
  if [ "${ERRORSTRING}" ] || [ "${OKSTRING}" ] || [ "${WARNINGSTRING}" ]; then
    echo "${ERRORSTRING} ${WARNINGSTRING} ${OKSTRING}" | sed -E s/"^[[:blank:]]{1,}\/ "//
    exit "${ERR}"
  else
    echo no zpool volumes found
    ERR=$(set_error_code "${ERR}" "unknown")
    exit "${ERR}"
  fi
fi
