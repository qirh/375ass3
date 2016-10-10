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
#include <string.h>

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

%option yylineno

%%

  program   : PROGRAM IDENTIFIER LPAREN id_list RPAREN SEMICOLON vblock DOT { printf("1 program\n"); parseresult = makeprogram($2, $4, $7); }
            ;
  variable  : IDENTIFIER                               { printf("1 variable\n"); }
            ;
  id_list   : variable COMMA id_list                   { printf("1 id_list\n"); $$ = cons($1, $3); }
            | variable                                 { printf("2 id_list\n"); $$ = cons($1, NULL); }
            ;  
  type      : simple_type                              { printf("1 type\n"); }
            | ARRAY LBRACKET simple_type_list RBRACKET OF type { printf("2 type\n"); $$ = NULL; }
            | POINT IDENTIFIER                         { printf("3 type\n"); $$ = NULL; }
            ;  
  simple_type:variable                                 { printf("1 simple_type\n"); $$ = findtype($1); }
            | LPAREN id_list RPAREN                    { printf("2 simple_type\n"); $$ = NULL; }
            | NUMBER DOTDOT NUMBER /*NUMBER|constant?*/{ printf("3 simple_type\n"); $$ = NULL; }
            ;
  simple_type_list : simple_type COMMA simple_type_list{ printf("1 simple_type_list\n"); $$ = cons($3, $1); }
                   | simple_type                       { printf("2 simple_type_list\n"); }
                   ;
  block     : BEGINBEGIN statement endpart             { printf("1 block\n"); $$ = makeprogn($1, cons($2, $3)); printf("1 block2\n"); }
            ;
  vblock    : VAR vdef_list block                      { printf("1 vblock\n"); $$ = $3; }
            | block                                    { printf("2 vblock\n"); }
            ; 
  vdef_list : vdef SEMICOLON                           { printf("1 vdef_list\n"); }
            ;
  vdef      : id_list COLON type                       { printf("1 vdef\n"); instvars($1, $3); }
            ;
  statement : NUMBER COLON statement                   { printf("3 statement\n"); $$ = NULL; }
            | assignment                               { printf("4 statement\n"); $$ = $1; printf("4 statement2\n"); }
            | variable LPAREN args RPAREN              { printf("5 statement\n"); $$ = makefuncall($2, findid($1), $3); }
            | BEGINBEGIN statement endpart             { printf("6 statement\n"); $$ = makeprogn($1, cons($2, $3)); }
            | IF expr THEN statement endif             { printf("7 statement\n"); $$ = makeif($1, $2, $4, $5); }
            | FOR assignment TO expr DO statement      { printf("8 statement\n"); $$ = makefor(+1, $1, $2, $3, findid($4), $5, $6); }    //+?
            | FOR assignment DOWNTO expr DO statement  { printf("9 statement\n"); $$ = makefor(-1, $1, $2, $3, findid($4), $5, $6); }
            | /* empty */                              { printf("A statement\n"); $$ = NULL; }
            ;
  endpart   : SEMICOLON statement endpart              { printf("1 endpart\n"); $$ = cons($2, $3); }
            | END                                      { printf("2 endpart\n"); $$ = NULL; }
            ;
  endif     : ELSE statement                           { printf("1 endif\n"); $$ = $2; }
            | /* empty */                              { printf("2 endif\n"); $$ = NULL; }
            ;
  assignment: variable ASSIGN expr                     { printf("1 assignment\n"); $$ = binop($2, findid($1), $3); }
            ;
  expr      : expr TIMES sexpr                         { printf("1 expr\n"); $$ = binop($2, $1, $3); }
            | expr PLUS sexpr                          { printf("2 expr\n"); $$ = binop($2, $1, $3); }
            | expr MINUS sexpr                         { printf("3 expr\n"); $$ = binop($2, $1, $3); }
            | expr EQ sexpr                            { printf("4 expr\n"); $$ = binop($2, $1, $3); }
            | sexpr                                    { printf("5 expr\n");  }
            ;
  sexpr     : MINUS term                               { printf("1 sexpr\n"); $$ = unaryop($1, $2); }
            | term                                     { printf("2 sexpr\n"); }
            ;
  term      : factor TIMES factor                      { printf("1 term\n"); $$ = binop($2, $1, $3); }
            | factor DIVIDE factor                     { printf("2 term\n"); $$ = binop($2, $1, $3); }
            | factor DIV factor                        { printf("3 term\n"); $$ = binop($2, $1, $3); }
            | factor MOD factor                        { printf("4 term\n"); $$ = binop($2, $1, $3); }
            | factor AND factor                        { printf("5 term\n"); $$ = binop($2, $1, $3); }
            | factor                                   { printf("6 term\n"); }
            ;
  factor    : LPAREN expr RPAREN                       { printf("1 factor\n"); $$ = $2; }
            | variable LPAREN args RPAREN              { printf("2 factor\n"); $$ = makefuncall($2, $1, $3); }
            | variable                                 { printf("3 factor\n"); }
            | NUMBER                                   { printf("4 factor\n"); }
            | STRING                                   { printf("5 factor\n"); }
            ;
  args      : expr COMMA args                          { printf("1 args\n"); $$ = cons($1, $3); }
            | expr                                     { printf("2 args\n"); $$ = cons($1, NULL);}
            ;
  compare_op: EQ                                       { printf("1 compare_op\n"); }
            | LT                                       { printf("2 compare_op\n"); }
            | GT                                       { printf("3 compare_op\n"); }
            | NE                                       { printf("4 compare_op\n"); }
            | LE                                       { printf("5 compare_op\n"); }
            | GE                                       { printf("6 compare_op\n"); }
            | IN                                       { printf("7 compare_op\n"); }
            ;

