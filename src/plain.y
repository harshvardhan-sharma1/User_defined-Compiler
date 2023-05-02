%{
#include <stdio.h>
%}
%token NUM COLON IDENTIFIER L_SQR R_SQR L_CUR R_CUR L_PAR R_PAR
%token MODULUS NUM PLUS MINUS DIVIDE MULTIPLY 
%token L_T G_T L_EQ G_EQ EQ AND OR NOT EQUALS NOT_EQ CONTAIN
%token BREAK PERIOD CONT LOOP IF ELSE INPUT OUTPUT OUTPUT_WITH_NEWLINE
%token RETURN COMMA COLON FUNCNAME 

%%
prog_start: %empty {printf("prog_start --> epsilon\n");}
            | functions {printf("prog_start --> functions\n");}
            ; 

functions:  function {printf("function --> functions\n");}
            | function functions {printf("function --> function functions\n");}
            ;
function:   FUNCNAME L_PAR arguments R_PAR NUM L_CUR statements R_CUR
            {printf("function -->   NUM IDENTIFIER L_PAR arguments R_PAR L_CUR statements R_CUR\n");}

arguments:  %empty {printf("arguments --> epsilon");}
            | argument COMMA arguments {printf("arguments --> arguments COMMA arguments");}
            | argument  {printf("arguments --> argument");}
            ;

argument:   %empty {printf("arguments --> epsilon");} 
            | NUM IDENTIFIER {printf("argument --> NUM IDENTIFIER");}
            ;

if-statement:   %empty {printf("if --> epsilon");} 
                | IF CONTAIN expressions CONTAIN L_CUR statements R_CUR else-statement {printf("if-statement --> IF CONTAIN expressions CONTAIN L_CUR statements R_CUR else-statement");}
                | 
                ;
else-statement: %empty {printf("else-statement --> epsilon");}
                | ELSE L_CUR statements R_CUR {printf("else-statement --> ELSE L_CUR statements R_CUR");}
                ;
expressions:    expression AND expressions {printf("expressions--> expression AND expressions");}
                | expression OR expressions {printf("expressions--> expression OR expressions");}
                | NOT expressions   {printf("expressions--> NOT expressions");}
                | expression    {printf("expressions--> expression");}
                ;

expression:  declaration {printf("expressions--> declaration");}
            | function_call {printf("expressions--> function_call");}
            | mathexp   {printf("expressions--> mathexp")}
            | expression same expression    {printf("expressions--> expression same expression");}
            | expression diff expression    {printf("expressions--> expression diff expression");}
            ;

function_call:  function_call PERIOD {printf("fuction_call --> expression diff expression");}
                | FUNCNAME L_PAR paramaters R_PAR 
                ;

mathexp:  
            | mathexp addop term | term
            ;
addop:    
            | PLUS 
            | MINUS
            ;
term:    
            | term mulop factor  
            | factor
            ;
mulop:    
            | MULTIPLY
            | DIVIDE
            | MODULUS
            ;
factor:    
            | L_PAR exp R_PAR 
            | NUM
            ;

loops:  
            | loop loops {printf("loop --> loop loops\n");}
            ;

loop:   
            | CONTAIN expressions CONTAIN L_CUR statements R_CUR
            ;

statements: %empty {printf("statements --> epsilon")}
            | statement PERIOD statements
            ;
               
statement:  declaration
            | function_call
            | pstatements
            | rstatement
            ;

declaration: 

pstatements:  OUTPUT L_PAR IDENTIFIER R_PAR
             | OUTPUT_WITH_NEWLINE L_PAR IDENTIFIER R_PAR
             ;

rstatement:  INPUT L_PAR IDENTIFIER R_PAR
             ;
                

//==============================================
// "....go onto define all features of your language..."
//==============================================
%%
void main(int argc, char** argv)
{
    if(argc >=2)
        yyin = fopen(argv[1], "r");
        if(yyin == NULL)
            yyin = stdin;
        else
            yyin=stdin;

        yyparse();
}