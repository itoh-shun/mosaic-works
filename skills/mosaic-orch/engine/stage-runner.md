# Stage Runner — mosaic-orch (L3)

1 Stage の実行を担当する。Orchestrator(L2) から呼ばれる。

## あなたの責務

Stage 定義を受け取り、(1) Facet 合成 → (2) 入力注入 → (3) サブエージェント起動 → (4) 契約検証
のパイプラインを実行して結果を返す。
**Workflow 全体は知らない。** 次の Stage も前の Stage も関知しない。

## 事前読み込み

以下を **Read tool で読み込む**:
1. `engine/composer.md` — Facet 合成
2. `engine/dispatcher.md` — サブエージェント起動
3. `engine/contracts.md` — Output Contract 検証
4. `engine/facet-loader.md` — Facet 解決（composer.md が使う）

## 入力

- `stage`: Stage 定義オブジェクト（YAML の 1 stage 分）
- `input`: 変数展開済みの入力テキスト（Orchestrator が展開済み）
- `permission`: 権限モード
- `timeout`: タイムアウト秒
- `dryRun`: boolean
- `runDir`: ランディレクトリパス（run-recorder 用）
- `workflowName`: ワークフロー名（実行コンテキスト注入用）
- `stageIndex`: 現在の stage インデックス（0始まり）
- `totalStages`: stages 配列の全長

## Kind 別の実行フロー

### 共通前処理: Facet 変数展開

全 kind 共通で、Composer にfacetsを渡す前に variable-resolver で `${...}` を展開する。

```
0. stage.facets 内の全文字列値を variable-resolver で展開する:
   - persona: ${subtask.persona} → "backend-lead"
   - instructions: [${subtask.instruction}] → ["implement-backend"]
   - policies, knowledge, rubrics も同様
   展開後の facets を以降の Step 1 で Composer に渡す。
   VariableUnresolved → StageFailure（facet名の展開失敗）
```

### kind: task

```
1. Composer に stage.facets を渡してプロンプトを合成する
   → { systemPrompt, userMessage, policyReminder, sourceFiles }

1.2. userMessage の末尾に実行コンテキストを追記する:
   ---
   ## 実行コンテキスト
   - ワーキングディレクトリ: {cwd}
   - ワークフロー: {workflowName}
   - ステージ: {stage.id} ({stage.kind})
   - ステージ番号: {stageIndex + 1} / {totalStages}
   ※ cwd は Orchestrator 起動時点の process.cwd()。workflowName は YAML の name フィールド。

1.5. **スキル注入（スキップ厳禁）**: stage.skills がある場合、userMessage の末尾に以下を**必ず**追記する。
   このステップを省略してはならない。スキルが選定されているのに注入しないと、サブエージェントはスキルの存在を知らずに作業し、品質が低下する。

   ---
   ## スキル活用（必須 — 作業中に該当スキルを Skill tool で起動すること）

   以下のスキルが利用可能です。**必ず**作業中に該当する場面で Skill tool を使って起動してください。
   スキルを起動せずに作業を完了した場合、品質不足として差し戻される可能性があります。

   {skills リストから各スキル名を箇条書きで列挙}

   スキルの内容は事前に読み込まず、必要になった時点で Skill tool で起動してください。
   **出力の skills_used フィールドに、実際に使用したスキル名を記録してください。**

1.7. **MCPツール注入**: stage.mcps がある場合、userMessage の末尾に以下を追記する。
   MCPツールはユーザー環境依存のため、利用可能なもののみ注入される。

   ---
   ## 利用可能な MCP ツール

   以下の MCP ツールが利用可能です。ライブラリのAPIや仕様を確認する際に活用してください:
   {mcps リストから各エントリを箇条書きで列挙。形式: "- {名前}: {説明}（ツール名: {tool_prefix}）"}

   使い方: 該当する MCP の tool を直接呼び出してください。

2. userMessage の末尾に入力を追記する:
   ---
   ## Input
   {input}

2.5. policyReminder が空でない場合、userMessage の末尾に追記する:
   {policyReminder}
   ※ Lost in the Middle 対策: skills / input よりも後ろ（プロンプト最末尾）に配置する

3. run-recorder.recordStage(runDir, stage.id, { prompt: userMessage })

4. Dispatcher に単発実行を依頼する:
   → agentOutput (文字列)

5. run-recorder.recordStage(runDir, stage.id, { response: agentOutput })

6. output_contract がある場合:
   a. contracts.md の手順で検証する
   b. 成功 → extracted を返す
   c. ContractViolation →
      - リトライカウント < 2 なら同じプロンプトで再度 Step 4 から
      - リトライカウント >= 2 なら StageFailure エラー

7. output_contract がない場合:
   agentOutput をそのまま返す
```

### kind: fan_out

