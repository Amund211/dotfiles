#!/bin/sh

# Starts one pr-review.sh poller per repository.
#
# This is the single source of truth for which repositories are polled and how:
# scripts/init.sh delegates here at login, so the command line exists in exactly one
# place. Anything else that needs the pollers running must call this script rather than
# copy the pr-review.sh invocation - a second copy is what this script exists to avoid.

set -u

user='Amund211'
repos="$HOME/git/ignite/main $HOME/git/ignite/go-packages $HOME/git/ignite/dataform"
pr_review="$HOME/.dotfiles/scripts/pr-review.sh"

# /tmp is tmpfs, so a reboot takes pr-review.sh's seen-state with it and a cold start
# treats every open PR as new - a browser window plus a claude terminal for each, across
# all three repos at once. Starting them this far apart spreads that burst. A --restart
# has warm state, so nothing is new and there is nothing to spread: stagger defaults to 0
# there.
cold_start_stagger=60

restart=''
dry_run=''
stagger=''
problems=0

usage() {
	echo "Usage: $0 [--restart] [--dry-run] [--stagger <seconds>]"
	echo "      --restart          Stop the running pollers first, then start them all"
	echo "  -n, --dry-run          Report what would happen and change nothing"
	echo "      --stagger <secs>   Delay between starts (default $cold_start_stagger, or 0 with --restart)"
	echo "  -h, --help             Show this help"
	echo
	echo "Without --restart, repositories that are already being polled are left alone."
}

