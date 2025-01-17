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
alias gcl "git clone --depth 1"
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

alias gcp "git cherry-pick"


alias gfu "git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup"
# Switch branchs
alias cbr 'git branch --sort=-committerdate | fzf --header "Checkout Recent Branch" --preview "git diff {1} --color=always | delta" --pointer="" | xargs git switch'
# Get help docs
alias tldrf 'tldr --list | fzf --preview "tldr {1}" --preview-window=right,70% | xargs tldr'
alias rsync "rsync -lahz"
