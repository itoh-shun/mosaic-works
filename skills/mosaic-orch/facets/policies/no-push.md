---
name: no-push
description: 実装中はgit pushしないポリシー。pushはfinalize stageのみ。
---

# No-Push ポリシー

## ルール
- 実装→レビュー→修正のサイクルはすべてローカルコミットのみで行う
- `git push` は finalize stage でのみ実行する
- 中間段階での push は禁止（Draft PRの早期作成も禁止）

## 理由
- レビュー修正のforce-pushを避ける
- 全ブランチの一括push + PR作成でCI実行を効率化する
- PRの「レビュー前pushによるノイズ」を防ぐ

## 違反時の対応
- 実装agent内で push コマンドが実行された場合、品質ゲートでFAILとする
