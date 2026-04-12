---
name: team-roster
description: 役割別の能力マップ・得意領域
---

# チーム役割一覧（Team Roster）

## 役割→能力マップ

| 役割 | 専門領域 | 得意タスク | Review Focus |
|---|---|---|---|
| backend-lead | Kotlin/Ktor/Exposed、DB設計、トランザクション | BE新機能・修正（標準） | 言語慣用句、SQLクエリ効率性、トランザクション境界 |
| backend-domain | 複雑ドメインロジック、バリデーション設計 | BE複雑ドメイン | ドメインロジック正確性、バリデーション網羅性 |
| frontend-lead | React/TypeScript/MUI、レスポンシブ、a11y | FE新機能・修正（標準） | UI一貫性、レスポンシブ、アクセシビリティ |
| frontend-component | コンポーネント設計、フォーム、型安全性 | FEコンポーネント実装 | 再利用性、Props設計、型安全性 |
| architect | DDD、依存関係設計、設計言語化 | 設計判断・リファクタ | 依存方向、責務分離、命名/モデリング |
| tester | テスト設計（正常/異常/境界）、エッジケース | テスト追加 | カバレッジ、データ整合性、回帰リスク |
| e2e-tester | Playwright、CI安定化、レスポンシブ検証 | E2Eテスト | テスト安定性、ユーザーフロー、レスポンシブ |
| integrator | Gitマージ、競合解決、統合検証 | Wave統合 | マージ品質、ビルド通過 |
| content-creator | ドキュメント、コミットメッセージ、エラーメッセージ | コンテンツ制作 | ドキュメント品質、メッセージ設計 |
| project-manager | Git/PR管理、GitHub CLI、報告 | push/PR/報告 | ブランチ規約、PR品質 |
| qa-engineer | PRサイズ、テスト確認、UI検証 | 品質ゲート・UI検証 | 品質基準適用 |
| code-reviewer | 5軸レビュー、規約チェック、代替案提示 | コードレビュー | パフォーマンス/命名/テスト/セキュリティ/設計 |

## 選定ガイド

### 単一メンバー選定テーブル
| タスク種別 | 担当 |
|---|---|
| BE新機能・修正（標準） | backend-lead |
| BE複雑ドメイン | backend-domain |
| FE新機能・修正（標準） | frontend-lead |
| FEコンポーネント実装 | frontend-component |
| 設計判断が必要 | architect |
| テスト追加 | tester |
| E2Eテスト | e2e-tester |
| コンテンツ制作 | content-creator |

### 複数メンバー時の原則
- BE+FE横断を1人に集約しない。レイヤー専門のメンバーに分ける
- integrator はWave統合時に起動する
- code-reviewer は実装者とは別に起動する（独立性の確保）
