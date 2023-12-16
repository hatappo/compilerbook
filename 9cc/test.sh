#!/bin/bash
assert() {
  expected="$1"
  input="$2"

  ./9cc "$input" > tmp.s  # compile to assembly
  cc tmp.s -o tmp         # compile to executable binary
  ./tmp                   # execute
  actual="$?"

  if [ "$actual" = "$expected" ]; then
    echo "$input => $actual"
  else
    echo "$input => $expected expected, but got $actual"
    exit 1
  fi
}

assert 0 0
assert 42 42
assert 21 "5+20-4"
assert 41 " 12 + 34 - 5 "
# assert 0 "256"
# assert 0 "1+3++" # トークナイズエラー
# assert 0 "1 + foo + 5" # トークナイズエラー

echo OK
