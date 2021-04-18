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

typedef union Datum {   // interpreter stack type
    double val;
    Symbol *sym;
} Datum;

extern Datum pop();

typedef int (*Inst)();  // machine instruction
#define STOP (Inst) 0

extern Inst prog[], *progp, *code();
extern void initcode();
extern void eval(), add(), sub(), mul(), divide(), negate(), power();
extern void assign(), bltin(), varpush(), constpush(), print(), execute(Inst *);
extern void prexpr();
extern void gt(), lt(), eq(), ge(), le(), ne(), and(), or(), not();
extern void ifcode(), whilecode();

void execerror(char *, char *);
void fpecatch();
void warning(char *, char *);