#!/bin/sh

set -u

if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
	echo "Usage: $0 [ -t | --test ] <repository-path> <my-github-name>"
	echo "  -t, --test    Run tests only"
	echo "  <repository-path>  Path to the local git repository"
	echo "  <my-github-name>   Your GitHub username"
	exit 0
fi

filter_review_requested() {
	github_username="${1:-}"
	if [ -z "$github_username" ]; then
		echo "No github name provided" >&2
		exit 1
	fi

	filter="select(.reviewRequests | map(.login) | contains([\"$github_username\"]))"

	jq -c "$filter"
}

filter_reviewed() {
	github_username="${1:-}"
	if [ -z "$github_username" ]; then
		echo "No github name provided" >&2
		exit 1
	fi

	filter="select(.author.login == \"$github_username\" and any(.reviews[]; .author.login != \"$github_username\" and .author.login != \"copilot-pull-request-reviewer\" and .author.login != \"cursor\"))"

	jq -c "$filter"
}

run_test() {
	test_name="${1:-}"
	if [ -z "$test_name" ]; then
		echo "ERROR: No test name provided" >&2
		return 1
	fi
	test_input="${2:-}"
	if [ -z "$test_input" ]; then
		echo "ERROR: No test input provided - $test_name" >&2
		return 1
	fi
	function_name="${3:-}"
	if [ -z "$function_name" ]; then
		echo "ERROR: No function name provided - $test_name" >&2
		return 1
	fi
	github_username="${4:-}"
	if [ -z "$github_username" ]; then
		echo "ERROR: No github username provided - $test_name" >&2
		return 1
	fi
	expected_output="${5:-}"
	if [ -z "$expected_output" ]; then
		echo "ERROR: No expected output provided - $test_name" >&2
		return 1
	fi
	if [ "$expected_output" != '0' ] && [ "$expected_output" != '1' ]; then
		echo "ERROR: Expected output must be 0 or 1 - $test_name" >&2
		return 1
	fi

	actual_output="$(echo "$test_input" | "$function_name" "$github_username" | wc -l)"
	if [ "$actual_output" = "$expected_output" ]; then
		echo "PASS: $test_name" >&2
	else
		echo "FAIL: $test_name" >&2
		return 1
	fi
}

