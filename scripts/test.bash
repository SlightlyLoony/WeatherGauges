# $1 is remote user
# $2 is remote host
# $3 is local source path (globbable)
# $4 is remote destination path
_scp_to_remote() {
  scp -q -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$3" "$1"@"$2":"$4" 2>/dev/null
}


# $1 is remote user
# $2 is remote host
# $3 is remote source path (globbable)
# $4 is local destination path
_scp_from_remote() {
  scp -q -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1"@"$2":"$3" "$4" 2>/dev/null
}

_scp_to_remote pi weathergauges ../scripts /home/pi
