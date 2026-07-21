%{
#include <stdio.h>
#include <string.h>

int keywordCount = 0;
int identifierCount = 0;

extern FILE *yyin;

/* List of C keywords */
const char *keywords[] = {
    "auto","break","case","char","const","continue","default","do",
    "double","else","enum","extern","float","for","goto","if","int",
    "long","register","return","short","signed","sizeof","static",
    "struct","switch","typedef","union","unsigned","void","volatile",
    "while"
};

int isKeyword(char *str)
{
    int total = sizeof(keywords) / sizeof(keywords[0]);

    for(int i=0;i<total;i++)
    {
        if(strcmp(str, keywords[i]) == 0)
            return 1;
    }

    return 0;
}
%}

LETTER      [A-Za-z]
DIGIT       [0-9]
ID          ({LETTER}|_)([A-Za-z0-9_])*

%%

{ID} {
    if (isKeyword(yytext)) {
        printf("Keyword     : %s\n", yytext);
        keywordCount++;
    } else {
        printf("Identifier  : %s\n", yytext);
        identifierCount++;
    }
}

[0-9]+(\.[0-9]+)?      ;

\"([^\\\"\n]|\\.)*\"   ;

\'([^\\']|\\.)\'       ;

"//".*                 ;

"/*"([^*]|\*+[^*/])*"*/" ;

[ \t\r\n]+             ;

.                      ;

%%

int yywrap()
{
    return 1;
}

int main()
{
    yyin = fopen("source.txt", "r");

    if(yyin == NULL)
    {
        printf("Error: Cannot open source.txt\n");
        return 1;
    }

    printf("=========================================\n");
    printf(" Keyword and Identifier Detector\n");
    printf("=========================================\n\n");


    yylex();
    fclose(yyin);

    printf("\n=========================================\n");
    printf("Summary\n");
    printf("-----------------------------------------\n");
    printf("Total Keywords    : %d\n", keywordCount);
    printf("Total Identifiers : %d\n", identifierCount);
    printf("=========================================\n");

    return 0;
}