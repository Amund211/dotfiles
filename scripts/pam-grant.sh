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
set -- cloudfunctions-developer cloudrun-developer cloudsql-editor conda-oslogin custom-cloud-storage-sign-url firebase-admin gke-production monitoring-admin pubsub-editor storage-insights

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

echo "Requesting entitlement '$chosen_entitlement' for $duration with justification: '$justification'"
gcloud pam grants create \
	--entitlement="$entitlement" \
	--requested-duration="$duration" \
	--justification="$justification" \
	--location=global \
	--project=26175511240
