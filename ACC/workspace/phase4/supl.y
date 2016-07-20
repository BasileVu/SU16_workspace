/*------------------------------------------------------------------------------
  HEIG-Vd - CoE@SNU              Summer University              July 11-22, 2016

  The Art of Compiler Construction


  suPL parser definition

*/

%locations

%code top{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define YYDEBUG 1

extern char *yytext;
}

%code requires {
#include "supllib.h"
}

%union {
    long int n;
    char     *str;
    IDlist   *idl;
    EType    t;
    BPrecord *bpr;
    EOpcode  *eop;
}

%code {
    Stack   *stack = NULL;
    Symtab *symtab = NULL;
    CodeBlock *cb  = NULL;

    char *fn_pfx   = NULL;
    EType rettype  = tVoid;
    
    Funclist *fn_list = NULL;
}

%start program

%token INTEGER VOID
%token NUMBER
%token IDENT
%token STRING

%token IF
%token ELSE
%token WHILE
%token PRINT
%token READ
%token WRITE
%token RETURN

%token EQ
%token LTE
%token LT

%type<n>    number NUMBER optcallpars exprl condition
%type<str>  ident IDENT
%type<idl>  identl vardecl paraml
%type<t>    type
%type<str>  STRING
%type<bpr>  IF WHILE

%%

program     :                               { 
                                                stack = init_stack(NULL); 
                                                symtab = init_symtab(stack, NULL); 
                                            } 
              decll                         { 
                                                cb = init_codeblock(""); 
                                                stack = init_stack(stack); 
                                                symtab = init_symtab(stack, symtab);
                                                rettype = tVoid;
                                            } 
              stmtblock                     { 
                                                add_op(cb, opHalt, NULL);
                                                dump_codeblock(cb); save_codeblock(cb, fn_pfx);
                                                
                                                Stack *pstck = stack; 
                                                stack = stack->uplink; 
                                                delete_stack(pstck);
                                                
                                                Symtab *pst = symtab; 
                                                symtab = symtab->parent; 
                                                delete_symtab(pst);
                                            }
            ;

decll       : %empty
            | decll vardecl ';'             { delete_idlist($vardecl); }
            | decll fundecl
            ;

vardecl     : type identl                   {
                                                if ($type == tVoid) {
                                                    char *error = NULL;
                                                    asprintf(&error, "void type is not allowed.");
                                                    yyerror(error);
                                                    free(error);
                                                    YYABORT;
                                                }

                                                IDlist *l = $identl;
                                                while (l) { 
                                                    if (insert_symbol(symtab, l->id, $type) == NULL) {
                                                        char *error = NULL;
                                                        asprintf(&error, "Duplicated identifier '%s'.", l->id);
                                                        yyerror(error);
                                                        free(error);
                                                        YYABORT;
                                                    }
                                                    l = l->next;
                                                }
                                                $$ = $identl;
                                            }
            ;
identl      : ident                         { 
                                                $$ = (IDlist*)calloc(1, sizeof(IDlist)); 
                                                $$->id = $ident; 
                                            }
            | identl ',' ident              { 
                                                $$ = (IDlist*)calloc(1, sizeof(IDlist)); 
                                                $$->id = $ident; 
                                                $$->next = $1;
                                            }
            ;
            
type        : INTEGER                       { $$ = tInteger; }
            | VOID                          { $$ = tVoid; }
            ;
          
fundecl     : type ident '(' paraml ')' { 

                                                        if (find_func(fn_list, $ident)) {
                                                            char *error = NULL;
                                                            asprintf(&error, "function name already exists.");
                                                            yyerror(error);
                                                            free(error);
                                                            YYABORT;
                                                        }
                                                        
                                                        Funclist *func = (Funclist*)calloc(1, sizeof(Funclist));
                                                        func->id = $ident;
                                                        func->rettype = $type;
                                                        func->narg = 0;
                                                        func->next = fn_list;
                                                        
                                                        fn_list = func;
                                                        
                                                        IDlist *l = $paraml;
                                                        while (l) {
                                                            l = l->next;
                                                            func->narg++;
                                                        }

                                                        rettype = $type;
                                                    }
            stmtblock                               
            ;
          
paraml      :  %empty                               { $$ = NULL; }
            |  vardecl
            ;
  
stmtblock   : '{' '}'
            | '{' stmtl '}'
            ;
                        
stmtl       : stmt
            | stmtl stmt
            ;
            
stmt        : vardecl ';'
            | assign
            | if
            | while
            | call ';'
            | return
            | read
            | write
            | print
            ;
            
