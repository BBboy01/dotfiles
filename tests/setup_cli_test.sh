#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)

cleanup() {
	rm -rf "$TMP_DIR"
}

trap cleanup EXIT

strip_ansi() {
	perl -pe 's/\e\[[0-9;]*m//g'
}

create_fixture() {
	local fake_home="$TMP_DIR/home"
	local fake_dotfiles="$fake_home/.dotfiles"

	mkdir -p "$fake_dotfiles/link" "$fake_dotfiles/config"
	cp "$ROOT_DIR/setup" "$fake_dotfiles/setup"
	chmod +x "$fake_dotfiles/setup"

	printf '%s\n' "$fake_home"
}

assert_output_contains() {
	local output="$1"
	local expected="$2"

	grep -F -- "$expected" <<<"$output" >/dev/null
}

assert_help_output() {
	local output

	output=$(bash "$ROOT_DIR/setup" --help)
	assert_output_contains "$output" "Usage:"
	assert_output_contains "$output" "[OPTIONS]"
	assert_output_contains "$output" "--dry-run"
	assert_output_contains "$output" "--config"
}

assert_modules_output() {
	local output

	output=$(bash "$ROOT_DIR/setup" --modules)
	assert_output_contains "$output" "Available modules:"
	assert_output_contains "$output" "--system"
	assert_output_contains "$output" "--tools"
}

assert_explicit_module_selection() {
	local fake_home
	local output

	fake_home=$(create_fixture)
	output=$(HOME="$fake_home" bash "$fake_home/.dotfiles/setup" --dry-run --shell --git | strip_ansi)

	assert_output_contains "$output" "Shell Configuration: ✅"
	assert_output_contains "$output" "Git Configuration: ✅"
	assert_output_contains "$output" "Skipping config linking (module disabled)"
	if grep -F "Config Linking: ✅" <<<"$output" >/dev/null; then
		return 1
	fi
}

assert_unknown_option_fails() {
	local output

	if output=$(bash "$ROOT_DIR/setup" --nope 2>&1); then
		return 1
	fi

	assert_output_contains "$output" "Unknown option: --nope"
	assert_output_contains "$output" "Use --help for usage information."
}

assert_git_module_runs_independently() {
	local fake_home
	local expected_difftool_cmd="difft \"\$LOCAL\" \"\$REMOTE\""

	fake_home=$(create_fixture)
	HOME="$fake_home" bash "$fake_home/.dotfiles/setup" --git >/dev/null

	test "$(HOME="$fake_home" git config --global --get core.editor)" = "nvim"
	test "$(HOME="$fake_home" git config --global --get init.defaultbranch)" = "main"
	test "$(HOME="$fake_home" git config --global --get core.excludesFile)" = "$fake_home/.gitignore_global"
	test "$(HOME="$fake_home" git config --global --get user.signingKey)" = "$fake_home/.ssh/key.pub"
	test "$(HOME="$fake_home" git config --global --get difftool.difftastic.cmd)" = "$expected_difftool_cmd"
}

assert_tools_dry_run_skips_install_phase() {
	local fake_home
	local output

	fake_home=$(create_fixture)
	output=$(HOME="$fake_home" bash "$fake_home/.dotfiles/setup" --dry-run --tools | strip_ansi)

	assert_output_contains "$output" "Other Tools: ✅"
	if grep -F -- "Installing and configuring packages..." <<<"$output" >/dev/null; then
		return 1
	fi
}

assert_help_output
assert_modules_output
assert_explicit_module_selection
assert_unknown_option_fails
assert_git_module_runs_independently
assert_tools_dry_run_skips_install_phase
