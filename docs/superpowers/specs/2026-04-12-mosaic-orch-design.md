# Mosaic-Orch — Faceted Orchestration Skill 設計仕様

- **日付**: 2026-04-12
- **ステータス**: Draft(ユーザーレビュー待ち)
- **種別**: 新規Skill設計
- **関連**: faceted-prompting (nrslib/faceted-prompting), intendant, radio-writer, TAKT

---

## 0. Executive Summary

**Mosaic-Orch**(仮称)は、faceted-promptingのSoC原則を尊重したまま、**Stage / Fan-out-Fan-in / Rubric Facet** の3拡張で「単一プロンプトの合成」から「多段オーケストレーション」へと橋渡しする、ドメイン非依存の薄いオーケストレーターSkillである。

既存の`intendant`・`radio-writer`・`TAKT`で暗黙的に実装されていたパターン(多段レビュー、Wave並列、評価ループ)を、**宣言的YAMLワークフロー**として明示的に表現し直すことが主題。新発明ではなく「整理と明示化」が目的。

### 3つのオリジナル拡張

1. **Stage + Output Contract** — 工程の関心を分離し、Stage境界で出力型を強制
2. **Fan-out / Fan-in プリミティブ** — 1タスクを関心軸でN分解→並列→統合
3. **Rubric Facet(第5Facet)** — faceted-promptingの4Facet(Persona/Policy/Knowledge/Instruction)に評価基準用のRubricを純粋追加。PolicyとRubricを明確にSoC分離

### 既存Skillとの関係

- **置き換えない**: intendantは開発ドメインの専用オーケストレーターとして残る
- **共存する**: Mosaic-Orchはドメイン非依存(コンテンツ制作、調査、分析、ビジネスプロセス等)
- **踏襲する**: intendant/radio-writer/TAKTのパターンを整理して宣言化する

---

## 1. アーキテクチャ概要と層分離

### 1.1 目的

faceted-promptingのSoC原則を尊重したまま、Stage/Fan-out/Rubricの3拡張で「単一プロンプト合成」から「多段オーケストレーション」へと橋渡しする、ドメイン非依存の薄いオーケストレーターSkill。

### 1.2 層構造(依存は一方向)

```
┌──────────────────────────────────────────────┐
│ L1: Entry           — SKILL.md (~80行)       │  ユーザー接点。引数解析と L2 への委譲のみ
├──────────────────────────────────────────────┤
│ L2: Orchestrator    — engine/orchestrator.md │  Workflow状態機械。Stage順序、Fan-out/in、
│                                              │  Loop、条件分岐を司る
├──────────────────────────────────────────────┤
│ L3: Stage Runner    — engine/stage-runner.md │  1 Stageの実行を担当。facet解決 → 合成 →
│                                              │  サブエージェント起動 → output契約検証
├──────────────────────────────────────────────┤
│ L4: Composer        — engine/composer.md     │  faceted-promptingのcompose相当。5Facetを
│                                              │  決定論的にsystem/userプロンプトへ配置
├──────────────────────────────────────────────┤
│ L5: Dispatcher      — engine/dispatcher.md   │  Task tool呼び出しラッパー。権限モード、
│                                              │  並列起動、結果回収
└──────────────────────────────────────────────┘

横断:
┌──────────────────────────────────────────────┐
│ engine/contracts.md   — Output Contract検証  │
│ engine/facet-loader.md — Facet解決器         │
│ engine/yaml-schema.md  — Workflow YAML仕様   │
│ engine/variable-resolver.md — ${} 展開       │
│ engine/run-recorder.md — .mosaic-orch/runs/* 記録  │
└──────────────────────────────────────────────┘

資産:
┌──────────────────────────────────────────────┐
│ facets/{personas,policies,knowledge,         │
│        instructions,rubrics}/*.md            │
│ contracts/*.md                               │
│ workflows/*.yaml                             │
└──────────────────────────────────────────────┘
```

### 1.3 層間の契約

| 層 | 入力 | 出力 | 知らないこと |
|---|---|---|---|
| L1 | ユーザー引数 | workflow名 + タスク入力 | Stage / Facet / エンジン内部 |
| L2 | workflow YAML + 入力 | 全Stage実行結果 | Facet合成方法 / Task tool |
| L3 | 1 Stage定義 + 入力 | Stage出力 + 契約検証済 | Workflow全体 / 次Stage |
| L4 | 5Facetセット | system/userプロンプト | Stage / 実行 |
| L5 | プロンプト + 権限 | サブエージェント出力(文字列) | プロンプト合成方法 |

**重要原則**:
- **L4(Composer)はfaceted-promptingの純粋な再実装**にとどめ、Stageの概念もFan-outも知らない
- **L3はL4を知っているがL2を知らない**。Stage Runnerは次Stageを決めない
- **L5はペイロードしか知らない**。facet構造から切り離されており将来モックやDry-runも容易

