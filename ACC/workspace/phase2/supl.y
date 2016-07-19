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
}

%start program

%token INTEGER VOID
%token NUMBER
%token IDENT
%token STRING

%type<n>    NUMBER
%type<str>  ident IDENT
%type<idl>  identl vardecl
%type<t>    type

%%

program     :                                 { stack = init_stack(NULL); symtab = init_symtab(stack, NULL); } 
              decll                           { cb = init_codeblock(""); 
                                                stack = init_stack(stack); symtab = init_symtab(stack, symtab);
                                                rettype = tVoid;
                                              } 
              stmtblock                       { add_op(cb, opHalt, NULL);
                                                dump_codeblock(cb); save_codeblock(cb, fn_pfx);
                                                Stack *pstck = stack; stack = stack->uplink; delete_stack(pstck);
                                                Symtab *pst = symtab; symtab = symtab->parent; delete_symtab(pst);
                                              }
            ;

decll       : %empty
            | decll vardecl ';'               { free_idlist($vardecl); }
            ;

vardecl     : type identl                     { 
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

type        : INTEGER                         { $$ = tInteger; }
            | VOID                            { $$ = tVoid; }
            ;

identl      : ident                           { $$ = (IDlist*)calloc(1, sizeof(IDlist)); $$->id = $ident; }
            | ident ',' identl                { $$ = (IDlist*)calloc(1, sizeof(IDlist)); $$->id = $ident; $$->next = $1; }
            ;

stmtblock   : '{' optstmt '}'
            ;
            
optstmt     : %empty
            | stmt
            ;
            
stmt        : vardecl ';'
            | assign
            | if
            | while
            | call ;
            | return
            | read
            | write
            | print
            ;
            
assign      : ident '=' expression
            ;
            
if          : "if" '(' condition ')' stmtblock optelse
            ;
        
optelse     : %empty
            | "else" stmtblock
            ;
    
while       : "while" '(' condition ')' stmtblock
            ;

call        : ident '(' params ')'
            ;

params      : %empty
            | paraml
            ;
            
paraml      : expression
            | expression ',' paraml
            ;
            
return      : "return" optexpr ';'
            ;

read        : "read" ident ';'
            ;
            
write        : "write" expression ';'
            ;            
            
print       : "print" string ';'
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

condition   : expression "==" expression 
            | expression "<=" expression 
            | expression '<' expression
            ;
            
number      : NUMBER
            ;
            
ident       : IDENT
            ;
            
string      : STRING
            ;
            
optexpr     : %empty
            | expression
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

