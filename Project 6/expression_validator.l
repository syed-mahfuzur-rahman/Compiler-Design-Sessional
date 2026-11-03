%option noyywrap noinput nounput

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    TOKEN_NUMBER = 256,
    TOKEN_IDENTIFIER,
    TOKEN_INVALID
} TokenType;

typedef struct {
    int type;
} Token;

static Token *tokens = NULL;
static size_t token_count = 0;
static size_t token_capacity = 0;

static char *source_line = NULL;
static size_t source_length = 0;
static size_t source_capacity = 0;

static size_t parser_position = 0;
static const char *parse_error = NULL;

static void allocation_error(void)
{
    fprintf(stderr, "Memory allocation failed.\n");
    exit(EXIT_FAILURE);
}

static void append_source(const char *text, size_t length)
{
    size_t needed = source_length + length + 1;

    if (needed > source_capacity) {
        size_t new_capacity = source_capacity == 0 ? 128 : source_capacity;
        while (new_capacity < needed) {
            new_capacity *= 2;
        }

        char *new_source = realloc(source_line, new_capacity);
        if (new_source == NULL) {
            allocation_error();
        }

        source_line = new_source;
        source_capacity = new_capacity;
    }

    memcpy(source_line + source_length, text, length);
    source_length += length;
    source_line[source_length] = '\0';
}

static void add_token(int type)
{
    if (token_count == token_capacity) {
        size_t new_capacity = token_capacity == 0 ? 16 : token_capacity * 2;
        Token *new_tokens = realloc(tokens, new_capacity * sizeof(*tokens));
        if (new_tokens == NULL) {
            allocation_error();
        }

        tokens = new_tokens;
        token_capacity = new_capacity;
    }

    tokens[token_count].type = type;
    token_count++;
    append_source(yytext, (size_t)yyleng);
}

static int current_token(void)
{
    if (parser_position >= token_count) {
        return 0;
    }
    return tokens[parser_position].type;
}

static int is_operator(int type)
{
    return type == '+' || type == '-' || type == '*' ||
           type == '/' || type == '%' || type == '^';
}

static void set_parse_error(const char *message)
{
    if (parse_error == NULL) {
        parse_error = message;
    }
}

static int parse_expression(void);
static int parse_term(void);
static int parse_unary(void);
static int parse_power(void);
static int parse_primary(void);

static int parse_expression(void)
{
    if (!parse_term()) {
        return 0;
    }

    while (current_token() == '+' || current_token() == '-') {
        parser_position++;
        if (!parse_term()) {
            return 0;
        }
    }

    return 1;
}

static int parse_term(void)
{
    if (!parse_unary()) {
        return 0;
    }

    while (current_token() == '*' || current_token() == '/' ||
           current_token() == '%') {
        parser_position++;
        if (!parse_unary()) {
            return 0;
        }
    }

    return 1;
}

static int parse_unary(void)
{
    if (current_token() == '+' || current_token() == '-') {
        parser_position++;
        if (!parse_unary()) {
            return 0;
        }
        return 1;
    }

    return parse_power();
}

static int parse_power(void)
{
    if (!parse_primary()) {
        return 0;
    }

    if (current_token() == '^') {
        parser_position++;
        if (!parse_unary()) {
            return 0;
        }
    }

    return 1;
}

static int parse_primary(void)
{
    int type = current_token();

    if (type == TOKEN_NUMBER || type == TOKEN_IDENTIFIER) {
        parser_position++;
        return 1;
    }

    if (type == '(') {
        parser_position++;
        if (!parse_expression()) {
            return 0;
        }

        if (current_token() != ')') {
            set_parse_error("Missing closing parenthesis.");
            return 0;
        }

        parser_position++;
        return 1;
    }

    if (type == TOKEN_INVALID) {
        set_parse_error("Invalid character in expression.");
    } else if (type == ')') {
        set_parse_error("Missing operand before ')'.");
    } else if (is_operator(type)) {
        if (type != '+' && type != '-') {
            if (parser_position > 0 &&
                is_operator(tokens[parser_position - 1].type)) {
                set_parse_error("Consecutive operators detected.");
            } else {
                set_parse_error("Operator is missing a left operand.");
            }
        } else {
            set_parse_error("Missing operand.");
        }
    } else if (type == 0) {
        if (token_count > 0 &&
            is_operator(tokens[token_count - 1].type)) {
            set_parse_error("Expression ends with an operator (missing operand).");
        } else {
            set_parse_error("Missing operand.");
        }
    } else {
        set_parse_error("Invalid expression syntax.");
    }

    return 0;
}

