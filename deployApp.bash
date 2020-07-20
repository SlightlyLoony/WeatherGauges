source scripts/deploy/common.bash
bash scripts/deploy/deployApp.bash weathergauges
bash scripts/deploy/deploySite.bash weathergauges
echo "sudo systemctl restart weathergauges.service" | _ssh "weathergauges" "weathergauges" && true; EC=$?
echo $?

