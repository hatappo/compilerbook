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

NEXT NOTE: here: https://www.sigbus.info/compilerbook#%E3%82%B9%E3%82%BF%E3%83%83%E3%82%AF%E3%83%9E%E3%82%B7%E3%83%B3









## 5. 分割コンパイルとリンク


### ステップ5：四則演算のできる言語の作成


### ステップ6：単項プラスと単項マイナス


### ステップ7: 比較演算子






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


## Cコンパイラ作成集中講座 (2020) 第4回


## Cコンパイラ作成集中講座 (2020) 第5回


## Cコンパイラ作成集中講座 (2020) 第6回


## Cコンパイラ作成集中講座 (2020) 第7回


## Cコンパイラ作成集中講座 (2020) 第8回


## Cコンパイラ作成集中講座 (2020) 第9回


## Cコンパイラ作成集中講座 (2020) 第10回


## Cコンパイラ作成集中講座 (2020) 第11回


## Cコンパイラ作成集中講座 (2020) 第12回


## Cコンパイラ作成集中講座 (2020) 第13回


## Cコンパイラ作成集中講座 (2020) 第14回

