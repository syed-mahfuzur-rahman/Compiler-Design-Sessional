%{
#include <stdio.h>

FILE *yyin;
%}

LETTER      [A-Za-z_]
DIGIT       [0-9]

IDENTIFIER  {LETTER}({LETTER}|{DIGIT})*
FLOAT       {DIGIT}+"."{DIGIT}+
INTEGER     {DIGIT}+

%%

("int"|"float"|"char"|"double"|"if"|"else"|"for"|"while"|"return"|"void")    { printf("%-15s %s\n","KEYWORD",yytext); }

{FLOAT}        { printf("%-15s %s\n","CONSTANT",yytext); }

{INTEGER}      { printf("%-15s %s\n","CONSTANT",yytext); }

{IDENTIFIER}   { printf("%-15s %s\n","IDENTIFIER",yytext); }

("=="|"<="|">="|"!="|"&&"|"||"|"++"|"--")    { printf("%-15s %s\n","OPERATOR",yytext); }

[+\-*/=<>%]    { printf("%-15s %s\n","OPERATOR",yytext); }

[;,(){}\[\]]   { printf("%-15s %s\n","DELIMITER",yytext); }

[ \t\r\n]+     ;

.              { printf("%-15s %s\n","UNKNOWN",yytext); }

%%

int yywrap(void)
{
    return 1;
}

int main(void)
{
    yyin = fopen("source.txt", "r");

    if (yyin == NULL)
    {
        printf("Cannot open input.txt\n");
        return 1;
    }

    printf("%-15s %s\n", "TOKEN", "LEXEME");
    printf("-------------------------------\n");

    yylex();

    fclose(yyin);
    return 0;
}