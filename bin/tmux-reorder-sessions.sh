#!/bin/bash
#
# 歯抜けになった tmux のセッション番号を 0 から連番に振り直す
# （0, 1, 5, 7 -> 0, 1, 2, 3）。対象は数字で始まるセッション名のみ。
# アタッチ中のセッションの番号も変わる。.tmux.conf のフックから呼ばれる。

sessions=$(tmux ls | grep -E '^[0-9]*:' | cut -f1 -d':' | sort)

new=0

for old in $sessions; do
  tmux rename -t $old $new
  ((new++))
done
