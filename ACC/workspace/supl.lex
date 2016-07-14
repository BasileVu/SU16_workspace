/*------------------------------------------------------------------------------
  HEIG-Vd - CoE@SNU              Summer University              July 11-22, 2016

  The Art of Compiler Construction


  suPL scanner definition

*/

SPACES          [\ ]*
DIGIT           [0-9]
NUMBER          {DIGIT}+
ALPHA           [a-zA-Z]
IDENT           {ALPHA}({ALPHA}|{NUMBER})+
OP              [\+\-\*\/\%\^]
COMPARATOR      ==|<=|<|&&
CONDITION       {EXPRESSION}{SPACES}{COMPARATOR}{SPACES}{EXPRESSION}
CALL            {IDENT}\(({EXPRESSION}(,{EXPRESSION})+)*\)
EXPRESSION      {NUMBER}|{IDENT}
STMT            {IF}|{RETURN}
STMTBLOCK       \{.*\}

IF              if{SPACES}\({CONDITION}\){SPACES}{STMTBLOCK}
RETURN          return.*

%%
{NUMBER}        printf("number: %s\n", yytext);
int|void        printf("type: %s\n", yytext);
{STMT}          printf("statement: %s\n", yytext);
{OP}            printf("op: %s\n", yytext);
{CONDITION}     printf("condition: %s\n", yytext);
{RETURN}        printf("return\n");
{IDENT}         printf("ident: %s\n", yytext);
\n 
.
%%
    

int main( int argc, char **argv )
{
  yyin = stdin;
  if (argc > 1) yyin = fopen(argv[1], "r");

  yylex();

  return 0;
}