### 1.4 Skill内部SoCの効き目

現状intendantの問題: SKILL.md 1ファイルに「チーム選定」「Git/PR」「品質ゲート」「レビュー」「ログ」が全部混在(約580行)。1つの関心を変えると他も壊れる。

Mosaic-Orchの対応: **1ファイル1関心**。`Rubric`の採点ロジックを変えたければ `engine/contracts.md` を1ファイルいじれば終わる。Fan-outの並列度を変えたければ `engine/orchestrator.md` だけ。Composer(プロンプト合成)は一切触らない。

---

## 2. 5 Facetモデル(Rubric Facetの追加)

### 2.1 Facet一覧

faceted-promptingの4Facetはそのまま尊重し、**第5Facetとして`Rubric`を追加**する。追加だけで、既存Facetの意味・配置は変更しない(非破壊拡張)。

| Facet | 役割 | 応答時に効く側面 | プロンプト配置 | 新規 |
|---|---|---|---|---|
| **Persona** | WHO — 実行者の同一性 | キャラクター、声、得意分野 | systemプロンプト | — |
| **Policy** | HOW — 実行中の行動規範 | やってよいこと・ダメなこと | userメッセージ | — |
| **Knowledge** | WHAT TO KNOW — 前提知識 | ドメイン知識、アーキ、過去経緯 | userメッセージ | — |
| **Instruction** | WHAT TO DO — やるべきこと | 今回の具体タスク | userメッセージ | — |
| **Rubric** | HOW TO BE JUDGED — 評価基準 | 何を満たせば合格か、採点軸 | userメッセージ(末尾) | ★ |

### 2.2 なぜRubricをPolicyから分離するのか

`Policy`と`Rubric`は似ているが**関心が別**。分けないとレビュー・評価ステージでSoCが必ず崩れる。

| 観点 | Policy | Rubric |
|---|---|---|
| 誰向けか | **実行者**向け | **評価者**向け |
| いつ効くか | タスク実行中 | タスク完了後の採点時 |
| 時制 | 命令形「〜せよ」 | 評価軸「〜を満たしているか」 |
| 逆転のしかた | 破ると失敗 | 満たすと合格 |
| 例 | 「any型を使うな」「N+1を書くな」 | 「正確性 S/A/B/C」「読者ターゲット適合度 S/A/B/C」 |

**具体的落とし穴**: 既存多くのレビュープロンプトが`policies: [code-quality]`を実行者にもレビュー者にも渡している。しかし実行者に必要なのは「any型を使うな」(行動規範)、レビュー者に必要なのは「any型がないか5段階で採点せよ」(評価観点)。同じ情報源だが**役割が違う**ため、Rubricとして分離して書き、該当Stageだけに注入する。

### 2.3 Rubric Facetの内容構造

Rubricは単なるMarkdownファイルだが、**採点軸・評価段階・出力フォーマット**を持つのを慣例とする。エンジンは内容をパースせず、そのままプロンプトに埋めるだけ(SoC: エンジンはRubricの中身を知らない)。

慣例フォーマット例:
```markdown
---
name: clarity
description: 読み手への伝達のクリアさを評価する
---

# 評価軸: Clarity(伝達の明晰さ)

## 採点段階
- S: 再読不要。1度で伝わる
- A: 小さな引っかかりあり。8割の読者に1度で伝わる
- B: 2回読まないと伝わらない箇所が3つ以上
- C: 前提知識が足りず、伝わらない

## 採点時に観察すること
- 主語と述語の対応
- 専門用語の説明
- 指示代名詞の曖昧さ

## 出力フォーマット
grade: {S|A|B|C}
evidence: <採点の根拠を1-3個の具体的引用で>
suggestions: <改善提案を0-3個>
```

### 2.4 ファイル配置

faceted-promptingの流儀に合わせる:

```
facets/
├── personas/{name}.md
├── policies/{name}.md
├── knowledge/{name}.md
├── instructions/{name}.md
└── rubrics/{name}.md    ← 新規
```

### 2.5 Workflow YAMLからの参照

Facetは**Stageごとに宣言**する。同じWorkflow内の別Stageは別のFacetセットを持てる。

```yaml
- id: review
  facets:
    persona: reviewer
    knowledge: [project-context]
    rubrics: [clarity, flow, tone]   # 複数Rubricを合成可
    instructions: [apply-rubrics]
```

**決定論的配置ルール**(Composer=L4の責務):
```
systemプロンプト:  Persona のみ
userメッセージ:    Knowledge → Instruction → Policy → Rubric(末尾)
```

