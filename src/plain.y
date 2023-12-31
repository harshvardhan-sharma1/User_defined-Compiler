%{
#include <stdio.h>
#include<stdio.h>
#include<string>
#include<vector>
#include<stack>
#include<string.h>
#include<stdlib.h>
#include "p.tab.h"

extern FILE* yyin;
extern int yylex(void);
void yyerror(const char *msg);
extern int currLine;
extern int newLine;
extern int col; 

char *identToken;
int numberToken;
int  count_names = 0;
int tempcounter = 0;
int inloop = -1;
std::string tempForArrange;

enum Type { Integer, Array };

struct Symbol {
  std::string name;
  Type type;
};

struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};

int functioncounter = 0;
std::vector <Function> symbol_table;

const int keySIZE = 19;
std::string keywords[keySIZE] = {"num", "lt", "gt", "leq", "geq", "AND", "NOT", "OR", "same", "diff", "break", "contn", "loop", "IF", "ELSE", "scan", "print", "printL", "ret"};

// remember that Bison is a bottom up parser: that it parses leaf nodes first before
// parsing the parent nodes. So control flow begins at the leaf grammar nodes
// and propagates up to the parents.
Function *get_function() {
  int last = symbol_table.size()-1;
  if (last < 0) {
    printf("\n***Error. Attempt to call get_function with an empty symbol table***\n");
    printf("Create a 'Function' object using 'add_function_to_symbol_table' before\n");
    printf("calling 'find' or 'add_variable_to_symbol_table'");
    exit(1);
  }
  return &symbol_table[last];
}

bool findFunction(std::string &ident){
  for(int i = 0; i < symbol_table.size(); i++)
  {       
     //printf("symbol_table_value = %s, IDENT = %s\n", symbol_table[i].name.c_str(), ident.c_str());

      if(symbol_table[i].name == ident)
      {
        return true;
      }
  }
  return false;
}

// find a particular variable using the symbol table.
// grab the most recent function, and linear search to
// find the symbol you are looking for.
// you may want to extend "find" to handle different types of "Integer" vs "Array"
bool find(std::string &value, Type t) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if ((s->name == value) && (s->type == t)) {
      return true;
    }
  }
  return false;
}

// when you see a function declaration inside the grammar, add
// the function name to the symbol table
void add_function_to_symbol_table(std::string &value) {
  Function f; 
  f.name = value;
  symbol_table.push_back(f);
}

// when you see a symbol declaration inside the grammar, add
// the symbol name as well as some type information to the symbol table
void add_variable_to_symbol_table(std::string &value, Type &t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}

// a function to print out the symbol table to the screen
// largely for debugging purposes.
void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}


std::stack<int> loopstack;

void verifyDigit(std::string &dig)
{
  int digit = std::stoi(dig);
  if(digit <= 0)
  {
    yyerror(std::string(" Array size must be greater than 0.").c_str());
    exit(1);
  }
}

bool checkIfReserved(std::string &ident)
{
  for(int i = 0; i < keySIZE; i++)
  {
     if(ident == keywords[i])
     {
       return true;
     }
  }
  return false;
}

std::string create_Temp()
{
  static int num = 0;
  std::string t = std::string("_temp")+std::to_string(num);
  num ++;
  return t;
}

std::string decl_temp_code(std::string &temp)
{
  return std::string(". ") + temp + std::string("\n");
}

std::string create_if()
{
  static int if_num = 0;
  std::string t = std::string("if_true")+std::to_string(if_num);
  if_num ++;
  return t;
}

std::string create_loop()
{
  //static int loop_num = 0;
  std::string t = std::string("beginloop")+std::to_string(loopstack.top());
  //loop_num ++;
  return t;
}

std::string decl_label_code(std::string &temp)
{
  return std::string(": ") + temp + std::string("\n");
}

std::string create_else()
{
  static int num = 0;
  std::string t = std::string("else") + std::to_string(num);
  num++;
  return t;
}

struct CodeNode {
    std::string code; // generated code as a string.
    std::string name;
};

%}

%union {
  struct CodeNode *node;
  char *op_val;
}


