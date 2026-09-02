#!/bin/sh

set -u

repository_path=''
my_github_name=''
claude_review=''
test_only=''

usage() {
	echo "Usage: $0 --repo <path> --user <github-name> [--claude-review] [--test]"
	echo "  -r, --repo <path>   Local git repository to poll for PRs and base review worktrees on"
	echo "  -u, --user <name>   Your GitHub username"
	echo "      --claude-review Spin up a PR-head worktree + a 'claude /code-review' terminal for each hit"
	echo "  -t, --test          Run tests only"
	echo "  -h, --help          Show this help"
}

while [ $# -gt 0 ]; do
	case "$1" in
	-r | --repo)
		[ $# -ge 2 ] || { echo "Missing value for $1" >&2; exit 1; }
		repository_path="$2"
		shift 2
		;;
	-u | --user)
		[ $# -ge 2 ] || { echo "Missing value for $1" >&2; exit 1; }
		my_github_name="$2"
		shift 2
		;;
	--claude-review)
		claude_review=1
		shift
		;;
	-t | --test)
		test_only=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown argument: $1" >&2
		usage >&2
		exit 1
		;;
	esac
done

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

filter_authored() {
	github_username="${1:-}"
	if [ -z "$github_username" ]; then
		echo "No github name provided" >&2
		exit 1
	fi

	filter="select(.author.login == \"$github_username\")"

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

	if ! run_test 'authored_by_me -> include' "$not_reviewed" 'filter_authored' 'Amund211' '1'; then
		return 1
	fi

	if ! run_test 'authored_by_someone_else -> exclude' "$not_reviewed" 'filter_authored' 'someone-else' '0'; then
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
if [ -n "$test_only" ]; then
	exit 0
fi

if [ -z "$repository_path" ]; then
	echo "Missing required --repo" >&2
	usage >&2
	exit 1
fi
if [ -z "$my_github_name" ]; then
	echo "Missing required --user" >&2
	usage >&2
	exit 1
fi

tmpdir='/tmp/pr-review'

# (Hopefully) Unique string for each repository
pathId="$(echo "$repository_path" | sed 's/\//-/g')"

# Three repos are polled in parallel, so a bare PR number is ambiguous in window titles.
repo_name="${repository_path##*/}"

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
	window_title=$4
	workspace="${5:-10}"

	# --window-name freezes WM_NAME for the life of the window, so it has to carry the
	# identifying information itself - the page title never gets through. It ends with the
	# pr-review-<queue> token the i3 rules match on, so the browser row and the review
	# terminal for the same PR open with the same <repo>#<number> and can be read as a
	# pair. See docs/i3-pr-review-windows.md.
	chromium --window-name="$window_title" --new-window "$url" >/dev/null 2>&1 &

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

launch_review() {
	number=$1
	url=$2
	title=$3
	window_class=$4
	base_branch=$5

	worktree_base="/tmp/claude-1000/pr-review-$repo_name"
	worktree_path="$worktree_base/pr-$number"
	branch="pr-review-$number"
	pr_ref="refs/pr-review/$number"
	base_ref="refs/pr-review/$number-base"

	# Fetch the PR head into a dedicated per-PR ref (not the shared FETCH_HEAD, which
	# a concurrent fetch in this repo could clobber) and build the worktree from it.
	# The pr-review-<number> branch is uniquely named so it never collides with a
	# branch checked out in the main repo. Clean any stale worktree from a prior run.
	# The base branch gets its own per-PR ref for the same reason: the review range is
	# pinned to SHAs resolved here, so master/origin/master moving in the main checkout
	# later cannot change what the session ends up reviewing. Two fetches, not one with
	# two refspecs, so a deleted base branch does not take the head fetch down with it.
	mkdir -p "$worktree_base"
	git -C "$repository_path" fetch origin "+refs/pull/$number/head:$pr_ref"
	git -C "$repository_path" fetch origin "+refs/heads/$base_branch:$base_ref" ||
		echo "pr-review: could not fetch base branch '$base_branch' for PR $number" >&2
	git -C "$repository_path" worktree remove --force "$worktree_path" 2>/dev/null
	rm -rf "$worktree_path"
	git -C "$repository_path" worktree prune

	if ! git -C "$repository_path" worktree add --force -B "$branch" "$worktree_path" "$pr_ref"; then
		echo "pr-review: failed to create worktree for PR $number" >&2
		return 1
	fi

	# Resolve the range now and hand claude the two SHAs, never ref names. A review
	# session lives for hours; in that time the main checkout fetches and rebases, and
	# refs the worktree shares with it (master, origin/master) move, which is how a
	# session ends up reviewing code that has nothing to do with its PR. merge-base -
	# not the base tip - is what gives the same three-dot diff GitHub shows.
	head_sha="$(git -C "$repository_path" rev-parse --verify --quiet "$pr_ref^{commit}")"
	base_sha="$(git -C "$repository_path" merge-base "$base_ref" "$pr_ref" 2>/dev/null)"

	if [ -n "$base_sha" ] && [ -n "$head_sha" ]; then
		diff_instructions="$(printf 'Review exactly this diff and nothing else:\n\n    git diff %s %s\n\n%s is the PR head this worktree is checked out to; %s is its merge-base with the PR base branch %s. Both were resolved when this worktree was created - use them verbatim, and do not name master, origin/master, HEAD~N or any other moving ref when you resolve the range.' "$base_sha" "$head_sha" "$head_sha" "$base_sha" "$base_branch")"
	else
		echo "pr-review: no merge-base for PR $number against '$base_branch', falling back to gh pr diff" >&2
		diff_instructions="$(printf 'Review exactly the diff that "gh pr diff %s" prints, and nothing else. Do not derive a range from master, origin/master, HEAD~N or any other ref this worktree shares with the main checkout - they move while the review runs.' "$number")"
	fi

	prompt="$(printf '/code-review %s\n\n%s\n\nYou are in a throwaway git worktree on branch %s, checked out to this PR head; edit freely, it does not touch the main checkout.' "$url" "$diff_instructions" "$branch")"

	# Reap the worktree/branch/ref once claude exits so they don't pile up and
	# eventually fill /tmp (mirrors prune_review_state). Values go through env, not the
	# sh -c string, so arbitrary PR titles/prompts can't break quoting. If the window is
	# force-killed (SIGHUP) rather than exited, cleanup is skipped - the pre-add remove
	# above and startup prune_review_state catch those leftovers.
	# --class is what i3 assigns on: WM_CLASS is set once at map time and never changes,
	# unlike the title. Passing --title instead would also make alacritty ignore every
	# later title change, so claude's --name would never reach the title bar. The instance
	# half of --class is a per-PR handle for i3 criteria. See docs/i3-pr-review-windows.md.
	# --settings enableAllProjectMcpServers auto-approves the repo's .mcp.json servers,
	# which otherwise prompt in every fresh worktree.
	# setsid puts the terminal in its own session rather than the poller's process group,
	# so restarting or killing the poller cannot take a review session down with it.
	# The -u list drops the environment a claude session stamps on its children: if the
	# poller was started from inside one (restarting it by hand from a claude terminal is
	# the normal case), the review claude inherits CLAUDE_CODE_CHILD_SESSION and turns off
	# transcript saving, so those sessions can never be resumed. The rest are stale
	# pointers at the parent - its session, pid, effort and sandbox proxy - that a fresh
	# session sets for itself.
	setsid -f env \
		-u CLAUDE_CODE_CHILD_SESSION \
		-u CLAUDE_CODE_SESSION_ID \
		-u CLAUDE_PID \
		-u CLAUDE_EFFORT \
		-u CLAUDECODE \
		-u CLAUDE_CODE_ENTRYPOINT \
		-u CLAUDE_CODE_EXECPATH \
		-u CLAUDE_CODE_HOST_HTTP_PROXY_PORT \
		-u CLAUDE_CODE_HOST_SOCKS_PROXY_PORT \
		-u AI_AGENT \
		REVIEW_REPO="$repository_path" \
		REVIEW_WORKTREE="$worktree_path" \
		REVIEW_BRANCH="$branch" \
		REVIEW_REF="$pr_ref" \
		REVIEW_BASE_REF="$base_ref" \
		REVIEW_CLAUDE_NAME="$repo_name#$number $title" \
		REVIEW_PROMPT="$prompt" \
		alacritty \
		--class "$window_class,prr-$repo_name-$number" \
		--working-directory "$worktree_path" \
		-e sh -c '
claude --settings "{\"enableAllProjectMcpServers\":true}" --name "$REVIEW_CLAUDE_NAME" "$REVIEW_PROMPT"
git -C "$REVIEW_REPO" worktree remove --force "$REVIEW_WORKTREE" 2>/dev/null
rm -rf "$REVIEW_WORKTREE"
git -C "$REVIEW_REPO" worktree prune
git -C "$REVIEW_REPO" branch -D "$REVIEW_BRANCH" 2>/dev/null
git -C "$REVIEW_REPO" update-ref -d "$REVIEW_REF" 2>/dev/null
git -C "$REVIEW_REPO" update-ref -d "$REVIEW_BASE_REF" 2>/dev/null
' \
		>/dev/null
}

prune_review_state() {
	# Clear leftover review branches/refs from previous runs so they don't pile up.
	# Worktrees whose dirs are gone (e.g. /tmp cleared on reboot) are pruned first so
	# their branches become deletable; branches still checked out in a live worktree
	# are left alone.
	git -C "$repository_path" worktree prune
	git -C "$repository_path" for-each-ref --format='%(refname)' 'refs/pr-review/*' | while read -r ref; do
		git -C "$repository_path" update-ref -d "$ref"
	done
	git -C "$repository_path" for-each-ref --format='%(refname:short)' 'refs/heads/pr-review-*' | while read -r br; do
		git -C "$repository_path" branch -D "$br" 2>/dev/null
	done
}

# Dedup keyed by event so the authored/reviewed cases (both my PRs) don't suppress each other.
seen() {
	grep -qxF "$1 $2" "$state_file" 2>/dev/null
}

mark_seen() {
	echo "$1 $2" >>"$state_file"
}

check() {
	all_prs="$(gh pr list --search '-author:app/dependabot' --limit=100 --json url,title,author,createdAt,reviewRequests,reviews,number,baseRefName | jq -cr ".[] | select(.createdAt | fromdate > (now -3000000))")"

	# Review requested from me -> browser + notification + claude review on ws9.
	echo "$all_prs" | filter_review_requested "$my_github_name" | while read -r line; do
		url=$(echo "$line" | jq -r '.url')

		seen requested "$url" && continue
		mark_seen requested "$url"

		number=$(echo "$line" | jq -r '.number')
		title=$(echo "$line" | jq -r '.title')
		author=$(echo "$line" | jq -r '.author.login')

		send_notification "Review: $title" "Author: $author" "$url" "$repo_name#$number $title — pr-review-requested" 9 &
		if [ -n "$claude_review" ]; then
			base_branch=$(echo "$line" | jq -r '.baseRefName')
			launch_review "$number" "$url" "$title" 'pr-review-requested' "$base_branch"
		fi
	done

	# A PR I authored -> claude review only on ws10 (no browser/notification; I just
	# opened it). Only meaningful with --claude-review, so the whole branch is gated on it.
	if [ -n "$claude_review" ]; then
		echo "$all_prs" | filter_authored "$my_github_name" | while read -r line; do
			url=$(echo "$line" | jq -r '.url')

			seen authored "$url" && continue
			mark_seen authored "$url"

			number=$(echo "$line" | jq -r '.number')
			title=$(echo "$line" | jq -r '.title')
			base_branch=$(echo "$line" | jq -r '.baseRefName')

			launch_review "$number" "$url" "$title" 'pr-review-reviewed' "$base_branch"
		done
	fi

	# My PR got a human review -> merge notification on ws10 (unchanged).
	echo "$all_prs" | filter_reviewed "$my_github_name" | while read -r line; do
		url=$(echo "$line" | jq -r '.url')

		seen reviewed "$url" && continue
		mark_seen reviewed "$url"

		number=$(echo "$line" | jq -r '.number')
		title=$(echo "$line" | jq -r '.title')
		author=$(echo "$line" | jq -r '.author.login')

		send_notification "Merge: $title" "Author: $author" "$url" "$repo_name#$number $title — pr-review-reviewed" 10 &
	done
}

mkdir -p "$tmpdir"

if ! cd "$repository_path"; then
	echo "Could not cd to '$repository_path'" >>"$output_file"
	exit 1
fi

if [ -n "$claude_review" ]; then
	prune_review_state >>"$output_file" 2>&1
fi

while true; do
	check >>"$output_file" 2>&1
	sleep 20
done
