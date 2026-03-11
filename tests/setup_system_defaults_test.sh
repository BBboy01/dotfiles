#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)

cleanup() {
	rm -rf "$TMP_DIR"
}

trap cleanup EXIT

create_fixture() {
	local fake_home="$TMP_DIR/home"
	local fake_dotfiles="$fake_home/.dotfiles"
	local mock_bin="$TMP_DIR/bin"

	mkdir -p "$fake_dotfiles/link" "$fake_dotfiles/config" "$mock_bin"
	cp "$ROOT_DIR/setup" "$fake_dotfiles/setup"
	chmod +x "$fake_dotfiles/setup"

	cat >"$mock_bin/defaults" <<EOF
#!/usr/bin/env bash
printf '%s\t' "\$@" >> "$TMP_DIR/defaults.log"
printf '\n' >> "$TMP_DIR/defaults.log"
EOF

	cat >"$mock_bin/killall" <<EOF
#!/usr/bin/env bash
printf '%s\t' "\$@" >> "$TMP_DIR/killall.log"
printf '\n' >> "$TMP_DIR/killall.log"
EOF

	cat >"$mock_bin/xcode-select" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--print-path" ]]; then
	printf '/Library/Developer/CommandLineTools\n'
	exit 0
fi

exit 0
EOF

	cat >"$mock_bin/sudo" <<EOF
#!/usr/bin/env bash
printf '%s\t' "\$@" >> "$TMP_DIR/sudo.log"
printf '\n' >> "$TMP_DIR/sudo.log"
exit 0
EOF

	chmod +x "$mock_bin/defaults" "$mock_bin/killall" "$mock_bin/xcode-select" "$mock_bin/sudo"

	printf '%s\t%s\n' "$fake_home" "$mock_bin"
}

assert_file_contains() {
	local file="$1"
	local expected="$2"

	grep -F -- "$expected" "$file" >/dev/null
}

assert_system_defaults_are_written() {
	local fixture
	local fake_home
	local mock_bin
	local expected_path_line
	local expected_rollover_line

	fixture=$(create_fixture)
	IFS=$'\t' read -r fake_home mock_bin <<<"$fixture"
	expected_path_line=$(printf 'com.apple.finder\tNewWindowTargetPath\t-string\tfile://%s/\t' "$fake_home")
	expected_rollover_line=$'-g\tNSToolbarTitleViewRolloverDelay\t-int\t0\t'

	PATH="$mock_bin:$PATH" HOME="$fake_home" bash "$fake_home/.dotfiles/setup" --system >/dev/null

	assert_file_contains "$TMP_DIR/defaults.log" $'-g\t_HIHideMenuBar\t-bool\ttrue\t'
	assert_file_contains "$TMP_DIR/defaults.log" "$expected_rollover_line"
	assert_file_contains "$TMP_DIR/defaults.log" $'com.apple.dock\ttilesize\t-int\t48\t'
	assert_file_contains "$TMP_DIR/defaults.log" "$expected_path_line"
	assert_file_contains "$TMP_DIR/killall.log" $'Dock\tFinder\t'
	assert_file_contains "$TMP_DIR/sudo.log" $'spctl\t--master-disable\t'
}

assert_system_defaults_are_written
