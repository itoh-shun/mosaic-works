---
name: verify-ui-visual
description: Playwrightスクリーンショット（デスクトップ+モバイル）とPencil比較の指示
---

# 指示: UI視覚検証

UI層の変更に対して視覚検証を行ってください。

## 手順

### Step 1: スクリーンショット取得

Playwrightで対象画面のスクリーンショットを取得する:

**デスクトップ（1280x720）:**
```bash
npx playwright screenshot --viewport-size=1280,720 {URL} desktop.png
```

**モバイル（375x667）:**
```bash
npx playwright screenshot --viewport-size=375,667 {URL} mobile.png
```

変更された全画面に対して実施する。

### Step 2: デザイン仕様との比較

デザイン仕様（.penファイル等）がある場合:
- Pencilツールを使って仕様と実装のスクリーンショットを比較する
- 仕様に存在しない要素の追加がないか確認する
- 色、間隔、フォントサイズの仕様との差異を確認する

### Step 3: 視覚チェック

- 意図しない変化がないか視認する
- レイアウト崩れ、文字の切れ、要素の重なりを確認する
- デスクトップとモバイルの両方で問題がないか確認する

### Step 4: 判定

| 結果 | 判定 |
|---|---|
| 問題なし | pass |
| 軽微な問題（微調整で解決） | warn — 修正指示を含める |
| 重大な問題（レイアウト崩れ等） | fail — 差し戻し |
| 仕様不明で判断できない | ask_user — ユーザーに確認 |

## 出力フォーマット

## UI Verification
- screenshots: [{ファイル名}: {画面名}, ...]
- comparison_result: pass | warn | fail | ask_user
- issues: [{問題の説明}, ...]
- recommendation: {修正指示またはユーザーへの質問}
