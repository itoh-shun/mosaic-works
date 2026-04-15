---
name: skill-catalog
description: 利用可能なSkill一覧とトリガー条件
---

# Skill Catalog

エージェントに渡すスキル名を選定するための参考カタログ。スキルの内容はエージェントに事前読み込みさせず、名前だけ渡して作業中に必要時にSkill toolで起動させる。

## タスク種別別 推奨スキル

### バックエンド開発
| トリガー | スキル例 |
|---|---|
| Kotlin慣用句・パターン | `kotlin-specialist` |
| DB、クエリ、インデックス、マイグレーション | `postgres`, `postgresql-database-engineering` |
| TDD、ユニットテスト | `tdd`, `superpowers:test-driven-development` |
| 認証、認可、OWASP | `owasp-security` |

### フロントエンド開発
| トリガー | スキル例 |
|---|---|
| React、コンポーネント、hooks | `react-patterns`, `vercel-react-best-practices` |
| パフォーマンス、レンダリング | `react-performance-optimization` |
| Props設計、合成パターン | `vercel-composition-patterns` |
| UI実装、デザイン→コード変換 | `frontend-implementation` |
| アクセシビリティ | `accessibility`, `accessibility-engineer` |
| ブランド一貫UI、`Stripe風` / `Linear風` など特定ブランドスタイル | `awesome-design-md` |

### テスト・品質
| トリガー | スキル例 |
|---|---|
| E2E、Playwright | `playwright-e2e-testing`, `playwright-skill` |
| Playwrightスキャフォールド | `playwright-scaffolder` |
| TDD | `tdd` |

### レビュー・品質ゲート
| トリガー | スキル例 |
|---|---|
| コードレビュー | `code-review`, `code-review-and-quality` |
| 簡素化・リファクタ | `simplify` |

### ドキュメント
| トリガー | スキル例 |
|---|---|
| 仕様書、API文書 | `technical-writing` |

## スキル選定の原則
1. タスク内容のキーワードから該当カテゴリを特定
2. 利用可能なスキル一覧と突合（Agent起動時にSkill toolのリストを参照）
3. 必要なスキル名のみをエージェントに渡す（内容はオンデマンド読み込み）
4. 1タスクあたり2〜4スキル程度に絞る