while [ $# -gt 0 ]; do
	case "$1" in
	--restart)
		restart=1
		shift
		;;
	-n | --dry-run)
		dry_run=1
		shift
		;;
	--stagger)
		[ $# -ge 2 ] || { echo "Missing value for $1" >&2; exit 1; }
		stagger="$2"
		shift 2
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

if [ -z "$stagger" ]; then
	if [ -n "$restart" ]; then
		stagger=0
	else
		stagger="$cold_start_stagger"
	fi
fi

problem() {
	printf 'ERROR: %s\n' "$*" >&2
	problems=$((problems + 1))
}

warn() {
	printf 'WARN: %s\n' "$*" >&2
}

# The [.] stops the pattern from matching the shell that runs pgrep, whose own command
# line contains it. The trailing ' --user' keeps one repository path from matching another
# that merely starts with it.
pattern_for() {
	printf 'pr-review[.]sh --repo %s --user' "$1"
}

pids_for() {
	pgrep -f "$(pattern_for "$1")"
}

running() {
	pids_for "$1" >/dev/null 2>&1
}

verify() {
	for cmd in gh jq git alacritty chromium dunstify i3-msg setsid pgrep ps; do
		command -v "$cmd" >/dev/null 2>&1 || problem "missing command: $cmd"
	done

	[ -x "$pr_review" ] || problem "not executable: $pr_review"

	for repo in $repos; do
		if [ ! -d "$repo" ]; then
			problem "no such repository: $repo"
		elif ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
			problem "not a git repository: $repo"
		fi
	done

	# A path with whitespace would split in the loops above and break pattern_for.
	case "$repos$user" in
	*"	"* | *"
"*) problem "repository paths and user must not contain whitespace" ;;
	esac

	# pr-review.sh runs these itself on every start and notifies on failure, but checking
	# here means a broken script is caught before the running pollers are killed.
	if [ -x "$pr_review" ] && ! "$pr_review" --test >/dev/null 2>&1; then
		problem "$pr_review --test fails"
	fi

	# Not fatal: at login the network may not be up yet, and the pollers retry every 20s.
	if ! gh auth status >/dev/null 2>&1; then
		warn 'gh is not authenticated - the pollers will poll uselessly until it is'
	fi

	[ "$problems" -eq 0 ]
}

stop_one() {
	repo=$1
	pids=$(pids_for "$repo" | tr '\n' ' ')
	[ -n "$pids" ] || return 0

	for pid in $pids; do
		# Instances this script started are session leaders, so signalling the process
		# group also takes down whatever gh or git child is mid-poll. Instances started
		# some other way are not, so fall back to the pid alone.
		pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')
		if [ -n "$pgid" ] && [ "$pgid" = "$pid" ]; then
			kill -TERM "-$pid" 2>/dev/null || true
		else
			kill -TERM "$pid" 2>/dev/null || true
		fi
	done

	waited=0
	while [ "$waited" -lt 50 ]; do
		running "$repo" || return 0
		waited=$((waited + 1))
		sleep 0.1
	done

	left=$(pids_for "$repo" | tr '\n' ' ')
	warn "TERM did not stop $repo ($left) - escalating to KILL"
	for pid in $left; do
		kill -KILL "$pid" 2>/dev/null || true
	done

	sleep 0.5
	if running "$repo"; then
		problem "could not stop $repo ($(pids_for "$repo" | tr '\n' ' '))"
		return 1
	fi
}

start_one() {
	repo=$1
	delay=$2

	# setsid detaches into a new session, so the poller survives whatever shell started
	# it without needing nohup or disown. The delayed form must keep the same
	# '--repo <path> --user' spelling on its command line, or pattern_for stops matching
	# during the delay and the poller looks like it is not running.
	if [ "$delay" -gt 0 ]; then
		setsid -f sh -c "sleep $delay; exec $pr_review --repo $repo --user $user --claude-review" >/dev/null 2>&1
	else
		setsid -f "$pr_review" --repo "$repo" --user "$user" --claude-review >/dev/null 2>&1
	fi
}

if ! verify; then
	printf '%s\n' "start-pr-review: $problems problem(s) found, doing nothing" >&2
	dunstify --timeout=30000 'start-pr-review failed' "$problems problem(s) - see stderr" 2>/dev/null || true
	exit 1
fi

if [ -n "$restart" ]; then
	for repo in $repos; do
		pids=$(pids_for "$repo" | tr '\n' ' ')
		if [ -z "$pids" ]; then
			echo "not running, nothing to stop: $repo"
			continue
		fi
		if [ -n "$dry_run" ]; then
			echo "would stop: $repo ($pids)"
		else
			echo "stopping: $repo ($pids)"
			stop_one "$repo"
		fi
	done
fi

delay=0
started=0
for repo in $repos; do
	if [ -z "$dry_run" ] && running "$repo"; then
		echo "already running, leaving alone: $repo ($(pids_for "$repo" | tr '\n' ' '))"
		continue
	fi
	if [ -n "$dry_run" ] && [ -z "$restart" ] && running "$repo"; then
		echo "would leave alone, already running: $repo ($(pids_for "$repo" | tr '\n' ' '))"
		continue
	fi

	if [ -n "$dry_run" ]; then
		if [ "$delay" -gt 0 ]; then
			echo "would start: $repo (after ${delay}s)"
		else
			echo "would start: $repo (immediately)"
		fi
	else
		if [ "$delay" -gt 0 ]; then
			echo "starting: $repo (after ${delay}s)"
		else
			echo "starting: $repo"
		fi
		start_one "$repo" "$delay"
	fi

	started=$((started + 1))
	delay=$((delay + stagger))
done

if [ "$started" -eq 0 ]; then
	echo 'nothing to do'
	exit 0
fi

if [ -n "$dry_run" ]; then
	exit 0
fi

# Confirm the immediate starts actually took. Delayed ones are still a sleeping shell,
# which pattern_for matches too, so this covers them as well.
sleep 1
for repo in $repos; do
	running "$repo" || problem "failed to start: $repo"
done

if [ "$problems" -ne 0 ]; then
	dunstify --timeout=30000 'start-pr-review failed' "$problems poller(s) did not start" 2>/dev/null || true
	exit 1
fi

echo "all pollers running ($(echo "$repos" | wc -w) repositories)"
