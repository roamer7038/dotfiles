# 概要
コード整形ツールのPrettierと構文チェッカーのESlintを併用して利用する際の手順を記す。
併用の仕方は複数あるが、今回は`prettier-eslint-cli`を利用した手法である。
なお、今回はJavaScriptのコーディング規約の1つである**JavaScript Standard Style**を利用する。

# インストール

## 前提
利用する主要なソフトウェアのバージョンは以下のとおり

ソフトウェア名称 | バージョン |
-----------|-----------|
nodejs | 11.13.0 |
yarn | 1.15.2 |
eslint | 5.16.0 |
prettier | 1.17.0 |

## ESLint

ESLint本体とその他プラグインを導入する。
`yarn add -D eslint eslint-config-standard eslint-plugin-standard eslint-plugin-promise eslint-plugin-import eslint-plugin-node`

`.eslintrc.json`を作成する。
```json
{
  "extends": "standard"
}
```

## Prettier

Prettierを導入する。
`yarn add -D prettier prettier-eslint prettier-eslint-cli`

`.prettierrc.json`を作成する。
```json
{
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "semi": false,
  "singleQuote": true,
  "trailingComma": "none",
  "bracketSpacing": true,
  "jsxBracketSameLine": false,
  "arrowParens": "always",
  "parser": "babel",
  "requirePragma": false,
  "insertPragma": false,
  "proseWrap": "preserve"
}
```

# 実行

`package.json`の`scripts`に以下の2つを追加する。
```json
"scripts": {
  "lint": "eslint .",
  "fmt": "prettier-eslint --write \"./**/*.js\" --ignore \"./node_modules/**\""
},
```

それぞれ実行する。
```shell
yarn lint
yarn fmt
```

# 参考
今回の内容のprettier-eslint-cliを利用するやり方
https://qiita.com/0x50/items/d0ee369d1f7c3e92a81e

eslint-config-prettierで競合するeslintのルールを無効化するやり方
https://qiita.com/shoichiimamura/items/0ba005889e3e90ee66d9#webpack%E3%81%A7%E3%83%93%E3%83%AB%E3%83%89%E6%99%82%E3%81%ABeslint%E3%82%92%E3%81%8B%E3%81%91%E3%82%8B
