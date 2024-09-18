#!/bin/sh

set -u

repository_path="$1"
my_github_name="$2"

tmpdir='/tmp/pr-review'
state_file="$tmpdir/state"

send_notification() {
	title=$1
	subtitle=$2
	url=$3

	chromium --window-name=pr-review --new-window "$url" >/dev/null 2>&1 &

	ACTION="$(dunstify --action="default,Open" --timeout=30000 "$title" "$subtitle")"

	case "$ACTION" in
	"default")
		# Middle click
		i3-msg workspace 10 >/dev/null 2>&1
		;;
	"2")
		# Left or right click
		i3-msg workspace 10 >/dev/null 2>&1
		;;
	esac
}

check() {
	all_prs="$(gh pr list --limit=30 --json url,title,author,createdAt,reviewRequests,reviews | jq -cr ".[] | select(.createdAt | fromdate > (now -3000000))")"

	filter_mine_reviewed="select(.author.login == \"$my_github_name\" and (.reviews | length > 0))"
	filter_review_requested="select(.reviewRequests | map(.login) | contains([\"$my_github_name\"]))"

	echo "$all_prs" | jq -c "$filter_review_requested" | while read -r line; do
		url=$(echo "$line" | jq -r '.url')

		if grep "^$url\$" "$state_file" >/dev/null 2>&1; then
			continue
		fi
		echo "$url" >>"$state_file"

		# id=$(echo $url | rev | cut -d'/' -f1 | rev)
		# authorName=$(echo $line | jq -r '.author.name')
		title=$(echo "$line" | jq -r '.title')
		author=$(echo "$line" | jq -r '.author.login')

		send_notification "Review: $title" "Author: $author" "$url" &
	done

	echo "$all_prs" | jq -c "$filter_mine_reviewed" | while read -r line; do
		url=$(echo "$line" | jq -r '.url')

		if grep "^$url\$" "$state_file" >/dev/null 2>&1; then
			continue
		fi
		echo "$url" >>"$state_file"

		# id=$(echo $url | rev | cut -d'/' -f1 | rev)
		# authorName=$(echo $line | jq -r '.author.name')
		title=$(echo "$line" | jq -r '.title')
		author=$(echo "$line" | jq -r '.author.login')

		send_notification "Merge: $title" "Author: $author" "$url" &
	done
}

mkdir -p "$tmpdir"

if ! cd "$repository_path"; then
	echo "Could not cd to '$repository_path'" >"$tmpdir/output"
	exit 1
fi

while true; do
	check >"$tmpdir/output" 2>&1
	sleep 20
done
