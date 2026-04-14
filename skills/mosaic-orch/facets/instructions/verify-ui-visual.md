---
name: verify-ui-visual
description: Playwrightスクリーンショット（デスクトップ/モバイル/ダークモード）による多面的UI検証
---

# 指示: UI視覚検証

UI層の変更に対して、複数のビューポート・テーマで視覚検証を行ってください。

## 手順

### Step 1: 事前準備

1. Playwright がインストールされているか確認する。なければ `npm install -D playwright && npx playwright install chromium`
2. 対象アプリのサーバーが起動していることを確認する（起動していなければ `npm start` や `npx vite` で起動）
3. 検証対象の全画面URLをリストアップする

### Step 2: マルチビューポート・マルチテーマ スクリーンショット取得

**全画面に対して以下の4パターンを取得する:**

```javascript
const { chromium } = require('playwright');

const viewports = [
  { name: 'desktop-light', width: 1280, height: 900, colorScheme: 'light' },
  { name: 'desktop-dark',  width: 1280, height: 900, colorScheme: 'dark' },
  { name: 'mobile-light',  width: 375, height: 667,  colorScheme: 'light' },
  { name: 'mobile-dark',   width: 375, height: 667,  colorScheme: 'dark' },
];

// 各ページ × 各ビューポートでスクリーンショット取得
for (const vp of viewports) {
  const context = await browser.newContext({
    viewport: { width: vp.width, height: vp.height },
    colorScheme: vp.colorScheme,
  });
  const page = await context.newPage();
  await page.goto(url);
  await page.waitForTimeout(2000);
  await page.screenshot({ path: `screenshots/${pageName}-${vp.name}.png`, fullPage: true });
  await context.close();
}
```

スクリーンショットは `.mosaic-orch/screenshots/` または `/tmp/` に保存する。

### Step 3: 各スクリーンショットをRead toolで確認

**全スクリーンショットをRead toolで読み込んで（画像ファイルを直接読む）、以下をチェックする:**

#### 3a. レイアウト検証
- 要素の重なり・切れがないか
- 余白の統一性（カード間、セクション間）
- テーブルの読みやすさ（罫線、ホバー効果）
- 空白が過剰に大きい領域がないか

#### 3b. ダークモード検証
- テキストとバックグラウンドのコントラスト比（WCAG AA: 4.5:1以上）
- ボーダーやシャドウがダークモードで見えるか
- バッジ・ステータスラベルの色がダークモードでも判読可能か
- 画像やアイコンがダークモードで適切に表示されるか

#### 3c. モバイル検証
- サイドバーが折りたたまれるか、またはハンバーガーメニューがあるか
- テーブルが横スクロールなしで表示されるか（または適切にスクロール可能か）
- タッチターゲットが44px以上か
- フォームの入力フィールドが十分な幅を持っているか

#### 3d. 一貫性検証
- フォントファミリー・サイズが画面間で統一されているか
- カラーパレットが一貫しているか
- ボタンスタイル（プライマリ/セカンダリ/デストラクティブ）が統一されているか
- ヘッダー表示が重複していないか

### Step 4: デザイン仕様との比較（仕様がある場合）

デザイン仕様（.penファイル等）がある場合:
- Pencil MCPツールを使って仕様と実装のスクリーンショットを比較する
- 色、間隔、フォントサイズの仕様との差異を確認する

### Step 5: 判定

| 結果 | 判定 | 基準 |
|---|---|---|
| 問題なし | pass | 全4パターンで問題なし |
| 軽微な問題 | warn | 余白不統一、微調整レベル |
| ダークモード未対応 | fail | `prefers-color-scheme: dark` 未実装、コントラスト不足 |
| モバイル非対応 | fail | レスポンシブ未実装、要素の切れ |
| レイアウト崩れ | fail | 重大な表示崩れ |
| 仕様不明 | ask_user | ユーザーに確認が必要 |

## 出力フォーマット

## UI Verification
- screenshots_taken: {枚数} ({画面数} pages × {パターン数} viewports)
- desktop_light: pass | warn | fail
- desktop_dark: pass | warn | fail
- mobile_light: pass | warn | fail
- mobile_dark: pass | warn | fail
- issues: [{問題の説明}, ...]
- dark_mode_support: full | partial | none
- responsive_support: full | partial | none
- design_consistency: pass | warn | fail
- overall: pass | warn | fail
- recommendation: {修正指示}
