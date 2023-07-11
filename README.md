# Compilers Project

## Language name: Plain

<p>Extension for programs written in Plain: p (e.g., hello.p) <br>
Compiler Name: PlainC </p>

- Plain is case sensitive
- White Spaces are ignored in our language
- Variable names have the following rules:
  - Should not be a Token name or syntax keyword
  - Should not start with a number or be a number or a “ : ” or whitespace or uppercase letter
  - Should not contain a “$” or “#”
  - Should not end in or contain “.” 



|    C++ syntax     | Plain syntax |
|          :---:            |          :---:             |
|int| num |
|array| list |
|=|=|
|+, -, *, /, %| +, -, *, /, % |
|<|lt|
|>|gt|
|<=|leq|
|>=|geq|
|==|same|
|!|NOT|
| &#124; &#124;  | OR |
|&&| AND |
|!=|diff|
|while|loop|
|break|break|
|continue|contn|
|if/else|IF/ELSE|
|cin|scan()|
|cout|print()|
|cout << ... << endl  | printL() |
| // | $ |
|/\*...\*/| &#36; '...' &#36; |
|Func_type func_name(parameter)|:func_name (parameter)func_type|
|return|ret|
|;|.|



|    Language Feature     | Code Example |
|          :---            |          :---             |
|Scalar integer|num a. <br /> num a,b = 1.|
|One-dimensional array of integers|list firstList[5]. <br /> firstList[2] = 3.|
|Assignment statements|a = 5.|
|Arithmetic operators|a = b + c. <br /> a = b - c. <br /> a = b / c. <br /> a = b * c.|
|Relational operators |a gt b <br /> a lt b <br /> a leq b <br /> a geq b <br /> a same b <br /> NOT a <br /> a OR b <br /> a AND b <br /> a diff b|
|While loop|loop \|condition\|  { <br />  &nbsp; &nbsp; &nbsp; …$Statements <br />  }|
|If-then-else statements|IF \|a gt b\| <br /> { <br /> &nbsp; &nbsp; &nbsp; …$Statements <br />    } <br /> ELSE <br /> { <br /> &nbsp; &nbsp; &nbsp;…$Statements <br /> }|
|Read and write statements|scan(a). <br /> print(a). <br /> printL(a).|
|Comments|\$Statements <br /> \$’ I <br /> &nbsp; &nbsp;  Am <br /> &nbsp; &nbsp; Writing in three lines ‘\$|
|Functions|:addTwo (num a, num b) num <br />{ <br /> &nbsp; &nbsp; &nbsp; ret a+b. <br /> }|




|    Symbol in language     | TOKEN for lexical analyzer |
|          :---:            |          :---:             |
|integer number|NUMBERXXXX|
|variable names|IDENTIFIER|
|+|PLUS|
|-|MINUS|
|/|DIVIDE|
|*|MULTIPLY|
|%|MODULUS|
|[|L_SQR|
|]|R_SQR|
|{|L_CUR|
|}|R_CUR|
|&#124;|CONTAIN|
|lt (<)|L_T|
|gt (>)|G_T|
|leq (<=)|L_EQ|
|geq (>=)|G_EQ|
|=|EQ|
|AND|AND|
|NOT|NOT|
|OR|OR|
|same (==)|EQUALS|
|diff (!=)|NOT_EQ|
|(|L_PAR|
|)|R_PAR|
|break|BREAK|
|contn|CONT|
|.|PERIOD|
|loop|LOOP|
|IF|IF|
|ELSE|ELSE|
|scan|INPUT|
|print|OUTPUT|
|printL|OUTPUT_WITH_NEWLINE|
|ret|RETURN|
|,|COMMA|
|:|COLON|
|~~B~~ (whitespace)|#|