static int check_parentheses(void)
{
    size_t *stack;
    size_t stack_size = 0;
    size_t i;

    if (token_count == 0) {
        return 1;
    }

    stack = malloc(token_count * sizeof(*stack));
    if (stack == NULL) {
        allocation_error();
    }

    for (i = 0; i < token_count; i++) {
        if (tokens[i].type == '(') {
            stack[stack_size++] = i;
        } else if (tokens[i].type == ')') {
            if (stack_size == 0) {
                free(stack);
                return 0;
            }
            stack_size--;
        }
    }

    free(stack);
    return stack_size == 0;
}

static void reset_expression(void)
{
    token_count = 0;
    source_length = 0;
    if (source_line != NULL) {
        source_line[0] = '\0';
    }
}

static void validate_expression(void)
{
    int valid;

    if (token_count == 0) {
        reset_expression();
        return;
    }

    printf("Expression: %s\n", source_line);

    if (!check_parentheses()) {
        printf("Status: Invalid Expression\n");
        printf("Error: Unbalanced parentheses.\n\n");
        reset_expression();
        return;
    }

    parser_position = 0;
    parse_error = NULL;
    valid = parse_expression();

    if (valid && parser_position < token_count) {
        if (tokens[parser_position].type == TOKEN_INVALID) {
            set_parse_error("Invalid character in expression.");
        } else if (tokens[parser_position].type == ')' ||
                   tokens[parser_position].type == '(' ||
                   tokens[parser_position].type == TOKEN_NUMBER ||
                   tokens[parser_position].type == TOKEN_IDENTIFIER) {
            set_parse_error("Missing operator between operands.");
        } else {
            set_parse_error("Invalid expression syntax.");
        }
        valid = 0;
    }

    if (valid) {
        printf("Status: Valid Expression\n\n");
    } else {
        printf("Status: Invalid Expression\n");
        printf("Error: %s\n\n",
               parse_error == NULL ? "Invalid expression syntax." : parse_error);
    }

    reset_expression();
}
%}

DIGIT       [0-9]
NUMBER      ({DIGIT}+(\.{DIGIT}*)?|\.[0-9]+)
IDENTIFIER  [A-Za-z_][A-Za-z0-9_]*

%%

[ \t\r\f\v]+        { append_source(yytext, (size_t)yyleng); }
{NUMBER}            { add_token(TOKEN_NUMBER); }
{IDENTIFIER}        { add_token(TOKEN_IDENTIFIER); }
"+"|"-"|"*"|"/"|"%"|"^"|"("|")" {
                        add_token((unsigned char)yytext[0]);
                    }
\n                  { validate_expression(); }
.                   { add_token(TOKEN_INVALID); }
<<EOF>>             {
                        validate_expression();
                        return 0;
                    }

%%

int main(int argc, char **argv)
{
    FILE *input = stdin;
    const char *input_path = "sample_expressions.txt";

    if (argc > 2) {
        fprintf(stderr, "Usage: %s [input-file]\n", argv[0]);
        return EXIT_FAILURE;
    }

    if (argc == 2) {
        input_path = argv[1];
    }

    input = fopen(input_path, "r");
    if (input == NULL) {
        perror(input_path);
        return EXIT_FAILURE;
    }

    printf("------------------------------------------------\n");
    yyin = input;
    yylex();
    printf("------------------------------------------------\n");

    fclose(input);

    free(tokens);
    free(source_line);
    return EXIT_SUCCESS;
}
