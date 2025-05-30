# 🖥️ macOS Commander

![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

⚡ Command your Mac's destiny with powerful automation

A collection of utility scripts for macOS system management, including computer setup, teardown, and user folder cleanup.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Scripts](#scripts)
  - [Computer Setup](#computer-setup)
  - [Computer Teardown](#computer-teardown)
  - [Cleanup User Folders](#cleanup-user-folders)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

🚀 A suite of shell scripts that automate macOS setup, teardown, and maintenance. 💻 Deploy developer environments in minutes and keep your system clean. ✨

This repository contains a set of scripts designed to help with macOS system management:

- **Computer Setup**: Automates the installation of essential applications and development tools
- **Computer Teardown**: Safely removes applications and configurations installed by the setup script
- **Cleanup User Folders**: Manages and optionally deletes old files from Desktop or Downloads folders

## 🛠️ Prerequisites

- macOS (tested on macOS Sonoma and above)
- Administrative privileges on your Mac
- Internet connection for downloading applications

## 📥 Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/FernandoZnga/macos-commander.git
   cd macos-commander
   ```

2. Make the scripts executable:
   ```bash
   chmod +x *.sh
   ```

## 📜 Scripts

### Computer Setup

Automates the installation of essential applications and development tools for macOS.

**Usage:**
```bash
./computer_setup.sh
```

**Features:**
- Installs Xcode Command Line Tools
- Sets up Homebrew
- Installs common applications from `apps.txt`
- Configures development tools (GitHub CLI, NVM)
- Sets up Zsh with Oh My Zsh and plugins

### Computer Teardown

Safely removes applications and configurations installed by the setup script.

**Usage:**
```bash
./computer_teardown.sh
```

**Features:**
- Uninstalls applications installed by the setup script
- Removes development tools (GitHub CLI, NVM)
- Cleans up Zsh configurations
- Optionally removes Homebrew and Xcode Command Line Tools

### Cleanup User Folders

Manages and optionally deletes old files from Desktop or Downloads folders.

**Usage:**
```bash
./cleanup_user_folders.sh [OPTIONS]
```

**Options:**
- `--target VALUE`: Target folder to clean ('desktop' or 'downloads') (REQUIRED)
- `--delete`: Delete files (if not specified, files will only be listed)
- `--include-subfolders`: Include files in subfolders
- `--help`: Display help message

**Examples:**
```bash
./cleanup_user_folders.sh --target desktop            # List files in Desktop
./cleanup_user_folders.sh --target downloads --delete # Delete files from Downloads
```

## ⚙️ Configuration

### Application List

The `apps.txt` file contains the list of applications to be installed by the setup script and uninstalled by the teardown script. Each application name should be on a separate line.

Default applications include:
- Productivity: Slack, Visual Studio Code, Sublime Text, Postman
- Terminal: iTerm2, Warp
- Development: Docker, GitHub Desktop, Pritunl
- Browsers: Google Chrome, Vivaldi, Firefox, DuckDuckGo
- Communication: WhatsApp

You can customize this list by editing the `apps.txt` file.

## 👥 Contributing

Contributions are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Created with ❤️ for macOS enthusiasts