tests() {
	not_reviewed='{
  "author": {
    "id": "some-id",
    "is_bot": false,
    "login": "Amund211",
    "name": "name"
  },
  "createdAt": "2025-03-07T08:21:50Z",
  "reviewRequests": [
    {
      "__typename": "Team",
      "name": "team name",
      "slug": "org/team-name"
    },
    {
      "__typename": "User",
      "login": "username"
    }
  ],
  "reviews": [],
  "title": "do something",
  "url": "https://github.com/org/repo/pull/1234"
}'
	if ! run_test 'not_reviewed -> exclude' "$not_reviewed" 'filter_reviewed' 'Amund211' '0'; then
		return 1
	fi

	reviewed_by_human='{
  "author": {
    "id": "some-id",
    "is_bot": false,
    "login": "Amund211",
    "name": "name"
  },
  "createdAt": "2025-03-06T11:20:04Z",
  "reviewRequests": [
    {
      "__typename": "Team",
      "name": "team name",
      "slug": "org/team-name"
    },
    {
      "__typename": "User",
      "login": "username"
    }
  ],
  "reviews": [
    {
      "id": "PRR_some-id",
      "author": {
        "login": "some-username"
      },
      "authorAssociation": "MEMBER",
      "body": "",
      "submittedAt": "2025-03-06T10:02:34Z",
      "includesCreatedEdit": false,
      "reactionGroups": [],
      "state": "APPROVED",
      "commit": {
        "oid": "some-id"
      }
    }
  ],
  "title": "some-title",
  "url": "https://github.com/org/repo/pull/1234"
}'
	if ! run_test 'reviewed_by_human -> include' "$reviewed_by_human" 'filter_reviewed' 'Amund211' '1'; then
		return 1
	fi

	if ! run_test 'reviewed_by_human, not mine -> exclude' "$reviewed_by_human" 'filter_reviewed' 'someone-else' '0'; then
		return 1
	fi

	reviewed_by_copilot='{
  "author": {
    "id": "some-id",
    "is_bot": false,
    "login": "Amund211",
    "name": "name"
  },
  "createdAt": "2025-03-06T11:20:04Z",
  "reviewRequests": [
    {
      "__typename": "Team",
      "name": "team name",
      "slug": "org/team-name"
    },
    {
      "__typename": "User",
      "login": "username"
    }
  ],
  "reviews": [
    {
      "id": "PRR_some-id",
      "author": {
        "login": "copilot-pull-request-reviewer"
      },
      "authorAssociation": "NONE",
      "body": "## PR Overview\n\nThis PR fixes issues related to ...",
      "submittedAt": "2025-03-06T11:33:03Z",
      "includesCreatedEdit": false,
      "reactionGroups": [],
      "state": "COMMENTED",
      "commit": {
        "oid": "some-id"
      }
    }
  ],
  "title": "some-title",
  "url": "https://github.com/org/repo/pull/1234"
}'
	if ! run_test 'reviewed_by_copilot -> exclude' "$reviewed_by_copilot" 'filter_reviewed' 'Amund211' '0'; then
		return 1
	fi

	reviewed_by_copilot_and_human='{
  "author": {
    "id": "some-id",
    "is_bot": false,
    "login": "Amund211",
    "name": "name"
  },
  "createdAt": "2025-03-07T13:47:23Z",
  "reviewRequests": [],
  "reviews": [
    {
      "id": "PRR_kwDOBpQFF86e-_NI",
      "author": {
        "login": "copilot-pull-request-reviewer"
      },
      "authorAssociation": "NONE",
      "body": "some comment",
      "submittedAt": "2025-03-07T13:48:45Z",
      "includesCreatedEdit": false,
      "reactionGroups": [],
      "state": "COMMENTED",
      "commit": {
        "oid": "some-id"
      }
    },
    {
      "id": "PRR_some-id",
      "author": {
        "login": "human-reviewer"
      },
      "authorAssociation": "MEMBER",
      "body": "",
      "submittedAt": "2025-03-07T13:59:30Z",
      "includesCreatedEdit": false,
      "reactionGroups": [],
      "state": "APPROVED",
      "commit": {
        "oid": "some-id"
      }
    }
  ],
  "title": "some-title",
  "url": "https://github.com/org/repo/pull/1234"
}'
	if ! run_test 'reviewed_by_copilot_and_human -> include' "$reviewed_by_copilot_and_human" 'filter_reviewed' 'Amund211' '1'; then
		return 1
	fi

	reviewed_by_cursor_bot='{
  "author": {
    "id": "some-id",
    "is_bot": false,
    "login": "Amund211",
    "name": "name"
  },
  "createdAt": "2025-03-06T11:20:04Z",
  "reviewRequests": [
    {
      "__typename": "Team",
      "name": "team name",
      "slug": "org/team-name"
    },
    {
      "__typename": "User",
      "login": "username"
    }
  ],
  "reviews": [
    {
      "id": "PRR_some-id",
      "author": {
        "login": "cursor"
      },
      "authorAssociation": "NONE",
      "body": "## PR Overview\n\nThis PR fixes issues related to ...",
      "submittedAt": "2025-03-06T11:33:03Z",
      "includesCreatedEdit": false,
      "reactionGroups": [],
      "state": "COMMENTED",
      "commit": {
        "oid": "some-id"
      }
    }
  ],
  "title": "some-title",
  "url": "https://github.com/org/repo/pull/1234"
}'
	if ! run_test 'reviewed_by_cursor_bot -> exclude' "$reviewed_by_cursor_bot" 'filter_reviewed' 'Amund211' '0'; then
		return 1
	fi

	review_requested_from_you='{
  "author": {
    "id": "id",
    "is_bot": false,
    "login": "author-username",
    "name": "author name"
  },
  "createdAt": "2025-03-07T11:28:30Z",
  "reviewRequests": [
    {
      "__typename": "User",
      "login": "Amund211"
    }
  ],
  "reviews": [],
  "title": "some-title",
  "url": "https://github.com/org/repo/pull/1234"
}'
	if ! run_test 'review_requested_from_you -> include' "$review_requested_from_you" 'filter_review_requested' 'Amund211' '1'; then
		return 1
	fi

	review_requested_from_someone_else='{
  "author": {
    "id": "id",
    "is_bot": false,
    "login": "author-username",
    "name": "author name"
  },
  "createdAt": "2025-03-07T11:28:30Z",
  "reviewRequests": [
    {
      "__typename": "User",
      "login": "someone-else"
    }
  ],
  "reviews": [],
  "title": "some-title",
  "url": "https://github.com/org/repo/pull/1234"
}'
	if ! run_test 'review_requested_from_someone_else -> exclude' "$review_requested_from_someone_else" 'filter_review_requested' 'Amund211' '0'; then
		return 1
	fi

	review_requested_from_no_one='{
  "author": {
    "id": "id",
    "is_bot": false,
    "login": "author-username",
    "name": "author name"
  },
  "createdAt": "2025-03-07T11:28:30Z",
  "reviewRequests": [],
  "reviews": [],
  "title": "some-title",
  "url": "https://github.com/org/repo/pull/1234"
}'
	if ! run_test 'review_requested_from_no_one -> include' "$review_requested_from_no_one" 'filter_review_requested' 'Amund211' '0'; then
		return 1
	fi
}

