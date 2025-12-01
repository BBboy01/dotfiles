# dotfiles

Personal Mac dotfiles with Fish shell configuration

## Installation

```bash
git clone https://github.com/BBoyy01/dotfiles ~/.dotfiles
cd .dotfiles
chmod +x setup
./setup
```

## Features

- **Modular execution**: Selective execution of configuration modules
- **Complete macOS setup**: System defaults, Homebrew, Fish shell, Git configuration
- **Fish-optimized**: Leverages Fish conf.d system for PATH management
- **Enhanced logging**: Solarized color-coded output for better visibility
- **Safety first**: Dry-run mode and modular design for safe execution

## Usage

The setup script supports selective module execution:

- `--config`: Link config files and dotfiles
- `--brew`: Install packages via Homebrew
- `--shell`: Configure Fish shell
- `--git`: Configure Git settings
- `--tools`: Install development tools
- `--system`: Configure macOS system settings
- `--dry-run`: Preview changes without executing
- `--verbose`: Enable detailed output

**Default**: All modules run when no flags specified

**Example**: `./setup --git --shell` runs only Git and Shell configuration