assign      : ident '=' expression ';'                  { 
                                                            Symbol* sym = find_symbol(symtab, $ident, sGlobal);
                                                            if (sym == NULL) {
                                                                yyerror("Unknown identifier %s.", $ident);
                                                                YYABORT;
                                                            }
                                                            add_op(cb, opStore, sym);
                                                        }
            ;
            
if          : IF '(' condition ')'                      {
                                                            $IF = (BPrecord*)calloc(1, sizeof(BPrecord));
                                                            Operation *tb = add_op(cb, $condition, NULL);
                                                            Operation *fb = add_op(cb, opJump, NULL);
                                                            $IF->ttrue = add_backpatch($IF->ttrue, tb);
                                                            $IF->tfalse = add_backpatch($IF->tfalse, fb);
                                                            pending_backpatch(cb, $IF->ttrue);

                                                        }
              stmtblock                                 {
                                                            Operation *next = add_op(cb, opJump, NULL);
                                                            $IF->end = add_backpatch($IF->end, next);
                                                            pending_backpatch(cb, $IF->tfalse);
                                                        }
              else                                      { 
                                                            pending_backpatch(cb, $IF->end);
                                                        }
            ;
    
else        : %empty
            | ELSE stmtblock
            ;

while       : WHILE '(' condition ')' stmtblock
            ;

call        : ident '(' optcallpars ')'                     { 

                                                                Funclist *f = find_func(fn_list, $ident);
                                                                if (f == NULL) {
                                                                    char *error = NULL;
                                                                    asprintf(&error, "function %s was not declared.", $ident);
                                                                    yyerror(error);
                                                                    free(error);
                                                                    YYABORT;
                                                                }

                                                                if ($optcallpars != f->narg) {
                                                                    char *error = NULL;
                                                                    asprintf(&error, "the number of arguments for %s does not match.", f->id);
                                                                    yyerror(error);
                                                                    free(error);
                                                                    YYABORT;
                                                                }
                                                            }

optcallpars : %empty                                    {  $$ = 0; }
            | exprl
            ;
      
exprl       : expression                                {  $$ = 1; }
            | exprl ',' expression                      {  $$ = $1 + 1; }
            ;
            
return      : RETURN ';'                                {
                                                             if (rettype != tVoid) {
                                                                 yyerror("Expression expected.");
                                                                 YYABORT;
                                                             }

                                                        }
            | RETURN expression ';'                     { 
                                                            if (rettype == tVoid) {
                                                                yyerror("Function has no return value.");
                                                                YYABORT;
                                                            }
                                                        }

            ;

read        : READ ident ';'                            { /*add_op(cb, opRead, NULL);*/ }
            ;
            
write       : WRITE expression ';'                      { /*add_op(cb, opWrite, NULL);*/ }
            ;            
            
print       : PRINT string ';'                          { /*add_op(cb, opPrint, NULL);*/ }
            ;

expression  : number                                    { add_op(cb, opPush, (void*)(long int)$number); }
            | ident                                     { 
                                                            Symbol* sym = find_symbol(symtab, $ident, sGlobal);
                                                            if (sym == NULL) {
                                                                yyerror("Unknown identifier %s.", $ident);
                                                                YYABORT;
                                                            }
                                                            add_op(cb, opLoad, sym);
                                                        }

            | expression '+' expression                 { add_op(cb, opAdd, NULL); }
            | expression '-' expression                 { add_op(cb, opSub, NULL); }
            | expression '*' expression                 { add_op(cb, opMul, NULL); }
            | expression '/' expression                 { add_op(cb, opDiv, NULL); }
            | expression '%' expression                 { add_op(cb, opMod, NULL); }
            | expression '^' expression                 { add_op(cb, opPow, NULL); }
            |'(' expression ')'                         
            | call                                      { 
                                                            
                                                        }            
            ;
            
condition   : expression EQ expression                  { $$ = opJeq; }
            | expression LTE expression                 { $$ = opJle; }
            | expression LT expression                  { $$ = opJlt; }
            ;
            
number      : NUMBER
            ;
            
ident       : IDENT
            ;
            
string      : STRING
            ;
%%

int main(int argc, char *argv[])
{
  extern FILE *yyin;
  argv++; argc--;

  while (argc > 0) {
    // prepare filename prefix (cut off extension)
    fn_pfx = strdup(argv[0]);
    char *dot = strrchr(fn_pfx, '.');
    if (dot != NULL) *dot = '\0';

    // open source file
    yyin = fopen(argv[0], "r");
    yydebug = 0;

    // parse
    yyparse();

    // next input
    free(fn_pfx);
    argv++; argc--;
  }

  return 0;
}

int yyerror(const char *msg)
{
  printf("Parse error at %d:%d: %s\n", yylloc.first_line, yylloc.first_column, msg);
  return 0;
}

