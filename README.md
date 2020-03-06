# dotfiles

This repository manages and provides various configuration files. For example, `bash`,` zsh`, `vim`,` tmux`, and `git`, etc.... In addition, it holds configuration files managed by text, including GUI applications.

## Setup Dotfiles

If `bootstrap.sh` is executed, symbolic links of various setup files are created.
First, clone this repository in your home directory.
```
git clone https://github.com/roamer7038/dotfiles.git
cd dotfiles/
./bootstrap.sh
```

If the option `-n` is added when executing `bootstrap.sh`, `.vimrc` without plug-in is copied.
When run without any options, a `.vimrc` with the plugin will be placed.
Automatic installation of plug-ins starts as soon as you start Vim. At that time, the following commands are required.

* make
* go (Only the translation plugin depends.)
* nodejs
* yarn (nodejs package manager)

If you are a Golang user, execute the following command `:GoInstallBinaries` after starting Vim.

## Setup additionally

### Git config

Edit `.gitconfig` and change it to your username and Email.
```
[user]
	name = username
	email = your@example.com
```

### Login shell 

Recommended to use Z Shell as a login shell.
```
chsh -s $(which zsh)
```

### SSH public key authentication

Change to your user name and execute the following.
```
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cd ~/.ssh
curl https://github.com/roamer7038.keys >> ~/.ssh/authorized_keys
chmod 600 authorized_keys
```
