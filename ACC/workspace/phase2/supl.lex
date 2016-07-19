/*------------------------------------------------------------------------------
  HEIG-Vd - CoE@SNU              Summer University              July 11-22, 2016

  The Art of Compiler Construction


  suPL scanner definition

*/

%option yylineno

%{
#include "supl.tab.h"       // token definitions and yylval - generated by bison

int yycolumn = 1;

#define YY_USER_ACTION {                            \
  yylloc.first_line = yylloc.last_line = yylineno;  \
  yylloc.first_column = yycolumn;                   \
  yylloc.last_column = yycolumn + yyleng - 1;       \
  yycolumn += yyleng;                               \
}
%}

DIGIT     [0-9]
ALPHA     [A-Za-z_]
NUMBER    {DIGIT}+

%%

int                       { return(INTEGER); }
void                      { return(VOID); }

{ALPHA}({ALPHA}|{DIGIT})* { yylval.str = strdup(yytext); return(IDENT); }
{DIGIT}+                  { yylval.n = atoi(yytext);     return(NUMBER); }                  
\".*\"                    { yylval.str = strdup(yytext); return(STRING); }

[ \t]+                    // ignore whitespace
[\n]+                     { yycolumn = 1; }           // reset column on newlines
.                         { return(yytext[0]); }

%%