if ! tests; then
	echo "Tests failed" >&2
	dunstify --timeout=30000 'PR-review tests failed!'
	exit 1
fi

echo "Tests passed!" >&2
if [ "$1" = '-t' ] || [ "$1" = '--test' ]; then
	exit 0
fi

repository_path="$1"
my_github_name="$2"

tmpdir='/tmp/pr-review'

# (Hopefully) Unique string for each repository
pathId="$(echo "$repository_path" | sed 's/\//-/g')"

state_file="$tmpdir/state-$pathId"
output_file="$tmpdir/output-$pathId"

if [ ! -d "$repository_path" ]; then
	echo "'$repository_path' is not a directory!" >"$output_file"
	exit 1
fi

send_notification() {
	title=$1
	subtitle=$2
	url=$3
	window_name=$4
	workspace="${5:-10}"

	chromium --window-name="$window_name" --new-window "$url" >/dev/null 2>&1 &

	ACTION="$(dunstify --action="default,Open" --timeout=30000 "$title" "$subtitle")"

	case "$ACTION" in
	"default")
		# Middle click
		i3-msg workspace "$workspace" >/dev/null 2>&1
		;;
	"2")
		# Left or right click
		i3-msg workspace "$workspace" >/dev/null 2>&1
		;;
	esac
}

check() {
	all_prs="$(gh pr list --search '-author:app/dependabot' --limit=30 --json url,title,author,createdAt,reviewRequests,reviews | jq -cr ".[] | select(.createdAt | fromdate > (now -3000000))")"

	echo "$all_prs" | filter_review_requested "$my_github_name" | while read -r line; do
		url=$(echo "$line" | jq -r '.url')

		if grep "^$url\$" "$state_file" >/dev/null 2>&1; then
			continue
		fi
		echo "$url" >>"$state_file"

		# id=$(echo $url | rev | cut -d'/' -f1 | rev)
		# authorName=$(echo $line | jq -r '.author.name')
		title=$(echo "$line" | jq -r '.title')
		author=$(echo "$line" | jq -r '.author.login')

		send_notification "Review: $title" "Author: $author" "$url" 'pr-review-requested' 9 &
	done

	echo "$all_prs" | filter_reviewed "$my_github_name" | while read -r line; do
		url=$(echo "$line" | jq -r '.url')

		if grep "^$url\$" "$state_file" >/dev/null 2>&1; then
			continue
		fi
		echo "$url" >>"$state_file"

		# id=$(echo $url | rev | cut -d'/' -f1 | rev)
		# authorName=$(echo $line | jq -r '.author.name')
		title=$(echo "$line" | jq -r '.title')
		author=$(echo "$line" | jq -r '.author.login')

		send_notification "Merge: $title" "Author: $author" "$url" 'pr-review-reviewed' 10 &
	done
}

mkdir -p "$tmpdir"

if ! cd "$repository_path"; then
	echo "Could not cd to '$repository_path'" >>"$output_file"
	exit 1
fi

while true; do
	check >>"$output_file" 2>&1
	sleep 20
done
