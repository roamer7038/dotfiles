# dotfiles

## Supported Applications
### Common

* bash
* zsh
* tmux
* vim
* git
* latex

### macOS

* homebrew

### Linux

* X Window System
* i3wm
* i3status
* compton
* terminator
* alacritty
* dunst
* Keyboard (Xmodmap)

## Setup Dotfiles

If `setup.sh` is executed, symbolic links of various setup files are created.
```
git clone https://github.com/roamer7038/dotfiles.git
cd dotfiles/
./setup.sh
```

If the option `-n` is added when executing `setup.sh`, `.vimrc` without plug-in is copied.

## Setup Applications

### Public key authentication

Run `bin/public_key.sh`.
```
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cd ~/.ssh
curl https://github.com/roamer7038.keys >> ~/.ssh/authorized_keys
chmod 600 authorized_keys
```

### Zsh

Recommended to use Z Shell as a login shell.
```
chsh -s $(which zsh)
```

### Homebrew

The missing package manager for macOS (or Linux). https://brew.sh/
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

