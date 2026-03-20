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
- **Complete macOS setup**: System defaults, Homebrew, Fish shell, Git, and developer tooling
- **Fish-optimized**: Leverages Fish conf.d system for PATH management
- **Enhanced logging**: Solarized color-coded output for better visibility
- **Safety first**: Dry-run mode and modular design for safe execution
- **Rust via official rustup**: Bootstraps `rustup` with the official installer instead of Homebrew
- **SSH configuration**: Automatic SSH settings for better connection management

## Usage

The setup script supports selective module execution:

- `--config`: Link config files and dotfiles (`config/` 与 `link/` 第一层都支持文件与目录，目录会整体软链接)
- `--brew`: Install packages via Homebrew
- `--shell`: Configure Fish shell
- `--git`: Configure Git settings
- `--tools`: Initialize developer tooling (Neovim, tmux, Rust, JS)
- `--system`: Configure macOS system settings
- `--dry-run`: Preview changes without executing
- `--verbose`: Enable detailed output

`config/<name>` 会链接到 `~/.config/<name>`，`link/<name>` 会链接到 `~/<name>`。

`--dry-run` 默认会输出摘要级预览；配合 `--verbose` 时会展开到具体命令。

`--tools` 当前会处理：
- Neovim 配置
- Tmux Plugin Manager
- Rust toolchain（通过官方 `rustup` 安装脚本初始化）
- JavaScript tooling（`mise` / `corepack` / `pnpm`）

**Default**: All modules run when no flags specified

**Example**: `./setup --git --shell` runs only Git and Shell configuration
