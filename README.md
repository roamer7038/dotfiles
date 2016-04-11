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

#### nodebrew 
```
curl -L git.io/nodebrew | perl - setup
```

#### .DS_Storeを作らない
```
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
```
