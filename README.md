# Git Interface

A lightweight Git integration plugin for Godot Engine that provides version control functionality directly within the Godot Editor.

## 📋 Overview

Git Interface (FGI - Fxll3n's Git Interface) is a Godot 4.6+ editor plugin that adds a convenient Git panel to your editor workspace. It allows you to perform common Git operations like commit, push, pull, and status checking without leaving the Godot environment.

## ✨ Features

- **Real-time Status Monitoring**: Automatically refreshes Git status every 10 seconds
- **File Change Tracking**: Visual tree view of modified, added, deleted, and untracked files
- **Git Operations**:
  - 📝 Commit changes with custom messages
  - ⬆️ Push to remote repository
  - ⬇️ Pull from remote repository
  - 🔄 Fetch and refresh status
- **Cross-platform Support**: Works on Windows, Linux, and macOS
- **Async Operations**: Push and pull operations run asynchronously to prevent editor freezing
- **Dock Integration**: Seamlessly integrates as an editor dock panel

## 🚀 Installation

1. Clone or download this repository
2. Copy the `addons/fgi` folder into your Godot project's `addons` directory
3. Open your project in Godot Editor
4. Go to **Project → Project Settings → Plugins**
5. Enable the "Git Interface" plugin

## 📦 Requirements

- Godot Engine 4.6 or higher
- Git installed and available in system PATH
- A Git repository initialized in your project directory

## 🎮 Usage

Once enabled, the Git panel appears in the editor workspace (default location: upper left dock).

### Committing Changes

1. View your changed files in the file tree
2. Enter a commit message in the text area
3. Click the "Commit" button
4. All changes will be automatically staged and committed

### Pushing & Pulling

- Click "Push" to send commits to the remote repository
- Click "Pull" to fetch and merge changes from remote
- Operations run in the background without freezing the editor

### Status Icons

- `[M]` - Modified file
- `[A]` - Added file
- `[D]` - Deleted file
- `[?]` - Untracked file
- `[*]` - Other changes

## 🛠️ Technical Details

The plugin executes Git commands using `OS.execute()`:
- **Synchronous operations**: Status checks, commits, staging
- **Asynchronous operations**: Push and pull (uses threading to prevent blocking)

The current branch and status are displayed in the status panel.

## 📁 Project Structure

```
addons/fgi/
├── fgi.gd          # Main plugin script
├── git_ui.gd       # UI controller and Git operations
├── git_ui.tscn     # User interface scene
└── plugin.cfg      # Plugin configuration
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

Copyright (c) 2026 Angel Bitsov

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

## ⚠️ Known Limitations

- Requires Git to be installed and accessible via command line
- Does not support Git credential management (uses system credentials)
- Limited to basic Git operations (commit, push, pull)

## 🔗 Links

- [Godot Engine](https://godotengine.org/)
- [Git Documentation](https://git-scm.com/doc)

---

Made with ❤️ for the Godot community
