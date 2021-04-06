/* definitions */
%{
    #include <stdio.h>
    #include <ctype.h>
    #include <signal.h>
    #include <setjmp.h>
    #define MAX_MEM 26
    jmp_buf begin;
    double mem[MAX_MEM]; // memory for variables 'a' ... 'z'
    int yylex();
    void yyerror(char *);
    void warning(char *, char *);
    void execerror(char *, char*);
    void fpecatch();
%}
%union {    // stack type
    double val; // actual value
    int index;  // index into mem[]
}
%token  <val>   NUMBER
%token  <index> VAR
%type  <val>   expr
%right  '='
%left   '+' '-' /* left-associative, same precedence */
%left   '*' '/' /* left-associative, higher precedence */
%left   UNARYMINUS

%%
/* rules */
list:   /* nothing */
        |   list '\n'
        |   list expr '\n'  { printf("\t%.8g\n", $2); }
        ;
expr:   NUMBER
        |   VAR { $$ = mem[$1]; }
        |   VAR '=' expr    { $$ = mem[$1] = $3; }
        |   expr '+' expr   { $$ = $1 + $3; }
        |   expr '-' expr   { $$ = $1 - $3; }
        |   expr '*' expr   { $$ = $1 * $3; }
        |   expr '/' expr   {
                if ($3 == 0.0)
                    execerror("division by zero", "");
                $$ = $1 / $3;
            }
        |   '(' expr ')'    { $$ = $2; }
        |   '-' expr    %prec UNARYMINUS { $$ = -$2; }
        ;
%%

/* auxiliary routines */
char *progname; /* for error messages */
int lineno = 1;

int main(int argc, char *argv[]) {
    progname = argv[0];
    setjmp(begin);
    signal(SIGFPE, fpecatch);
    yyparse();
    return 0;
}

int yylex() {
    int c;
    while((c = getchar()) == ' ' || c == '\t');

    if (c == EOF)
        return 0;

    if (c == '.' || isdigit(c)) { // number
        ungetc(c, stdin);
        scanf("%lf", &yylval.val); // yylval is the value of the token shared between parser and lexical analyzer
        return NUMBER;
    }
    if (islower(c)) {
        yylval.index = c - 'a'; // ASCII only
        return VAR;
    }
    if (c == '\n')
        lineno++;
    return c;
}

void yyerror(char *s) { // call for yacc syntax error
    warning(s, (char *) 0);
}

void warning(char *s, char *t) { // print warning message
    fprintf(stderr, "%s: %s", progname, s);
    if (t)
        fprintf(stderr, " %s", t);
    fprintf(stderr, " near line %d\n", lineno);
}

void execerror(char *s, char *t) {  // recover from run-time error
    warning(s, t);
    longjmp(begin, 0);
}

void fpecatch() {   // catch floating point exception
    execerror("floating point exception", (char *) 0);
}