```
1. stage.from を input から取得する（配列であること）
   配列でなければ SchemaError

2. 配列の各要素 element に対して:
   a. fan_out の as 変数に element をバインド
   b. Composer に stage.facets を渡してプロンプトを合成する
      → { systemPrompt, userMessage, policyReminder, sourceFiles }
   b1. userMessage の末尾に実行コンテキストを追記する:
      ---
      ## 実行コンテキスト
      - ワーキングディレクトリ: {cwd}
      - ワークフロー: {workflowName}
      - ステージ: {stage.id} ({stage.kind}) — 要素 {index+1}/{配列長}
      - ステージ番号: {stageIndex + 1} / {totalStages}
   b2. **スキル注入（スキップ厳禁）**: stage.skills がある場合、userMessage の末尾に以下を**必ず**追記する:

      ---
      ## スキル活用（必須 — 作業中に該当スキルを Skill tool で起動すること）

      以下のスキルが利用可能です。**必ず**作業中に該当する場面で Skill tool を使って起動してください。
      スキルを起動せずに作業を完了した場合、品質不足として差し戻される可能性があります。

      {skills リストから各スキル名を箇条書きで列挙}

      スキルの内容は事前に読み込まず、必要になった時点で Skill tool で起動してください。
      **出力の skills_used フィールドに、実際に使用したスキル名を記録してください。**

   c. userMessage の末尾に入力を追記する:
      ---
      ## Input
      {element の内容}
   c2. policyReminder が空でない場合、userMessage の末尾に追記する:
      {policyReminder}
   d. run-recorder.recordStage(runDir, "{stage.id}-{index}", { prompt: userMessage })

3. 全プロンプトを Dispatcher に並列実行で渡す:
   → outputs[] (文字列の配列)

4. 各 output に対して:
   a. run-recorder.recordStage(runDir, "{stage.id}-{index}", { response: output })
   b. output_contract がある場合は検証する

5. エラー処理:
   - on_error == "fail" (デフォルト): 1つでも失敗 → StageFailure
   - on_error == "continue": 成功分のみ配列に含めて返す

6. 全結果を配列として返す → ${stage.id}.outputs で参照可能

7. stage.aggregate がある場合:
   各 aggregate ルールを評価する:
   a. ルールのプレフィックス (all:/any:/none:) を判定
   b. 条件式の ${item.X} を各結果要素に適用
   c. all: → 全要素が true なら "true"
      any: → 1要素でも true なら "true"
      none: → 全要素が false なら "true"
   d. 結果を output に追加: context[stage.id].output.{key} = "true" | "false"
```

### kind: fan_in

```
1. stage.from を input から取得する（配列であること）

2. 配列を整形して統合対象テキストを**準備する**（まだ追記しない）:

   ```
   ## 統合対象

   ### Item 1
   {outputs[0] の内容}

   ### Item 2
   {outputs[1] の内容}
   ```

   ...

3. Composer に stage.facets を渡してプロンプトを合成する
   → { systemPrompt, userMessage, policyReminder, sourceFiles }

4. userMessage の末尾に実行コンテキストを追記する:
   ---
   ## 実行コンテキスト
   - ワーキングディレクトリ: {cwd}
   - ワークフロー: {workflowName}
   - ステージ: {stage.id} ({stage.kind})
   - ステージ番号: {stageIndex + 1} / {totalStages}

5. userMessage の末尾に整形済み統合対象を追記する

5.5. **スキル注入（スキップ厳禁）**: stage.skills がある場合、userMessage の末尾に以下を**必ず**追記する:

   ---
   ## スキル活用（必須 — 作業中に該当スキルを Skill tool で起動すること）

   以下のスキルが利用可能です。**必ず**作業中に該当する場面で Skill tool を使って起動してください。
   スキルを起動せずに作業を完了した場合、品質不足として差し戻される可能性があります。

   {skills リストから各スキル名を箇条書きで列挙}

   スキルの内容は事前に読み込まず、必要になった時点で Skill tool で起動してください。
   **出力の skills_used フィールドに、実際に使用したスキル名を記録してください。**

6. policyReminder が空でない場合、userMessage の末尾に追記する:
   {policyReminder}

7. run-recorder.recordStage(runDir, stage.id, { prompt: userMessage })

8. Dispatcher に単発実行を依頼する → agentOutput

9. run-recorder.recordStage(runDir, stage.id, { response: agentOutput })

10. output_contract がある場合:
    a. contracts.md の手順で検証する
    b. 成功 → extracted を返す
    c. ContractViolation →
       - リトライカウント < 2 なら同じプロンプトで再度 Step 8 から
       - リトライカウント >= 2 なら StageFailure エラー

11. output_contract がない場合: agentOutput をそのまま返す
```

## loop_until 処理

**task kind のみ対応。** fan_out / fan_in で loop_until があれば SchemaError。

```
iteration = 1
loop:
  1. 上記 kind: task の Step 1〜7 を実行する
  2. output_contract の extracted から self 変数にバインドする
     例: extracted = { grade: "B" } → self.grade = "B"
  3. stage.loop_until の条件を評価する:
     a. 変数展開（self.X を実値に置換）
     b. 比較演算を実行:
        - 文字列比較: `<`, `>`, `>=`, `<=`, `==`, `!=`
        - 順序: S > A+ > A > B > C（成績型の場合）
     c. true → ループ終了、最新の output を返す
     d. false → iteration += 1

  4. iteration > max_iterations の場合:
     最新の output を返すが、フラグ loop_exhausted=true を付与する

end loop
```

## 比較演算の詳細

`when` / `loop_until` の条件式は以下の形式のみ対応:

```
${variable} operator 'value'
```

operator: `<`, `>`, `>=`, `<=`, `==`, `!=`

文字列の大小比較は以下の成績順序を使う:
`S > A+ > A > B > C`

例: `${review.output.grade} < 'A'` は grade が B または C のとき true。
