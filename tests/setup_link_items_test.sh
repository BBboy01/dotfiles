#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)

cleanup() {
	rm -rf "$TMP_DIR"
}

trap cleanup EXIT

create_fixture() {
	local name="$1"
	local fake_home="$TMP_DIR/$name/home"
	local fake_dotfiles="$fake_home/.dotfiles"

	mkdir -p "$fake_dotfiles/link" "$fake_dotfiles/config"
	cp "$ROOT_DIR/setup" "$fake_dotfiles/setup"
	chmod +x "$fake_dotfiles/setup"

	printf 'command_timeout = 500\n' > "$fake_dotfiles/config/starship.toml"
	mkdir -p "$fake_dotfiles/config/nvim"
	printf 'set number\n' > "$fake_dotfiles/config/nvim/init.vim"
	printf 'set-option -g mouse on\n' > "$fake_dotfiles/link/.testrc"
	mkdir -p "$fake_dotfiles/link/.testdir"
	printf 'nested content\n' > "$fake_dotfiles/link/.testdir/nested.txt"

	printf '%s\n' "$fake_home"
}

strip_ansi() {
	perl -pe 's/\e\[[0-9;]*m//g'
}

assert_file_contains() {
	local file="$1"
	local expected="$2"

	grep -F "$expected" "$file" >/dev/null
}

assert_line_contains_both() {
	local file="$1"
	local first="$2"
	local second="$3"

	awk -v first="$first" -v second="$second" 'index($0, first) && index($0, second) { found = 1 } END { exit(found ? 0 : 1) }' "$file"
}

assert_normal_run_links_files_and_directories() {
	local fake_home
	local fake_dotfiles

	fake_home=$(create_fixture normal)
	fake_dotfiles="$fake_home/.dotfiles"

	HOME="$fake_home" bash "$fake_dotfiles/setup" --config >/dev/null

	test -L "$fake_home/.config/starship.toml"
	test "$(readlink "$fake_home/.config/starship.toml")" = "$fake_dotfiles/config/starship.toml"
	test -L "$fake_home/.config/nvim"
	test "$(readlink "$fake_home/.config/nvim")" = "$fake_dotfiles/config/nvim"
	test -f "$fake_home/.config/nvim/init.vim"
	test -L "$fake_home/.testrc"
	test "$(readlink "$fake_home/.testrc")" = "$fake_dotfiles/link/.testrc"
	test -L "$fake_home/.testdir"
	test "$(readlink "$fake_home/.testdir")" = "$fake_dotfiles/link/.testdir"
	test -f "$fake_home/.testdir/nested.txt"
}

assert_dry_run_reports_without_creating_links() {
	local fake_home
	local fake_dotfiles
	local output_file
	local stripped_output

	fake_home=$(create_fixture dry-run)
	fake_dotfiles="$fake_home/.dotfiles"
	output_file="$TMP_DIR/dry-run-output.txt"
	stripped_output="$TMP_DIR/dry-run-output-stripped.txt"

	HOME="$fake_home" bash "$fake_dotfiles/setup" --config --dry-run > "$output_file"
	strip_ansi < "$output_file" > "$stripped_output"

	assert_line_contains_both "$stripped_output" "$fake_dotfiles/config/starship.toml" "$fake_home/.config/starship.toml"
	assert_line_contains_both "$stripped_output" "$fake_dotfiles/config/nvim" "$fake_home/.config/nvim"
	assert_line_contains_both "$stripped_output" "$fake_dotfiles/link/.testrc" "$fake_home/.testrc"
	assert_line_contains_both "$stripped_output" "$fake_dotfiles/link/.testdir" "$fake_home/.testdir"
	assert_file_contains "$stripped_output" "$fake_home/.hushlogin"
	assert_file_contains "$stripped_output" "$fake_home/.ssh/config"
	assert_file_contains "$stripped_output" "fc-cache"
	test ! -d "$fake_home/.config"
	test ! -e "$fake_home/.config/starship.toml"
	test ! -e "$fake_home/.config/nvim"
	test ! -e "$fake_home/.testrc"
	test ! -e "$fake_home/.testdir"
	test ! -e "$fake_home/.hushlogin"
	test ! -L "$fake_home/.config/starship.toml"
	test ! -L "$fake_home/.config/nvim"
	test ! -L "$fake_home/.testrc"
	test ! -L "$fake_home/.testdir"
	test ! -d "$fake_home/.ssh"
}

assert_normal_run_links_files_and_directories
assert_dry_run_reports_without_creating_links
