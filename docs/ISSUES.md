# Implementation Backlog (Issue Drafts)

このファイルは、現状のコードベース/README/テストを確認して抽出した「未実装・未対応項目」の Issue 草案です。

## Issue 1: component-side `v-model` を実装する
- **Status**: Open
- **Priority**: High
- **根拠**:
  - README の supported directives に `component-side v-model` が記載されている
  - しかし compiler 側で `component v-model is not supported yet` を返している
- **対象ファイル（想定）**:
  - `src/compiler/template/builder_validate.mbt`
  - `src/compiler/codegen/attrs_component.mbt`
  - `src/compiler/snapshot/attrs_test.mbt`
- **受け入れ条件**:
  1. `<MyInput v-model='state.get()' />` がコンパイル可能
  2. `v-model:prop` / `v-model` の component binding ルールを明文化
  3. snapshot test を追加

## Issue 2: `v-model` on `<input type="radio">` を実装する
- **Status**: Open
- **Priority**: Medium
- **根拠**:
  - compiler validate で `v-model on <input type="radio"> is not supported yet`
- **対象ファイル（想定）**:
  - `src/compiler/template/builder_validate.mbt`
  - `src/compiler/codegen/attrs_binding.mbt`
  - `src/compiler/snapshot/attrs_test.mbt`
- **受け入れ条件**:
  1. `checked` と value 同期のコード生成
  2. change イベントで target 更新
  3. snapshot test を追加

## Issue 3: `v-model` on `<input type="file">` 対応方針を決める
- **Status**: Open
- **Priority**: Medium
- **根拠**:
  - compiler validate で `v-model on <input type="file"> is not supported yet`
- **対応案**:
  - 仕様上無効（明示エラー維持）にするか、`files` 同期を設計して実装するかを決定
- **受け入れ条件**:
  1. README と compiler error message の整合
  2. 選択した方針の test を追加

## Issue 4: `v-model` on `<select multiple>` を実装する
- **Status**: Open
- **Priority**: Medium
- **根拠**:
  - compiler validate で `v-model on <select multiple> is not supported yet`
- **対象ファイル（想定）**:
  - `src/compiler/template/builder_validate.mbt`
  - `src/compiler/codegen/attrs_binding.mbt`
  - `src/compiler/snapshot/attrs_test.mbt`
- **受け入れ条件**:
  1. 複数選択値の配列同期
  2. 初期選択状態の反映
  3. snapshot test を追加

## Issue 5: LSP completion と実装実態の差分監査
- **Status**: Open
- **Priority**: Low
- **根拠**:
  - completion で候補提示される directive と compile 対応範囲を定期チェックしたい
- **対象ファイル（想定）**:
  - `src/tooling/lsp_completion.mbt`
  - `src/compiler/template/builder_validate.mbt`
  - `src/tooling/tooling_lsp_test.mbt`
- **受け入れ条件**:
  1. completion 候補ごとのサポート状況表をテストで担保
  2. 非対応機能は detail 表示で明示

---

## First action plan
1. Issue 1（component-side `v-model`）の仕様を確定
2. validate 制約を緩める
3. codegen を追加
4. snapshot test 追加
