# 『低レイヤを知りたい人のためのCコンパイラ作成入門』 をやってみる

- https://www.sigbus.info/compilerbook#%E3%81%AF%E3%81%98%E3%82%81%E3%81%AB 2020-03-16
- https://github.com/rui314/9cc
  - the successor: https://github.com/rui314/chibicc


現在、実装ステップは 28 まで書かれており、 29 以降は書かれていない。




# 全体的なノート

Mac および AppleSilicon （M1以降のMAC） での環境構築については [AppleSilicon](#AppleSilicon) の節を参照

## よく使うサンプルコマンド

```sh
# コンテナのシェルに入る。
docker run --rm -it -v $HOME/ws/books/compilerbook/9cc:/9cc -w /9cc --platform linux/amd64 --name compilerbook compilerbook

# コンテナ上でコマンドを実行する（この場合はテストの実行）
docker run --rm     -v $HOME/ws/books/compilerbook/9cc:/9cc -w /9cc --platform linux/amd64 --name compilerbook compilerbook make test
```

----------------------------------------

# 各章のノート

注意： 以降の内容は、ここに書かれている文章単体で完結していません。『低レイヤを知りたい人のためのCコンパイラ作成入門』を読んだうえで、あるいは一緒に読み進めないとコンテキストが明確でないものが多いです。

## 1. はじめに

> 本書ではIntelやAMDなどのいわゆる普通のPCで動く64ビットのLinux環境を想定しています。読者がお使いのディストリビューションに合わせてgccやmakeといった開発ツールをあらかじめインストールしておいてください。

OS はいいとして Apple Silicon の Mac だと CPU アーキテクチャ的にひょっとして無理？

## 2. 機械語とアセンブラ

### CPUとメモリ

- `アドレス`: CPUがメモリにアクセスするときに使用する、メモリの何バイト目にアクセスしたいのかという情報の数値表現
- `プログラムカウンタ`（PC） / `インストラクションポインタ`（IP）: 現在実行中の命令のアドレス
- `機械語`(machine code): CPUが実行するプログラムの形式そのもののこと
- CPUの「分岐命令」（branch instruction）
- `レジスタ`（register）: CPU が持つプログラムカウンタ以外の少数のデータ保存領域。IntelやAMDのプロセッサなら64ビット整数が保持できる領域が16個（8byte x 16 = 128byte）ある。
- `命令セットアーキテクチャ`（instruction set architecture, ISA）/ `命令セット` : 特定の機械語の命令の総称
  - 例：
    - `x86-64` または `x64`, `AMD64`, `Intel 64` とも。
    - `ARM`

### 3. アセンブラとは

アセンブリは機械語にほぼそのまま1対1で対応するような言語なのですが、機械語よりもはるかに人間にとって読みやすい

> 仮想マシンやインタープリタではなくネイティブなバイナリを出力するコンパイラの場合、通常、アセンブリを出力することが目標になります。機械語を直接出力しているように見えるコンパイラも、よくある構成では、アセンブリを出力したあとにバックグラウンドでアセンブラを起動しています。本書で作るCコンパイラもアセンブリを出力します。

↑そうだったのか、知らなかった。。


```sh
$ objdump -d -M intel /bin/ls | head
/bin/ls (architecture x86_64):
(__TEXT,__text) section
100003974:	55	push	rbp
100003975:	48 89 e5	mov	rbp, rsp
100003978:	48 83 c7 68	add	rdi, 104
10000397c:	48 83 c6 68	add	rsi, 104
100003980:	5d	pop	rbp
100003981:	e9 de 3b 00 00	jmp	0x100007564 ## symbol stub for: _strcoll
100003986:	55	push	rbp
100003987:	48 89 e5	mov	rbp, rsp
error: write on a pipe with no reader

$ objdump -d -M arm /bin/ls | wc -l
llvm-objdump: warning: invalid instruction encoding
    7552
```

### Cとそれに対応するアセンブラ


```sh
$ cc -o test1 test1.c

$ objdump -d test1

test1:	file format mach-o arm64

Disassembly of section __TEXT,__text:

0000000100003f94 <_main>:
100003f94: d10043ff    	sub	sp, sp, #16
100003f98: b9000fff    	str	wzr, [sp, #12]
100003f9c: 52800540    	mov	w0, #42
100003fa0: 910043ff    	add	sp, sp, #16
100003fa4: d65f03c0    	ret
```

### 関数呼び出しを含む例

- `リターンアドレス`: 関数呼び出しにおいて、関数終了時に戻るべき元々実行していた場所のアドレス
- `スタックポインタ`: スタックトップを保持している記憶領域
- Cの関数はアセンブリでも関数
- 関数呼び出しはスタックを使って実装されている

## 4. 電卓レベルの言語の作成

- `再帰下降構文解析法`（recursive descent parsing）: 構文解析の最も一般的なアルゴリズムの一つ

### ステップ1：整数1個をコンパイルする言語の作成


### ステップ2：加減算のできるコンパイラの作成

if や while の開きカッコ（`{`）が改行されるのを抑制したかったので次の設定値を `Google` にした。カッコの設定単体だけを変える方法は分からなかった。

```json
  // 次のコーディング スタイルが現在サポートされています: `Visual Studio`、`LLVM`、`Google`、`Chromium`、`Mozilla`、`WebKit`、`Microsoft`、`GNU`。`file` を使用して、現在のディレクトリまたは親ディレクトリにある `.clang-format` ファイルからスタイルを読み込むか、`file:<パス>/.clang-format` を使用して特定のパスを参照します。特定のパラメーターを設定するには、`{キー: 値, ...}` を使用します。たとえば、`Visual Studio` のスタイルは次のようになります: `{ BasedOnStyle: LLVM, UseTab: Never, IndentWidth: 4, TabWidth: 4, BreakBeforeBraces: Allman, AllowShortIfStatementsOnASingleLine: false, IndentCaseLabels: false, ColumnLimit: 0, AccessModifierOffset: -4, NamespaceIndentation: All, FixNamespaceComments: false }`。
  "C_Cpp.clang_format_style": "file",
```

参考： [Visual Studio Codeでの行頭カッコを何とかしたい #C++ - Qiita](https://qiita.com/Hiragi-GKUTH/items/998c0276e4e62e5c1def)


### ステップ3：トークナイザを導入

#### フォーマッタ

`"C_Cpp.clang_format_style": "Google"` だとサンプルコードと微妙に異なるスタイルがあるが、他の選択肢でもうまくいかない。個別の設定箇所もいまいちよく分からないので気にしないことに。ただ、Diff でサンプルコードと比較するときにはノイズになる。異なるスタイル例：

- ポインタの `*` 記号の位置： `Token *next` `Token* next`

#### C言語の可変長引数

```c
void error(char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  fprintf(stderr, "\n");
  exit(1);
}
```

`fprintf` は file に出力する printf 。
先頭の f は file の f だろう。
この場合はファイルディスクリプタとして標準エラー出力を渡しているということなのだろう。
`fprintf` は引数の個数をコンパイル時に固定する。
呼び出しごとに引数の数が可変となる場合は次の `fprintf` を使う。

`vfprintf` は第３引数 arg_ptr （上記サンプルコードでは ap）の可変長引数が呼び出しごとに異なる可能性がある場合に使える `fprintf` 。
先頭の v は variable arguments の v だろう。
arg_ptr 引数は各呼び出しごとにその前に `va_start` で初期化する必要がある。

`va_start(va_list ap, last)` は内包している関数の自体の可変長引数を取得する。
last には内包している側の任意の引数をわたし、わたすとその引数以降が ap に格納される対象となる。
つまり `va_start(ap, fmt)` においては `error(char* fmt, ...)` の第２引数が last として渡されているので第３引数以降が ap に渡されるというぐあい。

参考
- [vfprintf() - データのフォーマット設定とストリームへの出力 - IBM Documentation](https://www.ibm.com/docs/ja/zos/2.2.0?topic=functions-vfprintf-format-print-data-stream)

### ステップ4：エラーメッセージを改良

#### 捕捉

引数 `argv[1]` を、 main 関数のなかでグローバル変数 `user_input` に格納するように変更したので tokenize 関数はわざわざ引数で入力を受け取る必要がなくなった。
そのため引数が 0 になっている。

#### エラー

`error_at(p, "トークナイズできません");` とすべきところを `error_at(token->str, "トークナイズできません");` としてしまい

```
$ ./9cc "1 + foo + 5" > tmp.s
Segmentation fault
```

となってしまった。

#### コラム

`goto fail bug`

[到達不能コード - Wikipedia](https://ja.wikipedia.org/wiki/%E5%88%B0%E9%81%94%E4%B8%8D%E8%83%BD%E3%82%B3%E3%83%BC%E3%83%89)

[NVD - CVE-2014-1266](https://nvd.nist.gov/vuln/detail/CVE-2014-1266)

### 文法の記述方法と再帰下降構文解析

- `演算子の優先順位` operator precedence: どの演算子が最初に「くっつく」のかというルール

#### 木構造による文法構造の表現

- `構文木` こうぶんぎ、syntax tree: 
- `抽象構文木` abstract syntax tree、AST: グループ化のためのカッコなどの冗長な要素を木の中に残さずになるべくコンパクトに表現した構文木

> 構文解析におけるゴールは抽象構文木を構築すること

言い換えると、構文解析とは「文章という input から抽象構文木という output を作成する」こと

文章 → 抽象構文木 → そしてアセンブリ


#### 生成規則による文法の定義

- `生成規則` production rule: 生成規則は文法を再帰的に定義するルール。プログラミング言語の構文の大部分は生成規則を使って定義されている。

#### BNFによる生成規則の記述

`BNF`（Backus–Naur form）: 生成規則をコンパクトかつわかりやすく記述するための記法の一つ

- `終端記号` terminal symbol : それ以上展開できない記号
- `非終端記号` non-terminal symbol : どれかの生成規則の左辺に来ていて展開できる記号
- `文脈自由文法` context free grammar : このような生成規則で定義される文法一般
- `ε` （イプシロン）: なにもないことを表す記号
- `EBNF`（Extended BNF）: BNFの拡張

#### コラム: BNFとEBNF

EBNF で生成可能な文は BNF でも生成可能。 EBNF は BNF のショートカットの記法（構文糖衣的な？）を提供しているに過ぎない。

「生成可能な文」という意味のつもりで「その文の表現力」という曖昧な言い方をよく使ってしまう。今後は意識して直していきたい。

#### 単純な生成規則

`具象構文木`（concrete syntax tree）: 入力に含まれるすべてのトークンを含んだ、文法に完全に一対一でマッチしている構文木。抽象構文木と対比させたいときによく使われる。

プログラムのコメント文を使いたいときによく 具象構文木 というのを聞く気がする。

> なお、上記の具象構文木では、加減算を左から計算するというルールが木の形では表現されていません。そのようなルールは、ここで説明する文法では、EBNFを使って表現するのではなく、言語仕様書の中に文章で但し書きとして「加減算は左から先に計算します」と書いておくことになります。パーサではEBNFと但し書きの両方を考慮に入れて、式を表すトークン列を読み込んで、式の評価順を適切に表現している抽象構文木を構築することになります。

> 抽象構文木と具象構文木がなるべく同じ構造になるように文法を定義することも可能ですが、そうなると文法が冗長になって、パーサをどう書けばよいのかわかりづらくなってしまいます。

EBNF (BNF) で全てを記述するわけではないのか、なるほど。

#### 生成規則による演算子の優先順位の表現

```ebnf
expr = mul ("+" mul | "-" mul)*
mul  = num ("*" num | "/" num)*
```

なるほど、入れ子にすることで演算子優先順位を（シンプルに）記述できるのか。すごい。

#### 再帰を含む生成規則

#### 再帰下降構文解析

- `再帰下降構文解析`: "上記のような1つの生成規則を1つの関数にマップするという構文解析の手法"
- `LL(1)パーサ`: トークンを1つだけ先読みする再帰下降パーサのこと
- `LL(1)文法`: LL(1)パーサが書ける文法のこと

### スタックマシン

#### スタックマシンの概念

- `CISC（シスク）`
  - 機械語の演算がレジスタだけでなくメモリアドレスを取ることが可能
  - 機械語命令が可変長
  - 複雑な命令を行う命令を備えている。アセンブリプログラマにとって便利
  - `x86-64` は1978年発売の 8086 から発展
- `RISC（リスク）`
  - 演算はレジスタ間のみ。メモリに対する操作はレジスタへのロードとレジスタからのストアのみ。
  - 機械語命令が固定長
  - 複合命令を持たない。コンパイラが生成する簡単な命令のみを備える。
  - 1980年代に発明。 ARM、PowerPC、SPARC、MIPS、RISC-V など。

> Intelは、CPUの命令デコーダでx86命令を内部的にある種のRISC命令に変換して、x86を内部的にRISCプロセッサ化しました。それによりRISCが高速化に成功したのと同じテクニックをx86に適用することが可能になったのです。

- `RSP`レジスタ: スタックポインタとして使うことを想定して設計されたレジスタ

- `cqo` 命令: RAX の64bitの値を128bitに拡張して RDX と RAX に入れる

### ステップ5：四則演算のできる言語の作成

`strchr` 関数: `char *strchr(const char *string, int c);`

> strchr() 関数は、ストリング内の文字の最初の出現を検出します。 文字 c は、ヌル文字 (¥0) にすることができます。 string の終了ヌル文字も検索に含まれます。

##### リファレンス実装と解説の違うところ

1)
tokenize 関数内で受け入れる記号を判定しているところに乗算と除算とカッコを追加しなければならない。

`if (*p == '+' || *p == '-') {`
↓
`if (strchr("+-*/()", *p)) {`

2)
各種ノードを生成する関数を手前でプロトタイプ宣言しておく必要がある。
これらは互いに循環参照しているものがあるので、各関数の定義順を考慮して入れ替えるのでは対応できない。

```c
Node* expr();
Node* mul();
Node* primary();
```

3)
main 関数内の `tokenize` の呼び出しが引数ありになっているが、ステップ４で input をグローバル変数に出して引数なしに変えているので引数なし（`tokenize();`） が正しい。

### ステップ6：単項プラスと単項マイナス

```ebnf
expr    = mul ("+" mul | "-" mul)*
mul     = primary ("*" primary | "/" primary)*
primary = num | "(" expr ")"
```
↓
```ebnf
expr    = mul ("+" mul | "-" mul)*
mul     = unary ("*" unary | "/" unary)*
unary   = ("+" | "-")? primary
primary = num | "(" expr ")"
```

1)
```
    return new_node(ND_SUB, new_node_num(0), primary());
```

の `primary()` は `binary()` の誤り。
じゃないと `assert 10 '- -10'` のテストが通らない。


### ステップ7: 比較演算子

`memcmp` 関数: ２つのメモリ領域を指定文字数分比較する。
https://programming-place.net/ppp/contents/c/appendix/reference/memcmp.html


```ebnf
expr    = mul ("+" mul | "-" mul)*
mul     = unary ("*" unary | "/" unary)*
unary   = ("+" | "-")? primary
primary = num | "(" expr ")"
```
↓
```ebnf
expr       = equality
equality   = relational ("==" relational | "!=" relational)*
relational = add ("<" add | "<=" add | ">" add | ">=" add)*
add        = mul ("+" mul | "-" mul)*
mul        = unary ("*" unary | "/" unary)*
unary      = ("+" | "-")? primary
primary    = num | "(" expr ")"
```

1. expr 式
2. equality 比較演算（同一性）
3. relational 比較演算(大小)
4. add 二項演算（加算と減算）
5. mul 二項演算（乗算と除算）
6. unary 単項演算
7. primary 数値or式

`sete` 命令 （`setne`, `setl`, `setle`）

`movzb` 命令


## 5. 分割コンパイルとリンク

### ステップ8: ファイル分割とMakefileの変更

- リファレンスコミット
  - [Split main.c into multiple small files · rui314/chibicc@725badf](https://github.com/rui314/chibicc/commit/725badfb494544b7c7f1d4c4690b9bc033c6d051)
  - https://github.com/rui314/chibicc/commits/main/?after=90d1f7f199cc55b13c7fdb5839d1409806633fdb+279

ここから chibicc に名前を変えて、GitHub のコードにアラインすることにした。


## 6. 関数とローカル変数



## 7. コンピュータにおける整数の表現



## 8. ポインタと文字列リテラル



## 9. プログラムの実行イメージと初期化式



## 10. ステップ29以降: [要加筆]



## 11. スタティックリンクとダイナミックリンク



## 12. Cの型の構文



## 13. おわりに



## 付録1：x86-64命令セット チートシート

[Link](https://www.sigbus.info/compilerbook#%E4%BB%98%E9%8C%B21x86-64%E5%91%BD%E4%BB%A4%E3%82%BB%E3%83%83%E3%83%88-%E3%83%81%E3%83%BC%E3%83%88%E3%82%B7%E3%83%BC%E3%83%88)



## 付録2：Gitによるバージョン管理

[Link](https://www.sigbus.info/compilerbook#%E4%BB%98%E9%8C%B22git%E3%81%AB%E3%82%88%E3%82%8B%E3%83%90%E3%83%BC%E3%82%B8%E3%83%A7%E3%83%B3%E7%AE%A1%E7%90%86)



## 付録3：Dockerを使った開発環境の作成

[Link](https://www.sigbus.info/compilerbook#docker)

### AppleSilicon

Apple Silicon は ARM ベースであり x64 の CPU 命令セットとは互換性がありません。
Apple Silicon（つまりM1以降）の Mac でこの本を進めていくには、本に記載されている Docker の環境を構築だけでは足りません。以下にその対応を記載します。

[M1 Macでchibiccを動かす - sbite’s blog](https://sbite.hatenablog.com/entry/2021/04/21/222225) を参考に環境構築。

Apple Silicon の Mac 上で X86 のアプリケーションを動かす機能である Rosseta をインストールしてあること。

```sh
$ arch
arm64

$ arch -x86_64 uname -m
x86_64
```

`--platform` に amd64 を指定して docker build する。

```sh
$ docker build -t compilerbook https://www.sigbus.info/compilerbook/Dockerfile --platform linux/amd64
[+] Building 107.1s (9/9) FINISHED                                                                docker:desktop-linux
 => [internal] load remote build context                                                                          0.5s
 => [internal] load metadata for docker.io/library/ubuntu:latest                                                  3.5s
 => [1/6] FROM docker.io/library/ubuntu:latest@sha256:8eab65df33a6de2844c9aefd19efe8ddb87b7df5e9185a4ab73af93622  3.6s
 => => resolve docker.io/library/ubuntu:latest@sha256:8eab65df33a6de2844c9aefd19efe8ddb87b7df5e9185a4ab73af93622  0.0s
 => => sha256:8eab65df33a6de2844c9aefd19efe8ddb87b7df5e9185a4ab73af936225685bb 1.13kB / 1.13kB                    0.0s
 => => sha256:149d67e29f765f4db62aa52161009e99e389544e25a8f43c8c89d4a445a7ca37 424B / 424B                        0.0s
 => => sha256:b6548eacb0639263e9d8abfee48f8ac8b327102a05335b67572f715c580a968e 2.30kB / 2.30kB                    0.0s
 => => sha256:5e8117c0bd28aecad06f7e76d4d3b64734d59c1a0a44541d18060cd8fba30c50 29.55MB / 29.55MB                  2.8s
 => => extracting sha256:5e8117c0bd28aecad06f7e76d4d3b64734d59c1a0a44541d18060cd8fba30c50                         0.7s
 => [2/6] RUN apt update                                                                                          9.7s
 => [3/6] RUN DEBIAN_FRONTEND=noninteractive apt install -y gcc make git binutils libc6-dev gdb sudo             88.3s
 => [4/6] RUN adduser --disabled-password --gecos '' user                                                         0.5s
 => [5/6] RUN echo 'user ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/user                                           0.3s
 => [6/6] WORKDIR /home/user                                                                                      0.0s
 => exporting to image                                                                                            0.8s
 => => exporting layers                                                                                           0.8s
 => => writing image sha256:db70a3bd36cbad08d33e30cdad6b9d76febef7a3f53ea0350a8f632d6404fdcd                      0.0s
 => => naming to docker.io/library/compilerbook                                                                   0.0s

What's Next?
  View a summary of image vulnerabilities and recommendations → docker scout quickview
```

警告が出るけど大丈夫そう。

```sh
$ docker run --rm compilerbook lscpu | head
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
Architecture:                       x86_64
CPU op-mode(s):                     32-bit
Byte Order:                         Little Endian
CPU(s):                             8
On-line CPU(s) list:                0-7
Vendor ID:                          0x00
Model:                              0
Thread(s) per core:                 1
Core(s) per socket:                 8
Socket(s):                          1

$ docker run --rm compilerbook cat /etc/issue
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
Ubuntu 22.04.3 LTS \n \l
```

上記の警告（WARNING）を抑制するには docker run 時にも常に `--platform linux/amd64` を付けてください。

## 参考資料

[Link](https://www.sigbus.info/compilerbook#%E5%8F%82%E8%80%83%E8%B3%87%E6%96%99)


----------------------------------------


# YouTube の Cコンパイラ作成集中講座 (2020) のノート


## [Cコンパイラ作成集中講座 (2020) 第1回](https://www.youtube.com/watch?v=8s_4_rX07Vo)


Cのグローバル変数は関数を使って初期化できない。
なぜかというと、関数より前に固定の値を設定しないといけないから。その仕組みがCになり。C++にはある。

`Conservative GC`
https://www.gnu.org/software/guile/manual/html_node/Conservative-GC.html

`ブートストラップ問題 (Bootstrap problem)`
https://ja.wikipedia.org/wiki/%E3%83%96%E3%83%BC%E3%83%88%E3%82%B9%E3%83%88%E3%83%A9%E3%83%83%E3%83%97%E5%95%8F%E9%A1%8C
別にコンパイラだけの問題ではなくて、例えば最初のネジってネジのない世界で作られた。そしてネジがあるともっと精度のいいネジが作りやすい。


## [Cコンパイラ作成集中講座 (2020) 第2回](https://www.youtube.com/watch?v=vbJ6xz9KkhY)

`gdb`
セグフォで落ちるなら、gdbも落ちる。そこでバックトレースとか見ると関数呼び出し関係とかは分かる。それくらい単純に使うだけでも役には立つ。

`ミスコンパイル` のデバッグ。
アセンブリを見てデバッグするのはきつい。

そこで役に立つのが GCC や CLANG のような他のコンパイラ。それらのコンパイラの出力と自分のコンパイラの出力を比べる。 RAX じゃなくて EAX を使っていた、とか。

セルホストしていくと前の世代のコンパイラにある微妙なバグがその次の世代のコンパイラの出力に影響しちゃったりする。そのとき前の世代のコンパイラの出力を見てデバッグしようとしてはいけない。  
バグを再現できる最小のコードを2分探索で調べる。つまり、自作コンパイラで半分のファイルを、残りをgccでコンパイルしてリンクして動かす。それを繰り返していく。

x86の学習。
Intel の仕様書は500ページはあるが、その中でコンパイラが使う命令はごく一部。

`RISC`
コンパイラ向けの少ない命令セットの CPU アーキテクチャ。

`caller saved register`: 呼び出される側(callee)が自由に使って破壊して良いレジスタ。Caller は必要に応じで自分で値を保存しておく必要がある。

`callee saved register`: Callee が呼び出し前の状態に原状復帰する必要があるレジスタ。

- [x86-64のCalling Convention - 本当は怖いHPC](https://freak-da.hatenablog.com/entry/2021/03/25/172248)
- [assembly - What are callee and caller saved registers? - Stack Overflow](https://stackoverflow.com/questions/9268586/what-are-callee-and-caller-saved-registers)

C言語の仕様の学習。
仕様書は有料で販売されている。ただ、最終ドラフトは PDF で公開されている。本質的な内容は販売版と変わらない。  
ただ、直接読んで使う必要はそんなにない。レジスタやメモリの概念すら汎用的に表現されて抽象的に書かれている。非常に難解。

- [Project status and milestones](https://www.open-std.org/jtc1/sc22/wg14/www/projects)
- https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2310.pdf

`C言語の未定義動作`
網羅的に知っておく必要はないし、仕様書からそれを学習するのは難しい。
ただ、コンパイラを作る上で未定義動作について知っていると最適化の観点で有益なことはある。

`ANSI C` と `pre-ANSI C`
モダンな C とそれ以前の C を区別する意図でよく ANSI C という言い方を使う。ISO C とはあまり呼ばないがそこを区別しているわけではない。

## [Cコンパイラ作成集中講座 (2020) 第3回](https://www.youtube.com/watch?v=Fp0jPklQ3tE)

`ビットフィールド` を chibicc ではサポートしている。  
メモリの大きさを通常の Byte 単位ではなく Bit 単位で指定できる機能。Cでは構造体や共用体のメンバに対して指定できる。

### 最適化  

フロントエンドで最適化はしないほうが良い。
明らかに分かる冗長さに大きな害はない。

中間言語 を定義する

- フロントエンド: Cのコードから中間言語を出力するところ。
- バックエンド: 中間言語からアセンブリを出力するところ。

`mem2reg`: メモリからRegister に昇格する。ループの i 変数とか。

`定数伝播`（値を展開する） と `定数畳み込み`（計算する）  
`フロー分析`が必要。

`不要式除去 (dead code elimination)`

`スピル`: レジスタに置けない場合にメモリに追い出すこと。

LLVM（LLVM中間言語） ってまさにこういった中間言語。

### SRP 命令

Intel の CPU はアンアラインドなアクセスも普通にできる。多くのプロセッサでそうなってきている。ただ SSE 関係の命令など一部の命令はアラインメントが必要なものがある。

## [Cコンパイラ作成集中講座 (2020) 第4回](https://www.youtube.com/watch?v=MicEimqeNb4)

### アセンブラの `Intel Syntax`
で困ること。

- `RAX` などレジスタの名前の変数などが使えない （どちらかというと GNU アセンブラ Intel Syntax サポートの問題）
- Linux のデフォルトではない。デフォルトは `AT&T Syntax`
- 命令のオペランドの順番が `AT&T Syntax` と逆。

`nasm`: network assembler 

`TCC`: Tiny C Compiler https://ja.wikipedia.org/wiki/Tiny_C_Compiler
> ファブリス・ベラールによって作成されたx86、x86-64、ARMアーキテクチャ用のC言語のコンパイラである。名前の通りとても小さく、ディスク容量が小さいコンピューターでも動作するように設計されている。Windowsのサポートについてはバージョン0.9.23から追加されている。

### `Common Symbol` 型

初期化式なしのグローバル変数の定義は、重複して複数存在していてもリンクには失敗しない。Valid。

Fortran歴史的な事情と思われる。

`-fno-common` を付けることで、この動作を無効にして Common Symbol を作らないようにすることもできる。普通にCを書くならこのフラグを有効にしたほうがいい。

### `ELVM`
https://github.com/shinh/elvm [Hamaji-san](https://twitter.com/shinh) 作
ものすごく簡単な中間言語仕様。
命令が12個くらいしかない。
レジスタも6つしかない。

### 意図せずチューリング完全になってしまう問題
例えば、停止性を保証できなくなる。
例えば正規表現は、表現できることもそれなりに柔軟でバランスがいい。

## [Cコンパイラ作成集中講座 (2020) 第5回](https://www.youtube.com/watch?v=crAf_jCtXFI)


## [Cコンパイラ作成集中講座 (2020) 第6回](https://www.youtube.com/watch?v=6G5n0_QAiIw)

### `Tompson hack`
https://ja.wikipedia.org/wiki/%E3%82%B1%E3%83%B3%E3%83%BB%E3%83%88%E3%83%B3%E3%83%97%E3%82%BD%E3%83%B3
> チューリング賞。リッチーと共同受賞。「汎用オペレーティングシステム理論の発展への貢献と、特にUNIXオペレーティングシステムの実装に対して」。この時の受賞記念講演で述べたのが "Reflections on Trusting Trust"、後に Thompson hack と呼ばれるようになる、loginプログラムにバックドアを仕組むようなコンパイラを作るようコンパイラのバイナリを仕組み、その痕跡をコンパイラのソースからは消す、という驚異的な技巧の解説で、しかも実際にいくつかのシステムに仕込まれていたとする衝撃的なものであった。この講演だけで独立したコンピュータセキュリティに対する重要な指摘（仮にコンパイラの全ソースをチェックしても、それだけでは安全ではないかもしれない）とされている。

#### `Quine`: 自身のソースコードと完全に同じ文字列を出力するプログラム

C言語の例： https://ja.wikipedia.org/wiki/%E3%82%AF%E3%83%AF%E3%82%A4%E3%83%B3_(%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0)#C%E8%A8%80%E8%AA%9E

```c
int main() { char *s = "int main() { char *s = %c%s%c; printf(s, 34, s, 34); }"; printf(s, 34, s, 34); }
```

`34`はダブルクォートの文字コード

[Reflections on Trusting Trust](https://users.ece.cmu.edu/~ganger/712.fall02/papers/p761-thompson.pdf)

当時は Quine という言葉はメジャーではなかった？論文には self reproducible program という表現が使われている。

条件付きで悪意のあるコードを吐く処理を自身をコンパイルしているときにも埋め込む。

バイナリはソースコードから生成されるわけではなく、ソースコードとコンパイラから生成される。

####  「コンパイラのバイナリにしか含まれていない情報」というのが存在する
コンパイラの文字列におけるメタキャラクタ（`\n`とか）のエスケープ処理に、文字コードは登場しない。コンパイラをコンパイルするコンパイラ自身に既に埋め込まれている情報を使っている状態。自己言及になっている。

#### 信頼の輪


## [Cコンパイラ作成集中講座 (2020) 第7回](https://www.youtube.com/watch?v=BH4krqtEmx0)

### `VSP`: Virtual Secure Platform

[準同型暗号による バーチャルセキュアプラットフォーム の開発/Development of Virtual Secure Platform - Speaker Deck](https://speakerdeck.com/nindanaoto/development-of-virtual-secure-platform)

プログラム自体を暗号化し、暗号化したまま外部（クラウドとか）で実行し、結果も暗号化した形で受け取る。
秘密計算のプロジェクト。

`準同型暗号`

準同型暗号で演算が可能。 → ということは CPU エミュレータ（＝回路エミュレータ）を準同型暗号で作れるのではないか。

ただ、準同型暗号はものすごく処理が遅い。どうするか？ → CPUの命令セットやコンパイラの側面を含めて最適化。

`KVSP`: Kyoto Virtual Secure Platform: リファレンス実装。


`Intel SGX`  
[Intel SGX入門 - SGX基礎知識編 #IntelSGX - Qiita](https://qiita.com/Cliffford/items/2f155f40a1c3eec288cf)

Intel SGX の Secure Enclave とかとは原理的にまったく異なる。

### LLVM

RISC-V の LLVM バックエンドの実装はすごく良いコード。
開発のはじめのほうはドキュメントが存在する。

## [Cコンパイラ作成集中講座 (2020) 第8回](https://www.youtube.com/watch?v=LnhJuE0rM_Y)





## Cコンパイラ作成集中講座 (2020) 第9回


## Cコンパイラ作成集中講座 (2020) 第10回


## Cコンパイラ作成集中講座 (2020) 第11回


## Cコンパイラ作成集中講座 (2020) 第12回


## Cコンパイラ作成集中講座 (2020) 第13回


## Cコンパイラ作成集中講座 (2020) 第14回

