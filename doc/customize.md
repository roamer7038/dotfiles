# dotfiles のカスタマイズ

## Xmodmap

### CapsLockキーをControlキーに変更する
```
remove Lock = Caps_Lock
keysym Caps_Lock = Control_L
add Control = Control_L
```

### SuperキーとAltキーの位置を逆にする（HHKB向け）
```
remove Mod1 = Alt_L
remove Mod1 = Alt_R
remove Mod4 = Super_L
remove Mod4 = Super_R
keysym Alt_L = Super_L
keysym Alt_R = Super_R
keysym Super_L = Alt_L
keysym Super_R = Alt_R
add Mod1 = Alt_L
add Mod1 = Alt_R
add Mod4 = Super_L
add Mod4 = Super_R
```

## xprofile

### キーリピード速度を変更する
```
# xset r rate delay rate
xset r rate 300 30
```

### ThinkPadのタッチパッドを無効にする
```
synclient TouchpadOff=1
```

### NVIDIA GPUのファン速度を設定する
```
nvidia-settings -a "[gpu:0]/GPUFanControlState=1" -a "[fan:0]/GPUTargetFanSpeed=1"
```

## Compton

### GPUに応じた設定をする
```
backend = "glx";
```

## xrandr

### スクリプトによるマルチモニタ設定をする
`.config/i3/config`を編集し，起動時にスクリプトを読み込ませる．
```
exec --no-startup-id $HOME/.config/i3/monitor.sh
```

以下のような内容の`.config/i3/monitor.sh`を設置する．
```
xrandr --output DP-0 --primary --auto --output DVI-D-0 --auto --right-of DP-0
```

一部環境でi3からの起動で不具合が生じる．その場合，xprofileからmonitor.shを読み込ませる．
