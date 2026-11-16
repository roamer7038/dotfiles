---
name: wsl-chrome
description: WSL から Windows 側の Chrome を起動し、ページの見た目・DOM・コンソール・ネットワークを確認する。実装したページのレイアウト確認、スクリーンショットの取得、表示崩れやコンソールエラーの調査に使う。
---

# ページをブラウザで確認する

chrome-devtools MCP は自分でブラウザを起動しない（`--autoConnect` で既存インスタンスに接続する設定になっている）。
先に `wsl-chrome` で Chrome を起動しておく必要がある。
起動してあれば、MCP を再起動したりポートを気にしたりする必要はない。

## 手順

1. 起動しているか確認する。

```bash
wsl-chrome status
```

2. 起動していなければ起動する。エージェントだけで作業するならヘッドレスを使う。

```bash
wsl-chrome debug --headless   # 画面に出さない。ビューポートは 1280x800
wsl-chrome debug              # 人が同じ画面を見るとき
```

3. chrome-devtools MCP のツールでページを操作する。

- `new_page` に URL を渡してページを開く。ローカルファイルは `file://` 形式にする
- `list_pages` で開いているページと番号を得る
- 以降のツールは `pageId` に数値を渡す。文字列は弾かれる
- `take_screenshot` で見た目、`take_snapshot` で DOM、`list_console_messages` でエラーを見る
- 画面幅を変えて確認するときは `emulate` の `viewport`（例 `375x667`、`375x667x2,mobile,touch`）を使う

4. 作業が終わったら止める。人が画面を見ている場合は残しておく。

```bash
wsl-chrome stop
```

## 詰まったとき

| 症状 | 対処 |
| --- | --- |
| MCP がブラウザに接続できない | Chrome が起動していない。`wsl-chrome debug --headless` を実行する |
| `debug` がモードの違いを理由に終了する | 別のモードで起動済み。`wsl-chrome stop` してから起動し直す |
| `resize_page` で幅を狭めても 512px より狭くならない | Windows のウィンドウ最小幅による制限。狭い幅は `emulate` の `viewport` で指定する |

詳細は `~/dotfiles/docs/wsl-chrome.md` を参照する。
