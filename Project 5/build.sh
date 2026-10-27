#!/bin/bash
set -e
flex source_cleaner.l
gcc lex.yy.c -o source_cleaner
printf "Built successfully. Run: ./source_cleaner sample_input.c\n"