Rubricを末尾に置くのは、直前のInstruction/Policyの文脈を踏まえた上で**「この観点で自己評価せよ」**と最後に命じるのが一番効くため(プロンプトエンジニアリング上の経験則)。

### 2.6 Repertoire参照(非対応)

faceted-promptingには `@owner/repo/facet-name` のスコープ参照がある。初版Mosaic-Orchは**ローカルの `facets/` 直下参照のみサポート**し、repertoireは**意図的に対象外**とする:
- SoCの観点で「facet解決方法」はL4 Composerの責務だが、repertoire解決は外部ファイルシステムと結合する
- 将来必要になったら `engine/facet-loader.md` を差し替えれば足りる(インタフェースは変えない)
- YAGNI

---

## 3. Workflow YAMLスキーマ

### 3.1 設計方針

- **宣言的**: 実行順序・依存・繰り返しはYAMLで宣言し、エンジンは解釈するだけ
- **最小限**: 1つの機能=1つのキー(`fan_out`はfan-outしかしない、`when`は条件分岐しかしない)
- **予測可能**: 同じYAML + 同じ入力 → 同じ実行計画
- **平坦**: TAKTより入れ子を減らす

### 3.2 トップレベルスキーマ

```yaml
name: string                 # 必須 - workflow識別子
description: string          # 任意 - 人間向け説明
version: "1"                 # 必須 - スキーマバージョン

inputs:                      # 任意 - ユーザーから受け取るパラメータ宣言
  - name: topic
    type: string
    required: true

defaults:                    # 任意 - 全Stage共通のデフォルト値
  permission: default        # "default" | "acceptEdits" | "bypassPermissions"
  timeout: 600

stages:                      # 必須 - Stage配列(宣言順が実行順)
  - <StageDefinition>
  - <StageDefinition>
```

### 3.3 Stage種別(3つだけ)

Stageは**3種類のみ**。合成や入れ子はしない。

```yaml
kind: task      # 通常Stage: 1サブエージェントで1タスク実行
kind: fan_out   # 分解Stage: N個の並列タスクに展開
kind: fan_in    # 統合Stage: 直前のfan_out結果を1つに集約
```

### 3.4 task Stage

```yaml
- id: gather                      # 必須 - stage識別子(unique)
  kind: task
  facets:                         # 必須 - Facet参照
    persona: analyst
    knowledge: [project, domain]
    policies: [storytelling]
    instructions: [gather-activity]
    rubrics: []

  input: ${workflow.inputs.topic}
  output_contract: activity-log

  when: ${review.output.grade} < 'A'  # 任意 - 条件実行(前Stageの結果を明示参照)
  loop_until: ${self.grade} >= 'A'    # 任意 - 自己ループ(同Stage内で再試行)
  max_iterations: 3                   # loop_until使用時に必須

  permission: acceptEdits
  timeout: 900
```

### 3.5 fan_out Stage

```yaml
- id: draft
  kind: fan_out
  from: ${plan.output.sections}   # 必須 - 反復対象(配列)
  as: section                     # 必須 - 各要素の変数名
  max_parallel: 4                 # 任意 - 並列度の上限

  facets:
    persona: writer
    instructions: [draft-section]
  input: ${section}
  output_contract: section-draft
  permission: acceptEdits
```

**動作**: `from`の配列長 = 並列サブエージェント数。全サブエージェント完了まで次Stageには進まない(同期バリア)。出力は配列として `${draft.outputs}` で参照される。

**エラー時**: 1つでも失敗したら**全fan_out Stage失敗**(デフォルト)。`on_error: continue`オプションで部分成功を許す。

### 3.6 fan_in Stage

```yaml
- id: assemble
  kind: fan_in
  from: ${draft.outputs}          # 必須 - 統合対象
  facets:
    persona: editor
    instructions: [merge-sections]
  input: ${draft.outputs}
  output_contract: full-document
```

**動作**: 通常のtask Stageとほぼ同じだが、入力が配列である前提で、エンジンが自動的にサブエージェントへの提示形式を整える(各要素に見出し付き、元Stage ID明記など)。

### 3.7 変数参照文法

| 参照 | 意味 |
|---|---|
| `${workflow.inputs.X}` | ユーザー入力 |
| `${<stage_id>.output}` | 指定StageのOutput全体 |
| `${<stage_id>.output.field}` | 指定StageのOutput内の特定フィールド |
| `${self.X}` | loop_until内で自分自身の出力を参照 |
| `${<var>}` | fan_outの`as`で宣言した変数 |

**非対応**(意図的): 関数呼び出し、算術、ループカウンタ、文字列結合。複雑な変換が欲しければ間に1つtask Stageを挟む(分解の圧力になる)。

### 3.8 完成例: ラジオ台本生成ワークフロー

