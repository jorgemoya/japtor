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
				{

					var proc = new Proc("main", "main", 0, json_to_vars($4));
					yy.procs.push(proc);
				}
	;

vars
	: VAR type ID ';' vars
				{
					if (typeof $5 !== "undefined") {
						$$ = '{"id":"'+$3+'", "type":"'+$2+'", "dir":"'+0+'"},' + $5;
					} else {
						$$ =  '{"id":"'+$3+'", "type":"'+$2+'", "dir":"'+0+'"}';
					}
				}
	|
	;

type
	: INT
	| FLOAT
	| STRING
	;

funct
	: FUNCTION type ID '(' vars ')' vars block ';' funct
				{
					var proc = new Proc($3, $2, 0, json_to_vars($5));
					yy.procs.push(proc);
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
			procs: [],
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

function Proc(name, type, dir, vars){
	this.name = name;
	this.type = type;
	this.dir = dir;
	this.vars = vars;
};
Proc.prototype = {
	size : function() {
		return this.vars.variables.length;
	}
}

function json_to_vars(text) {
	var var_json = '{"variables":['+text+']}';
 	return JSON.parse(var_json);
}

if (typeof(window) !== 'undefined') {
	window.Raptor = Raptor;
} else {
	parser.Raptor = Raptor;
}
