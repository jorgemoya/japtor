%lex

%%
\s+          						{/* ignore whitespace */;}
"program"								{return 'PROGRAM';}
"function"							{return 'FUNCTION';}
";"											{return ';';}
":"											{return ':';}
"{"											{return '{';}
"}"											{return '}';}
"("											{return '(';}
")"											{return ')';}
"var"										{return 'VAR';}
"int"										{return 'INT';}
"float"									{return 'FLOAT';}
"string"								{return 'STRING';}
([a-zA-Z][a-zA-Z0-9]*)	{return 'ID';}
<<EOF>>									{return 'EOF';}

/lex

%start program

%%

program
	: EOF
				{return null;}
	| PROGRAM ID ';' vars funct block ';' EOF
				{return yy;}
	;

vars
	: VAR ID ':' type ';' vars
				{
					var variable = {
						id: $2,
						type: $4
					}
					yy.vars.push(variable);
				}
	|
	;

type
	: INT
	| FLOAT
	| STRING
	;

funct
	: FUNCTION ID '(' vars ')' vars block ';' funct
				{
					var funct = {
						id: $2
					}
					yy.functs.push(funct);
				}
	|
	;

block
	: '{' '}'
	;

%%

var Raptor = function() {
	var raptorLexer = function () {};
	raptorLexer.prototype = parser.lexer;

	var raptorParser = function () {
		this.lexer = new raptorLexer();
		this.yy = {
			vars: [],
			functs: [],
			escape: function(value) {
				return value
					.replace(/&/gi, '&amp;')
					.replace(/>/gi, '&gt;')
					.replace(/</gi, '&lt;')
					.replace(/\n/g, '\n<br>')
					.replace(/\t/g, '&nbsp;&nbsp;&nbsp ')
					.replace(/  /g, '&nbsp; ');
			},
			parseError: function(msg, hash) {
				this.done = true;
				var result = new String();
				result.html = '<pre>' + msg + '</pre>';
				result.hash = hash;
				return result;
			}
		};
	};

	raptorParser.prototype = parser;
	var newParser = new raptorParser();
	return newParser;
};
if (typeof(window) !== 'undefined') {
	window.Raptor = Raptor;
} else {
	parser.Raptor = Raptor;
}