```yaml
name: radio-script
version: "1"
description: お題からラジオ台本を生成、多角レビューで A+ まで磨く

inputs:
  - name: topic
    type: string
    required: true

defaults:
  permission: acceptEdits

stages:
  - id: plan
    kind: task
    facets:
      persona: radio-planner
      knowledge: [broadcast-format]
      instructions: [plan-corners]
    input: ${workflow.inputs.topic}
    output_contract: corner-plan

  - id: draft
    kind: fan_out
    from: ${plan.output.corners}
    as: corner
    facets:
      persona: radio-writer
      policies: [tone-casual]
      instructions: [draft-corner]
    input: ${corner}
    output_contract: corner-draft

  - id: assemble
    kind: fan_in
    from: ${draft.outputs}
    facets:
      persona: editor
      instructions: [assemble-script]
    output_contract: full-script

  - id: review
    kind: task
    facets:
      persona: reviewer
      rubrics: [clarity, humor, pace, accuracy]
      instructions: [multi-axis-review]
    input: ${assemble.output}
    output_contract: review-verdict    # { grade, evidence, suggestions }

  - id: polish
    kind: task
    when: ${review.output.grade} < 'A'
    facets:
      persona: editor
      rubrics: [clarity, humor, pace, accuracy]   # 自己採点にも同じrubricを使う
      instructions: [apply-suggestions-and-self-assess]
    input: ${assemble.output}
    loop_until: ${self.grade} >= 'A'
    max_iterations: 3
    output_contract: polished-verdict  # { script, grade, evidence } — 自己採点込み
```

**注**: `polish` stageはRubricを使って**自己採点まで同stage内で完結**させる(executionとself-assessmentを1ステップに束ねる)。loop_untilが `${self.grade}` を参照できるように、output_contractがgradeフィールドを含む必要がある。同じRubricがreview stageと polish stageで使い回される点が、RubricをFacetとして独立させた効き目の具体例。

---

## 4. エンジン動作モデル

### 4.1 L2 Orchestratorの状態機械

Orchestratorは**単純な状態機械**。複雑な遷移ロジックは持たない(TAKTより意図的に貧弱に保つ)。

```
[INIT] → [RESOLVE_STAGE] → [CHECK_WHEN] → [RUN_STAGE] → [CHECK_CONTRACT] → [CHECK_LOOP] → [ADVANCE] → [COMPLETE]
                                   ↓ false                ↓ fail                ↓ retry            ↑
                                 [SKIP] ─────────────→ [ABORT]               (back to RUN_STAGE)
```

| 状態 | 責務 | 委譲先 |
|---|---|---|
| INIT | YAML読み込み、inputs検証 | yaml-schema.md |
| RESOLVE_STAGE | 次Stage特定、変数展開 | variable-resolver.md |
| CHECK_WHEN | `when` 条件評価 | 自力 |
| RUN_STAGE | 実行をL3に委譲 | stage-runner.md |
| CHECK_CONTRACT | 出力契約検証 | contracts.md |
| CHECK_LOOP | `loop_until`評価 | 自力 |
| ADVANCE | 次Stageポインタ更新 | 自力 |
| ABORT / COMPLETE | 終了処理 | run-recorder.md |

**重要**: Orchestratorは**Facetを知らない**、**プロンプト合成方法を知らない**、**サブエージェント起動方法も知らない**。L3-L5に完全委譲する。

### 4.2 L3 Stage Runnerの実行フロー

**task Stage**:
```
1. Composer(L4)にfacetセットを渡して system/user プロンプトを取得
2. 入力変数(input)を user メッセージ末尾に "## 入力" として追記
3. Dispatcher(L5)にプロンプト + permission を渡して1サブエージェント起動
4. サブエージェント出力を受け取り、output_contract の形式に整形
5. 契約検証(contracts.md)
6. 成功なら出力を返す、失敗なら例外
```

**fan_out Stage**:
```
1. from の配列長 N を決定(変数展開)
2. 各要素ごとに task Stage と同じ流れでプロンプト合成(N個)
3. Dispatcher(L5)に N個のプロンプトを渡し、1メッセージで並列にTask tool起動
4. 全員完了を待機(max_parallel で分割実行する場合はバッチ化)
5. 出力配列 [out_1, out_2, ..., out_N] を契約検証
6. エラー: デフォルトは1つ失敗で Stage失敗。on_error: continue なら成功分のみ返す
```

**fan_in Stage**:
```
1. from の配列を受け取り、user メッセージに "## 統合対象" として整形して追記
   (各要素に "### Item i (from stage X)" の見出しを付与)
2. 以降は task Stage と同じ(1サブエージェント起動)
```

### 4.3 L4 Composerの決定論的プロンプト合成

faceted-promptingのcompose相当。**純粋関数**として実装し、外部状態を持たない。

