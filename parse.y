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


%%

  program   : PROGRAM IDENTIFIER LPAREN id_list RPAREN SEMICOLON vblock DOT /* { printf("1 program\n"); */ { parseresult = makeprogram($2, $4, $7); }
            ;
  variable  : IDENTIFIER                               /* { printf("1 variable\n"); */ { }
            ;
  id_list   : IDENTIFIER COMMA id_list                 /* { printf("1 id_list\n"); */ { $$ = cons($1, $3); }
            | IDENTIFIER                               /* { printf("2 id_list\n"); */ { $$ = cons($1, NULL); }
            ;  
  type      : simple_type                              /* { printf("1 type\n"); */ { }
            | ARRAY LBRACKET simple_type_list RBRACKET OF type /* { printf("2 type\n"); */ { $$ = NULL; }
            | POINT IDENTIFIER                         /* { printf("3 type\n"); */ { $$ = NULL; }
            ;  
  simple_type: IDENTIFIER                              /* { printf("1 simple_type\n"); */ { $$ = findtype($1); }
            | LPAREN id_list RPAREN                    /* { printf("2 simple_type\n"); */ { $$ = NULL; }
            | NUMBER DOTDOT NUMBER /*NUMBER|constant?*//* { printf("3 simple_type\n"); */ { $$ = NULL; }
            ;
  simple_type_list : simple_type COMMA simple_type_list/* { printf("1 simple_type_list\n"); */ { $$ = cons($3, $1); }
                   | simple_type                       /* { printf("2 simple_type_list\n"); */ { }
                   ;
  block     : BEGINBEGIN statement endpart             /* { printf("1 block\n"); */ { $$ = makeprogn($1, cons($2, $3));  }
            ;
  vblock    : VAR vdef_list block                      /* { printf("1 vblock\n"); */ { $$ = $3; }
            | block                                    /* { printf("2 vblock\n"); */ { }
            ; 
  vdef_list : vdef SEMICOLON                           /* { printf("1 vdef_list\n"); */ { }
            ;
  vdef      : id_list COLON type                       /* { printf("1 vdef\n"); */ { instvars($1, $3); }
            ;
  funcall   : IDENTIFIER LPAREN expr_list RPAREN       /* { printf("1 funcall\n"); */ { cons($1, $3); }
            ;
  statement : NUMBER COLON statement                   /* { printf("1 statement\n"); */ { $$ = NULL; }
            | assignment                               /* { printf("2 statement\n"); */ { $$ = $1; }
            | IDENTIFIER LPAREN args RPAREN            /* { printf("3 statement\n"); */ { $$ = makefuncall($2, findid($1), $3); }
            | BEGINBEGIN statement endpart             /* { printf("4 statement\n"); */ { $$ = makeprogn($1, cons($2, $3)); }
            | IF expr THEN statement endif             /* { printf("5 statement\n"); */ { $$ = makeif($1, $2, $4, $5); }
            | FOR assignment TO expr DO statement      /* { printf("6 statement\n"); */ { $$ = makefor(1, $1, $2, $3, $4, $5, $6); }
            | funcall                                  /* { printf("7 statement\n"); */ { }
            ;
  endpart   : SEMICOLON statement endpart              /* { printf("1 endpart\n"); */ { $$ = cons($2, $3); }
            | END                                      /* { printf("2 endpart\n"); */ { $$ = NULL; }
            ;
  endif     : ELSE statement                           /* { printf("1 endif\n"); */ { $$ = $2; }
            | /* empty */                              /* { printf("2 endif\n"); */ { $$ = NULL; }
            ;
  assignment: variable ASSIGN expr                     /* { printf("1 assignment\n"); */ { $$ = binop($2, $1, $3); }
            ;
  expr      : expr alg_op term                         /* { printf("1 expr\n"); */ { $$ = binop($2, $1, $3); }
            | expr alg_op sexpr                        /* { printf("2 expr\n"); */ { $$ = binop($2, $1, $3); }
            | sexpr                                    /* { printf("3 expr\n"); */ { }
            | term                                     /* { printf("4 expr\n"); */ { }
            ;
  sexpr     : sexpr alg_op term                        /* { printf("1 sexpr\n"); */ { $$ = unaryop($1, $2); }
            | term                                     /* { printf("2 sexpr\n"); */ { }
            | STRING                                   /* { printf("3 sexpr\n"); */ { }
            ;
  expr_list : expr COMMA expr_list                     /* { printf("1 expr_list\n"); */ { $$ = cons($1, $3); }
            | expr                                     /* { printf("2 expr_list\n"); */ { }
            ;
  term      : term TIMES factor                        /* { printf("1 term\n"); */ { $$ = binop($2, $1, $3); }
            | factor                                   /* { printf("2 term\n"); */ { }
            ;
  factor    : LPAREN expr RPAREN                       /* { printf("1 factor\n"); */ { $$ = $2; }
            | variable                                 /* { printf("2 factor\n"); */ { }
            | NUMBER                                   /* { printf("3 factor\n"); */ { }
            
            ;
  args      : expr COMMA args                          /* { printf("1 args\n"); */ { $$ = cons($1, $3); }
            | expr                                     /* { printf("2 args\n"); */ { $$ = cons($1, NULL);}
            ;
  compare_op: EQ                                       /* { printf("1 compare_op\n"); */ { }
            | LT                                       /* { printf("2 compare_op\n"); */ { }
            | GT                                       /* { printf("3 compare_op\n"); */ { }
            | NE                                       /* { printf("4 compare_op\n"); */ { }
            | LE                                       /* { printf("5 compare_op\n"); */ { }
            | GE                                       /* { printf("6 compare_op\n"); */ { }
            | IN                                       /* { printf("7 compare_op\n"); */ { }
            ;
  alg_op    : PLUS                                     /* { printf("1 plus_op\n"); */ { }
            | MINUS                                    /* { printf("2 plus_op\n"); */ { }
            | OR                                       /* { printf("3 plus_op\n"); */ { }
            | TIMES                                    /* { printf("4 plus_op\n"); */ { }
            | DIVIDE                                   /* { printf("5 plus_op\n"); */ { }
            ;
