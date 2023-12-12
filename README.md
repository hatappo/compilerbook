# 『低レイヤを知りたい人のためのCコンパイラ作成入門』 2020-03-16

- https://www.sigbus.info/compilerbook#%E3%81%AF%E3%81%98%E3%82%81%E3%81%AB
- https://github.com/rui314/9cc
  - the successor: https://github.com/rui314/chibicc


現在、実装ステップは 28 まで書かれており、 29 以降は書かれていない。


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




## 4. 電卓レベルの言語の作成



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



## [参考資料](https://www.sigbus.info/compilerbook#%E5%8F%82%E8%80%83%E8%B3%87%E6%96%99)


