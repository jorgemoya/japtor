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
"bool"									{return 'BOOL';}
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
					var proc = new Proc("main", "void", dir_proc(), json_to_vars($4));
					yy.procs.push(proc);
				}
	;

vars
	: VAR type ID ';' vars
				{
					alert(yystate);
					if ($5 !== "") {
						$$ = '{"id":"'+$3+'", "type":"'+$2+'", "dir":"'+dir_var($2)+'"},' + $5;
					} else {
						$$ =  '{"id":"'+$3+'", "type":"'+$2+'", "dir":"'+dir_var($2)+'"}';
					}
				}
	|
				{
					$$ = "";
				}
	;

type
	: INT
	| FLOAT
	| STRING
	| BOOL
	;

funct
	: FUNCTION type ID '(' vars ')' vars block ';' funct
				{
					var proc = new Proc($3, $2, dir_proc(), json_to_vars($5));
					yy.procs.push(proc);
				}
	|
	;

block
	: '{''}'
	;

%%

var dir_procs = 2000;

var gv_i = 5000;
var gv_f = 7000;
var gv_st = 9000;
var gv_bool = 11000;

var lv_i = 12000;
var lv_f = 14000;
var lv_st = 16000;
var lv_bool = 18000;

var tv_i = 19000;
var tv_f = 21000;
var tv_st = 23000;
var tv_bool = 25000;

var Raptor = function() {
	var raptorLexer = function () {};
	raptorLexer.prototype = parser.lexer;

	var raptorParser = function () {
		this.lexer = new raptorLexer();
		this.yy = {
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
	this.vars = vars.variables;
};

Proc.prototype = {
	size : function() {
		return this.vars.length;
	}
}

function dir_proc() {
	if(dir_procs < 5000)
		return dir_procs++;
	else
		alert("Out of memory.");
}

function dir_var(type) {
	switch(type) {
		case 'int':
			if (gv_i < 7000) {
				return gv_i++;
			} else {
				alert("Out of memory!");
			}
			break;
		case 'float':
			if (gv_f < 9000) {
				return gv_f++;
			} else {
				alert("Out of memory!");
			}
			break;
		case 'string':
			if (gv_st < 11000) {
				return gv_st++;
			} else {
				alert("Out of memory!");
			}
			break;
		case 'bool':
			if (gv_bool < 12000) {
				return gv_bool++;
			} else {
				alert("Out of memory!");
			}
			break;
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
