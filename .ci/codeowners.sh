#!/bin/sh -e
# Description: verify CODEOWNERS file is sane
# https://postmarketos.org/pmb-ci

# TODO Future improvements:
# * Check that all devices in main/community have someone in CODEOWNERS
# * Check that GitLab user actually exists (e.g. deleted account, account with
#   changed user name)

if grep -q "  " CODEOWNERS; then
	echo
	echo "ERROR: Found space indentation in CODEOWNERS."
	echo "ERROR: Please indent with tab characters."
	grep "  " CODEOWNERS
	echo
	exit 1
fi

fail=0
tmppipe=$(mktemp -u)
mkfifo "$tmppipe"
grep -v "^#" CODEOWNERS | cut -d'	' -f1  > "$tmppipe" &
while IFS= read -r line; do
	[ -z "$line" ] && continue

	# Check if entry generally exists
	# shellcheck disable=SC2086
	ls $line >/dev/null 2>&1 || { fail=1; echo "Non-existing: $line"; }

	# Check that directories end with a slash
	# shellcheck disable=SC2086
	if test -d "$(ls -d $line)"; then
		echo "$line" | grep -q '/$' || { fail=1; echo "Missing trailing slash: $line"; }
	fi
done < "$tmppipe"
rm "$tmppipe"

if [ "$fail" = 1 ]; then
	echo
	echo "ERROR: Invalid CODEOWNERS entries, see above."
	echo
	exit 1
fi
