# 『低レイヤを知りたい人のためのCコンパイラ作成入門』 をやってみる

- https://www.sigbus.info/compilerbook#%E3%81%AF%E3%81%98%E3%82%81%E3%81%AB 2020-03-16
- https://github.com/rui314/9cc
  - the successor: https://github.com/rui314/chibicc


現在、実装ステップは 28 まで書かれており、 29 以降は書かれていない。




# 全体的なノート

Docker 環境でのコマンド実行時 `--platform linux/amd64` を付ける。そうしないと Warning が毎回出てしまうので注意。

## サンプルコマンド

```sh
# コンテナのシェルに入る。
docker run --rm -it -v $HOME/ws/books/compilerbook/9cc:/9cc -w /9cc --platform linux/amd64 --name compilerbook compilerbook

# コンテナ上でコマンドを実行する（この場合はテストの実行）
docker run --rm -v $HOME/ws/books/compilerbook/9cc:/9cc -w /9cc --platform linux/amd64 --name compilerbook compilerbook make test
```




# 各章のノート

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


### ステップ2: 加減算のできるコンパイラの作成

if や while の開きカッコ（`{`）が改行されるのを抑制したかったので次の設定値を `Google` にした。カッコの設定単体だけを変える方法は分からなかった。

```json
  // 次のコーディング スタイルが現在サポートされています: `Visual Studio`、`LLVM`、`Google`、`Chromium`、`Mozilla`、`WebKit`、`Microsoft`、`GNU`。`file` を使用して、現在のディレクトリまたは親ディレクトリにある `.clang-format` ファイルからスタイルを読み込むか、`file:<パス>/.clang-format` を使用して特定のパスを参照します。特定のパラメーターを設定するには、`{キー: 値, ...}` を使用します。たとえば、`Visual Studio` のスタイルは次のようになります: `{ BasedOnStyle: LLVM, UseTab: Never, IndentWidth: 4, TabWidth: 4, BreakBeforeBraces: Allman, AllowShortIfStatementsOnASingleLine: false, IndentCaseLabels: false, ColumnLimit: 0, AccessModifierOffset: -4, NamespaceIndentation: All, FixNamespaceComments: false }`。
  "C_Cpp.clang_format_style": "file",
```

参考： [Visual Studio Codeでの行頭カッコを何とかしたい #C++ - Qiita](https://qiita.com/Hiragi-GKUTH/items/998c0276e4e62e5c1def)


## 5. 分割コンパイルとリンク



## 6. 関数とローカル変数



## 7. コンピュータにおける整数の表現



## 8. ポインタと文字列リテラル



## 9. プログラムの実行イメージと初期化式



## 10. ステップ29以降: [要加筆]



## 11. スタティックリンクとダイナミックリンク



## 12. Cの型の構文



## 13. おわりに



## [付録1：x86-64命令セット チートシート](https://www.sigbus.info/compilerbook#%E4%BB%98%E9%8C%B21x86-64%E5%91%BD%E4%BB%A4%E3%82%BB%E3%83%83%E3%83%88-%E3%83%81%E3%83%BC%E3%83%88%E3%82%B7%E3%83%BC%E3%83%88)



## [付録2：Gitによるバージョン管理](https://www.sigbus.info/compilerbook#%E4%BB%98%E9%8C%B22git%E3%81%AB%E3%82%88%E3%82%8B%E3%83%90%E3%83%BC%E3%82%B8%E3%83%A7%E3%83%B3%E7%AE%A1%E7%90%86)



## [付録3：Dockerを使った開発環境の作成](https://www.sigbus.info/compilerbook#docker)

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

警告が出るけど、一応大丈夫そう。

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

## [参考資料](https://www.sigbus.info/compilerbook#%E5%8F%82%E8%80%83%E8%B3%87%E6%96%99)