```
入力: FacetSet { persona, policies[], knowledge[], instructions[], rubrics[] }
      + ComposeOptions { order }

処理:
  1. persona ファイルの本文を Read → system プロンプト
  2. user メッセージを空配列で開始
  3. order に従って各facet群を追記(デフォルト順: knowledge → instructions → policies → rubrics)
  4. 各群の内部順はYAMLでの宣言順
  5. 群の間に見出し("## Knowledge", "## Instructions" など)を自動挿入
  6. user メッセージを改行結合で返す

出力: { systemPrompt: string, userMessage: string, sourceFiles: string[] }
```

**faceted-promptingとの違い**: `rubrics` を追加、デフォルト順を `knowledge → instructions → policies → rubrics` に変更(元は `knowledge → instructions → policies`)。Rubricは必ず最後。

### 4.4 L5 Dispatcherの並列起動ルール

```
単発実行(task / fan_in):
  1つのTask呼び出し、同期的に結果を受け取る

並列実行(fan_out):
  1つのメッセージで N個 の Task を同時に呼び出す
  (superpowers:dispatching-parallel-agents と同じパターン)
  全Task完了後、結果配列を返す

max_parallel がある場合:
  N を max_parallel でバッチ化し、バッチ単位で並列実行
  バッチ間は順次
```

Dispatcherは**プロンプトの中身を知らない**、**contract検証にも関与しない**。

### 4.5 Output Contractの検証

契約ファイルは `contracts/{name}.md` に置く。内容は「期待する出力の形式説明 + パース規則 + 検証項目」。

```markdown
---
name: review-verdict
description: 多角レビューの総合判定
---

# Output Contract: review-verdict

## 期待形式
マークダウンで以下を含むこと:
- "## Grade" 見出しの直下に S/A+/A/B/C のいずれか1つ
- "## Evidence" 見出しの直下に根拠の引用
- "## Suggestions" 見出しの直下に 0-3 個の改善提案

## パース規則(エンジンが抽出)
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- evidence: "## Evidence" から "## Suggestions" まで
- suggestions: "## Suggestions" から末尾まで、箇条書きを配列化

## 検証項目
- grade が正規表現にマッチすること(必須)
- evidence が空でないこと(必須)
- suggestions の件数が 0-3 の範囲(必須)
```

Stage Runnerがこの契約を参照して**(1) 抽出 (2) 検証 (3) 構造化**を行う。失敗した場合は2回まで同Stageを再実行。それでも失敗ならStage失敗 → ABORT(loop_untilがあればループ再試行)。

**SoCの効き目**: 契約の定義と検証方法は全部 `contracts/` と `contracts.md` に閉じ込められる。StageもOrchestratorも「契約が満たされているか」だけを知り、**何をもって満たされるかは知らない**。

### 4.6 ループ制御(loop_until)

Stage Runner内で完結する(Orchestratorは知らなくて良い):

```
iteration = 1
while iteration <= max_iterations:
  1. Stage を実行
  2. 契約検証(失敗時は例外)
  3. self 変数に今回の出力をバインド
  4. loop_until 条件を評価
  5. true → ループ終了、出力を返す
  6. false → iteration += 1、continue

iteration > max_iterations なら:
  最終出力を返すが、flag loop_exhausted=true を付与
  Orchestrator側で次Stageの when 条件が flag を見て分岐できる
```

### 4.7 実行ログと観測

Mosaic-Orchの実行は`.mosaic-orch/runs/{timestamp-slug}/`に記録する(TAKTの`.takt/runs/`に倣う)。

```
.mosaic-orch/runs/20260412-115400-radio-script/
├── workflow.yaml            # 実行に使ったYAMLのコピー
├── inputs.json              # ユーザー入力
├── trace.ndjson             # 各Stageの開始/終了/結果をJSON Lines
├── stages/
│   ├── plan/
│   │   ├── prompt.md        # Composerが組み立てたプロンプト
│   │   ├── response.md      # サブエージェントの出力
│   │   └── extracted.json   # contract抽出結果
│   ├── draft-1/ ... draft-N/
│   └── assemble/
└── final.md                 # 最終出力
```

Debug / 再現 / トレース性のため、全成果物を残す。

---

## 5. Skill内部のファイル構造(SoCの具現化)

### 5.1 ディレクトリ全体

