%{
#include <stdio.h>
#include <stdlib.h>

int keywordCount = 0;
int identifierCount = 0;

%}


%%
"#include"[ \t]*<[^>]+> ;

if|else|for|return|include|int|float|printf { printf("Keyword: %s\n", yytext); keywordCount++; }

[a-zA-Z_][a-zA-Z0-9_]*  { printf("Identifier: %s\n", yytext); identifierCount++; }

[ \t\r\n]+    ;

.              ;
%%

int main()
{
    yyin = fopen("source.txt", "r");

    if (yyin == NULL)
    {
        printf("Cannot open source.txt\n");
        return 1;
    }

    printf("========== Tokens ==========\n\n");

    yylex();

    fclose(yyin);

    printf("\n========== Summary ==========\n");
    printf("Total Keywords    : %d\n", keywordCount);
    printf("Total Identifiers : %d\n", identifierCount);

    return 0;
}

int yywrap()
{
    return 1;
}