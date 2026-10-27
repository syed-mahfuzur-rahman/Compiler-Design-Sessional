%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_SYMBOLS 100
#define MAX_NAME 32

struct SymbolEntry {
    int serial;
    char name[MAX_NAME];
    char dataType[16];
    int occurrences;
};

struct SymbolEntry symbolTable[MAX_SYMBOLS];
int symbolCount = 0;
char currentType[16] = "";
int expectIdentifierForDeclaration = 0;

int findSymbol(const char *name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

void insertOrUpdate(const char *name, const char *type, int countAsOccurrence) {
    int index = findSymbol(name);

    if (index != -1) {
        if (countAsOccurrence) {
            symbolTable[index].occurrences++;
        }
        return;
    }

    if (symbolCount >= MAX_SYMBOLS) {
        fprintf(stderr, "Symbol table is full.\n");
        return;
    }

    symbolTable[symbolCount].serial = symbolCount + 1;
    strncpy(symbolTable[symbolCount].name, name, MAX_NAME - 1);
    symbolTable[symbolCount].name[MAX_NAME - 1] = '\0';
    strncpy(symbolTable[symbolCount].dataType, type, 15);
    symbolTable[symbolCount].dataType[15] = '\0';
    symbolTable[symbolCount].occurrences = countAsOccurrence ? 1 : 0;
    symbolCount++;
}

void printSymbolTable(void) {
    printf("-------------------------------------------------------------\n");
    printf("Sl. No. | Identifier | Data Type | Occurrences\n");
    printf("-------------------------------------------------------------\n");

    for (int i = 0; i < symbolCount; i++) {
        printf("%-8d | %-11s | %-10s | %-10d\n",
               symbolTable[i].serial,
               symbolTable[i].name,
               symbolTable[i].dataType,
               symbolTable[i].occurrences);
    }

    printf("-------------------------------------------------------------\n");
}
%}

%option noyywrap
%x COMMENT

%%

"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>[^*\n]+        ;
<COMMENT>"*"           ;
<COMMENT>\n            ;
"//".*                  ;

"int"|"float"|"char"|"double"|"void" {
    strncpy(currentType, yytext, sizeof(currentType) - 1);
    currentType[sizeof(currentType) - 1] = '\0';
    expectIdentifierForDeclaration = 1;
}

"if"|"else"|"for"|"while"|"do"|"switch"|"case"|"return"|"break"|"continue"|"sizeof"|"typedef"|"struct"|"enum"|"include"|"define" {
    /* Ignore keywords */
}

"," {
    if (currentType[0] != '\0') {
        expectIdentifierForDeclaration = 1;
    }
}

";" {
    expectIdentifierForDeclaration = 0;
    currentType[0] = '\0';
}

[A-Za-z_][A-Za-z0-9_]*\s*\( {
    char name[MAX_NAME];
    int i = 0;
    int j = 0;

    while (yytext[i] != '\0' && yytext[i] != '(') {
        if (!isspace((unsigned char)yytext[i])) {
            name[j++] = yytext[i];
        }
        i++;
    }
    name[j] = '\0';

    insertOrUpdate(name, "-", 1);
    expectIdentifierForDeclaration = 0;
    currentType[0] = '\0';
}

[A-Za-z_][A-Za-z0-9_]* {
    char name[MAX_NAME];
    strncpy(name, yytext, MAX_NAME - 1);
    name[MAX_NAME - 1] = '\0';

    if (expectIdentifierForDeclaration) {
        insertOrUpdate(name, currentType, 0);
        expectIdentifierForDeclaration = 0;
    } else {
        insertOrUpdate(name, "-", 1);
    }
}

[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)? { /* ignore numeric constants */ }

\"([^\\\"]|\\.)*\" { /* ignore strings */ }

[ \t\r\n]+ { /* ignore whitespace */ }

. { /* ignore other tokens */ }

%%

int main(int argc, char **argv) {
    FILE *inputFile = NULL;

    inputFile = fopen("sample_program.c", "r");
    if (inputFile == NULL) {
        perror("Unable to open input file");
        return 1;
    }
    yyin = inputFile;

    yylex();
    printSymbolTable();

    if (inputFile != NULL) {
        fclose(inputFile);
    }

    return 0;
}