---
name: check-duplicates
description: 既存PR/Issueとの重複チェック指示
---

# 指示: 重複チェック

タスクの内容に対して、既存のPR/Issueとの重複を確認してください。

## 手順

### Step 1: PR検索

```bash
gh pr list --state open --search "{タスクのキーワード}" --limit 5
```

### Step 2: Issue検索

```bash
gh issue list --state open --search "{タスクのキーワード}" --limit 5
```

### Step 3: 判定

- 類似のPR/Issueが見つかった場合: ユーザーに確認を求める
- 見つからなかった場合: 重複なしとして続行

## 出力フォーマット

## Duplicate Check
- has_duplicate: true | false
- existing_prs: [{番号}: {タイトル}, ...]
- existing_issues: [{番号}: {タイトル}, ...]
- recommendation: proceed | ask_user
- message: {ユーザーへの確認メッセージ（重複時のみ）}