%define parse.error verbose
%start prog_start
%token NUM COLON L_SQR R_SQR L_CUR R_CUR L_PAR R_PAR
%token MODULUS PLUS MINUS DIVIDE MULTIPLY 
%token L_T G_T L_EQ G_EQ EQ AND OR NOT EQUALS NOT_EQ CONTAIN
%token BREAK PERIOD CONT LOOP IF ELSE INPUT OUTPUT OUTPUT_WITH_NEWLINE
%token RETURN COMMA  
%token LIST

%token <op_val> DIGIT 
%token <op_val> IDENTIFIER
%token <op_val> FUNCNAME
%type <node> prog_start
%type <node> functions
%type <node> function
%type <node> arguments
%type <node> argument
%type <node> statements
%type <node> statement
%type <node> array
%type <node> assign
%type <node> ifstatement
%type <node> elsestatement
%type <node> loop
%type <node> expressions
%type <node> binop
%type <node> paramaters
%type <node> declarations
%type <node> declist
%type <node> declaration
%type <node> function_call
%type <node> pstatements
%type <node> mathexp
%type <node> addop
%type <node> term
%type <node> mulop
%type <node> factor
%type <node> rstatement
%type <op_val> function_ident

%%
prog_start: %empty
            {
              CodeNode *node = new CodeNode;
              $$ = node;
            }
            | functions
              {
                  CodeNode *node = $1;
                  std::string code = node->code;
                  std::string t = "main";
                  bool temp = findFunction(t);
                  if(temp == false)
                  {
                    yyerror(std::string("Program has no main function\n").c_str());
                    exit(1);
                  }
                  node->code = code;
                  $$ = node;
                  printf("%s", code.c_str());
              }
            ; 

