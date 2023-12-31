#!/bin/bash
assert() {
  expected="$1"
  input="$2"

  ./chibicc "$input" > tmp.s || exit  # compile to assembly
  gcc -static tmp.s -o tmp            # compile to executable binary
  ./tmp                               # execute
  actual="$?"

  if [ "$actual" = "$expected" ]; then
    echo "$input => $actual"
  else
    echo "$input => $expected expected, but got $actual"
    exit 1
  fi
}

# 単一の値
assert 0 0
assert 42 42

# 加算と減算
assert 21 "5+20-4"

# スペースを無視する
assert 41 " 12 + 34 - 5 "

# トークナイズエラー
# assert 0 "1+3++"
# assert 0 "1 + foo + 5"
assert 0 "こんにちは"

# 乗算と除算
assert 105 '21 * 5'
assert 4 '28 / 7'
assert 47 '5+6*7'

# かっこ
assert 15 '5*(9-6)'
assert 4 '(3+5)/2'

# 単項演算子
assert 10 '-10+20'
assert 7 '+10-3'
assert 10 '- -10'
assert 10 '- - +10'

# 比較演算子

# 比較演算子
assert 1 '0<1'
assert 0 '1<1'
assert 0 '2<1'
assert 1 '0<=1'
assert 1 '1<=1'
assert 0 '2<=1'

# 比較演算子
assert 1 '1>0'
assert 0 '1>1'
assert 0 '1>2'
assert 1 '1>=0'
assert 1 '1>=1'
assert 0 '1>=2'


echo OK
