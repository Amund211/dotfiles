#!/bin/sh
set -eu

ENTITLEMENT='bigquery-viewer'

# ignite-{substring(tenant, 14)}-{substring(sha256(tenant), 8)}
project_id_from_tenant() {
	tenant="${1:-}"
	if [ -z "$tenant" ]; then
		echo "project_id_from_tenant: Missing tenant as first argument!" >&2
		exit 1
	fi

	tenant_hash=$(printf "%s" "$tenant" | shasum -a 256 | cut -c 1-8)
	tenant_substring=$(printf "%s" "$tenant" | cut -c 1-14)
	echo "ignite-$tenant_substring-$tenant_hash"
}
# Tests
if [ "$(project_id_from_tenant 'ignitekpis')" != 'ignite-ignitekpis-7f659168' ]; then
	echo 'Got unexpected project ID for ignitekpis!' >&2
	echo "$(project_id_from_tenant 'ignitekpis') != ignite-ignitekpis-7f659168" >&2
	exit 1
fi

usage() {
	cat <<'EOF'
Usage: customers-pam.sh <tenant[,tenant...]> <justification> [duration]

Request the 'bigquery-viewer' PAM grant on one or more tenant projects.

  tenant         Tenant id. Separate multiple with commas.
  justification  Reason for access. Quote it.
  duration       Number ending in s, m or h. Default: 3600s.

Example:
  customers-pam.sh 'ignitekpis,demosales' 'Investigating X' 2h
EOF
}

case "${1:-}" in
-h | --help)
	usage
	exit 0
	;;
esac

tenants="${1:-}"
justification="${2:-}"
duration="${3:-3600s}"

if [ $# -gt 3 ]; then
	echo "Too many arguments! Remember to quote your justification." >&2
	exit 1
fi

if [ -z "$tenants" ]; then
	echo "Missing tenant(s) as first argument! Separate multiple with commas." >&2
	exit 1
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

failed=''
set -f
IFS=','
for tenant in $tenants; do
	unset IFS
	[ -z "$tenant" ] && continue
	echo "Requesting '$ENTITLEMENT' on '$tenant' for $duration with justification: '$justification'"
	gcloud pam grants create \
		--entitlement="$ENTITLEMENT" \
		--requested-duration="$duration" \
		--justification="$justification" \
		--location=global \
		--project="$(project_id_from_tenant "$tenant")" ||
		failed="$failed $tenant"
done
unset IFS
set +f

if [ -n "$failed" ]; then
	echo "Failed for:$failed" >&2
	exit 1
fi
