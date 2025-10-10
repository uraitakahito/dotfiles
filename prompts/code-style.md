# コードスタイル

## SOLIDの原則に従います

### 単一責任の原則 (single-responsibility principle)

### 開放閉鎖の原則（open/closed principle）

### リスコフの置換原則（Liskov substitution principle）

φ(x)を型Tのオブジェクトxに関して証明可能な性質とする。このとき、φ(y)は型TのサブタイプSのオブジェクトyについて真でなければならない。

- preconditionsを、派生型で強めることはできない。派生型では同じか弱められる。
  - メソッドの先頭に渡された引数を検証するif文があれば、基底クラスとは違う検証をしている可能性がある。
- postconditionsを、派生型で弱めることはできない。派生型では同じか強められる。
  - 部分型のメソッドが早期にリターンすると、メソッドの後の部分が実行されない。その部分で事後条件を保証するコードがないか気をつける必要がある。
- invaritantsは、派生型でも保護されねばならない。派生型でそのまま維持される。
- 部分型が例外を早出してよいのは、上位型が送出する例外に適合する場合だけである。
- 部分型のオーバライドされたメソッドにsuper()などの規定型の呼び出しがなければ、その部分型は振る舞いが同じという関係をコードで定義できていないことになる。

#### 構造的部分型と名目的部分型

他のクラスを継承したりプロトコルに従ったりすものは、全て部分型です。そのため、上位型の契約を守らなければならない。契約がデータ型の構造を定義するだけなら、構造的部分型を使います。上位型の契約が、守らなければならない振る舞いとして特定の条件の元での操作方法などを定義するなら、is-a関係をより良く反映する継承を使います。

しかし、継承を使う前に **Composition over inheritance（継承よりコンポジションを優先せよ）** を検討してください。

### インターフェース分離の原則 (interface segregation principle)

### 依存性逆転の原則（dependency inversion principle）

## デメテルの法則(Law of Demeter)に従います

任意のオブジェクトが自分以外（サブコンポーネント含む）の構造やプロパティに対して持っている仮定を最小限にすべきです。

## 理解しやすいコードに努めます

- コードは他の人が最短時間で理解できるように書かなければいけません。
- コーディングに現れない意図は積極的にコメントに残します。逆にコーディングに現れる仕様はコメントにすることを控えます。
- 変数のスコープと可変性を最小化します。変数をmutableにするのは、必要な場合に限ります。
- Single source of truthを守ります。例えば、同じ値や実装を複数の場所で定義しないようにします。
- Principle of Least Astonishmentを守ります。

## TIDY FIRST APPROACH

- プログラムは人間が理解しやすいように、できる限り意味的に順番に並んでいることが望ましい
- 意味的に関連があるものは、近い場所に書かれていた方が良い
- コードの宣言と初期化は一緒に行うべき
- コードの中で再利用性が高いセンテンスがある場合は、それを独立した処理として抜き出すべき
- あまりにも細かく分散されて可読性が悪くなってはいけない
- 適切なコメントの付与は必要ですが、不要なコメントは削除しましょう

## コード品質基準

- 名前や構造を通じて意図を明確に表現する
- 状態と副作用は最小限に抑える
- 「うまく動くもっとも単純な解決策」を使う

## コメントについて

- コードが自明の場合の冗長なコメントは避けましょう
- コードは、 **なぜ** それを行っているのかを自明にしづらいことがあります。コメントはコードが存在する理由を積極的に記載しましょう

## Design Patterns

- [Composition over inheritance](https://en.wikipedia.org/wiki/Composition_over_inheritance)

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
