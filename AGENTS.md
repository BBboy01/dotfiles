# Repository Guidelines

## Project Structure & Module Organization

This repository is a macOS dotfiles setup project built around the `setup` Bash script.

- `setup`: main entry point for module selection, logging, symlink creation, and tool setup.
- `config/`: first-level items link to `~/.config/<name>`. Both files and directories are supported.
- `link/`: first-level items link to `~/<name>`. Use this for dotfiles like `.tmux.conf`.
- `tests/`: shell integration checks. `tests/setup_link_items_test.sh` covers real runs and `--dry-run`.
- `Brewfile`: Homebrew packages installed by the setup flow.

## Build, Test, and Development Commands

- `./setup`: run the full setup with all modules enabled.
- `bash setup --dry-run --config`: preview config and dotfile linking without making changes.
- `bash setup --help`: list modules and usage examples.
- `bash tests/setup_link_items_test.sh`: run the integration test for linking and dry-run behavior.
- `bash -n setup && bash -n tests/setup_link_items_test.sh`: syntax-check modified shell scripts.
- `shellcheck setup tests/setup_link_items_test.sh`: lint the touched shell files.

## Coding Style & Naming Conventions

Use Bash with `set -euo pipefail` and follow existing script patterns.

- indent with tabs in `setup`
- prefer descriptive names such as `item_name` and `target_item`
- keep comments short and behavior-focused
- use first-level discovery with `find ... -mindepth 1 -maxdepth 1 -print0`

Keep logging aligned with the current `COLOR_*` helpers and `log_*` functions.

## Testing Guidelines

Tests are shell integration tests rather than unit tests. Update tests whenever linking logic, dry-run behavior, or module side effects change.

- name scripts with a `_test.sh` suffix
- use temporary directories and a fake `HOME`
- verify both real execution and `--dry-run` when behavior changes

## Commit & Pull Request Guidelines

Follow the repository’s recent conventional style:

- `fix(setup): Support top-level config symlinks`
- `feat: add native tmux like keys`
- `chore: cleanup brew`

Keep commits focused and reviewable. PRs should include a short summary, affected modules, verification commands, and any user-visible setup changes.

## Security & Configuration Tips

Do not commit secrets, private keys, or machine-specific credentials. Keep reusable settings in `config/` or `link/`, and leave host-specific overrides outside the repository.
