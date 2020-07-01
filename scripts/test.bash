_ssh() {
  local SSH
  read -r -d '' SSH
  ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$1"@"$2" "$SSH" 2>/dev/null
}


IMAGE_ID=$(_ssh pi weathergauges << EOF
  cat /ImageID
EOF
)
EC=$?
if (( EC == 0 ))
then
  if [[ $IMAGE_ID == "Weather Gauges 1" ]]
  then
    echo "We're good!"
  else
    echo "Oh, oh - we don't know this image ID: ${IMAGE_ID}"
  fi
else
  echo "Bad things just happened, SSH returned exit code ${EC} when attempting to get image ID"
fi
