%lex

%%
\s+                 	{/* ignore whitespace */;}
"program"				{return 'TOKPROGRAM'; }
"var"					{return 'TOKVAR'; }
"int"					{return 'TOKINT';}
"float"					{return 'TOKFLOAT';}
"String"				{return 'TOKSTRING';}
"print"					{return 'TOKPRINT';}
"if" 					{return 'TOKIF';}
"else"					{return 'TOKELSE';}
"while"					{return 'TOKWHILE';}
"or"					{return 'TOKOR';}
"and"					{return 'TOKAND';}
[a-zA-Z][a-zA-Z0-9]*	{return 'ID';}
[0-9]+					{return 'INT';}
^[-+]?[0-9]*\.[0-9]+$	{return 'FLOAT';}
\"[^\"]*\"|\'[^\']*\' 	{return 'STRING';}
";"						{return 'SEMICOLON';}
":"						{return 'COLON';}
","						{return 'COMMA';}
"{"						{return 'OBRACE';}
"}"						{return 'EBRACE';}
"="						{return 'EQUAL';}
"("						{return 'OPARENT';}
")"						{return 'EPARENT';}
"<"						{return 'LBRACE';}
">"						{return 'RBRACE';}
"+"						{return 'PLUS';}
"-"						{return 'MINUS';}
"*"						{return 'ASTERISK';}
"/"						{return 'SLASH';}
"!"						{return 'EMARK';}

/lex

%%

program
	: TOKPROGRAM bloque
	| TOKPROGRAM vars bloque
	;

vars
	: TOKVAR ID ids COLON tipo SEMICOLON recvars
	;

recvars
	: ID ids COLON tipo SEMICOLON recvars
	|
	;

ids
	: ids COMMA ID
	|
	;

tipo
	: TOKINT
	| TOKFLOAT
	| TOKSTRING
	;

bloque
	: OBRACE estatutos EBRACE
	;

estatutos
	: estatuto estatutos
	|
	;

estatuto
	: asignacion
	| condicion
	| ciclo
	| escritura
	;

asignacion
	: ID EQUAL expresion SEMICOLON
	;

condicion
	: TOKIF OPARENT expresion EPARENT bloque else SEMICOLON
	;

else
	: TOKELSE bloque
	|
	;

ciclo
	: TOKWHILE OPARENT expresion EPARENT bloque
	;

escritura
	: TOKPRINT OPARENT expresion escrituras EPARENT SEMICOLON
	| TOKPRINT OPARENT STRING escrituras EPARENT SEMICOLON
	;	

escrituras
	: COMMA expresion escrituras
	| COMMA STRING escrituras
	|
	;

expresion
	: exp 
	| exp comparacion
	;

comparacion
	: LBRACE exp
	| RBRACE exp
	| negativo EQUAL exp
	;

igual
	: EQUAL
	|
	;

negativo
	: EMARK
	|
	;

exp
	: termino opsumres
	;

opsumres
	: PLUS exp
	| MINUS exp
	| TOKOR exp
	|
	;

termino
	: factor opmultdiv
	;

opmultdiv
	: ASTERISK termino
	| SLASH termino
	| TOKAND termino
	|
	;

factor
	: OPARENT expresion EPARENT
	| varcte
	;

varcte:
	INT | FLOAT | ID
	;
