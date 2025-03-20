# Minimalist Vim Configuration Guide

A clean, functional Vim setup that balances minimalism with productivity features.

## Table of Contents
- [Installation](#installation)
- [General Features](#general-features)
- [User Interface](#user-interface)
- [Text Editing](#text-editing)
- [Navigation](#navigation)
- [Key Mappings](#key-mappings)
- [Plugin System](#plugin-system)
- [Customization](#customization)

## Installation

1. Back up your existing Vim configuration (if any):

```bash
cp ~/.vimrc ~/.vimrc.backup
```

2. Download the new `.vimrc` file:

```bash
curl -o ~/.vimrc https://your-download-url.com/.vimrc
```

3. Launch Vim. The plugin manager (vim-plug) will be installed automatically, and plugins will be installed on first launch.

## General Features

- **Modern Vim Experience**: Uses `nocompatible` mode for full Vim features
- **File Type Support**: Enables syntax highlighting and filetype-specific indentation
- **Session Memory**: Returns to your last position when reopening files
- **Clean File System**: No backup or swap files to clutter your directories
- **Space Leader**: Uses the space bar as the leader key for easy access to shortcuts

## User Interface

### Display Features
- **Line Numbers**: Shows both absolute and relative line numbers for easy navigation
- **Current Line Highlight**: Highlights the line where your cursor is positioned
- **Status Line**: Displays essential information: file path, modification status, filetype, position
- **Command Completion**: Enhanced wildmenu for better command-line completion

### Visual Settings
- **Color Scheme**: Uses Desert by default (built-in) with Gruvbox as an enhancement if installed
- **Error Feedback**: No annoying sounds or flashes on errors
- **Matching Brackets**: Briefly highlights matching brackets when cursor is on one
- **Smooth Scrolling**: Maintains context by keeping 5 lines visible above/below cursor

## Text Editing

### Indentation and Formatting
- **Space-based Tabs**: Uses spaces instead of tab characters (4 spaces default)
- **Smart Indentation**: Automatically applies proper indentation for code
- **Language-specific Settings**: Uses 2-space indentation for web languages
- **Clean Code**: Automatically removes trailing whitespace on save

### Search Features
- **Highlighted Search**: Results are highlighted as you type
- **Smart Case Sensitivity**: Ignores case by default but becomes case-sensitive with uppercase

## Navigation

- **Window Navigation**: Use `Ctrl+h/j/k/l` to move between split windows
- **Buffer Navigation**: Use `<Space>n` for next buffer and `<Space>p` for previous
- **Enhanced Tab Completion**: Smart tabbing in command mode

## Key Mappings

### Normal Mode Shortcuts
- `<Space>w` - Save file
- `<Space>q` - Quit current buffer
- `<Space>x` - Save and quit
- `Esc` - Clear search highlighting
- `Ctrl+h/j/k/l` - Navigate between windows

### Insert Mode
- `Esc` or `Ctrl+[` - Return to normal mode

### Visual Mode
- `<Space>y` - Copy selection to system clipboard

### Clipboard Integration
- `<Space>y` - Yank (copy) to system clipboard
- `<Space>p` - Paste from system clipboard

## Plugin System

The configuration includes a minimal but powerful set of plugins:

### Core Plugins
- **Gruvbox**: Enhanced color scheme for better visual experience
- **vim-surround**: Easily manipulate quotes, parentheses, tags, etc.
- **vim-commentary**: Comment/uncomment code with a simple motion
- **FZF**: Fuzzy file finder for rapid navigation

### Plugin Shortcuts
- `<Space>f` - FZF file search
- `<Space>b` - FZF buffer list

## Customization

### Adding New Plugins
To add a new plugin, edit your `.vimrc` and add a line between the `call plug#begin()` and `call plug#end()` lines:

```vim
" Example: adding NERDTree
Plug 'preservim/nerdtree'
```

Then reload your `.vimrc` and run `:PlugInstall`

### Common Customizations

1. **Change color scheme**:
```vim
colorscheme blue  " Or another built-in theme
```

2. **Change tab width**:
```vim
set shiftwidth=2
set tabstop=2
```

3. **Add keybindings to escape insert mode**:
```vim
inoremap jj <Esc>
```

4. **Disable relative line numbers**:
```vim
set norelativenumber
```

5. **Enable mouse support**:
```vim
set mouse=a
```

### Advanced Configuration

For advanced users, consider these modifications:

- Add language-specific settings with autocmd groups
- Configure terminal integration for running tests
- Set up advanced text objects for enhanced editing

## Additional Resources

- `:help` - Vim's built-in help system (extremely comprehensive)
- [Vim Tips Wiki](https://vim.fandom.com/wiki/Vim_Tips_Wiki)
- [Learn Vimscript the Hard Way](https://learnvimscriptthehardway.stevelosh.com/)