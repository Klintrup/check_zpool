#!/bin/sh
# NRPE check for zpool
# Written by: Søren Klintrup <github at klintrup.dk>
# Get your copy from https://github.com/Klintrup/check_zpool
# version 1.0

PATH="/sbin:/bin:/usr/sbin:/usr/bin"
DEVICES="$(zpool list -H -o name)"
unset ERRORSTRING
unset OKSTRING
unset ERR

for DEVICE in ${DEVICES}
do
 DEVICESTRING="$(zpool list -H -o health ${DEVICE})"
 if [ "$(echo ${DEVICESTRING}|tr [:upper:] [:lower:]|sed -Ee 's/.*(degraded|faulted|offline|online|removed|unavail).*/\1/')" = "" ]
 then
  ERRORSTRING="${ERRORSTRING} / ${DEVICE}: unknown state"
  if ! [ "${ERR}" = 2 ];then ERR=3;fi
 else
  case $(echo ${DEVICESTRING}|tr [:upper:] [:lower:]|sed -Ee 's/.*(degraded|faulted|offline|online|removed|unavail).*/\1/') in
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
   faulted)
    ERR=3
    ERRORSTRING="${ERRORSTRING} / ${DEVICE}: FAULTED"
    ;;
   online)
    OKSTRING="${OKSTRING} / ${DEVICE}: online"
    ;;
   esac
 fi
done
if [ "${ERRORSTRING}" -o "${OKSTRING}" ]
then
 echo ${ERRORSTRING} ${OKSTRING}|sed s/"^\/ "//
 exit ${ERR}
else
 echo no zpool volumes found
 exit 3
fi
