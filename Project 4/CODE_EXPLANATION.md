# Identifier Manager - Complete Code Explanation for Beginners

This document provides a detailed line-by-line explanation of the `identifier_manager.l` Flex lexer program. This program reads a C source file and extracts all identifiers (variable names, function names) while tracking their data types and how many times they appear.

---

## Table of Contents
1. [Header Section](#header-section)
2. [Global Variables](#global-variables)
3. [Helper Functions](#helper-functions)
4. [Flex Rules Section](#flex-rules-section)
5. [Main Function](#main-function)

---

## Header Section

```c
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
```

### What Each Line Does:

- **`%{`** - This marks the beginning of the C code header in a Flex file. Everything between `%{` and `%}` is C code that will be copied into the generated lexer.

- **`#include <stdio.h>`** - This imports the standard input/output library, which provides functions like `printf()` (for printing) and `fopen()` (for opening files).

- **`#include <stdlib.h>`** - This imports the standard library, which contains general utility functions like `malloc()` and `free()`.

- **`#include <string.h>`** - This imports string handling functions like `strcmp()` (compare strings) and `strncpy()` (copy strings).

- **`#include <ctype.h>`** - This imports character classification functions like `isspace()` (check if a character is whitespace).

### Why These Are Needed:
- `stdio.h` → To print the symbol table to the user
- `stdlib.h` → For memory management
- `string.h` → To work with variable names (strings)
- `ctype.h` → To identify character types (like spaces)

---

## Constants Definition

```c
#define MAX_SYMBOLS 100
#define MAX_NAME 32
```

### What These Lines Do:

- **`#define MAX_SYMBOLS 100`** - Creates a constant named `MAX_SYMBOLS` with value 100. This means our symbol table can store a maximum of 100 identifiers.
  - **Why?** It sets a limit to prevent the program from using unlimited memory.

- **`#define MAX_NAME 32`** - Creates a constant named `MAX_NAME` with value 32. This means each identifier name can be at most 32 characters long.
  - **Why?** Most variable names are much shorter than 32 characters, so this is a practical limit.

---

## Structure Definition

```c
struct SymbolEntry {
    int serial;
    char name[MAX_NAME];
    char dataType[16];
    int occurrences;
};
```

### What This Does:

This defines a blueprint for storing information about one identifier.

- **`struct SymbolEntry`** - Creates a new data structure (like a container) to hold information about a symbol.

- **`int serial;`** - A field to store a serial number (1, 2, 3...). This gives each identifier a unique number.
  - **Example:** If "count" is the first identifier added, its serial would be 1.

- **`char name[MAX_NAME];`** - An array to store the name of the identifier (can store up to 32 characters).
  - **Example:** "count", "total", "main"

- **`char dataType[16];`** - An array to store the data type (up to 16 characters).
  - **Example:** "int", "float", "void"
  - **Note:** "-" means the type is unknown or not applicable (for functions).

- **`int occurrences;`** - A counter to track how many times this identifier appears in the code.
  - **Example:** If "count" is used 3 times, this field stores 3.

### How It Works:
Think of this structure like a row in a table:

```
| Serial | Name  | DataType | Occurrences |
| ------ | ----- | -------- | ----------- |
| 1      | count | int      | 3           |
| 2      | total | float    | 2           |
```

---

## Global Variables

```c
struct SymbolEntry symbolTable[MAX_SYMBOLS];
int symbolCount = 0;
char currentType[16] = "";
int expectIdentifierForDeclaration = 0;
```

### What Each Line Does:

- **`struct SymbolEntry symbolTable[MAX_SYMBOLS];`** - Creates an array of 100 `SymbolEntry` structures. This is our symbol table that will hold all identifiers.
  - **Input/Output:**
    - Before: Empty array (no identifiers yet)
    - After: Filled with identifiers as the program scans the C file

- **`int symbolCount = 0;`** - A counter that tracks how many identifiers we've found. It starts at 0.
  - **Purpose:** When we find a new identifier, we increment this. It tells us how many slots of the symbol table are filled.
  - **Example:** After finding "count" and "total", this would be 2.

- **`char currentType[16] = "";`** - A temporary storage for the most recent data type we encountered.
  - **Why?** When we see `int`, we store "int" here. Then when we see an identifier like `count`, we know it's an `int`.
  - **Example Flow:**
    - See `int` → Store "int" in `currentType`
    - See `count` → Add "count" to table with type "int"

- **`int expectIdentifierForDeclaration = 0;`** - A flag (0 = false, 1 = true) that tells us if we should expect an identifier next.
  - **Why?** After seeing a data type like `int`, we expect an identifier. But after a semicolon `;`, we don't expect one.
  - **Example:**
    - See `int` → Set this to 1 (we expect an identifier)
    - See `count` → Process it, set this to 0 (we don't expect another identifier)

---

## Helper Function: `findSymbol()`

```c
int findSymbol(const char *name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}
```

### What This Function Does:

This searches the symbol table to see if an identifier already exists.

- **`int findSymbol(const char *name)`** - Function signature:
  - **`int`** → Returns an integer (the position of the identifier, or -1 if not found)
  - **`const char *name`** → Takes a string as input (the identifier to search for)

- **`for (int i = 0; i < symbolCount; i++)`** - Loop through all identifiers in the table.
  - Starts at position 0, checks each position until we've checked all `symbolCount` identifiers.

- **`if (strcmp(symbolTable[i].name, name) == 0)`** - Compares the current symbol's name with the search name.
  - **`strcmp()`** compares two strings and returns 0 if they're identical.
  - **What it checks:** Does the name at position `i` match the name we're looking for?

- **`return i;`** - If we find a match, return the position (index) where we found it.
  - **Output:** Position like 0, 1, 2, etc.

- **`return -1;`** - If no match is found after checking all identifiers, return -1.
  - **Convention:** -1 means "not found" in programming.

### Example Execution:

**Scenario:** We're looking for "count" and the symbol table has:
- Position 0: "main"
- Position 1: "count"
- Position 2: "total"

**Step-by-step:**
1. `i = 0`: Compare "main" with "count" → Not equal, continue
2. `i = 1`: Compare "count" with "count" → Equal! Return 1
3. The function returns 1

---

## Helper Function: `insertOrUpdate()`

```c
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
```

### What This Function Does:

This is a critical function. It either adds a new identifier to the table OR updates an existing one.

- **`void insertOrUpdate(...)`** - Function that doesn't return a value (void), but takes 3 parameters:
  - **`const char *name`** → The identifier name (e.g., "count")
  - **`const char *type`** → The data type (e.g., "int" or "-")
  - **`int countAsOccurrence`** → A flag: 1 if we should increment occurrence count, 0 if not

### Part 1: Search for Existing Identifier

```c
int index = findSymbol(name);

if (index != -1) {
    if (countAsOccurrence) {
        symbolTable[index].occurrences++;
    }
    return;
}
```

**What it does:**
- **`int index = findSymbol(name);`** - Search the table for this identifier. Store the position in `index`.
  - **Output:** `index` = position (0, 1, 2...) or -1 if not found

- **`if (index != -1)`** - If the identifier was found (index is not -1):

- **`if (countAsOccurrence)`** - If this is a usage (not a declaration):
  - **`symbolTable[index].occurrences++;`** - Increment the occurrence counter by 1
  - **Example:** If "count" has 2 occurrences, now it has 3

- **`return;`** - Exit the function. We're done updating.

**Scenario Example:**
- Declare: `int count;` → Add "count" with type "int", occurrence = 0
- Use: `count = 5;` → Find "count", increment occurrence to 1
- Use: `count++` → Find "count", increment occurrence to 2

### Part 2: Check If Table Is Full

```c
if (symbolCount >= MAX_SYMBOLS) {
    fprintf(stderr, "Symbol table is full.\n");
    return;
}
```

**What it does:**
- **`if (symbolCount >= MAX_SYMBOLS)`** - If we've already stored 100 identifiers:
  - **`fprintf(stderr, ...)`** - Print an error message to the error stream
  - **`return;`** - Exit the function (don't add more)

**Why?** We can only store 100 identifiers, so we prevent overflow.

### Part 3: Add New Identifier

```c
symbolTable[symbolCount].serial = symbolCount + 1;
strncpy(symbolTable[symbolCount].name, name, MAX_NAME - 1);
symbolTable[symbolCount].name[MAX_NAME - 1] = '\0';
strncpy(symbolTable[symbolCount].dataType, type, 15);
symbolTable[symbolCount].dataType[15] = '\0';
symbolTable[symbolCount].occurrences = countAsOccurrence ? 1 : 0;
symbolCount++;
```

**Line-by-line breakdown:**

- **`symbolTable[symbolCount].serial = symbolCount + 1;`** - Assign a serial number.
  - **Example:** If `symbolCount` is 0 (first identifier), serial = 1
  - **Why `+ 1`?** Serial numbers are 1, 2, 3... but arrays are 0-indexed

- **`strncpy(symbolTable[symbolCount].name, name, MAX_NAME - 1);`** - Copy the identifier name.
  - **`strncpy()`** safely copies a string with a maximum length
  - **`MAX_NAME - 1`** means copy at most 31 characters (leaving room for the null terminator)
  - **Example:** Copy "count" into the name field

- **`symbolTable[symbolCount].name[MAX_NAME - 1] = '\0';`** - Add a null terminator.
  - **Why?** Strings in C must end with `\0` to mark the end
  - **Safety:** Ensures the string is properly terminated even if the name is too long

- **`strncpy(symbolTable[symbolCount].dataType, type, 15);`** - Copy the data type.
  - **Example:** Copy "int" into the dataType field

- **`symbolTable[symbolCount].dataType[15] = '\0';`** - Add a null terminator to the data type string.

- **`symbolTable[symbolCount].occurrences = countAsOccurrence ? 1 : 0;`** - Set occurrences.
  - **Ternary operator:** `condition ? value_if_true : value_if_false`
  - **If `countAsOccurrence` is 1** → Set occurrences = 1 (this is a usage)
  - **If `countAsOccurrence` is 0** → Set occurrences = 0 (this is a declaration)

- **`symbolCount++;`** - Increment the counter. We now have one more identifier in the table.

---

## Helper Function: `printSymbolTable()`

```c
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
```

### What This Function Does:

This prints the symbol table in a nice table format.

- **`void printSymbolTable(void)`** - Function with no parameters and no return value

- **`printf("-------------------------------------------------------------\n");`** - Print a line of dashes (for the table border)

- **`printf("Sl. No. | Identifier | Data Type | Occurrences\n");`** - Print the table header

- **`for (int i = 0; i < symbolCount; i++)`** - Loop through each identifier in the table

- **`printf("%-8d | %-11s | %-10s | %-10d\n", ...);`** - Print one row of the table
  - **`%-8d`** → Print an integer left-aligned in an 8-character space
  - **`%-11s`** → Print a string left-aligned in an 11-character space
  - **`%-10s`** → Print a string left-aligned in a 10-character space
  - **`%-10d`** → Print an integer left-aligned in a 10-character space
  - The format codes ensure nice columns

### Output Example:

```
-------------------------------------------------------------
Sl. No. | Identifier | Data Type | Occurrences
-------------------------------------------------------------
1        | main        | -          | 1         
2        | count       | int        | 3         
3        | total       | float      | 2         
-------------------------------------------------------------
```

---

## Flex Rules Section

```c
%}

%option noyywrap
%x COMMENT

%%
```

### What These Mean:

- **`%}`** - End of the C header section

- **`%option noyywrap`** - A Flex option that tells Flex we won't use the `yywrap()` function (which handles multiple input files). This simplifies our program.

- **`%x COMMENT`** - Defines a special state called `COMMENT` for handling multi-line comments.
  - In Flex, different states can have different rules
  - When we see `/*`, we enter the COMMENT state
  - When we see `*/`, we exit the COMMENT state

- **`%%`** - Marks the beginning of the lexer rules section

---

## Comment Handling Rules

```c
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>[^*\n]+        ;
<COMMENT>"*"           ;
<COMMENT>\n            ;
"//".*                  ;
```

### What Each Rule Does:

- **`"/*" { BEGIN(COMMENT); }`** - When we see `/*`:
  - **Action:** Enter the COMMENT state
  - **Why?** We need to skip everything until we find `*/`

- **`<COMMENT>"*/" { BEGIN(INITIAL); }`** - When in COMMENT state, if we see `*/`:
  - **Action:** Return to INITIAL state (normal processing)
  - **Why?** The comment has ended, so process normally again

- **`<COMMENT>[^*\n]+`** - In COMMENT state, when we see characters that are NOT `*` or newline:
  - **Action:** Do nothing (`;` means ignore)
  - **Why?** Skip the comment content

- **`<COMMENT>"*"`** - In COMMENT state, if we see `*` (not followed by `/`):
  - **Action:** Do nothing
  - **Why?** Skip it; it's part of the comment

- **`<COMMENT>\n`** - In COMMENT state, if we see a newline:
  - **Action:** Do nothing
  - **Why?** Skip it but stay in COMMENT state

- **`"//".*`** - When we see `//`:
  - **`.*`** matches any characters until end of line
  - **Action:** Do nothing (ignore the entire line)
  - **Why?** `//` indicates a comment to the end of line

### Example:
```c
/* This is a comment */
int count;  // This is also a comment
```
Both comments are ignored by the lexer.

---

## Data Type Recognition

```c
"int"|"float"|"char"|"double"|"void" {
    strncpy(currentType, yytext, sizeof(currentType) - 1);
    currentType[sizeof(currentType) - 1] = '\0';
    expectIdentifierForDeclaration = 1;
}
```

### What This Rule Does:

When we encounter a data type keyword:

- **`"int"|"float"|"char"|"double"|"void"`** - Match any of these data type keywords
  - **`|`** means OR in regex

- **`strncpy(currentType, yytext, sizeof(currentType) - 1);`** - Copy the matched text into `currentType`
  - **`yytext`** is a special Flex variable that contains the matched text
  - **Example:** If we matched "int", yytext = "int"

- **`currentType[sizeof(currentType) - 1] = '\0';`** - Add null terminator for safety

- **`expectIdentifierForDeclaration = 1;`** - Set flag to 1 (true)
  - **Why?** After seeing a data type, we expect an identifier next
  - **Example Flow:** See "int" → Set flag → Next, we see "count" and know it's an `int`

### Example:
```
Input: int count;
Process:
1. Match "int" → Store "int" in currentType, set flag = 1
2. Match "count" → We know it's an int (because flag = 1)
```

---

## Keyword Ignoring

```c
"if"|"else"|"for"|"while"|"do"|"switch"|"case"|"return"|"break"|"continue"|"sizeof"|"typedef"|"struct"|"enum"|"include"|"define" {
    /* Ignore keywords */
}
```

### What This Rule Does:

- **Matches:** Any of these C keywords
- **Action:** Do nothing (ignore them)
- **Why?** We only want to track identifiers, not keywords

---

## Comma Handling

```c
"," {
    if (currentType[0] != '\0') {
        expectIdentifierForDeclaration = 1;
    }
}
```

### What This Rule Does:

When we see a comma:

- **`if (currentType[0] != '\0')`** - Check if we have a stored data type
  - **`currentType[0]`** is the first character of the type
  - **`!= '\0'`** means "not empty"

- **`expectIdentifierForDeclaration = 1;`** - Set flag to expect another identifier

### Example:
```c
int a, b, c;
```
- See "int" → store it
- See "a" → add to table
- See "," → we still have "int", so expect another identifier
- See "b" → add to table
- See "," → expect another identifier
- See "c" → add to table
- See ";" → done

---

## Semicolon Handling

```c
";" {
    expectIdentifierForDeclaration = 0;
    currentType[0] = '\0';
}
```

### What This Rule Does:

When we see a semicolon (end of statement):

- **`expectIdentifierForDeclaration = 0;`** - Clear the flag (stop expecting identifiers)
- **`currentType[0] = '\0';`** - Clear the stored type

### Why?
The declaration statement is complete. We won't expect another identifier or use the type until we see another data type keyword.

---

## Function Detection

```c
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
```

### What This Rule Does:

Detects function names (identifiers followed by a parenthesis).

- **`[A-Za-z_][A-Za-z0-9_]*\s*\(`** - Pattern that matches:
  - **`[A-Za-z_]`** → Start with a letter or underscore
  - **`[A-Za-z0-9_]*`** → Followed by zero or more letters, digits, or underscores
  - **`\s*`** → Optional whitespace
  - **`\(`** → Followed by an opening parenthesis
  - **Example matches:** `main(`, `count (`, `calculateTotal(`

### Processing the Function Name:

```c
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
```

**What this loop does:**
- Creates a local array `name` to store just the function name (without the parenthesis or whitespace)
- Loops through `yytext` (the matched text)
- Skips whitespace using `!isspace()`
- Copies non-whitespace characters to `name`
- Stops when it encounters `(` or end of string

**Example:**
- Input: `main (`
- yytext = "main ("
- i=0: 'm' → Add to name, j becomes 1
- i=1: 'a' → Add to name, j becomes 2
- i=2: 'i' → Add to name, j becomes 3
- i=3: 'n' → Add to name, j becomes 4
- i=4: ' ' → Skip (it's whitespace)
- i=5: '(' → Stop
- name = "main"

```c
insertOrUpdate(name, "-", 1);
```

- **`"-"`** → Data type is "-" (function, type not tracked)
- **`1`** → Count this as an occurrence (we found a function call)

```c
expectIdentifierForDeclaration = 0;
currentType[0] = '\0';
```

- Clear the expectations for the next tokens

---

## General Identifier Handling

```c
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
```

### What This Rule Does:

Matches any identifier (variable name) that isn't preceded by `(`.

- **`[A-Za-z_][A-Za-z0-9_]*`** - Pattern for valid identifiers:
  - **Example matches:** `count`, `total`, `_temp`, `x`

- **`char name[MAX_NAME];`** - Local array for the identifier name

- **`strncpy(name, yytext, MAX_NAME - 1);`** - Copy the matched text
- **`name[MAX_NAME - 1] = '\0';`** - Ensure null termination

### Decision Logic:

```c
if (expectIdentifierForDeclaration) {
    insertOrUpdate(name, currentType, 0);
    expectIdentifierForDeclaration = 0;
} else {
    insertOrUpdate(name, "-", 1);
}
```

**Two scenarios:**

**Scenario 1: We expect a declaration**
- Happens after seeing `int`, `float`, etc.
- **`insertOrUpdate(name, currentType, 0);`** - Add with the stored type, 0 occurrences
- **Why 0?** Declaration doesn't count as a usage yet

**Scenario 2: We don't expect a declaration**
- The identifier is being used (not declared)
- **`insertOrUpdate(name, "-", 1);`** - Add or update with "-" as type, count as 1 occurrence
- **Why "-"?** We don't track the type of usage
- **Why 1?** Count this as a usage

### Example:
```c
int count = 0;
count = count + 1;
```

- **Line 1:** See "int" → flag=1. See "count" → Add with type "int", occurrence=0
- **Line 2:** See "count" (first one) → flag=0. Update "count", occurrence=1
- **Line 2:** See "count" (second one) → Update "count", occurrence=2

---

## Number Handling

```c
[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)? { /* ignore numeric constants */ }
```

### What This Rule Does:

Matches numeric constants (numbers) and ignores them.

- **`[0-9]+`** → One or more digits (e.g., "42")
- **`(\.[0-9]+)?`** → Optionally, a decimal point followed by digits (e.g., ".5")
  - **`?`** makes it optional
  - **Example:** "3.14"
- **`([eE][+-]?[0-9]+)?`** → Optionally, scientific notation (e.g., "1e-5")
  - **`e` or `E`** → Exponent indicator
  - **`[+-]?`** → Optional sign
  - **`[0-9]+`** → Exponent digits

**Examples matched:**
- `42`, `3.14`, `1e10`, `2.5e-3`

**Action:** Do nothing (ignore numbers)

---

## String Handling

```c
\"([^\\\"]|\\.)*\" { /* ignore strings */ }
```

### What This Rule Does:

Matches string literals and ignores them.

- **`\"`** → A double quote character (escaped with `\`)
- **`([^\\\"]|\\.)*`** → Inside the quotes:
  - **`[^\\\"]`** → Any character that is NOT a backslash or quote
  - **OR**
  - **`\\.`** → A backslash followed by any character (for escaped characters like `\"` or `\\`)
  - **`*`** → Repeat any number of times

**Examples matched:**
- `"hello"`, `"name: \"John\""`, `"line1\nline2"`

**Action:** Do nothing (ignore string contents)

---

## Whitespace Handling

```c
[ \t\r\n]+ { /* ignore whitespace */ }
```

### What This Rule Does:

Matches whitespace characters and ignores them.

- **`[ \t\r\n]+`** → One or more of:
  - Space, Tab, Carriage return, Newline
- **`+`** → One or more occurrences

**Action:** Do nothing (skip whitespace)

---

## Catch-All Rule

```c
. { /* ignore other tokens */ }
```

### What This Rule Does:

Matches any single character not matched by previous rules.

- **`.`** → Any single character
- **Action:** Do nothing

**Why?** This is a safety net for operators, punctuation, etc. that we don't care about.

---

## Main Function

```c
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
```

### Function Signature:

```c
int main(int argc, char **argv)
```

- **`int main`** → Returns an integer (exit code)
- **`int argc`** → Number of command-line arguments
- **`char **argv`** → Array of command-line argument strings

### Line-by-line Explanation:

```c
FILE *inputFile = NULL;
```

- **`FILE *inputFile`** → Create a file pointer (used to access a file)
- **`= NULL`** → Initialize it to NULL (no file yet)
- **Why?** We'll later open a file and store the reference here

**Step 1: Open the File**

```c
inputFile = fopen("sample_program.c", "r");
```

- **`fopen("sample_program.c", "r")`** → Open the file "sample_program.c"
  - **`"r"`** → Open in read mode (we can only read from it)
- **Stores:** The file reference in `inputFile`
- **Returns:** A file pointer if successful, or NULL if it fails

**Step 2: Error Checking**

```c
if (inputFile == NULL) {
    perror("Unable to open input file");
    return 1;
}
```

- **`if (inputFile == NULL)`** → Check if opening the file failed
- **`perror(...)`** → Print an error message
- **`return 1;`** → Exit the program with code 1 (indicates error)
- **Why?** If we can't open the file, there's no point continuing

**Step 3: Tell Flex Where to Read From**

```c
yyin = inputFile;
```

- **`yyin`** → A special Flex variable that tells the lexer where to read input from
- **By default:** `yyin` reads from `stdin` (keyboard)
- **Now:** We tell it to read from our file

**Step 4: Run the Lexer**

```c
yylex();
```

- **`yylex()`** → The main Flex function
- **What it does:** 
  - Reads the input file character by character
  - Matches text against the lexer rules
  - Executes the corresponding action for each rule
  - Continues until the entire file is read

**Step 5: Print Results**

```c
printSymbolTable();
```

- **Calls:** Our `printSymbolTable()` function
- **What it does:** Displays the collected identifiers in table format

**Step 6: Close the File**

```c
if (inputFile != NULL) {
    fclose(inputFile);
}
```

- **`if (inputFile != NULL)`** → If the file was successfully opened
- **`fclose(inputFile);`** → Close the file and free the resource
- **Why?** Always close files when done to prevent resource leaks

**Step 7: Return Success**

```c
return 0;
```

- **`return 0;`** → Exit the program with code 0 (indicates success)
- **Convention:** 0 = success, non-zero = error

---

## Complete Execution Flow Example

Let's trace through what happens when we run the program with this input:

```c
int main() {
    int count = 0;
    count++;
    return 0;
}
```

### Step-by-step:

1. **Open file:** `sample_program.c` → Load the code above
2. **Read `int`:** Match data type rule → Store "int" in currentType, set flag=1
3. **Read `main`:** Followed by `(` → Match function rule → Add "main" with type "-"
4. **Read `(`:** Ignored by catch-all rule
5. **Read `)`:** Ignored by catch-all rule
6. **Read `{`:** Ignored by catch-all rule
7. **Read `int`:** Match data type rule → Store "int" in currentType, set flag=1
8. **Read `count`:** No `(` follows → Match identifier rule → Add "count" with type "int", occurrence=0, set flag=0
9. **Read `= 0`:** Operators and numbers ignored
10. **Read `;`:** Match semicolon rule → Clear flag and type
11. **Read `count`:** Match identifier rule → No flag set → Update "count", increment occurrence to 1
12. **Read `++`:** Ignored by catch-all rule
13. **Read `;`:** Match semicolon rule → Clear flag and type
14. **Continue...** until EOF

### Output:

```
-------------------------------------------------------------
Sl. No. | Identifier | Data Type | Occurrences
-------------------------------------------------------------
1        | main        | -          | 1         
2        | count       | int        | 1         
-------------------------------------------------------------
```

---

## Key Concepts Summary

| Concept          | Meaning                                                           |
| ---------------- | ----------------------------------------------------------------- |
| **Lexer**        | A program that reads text and breaks it into tokens (small units) |
| **Flex**         | A tool to create lexers from pattern rules                        |
| **Symbol Table** | A data structure that stores information about identifiers        |
| **Identifier**   | A name used in code (variable name, function name, etc.)          |
| **Token**        | A unit of meaningful text (keyword, identifier, operator, etc.)   |
| **Pattern**      | A regex rule that describes what text to match                    |
| **Action**       | The code executed when a pattern is matched                       |
| **yytext**       | The actual matched text in Flex                                   |
| **yyin**         | Where Flex reads input from in Flex                               |

---

## Common Debugging Tips

1. **Program doesn't detect identifiers:**
   - Check the regex patterns are correct
   - Verify the data type rules come before identifier rules

2. **Occurrence count wrong:**
   - Check if `expectIdentifierForDeclaration` flag is being set/cleared correctly
   - Verify `countAsOccurrence` parameter values in `insertOrUpdate()` calls

3. **Symbol table shows strange characters:**
   - Check null terminator `\0` is properly added
   - Verify string copy functions are bounded (using `strncpy`)

4. **Program crashes:**
   - Verify symbol table array bounds (max 100 identifiers)
   - Check for NULL file pointer before reading
