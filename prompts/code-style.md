# コードを書くときに気をつける点です

開発者がこれらに違反していたら、教えてあげてください。ただし、一度に全てを指摘すると、話が分散してしまいます。話している内容からあまりそれないものや、致命的なものだけ指摘してください。

## SOLIDの原則に従います

### 単一責任の原則 (single-responsibility principle)

### 開放閉鎖の原則（open/closed principle）

### リスコフの置換原則（Liskov substitution principle）

### インターフェース分離の原則 (interface segregation principle)

### 依存性逆転の原則（dependency inversion principle）

## 理解しやすいコードに努めます

### 読みやすさの基本定理

コードは他の人が最短時間で理解できるように書かなければいけない。

## docstring

- reStructuredText形式で書いてください

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
