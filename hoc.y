/* definitions */
%{
    #include <stdio.h>
    #include <ctype.h>
    #include <signal.h>
    #include <setjmp.h>
    #include "hoc.h"
    extern double Pow();
    jmp_buf begin;
    int yylex();
    void yyerror(char *);
%}
%union {    // stack type
    double val; // actual value
    Symbol *sym;  // symbol table pointer
}
%token  <val>   NUMBER
%token  <sym>   VAR BLTIN UNDEF
%type   <val>   expr asgn
%right  '='
%left   '+' '-' /* left-associative, same precedence */
%left   '*' '/' /* left-associative, higher precedence */
%left   UNARYMINUS  /* serve the purpose of %token and specify associativity and relative precedence */
%right  '^' /* exponentiation */

%%
/* rules */
list:   /* nothing */
        |   list '\n'
        |   list asgn '\n'
        |   list expr '\n'  { printf("\t%.8g\n", $2); }
        |   list error '\n' { yyerrok; }
        /* error is reserved word in yacc for error recovery,
        which is generated whenever a syntax error happens.
        yyerrok is a macro defined by yacc being to invoked
        meaning that that error recovery is complete */
        ;
asgn:   VAR '=' expr { $$ = $1->u.val = $3; $1->type = VAR; }
        ;
expr:   NUMBER
        |   VAR {
                if ($1->type == UNDEF)
                    execerror("undefined variable", $1->name);
                $$ = $1->u.val;
            }
        |   asgn
        |   BLTIN '(' expr ')'  { $$ = (*($1->u.ptr))($3); }
        |   expr '+' expr   { $$ = $1 + $3; }
        |   expr '-' expr   { $$ = $1 - $3; }
        |   expr '*' expr   { $$ = $1 * $3; }
        |   expr '/' expr   {
                if ($3 == 0.0)
                    execerror("division by zero", "");
                $$ = $1 / $3;
            }
        |   expr '^' expr   { $$ = Pow($1, $3); }
        |   '(' expr ')'    { $$ = $2; }
        |   '-' expr    %prec UNARYMINUS { $$ = -$2; }
        /* specify precedence of a rule,
        which means the precedence of the rule is the same as
        the precedence of token UNARYMINUS */
        ;
%%

/* auxiliary routines */
char *progname; /* for error messages */
int lineno = 1;

int main(int argc, char *argv[]) {
    void init();
    progname = argv[0];
    init();
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
    // if (islower(c)) {
    //     yylval.index = c - 'a'; // ASCII only
    //     return VAR;
    // }
    if (isalpha(c)) {
        Symbol *s;
        char sbuf[100], *p = sbuf;
        do {
            *p++ = c;
        } while ((c=getchar()) != EOF && isalnum(c));
        ungetc(c, stdin);
        *p = '\0';
        if ((s = lookup(sbuf)) == 0)
            s = install(sbuf, UNDEF, 0.0);
        yylval.sym = s;
        return s->type == UNDEF ? VAR : s->type;
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