# dotfiles

* bash
* zsh
* screen
* vim

## setup

```
git clone https://github.com/roamer7038/dotfiles.git
cd dotfiles/
./setup.sh
```


### for Mac

#### Homebrew
http://brew.sh/index_ja.html

```
cd
touch .github_api_token
echo 'export HOMEBREW_GITHUB_API_TOKEN="[token]"' > .github_api_token
```

```
source .bashrc
cd ~/dotfiles
brew tap homebrew/bundle
brew bundle
```

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
```
curl https://github.com/roamer7038.keys >> ~/.ssh/authorized_keys
```
