#!/bin/bash

# Создание структуры директорий
mkdir -p project_root/src
mkdir -p project_root/bin

# Создание файла commands.l
cat << 'EOF' > project_root/src/commands.l
%{
#include "y.tab.h"
#include <wchar.h>
#include <wctype.h>
#include <locale.h>
#include <stdlib.h>
#include <time.h>
#include <stdio.h>

void initialize();
void handle_error(const char *error);
%}

%x UTF16

%%
"add"              { return ADD; }
"analyze"          { return ANALYZE; }
"command"          { return COMMAND; }
"directory"        { return DIRECTORY; }
"ping"             { return PING; }
"self"             { return SELF; }
"traceroute"       { return TRACEROUTE; }
"feelings"         { return FEELINGS; }
"utf16"            { BEGIN UTF16; }
<UTF16>[0-9A-Fa-f]{4} {
                       wchar_t wc;
                       swscanf(yytext, L"%4hx", &wc);
                       yylval.wc = wc;
                       return UTF16CHAR;
                   }
<UTF16>[ \t\n]      { /* игнорирование пробелов и новых строк */ }
<UTF16>.            { handle_error("Invalid UTF-16 character"); }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return IDENTIFIER; }
[ \t\n]            { /* игнорирование пробелов и новых строк */ }
.                  { return yytext[0]; }
%%
EOF

# Создание файла commands.y
cat << 'EOF' > project_root/src/commands.y
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <locale.h>
#include <time.h>

typedef struct Command {
    char *name;
    void (*function)();
    struct Command *next;
    int color_level;
} Command;

Command *command_list = NULL;

void add_command(char *name, void (*function)(), int color_level);
void analyze_self();
void ask_feelings();
void execute_command(char *name);
void perform_ping(const char* host);
void perform_traceroute(const char* host);
void initialize();
void handle_error(const char *error);
void cache_command(char *name, void (*function)());
void load_cache();
%}

%union {
    char *str;
    wchar_t wc;
}

%token <str> IDENTIFIER
%token <wc> UTF16CHAR
%token ADD ANALYZE COMMAND DIRECTORY FEELINGS PING SELF TRACEROUTE UTF16

%%
commands:
    command '\n' { printf("Command executed.\n"); }
    ;

command:
    ADD COMMAND IDENTIFIER { add_command($3, NULL, 1); }
    | ANALYZE SELF { analyze_self(); }
    | FEELINGS { ask_feelings(); }
    | IDENTIFIER { execute_command($1); }
    | PING { perform_ping("google.com"); }
    | TRACEROUTE { perform_traceroute("google.com"); }
    | UTF16CHAR { wprintf(L"UTF-16 Character: %lc\n", $1); }
    ;
%%

int main() {
    initialize();
    load_cache();
    add_command("analyze_self", analyze_self, 4);
    add_command("ping", perform_ping, 5);
    add_command("traceroute", perform_traceroute, 6);
    add_command("feelings", ask_feelings, 7);
    
    yyparse();
    return 0;
}

void initialize() {
    setlocale(LC_ALL, "");
    srand(time(NULL));
}

void yyerror(char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void handle_error(const char *error) {
    fprintf(stderr, "Error: %s\n", error);
    // Здесь можно подключить внешнюю модель GPT для обработки ошибки и поиска решений
}

void add_command(char *name, void (*function)(), int color_level) {
    Command *new_command = malloc(sizeof(Command));
    new_command->name = strdup(name);
    new_command->function = function;
    new_command->color_level = color_level;
    new_command->next = command_list;
    command_list = new_command;

    // Кэширование команды
    cache_command(name, function);
}

void analyze_self() {
    printf("Analyzing system...\n");
    system("free -h");
    system("uptime");
    system("df -h");
    printf("System analysis completed.\n");
    printf("How are you feeling?\n");
}

void ask_feelings() {
    printf("How are you feeling?\n");
}

void execute_command(char *name) {
    Command *current = command_list;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            if (current->function != NULL) {
                current->function();
            } else {
                printf("Command '%s' added but not implemented yet.\n", name);
            }
            return;
        }
        current = current->next;
    }
    printf("Unknown command: %s\n", name);
}

