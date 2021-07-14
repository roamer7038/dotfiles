# dotfiles

roamer7038's dotfiles.

## Installation


minimum setup (ex. server):

```
make
```

i3wm + vim (`nodejs`, `yarn` are required):

```
make i3
make develop
```

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
