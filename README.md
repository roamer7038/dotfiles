# dotfiles
### Common

* bash
* zsh
* screen
* vim
* git
* latex

### macOS

* homebrew

### Linux

* X
* i3wm
* i3status
* terminator

## setup

```
git clone https://github.com/roamer7038/dotfiles.git
cd dotfiles/
./setup.sh
```

#### Homebrew

http://brew.sh/index_ja.html

`setup.sh`を実行後，GitHub API Tokenが聞かれるので入力する．

#### nodebrew 
```
curl -L git.io/nodebrew | perl - setup
```

#### .DS_Storeを作らない
```
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
```

#### ログインシェルをZshにする
```
echo '/usr/local/bin/zsh' | sudo tee -a /etc/shells
chsh -s /usr/local/bin/zsh
```

#### 公開鍵認証

`install_key.sh`を実行する．

```
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cd ~/.ssh
curl https://github.com/roamer7038.keys >> ~/.ssh/authorized_keys
chmod 600 authorized_keys
```
