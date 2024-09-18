#!/bin/bash

set -u

# "/usr/lib/git-core/git" --exec-path="/usr/lib/git-core" for-each-repo --config=maintenance.repo maintenance run --schedule=hourly
# "/usr/lib/git-core/git" --exec-path="/usr/lib/git-core" for-each-repo --config=maintenance.repo maintenance run --schedule=daily
# "/usr/lib/git-core/git" --exec-path="/usr/lib/git-core" for-each-repo --config=maintenance.repo maintenance run --schedule=weekly

RUN_MAINTENANCE='/usr/lib/git-core/git --exec-path="/usr/lib/git-core" for-each-repo --config=maintenance.repo maintenance run'
LOG=/tmp/custom-git-maintenance.log
PERIOD=1800

if_its_time() {
	result="$(($RANDOM % $2))"
	if [ $result -eq 0 ]; then
		echo "$(date --iso=seconds): Running '$1'" >>$LOG
		$1 &>>$LOG
		echo "$(date --iso=seconds): Completed '$1'" >>$LOG
		echo >>$LOG
	else
		echo "Skipping '$1': $result" >>$LOG
	fi
}

echo "$(date --iso=seconds): Starting loop" >>$LOG

while true; do
	if_its_time "$RUN_MAINTENANCE --schedule=hourly" 1
	if_its_time "$RUN_MAINTENANCE --schedule=daily" 8
	if_its_time "$RUN_MAINTENANCE --schedule=weekly" 40
	sleep $PERIOD
done
