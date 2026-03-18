#!/usr/bin/env bash
set -euo pipefail

NVIM_VERSION="v0.10.4"
NVIM_CONFIG_REPO="git@github.com:carloscalage/nvim.git"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
NVIM_INSTALL_DIR="$HOME/.local"

echo "==> Installing Neovim ${NVIM_VERSION}..."

# Install dependencies (build-essential for treesitter, git, etc.)
if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq git curl unzip build-essential ripgrep fd-find
elif command -v yum &>/dev/null; then
    sudo yum install -y git curl unzip gcc gcc-c++ make ripgrep
fi

# Download and install Neovim appimage
mkdir -p "$NVIM_INSTALL_DIR/bin"
curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
    -o /tmp/nvim.tar.gz
tar -xzf /tmp/nvim.tar.gz -C /tmp
cp -rf /tmp/nvim-linux-x86_64/* "$NVIM_INSTALL_DIR/"
rm -rf /tmp/nvim.tar.gz /tmp/nvim-linux-x86_64

echo "==> Neovim installed at ${NVIM_INSTALL_DIR}/bin/nvim"

# Add to PATH if not already there
EXPORT_LINE="export PATH=\"${NVIM_INSTALL_DIR}/bin:\$PATH\""

add_to_rc() {
    local rc_file="$1"
    if ! grep -qF "$NVIM_INSTALL_DIR/bin" "$rc_file" 2>/dev/null; then
        echo "" >> "$rc_file"
        echo "# Neovim" >> "$rc_file"
        echo "$EXPORT_LINE" >> "$rc_file"
        echo "==> Added PATH export to $rc_file"
    else
        echo "==> PATH already configured in $rc_file"
    fi
}

if [ -f "$HOME/.zshrc" ]; then
    add_to_rc "$HOME/.zshrc"
else
    add_to_rc "$HOME/.bashrc"
fi

# Make nvim available in current session
export PATH="${NVIM_INSTALL_DIR}/bin:$PATH"

# Clone config
if [ -d "$NVIM_CONFIG_DIR" ]; then
    echo "==> Config already exists at ${NVIM_CONFIG_DIR}, pulling latest..."
    git -C "$NVIM_CONFIG_DIR" pull --ff-only || true
else
    echo "==> Cloning config..."
    mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
    git clone "$NVIM_CONFIG_REPO" "$NVIM_CONFIG_DIR"
fi

# Install plugins headlessly
echo "==> Installing plugins (headless)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

echo ""
echo "==> Done! Restart your shell or run:"
echo "    source ~/.bashrc  (or source ~/.zshrc)"
echo "    nvim"
