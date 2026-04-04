#!/usr/bin/env bash
set -eu

DOTFILES_DIR="/dotfiles"
DOTFILES_URL="https://github.com/w4daka/rust-dev-dotfiles.git"
DOTFILES_BRANCH="main"

if [ ! -d "${DOTFILES_DIR}/.git" ]; then
  git clone --branch "${DOTFILES_BRANCH}" "${DOTFILES_URL}" "${DOTFILES_DIR}"
fi

mkdir -p /root/.config/sheldon
mkdir -p /root/.config/kitty
rm -rf /root/.config/nvim
ln -sfn "${DOTFILES_DIR}/nvim" /root/.config/nvim
ln -sfn "${DOTFILES_DIR}/sheldon/plugins.toml" /root/.config/sheldon/plugins.toml
ln -sfn "${DOTFILES_DIR}/zsh/.zshrc" /root/.zshrc
ln -sfn "${DOTFILES_DIR}/kitty/kitty.conf" /root/.config//kitty/kitty.conf
