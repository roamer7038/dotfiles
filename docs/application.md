# Additional Application Setup

### Homebrew

The missing package manager for macOS (or Linux). https://brew.sh/
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
or
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

## Yay

An AUR Helper.
```
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

## anyenv

All in one for \*\*env https://anyenv.github.io

### Install

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

### env install

example:
```
anyenv install nodenv
exec $SHELL -l
nodenv install ...
```

### env update

```
anyenv install --init https://github.com/foo/anyenv-install.git
anyenv install --update
```

## ranger

ranger is a text-based file manager written in Python.

### PDF preview
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

