all:
	flex ./plain.lex
	bison -v -d --file-prefix=p plain.y
	g++ -o parser p.tab.c lex.yy.c -lfl -std=c++11

clean:
	rm -f parser lex.yy.c lexer p.output p.tab.h p.tab.c *.mil
