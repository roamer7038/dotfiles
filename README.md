# dotfiles

roamer7038's Linux Desktop/Server Environment Configuration.

The following basic software is assumed.
- Vim
- Tmux
- Zsh

The desktop environment is i3wm.

## Installation

Setup requires the `make` command.
Generates a symbolic link to the configuration file in the home directory.

#### Minimum Setup

Generates symbolic links to minimal configuration files.
(.bashrc .zshrc .tmux.conf .gitconfig .latexmkrc)

```
make minimum
```

#### Basic Setup

In addition to minimum setup, it generates symbolic links to additional application configuration files.
To enable the vim plugin, `vim8` or later, `golang`, `nodejs`, `npm`, and `yarn` are required.
(minimum + terminator, dunst, ranger, vim (+plugins))

```
make basic
```

#### Full Setup


In addition to the basics setup, enable i3wm settings. (basic + i3wm)

```
make full
```

## Add Development Environment

### anyenv

Install additional programming language execution environments.
[anyenv](https://github.com/anyenv/anyenv) can add multiple versions of multiple programming languages to your userland.

```
git clone https://github.com/anyenv/anyenv ~/.anyenv
~/.anyenv/bin/anyenv init
anyenv install --init
```

Add the execution path.

```
export PATH="$HOME/.anyenv/bin:$PATH"
```

...and more.

```
anyenv install rbenv
anyenv install pyenv
anyenv install nodenv
exec $SHELL -l

rbenv install ...
pyenv install ...
nodenv install ...
```

> rbenv requires the following packages:
`apt install -y build-essential libssl-dev zlib1g-dev libyaml`

## Customize

### Git

Edit `.gitconfig` and change it to your username and Email.
```
[user]
	name = username
	email = your@example.com
```

### SSH public key authentication

Change to your user name and execute the following.
```
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cd ~/.ssh
curl https://github.com/roamer7038.keys >> ~/.ssh/authorized_keys
chmod 600 authorized_keys
```
