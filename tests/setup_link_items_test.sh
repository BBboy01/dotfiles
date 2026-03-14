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

assert_file_not_contains() {
	local file="$1"
	local unexpected="$2"

	if grep -F -- "$unexpected" "$file" >/dev/null; then
		return 1
	fi
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
	assert_file_not_contains "$stripped_output" "fc-cache -f -v"
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

assert_dry_run_system_module_skips_spctl_and_reports_manual_steps() {
	local fake_home
	local fake_dotfiles
	local output_file
	local stripped_output

	fake_home=$(create_fixture system-dry-run)
	fake_dotfiles="$fake_home/.dotfiles"
	output_file="$TMP_DIR/system-dry-run-output.txt"
	stripped_output="$TMP_DIR/system-dry-run-output-stripped.txt"

	HOME="$fake_home" bash "$fake_dotfiles/setup" --system --dry-run > "$output_file"
	strip_ansi < "$output_file" > "$stripped_output"

	assert_file_not_contains "$stripped_output" "spctl --master-disable"
	assert_file_contains "$stripped_output" "ACTION REQUIRED AFTER A REAL RUN: Gatekeeper changes must be confirmed manually."
	assert_file_contains "$stripped_output" "Manual steps you may still need to complete:"
	assert_file_contains "$stripped_output" "Gatekeeper changes now require confirmation in System Settings > Privacy & Security."
}

assert_eval_homebrew_shellenv_allows_brew_exports() {
	if [[ ! -x /opt/homebrew/bin/brew ]]; then
		return
	fi

	HOME="$TMP_DIR/home" SHELL=/bin/bash bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		eval_homebrew_shellenv
		test \"\${HOMEBREW_PREFIX}\" = '/opt/homebrew'
		test \"\${HOMEBREW_CELLAR}\" = '/opt/homebrew/Cellar'
	"
}

assert_system_preferences_include_battery_and_trackpad_tweaks() {
	HOME="$TMP_DIR/home" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tAirDrop\t-int\t8'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tBattery\t-int\t4'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tBluetooth\t-int\t24'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tFocusModes\t-int\t8'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tKeyboardBrightness\t-int\t8'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tSpotlight\t-int\t8'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tTimer\t-int\t2'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tVoiceControl\t-int\t8'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tWeather\t-int\t8'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.controlcenter\tWiFi\t-int\t24'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'-g\tAppleIconAppearanceTheme\t-string\tRegularDark'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'-g\tNSGlassDiffusionSetting\t-int\t1'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'-g\tAppleShowScrollBars\t-string\tWhenScrolling'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'-g\tAppleScrollerPagingBehavior\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'-g\tcom.apple.swipescrolldirection\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.HIToolbox\tAppleDictationAutoEnable\t-int\t0'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'-g\tcom.apple.trackpad.scaling\t-float\t1.5'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.HIToolbox\tAppleFnUsageType\t-int\t0'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.AppleMultitouchTrackpad\tTrackpadRightClick\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.AppleMultitouchTrackpad\tTrackpadThreeFingerTapGesture\t-int\t0'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.driver.AppleBluetoothMultitouch.trackpad\tTrackpadRightClick\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.driver.AppleBluetoothMultitouch.trackpad\tTrackpadThreeFingerTapGesture\t-int\t0'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'-g\tcom.apple.trackpad.forceClick\t-bool\tfalse'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'-g\tshouldShowRSVPDataDetectors\t-bool\tfalse'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.WindowManager\tHideDesktop\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.WindowManager\tStandardHideDesktopIcons\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.WindowManager\tAutoHide\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.WindowManager\tStandardHideWidgets\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.WindowManager\tStageManagerHideWidgets\t-bool\ttrue'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\" | grep -Fq -- \$'com.apple.finder\tShowRecentTags\t-bool\tfalse'
		printf '%s\n' \"\${PMSET_SETTINGS[@]}\" | grep -Fq -- \$'-b\tlowpowermode\t0'
		printf '%s\n' \"\${PMSET_SETTINGS[@]}\" | grep -Fq -- \$'-b\tlessbright\t0'
		printf '%s\n' \"\${PMSET_SETTINGS[@]}\" | grep -Fq -- \$'-b\tdisplaysleep\t5'
	"
}

assert_system_preferences_skip_default_battery_and_drag_settings() {
	local setup_copy
	local current_host_copy

	setup_copy="$TMP_DIR/setup-values.txt"
	current_host_copy="$TMP_DIR/current-host-values.txt"

	HOME="$TMP_DIR/home" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		printf '%s\n' \"\${SYSTEM_DEFAULTS[@]}\"
	" > "$setup_copy"

	HOME="$TMP_DIR/home" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		printf '%s\n' \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\"
	" > "$current_host_copy"

	assert_file_not_contains "$setup_copy" $'com.apple.AppleMultitouchTrackpad\tTrackpadThreeFingerDrag\t-bool\ttrue'
	assert_file_not_contains "$setup_copy" $'com.apple.driver.AppleBluetoothMultitouch.trackpad\tTrackpadThreeFingerDrag\t-bool\ttrue'
	assert_file_not_contains "$setup_copy" $'com.apple.controlcenter\tBatteryShowPercentage\t-bool\ttrue'
	assert_file_not_contains "$current_host_copy" $'com.apple.controlcenter\tBatteryShowPercentage\t-bool\ttrue'
}

assert_apply_current_host_defaults_writes_menu_bar_controls() {
	local log_file

	log_file="$TMP_DIR/current-host-defaults.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		defaults() {
			printf 'defaults %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		apply_current_host_defaults_entries \"\${CURRENT_HOST_SYSTEM_DEFAULTS[@]}\"
	"

	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter AirDrop -int 8"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter Battery -int 4"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter Bluetooth -int 24"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter FocusModes -int 8"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter KeyboardBrightness -int 8"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter Spotlight -int 8"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter Timer -int 2"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter VoiceControl -int 8"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter Weather -int 8"
	assert_file_contains "$log_file" "defaults -currentHost write com.apple.controlcenter WiFi -int 24"
}

assert_apply_system_defaults_refreshes_menu_bar_processes() {
	local log_file

	log_file="$TMP_DIR/system-defaults.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		defaults() {
			printf 'defaults %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		pgrep() {
			return 0
		}
		log_task() {
			:
		}
		pmset() {
			if [[ \"\$1 \$2\" == '-g cap' ]]; then
				printf '%s\n' 'Capabilities for AC Power:' ' lowpowermode'
				return
			fi
			if [[ \"\$1 \$2\" == '-g batt' ]]; then
				printf '%s\n' 'Now drawing from \"AC Power\"' ' -InternalBattery-0 (id=1234567)\t95%; charging;'
				return
			fi
			return 1
		}
		DRY_RUN=false
		apply_system_defaults
	"

	assert_file_contains "$log_file" "exec killall Dock Finder"
	assert_file_contains "$log_file" "exec killall ControlCenter"
	assert_file_contains "$log_file" "exec killall SystemUIServer"
}

assert_apply_system_defaults_clears_persistent_dock_apps() {
	local log_file

	log_file="$TMP_DIR/dock-persistent-apps.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		defaults() {
			printf 'defaults %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		pgrep() {
			return 1
		}
		log_task() {
			:
		}
		pmset() {
			if [[ \"\$1 \$2\" == '-g cap' ]]; then
				printf '%s\n' 'Capabilities for AC Power:' ' lowpowermode'
				return
			fi
			if [[ \"\$1 \$2\" == '-g batt' ]]; then
				printf '%s\n' 'Now drawing from \"AC Power\"' ' -InternalBattery-0 (id=1234567)\t95%; charging;'
				return
			fi
			return 1
		}
		DRY_RUN=false
		apply_system_defaults
	"

	assert_file_contains "$log_file" "defaults write com.apple.dock persistent-apps -array"
	assert_file_not_contains "$log_file" "defaults write com.apple.dock persistent-others"
}

assert_apply_pmset_entries_writes_supported_battery_settings() {
	local log_file

	log_file="$TMP_DIR/pmset.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_warn() {
			printf 'warn %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		pmset() {
			if [[ \"\$1 \$2\" == '-g cap' ]]; then
				printf '%s\n' 'Capabilities for AC Power:' ' lowpowermode'
				return
			fi
			if [[ \"\$1 \$2\" == '-g batt' ]]; then
				printf '%s\n' 'Now drawing from \"AC Power\"' ' -InternalBattery-0 (id=1234567)\t95%; charging;'
				return
			fi
			return 1
		}
		apply_pmset_entries \"\${PMSET_SETTINGS[@]}\"
	"

	assert_file_contains "$log_file" "exec sudo pmset -b lowpowermode 0"
	assert_file_contains "$log_file" "exec sudo pmset -b lessbright 0"
	assert_file_contains "$log_file" "exec sudo pmset -b displaysleep 5"
	assert_file_not_contains "$log_file" "warn "
}

assert_configure_screen_lock_requests_immediate_password_prompt_when_needed() {
	local log_file

	log_file="$TMP_DIR/screen-lock.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		sysadminctl() {
			if [[ \"\$1 \$2\" == '-screenLock status' ]]; then
				printf '%s\n' 'screenLock delay is off'
				return
			fi
			command sysadminctl \"\$@\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			:
		}
		configure_screen_lock_settings
	"

	assert_file_contains "$log_file" "exec sysadminctl -screenLock immediate -password -"
}

assert_configure_screen_lock_skips_when_already_immediate() {
	local log_file

	log_file="$TMP_DIR/screen-lock-immediate.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		sysadminctl() {
			if [[ \"\$1 \$2\" == '-screenLock status' ]]; then
				printf '%s\n' 'screenLock delay is immediate'
				return
			fi
			command sysadminctl \"\$@\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			:
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		configure_screen_lock_settings
	"

	assert_file_contains "$log_file" "subtask Screen lock already requires the password immediately"
	assert_file_not_contains "$log_file" "exec sysadminctl -screenLock immediate -password -"
}

assert_configure_screen_lock_handles_empty_status_output() {
	local log_file

	log_file="$TMP_DIR/screen-lock-empty-status.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		sysadminctl() {
			if [[ \"\$1 \$2\" == '-screenLock status' ]]; then
				return 0
			fi
			command sysadminctl \"\$@\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			:
		}
		configure_screen_lock_settings
	"

	assert_file_contains "$log_file" "exec sysadminctl -screenLock immediate -password -"
}

assert_configure_screen_lock_skips_when_status_is_reported_on_stderr() {
	local log_file

	log_file="$TMP_DIR/screen-lock-stderr-status.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		sysadminctl() {
			if [[ \"\$1 \$2\" == '-screenLock status' ]]; then
				printf '%s\n' '2026-03-14 20:21:36.486 sysadminctl[19996:2556049] screenLock delay is immediate' >&2
				return 0
			fi
			command sysadminctl \"\$@\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			:
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		configure_screen_lock_settings
	"

	assert_file_contains "$log_file" "subtask Screen lock already requires the password immediately"
	assert_file_not_contains "$log_file" "exec sysadminctl -screenLock immediate -password -"
}

assert_configure_first_day_of_week_sets_monday() {
	local log_file

	log_file="$TMP_DIR/first-day-of-week.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			:
		}
		configure_first_day_of_week
	"

	assert_file_contains "$log_file" "exec defaults write NSGlobalDomain AppleFirstWeekday -dict gregorian 2"
}

assert_configure_startup_sound_skips_when_already_disabled() {
	local log_file

	log_file="$TMP_DIR/startup-sound-disabled.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		nvram() {
			if [[ \"\$1\" == 'SystemAudioVolume' ]]; then
				printf '%s\n' 'SystemAudioVolume	%80'
				return 0
			fi
			command nvram \"\$@\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			:
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		configure_startup_sound
	"

	assert_file_contains "$log_file" "subtask Startup sound already disabled"
	assert_file_not_contains "$log_file" "exec sudo nvram SystemAudioVolume=%80"
}

assert_configure_startup_sound_disables_when_needed() {
	local log_file

	log_file="$TMP_DIR/startup-sound-enable.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		nvram() {
			if [[ \"\$1\" == 'SystemAudioVolume' ]]; then
				return 1
			fi
			command nvram \"\$@\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			:
		}
		configure_startup_sound
	"

	assert_file_contains "$log_file" "exec sudo nvram SystemAudioVolume=%80"
}

assert_finalize_setup_reports_manual_system_steps() {
	local log_file

	log_file="$TMP_DIR/finalize.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		log_main() {
			printf 'main %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_warn() {
			printf 'warn %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			printf 'task %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		MODULE_SYSTEM=true
		MODULE_CONFIG=false
		MODULE_BREW=false
		MODULE_SHELL=false
		MODULE_GIT=false
		MODULE_TOOLS=false
		finalize_setup
	"

	assert_file_contains "$log_file" "warn ACTION REQUIRED: Gatekeeper changes must be confirmed manually."
	assert_file_contains "$log_file" "task Manual steps you may still need to complete:"
	assert_file_contains "$log_file" "subtask Gatekeeper changes now require confirmation in System Settings > Privacy & Security."
}

assert_finalize_setup_skips_manual_system_steps_when_system_module_disabled() {
	local log_file

	log_file="$TMP_DIR/finalize-no-system.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		log_main() {
			printf 'main %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_warn() {
			printf 'warn %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_task() {
			printf 'task %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		MODULE_SYSTEM=false
		MODULE_CONFIG=true
		MODULE_BREW=false
		MODULE_SHELL=false
		MODULE_GIT=false
		MODULE_TOOLS=false
		DRY_RUN=false
		finalize_setup
	"

	assert_file_not_contains "$log_file" "Gatekeeper changes"
	assert_file_not_contains "$log_file" "ACTION REQUIRED"
}

assert_install_homebrew_packages_continues_when_brew_doctor_fails() {
	local log_file

	log_file="$TMP_DIR/homebrew-doctor.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -lc "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		eval_homebrew_shellenv() {
			:
		}
		log_task() {
			printf 'task %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_warn() {
			printf 'warn %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		brew() {
			if [[ \"\$1 \$2 \$3\" == 'bundle install --file' ]]; then
				printf 'brew %s\n' \"\$*\" >> \"\$LOG_FILE\"
				return 0
			fi
			printf 'brew %s\n' \"\$*\" >> \"\$LOG_FILE\"
			return 0
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
			if [[ \"\$1 \$2\" == 'brew doctor' ]]; then
				return 1
			fi
			return 0
		}
		MODULE_BREW=true
		DRY_RUN=false
		install_homebrew_packages
		printf 'after install_homebrew_packages\n' >> \"\$LOG_FILE\"
	"

	assert_file_contains "$log_file" "brew bundle install --file $TMP_DIR/home/.dotfiles/Brewfile"
	assert_file_contains "$log_file" "exec brew cleanup"
	assert_file_contains "$log_file" "exec brew doctor"
	assert_file_contains "$log_file" "warn Homebrew doctor reported issues; continuing setup."
	assert_file_contains "$log_file" "after install_homebrew_packages"
}

assert_setup_javascript_tooling_skips_global_pnpm_packages() {
	local log_file

	log_file="$TMP_DIR/pnpm-home.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -c "
		set -euo pipefail
		unset PNPM_HOME
		source '$ROOT_DIR/setup'
		log_task() {
			:
		}
		log_subtask() {
			:
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		setup_javascript_tooling
		printf 'pnpm_home=%s\n' \"\${PNPM_HOME-unset}\" >> \"\$LOG_FILE\"
	"

	assert_file_contains "$log_file" "exec corepack enable"
	assert_file_contains "$log_file" "exec corepack install -g pnpm@latest"
	assert_file_not_contains "$log_file" "exec pnpm i -g vite @angular/cli prettier"
	assert_file_contains "$log_file" "pnpm_home=unset"
}

assert_install_neovim_config_skips_existing_target() {
	local fake_home
	local log_file
	local stripped_log_file

	fake_home="$TMP_DIR/home"
	log_file="$TMP_DIR/neovim-config.log"
	stripped_log_file="$TMP_DIR/neovim-config-stripped.log"
	mkdir -p "$fake_home/.config/nvim"
	printf 'existing config\n' > "$fake_home/.config/nvim/init.lua"

	HOME="$fake_home" LOG_FILE="$log_file" bash -c "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		log_task() {
			printf 'task %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_warn() {
			printf 'warn %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		git() {
			printf 'git %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		install_neovim_config
	"

	strip_ansi < "$log_file" > "$stripped_log_file"

	assert_file_contains "$stripped_log_file" "warn Neovim config already exists at "
	assert_file_contains "$stripped_log_file" "$fake_home/.config/nvim"
	assert_file_contains "$stripped_log_file" "skipping clone."
	assert_file_not_contains "$stripped_log_file" "git clone --recurse-submodules https://github.com/BBBoy01/nvim $fake_home/.config/nvim"
}

assert_install_tmux_plugin_manager_skips_existing_target() {
	local fake_home
	local log_file
	local stripped_log_file

	fake_home="$TMP_DIR/home"
	log_file="$TMP_DIR/tmux-plugin-manager.log"
	stripped_log_file="$TMP_DIR/tmux-plugin-manager-stripped.log"
	mkdir -p "$fake_home/.tmux/plugins/tpm"
	printf 'existing plugin manager\n' > "$fake_home/.tmux/plugins/tpm/README.md"

	HOME="$fake_home" LOG_FILE="$log_file" bash -c "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		log_task() {
			printf 'task %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_warn() {
			printf 'warn %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		git() {
			printf 'git %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		install_tmux_plugin_manager
	"

	strip_ansi < "$log_file" > "$stripped_log_file"

	assert_file_contains "$stripped_log_file" "warn Tmux Plugin Manager already exists at "
	assert_file_contains "$stripped_log_file" "$fake_home/.tmux/plugins/tpm"
	assert_file_contains "$stripped_log_file" "skipping clone."
	assert_file_not_contains "$stripped_log_file" "git clone https://github.com/tmux-plugins/tpm $fake_home/.tmux/plugins/tpm"
}

assert_configure_shell_module_skips_chsh_when_shell_matches() {
	local log_file
	local stripped_log_file

	log_file="$TMP_DIR/shell-module.log"
	stripped_log_file="$TMP_DIR/shell-module-stripped.log"

	HOME="$TMP_DIR/home" SHELL=/opt/homebrew/bin/fish LOG_FILE="$log_file" bash -c "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		grep() {
			return 0
		}
		log_task() {
			printf 'task %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		log_subtask() {
			printf 'subtask %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		execute_with_log() {
			printf 'exec %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		MODULE_SHELL=true
		configure_shell_module
	"

	strip_ansi < "$log_file" > "$stripped_log_file"

	assert_file_contains "$stripped_log_file" "subtask Fish shell already in "
	assert_file_contains "$stripped_log_file" "/etc/shells"
	assert_file_contains "$stripped_log_file" "subtask Default shell already set to "
	assert_file_contains "$stripped_log_file" "/opt/homebrew/bin/fish"
	assert_file_not_contains "$stripped_log_file" "exec chsh -s /opt/homebrew/bin/fish"
}

assert_configure_tools_module_skips_luarocks_packages() {
	local log_file

	log_file="$TMP_DIR/tools-module.log"

	HOME="$TMP_DIR/home" LOG_FILE="$log_file" bash -c "
		set -euo pipefail
		source '$ROOT_DIR/setup'
		install_neovim_config() {
			printf 'step neovim\n' >> \"\$LOG_FILE\"
		}
		install_tmux_plugin_manager() {
			printf 'step tmux\n' >> \"\$LOG_FILE\"
		}
		install_rust_toolchain() {
			printf 'step rust\n' >> \"\$LOG_FILE\"
		}
		setup_javascript_tooling() {
			printf 'step javascript\n' >> \"\$LOG_FILE\"
		}
		start_window_manager_services() {
			printf 'step window-manager\n' >> \"\$LOG_FILE\"
		}
		luarocks() {
			printf 'luarocks %s\n' \"\$*\" >> \"\$LOG_FILE\"
		}
		MODULE_TOOLS=true
		configure_tools_module
	"

	assert_file_contains "$log_file" "step neovim"
	assert_file_contains "$log_file" "step tmux"
	assert_file_contains "$log_file" "step rust"
	assert_file_contains "$log_file" "step javascript"
	assert_file_contains "$log_file" "step window-manager"
	assert_file_not_contains "$log_file" "luarocks --lua-version=5.1 install vusted"
}

assert_normal_run_links_files_and_directories
assert_dry_run_reports_without_creating_links
assert_dry_run_system_module_skips_spctl_and_reports_manual_steps
assert_eval_homebrew_shellenv_allows_brew_exports
assert_system_preferences_include_battery_and_trackpad_tweaks
assert_system_preferences_skip_default_battery_and_drag_settings
assert_apply_current_host_defaults_writes_menu_bar_controls
assert_apply_system_defaults_refreshes_menu_bar_processes
assert_apply_system_defaults_clears_persistent_dock_apps
assert_apply_pmset_entries_writes_supported_battery_settings
assert_configure_screen_lock_requests_immediate_password_prompt_when_needed
assert_configure_screen_lock_skips_when_already_immediate
assert_configure_screen_lock_handles_empty_status_output
assert_configure_screen_lock_skips_when_status_is_reported_on_stderr
assert_configure_first_day_of_week_sets_monday
assert_configure_startup_sound_skips_when_already_disabled
assert_configure_startup_sound_disables_when_needed
assert_finalize_setup_reports_manual_system_steps
assert_finalize_setup_skips_manual_system_steps_when_system_module_disabled
assert_install_homebrew_packages_continues_when_brew_doctor_fails
assert_setup_javascript_tooling_skips_global_pnpm_packages
assert_install_neovim_config_skips_existing_target
assert_install_tmux_plugin_manager_skips_existing_target
assert_configure_shell_module_skips_chsh_when_shell_matches
assert_configure_tools_module_skips_luarocks_packages
