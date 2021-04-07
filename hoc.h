
typedef struct Symbol { // symbol table entry
    char *name;
    short type; // VAR, BLTIN, UNDEF
    union {
        double val; // if VAR
        double (*ptr)(); // if BLTIN
    } u;
    struct Symbol *next; // to link to another
} Symbol ;

Symbol *install(), *lookup();

void execerror(char *s, char *t);
void fpecatch();
void warning(char *, char *);