/*------------------------------------------------------------------------------
  HEIG-Vd - CoE@SNU              Summer University              July 11-22, 2016

  The Art of Compiler Construction


  suPL scanner definition

*/

WHITESPACES     [\ \n]*
DIGIT           [0-9]
NUMBER          {DIGIT}+
ALPHA           [a-zA-Z]
STRING          \"({ALPHA}|{DIGIT})*\"
IDENT           {ALPHA}({ALPHA}|{NUMBER})+
OP              [\+\-\*\/\%\^]
COMPARATOR      ==|<=|<|&&
EXPRESSION      {NUMBER}|{IDENT}

TYPE            int|void

IF              if
WHILE           while
RETURN          return

%%
{NUMBER}        printf("number: %s\n", yytext);
{TYPE}          printf("type: %s\n", yytext);
{OP}            printf("op: %s\n", yytext);
{RETURN}        printf("return\n");
{IDENT}         printf("ident: %s\n", yytext);
{COMPARATOR}    printf("comparator: %s\n", yytext);

\(              printf("(\n");
\)              printf(")\n");
\{              printf("{\n");
\}              printf("}\n");

call            printf("call: %s\n", yytext);

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


