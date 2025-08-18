#!/bin/sh
set -eu

entitlement="${1:-}"
justification="${2:-}"
duration="${3:-3600s}"

if [ $# -gt 3 ]; then
	echo "Too many arguments! Remember to quote your justification." >&2
	exit 1
fi

# Valid entitlements
set -- \
	cloudfunctions-developer \
	cloudrun-developer \
	cloudscheduler-admin \
	cloudsql-editor \
	cloudtask-admin \
	custom-cloud-storage-sign-url \
	errorreporting-user \
	firebase-admin \
	gke-production \
	monitoring-admin \
	pubsub-editor \
	redis-admin \
	storage-insights \
	storage-object-admin \
	suprema-oslogin \
	visionai-editor

if [ -z "$entitlement" ]; then
	echo "Missing entitlement as first argument! Must be one of $*" >&2
	exit 1
fi

chosen_entitlement=''
for valid_entitlement in "$@"; do
	if [ "$entitlement" = "$valid_entitlement" ]; then
		chosen_entitlement="$valid_entitlement"
		break
	fi
done

if [ -z "$chosen_entitlement" ]; then
	echo "Invalid entitlement '$entitlement'! Must be one of $*" >&2
fi

if [ -z "$justification" ]; then
	echo "Missing justification as second argument!" >&2
	exit 1
fi

duration_unit="$(printf "%s" "$duration" | tail -c 1)"
duration_amount="$(echo "$duration" | sed 's/.$//')"
case "$duration_unit" in
s)
	# seconds, no change needed
	;;
m)
	duration="$((duration_amount * 60))s"
	;;
h)
	duration="$((duration_amount * 3600))s"
	;;
*)
	echo "Invalid duration '$duration'! Must end with s, m, or h." >&2
	exit 1
	;;
esac

echo "Requesting entitlement '$chosen_entitlement' for $duration with justification: '$justification'"
gcloud pam grants create \
	--entitlement="$entitlement" \
	--requested-duration="$duration" \
	--justification="$justification" \
	--location=global \
	--project=26175511240
