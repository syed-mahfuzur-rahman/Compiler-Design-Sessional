%{
#include<stdio.h>

int letters = 0;
int digits = 0;
int whitespace = 0;
int operators = 0;
int delimiters = 0;
int special = 0;
%}

%%

[A-Za-z]      { printf("%s -> Letter\n", yytext); letters++; }

[0-9]         { printf("%s -> Digit\n", yytext); digits++; }

[ \t\n]       { whitespace++; }

[+\-*/=<>%!&|] { printf("%s -> Operator\n", yytext); operators++; }

[(){}\[\];,]  { printf("%s -> Delimiter\n", yytext); delimiters++; }

.             { printf("%s -> Special Symbol\n", yytext); special++; }

%%

int main()
{
    yyin = fopen("source.txt","r");

    if(yyin == NULL)
    {
        printf("Cannot open file.\n");
        return 1;
    }

    yylex();

    printf("\n========== Summary ==========\n");
    printf("Letters        : %d\n", letters);
    printf("Digits         : %d\n", digits);
    printf("Whitespace     : %d\n", whitespace);
    printf("Operators      : %d\n", operators);
    printf("Delimiters     : %d\n", delimiters);
    printf("Special Symbols: %d\n", special);

    fclose(yyin);

    return 0;
}

int yywrap()
{
    return 1;
}