```
~/.claude/skills/mosaic-orch/
├── SKILL.md                        # L1 Entry(~80行)
│
├── engine/                         # エンジン層 — 各ファイル 1責務
│   ├── orchestrator.md             # L2: 状態機械、Stage順序
│   ├── stage-runner.md             # L3: Stage実行(task/fan_out/fan_in)
│   ├── composer.md                 # L4: Facet合成(faceted-prompting相当)
│   ├── dispatcher.md               # L5: Task tool呼び出し
│   ├── facet-loader.md             # Facet解決(横断)
│   ├── contracts.md                # Output Contract検証(横断)
│   ├── yaml-schema.md              # Workflow YAMLスキーマ定義
│   ├── variable-resolver.md        # ${...} 変数展開(横断)
│   └── run-recorder.md             # .mosaic-orch/runs/* への記録(横断)
│
├── facets/                         # Facet資産
│   ├── personas/*.md
│   ├── policies/*.md
│   ├── knowledge/*.md
│   ├── instructions/*.md
│   └── rubrics/*.md                # ★ 新Facet
│
├── contracts/                      # Output Contract定義
│   └── *.md
│
├── workflows/                      # 組込みワークフロー
│   └── *.yaml
│
├── examples/                       # 学習用サンプル
│   └── radio-script-walkthrough.md
│
└── references/                     # 実装者向けの詳細リファレンス
    ├── prompt-construction.md      # プロンプト構築の詳細
    ├── error-handling.md           # エラーパターンと対応
    └── migration-from-takt.md      # TAKTピース→Mosaic-Orch workflowへの移行ガイド
```

### 5.2 各ファイルの責務と行数目安

| ファイル | 責務(1行で) | 目安行数 | 他ファイルとの関係 |
|---|---|---|---|
| `SKILL.md` | 引数解析 → workflow特定 → orchestrator.mdへ委譲 | ~80 | orchestrator.mdのみ参照 |
| `engine/orchestrator.md` | 状態機械の実装手順(INIT→...→COMPLETE) | ~150 | stage-runner, variable-resolver, run-recorder |
| `engine/stage-runner.md` | 3 kindごとのStage実行手順 | ~180 | composer, dispatcher, contracts, facet-loader |
| `engine/composer.md` | Facet → system/user プロンプトの決定論的合成 | ~80 | facet-loader のみ |
| `engine/dispatcher.md` | Task tool単発/並列呼び出しラッパー | ~60 | (外部Task tool) |
| `engine/facet-loader.md` | facet名 → Markdownファイル本文 の解決 | ~50 | (ファイルシステム) |
| `engine/contracts.md` | contract定義ファイル解釈と検証 | ~120 | variable-resolver |
| `engine/yaml-schema.md` | YAMLスキーマ定義(仕様書+検証ルール) | ~200 | 参照専用 |
| `engine/variable-resolver.md` | `${...}` 文字列展開、型安全 | ~80 | 参照専用 |
| `engine/run-recorder.md` | `.mosaic-orch/runs/*`への記録手順 | ~80 | (ファイルシステム) |

**合計エンジン部分: ~1000行** を9ファイルに分散。1ファイルあたり平均110行。intendantの580行1ファイルと比べて、各ファイルが**短く、1つの関心に集中**している。

### 5.3 SKILL.mdの擬似構造

```markdown
---
name: mosaic-orch
description: Facetベースのドメイン非依存オーケストレーション。...
user-invocable: true
---

# Mosaic-Orch Skill

## 引数の解析
$ARGUMENTS を以下のように解析する:
  /mosaic-orch {workflow} [inputs...]

## 手順
1. 引数から workflow 名を取得
2. workflow 検索: workflows/{name}.yaml または ~/.mosaic-orch/workflows/{name}.yaml または絶対パス
3. engine/orchestrator.md を Read
4. orchestrator.md の手順に従って実行開始
   - YAML path, inputs, permission mode を渡す
5. orchestrator.md が COMPLETE を返したら、結果をユーザーに報告
6. ABORT の場合は失敗理由を報告
```

ここにはStage概念もFacet概念もない。「workflow名 → orchestrator.mdに委譲」以外の責務を持たない。

### 5.4 依存の方向(SoCの検証)

ファイル間の参照(Read tool)が**一方向であること**を設計制約とする:

```
SKILL.md
  └─→ engine/orchestrator.md
        ├─→ engine/yaml-schema.md       (仕様参照)
        ├─→ engine/variable-resolver.md (変数展開)
        ├─→ engine/run-recorder.md      (ログ記録)
        └─→ engine/stage-runner.md
              ├─→ engine/composer.md
              │     └─→ engine/facet-loader.md
              │           └─→ facets/**/*.md    (データ読み込み)
              ├─→ engine/dispatcher.md
              └─→ engine/contracts.md
                    └─→ contracts/**/*.md       (データ読み込み)
```

