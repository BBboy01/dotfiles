#!/usr/bin/env bash

# @see https://apple.stackexchange.com/questions/10467/how-to-increase-keyboard-key-repeat-rate-on-os-x
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 10

dotfiles_dir="$HOME/.dotfiles"
home_config_dir="$HOME/.config"

echo "link config file"
target_folders=("alacritty" "kitty")
for folder_name in "${target_folders[@]}"; do
  folder="$dotfiles_dir/config/$folder_name"
  target_folder="$home_config_dir/$folder_name"

  if [ -d "$target_folder" ]; then
    rm -rf "$target_folder"
    echo "Removed existing $target_folder"
  fi

  ln -s "$folder" "$target_folder"
  echo "Created symlink from $folder to $target_folder"
done

# ###########################################################
# Install non-brew various tools (PRE-BREW Installs)
# ###########################################################
echo "ensuring build/install tools are available"
if ! xcode-select --print-path &> /dev/null; then
  # Prompt user to install the XCode Command Line Tools
  xcode-select --install &> /dev/null
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Wait until the XCode Command Line Tools are installed
  until xcode-select --print-path &> /dev/null; do
    sleep 5
  done

  if [[ $? != 0 ]]; then
    echo 'XCode Command Line Tools Installed'
  else
    echo $? 'XCode Command Line Tools Install Failed!!!'
  fi
  # Prompt user to agree to the terms of the Xcode license
  # https://github.com/alrra/dotfiles/issues/10
  sudo xcodebuild -license
  echo $? 'Agree with the XCode Command Line Tools licence'
fi

# ###########################################################
# install homebrew (CLI Packages)
# ###########################################################
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  echo "installing homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ $? != 0 ]]; then
    echo "unable to install homebrew, script $0 abort!"
    exit 2
  fi
fi

###########################################################
# Config
###########################################################
for file in "$HOME/.dotfiles/link"/*; do
  if [ -f "$HOME/$file" ]; then
    rm -f "$HOME/$file"
    echo "Removed existing $HOME/$file"
  fi

  if [ -f "$file" ]; then
    filename=$(basename "$file")
    ln -s "$file" "$HOME/$filename"
    echo "Created symlink: $HOME/$filename -> $file"
  fi
done

# Function to install a package with a given package manager
install_package() {
  local package_manager="$1"
  local package="$2"
  case "$package_manager" in
    "brew")
      if brew list "$package" &> /dev/null; then
        echo "Package '$package' is already installed."
      else
        brew install "$package"
        if [ $? -eq 0 ]; then
          echo "Successfully installed '$package'."
        else
          echo "Error installing '$package'."
          exit 1
        fi
      fi
      ;;

    "pnpm")
      if pnpm ls -g "$package" &> /dev/null; then
        echo "Package '$package' is already installed globally."
      else
        pnpm add -g "$package"
        if [ $? -eq 0 ]; then
          echo "Successfully installed '$package' globally."
        else
          echo "Error installing '$package' globally."
          exit 1
        fi
      fi
      ;;
      
    *)
      echo "Unsupported package manager: $package_manager"
      exit 1
      ;;
  esac
}

echo "install packages"
brew tap homebrew/cask-fonts
brew_packages=(
  "git"
  "difftastic"
  "git-delta"
  "make"
  "cmake"
  "llvm"
  "curl"
  "fish"
  "ripgrep"
  "ninja"
  "fzf"
  "jq"
  "zoxide"
  "tldr"
  "tokei"
  "tmux"
  "bat"
  "btop"
  "yazi"
  "bun"
  "pnpm"
  "stylua"
  "dprint"
  "lua"
  "luarocks"
  "luacheck"
  "rustup-init"
  "rust-analyzer"
  "lua-language-server"
  "golang"
  "gopls"
  "yabai"
  "skhd"
  "font-monaspace"
  "font-hack-nerd-font"
  "visual-studio-code"
  "karabiner-elements"
  "raycast"
  "cleanshot"
  "arc"
  "firefox"
  "google-chrome"
  "qq"
  "qqmusic"
  "docker"
  "wechat"
  "iina"
)

brew install alacritty --no-quarantine

# Install Homebrew packages
for package in "${brew_packages[@]}"; do
  install_package "brew" "$package"
done

# Change to fish
# chsh -s $(which fish)

# Config git
git config --global user.name "BBBoy01"
git config --global user.email "1156678002@qq.com"
git config --global core.editor "nvim"
git config --global core.pager "delta"
git config --global credential.helper store
git config --global core.excludesFile $HOME/.gitignore_global
git config --global init.defaultbranch "main"
git config --global interactive.difffilter "delta --color-only"
git config --global add.interactive.usebuiltin false
git config --global delta.light false
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global delta.syntax-theme Dracula
git config --global merge.conflictstyle diff3
git config --global diff.colormoved default
git config --global diff.tool difftastic
git config --global diff.external difft
git config --global difftool.prompt false
git config --global difftool.difftastic.cmd "difft $LOCAL $REMOTE"
git config --global pager.difftool true

# My neovim config
echo "Download neovim config"
git clone https://github.com/BBBoy01/nvim ~/.config/nvim

# Tmux tpm plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Neovim plugin test framework
luarocks --lua-version=5.1 install vusted

# Init rust
echo $CARGO_HOME $RUSTUP_HOME
rustup-init

# refresh cache
fc-cache -f -v

# pnpm relate
pnpm_packages=(
  "vite"
  "eslint_d"
  "prettier"
  "emmet-ls"
  "typescript"
  "@vue/language-server"
  "bash-language-server"
  "yaml-language-server"
  "typescript-language-server"
  "@angular/language-server@15"
  "@tailwindcss/language-server"
  "vscode-langservers-extracted"
  "dockerfile-language-server-nodejs"
)
# Install npm packages globally
for package in "${npm_packages[@]}"; do
  install_package "pnpm" "$package"
done
# Install lts node
pnpm env use -g lts

# Init yabai
sudo yabai --load-sa
yabai --start-service
skhd --start-service

brew cleanup
brew doctor
echo "All done"
