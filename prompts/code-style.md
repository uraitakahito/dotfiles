# コードスタイル

開発者がこれらに違反していたら、教えてあげてください。ただし、一度に全てを指摘すると、話が分散してしまいます。話している内容からあまりそれないものや、致命的なものだけ指摘してください。

## SOLIDの原則に従います

### 単一責任の原則 (single-responsibility principle)

### 開放閉鎖の原則（open/closed principle）

### リスコフの置換原則（Liskov substitution principle）

### インターフェース分離の原則 (interface segregation principle)

### 依存性逆転の原則（dependency inversion principle）

## 理解しやすいコードに努めます

- コードは他の人が最短時間で理解できるように書かなければいけない。
- コーディングに現れない意図は積極的にコメントに残しましょう

## TIDY FIRST APPROACH

### コードの変更方針

- すべての変更を次の2つのタイプに明確に分ける:

1. 構造的変更（STRUCTURAL CHANGES）: 振る舞いを変えずにコードを整理する（名前の変更、メソッドの抽出、コードの移動など）
2. 振る舞いの変更（BEHAVIORAL CHANGES）: 実際の機能を追加・修正する変更

- 構造的変更と振る舞いの変更を同じコミットに混在させないこと
- 両方の変更が必要な場合は、必ず先に構造的変更を行うこと
- 構造的変更の前後でテストを実行して、動作が変わっていないことを検証すること

### その他

- プログラムは人間が理解しやすいように、できる限り意味的に順番に並んでいることが望ましい
- 意味的に関連があるものは、近い場所に書かれていた方が良い
- コードの宣言と初期化は一緒に行うべき
- コードの中で再利用性が高いセンテンスがある場合は、それを独立した処理として抜き出すべき
- あまりにも細かく分散されて可読性が悪くなってはいけない
- 適切なコメントの付与は必要ですが、不要なコメントは削除しましょう

# コード品質基準

- 名前や構造を通じて意図を明確に表現する
- 依存関係は明示的にする
- 状態と副作用は最小限に抑える
- 「うまく動くもっとも単純な解決策」を使う

## テストコード

テストコードでも単一責任の原則を適用してください。

入れ子で呼び出しているメソッドのテストを過剰にしないでください。例えば、次のようなコードがあるとします。

```python
def foo(message: str) -> str:
    return f"Foo says: {message}"

def bar(message: str = "Hello!") -> str:
    foo_result = foo(message)
    return f"Bar says: {foo_result}"
```

この時 `bar` の機能確認のためのテストを書くときには `bar` から呼び出している `foo` の機能が正しいかを確認するテストは書かないでください。

- `foo` の機能確認は `foo` のテストで確認してください。
- `bar` が入れ子のメソッドである `foo` を正しい引数で呼び出しているかは `bar` のテストで確認してください。

`bar` で `foo` の機能を確認しようとすると密結合なテストになってしまい、複雑になるからです。

## 参考資料

- [Adapter Pattern - GoF Design Patterns](https://en.wikipedia.org/wiki/Adapter_pattern)
- [Repository Pattern - Martin Fowler](https://martinfowler.com/eaaCatalog/repository.html)
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
