set -gx LANG en_US.UTF-8
set -gx TERM ghostty
set -gx NEOVIDE_FORK 1
set -gx EDITOR nvim

set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/var

set -gx GOPATH $XDG_DATA_HOME/go
set -gx GOBIN $XDG_DATA_HOME/go/bin
set -gx GOPROXY https://goproxy.cn,direct
set -gx GO111MODULE on

set -gx CARGO_HOME $XDG_DATA_HOME/cargo
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup
set -gx CARGO_INSTALL $HOME/.cargo

set -gx PNPM_HOME $HOME/Library/pnpm
set -gx BUN_INSTALL $HOME/.bun

set fisher_path $XDG_DATA_HOME/fisher
set fish_complete_path $fish_complete_path[1] $fisher_path/completions $fish_complete_path[2..]
set fish_function_path $fish_function_path[1] $fisher_path/functions $fish_function_path[2..]
for file in $fisher_path/conf.d/*.fish
    source $file
end

set -gx PUPPETEER_SKIP_DOWNLOAD true
set -gx PUPPETEER_EXECUTABLE_PATH (which chromium)

set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew
! set -q MANPATH; and set MANPATH ''
set -gx MANPATH /opt/homebrew/share/man $MANPATH
! set -q INFOPATH; and set INFOPATH ''
set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
