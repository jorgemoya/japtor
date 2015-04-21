%lex

%%
\s+          					 {/* ignore whitespace */;}
"program"							{return 'TOKPROGRAM';}
"function"						{return 'TOKFUNCTION';}
"var"									{return 'TOKVAR';}
"int"									{return 'TOKINT';}
"float"								{return 'TOKFLOAT';}
"print"								{return 'TOKPRINT';}
"if" 									{return 'TOKIF';}
"else"								{return 'TOKELSE';}
"while"								{return 'TOKWHILE';}
"or"									{return 'TOKOR';}
"and"									{return 'TOKAND';}
[a-zA-Z][a-zA-Z0-9]*	{return 'ID';}
[0-9]+								{return 'INT';}
^[-+]?[0-9]*\.[0-9]+$	{return 'FLOAT';}
\"[^\"]*\"|\'[^\']*\' {return 'STRING';}
";"										{return 'SEMICOLON';}
":"										{return 'COLON';}
","										{return 'COMMA';}
"{"										{return 'OBRACE';}
"}"										{return 'EBRACE';}
"="										{return 'EQUAL';}
"("										{return 'OPARENT';}
")"										{return 'EPARENT';}
"<"										{return 'LBRACE';}
">"										{return 'RBRACE';}
"+"										{return 'PLUS';}
"-"										{return 'MINUS';}
"*"										{return 'ASTERISK';}
"/"										{return 'SLASH';}
"!"										{return 'EMARK';}

/lex

%start program

%%

program
	: TOKPROGRAM ID SEMICOLON vars funcion bloque
														{{ $$ = ['Vars', $4]}}

	;

vars
	: TOKVAR ID ids COLON tipo SEMICOLON recvars
														{{ $$ = $2 }}

	|
	;

recvars
	: ID ids COLON tipo SEMICOLON recvars	{
												// console.log($1)
											}
	|
	;

ids
	: COMMA ID ids	{
						// console.log($2)
					}
	|
	;

tipo
	: TOKINT
	| TOKFLOAT
	| TOKSTRING
	;

funcion
	: TOKFUNCTION ID OPARENT recvars EPARENT vars bloque SEMICOLON
	|
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
	: TOKWHILE OPARENT expresion EPARENT bloque SEMICOLON
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
	: LBRACE EQUAL exp
	| RBRACE EQUAL exp
	| EMARK EQUAL exp
	| EQUAL EQUAL exp
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
	| ID params
	;

varcte
	: INT | FLOAT
	;

params
	: OPARENT EXP EPARENT
	|
	;