void perform_ping(const char* host) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ping -c 4 %s", host);
    printf("Performing ping to: %s\n", host);
    system(cmd);
}

void perform_traceroute(const char* host) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "traceroute %s", host);
    printf("Performing traceroute to: %s\n", host);
    system(cmd);
}

void cache_command(char *name, void (*function)()) {
    FILE *cache = fopen("command_cache.txt", "a");
    if (cache == NULL) {
        handle_error("Failed to open cache file");
        return;
    }
    fprintf(cache, "%s\n", name);
    fclose(cache);
}

void load_cache() {
    FILE *cache = fopen("command_cache.txt", "r");
    if (cache == NULL) {
        handle_error("Failed to open cache file");
        return;
    }
    char name[256];
    while (fgets(name, sizeof(name), cache)) {
        name[strcspn(name, "\n")] = '\0';
        add_command(name, NULL, 1);
    }
    fclose(cache);
}
EOF

# Создание файла command_parser.c
cat << 'EOF' > project_root/src/command_parser.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <locale.h>
#include <time.h>
#include "commands.h"

int main() {
    initialize();
    load_cache();
    add_command("analyze_self", analyze_self, 4);
    add_command("ping", perform_ping, 5);
    add_command("traceroute", perform_traceroute, 6);
    add_command("feelings", ask_feelings, 7);
    
    yyparse();
    return 0;
}

void initialize() {
    setlocale(LC_ALL, "");
    srand(time(NULL));
}

void yyerror(char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void handle_error(const char *error) {
    fprintf(stderr, "Error: %s\n", error);
    // Здесь можно подключить внешнюю модель GPT для обработки ошибки и поиска решений
}

void add_command(char *name, void (*function)(), int color_level) {
    Command *new_command = malloc(sizeof(Command));
    new_command->name = strdup(name);
    new_command->function = function;
    new_command->color_level = color_level;
    new_command->next = command_list;
    command_list = new_command;

    // Кэширование команды
    cache_command(name, function);
}

void analyze_self() {
    printf("Analyzing system...\n");
    system("free -h");
    system("uptime");
    system("df -h");
    printf("System analysis completed.\n");
    printf("How are you feeling?\n");
}

void ask_feelings() {
    printf("How are you feeling?\n");
}

void execute_command(char *name) {
    Command *current = command_list;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0) {
            if (current->function != NULL) {
                current->function();
            } else {
                printf("Command '%s' added but not implemented yet.\n", name);
            }
            return;
        }
        current = current->next;
    }
    printf("Unknown command: %s\n", name);
}

void perform_ping(const char* host) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ping -c 4 %s", host);
    printf("Performing ping to: %s\n", host);
    system(cmd);
}

void perform_traceroute(const char* host) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "traceroute %s", host);
    printf("Performing traceroute to: %s\n", host);
    system(cmd);
}

void cache_command(char *name, void (*function)()) {
    FILE *cache = fopen("command_cache.txt", "a");
    if (cache == NULL) {
        handle_error("Failed to open cache file");
        return;
    }
    fprintf(cache, "%s\n", name);
    fclose(cache);
}

void load_cache() {
    FILE *cache = fopen("command_cache.txt", "r");
    if (cache == NULL) {
        handle_error("Failed to open cache file");
        return;
    }
    char name[256];
    while (fgets(name, sizeof(name), cache)) {
        name[strcspn(name, "\n")] = '\0';
        add_command(name, NULL, 1);
    }
    fclose(cache);
}
EOF

# Компиляция и запуск
cd project_root/src
lex commands.l
yacc -d commands.y
cc lex.yy.c y.tab.c -o ../bin/command_parser -ll -ly

# Запуск командного парсера
../bin/command_parser
