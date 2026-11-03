#!/bin/sh
set -eu

flex -o lex.yy.c expression_validator.l
gcc -std=c11 -Wall -Wextra -Wpedantic -Wno-sign-compare lex.yy.c -o expression_validator

printf "Build successful. Run ./expression_validator to check sample_expressions.txt\n"
