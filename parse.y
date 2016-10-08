%{     /* pars1.y    Pascal Parser      Gordon S. Novak Jr.  ; 30 Jul 13   */

/* Copyright (c) 2013 Gordon S. Novak Jr. and
   The University of Texas at Austin. */

/* 14 Feb 01; 01 Oct 04; 02 Mar 07; 27 Feb 08; 24 Jul 09; 02 Aug 12 */

/*
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program; if not, see <http://www.gnu.org/licenses/>.
  */


/* NOTE:   Copy your lexan.l lexical analyzer to this directory.      */

       /* To use:
                     make pars1y              has 1 shift/reduce conflict
                     pars1y                   execute the parser
                     i:=j .
                     ^D                       control-D to end input

                     pars1y                   execute the parser
                     begin i:=j; if i+j then x:=a+b*c else x:=a*b+c; k:=i end.
                     ^D

                     pars1y                   execute the parser
                     if x+y then if y+z then i:=j else k:=2.
                     ^D

           You may copy pars1.y to be parse.y and extend it for your
           assignment.  Then use   make parser   as above.
        */

        /* Yacc reports 1 shift/reduce conflict, due to the ELSE part of
           the IF statement, but Yacc's default resolves it in the right way.*/

#include <stdio.h>
#include <ctype.h>
#include "token.h"
#include "lexan.h"
#include "symtab.h"
#include "parse.h"

        /* define the type of the Yacc stack element to be TOKEN */

#define YYSTYPE TOKEN

TOKEN parseresult;

%}

/* Order of tokens corresponds to tokendefs.c; do not change */

%token IDENTIFIER STRING NUMBER   /* token types */

%token PLUS MINUS TIMES DIVIDE    /* Operators */
%token ASSIGN EQ NE LT LE GE GT POINT DOT AND OR NOT DIV MOD IN

%token COMMA                      /* Delimiters */
%token SEMICOLON COLON LPAREN RPAREN LBRACKET RBRACKET DOTDOT

%token ARRAY BEGINBEGIN           /* Lex uses BEGIN */
%token CASE CONST DO DOWNTO ELSE END FILEFILE FOR FUNCTION GOTO IF LABEL NIL
%token OF PACKED PROCEDURE PROGRAM RECORD REPEAT SET THEN TO TYPE UNTIL
%token VAR WHILE WITH


