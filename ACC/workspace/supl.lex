/*------------------------------------------------------------------------------
  HEIG-Vd - CoE@SNU              Summer University              July 11-22, 2016

  The Art of Compiler Construction


  suPL scanner definition

*/

WSPACE          [\ \n]
DIGIT           [0-9]
NUMBER          {DIGIT}+
ALPHA           [a-zA-Z]
STRING          \".*\"
ID              {ALPHA}({ALPHA}|{NUMBER})*
OP              [\+\-\*\/\%\^]
COMP            ==|<=|<|>|>=|&&|\|\|

TYPE            int|void
KEY             if|else|while|read|write|print|return

%%
{NUMBER}        printf("NUMBER %s\n", yytext);
{TYPE}          printf("TYPE %s\n", yytext);
{OP}            printf("OP %s\n", yytext);
{COMP}          printf("COMP %s\n", yytext);
{KEY}           printf("KEY %s\n", yytext);
{STRING}        printf("STRING %s\n", yytext);
{ID}            printf("ID %s\n", yytext);

=               printf("=\n");
\(              printf("(\n");
\)              printf(")\n");
\{              printf("{\n");
\}              printf("}\n");
,               printf(",\n");
;               printf(";\n");

{WSPACE}+
.
%%
    

int main( int argc, char **argv )
{
  yyin = stdin;
  if (argc > 1) yyin = fopen(argv[1], "r");

  yylex();

  return 0;
}


