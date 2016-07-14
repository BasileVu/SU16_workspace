/*------------------------------------------------------------------------------
  HEIG-Vd - CoE@SNU              Summer University              July 11-22, 2016

  The Art of Compiler Construction


  suPL scanner definition

*/

WHITESPACES     [\ \n]*
DIGIT           [0-9]
NUMBER          {DIGIT}+
ALPHA           [a-zA-Z]
STRING          \".*\"
IDENT           {ALPHA}({ALPHA}|{NUMBER})*
OP              [\+\-\*\/\%\^]
COMPARATOR      ==|<=|<|>|>=|&&|\|\|

TYPE            int|void
KEYWORD         if|else|while|read|write|print|return

%%
{NUMBER}        printf("number: %s\n", yytext);
{TYPE}          printf("type: %s\n", yytext);
{OP}            printf("op: %s\n", yytext);
{COMPARATOR}    printf("comparator: %s\n", yytext);
{KEYWORD}       printf("keyword: %s\n", yytext);
{STRING}        printf("string: %s\n", yytext);
{IDENT}         printf("ident: %s\n", yytext);

=               printf("=\n");
\(              printf("(\n");
\)              printf(")\n");
\{              printf("{\n");
\}              printf("}\n");
,               printf(",\n");
;               printf(";\n");

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


