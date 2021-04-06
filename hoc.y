/* definitions */
%{
    #include <stdio.h>
    #include <ctype.h>
    #define YYSTYPE double  /* data type of yacc stack */
    int yylex();
    void yyerror(char *);
    void warning(char *, char *);
%}
%token  NUMBER
%left   '+' '-' /* left-associative, same precedence */
%left   '*' '/' /* left-associative, higher precedence */
%left   UNARYMINUS

%%
/* rules */
list:   /* nothing */
        |   list '\n'
        |   list expr '\n'  { printf("\t%.8g\n", $2); }
        ;
expr:   NUMBER  { $$ = $1; }
        |   expr '+' expr   { $$ = $1 + $3; }
        |   expr '-' expr   { $$ = $1 - $3; }
        |   expr '*' expr   { $$ = $1 * $3; }
        |   expr '/' expr   { $$ = $1 / $3; }
        |   '(' expr ')'    { $$ = $2; }
        |   '-' expr    %prec UNARYMINUS { $$ = -$2; }
        ;
%%

/* auxiliary routines */
char *progname; /* for error messages */
int lineno = 1;

int main(int argc, char *argv[]) {
    progname = argv[0];
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
        scanf("%lf", &yylval); // yylval is the value of the token shared between parser and lexical analyzer
        return NUMBER;
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
