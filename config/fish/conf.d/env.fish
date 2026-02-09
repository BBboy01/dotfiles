# =============================================================================
# SYSTEM & SHELL SETTINGS
# =============================================================================

set -gx LANG en_US.UTF-8
set -gx NEOVIDE_FORK 1
set -gx EDITOR nvim

# =============================================================================
# XDG BASE DIRECTORIES
# =============================================================================

set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/var

# =============================================================================
# LANGUAGE-SPECIFIC PATHS & SETTINGS
# =============================================================================

# Go programming language
set -gx GOPATH $XDG_DATA_HOME/go
set -gx GOBIN $XDG_DATA_HOME/go/bin
set -gx GOPROXY https://goproxy.cn,direct
set -gx GO111MODULE on

# Rust programming language
set -gx CARGO_HOME $XDG_DATA_HOME/cargo
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup

# =============================================================================
# PACKAGE MANAGERS
# =============================================================================

set -gx PNPM_HOME $HOME/Library/pnpm
set -gx BUN_INSTALL $HOME/.bun

# =============================================================================
# SHELL PROMPT CONFIGURATION
# =============================================================================

set -gx STARSHIP_CONFIG $XDG_CONFIG_HOME/starship/starship.toml

# =============================================================================
# PUPPETEER SETTINGS
# =============================================================================

set -gx PUPPETEER_SKIP_DOWNLOAD true
set -gx PUPPETEER_EXECUTABLE_PATH (command -s chromium)

# =============================================================================
# HOMEBREW CONFIGURATION
# =============================================================================

set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew
! set -q MANPATH; and set MANPATH ''
set -gx MANPATH /opt/homebrew/share/man $MANPATH
! set -q INFOPATH; and set INFOPATH ''
set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
