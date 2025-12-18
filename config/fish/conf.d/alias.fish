# @fish-lsp-disable 2002

# =============================================================================
# FILE NAVIGATION & EXPLORATION
# =============================================================================

alias la "ls -a"
alias ll "eza -l -g --icons --git"
alias lla "ll -a"
alias ls "eza --icons"
alias tree "eza --tree --icons -g --git-ignore"
alias treel "ll --tree --git --git-ignore"

# =============================================================================
# FILE OPERATIONS
# =============================================================================

alias cat "bat --paging=never"
alias md "open -a /Applications/Typora.app"
alias rsync "rsync -lahz"

# =============================================================================
# GIT MAIN COMMANDS
# =============================================================================

alias gaa "git add -A"
alias gb "git branch"
alias gbD "git branch -D"
alias gc "git commit -m"
alias gcf "git commit --fixup"
alias gca "git commit --amend"
alias gcan "git commit --amend --no-edit"
alias gcl "git clone --depth 1"
alias gd "git diff"
alias gds "git diff --staged"
alias gf "git fetch"
alias gfo "git fetch origin"
alias gl "git log"
alias glo "git log --oneline --graph"
alias glf "git log -p"
alias gpl "git pull"
alias gp "git push"
alias gpf "git push --force"
alias gpft "git push --follow-tags"
alias gpdo "git push --delete origin"
alias gsha "git rev-parse HEAD | pbcopy"
alias gst "git stash"
alias gsta "git stash apply"
alias gstp "git stash pop"
alias gsp "git switch -"
alias gsb "git switch"
alias grb "git rebase"
alias grbc "git rebase --continue"
alias grba "git rebase --abort"
alias gcp "git cherry-pick"
alias gx "git clean -df"
alias gxn "git clean -dn"

# =============================================================================
# GIT WORKFLOW SHORTCUTS
# =============================================================================

alias dev "git switch develop"
alias ff "gbp && git pull --ff-only"
alias gbp "git remote prune origin"
alias main "git switch main"
alias master "git switch master"

# =============================================================================
# GIT INTERACTIVE COMMANDS
# =============================================================================

alias cbr 'git branch --sort=-committerdate | fzf --header "Checkout Recent Branch" --preview "git diff {1} --color=always | delta" --pointer="" | xargs git switch'
alias gs "git status"
alias gfu "git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup"

# =============================================================================
# UTILITIES & TOOLS
# =============================================================================

alias tldrf 'tldr --list | fzf --preview "tldr {1}" --preview-window=right,70% | xargs tldr'
alias vim nvim
