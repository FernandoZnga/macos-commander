#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Xcode Command Line Tools
echo "🔍 Checking for Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
    echo "✅ Xcode Command Line Tools already installed."
else
    echo "➡ Installing Xcode Command Line Tools..."
    xcode-select --install

    echo "⏳ Waiting for Xcode Command Line Tools to finish installing..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    echo "✅ Xcode Command Line Tools installed successfully."
fi

# Install Homebrew if not installed
if ! command_exists brew; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew is already installed."
fi

# Update Homebrew
echo "🔄 Updating Homebrew..."
brew update

# Install Applications
APPS_FILE="$(dirname "$0")/apps.txt"

# Check if apps.txt exists
if [ ! -f "$APPS_FILE" ]; then
    echo "❌ Error: apps.txt file not found at $APPS_FILE"
    echo "Please create the apps.txt file with a list of applications to install (one per line)."
    exit 1
fi

# Read apps from file into array
mapfile -t apps < "$APPS_FILE" 2>/dev/null || {
    echo "❌ Error: Failed to read apps from $APPS_FILE"
    exit 1
}

# Remove empty lines from the array
apps=("${apps[@]}")

# Check if the apps array has any elements
if [ ${#apps[@]} -eq 0 ]; then
    echo "❌ Error: No applications found in $APPS_FILE"
    echo "Please add application names to the file, one per line."
    exit 1
fi

echo "📦 Installing GUI apps..."
for app in "${apps[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
        echo "✅ $app is already installed."
    else
        echo "➡ Installing $app..."
        brew install --cask "$app"
    fi
done

# Install GitHub CLI
if brew list gh &>/dev/null; then
    echo "✅ GitHub CLI already installed."
else
    echo "➡ Installing GitHub CLI..."
    brew install gh
fi

# Install NVM
if [ -d "$HOME/.nvm" ]; then
    echo "✅ NVM is already installed."
else
    echo "📦 Installing NVM (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
fi

# Install Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "✅ Oh My Zsh is already installed."
else
    echo "🎩 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Zsh plugins
echo "🔧 Installing Zsh plugins..."
brew install zsh-autosuggestions zsh-syntax-highlighting

# Add plugins to .zshrc
ZSHRC="$HOME/.zshrc"
if ! grep -q "zsh-autosuggestions" "$ZSHRC"; then
    echo "➡ Adding zsh-autosuggestions to .zshrc"
    echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> "$ZSHRC"
fi

if ! grep -q "zsh-syntax-highlighting" "$ZSHRC"; then
    echo "➡ Adding zsh-syntax-highlighting to .zshrc"
    echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$ZSHRC"
fi

# Final Docker check
if command_exists docker; then
    echo "✅ Docker installed successfully."
    echo "⚠️ You may need to start Docker Desktop manually."
else
    echo "❌ Docker installation may have failed. Please check manually."
fi

echo "🎉 Setup complete! Your Mac is ready to roll. 🚀"