%%

  program   : PROGRAM IDENTIFIER LPAREN id_list RPAREN SEMICOLON lblock DOT { printf("1 program\n"); parseresult = makeprogram($2, $4, $7); }
            ;
  id_list   : IDENTIFIER COMMA id_list                 { printf("1 id_list\n"); $$ = cons($1, $3); }
            | IDENTIFIER                               { printf("2 id_list\n"); $$ = cons($1, NULL); }
            ;
  statement_list : statement SEMICOLON statement_list  { printf("1 statement_list\n"); $$ = cons($1, $3); }
                 |   statement                         { printf("2 statement_list\n"); $$ = $1; }
                 ;
  vargroup  : id_list COLON type                       { printf("1 varspecs\n"); $$ = $3; }
            ;
  varspecs  : vargroup SEMICOLON varspecs              { printf("1 varspecs\n"); $$ = $3; }
            | vargroup SEMICOLON                       { printf("2 varspecs\n"); $$ = $1; }
            ;  
  cdef_list : IDENTIFIER EQ NUMBER SEMICOLON cdef_list { printf("1 cdef_list\n"); instconstant($1, $3); }
            | IDENTIFIER EQ NUMBER SEMICOLON           { printf("2 cdef_list\n"); instconstant($1, $3); }
            ;
  type      : simple_type                              { printf("1 type\n"); $$ = $1; }
            | ARRAY LBRACKET simple_type_list RBRACKET OF type { printf("2 type\n"); $$ = NULL; }
            | RECORD field_list END                    { printf("3 type\n"); $$ = instrec($1, $2); }
            | POINT IDENTIFIER                         { printf("4 type\n"); $$ = NULL; }
            ;
  field_list: id_list COLON type                        { printf("1 field_list\n"); $$ = NULL; }
            | id_list COLON type SEMICOLON field_list   { printf("2 field_list\n"); $$ = nconc($1, $5); }
            | /* empty */                               { printf("3 field_list\n"); $$ = NULL; }
            ;   
  simple_type:IDENTIFIER                                { printf("1 simple_type\n"); $$ = findtype($1); }
            | LPAREN id_list RPAREN                     { printf("2 simple_type\n"); $$ = NULL; }
            | NUMBER DOTDOT NUMBER /*NUMBER|constant?*/ { printf("3 simple_type\n"); $$ = NULL; }
            ;
  simple_type_list : simple_type COMMA simple_type_list  { printf("1 simple_type_list\n"); $$ = cons($3, $1); }
                   | simple_type                         { printf("2 simple_type_list\n"); $$ = $1; }
                   ;
  block     : BEGINBEGIN statement endpart             { printf("1 block\n"); $$ = makeprogn($1, cons($2, $3)); }
            ;
  vblock    : VAR varspecs  block                      { printf("1 vblock\n"); $$ = $3; }
            | block                                    { printf("2 vblock\n"); $$ = $1; }
            ;           
  lblock    : CONST cdef_list vblock                   { printf("1 lblock\n"); $$ = $3;}       
            | vblock                                   { printf("2 lblock\n"); $$ = $1;} 
            ;
  statement : NUMBER COLON statement                   { printf("3 statement\n"); $$ = NULL; }
            | assignment                               { printf("4 statement\n"); $$ = $1; }
            | IDENTIFIER LPAREN args RPAREN            { printf("5 statement\n"); $$ = makefuncall($2, $1, $3); }
            | BEGINBEGIN statement endpart             { printf("6 statement\n"); $$ = makeprogn($1, cons($2, $3)); }
            | IF expr THEN statement endif             { printf("7 statement\n"); $$ = makeif($1, $2, $4, $5); }
            | WHILE expr DO statement                  { printf("8 statement\n"); $$ = makewhile($1, $2, $3, $4); }
            | REPEAT statement_list UNTIL expr         { printf("9 statement\n"); $$ = makerepeat($1, $2, $3, $4); } //just 2??
            | FOR assignment TO expr DO statement      { printf("A statement\n"); $$ = makefor(+1, $1, $2, $3, $4, $5, $6); }    //+?
            | FOR assignment DOWNTO expr DO statement  { printf("B statement\n"); $$ = makefor(-1, $1, $2, $3, $4, $5, $6); }
            | GOTO NUMBER                              { printf("C statement\n"); $$ = dogoto($1, $2); }
            | /* empty */                              { printf("D statement\n"); $$ = NULL; }
            ;
  endpart   : SEMICOLON statement endpart              { printf("1 endpart\n"); $$ = cons($2, $3); }
            | END                                      { printf("1 endpart\n"); $$ = NULL; }
            ;
  endif     : ELSE statement                           { printf("1 endif\n"); $$ = $2; }
            | /* empty */                              { printf("2 endif\n"); $$ = NULL; }
            ;
  assignment: factor ASSIGN expr                       { printf("1 assignment\n"); $$ = binop($2, $1, $3); }
            ;
  expr      : expr TIMES sexpr                         { printf("1 expr\n"); $$ = binop($2, $1, $3); }
            | expr PLUS sexpr                          { printf("2 expr\n"); $$ = binop($2, $1, $3); }
            | expr MINUS sexpr                         { printf("3 expr\n"); $$ = binop($2, $1, $3); }
            | expr EQ sexpr                            { printf("4 expr\n"); $$ = binop($2, $1, $3); }
            | sexpr                                    { printf("5 expr\n"); $$ = $1; }
            ;
  sexpr     : MINUS term                               { printf("1 sexpr\n"); $$ = onenop($1, $2); }
            | term                                     { printf("2 sexpr\n"); $$ = $1; }
            ;
  term      : factor TIMES factor                      { printf("1 term\n"); $$ = binop($2, $1, $3); }
            | factor DIVIDE factor                     { printf("2 term\n"); $$ = binop($2, $1, $3); }
            | factor DIV factor                        { printf("3 term\n"); $$ = binop($2, $1, $3); }
            | factor MOD factor                        { printf("4 term\n"); $$ = binop($2, $1, $3); }
            | factor AND factor                        { printf("5 term\n"); $$ = binop($2, $1, $3); }
            | factor                                   { printf("6 term\n"); $$ = $1; }
            ;
  factor    : LPAREN expr RPAREN                       { printf("1 factor\n"); $$ = $2; }
            | IDENTIFIER LPAREN args RPAREN            { printf("2 factor\n"); $$ = makefuncall($2, $1, $3); }
            | IDENTIFIER                               { printf("3 factor\n"); $$ = findid($1); }   //only thing i could think of, check if it actually works?
            | NUMBER                                   { printf("4 factor\n"); $$ = $1;}
            | STRING                                   { printf("5 factor\n"); $$ = $1;}
            ;
  args      : expr COMMA args                          { printf("1 args\n"); $$ = cons($1, $3); }
            | expr                                     { printf("2 args\n"); $$ = cons($1, NULL);}
            ;

%%

/* You should add your own debugging flags below, and add debugging
   printouts to your programs.

   You will want to change DEBUG to turn off printouts once things
   are working.
  */

#define DEBUG        31             /* set bits here for debugging, 0 = off  */
#define DB_CONS       1             /* bit to trace cons */
#define DB_BINOP      2             /* bit to trace binop */
#define DB_MAKEIF     4             /* bit to trace makeif */
#define DB_MAKEPROGN  8             /* bit to trace makeprogn */
#define DB_PARSERES  16             /* bit to trace parseresult */

 int labelnumber = 0;  /* sequential counter for internal label numbers */

   /*  Note: you should add to the above values and insert debugging
       printouts in your routines similar to those that are shown here.     */

