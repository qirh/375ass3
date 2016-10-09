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

  program   : PROGRAM IDENTIFIER LPAREN id_list RPAREN SEMICOLON lblock DOT { printf("1 program\n"); parseresult = makeprogram($2, $4, $7); }
            ;
  id_list   : IDENTIFIER COMMA id_list                 { printf("1 id_list\n"); $$ = cons($1, $3); }
            | IDENTIFIER                               { printf("2 id_list\n"); $$ = cons($1, NULL); }
            ;
  vargroup  : id_list COLON type                       { printf("1 vargroup\n"); instvars($1, $3); }
            ;  
  cdef_list : IDENTIFIER EQ NUMBER SEMICOLON cdef_list { printf("1 cdef_list\n"); $$ = $3; }
            | IDENTIFIER EQ NUMBER SEMICOLON           { printf("2 cdef_list\n"); $$ = $1; }
            ;
  type      : simple_type                              { printf("1 type\n"); $$ = $1; }
            | ARRAY LBRACKET simple_type_list RBRACKET OF type { printf("2 type\n"); $$ = NULL; }
            //| RECORD field_list END                    { printf("3 type\n"); $$ = instrec($1, $2); }
            | POINT IDENTIFIER                         { printf("4 type\n"); $$ = NULL; }
            ;  
  simple_type:IDENTIFIER                               { printf("1 simple_type\n"); $$ = findtype($1); }
            | LPAREN id_list RPAREN                    { printf("2 simple_type\n"); $$ = NULL; }
            | NUMBER DOTDOT NUMBER /*NUMBER|constant?*/{ printf("3 simple_type\n"); $$ = NULL; }
            ;
  simple_type_list : simple_type COMMA simple_type_list{ printf("1 simple_type_list\n"); $$ = cons($3, $1); }
                   | simple_type                       { printf("2 simple_type_list\n"); $$ = $1; }
                   ;
  block     : BEGINBEGIN statement endpart             { printf("1 block\n"); $$ = makeprogn($1, cons($2, $3)); }
            ;
  vblock    : VAR varspecs  block                      { printf("1 vblock\n"); $$ = $3; }
            | block                                    { printf("2 vblock\n"); $$ = $1; }
            ; 
  varspecs :  vargroup SEMICOLON varspecs              { printf("1 varspecs\n"); }
           |  vargroup SEMICOLON                       { printf("2 varspecs\n"); }
           ;
  vargroup :  id_list COLON type
                            { instvars($1, $3); }
  lblock    : CONST cdef_list vblock                   { printf("1 lblock\n"); $$ = $3;}       
            | vblock                                   { printf("2 lblock\n"); $$ = $1;} 
            ;
  statement : NUMBER COLON statement                   { printf("3 statement\n"); $$ = NULL; }
            | assignment                               { printf("4 statement\n"); $$ = $1; }
            | IDENTIFIER LPAREN args RPAREN            { printf("5 statement\n"); $$ = makefuncall($2, $1, $3); }
            | BEGINBEGIN statement endpart             { printf("6 statement\n"); $$ = makeprogn($1, cons($2, $3)); }
            | IF expr THEN statement endif             { printf("7 statement\n"); $$ = makeif($1, $2, $4, $5); }
            | FOR assignment TO expr DO statement      { printf("8 statement\n"); $$ = makefor(+1, $1, $2, $3, $4, $5, $6); }    //+?
            | FOR assignment DOWNTO expr DO statement  { printf("9 statement\n"); $$ = makefor(-1, $1, $2, $3, $4, $5, $6); }
            | /* empty */                              { printf("A statement\n"); $$ = NULL; }
            ;
  endpart   : SEMICOLON statement endpart              { printf("1 endpart\n"); $$ = cons($2, $3); }
            | END                                      { printf("2 endpart\n"); $$ = NULL; }
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
  sexpr     : MINUS term                               { printf("1 sexpr\n"); $$ = unaryop($1, $2); }
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

