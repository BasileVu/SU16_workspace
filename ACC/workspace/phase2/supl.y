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

%type<n>    NUMBER
%type<str>  ident IDENT
%type<idl>  identl vardecl
%type<t>    type
%type<str>  STRING

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
          
fundecl     : type ident '(' ')' stmtblock          { 
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
                                                    }   
            | type[t1] ident '(' type[t2] identl ')' stmtblock  { 

                                                        if (find_func(fn_list, $ident)) {
                                                            char *error = NULL;
                                                            asprintf(&error, "function name already exists.");
                                                            yyerror(error);
                                                            free(error);
                                                            YYABORT;
                                                        }
                                                        
                                                        Funclist *func = (Funclist*)calloc(1, sizeof(Funclist));
                                                        func->id = $ident;
                                                        func->rettype = $t1;
                                                        func->narg = 0;
                                                        func->next = fn_list;
                                                        
                                                        fn_list = func;

                                                        if ($t2 == tVoid) {
                                                            char *error = NULL;
                                                            asprintf(&error, "void type is not allowed.");
                                                            yyerror(error);
                                                            free(error);
                                                            YYABORT;
                                                        }
                                                        
                                                        IDlist *l = $identl;
                                                        while (l) { 
                                                            if (insert_symbol(symtab, l->id, $t2) == NULL) {
                                                                char *error = NULL;
                                                                asprintf(&error, "Duplicated identifier '%s'.", l->id);
                                                                yyerror(error);
                                                                free(error);
                                                                YYABORT;
                                                            }
                                                            l = l->next;
                                                            func->narg++;
                                                        }
                                                    }
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
            
assign      : ident '=' expression ';'
            ;
            
if          : IF '(' condition ')' stmtblock
            | IF '(' condition ')' stmtblock ELSE stmtblock
            ;
    
while       : WHILE '(' condition ')' stmtblock
            ;

call        : ident '(' ')'
            | ident '(' exprl ')'
            ;
            
exprl       : expression
            | exprl ',' expression
            ;
            
return      : RETURN ';'
            | RETURN expression ';' 
            ;

read        : READ ident ';'
            ;
            
write       : WRITE expression ';'
            ;            
            
print       : PRINT string ';'
            ;

expression  : number
            | ident
            | expression '+' expression
            | expression '-' expression
            | expression '*' expression
            | expression '/' expression
            | expression '%' expression
            | expression '^' expression
            |'(' expression ')'
            | call
            ;
            
condition   : expression EQ expression
            | expression LTE expression
            | expression LT expression
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

