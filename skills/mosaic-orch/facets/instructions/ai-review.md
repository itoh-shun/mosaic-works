---
name: ai-review
description: AI特有アンチパターン検出レビュー（幻覚API、過剰エンジニアリング、デッドコード、フォールバック濫用、スコープクリープ）
---

# 指示: AI アンチパターンレビュー

実装された差分に対して、AI生成コード特有のアンチパターンを検出してください。

## 前提

- 実装フェーズが完了し、差分が存在する
- Policy セクション（ai-antipattern）に検出基準が記載されている
- あなたは AI 特有の問題のみを扱う。パフォーマンス・命名・5軸レビューは後続の review stage が担当する

## レビュー手順

### Step 1: 変更差分の取得

```bash
git diff {base-branch}...HEAD
```

変更全体を把握する。

### Step 2: Policy 各検出基準の適用

Policy (ai-antipattern) の検出基準を順に適用する:

1. **仮定の検証**: 実装が要求と一致するか、既存規則に合うか
2. **もっともらしいが間違っている検出**: 幻覚API、古いパターン、配線忘れ
3. **コピペパターン検出**: 繰り返される問題、一貫性のない実装
4. **コンテキスト適合性評価**: 命名規則、エラーハンドリング、ログ、テストスタイル
5. **スコープクリープ検出**: 要求外機能、早すぎる抽象化、不要Legacy対応
6. **デッドコード検出**: 未使用関数、到達不能コード、論理的デッドコード
7. **フォールバック・デフォルト引数の濫用検出**: 必須データへのフォールバック、多段フォールバック
8. **未使用コードの検出**: 現在呼ばれていないpublicコード
9. **不要な後方互換コードの検出**: deprecated + 使用箇所なし、移行済みラッパー

### Step 3: finding_id 採番

各 finding に finding_id を採番する:
- 今回新規検出 → `AI-NEW-{file-slug}-L{line}`
- 前回指摘継続 → `AI-PERSIST-{file-slug}-L{line}`
- 前回指摘解消 → `AI-RESOLVED-{file-slug}-L{line}`

前回の ai-review 出力がある場合は照合し、persists/resolved を判定する。

### Step 4: 判定

- new または persists が 1 件でもあれば **REJECT**
- すべて resolved または指摘なしなら **APPROVE**
- finding_id なしの指摘は無効

## 重要な制約

- **あなたの出力はレビューレポートのみ。** コード修正は行わない
- 指摘は具体的に（ファイル:行番号、理由、修正案を明記）
- 「概ね良い」は APPROVE の根拠にならない
- 認知負荷軽減: 問題なしなら10行以内、ありなら該当セクションのみ30行以内

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

## AI Review
- verdict: APPROVE | REJECT

## Summary
{1文で結果を要約}

## Checks
| 観点 | 結果 | 備考 |
|------|------|------|
| 仮定の妥当性 | ✅/❌ | - |
| API/ライブラリの実在 | ✅/❌ | - |
| コンテキスト適合 | ✅/❌ | - |
| スコープ | ✅/❌ | - |
| デッドコード | ✅/❌ | - |
| フォールバック濫用 | ✅/❌ | - |

## Findings (new)
### Finding N
- finding_id: AI-NEW-{file-slug}-L{line}
- category: hallucinated_api | scope_creep | dead_code | fallback_abuse | context_mismatch | assumption | backward_compat
- location: {ファイルパス:行番号}
- problem: {具体的な問題}
- fix: {修正案}

## Findings (persists)
### Finding N
- finding_id: AI-PERSIST-{file-slug}-L{line}
- category: {前回と同じカテゴリ}
- prev_evidence: {前回の根拠}
- current_evidence: {今回の根拠}
- problem: {未解消の問題}
- fix: {修正案}

## Findings (resolved)
- finding_id: AI-RESOLVED-{file-slug}-L{line}
- evidence: {解消根拠}

（各セクションで finding がない場合は「なし」と記載）