%%

/* You should add your own debugging flags below, and add debugging
   printouts to your programs.

   You will want to change DEBUG to turn off printouts once things
   are working.
  */

#define DEBUG        0

 int labelnumber = 0;  /* sequential counter for internal label numbers */

   /*  Note: you should add to the above values and insert debugging
       printouts in your routines similar to those that are shown here.     */

TOKEN cons(TOKEN item, TOKEN list) {
  //printf("cons()\n");
  item->link = list;
  if (DEBUG) {
    printf("cons\n");
    dbugprinttok(item);
    dbugprinttok(list);
  };
  //printf("cons() ends\n");
  return item;
}
TOKEN unaryop(TOKEN op, TOKEN lhs) {
  //printf("unaryop()\n");
  op->operands = lhs;
  lhs->link = NULL;
  //printf("unaryop() ends\n");
  return op;
}
TOKEN binop(TOKEN op, TOKEN lhs, TOKEN rhs) { 
  //printf("binop()\n");
  op->operands = lhs;          /* link operands to operator       */
  lhs->link = rhs;             /* link second operand to first    */
  rhs->link = NULL;            /* terminate operand list          */
  if (DEBUG) { 
    printf("binop\n");
    dbugprinttok(op);
    dbugprinttok(lhs);
    dbugprinttok(rhs);
  };
  //printf("binop() ends\n");
  return op;
}
TOKEN findid(TOKEN tok) {
  //printf("findid()\n");
  SYMBOL sym, typ;
  sym = searchst(tok->stringval);
  tok->symentry = sym;
  typ = sym->datatype;
  tok->symtype = typ;
  if ( typ->kind == BASICTYPE || typ->kind == POINTERSYM)
      tok->datatype = typ->basicdt;
  //printf("findid() ends\n");
  return tok;
}
void instvars(TOKEN id_list, TOKEN typetok) {
  //printf("instvars()\n");
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
  //printf("instvars() ends\n");
}
TOKEN makeif(TOKEN tok, TOKEN exp, TOKEN thenpart, TOKEN elsepart) {
  //printf("makeif()\n");
  tok->tokentype = OPERATOR; /* Make it look like an operator   */
  tok->whichval = IFOP;
  if (elsepart != NULL) elsepart->link = NULL;
  thenpart->link = elsepart;
  exp->link = thenpart;
  tok->operands = exp;
  if (DEBUG) {
    printf("makeif\n");
    dbugprinttok(tok);
    dbugprinttok(exp);
    dbugprinttok(thenpart);
    dbugprinttok(elsepart);
  };
  //printf("makeif() ends\n");
  return tok;
}
TOKEN makeprogn(TOKEN tok, TOKEN statements) {
  //printf("makeprogn()\n");
  tok->tokentype = OPERATOR;
  tok->whichval = PROGNOP;
  tok->operands = statements;
  if (DEBUG) {
    printf("makeprogn\n");
    dbugprinttok(tok);
    dbugprinttok(statements);
  };
  //printf("makeprogn() ends\n");
  return tok;
}
TOKEN makelabel() {
  //printf("makelabel()\n");
  TOKEN l = talloc();
  l->tokentype = OPERATOR;
  l->whichval = LABELOP;
  l->operands = makeintc(labelnumber);
  labelnumber += 1;
  //printf("makelabel() ends\n");
  return l;
}
TOKEN makegoto(int label) {
  //printf("makegoto()\n");
  TOKEN gotoTok = talloc();
  gotoTok->tokentype = OPERATOR;
  gotoTok->whichval = GOTOOP;
  gotoTok->operands = makeintc(labelnumber - 1);
  //printf("makegoto() ends\n");
  return gotoTok;
}
TOKEN makefuncall(TOKEN tok, TOKEN fn, TOKEN args) {
  //printf("makefuncall() with args\n");
  ppexpr(args);
  tok->tokentype = OPERATOR;
  tok->whichval = FUNCALLOP;

  fn->link = args;
  tok->operands = fn;

  //printf("makefuncall() ends\n");
  return tok;
}
TOKEN makeintc(int num) {
  //printf("makeintc()\n");
  TOKEN intMade = talloc();
  intMade->tokentype = NUMBERTOK;
  intMade->datatype = INTEGER;
  intMade->intval = num;
  //printf("makeintc() ends\n");
  return intMade;
}
TOKEN makeprogram(TOKEN name, TOKEN args, TOKEN statements) {
  //printf("makeprogram() with args:\n\t");
  ppexpr(args);
  TOKEN program = talloc();
  TOKEN tmpArgs = talloc();
  program->tokentype = OPERATOR;
  program->whichval = PROGRAMOP;
  program->operands = name;
  
  tmpArgs = makeprogn(tmpArgs, args);
  name->link = tmpArgs;
  tmpArgs->link = statements;
  
  //printf("makeprogram() ends\n");

  return program;
}
TOKEN makefor(int sign, TOKEN tok, TOKEN asg, TOKEN tokb, TOKEN endexpr,
  TOKEN tokc, TOKEN statement) {

  //printf("makefor()\n\t");

  tok->tokentype = OPERATOR;
  tok->whichval = PROGNOP;
  tok->operands = asg;

  tokb->tokentype = OPERATOR;
  tokb->whichval = LABELOP;
  asg->link=tokb;
  
  TOKEN tok1 = talloc();
  tok1->tokentype = NUMBERTOK;
  tok1->datatype = INTEGER;
  int lbl = labelnumber++;
  tok1->intval = lbl; 
  tokb->operands = tok1;
  
  tokc->tokentype = OPERATOR;
  tokc->whichval = IFOP;
  tokb->link = tokc;
  
  TOKEN tok2 = talloc();
  tok2->tokentype = OPERATOR;
  tok2->whichval = LEOP;
  tokc->operands = tok2;

  TOKEN tok3 = talloc();
  tok3->tokentype = asg->operands->tokentype;
  strcpy (tok3->stringval,asg->operands->stringval);
  tok3->link = endexpr;
  
  tok2->operands = tok3;
  
  TOKEN tok4 = talloc();
  tok4->tokentype = OPERATOR;
  tok4->whichval = PROGNOP;
  tok2->link = tok4;
  
  tok4->operands = statement;

  TOKEN tok5 = talloc();
  tok5->tokentype = OPERATOR;
  tok5->whichval = ASSIGNOP;
  statement->link = tok5;

  TOKEN tok6 = talloc();
  tok6->tokentype = asg->operands->tokentype;
  
  strcpy (tok6->stringval,asg->operands->stringval);
  tok5->operands = tok6;
  
  TOKEN tok7 = talloc();
  tok7->tokentype = OPERATOR;
  tok7->whichval = PLUSOP;
  tok6->link = tok7;

  TOKEN tok8 = talloc();
  tok8->tokentype = asg->operands->tokentype;
  strcpy (tok8->stringval,asg->operands->stringval);
  tok7->operands = tok8;

  TOKEN tok9 = talloc();
  tok9->tokentype = NUMBERTOK;
  tok9->datatype = INTEGER;
  tok9->intval = 1;
  tok8->link = tok9;

  TOKEN tokA = talloc();
  tokA->tokentype = OPERATOR;
  tokA->whichval = GOTOOP;
  tok5->link = tokA;

  TOKEN tokB = talloc();
  tokB->tokentype = NUMBERTOK;
  tokB->datatype = INTEGER;
  tokB->intval = lbl;
  
  tokA->operands = tokB;
  
  if (DEBUG){ 
    printf("makefor\n");
    dbugprinttok(tok);
    dbugprinttok(asg);
    dbugprinttok(tokb);
    dbugprinttok(endexpr);
    dbugprinttok(tokc);
    dbugprinttok(statement);
  };
  ppexpr(tok); 
  //printf("makefor() ends\n");
  return tok;

}
TOKEN findtype(TOKEN tok) {
  //printf("findtype()\n");
  tok -> symtype = searchst(tok -> tokenval.tokenstring);
  //printf("findtype() ends\n");
  return tok;
}
int wordaddress(int n, int wordsize) {
  return ((n + wordsize - 1) / wordsize) * wordsize;
}
yyerror(s) char * s; {
  extern int yylineno;  // defined and maintained in lex
  extern char *yytext;  // defined and maintained in lex
  fprintf(stderr, "ERROR: %s at symbol '%s' on line %d\n", s, yytext, yylineno);
  fputs(s, stderr);
  putc('\n', stderr);
}
main() {
  int res;
  initsyms();
  res = yyparse();
  printst();
  printf("yyparse result = %8d\n", res);
  if (DEBUG) 
    dbugprinttok(parseresult);
  ppexpr(parseresult); /* Pretty-print the result tree */
}