#!/bin/bash

echo "⚠️ This will uninstall apps installed via setup.sh and clean up related configs."
read -p "Are you sure you want to continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Apps to uninstall
APPS_FILE="$(dirname "$0")/apps.txt"

# Check if apps.txt exists
if [ ! -f "$APPS_FILE" ]; then
    echo "❌ Error: apps.txt file not found at $APPS_FILE"
    echo "Please create the apps.txt file with a list of applications to uninstall (one per line)."
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

echo "🧼 Uninstalling GUI apps..."
for app in "${apps[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
        echo "❌ Uninstalling $app..."
        brew uninstall --cask "$app"
    else
        echo "✅ $app was not installed or already removed."
    fi
done

# Remove GitHub CLI
if brew list gh &>/dev/null; then
    echo "❌ Uninstalling GitHub CLI..."
    brew uninstall gh
fi

# Remove NVM
if [ -d "$HOME/.nvm" ]; then
    echo "🗑️ Removing NVM..."
    rm -rf "$HOME/.nvm"
    sed -i '' '/NVM_DIR/d' ~/.zshrc
    sed -i '' '/nvm.sh/d' ~/.zshrc
    sed -i '' '/bash_completion/d' ~/.zshrc
else
    echo "✅ NVM is not installed or already removed."
fi

# Remove Zsh plugins
echo "🧹 Cleaning up Zsh plugins..."
brew uninstall zsh-autosuggestions zsh-syntax-highlighting

# Remove plugin lines from .zshrc
echo "✂️ Cleaning up plugin config from ~/.zshrc..."
sed -i '' '/zsh-autosuggestions/d' ~/.zshrc
sed -i '' '/zsh-syntax-highlighting/d' ~/.zshrc

# Remove Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "🗑️ Removing Oh My Zsh..."
    uninstall_oh_my_zsh="$HOME/.oh-my-zsh/tools/uninstall.sh"
    if [ -f "$uninstall_oh_my_zsh" ]; then
        RUNZSH=no CHSH=no sh "$uninstall_oh_my_zsh"
    else
        echo "⚠️ Could not find the Oh My Zsh uninstall script. You may need to remove ~/.oh-my-zsh manually."
    fi
fi

# Optional: Uninstall Homebrew
read -p "Do you also want to uninstall Homebrew? (y/N): " remove_brew
if [[ "$remove_brew" =~ ^[Yy]$ ]]; then
    echo "🧨 Uninstalling Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
else
    echo "✅ Keeping Homebrew."
fi

# Optional: Uninstall Xcode Command Line Tools
read -p "Do you also want to uninstall Xcode Command Line Tools? (y/N): " remove_xcode
if [[ "$remove_xcode" =~ ^[Yy]$ ]]; then
    echo "🧨 Uninstalling Xcode Command Line Tools..."
    sudo rm -rf /Library/Developer/CommandLineTools
    sudo xcode-select --reset
    echo "✅ Xcode Command Line Tools removed."
else
    echo "✅ Keeping Xcode Command Line Tools."
fi

echo "🎉 Teardown complete. Your system is clean and minimal again. 🧼"