functions:  function
            {
              $$ = $1;
            }
            | function functions
              {
                CodeNode *func  = $1;
                CodeNode *funcs = $2;
                std::string code = func->code + funcs->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            ;

function_ident: FUNCNAME {
  // add the function to the symbol table.
  std::string f = $1;
  std::string fncnm = f.substr(1);
  add_function_to_symbol_table(fncnm);
  $$ = $1;
}

function:   function_ident L_PAR arguments R_PAR NUM L_CUR statements R_CUR
            {
              std::string fncnm = $1 + 1;
              
              if(!findFunction(fncnm))
              {
                yyerror(std::string("Function" + fncnm + "() has not been defined").c_str());
                exit(2);
              }
              CodeNode* args = $3;
              CodeNode* sts = $7;
              
              std::string code = std::string("func ") + fncnm + std::string("\n") + args->code + sts->code + std::string("endfunc\n\n");
              functioncounter = 0;
              CodeNode *node = new CodeNode;
              node->code = code;
              $$ = node;
            };

arguments:  %empty
            { 
              CodeNode *node = new CodeNode;
              $$ = node;
            }
            | argument COMMA arguments
              {
                  CodeNode *arg1 = $1;
                  CodeNode *arg2 = $3;
                  CodeNode *node = new CodeNode;
                  node->code = arg1->code + std::string("\n") + arg2->code;
                  // $$->ids = arg1->ids+ arg2->ids;
                  $$ = node;
              }
            | argument  
            {
              $$->code += std::string("\n");
              $$ = $1 ;
            };

argument:   NUM IDENTIFIER
            {
                std::string ident = $2;
                if(find(ident, Integer))
                {
                  yyerror(std::string("Variable" + ident + " is already defined").c_str());
                  exit(1);
                }
                if(checkIfReserved(ident))
                {
                  yyerror(std::string("Variable" + ident + " cannot be defined as a keyword.").c_str());
                }
                Type t = Integer;
                add_variable_to_symbol_table(ident, t);
                std::string code = 	std::string(". ") + ident +  std::string("\n= ") + ident + std::string(", $") + std::to_string(functioncounter);
                functioncounter++;
                CodeNode *node = new CodeNode;
                node->code = code;
                node->name = ident;
                // $$->ids.push_back(ident);
                $$ = node;
            };


statements: %empty 
            {
              CodeNode *node = new CodeNode;
              $$ = node;
            }
            | statement statements
            {
              CodeNode *stmt1 = $1;
              CodeNode *stmt2 = $2;
              CodeNode *node = new CodeNode;
              node->code = stmt1->code + stmt2->code;
              $$ = node;
            };

statement:  declarations 
              {
                CodeNode* dec = $1;
                std::string code = dec->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | ifstatement
            {
              CodeNode* ifst = $1;
              std::string code = ifst->code;
              CodeNode *node = new CodeNode;
              node->code = code;
              $$ = node;
            }
            | loop
            {
              CodeNode* loopst = $1;
              std::string code = loopst->code;
              CodeNode *node = new CodeNode;
              node->code = code;
              $$ = node;
            }
            | pstatements
              {
                CodeNode* pst = $1;
                std::string code = pst->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | rstatement 
              {
                CodeNode* rst = $1;
                std::string code = rst->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | assign PERIOD
              {
                CodeNode* assgn = $1;
                std::string code = assgn->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | RETURN mathexp PERIOD
              {
                CodeNode* mathxp = $2;
                std::string code = mathxp->code + std::string("ret ") + mathxp->name + std::string("\n");
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | array PERIOD 
              {
                CodeNode* arr = $1;
                std::string code = arr->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | BREAK PERIOD 
              {
                std::string code = std::string(":= endloop");
                if(loopstack.empty())
                {
                  yyerror("break is not in loop");
                  exit(10);
                }
                else
                {
                  code +=  std::to_string(loopstack.top()) + std::string("\n");
                }
                
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | CONT PERIOD
              {
                std::string code = std::string(":= beginloop"); 
                if(loopstack.empty())
                {
                  yyerror("contn is not in a loop");
                  exit(9);
                }
                else{
                  code += std::to_string(loopstack.top()); 
                }
                code+= std::string("\n");
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            ;

array:      LIST IDENTIFIER L_SQR DIGIT R_SQR
              {
                std::string ident = $2;
                Type t = Array;
                if(find(ident, Integer))
                {
                  yyerror(std::string("Variable " + ident + " has already been declared as an integer.").c_str());
                  exit(1);
                }
                if(find(ident, Array) == false)
                {
                  add_variable_to_symbol_table(ident, t);
                  std::string dig = $4;
                  verifyDigit(dig);
                  std::string code = std::string(".[] ") + ident + std::string(", ") + dig + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
                }
                else
                {
                  yyerror(std::string("Array "+ ident + " has already been declared").c_str());
                  exit(1);
                }
              } 
            | IDENTIFIER L_SQR DIGIT R_SQR EQ mathexp
              { 
                std::string ident = $1;
                if(find(ident, Integer))
                {
                  yyerror(std::string("Variable" + ident + " has already been declared as an integer").c_str());
                  exit(1);
                }
                if(find(ident, Array) == true)
                {
                  std::string dig = $3;
                  // verifyDigit(dig);
                  if(stoi(dig)<0)
                  {
                    yyerror(std::string("List cannot be defined with negative index").c_str());
                    exit(8);
                  }
                  CodeNode *mathx = $6;
                  std::string code = mathx->code + std::string("[]= ") + ident + std::string(", ") + dig + std::string(", ") + mathx->name + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                 $$ = node;
                }
                else
                {
                  yyerror(std::string("Variable " + ident+ " is not an array.").c_str());
                  exit(1);
                }
                
              }
            ;

assign:      IDENTIFIER EQ mathexp  
              {
                std::string ident = $1;
                Type t = Integer;
                if(find(ident, t) == false)
                {
                  yyerror(("Variable " + ident+ " not declared").c_str());
                  exit(1);
                }
                if(find(ident, Array) == true)
                {
                  yyerror(std::string(ident +" is a integer variable").c_str());
                  exit(1);
                }
                CodeNode* mathxp = $3;
                std::string code,temp3 ;
                int index;
                code += mathxp->code;
                code += std::string("= ") + ident + std::string(", ") + mathxp->name + std::string("\n");
                
                /*if(mathxp->code.find("_temp") != std::string::npos)
                  {
                    index = mathxp->code.find("_temp");
                    temp3 = mathxp->code.substr(index, mathxp->code.size() -1);
                    printf("Here:%s;", temp3.c_str());
                    index = mathxp->code.find("=");
                    temp3 = mathxp->code.substr(0, index);
                    printf("Result:%s",temp3.c_str());
                    code = decl_temp_code(temp3) +  std::string("= ") + ident + std::string(", ") + mathxp->name + std::string("\n") ;
                  }else{
                  }*/
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | IDENTIFIER COMMA declaration 
              {
                
                std::string ident = $1;
                Type t = Integer;
                if(find(ident, Integer) == false)
                {
                  yyerror(std::string("Variable " + ident + " not a integer").c_str());
                  exit(1);
                }
                if(find(ident, Array) == true)
                {
                  yyerror(std::string(" " + ident +" is a integer variable").c_str());
                  exit(1);
                }
                CodeNode* dcl = $3;
                std::string code = std::string(". ") + ident + std::string("\n") + dcl->code;
                
                //std::string code = std::string("=") + ident + std::string(", ") + dcl->code + std::string("\n");
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            ;

ifstatement:   IF CONTAIN expressions CONTAIN L_CUR statements R_CUR elsestatement 
                {
                  CodeNode* condition = $3;
                  CodeNode* st = $6;
                  CodeNode* elsest = $8;
                  CodeNode* node = new CodeNode;
                  std::string iflabel = create_if();
                  std::string code = condition->code;
                  code += std::string("?:= ") + iflabel + std::string(", ") + condition->name + std::string("\n");
                  code += elsest->name; //code += ":= " + elsest->name + std::string("\n");
                  code += ": " + iflabel + std::string("\n");
                  code += st->code;
                  std::string temp = std::string("endif") + iflabel.substr(iflabel.find("e") + 1, iflabel.at(iflabel.size()-1));
                  code += std::string(":= ") + temp + std::string("\n"); //have end if
                  code += elsest->code;
                  code += std::string(": ") + temp + std::string("\n");
                  node->code = code;
                  $$ = node;
                }
                ;


elsestatement: %empty
                {
                  CodeNode *node = new CodeNode;
                  $$ = node;
                }
                | ELSE L_CUR statements R_CUR
                {
                  CodeNode *node = new CodeNode;
                  std::string n = create_else();
                  node->name =  std::string(":= ") + n + std::string("\n");
                  CodeNode *st = $3;
                  node->code = decl_label_code(n) + st->code;
                  $$ = node;
                }
                ;

loopbegin: LOOP {
    inloop++;
    loopstack.push(inloop);
}

loop:       loopbegin CONTAIN expressions CONTAIN L_CUR statements R_CUR
            {
                CodeNode* condition = $3;
                CodeNode* st = $6;
                CodeNode* node = new CodeNode;
                std::string loopname = create_loop();
                std::string integer = loopname.substr(loopname.find("p") + 1 , loopname.at(loopname.size() -1));
                std::string code = std::string(": ") + loopname + std::string("\n") + condition->code;
                code += std::string("?:= loopbody") + integer + std::string(", ") + condition->name + std::string("\n");
                code += std::string(":= endloop") + integer + std::string("\n");
                code += std::string(": loopbody") + integer + std::string("\n");
                code += st->code;
                code += std::string(":= ") + loopname + std::string("\n");
                code += std::string(": endloop")+ integer + std::string("\n");
                loopstack.pop();
                node->code = code;
                $$ = node;
            } 
            ;

expressions:    mathexp binop expressions
                {
                  CodeNode* mathxp = $1;
                  CodeNode* binoperat = $2;
                  CodeNode* expr = $3;
                  std::string temp = create_Temp();
                  std::string code = decl_temp_code(temp) + mathxp->code + expr->code + binoperat->code + temp + std::string(", ") + mathxp->name + std::string(", ") + expr->name + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->name = temp;
                  node->code = code;
                  $$ = node;
                }
                | NOT mathexp  //Work on NOT
                  {
                    CodeNode* mathxp = $2;
                    std::string temp = create_Temp();
                    std::string code = decl_temp_code(temp) + mathxp->code + std::string("! ") + temp + std::string(", ") + mathxp->name + std::string("\n");;
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    node->name = temp;
                    $$ = node;
                  }
                | NOT mathexp binop expressions  
                  {
                    CodeNode* mathxp = $2;
                    CodeNode* binoperat = $3;
                    CodeNode* expr = $4;
                    std::string temp = create_Temp();
                    std::string temp2 = create_Temp();
                    std::string code = decl_temp_code(temp) + decl_temp_code(temp2) + mathxp->code + expr->code + binoperat->code + temp + std::string(", ") + mathxp->name + std::string(", ") + expr->name + std::string("\n"); 
                    code += std::string("! ") + temp2 + std::string(", ") + temp + std::string("\n");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    node->name = temp2;
                    $$ = node;
                  }
                | CONTAIN expressions CONTAIN   //New temp made here
                  {
                    $$ = $2;
                  }
                | mathexp 
                  {
                     CodeNode* mathxp = $1;
                     CodeNode *node = new CodeNode;
                     node->code = mathxp->code;
                     node->name = mathxp->name;
                     $$ = node;
                  };

binop :          AND 
                {
                  std::string code = std::string("&& ");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
                }
                | OR 
                  {
                    std::string code = std::string("|| ");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    $$ = node;
                  }
                | EQUALS
                  {
                    std::string code = std::string("== ");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    $$ = node;
                  }
                | NOT_EQ
                  {
                    std::string code = std::string("!= ");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    $$ = node;
                  }
                | L_T 
                  {
                    std::string code = std::string("< ");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    $$ = node;
                  }
                | G_T 
                  {
                    std::string code = std::string("> ");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    $$ = node;
                  }
                | L_EQ
                  {
                    std::string code = std::string("<= ");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    $$ = node;
                  }
                | G_EQ
                  {
                    std::string code = std::string(">= ");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    $$ = node;
                  }
                ;

declarations:  NUM declist PERIOD
              {
                CodeNode* decl = $2;
                std::string code = decl->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            ;

declist:  declaration 
            {
              // CodeNode* declr = $1;
              // std::string code = declr->code;
              // CodeNode *node = new CodeNode;
              // node->code = code;
              // $$ = node;

              $$ = $1;
            }
            | declaration COMMA declist
              {
                CodeNode* declr = $1;
                CodeNode* decl = $3;
                std::string code = declr->code  + decl->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            ;

declaration:  IDENTIFIER 
              {
                std::string ident = $1;
                std::string code = std::string(". ") + ident + std::string("\n");
                Type temp = Integer;
                bool temp2 = checkIfReserved(ident);
                if(find(ident, Array))
                {
                  yyerror(std::string("Variable"+ ident + " has already been declared as a list").c_str());
                  exit(4);
                }
                if((find(ident, temp) == false) && !temp2)
                {
                  add_variable_to_symbol_table(ident, temp);
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
                } else 
                {
                  if(temp2)
                  {
                    yyerror(std::string("Variable "+ ident + " is a keyword").c_str());
                    exit(1);
                  }else
                  {
                    yyerror(std::string("Error, variable " + ident + " has already declared").c_str());
                    exit(1);
                  }
                }

              }
            | IDENTIFIER EQ mathexp 
              {
                std::string ident = $1;
                if(find(ident, Array))
                {
                  yyerror(std::string("Error, variable " + ident + " has already been declared as a list").c_str());
                  exit(4);
                }
                Type temp = Integer;
                bool temp2 = checkIfReserved(ident);
                std::string code;
                std::string temp3;
                int index;
                if((find(ident, temp) == false) && !temp2)
                {
                  add_variable_to_symbol_table(ident, temp);              
                  CodeNode* mathxp = $3;
                  /*if(mathxp->code.find("_temp") != std::string::npos)
                  {
                    index = mathxp->code.find("_temp");
                    temp3 = mathxp->code.substr(index, mathxp->code.size() -1);
                    index = mathxp->code.find(" ");
                    temp3 = mathxp->code.substr(0, index);
                    code = decl_temp_code(temp3);
                  }else{
                    code = std::string("= ") + ident + std::string(", ") + mathxp->code + std::string("\n");
                  }*/
                  //code += mathxp->code;
                  code += std::string(". ") + ident + std::string("\n");
                  code += std::string("= ") + ident + std::string(", ") + mathxp->name + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
                } else 
                {
                  if(temp2)
                  {
                    yyerror(std::string("Error, variable " + ident + " is a keyword").c_str());
                    exit(1);
                  }else
                  {
                    yyerror(std::string("Error, variable " + ident + " has not been declared").c_str());
                    exit(1);
                  }
                }
              };


pstatements:  OUTPUT L_PAR function_call R_PAR PERIOD
              {
                  CodeNode* fncall = new CodeNode;
                  fncall = $3;
                  if(!findFunction(fncall->name))
                  {
                    yyerror(std::string("Error, Function " + fncall->name + " has not been defined").c_str());
                    exit(2);
                  }
                  std::string tmp = create_Temp();
                  
                  // std::string code = decl_temp_code(tmp) + std::string("call ") + fncall->name + (", ") + tmp + std::string("\n");
                  std::string code = fncall->code + std::string(".> ") + fncall->name + std::string("\n");
                  // code+= fncall->code + std::string(".> ") + tmp + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
              }
              |
              OUTPUT L_PAR IDENTIFIER R_PAR PERIOD
              {
                  std::string ident = $3;
                  if(!find(ident, Integer)) 
                  {
                    yyerror(std::string("Error, variable " + ident + " has not been declared").c_str());
                    exit(1);
                  }
                  std::string code = std::string(".> ") + ident + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
              }
              |
              OUTPUT L_PAR IDENTIFIER L_SQR DIGIT R_SQR R_PAR PERIOD
              {
                  std::string ident = $3;
                  if(!find(ident, Array)) 
                  {
                    yyerror(std::string("Error, variable " + ident + " has not been declared").c_str());
                    exit(1);
                  }
                  std::string dig = $5;
                  // verifyDigit(dig);
                  if(stoi(dig)<0)
                  {
                    yyerror(std::string("Error, List " + ident + " cannot be defined with negative index").c_str());
                    exit(8);
                  }
                  std::string code = std::string(".[]> ") + ident + std::string(", ") + dig + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
              }
              | OUTPUT_WITH_NEWLINE L_PAR IDENTIFIER R_PAR PERIOD
              {
                  std::string ident = $3;
                  if(!find(ident, Integer)) 
                  {
                    yyerror(std::string("Error, variable " + ident + " has not been declared").c_str());
                    exit(1);
                  }
                  std::string code = std::string(".> ") + ident + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
              }
              |
               OUTPUT_WITH_NEWLINE L_PAR IDENTIFIER L_SQR DIGIT R_SQR R_PAR PERIOD
               {
                  std::string ident = $3;
                  if(!find(ident, Array)) 
                  {
                    yyerror(std::string("Error, variable " + ident + " has not been declared").c_str());
                    exit(1);
                  }
                  std::string dig = $5;
                  // verifyDigit(dig);
                  if(stoi(dig)<0)
                  {
                    yyerror(std::string("Error, List " + ident + " cannot be defined with negative index ").c_str());
                    exit(8);
                  }
                  std::string code = std::string(".[]> ") + ident + std::string(", ") + dig + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
              }
              ;

//print(var). print(a[8]).
//Must be rstatement: INPUT L_PAR mathexp R_PAR PERIOD
rstatement:  INPUT L_PAR IDENTIFIER R_PAR PERIOD 
             {
                std::string ident = $3;
                std::string code = std::string(".< ") + ident + std::string("\n");
                if(find(ident, Integer) == false) 
                {
                  yyerror(std::string("Error, Variable " + ident + " has not been declared").c_str());
                  exit(1);
                }
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
             }
             |
             INPUT L_PAR IDENTIFIER L_SQR DIGIT R_SQR R_PAR
             {
                std::string ident = $3;
                std::string dig = $5;
                if(find(ident, Array) == false)
                {
                  yyerror(std::string("Error, Variable " + ident + " has not been declared ").c_str());
                  exit(1);
                }
                else{
                  // verifyDigit(dig);
                  if(stoi(dig)<0)
                  {
                    yyerror(std::string("Error, List " + ident + " cannot be defined with negative index ").c_str());
                    exit(8);
                  }
                  std::string code = std::string(".[]< ") + ident + std::string(", ") + dig + std::string("\n");
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
                }
             }
             ;

mathexp:    mathexp addop term  
            {
                CodeNode *mathx = $1;
                CodeNode *addoperator = $2;
                CodeNode *trm = $3;
                std::string temp = create_Temp();
                std::string code = decl_temp_code(temp);
                code += mathx->code + trm->code + addoperator->code + temp + std::string(", ") +mathx->name + std::string(", ") + trm->name + std::string("\n") ; 
                CodeNode *node = new CodeNode;
                node->code = code;
                node->name = temp;
                $$ = node;
            }
            | term 
              {
                CodeNode *trm = $1;
                $$ = trm;
              }
              ;

addop:      PLUS 
             {
              std::string code = std::string("+ ");
              CodeNode *node = new CodeNode;
              node->code = code;
              $$ = node;
            }
            | MINUS 
               {
                std::string code = std::string("- ");
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
              ;

term:       term mulop factor  
              {
                CodeNode *trm = $1;
                CodeNode *muloperator = $2;
                CodeNode *fact = $3;
                std::string temp = create_Temp();
                std::string code =  decl_temp_code(temp);
                code += trm->code;
                code += fact->code;
                code += muloperator->code +  temp + std::string(", ") +trm->name + std::string(", ") + fact->name +  std::string("\n") ; 
                CodeNode *node = new CodeNode;
                node->code = code;
                node->name = temp;
                $$ = node;
              }
            | factor 
              {
                  CodeNode *fact = $1;
                  $$ = fact;
                }
                ;

mulop:      MULTIPLY 
            {
                std::string code = std::string("* ");
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | DIVIDE 
              {
                std::string code = std::string("/ ");
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
            | MODULUS 
              {
                std::string code = std::string("% ");
                CodeNode *node = new CodeNode;
                node->code = code;
                $$ = node;
              }
              ;

factor:     L_PAR mathexp R_PAR 
            { 
              CodeNode *mathx = $2;
              $$ = mathx;
            }
            | DIGIT 
              {
                std::string name = $1;
                CodeNode *node = new CodeNode;
                node->name = name;
                $$ = node;
              }
            | IDENTIFIER 
              {
                std::string name = $1;
                CodeNode *node = new CodeNode;
                //node->code = code;
                if(!find(name, Integer)) 
                {
                  yyerror(std::string("Error, Variable " + name + " has not been declared ").c_str());
                  exit(4);
                }
                node->name = name;
                $$ = node;
              }
            | function_call 
              {
                CodeNode *para = $1;
                std::string code = para->code;
                CodeNode *node = new CodeNode;
                node->code = code;
                node->name = para->name;
                $$ = node;
              }
            | IDENTIFIER L_SQR DIGIT R_SQR 
              {
                std::string ident = $1;
                std::string dig = $3;
                if(!find(ident, Array)) 
                {
                  yyerror(std::string("Error, Variable " + ident + " has not been declared ").c_str());
                  exit(1);
                }
                //  verifyDigit(dig);
                  if(stoi(dig)<0)
                  {
                    yyerror(std::string("Error, List " + ident + " cannot be defined with negative index ").c_str());
                    exit(8);
                  }
                std::string temp = create_Temp();
                std::string code = decl_temp_code(temp) + std::string("=[] ") + temp + std::string(", ")+ident + std::string(", ") + dig + std::string("\n");
                CodeNode *node = new CodeNode;
                node->name = temp;
                node->code = code;
                $$ = node;
              }
              ;

function_call:  IDENTIFIER L_PAR paramaters R_PAR
                {
                  std::string ident = $1;
                  bool temp = findFunction(ident);
                  if(temp == true)
                  {
                    std::string temp = create_Temp();
                    CodeNode *param = $3;
                    std::string code = param->code + decl_temp_code(temp) 
                                     + std::string("call ") + ident + std::string(", ") + temp +  std::string("\n");
                    CodeNode *node = new CodeNode;
                    node->code = code;
                    node->name = temp;
                    $$ =  node;
                  } 
                  else
                  {
                    yyerror(std::string("Error, Unknown function: " + ident).c_str());
                    exit(1);
                  }
                };


paramaters:     %empty 
                {
                }
                | mathexp COMMA paramaters 
                {
                  CodeNode *math = $1;
                  CodeNode *params = $3;
                  std::string code;
                  CodeNode *node = new CodeNode;
                  node->code += math->code + std::string("param ") + math->name + std::string("\n");
                  node->code += params->code;
                  //node->code =  param->code + math->name + math->code + std::string("\n") +  std::string("param ") + param->name + std::string("\n") ;
                  $$ = node;
                }
                | mathexp 
                {
                  CodeNode *math = $1;
                  std::string code = math->code +  std::string("param ") + math->name + std::string("\n") ;
                  CodeNode *node = new CodeNode;
                  node->code = code;
                  $$ = node;
                };

%%
int main(int argc, char** argv){
	if(argc >= 2){
		yyin = fopen(argv[1], "r");
		if(yyin == NULL)
			yyin = stdin;
	}else{
		yyin = stdin;
	}
	yyparse();

  return 0;
}

/* Called by yyparse on error. */
void yyerror (const char *s)
{
      extern int newLine;
      extern int col;

	  fprintf (stderr, "**Error at line %d:%d. %s\n", newLine, col, s);
}