%%

/* You should add your own debugging flags below, and add debugging
   printouts to your programs.

   You will want to change DEBUG to turn off printouts once things
   are working.
  */

#define DEBUG         1             /* set bits here for debugging, 0 = off  */
#define DB_CONS       1             /* bit to trace cons */
#define DB_BINOP      2             /* bit to trace binop */
#define DB_MAKEIF     4             /* bit to trace makeif */
#define DB_MAKEPROGN  8             /* bit to trace makeprogn */
#define DB_PARSERES  16             /* bit to trace parseresult */

 int labelnumber = 0;  /* sequential counter for internal label numbers */

   /*  Note: you should add to the above values and insert debugging
       printouts in your routines similar to those that are shown here.     */

TOKEN cons(TOKEN item, TOKEN list) {
  printf("cons()\n");
  item->link = list;
  if (DEBUG & DB_CONS) {
    printf("cons\n");
    dbugprinttok(item);
    dbugprinttok(list);
  };
  printf("cons() ends\n");
  return item;
}
TOKEN unaryop(TOKEN op, TOKEN lhs) {
  printf("unaryop()\n");
  op->operands = lhs;
  lhs->link = NULL;
  printf("unaryop() ends\n");
  return op;
}
TOKEN findid(TOKEN tok) {
  /*
  printf("findid()\n");
  SYMBOL sym, typ;
  sym = searchins(tok-> stringval);
  printf("findid() 2\n");
  tok->symentry = sym;
  printf("findid() 3\n");
  debugprinttok(tok);
  dbprsymbol(sym);
  typ = sym->datatype;
  printf("findid() 4\n");
  tok->symtype = typ;
  printf("findid() 5\n");
  if (typ->kind == BASICTYPE || typ->kind == POINTERSYM){
    printf("findid() 6\n");
    tok->datatype = typ->basicdt;
  }
  printf("findid() 7\n");
  printf("findid() ends\n");
  return tok;
  */
  SYMBOL sym, typ;

sym = searchst(tok->stringval);
tok->symentry = sym;
typ = sym->datatype;
tok->symtype = typ;
if ( typ->kind == BASICTYPE ||
     typ->kind == POINTERSYM)
    tok->datatype = typ->basicdt;
return tok;
}
void instvars(TOKEN id_list, TOKEN typetok) {
  printf("instvars()\n");
  SYMBOL sym, typesym;
  int align;
  typesym = typetok->symtype;
  align = alignsize(typesym);
  while (id_list != NULL) {
    sym = insertsym(id_list->stringval);
    sym->kind = VARSYM;
    sym->offset = wordaddress(blockoffs[blocknumber], align);
    sym->size = typesym->size;
    blockoffs[blocknumber] = sym->offset + sym->size;
    sym->datatype = typesym;
    sym->basicdt = typesym->basicdt;
    id_list = id_list->link;
  }
  printf("instvars() ends\n");
}
TOKEN binop(TOKEN op, TOKEN lhs, TOKEN rhs) { 
  printf("binop()\n");
  op->operands = lhs;          /* link operands to operator       */
  lhs->link = rhs;             /* link second operand to first    */
  rhs->link = NULL;            /* terminate operand list          */
  if (DEBUG & DB_BINOP) { 
    printf("binop\n");
    dbugprinttok(op);
    dbugprinttok(lhs);
    dbugprinttok(rhs);
  };
  printf("binop() ends\n");
  return op;
}
TOKEN makeif(TOKEN tok, TOKEN exp, TOKEN thenpart, TOKEN elsepart) {
  printf("makeif()\n");
  tok->tokentype = OPERATOR; /* Make it look like an operator   */
  tok->whichval = IFOP;
  if (elsepart != NULL) elsepart->link = NULL;
  thenpart->link = elsepart;
  exp->link = thenpart;
  tok->operands = exp;
  if (DEBUG & DB_MAKEIF) {
    printf("makeif\n");
    dbugprinttok(tok);
    dbugprinttok(exp);
    dbugprinttok(thenpart);
    dbugprinttok(elsepart);
  };
  printf("makeif() ends\n");
  return tok;
}
TOKEN makeprogn(TOKEN tok, TOKEN statements) {
  printf("makeprogn()\n");
  tok->tokentype = OPERATOR;
  tok->whichval = PROGNOP;
  tok->operands = statements;
  if (DEBUG & DB_MAKEPROGN) {
    printf("makeprogn\n");
    dbugprinttok(tok);
    dbugprinttok(statements);
  };
  printf("makeprogn() ends\n");
  return tok;
}
TOKEN makelabel() {
  printf("makelabel()\n");
  TOKEN l = talloc();
  l->tokentype = OPERATOR;
  l->whichval = LABELOP;
  l->operands = makeintc(labelnumber);
  labelnumber += 1;
  printf("makelabel() ends\n");
  return l;
}
TOKEN makegoto(int label) {
  printf("makegoto()\n");
  TOKEN gotoTok = talloc();
  gotoTok->tokentype = OPERATOR;
  gotoTok->whichval = GOTOOP;
  gotoTok->operands = makeintc(labelnumber - 1);
  printf("makegoto() ends\n");
  return gotoTok;
}
TOKEN makefuncall(TOKEN tok, TOKEN fn, TOKEN args) {
  printf("makefuncall() with args\n");
  ppexpr(args);
  tok->tokentype = OPERATOR;
  tok->whichval = FUNCALLOP;

  fn->link = args;
  tok->operands = fn;

  printf("makefuncall() ends\n");
  return tok;
}
TOKEN makeintc(int num) {
  printf("makeintc()\n");
  TOKEN intMade = talloc();
  intMade->tokentype = NUMBERTOK;
  intMade->datatype = INTEGER;
  intMade->intval = num;
  printf("makeintc() ends\n");
  return intMade;
}
TOKEN makeprogram(TOKEN name, TOKEN args, TOKEN statements) {
  printf("makeprogram() with %s\n", name);
  ppexpr(args);
  TOKEN program = talloc();
  TOKEN tmpArgs = talloc();
  program->tokentype = OPERATOR;
  program->whichval = PROGRAMOP;
  program->operands = name;

  tmpArgs = makeprogn(tmpArgs, args);
  name->link = tmpArgs;
  tmpArgs->link = statements;
  printf("makeprogram() ends\n");
  return program;
}
TOKEN makefor(int sign, TOKEN tok, TOKEN asg, TOKEN tokb, TOKEN endexpr,
  TOKEN tokc, TOKEN statement) {
  printf("makefor() with statement\n");
  ppexpr(statement);
  
  tok->tokentype = OPERATOR;
  tok->whichval = PROGNOP;
  tok->operands = asg;
  tokb->tokentype = OPERATOR;
  tokb->whichval = LABELOP;
  
  asg->link = tokb;

  TOKEN tokd = talloc();
  tokd->tokentype = NUMBERTOK;
  tokd->datatype = INTEGER;
  int lbl = labelnumber;
  labelnumber += 1;
  tokd->intval = lbl; // 0 in the diagram
  
  tokb->operands = tokd;

  tokc->tokentype = OPERATOR;
  tokc->whichval = IFOP;

  tokb->link = tokc;

  TOKEN tokr = talloc();
  tokr->tokentype = OPERATOR;
  tokr->whichval = LEOP;
  
  tokc->operands = tokr;
  TOKEN tokf = talloc();
  tokf->tokentype = asg->operands->tokentype;
  printf("the value for asg operands token type is: %s \n", asg->operands->stringval);
  strcpy(tokf->stringval, asg->operands->stringval);
  tokf->link = endexpr;

  tokd->operands = tokf;

  TOKEN toke = talloc();
  toke->tokentype = OPERATOR;
  toke->whichval = PROGNOP;

  tokd->link = toke;

  toke->operands = statement;

  TOKEN tokg = talloc();
  tokg->tokentype = OPERATOR;
  tokg->whichval = ASSIGNOP;
  statement->link = tokg;

  TOKEN tokh = talloc();
  tokh->tokentype = asg->operands->tokentype;

  strcpy(tokh->stringval, asg->operands->stringval);
  tokg->operands = tokh;

  TOKEN toki = talloc();
  toki->tokentype = OPERATOR;
  toki->whichval = PLUSOP;
  tokh->link = toki;

  TOKEN tokj = talloc();
  tokj->tokentype = asg->operands->tokentype;
  strcpy(tokj->stringval, asg->operands->stringval);
  toki->operands = tokj;

  TOKEN tokl = talloc();
  tokl->tokentype = NUMBERTOK;
  tokl->datatype = INTEGER;
  tokl->intval = 1;
  tokj->link = tokl;

  TOKEN tokq = talloc();
  tokq->tokentype = OPERATOR;
  tokq->whichval = GOTOOP;
  tokg->link = tokq;

  TOKEN tokm = talloc();
  tokm->tokentype = NUMBERTOK;
  tokm->datatype = INTEGER;
  tokm->intval = lbl;

  tokq->operands = tokm;

  printf("makefor() ends with tokens\n");
  ppexpr(tok);
  return tok;
}
TOKEN findtype(TOKEN tok) {
  printf("findtype()\n");

  SYMBOL sym, typ;
  sym = searchst(tok->stringval);

  if (sym->kind == BASICTYPE)
  {
    tok->symtype = sym;
    tok->datatype = sym->basicdt;
  } 
  else if (sym->kind == TYPESYM) {
    tok->symtype = sym->datatype;
  } 
  else
  {
    printf("bad type\n");
  }
  printf("findtype() ends\n");
  return tok;
}
int wordaddress(int n, int wordsize) {
  return ((n + wordsize - 1) / wordsize) * wordsize;
}

yyerror(s) char * s; {
  fprintf(stderr,"At line %d %s ",s,yylineno);

  fputs(s, stderr);
  putc('\n', stderr);

}

main() {
  int res;
  initsyms();
  res = yyparse();
  printst();
  printf("yyparse result = %8d\n", res);
  if (DEBUG & DB_PARSERES) 
    dbugprinttok(parseresult);
  ppexpr(parseresult); /* Pretty-print the result tree */
}





















