set fish_greeting

set -gx SHELL fish
set -gx LANG en_US.UTF-8
set -gx TERM alacritty
set -gx NEOVIDE_TITLE_HIDDEN true
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

set -gx HOMEBREW_INSTALL /opt/homebrew
set -gx PNPM_HOME $HOME/Library/pnpm
set -gx BUN_INSTALL $HOME/.bun

set fisher_path $XDG_DATA_HOME/fisher
set fish_complete_path $fish_complete_path[1] $fisher_path/completions $fish_complete_path[2..]
set fish_function_path $fish_function_path[1] $fisher_path/functions $fish_function_path[2..]
for file in $fisher_path/conf.d/*.fish
    source $file
end

set -gx PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
set -gx PUPPETEER_EXECUTABLE_PATH (which chromium)


fish_add_path "$HOMEBREW_INSTALL/bin"
fish_add_path "$HOMEBREW_INSTALL/sbin"
fish_add_path "/usr/local/bin"

fish_add_path "bin"
fish_add_path "node_modules/.bin"
fish_add_path "$CARGO_INSTALL/bin"
fish_add_path "$BUN_INSTALL/bin"
fish_add_path "$PNPM_HOME"

# Aliases
alias vim nvim

alias ls "eza --icons"
alias la "ls -a"
alias ll "eza -l -g --icons --git"
alias lla "ll -a"
alias tree "eza --tree --icons -g"
alias treel "ll --tree --git"
alias cat "bat --paging=never"
alias md "open -a /Applications/Typora.app"

# Git alias
# go to project root
alias grt 'cd "$(git rev-parse --show-toplevel)"'

alias gs "git status"
alias gp "git push"
alias gpoh "git push -u origin HEAD"
alias gpf "git push --force"
alias gpft "git push --follow-tags"
alias gpdo "git push --delete origin"
alias gpl "git pull --rebase"
alias gcl "git clone"
alias gst "git stash"
alias gsta "git stash apply"
alias gstp "git stash pop"
alias grm "git rm"
alias gmv "git mv"
alias gd "git diff"
alias gds "git diff --staged"

alias main "git switch main"
alias master "git switch master"
alias dev "git switch develop"
alias gsb "git switch"
alias gsp "git switch -"
alias gbp "git remote prune origin"
alias ff "gbp && git pull --ff-only"

alias gb "git branch"
alias gbD "git branch -D"

alias gf "git fetch"
alias gfo "git fetch origin"

alias grb "git rebase"
alias grbas "git rebase --autosquash"
alias grbom "git rebase origin/master"
alias grbod "git rebase origin/develop"
alias grbc "git rebase --continue"
alias grba "git rebase --abort"

alias gl "git log"
alias glo "git log --oneline --graph"

alias grsH "git reset HEAD"
alias grsH1 "git reset HEAD~1"
alias grsh "git reset --hard"
alias grshod "git reset --hard origin/dev"
alias grshom "git reset --hard origin/main"

alias ga "git add"
alias gaa "git add -A"

alias gc "git commit -m"
alias gcf "git commit --fixup"
alias gca "git commit --amend"
alias gcan "git commit --amend --no-edit"
alias gcam "git add -A && git commit -m"
alias gfrb "git fetch origin && git rebase origin/main"
alias gsha "git rev-parse HEAD | pbcopy"

alias gxn "git clean -dn"
alias gx "git clean -df"

alias gop "git open"


alias gfu "git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup"
# Switch branchs
alias cbr 'git branch --sort=-committerdate | fzf --header "Checkout Recent Branch" --preview "git diff {1} --color=always | delta" --pointer="" | xargs git switch'
# Get help docs
alias tldrf 'tldr --list | fzf --preview "tldr {1}" --preview-window=right,70% | xargs tldr'
alias rsync "rsync -lahz"

function proxy
    set -gx https_proxy http://127.0.0.1:7890
    set -gx http_proxy http://127.0.0.1:7890
    set -gx all_proxy socks5://127.0.0.1:7890
end
function unproxy
    set -gu http_proxy
    set -gu https_proxy
    set -gu all_proxy
end
function ssh_proxy
    ssh -o ProxyCommand="nc -X 5 -x 127.0.0.1:7890 %h %p" $argv
end

function code
  set location "$PWD/$argv"
  open -n -b "com.microsoft.VSCode" --args $location
end

function yy
  set tmp (mktemp -t "yazi-cwd.XXXXXX")
  yazi $argv --cwd-file="$tmp"
  if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
    cd -- "$cwd"
  end
  rm -f -- "$tmp"
end
