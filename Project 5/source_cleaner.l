%option yylineno noyywrap noinput nounput
%x BLOCK_COMMENT STRING CHARACTER

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int line;
    char message[64];
    char lexeme[64];
} ErrorEntry;

int error_count = 0;
int error_capacity = 0;
ErrorEntry *errors = NULL;

char *cleaned_buffer = NULL;
size_t cleaned_len = 0;
size_t cleaned_cap = 0;

char char_literal_buffer[64];
int char_literal_len = 0;

void grow_buffer(size_t needed) {
    if (needed <= cleaned_cap) {
        return;
    }

    size_t new_cap = cleaned_cap == 0 ? 256 : cleaned_cap;
    while (new_cap < needed) {
        new_cap *= 2;
    }

    cleaned_buffer = realloc(cleaned_buffer, new_cap);
    if (cleaned_buffer == NULL) {
        fprintf(stderr, "Memory allocation failed.\n");
        exit(1);
    }

    cleaned_cap = new_cap;
}

void add_char(char c) {
    grow_buffer(cleaned_len + 2);
    cleaned_buffer[cleaned_len++] = c;
    cleaned_buffer[cleaned_len] = '\0';
}

void add_text(const char *text) {
    size_t length = strlen(text);
    grow_buffer(cleaned_len + length + 1);
    memcpy(cleaned_buffer + cleaned_len, text, length);
    cleaned_len += length;
    cleaned_buffer[cleaned_len] = '\0';
}

void add_space_if_needed(void) {
    if (cleaned_len == 0) {
        return;
    }

    char last = cleaned_buffer[cleaned_len - 1];
    if (last != ' ' && last != '\t' && last != '\n') {
        add_char(' ');
    }
}

void add_newline_if_needed(void) {
    if (cleaned_len == 0 || cleaned_buffer[cleaned_len - 1] != '\n') {
        add_char('\n');
    }
}

void clear_char_buffer(void) {
    char_literal_len = 0;
    char_literal_buffer[0] = '\0';
}

void add_to_char_buffer(char c) {
    if (char_literal_len < 63) {
        char_literal_buffer[char_literal_len++] = c;
        char_literal_buffer[char_literal_len] = '\0';
    }
}

void add_error(const char *message, const char *lexeme) {
    if (error_count == error_capacity) {
        int new_capacity = error_capacity == 0 ? 8 : error_capacity * 2;
        errors = realloc(errors, new_capacity * sizeof(ErrorEntry));
        if (errors == NULL) {
            fprintf(stderr, "Memory allocation failed.\n");
            exit(1);
        }
        error_capacity = new_capacity;
    }

    errors[error_count].line = yylineno;
    strncpy(errors[error_count].message, message, sizeof(errors[error_count].message) - 1);
    errors[error_count].message[sizeof(errors[error_count].message) - 1] = '\0';
    strncpy(errors[error_count].lexeme, lexeme, sizeof(errors[error_count].lexeme) - 1);
    errors[error_count].lexeme[sizeof(errors[error_count].lexeme) - 1] = '\0';
    error_count++;
}
%}

%%
"//".*                      { /* ignore single-line comments */ }
"/*"                        { BEGIN(BLOCK_COMMENT); }
<BLOCK_COMMENT>"*/"         { BEGIN(INITIAL); }
<BLOCK_COMMENT>\n           { add_newline_if_needed(); }
<BLOCK_COMMENT>.            { /* ignore block comment content */ }

\"                          { add_char('"'); BEGIN(STRING); }
<STRING>\\\"              { add_text("\\\""); }
<STRING>\\n               { add_text("\\n"); }
<STRING>\"                 { add_char('"'); BEGIN(INITIAL); }
<STRING>\n                 { add_error("Unterminated string literal", "\""); add_newline_if_needed(); BEGIN(INITIAL); }
<STRING><<EOF>>            { add_error("Unterminated string literal", "\""); BEGIN(INITIAL); }
<STRING>.                  { add_char(yytext[0]); }

'                           { add_char('\''); clear_char_buffer(); BEGIN(CHARACTER); }
<CHARACTER>'               { add_char('\''); clear_char_buffer(); BEGIN(INITIAL); }
<CHARACTER>\n             { add_error("Unterminated character literal", "'"); add_newline_if_needed(); BEGIN(INITIAL); }
<CHARACTER><<EOF>>         { add_error("Unterminated character literal", "'"); BEGIN(INITIAL); }
<CHARACTER>.               { add_char(yytext[0]); add_to_char_buffer(yytext[0]); }

[ \t\r]+                   { add_space_if_needed(); }
\n+                         { add_newline_if_needed(); }

[0-9]+(\.[0-9]+)?          { add_text(yytext); }
[0-9][A-Za-z_][A-Za-z0-9_]* { add_error("Invalid identifier", yytext); add_text(yytext); }
[A-Za-z_][A-Za-z0-9_]*     { add_text(yytext); }
[\[\]{}();:,.+\-*/%=&|^~<>!?] { add_text(yytext); }
"@"                        { add_error("Illegal character", yytext); add_text(yytext); }
.                           { add_error("Illegal character", yytext); add_text(yytext); }

%%

int main(int argc, char **argv) {
    FILE *input = fopen("sample_input.c", "r");

    if (input == NULL) {
        perror("Unable to open sample_input.c");
        return 1;
    }

    yyin = input;
    yylex();
    fclose(input);

    printf("------------------------------------------------\n");
    printf("Cleaned Source Code\n");
    printf("------------------------------------------------\n");
    if (cleaned_buffer != NULL) {
        printf("%s", cleaned_buffer);
    }
    printf("\n------------------------------------------------\n");
    printf("Lexical Errors Detected\n");
    printf("------------------------------------------------\n");

    if (error_count == 0) {
        printf("No lexical errors found.\n");
    } else {
        for (int i = 0; i < error_count; i++) {
            printf("Line %d : %s -> %s\n", errors[i].line, errors[i].message, errors[i].lexeme);
        }
    }
    printf("------------------------------------------------\n");

    free(cleaned_buffer);
    free(errors);
    return 0;
}