TOKEN cons(TOKEN item, TOKEN list)           /* add item to front of list */
  { item->link = list;
    if (DEBUG & DB_CONS)
       { printf("cons\n");
         dbugprinttok(item);
         dbugprinttok(list);
       };
    return item;
  }
TOKEN nconc(TOKEN lista, TOKEN listb)
{

}

TOKEN binop(TOKEN op, TOKEN lhs, TOKEN rhs)        /* reduce binary operator */
  { op->operands = lhs;          /* link operands to operator       */
    lhs->link = rhs;             /* link second operand to first    */
    rhs->link = NULL;            /* terminate operand list          */
    if (DEBUG & DB_BINOP)
       { printf("binop\n");
         dbugprinttok(op);
         dbugprinttok(lhs);
         dbugprinttok(rhs);
       };
    return op;
  }
TOKEN unaryop(TOKEN op, TOKEN lhs)
{

}
TOKEN makeop(int opnum)
{

}
TOKEN makefloat(TOKEN tok)
{

}
TOKEN makefix(TOKEN tok)
{

}
TOKEN fillintc(TOKEN tok, int num)
{

}
TOKEN makeintc(int num)
{

}
TOKEN copytok(TOKEN origtok)
{

}
TOKEN makeif(TOKEN tok, TOKEN exp, TOKEN thenpart, TOKEN elsepart)
  {  tok->tokentype = OPERATOR;  /* Make it look like an operator   */
     tok->whichval = IFOP;
     if (elsepart != NULL) elsepart->link = NULL;
     thenpart->link = elsepart;
     exp->link = thenpart;
     tok->operands = exp;
     if (DEBUG & DB_MAKEIF)
        { printf("makeif\n");
          dbugprinttok(tok);
          dbugprinttok(exp);
          dbugprinttok(thenpart);
          dbugprinttok(elsepart);
        };
     return tok;
   }

TOKEN makeprogn(TOKEN tok, TOKEN statements)
  {  tok->tokentype = OPERATOR;
     tok->whichval = PROGNOP;
     tok->operands = statements;
     if (DEBUG & DB_MAKEPROGN)
       { printf("makeprogn\n");
         dbugprinttok(tok);
         dbugprinttok(statements);
       };
     return tok;
   }
TOKEN appendst(TOKEN statements, TOKEN more)
{

}
TOKEN dogoto(TOKEN tok, TOKEN labeltok)
{

}
TOKEN makelabel()
{

}
TOKEN dolabel(TOKEN labeltok, TOKEN tok, TOKEN statement)
{

}
void  instlabel (TOKEN num)
{

}
TOKEN makegoto(int label)
{

}
void  settoktype(TOKEN tok, SYMBOL typ, SYMBOL ent)
{

}
TOKEN makefuncall(TOKEN tok, TOKEN fn, TOKEN args)
{

}
TOKEN makeprogram(TOKEN name, TOKEN args, TOKEN statements)
{
  printf("makeprogram() with %s\n", name);
  TOKEN program = talloc();
  TOKEN tmpArgs = talloc();
  program->tokentype = OPERATOR;
  program->whichval = PROGRAMOP;
  program->operands = name;

  tmpArgs = makeprogn(tmpArgs, args);
  name->link = tmpArgs;
  nameToArgs->link = statements;
  return program;
}
TOKEN makewhile(TOKEN tok, TOKEN expr, TOKEN tokb, TOKEN statement)
{

}
TOKEN makerepeat(TOKEN tok, TOKEN statements, TOKEN tokb, TOKEN expr)
{

}
TOKEN makefor(int sign, TOKEN tok, TOKEN asg, TOKEN tokb, TOKEN endexpr,
              TOKEN tokc, TOKEN statement)
{

}
TOKEN findid(TOKEN tok)
{

}
void  instconst(TOKEN idtok, TOKEN consttok)
{

}
TOKEN makesubrange(TOKEN tok, int low, int high)
{

}
TOKEN instenum(TOKEN idlist)
{

}
TOKEN instdotdot(TOKEN lowtok, TOKEN dottok, TOKEN hightok)
{
}
TOKEN findtype(TOKEN tok);

int wordaddress(int n, int wordsize)
  { return ((n + wordsize - 1) / wordsize) * wordsize; }
 
yyerror(s)
  char * s;
  { 
  fputs(s,stderr); putc('\n',stderr);
  }

main()
  { int res;
    initsyms();
    res = yyparse();
    printst();
    printf("yyparse result = %8d\n", res);
    if (DEBUG & DB_PARSERES) dbugprinttok(parseresult);
    ppexpr(parseresult);           /* Pretty-print the result tree */
  }