**禁止される逆方向参照**(コードレビュー時のチェック項目):
- composer.md が stage-runner.md を読む
- dispatcher.md が facet を知る
- facet-loader.md が contract を知る
- どのエンジンファイルも workflows/*.yaml の具体名を知らない

これが崩れると「SoCが崩れた」シグナルとなり、次のリファクタの起点になる。

### 5.5 資産ファイル(facets/contracts/workflows)の独立性

エンジン層は**資産ファイルの具体内容を一切知らない**。
- `personas/analyst.md` の中身を書き換えても、エンジンのコードは1行も変わらない
- 新しい rubric を `rubrics/newaxis.md` として追加するだけで、workflows/*.yaml から参照できる
- 新しい workflow を追加しても、既存workflowに影響しない

**Open/Closed原則**の具現化: 拡張には開かれ、変更には閉じている。

### 5.6 SKILL descriptionの設計

```yaml
description: >
  Facetベース(persona/policy/knowledge/instruction/rubric)のドメイン非依存オーケストレーター。
  Stage/Fan-out/Fan-in/Loopをサポートする宣言的Workflow YAMLで、複数サブエージェントを合成する。
  Use when: 多段レビューループ、並列分解タスク、faceted-prompting流の構造化プロンプト実行。
  Not for: 単発の軽い質問、開発タスク(intendant推奨)、直接コーディング。
```

**Use when**と**Not for**を明示し、find-skillsが誤選択するのを防ぐ。

---

## 6. エラー処理・検証・テスト戦略

### 6.1 エラー分類と処理層

| 分類 | 発生層 | 処理 | エスカレーション |
|---|---|---|---|
| **SchemaError** | L2 INIT | YAML不正・必須フィールド欠落 | 即ABORT、ユーザーに報告 |
| **VariableUnresolved** | L2 RESOLVE_STAGE | `${...}`参照先が存在しない | 即ABORT、該当Stage名を報告 |
| **FacetNotFound** | L4 Composer | `facets/persona/foo.md` が無い | 即ABORT、どのStageのどのFacetか報告 |
| **DispatchTimeout** | L5 Dispatcher | Task tool応答なし | 1回リトライ → 失敗で Stage失敗 |
| **ContractViolation** | L3 CHECK_CONTRACT | 出力が契約を満たさない | 2回同Stageリトライ → 失敗でStage失敗 |
| **StageFailure** | L3 | 上記のStage失敗が伝播 | `loop_until`あればループ継続、なければABORT |
| **LoopExhausted** | L3 | `max_iterations`到達 | フラグ`loop_exhausted=true`を付けて次Stage引き渡し |
| **PartialFanout** | L3 fan_out | 並列子の一部失敗 | `on_error: continue`なら成功分のみ、でなければ全失敗 |

**原則**: インフラ系エラー(Timeout/NotFound)はリトライ、契約違反系エラーはロジックの問題だから修正が必要なので無制限リトライしない。

### 6.2 ABORT時のユーザー報告

```
❌ ABORT
Workflow: {name}
Failed stage: {stage_id} (iteration {i} of {max})
Error: {error_type}
Details: {human_readable_detail}

Trace: .mosaic-orch/runs/{timestamp-slug}/
最終成功Stage: {last_ok_stage_id} (成果物あり)
再開提案: /mosaic-orch resume {run_slug} --from {stage_id}
```

`--from`による再開は**将来拡張** — 初版は実行済みrun slugを案内するだけにとどめる。

### 6.3 Dry-runモード

```
/mosaic-orch --dry-run radio-script --topic "4月のニュース"
```

Dry-runは:
- YAMLを全部パース
- Stageを走査し、合成されるプロンプトを`.mosaic-orch/runs/DRYRUN-*/stages/*/prompt.md`に書き出す
- **L5 Dispatcherは呼ばない**(Task toolなし)
- 変数展開で足りないものがあれば`VariableUnresolved`を報告
- 実行計画(Stage順序、fan_outの想定N、ループ条件)をレポート

### 6.4 Static Validation(事前検査)

orchestrator.mdのINIT状態で実施:

| 検査項目 | 失敗時 |
|---|---|
| YAMLがスキーマに従う | SchemaError |
| 全Stage idがunique | SchemaError |
| 変数参照`${X.output}`のXが先行Stageまたはworkflow.inputs | VariableUnresolved |
| 全facet参照先のファイルが実在 | FacetNotFound(事前) |
| 全output_contract参照先のファイルが実在 | SchemaError |
| fan_out のfromが先行Stageの配列出力である | SchemaError |
| fan_in の直前がfan_out(推奨、警告のみ) | WARN |
| loop_until使用時にmax_iterationsが宣言されている | SchemaError |

### 6.5 Skillの「テスト戦略」

#### 6.5.1 Golden Workflow テスト

`examples/` 配下に**組込ワークフローごとに1つ**、次のファイルセットを置く:

```
examples/radio-script-walkthrough/
├── input.md              # 期待される入力
├── expected-plan.md      # 期待される Stage trace(プレーン手書き)
└── verify.md             # 検証シナリオ
```

`verify.md`の流れ:
1. `/mosaic-orch --dry-run radio-script --topic "テスト用お題"`
2. 生成された `.mosaic-orch/runs/DRYRUN-*/stages/*/prompt.md` を `expected-plan.md` と照合
3. 差分があれば設計がずれている

実際にAgentを走らせる本実行テストは重いので、dry-runでプロンプト合成とStageスケジューリングまでを検証する。

#### 6.5.2 Facet Isolation テスト

各Facetが**単独で意味を成すか**を人がレビューする:
- `persona/analyst.md` だけ読んで「どういう人物か」がわかるか
- `rubric/clarity.md` だけ読んで「どう採点するか」がわかるか
- Facetファイル内で他のFacetに依存していないか

#### 6.5.3 Engine Self-consistency テスト

エンジン層のMarkdownファイル同士の依存方向が一方向であること(5.4節)をチェックする単純なスクリプト:

```bash
# 逆方向参照の検出
grep -l "stage-runner" engine/composer.md && echo "VIOLATION: composer references stage-runner"
grep -l "orchestrator" engine/composer.md && echo "VIOLATION: composer references orchestrator"
# ... (禁止方向のペアを全て検査)
```

`examples/validate-soc.sh`に置き、CI的に実行する(初版は手動で十分)。

### 6.6 デバッグ支援

実行トレース(`.mosaic-orch/runs/*/trace.ndjson`)は以下のスキーマ:

```json
{"ts": "...", "event": "stage_start", "stage_id": "plan", "iteration": 1}
{"ts": "...", "event": "prompt_composed", "stage_id": "plan", "chars": 1834}
{"ts": "...", "event": "dispatch", "stage_id": "plan", "permission": "default"}
{"ts": "...", "event": "response", "stage_id": "plan", "chars": 2140}
{"ts": "...", "event": "contract_check", "stage_id": "plan", "result": "ok"}
{"ts": "...", "event": "stage_complete", "stage_id": "plan", "duration_ms": 4200}
```

1行1イベントのNDJSONは`jq`や`grep`で切り刻めるのでデバッグが楽。

### 6.7 初版で意図的に**やらない**こと(YAGNI)

- ❌ Repertoire参照(`@owner/repo/facet`)
- ❌ Workflow自体のfacet化(Approach Cで検討)
- ❌ 任意DAG(直列パイプラインに限定、`when`で簡易分岐)
- ❌ 並列実行の動的スケール(max_parallelは静的値のみ)
- ❌ Stage間の永続メモリ共有(各Stageはstatelessに保つ、入出力は explicit)
- ❌ カスタム関数・算術・条件式の拡張(`${a}` 展開のみ)
- ❌ 外部ファイル読み書き(Task tool経由のサブエージェントが自分でやる)

これらは**必要になったら**追加する。追加の入り口は全て`engine/`の該当ファイル1〜2箇所に閉じる(SoCが守られていれば)。

---

## 7. オープン事項・将来拡張

### 7.1 Skill名の決定

**確定名**: リポジトリ `mosaic-works` / Skill `mosaic-orch`。

### 7.2 将来拡張の候補(優先度順)

1. **Repertoire参照**: `@owner/repo/facet-name` の解決。facet-loader.mdだけ差し替えで対応可能
2. **Workflow再開**: `/mosaic-orch resume {run_slug} --from {stage_id}` で途中から再実行
3. **カスタムパーミッションプリセット**: workflow単位で細かく権限を分ける
4. **Workflow-as-Facet(Approach C)**: workflowをfacet化して再利用可能に
5. **任意DAG**: 直列以上の表現力が必要になったら

---

## 8. 既存Skillから踏襲した要素のまとめ

| Mosaic-Orchの要素 | 元ネタ |
|---|---|
| 多段パイプライン(Stage) | intendantの手順2→4→5→6→9のフェーズ構造 |
| fan_out/fan_in(並列分解→統合) | intendantのWave実行(並列worktree→統合) |
| loop_until + rubric のレビューループ | intendantの「A+必須・再帰的レビュー」、radio-writerの「6名レビューでA+〜S到達まで推敲」 |
| rubric Facetの複数軸評価 | radio-writerの6作家、intendantの5軸評価 |
| 4 Facet(persona/policy/knowledge/instruction) | faceted-prompting / TAKTのセクション構造 |
| 別エージェントで実行=コンテキスト分離 | intendant / TAKTの基本原則 |
| 宣言的YAMLワークフロー | TAKTのピースYAML |
| `.mosaic-orch/runs/`実行ログ | TAKTの`.takt/runs/` |

**Mosaic-Orch固有の新規性は以下3点のみ**:
1. Rubric Facet の第5Facetとしての独立
2. 平坦な3 kindスキーマ(task / fan_out / fan_in)
3. Output Contractの強制検出とSkill内部SoCの徹底(1ファイル1関心)