#define DEBUG         1             /* set bits here for debugging, 0 = off  */
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
TOKEN unaryop(TOKEN op, TOKEN lhs) {
    op->operands = lhs;          /* link operands to operator       */
    lhs->link = NULL;
    return op;
}
TOKEN findid(TOKEN tok) { /* the ID token */
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
void instvars(TOKEN idlist, TOKEN typetok)
  {  SYMBOL sym, typesym; int align;
     typesym = typetok->symtype;
     align = alignsize(typesym);
     while ( idlist != NULL )   /* for each id */
       {  sym = insertsym(idlist->stringval);
          sym->kind = VARSYM;
          sym->offset =
              wordaddress(blockoffs[blocknumber],
                          align);
          sym->size = typesym->size;
          blockoffs[blocknumber] =
                         sym->offset + sym->size;
          sym->datatype = typesym;
          sym->basicdt = typesym->basicdt;
          idlist = idlist->link;
        }
  }
TOKEN binop(TOKEN op, TOKEN lhs, TOKEN rhs) 
  { op->operands = lhs;        
    lhs->link = rhs;           
    rhs->link = NULL; 
    return op;
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
TOKEN makelabel() {
  TOKEN newLabel = talloc();
  newLabel->tokentype = OPERATOR;
  newLabel->whichval = LABELOP;
  newLabel->operands = makeintc(labelnumber);
  labelnumber += 1;
  return newLabel;
}
TOKEN makegoto(int label)
{
  TOKEN gotoTok = talloc();
  gotoTok->tokentype = OPERATOR;
  gotoTok->whichval = GOTOOP;
  gotoTok->operands = makeintc(labelnumber - 1);
  return gotoTok;
}
TOKEN makefuncall(TOKEN tok, TOKEN fn, TOKEN args)
{
  printf("You called the makefuncall action \n");
  printf("This is what args looks like: \n");
  ppexpr(args);
  tok->tokentype = OPERATOR;
  tok->whichval = FUNCALLOP;
    
  //link fn to args
  fn->link = args;
  //link tok to fn
  tok->operands = fn;

  printf("You finished calling the makefuncall action \n");
  return tok;
}
TOKEN makeintc(int num) {
  TOKEN intMade = talloc();
  intMade->tokentype = NUMBERTOK;
  intMade->datatype = INTEGER;
  intMade->intval = num;
  return intMade;
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
  tmpArgs->link = statements;
  return program;
}
TOKEN makefor(int sign, TOKEN tok, TOKEN asg, TOKEN tokb, TOKEN endexpr,
              TOKEN tokc, TOKEN statement)
{
  printf("You called the makefor function \n");
    //what am i suppose to in this function
    //create progn operator token
    
    printf("This is what statement looks like: \n");
    ppexpr(statement);
    //Set up progn
    tok->tokentype = OPERATOR;
    tok->whichval = PROGNOP;
    printf("setted up tok \n");
    //progn link to asg
    tok->operands = asg;
    printf("tok operanded \n");
    
    //setup tokb to be label
    tokb->tokentype = OPERATOR;
    tokb->whichval = LABELOP;
    printf("setted up tokb \n");
    
    //link asg to label
    asg->link=tokb;
    
    
    //create integer token
    TOKEN tokz = talloc();
    tokz->tokentype = NUMBERTOK;
    tokz->datatype = INTEGER;
    int lbl = labelnumber++;
    tokz->intval = lbl; // 0 in the diagram
    printf("setted up tokz \n");
    
    //link tokb to tokz (integer token)
    tokb->operands = tokz;
    
    //create ifop token
    tokc->tokentype = OPERATOR;
    tokc->whichval = IFOP;
    printf("setted up tokc \n");
    
    //link tokb to tokc (label to if)
    tokb->link = tokc;
    
    //create <= tok
    TOKEN tokd = talloc();
    tokd->tokentype = OPERATOR;
    tokd->whichval = LEOP;
    printf("setted up tokd \n");
    
    //link ifop (tokc) to <= tok 
    tokc->operands = tokd;
    
    //tokd->link =
    //tokd->operands =
    
    //create 'i' token - which is copying token i from asg tok
    TOKEN tokf = talloc();
    tokf->tokentype = asg->operands->tokentype;
    printf("the value for asg operands token type is: %s \n",asg->operands->stringval);
    strcpy (tokf->stringval,asg->operands->stringval);
    //tokf->stringval = asg->operands->stringval;
    //connect tokf to endexpr
    tokf->link = endexpr;
    
    //connect <= operator to i
    tokd->operands = tokf;
    
    //Set up progn
    TOKEN toke = talloc();
    toke->tokentype = OPERATOR;
    toke->whichval = PROGNOP;
    printf("setted up toke \n");
    
    //link tokd with progn (less than equal to, to , progn)
    tokd->link = toke;
    
    //progn link to statement
    toke->operands = statement;
    printf("tok operanded \n");
    
    //statement link to :=
    TOKEN tokg = talloc();
    tokg->tokentype = OPERATOR;
    tokg->whichval = ASSIGNOP;
    statement->link = tokg;
    printf("statement linked to := \n");
    
    //:= to i
    //create 'i' token - which is copying token i from asg tok
    TOKEN tokh = talloc();
    tokh->tokentype = asg->operands->tokentype;
    
    strcpy (tokh->stringval,asg->operands->stringval);
    //link tokg(:=) to identiifer token i
    tokg->operands = tokh;
    printf("operanded := with i \n");
    
    //i to +
    TOKEN toki = talloc();
    toki->tokentype = OPERATOR;
    toki->whichval = PLUSOP;
    tokh->link = toki;
    printf("linked i with + \n");
    
    //+ to i
    TOKEN tokj = talloc();
    tokj->tokentype = asg->operands->tokentype;
    strcpy (tokj->stringval,asg->operands->stringval);
    toki->operands = tokj;
    printf("operaended + with 1 \n");
    
    //i to 1
    TOKEN tokl = talloc();
    tokl->tokentype = NUMBERTOK;
    tokl->datatype = INTEGER;
    tokl->intval = 1;
    tokj->link = tokl;
    printf("linked i and 1 \n");
    
    //tokg link to goto
    TOKEN tokq = talloc();
    tokq->tokentype = OPERATOR;
    tokq->whichval = GOTOOP;
    tokg->link = tokq;
    printf("linked := with goto \n");
    
    //goto operand to 0 (lbl)
    TOKEN tokm = talloc();
    tokm->tokentype = NUMBERTOK;
    tokm->datatype = INTEGER;
    tokm->intval = lbl;
    printf("operanded goto and labelnumber \n");
    
    tokq->operands = tokm;
    printf("the following shows what tok looks like in makefor function using pretty print function \n");
    
    ppexpr(tok); 
    printf("\n ppexpr just ran \n");
    printf("You finished calling the makefor function \n");
    return tok;

}
TOKEN findtype(TOKEN tok)
{
    SYMBOL sym, typ;
    sym = searchst(tok->stringval);
        
    if(sym->kind == BASICTYPE ) //then the token is itself a basic datatype (Integer, Real, String, Bool)
    {
      tok->symtype = sym; 
      tok->datatype = sym->basicdt; 
          
    }
    else if(sym->kind == TYPESYM)
    {
      tok->symtype = sym->datatype;
        
    }
    else //error
    {
        printf("Your findtype recieved bad type \n");
    }
     return tok;
}
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
