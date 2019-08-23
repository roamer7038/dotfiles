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

## Setup Dotfiles

If `setup.sh` is executed, symbolic links of various setup files are created.
```
git clone https://github.com/roamer7038/dotfiles.git
cd dotfiles/
./setup.sh
```

If the option `-nox` is added when executing `setup.sh`, `.vimrc` without plug-in is copied.

## Setup Applications

### Homebrew

The missing package manager for macOS (or Linux). https://brew.sh/
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### Yay

An AUR Helper.
```
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

### Public key authentication

Run `bin/public_key.sh`.
```
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cd ~/.ssh
curl https://github.com/roamer7038.keys >> ~/.ssh/authorized_keys
chmod 600 authorized_keys
```

### anyenv

All in one for \*\*env https://anyenv.github.io

#### Install

Manual git checkout:
```
git clone https://github.com/anyenv/anyenv ~/.anyenv
~/.anyenv/bin/anyenv init
```

Homebrew:
```
brew install anyenv
anyenv init
```

AUR:
```
yay -S anyenv
anyenv init
```

#### env install

example:
```
anyenv install nodenv
exec $SHELL -l
nodenv install ...
```

#### env update

```
anyenv install --init https://github.com/foo/anyenv-install.git
anyenv install --update
```

### ranger

ranger is a text-based file manager written in Python.

#### PDF preview
Edit the `~/.config/ranger/rc.conf`
```
# Use one of the supported image preview protocols
set preview_images true
```

and, add preview command to `~/.config/ranger/scope.sh`.
```
# Image previews, if enabled in ranger.
if [ "$preview_images" = "True" ]; then
    case "$mimetype" in
        application/pdf)
             pdftoppm -jpeg -singlefile "$path" "${cached//.jpg}" && exit 6;;
    esac
fi
```

To use it, you need to install `w3m` and` poppler`.

