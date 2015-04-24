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
([a-zA-Z][a-zA-Z0-9]*)(-|_)*([a-zA-Z][a-zA-Z0-9]*)	{return 'ID';}
<<EOF>>									{return 'EOF';}

/lex

%start program

%%

program
	: EOF
				{return null;}
	| PROGRAM ID ';' vars funct block ';' EOF
				{
					var proc = new Proc("main", "void", dir_proc(), [], json_to_vars($4));
					yy.procs.push(proc);

					assign_memory(yy.procs);
				}
	;

vars
	: VAR type ID ';' vars
				{
					if ($5 !== "") {
						$$ = '{"id":"'+$3+'", "type":"'+$2+'", "dir":"'+0+'"},' + $5;
					} else {
						$$ =  '{"id":"'+$3+'", "type":"'+$2+'", "dir":"'+0+'"}';
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
					var json;
					if ($5 === "" || $7 === "")
						json = $5 + $7;
					else
						json = $5 + "," + $7;

					var vars = json_to_vars($5);
					var paramTypes = [];

					for(var i = 0; i < vars.length; i++) {
						paramTypes.push(vars[i].type);
					}

					var proc = new Proc($3, $2, dir_proc(), paramTypes, json_to_vars(json));
					yy.procs.push(proc);
				}
	|
	;

block
	: '{''}'
	;

%%

var dir_procs;

var gv_i;
var gv_f;
var gv_st;
var gv_bool;

var lv_i;
var lv_f;
var lv_st;
var lv_bool;

var tv_i;
var tv_f;
var tv_st;
var tv_bool;

init_dirs();

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

function Proc(name, type, dir, params, vars){
	this.name = name;
	this.type = type;
	this.dir = dir;
	this.params = params;
	this.vars = vars;
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

function assign_memory(procs) {
	for(var i = 0; i < procs.length; i++) {
		var isGlobal = false;
		if (procs[i].name == "main") {
			isGlobal = true;
		}

		for(var j = 0; j < procs[i].vars.length; j++) {
			if (procs[i].vars[j].id.indexOf("tmp__") > -1)
			{
				switch(procs[i].vars[j].type) {
					case 'int':
						if (tv_i < 21000) {
							procs[i].vars[j].dir = tv_i++;
						} else {
							alert("Out of memory!");
						}
						break;
					case 'float':
						if (tv_f < 23000) {
							procs[i].vars[j].dir = tv_f++;
						} else {
							alert("Out of memory!");
						}
						break;
					case 'string':
						if (tv_st < 25000) {
							procs[i].vars[j].dir = tv_st++;
						} else {
							alert("Out of memory!");
						}
						break;
					case 'bool':
						if (tv_bool < 26000) {
							procs[i].vars[j].dir = tv_bool++;
						} else {
							alert("Out of memory!");
						}
						break;
				}
			} else {
				if(isGlobal) {
					switch(procs[i].vars[j].type) {
						case 'int':
							if (gv_i < 7000) {
								procs[i].vars[j].dir = gv_i++;
							} else {
								alert("Out of memory!");
							}
							break;
						case 'float':
							if (gv_f < 9000) {
								procs[i].vars[j].dir = gv_f++;
							} else {
								alert("Out of memory!");
							}
							break;
						case 'string':
							if (gv_st < 11000) {
								procs[i].vars[j].dir = gv_st++;
							} else {
								alert("Out of memory!");
							}
							break;
						case 'bool':
							if (gv_bool < 12000) {
								procs[i].vars[j].dir = gv_bool++;
							} else {
								alert("Out of memory!");
							}
							break;
					}
				} else {
					switch(procs[i].vars[j].type) {
						case 'int':
							if (lv_i < 14000) {
								procs[i].vars[j].dir = lv_i++;
							} else {
								alert("Out of memory!");
							}
							break;
						case 'float':
							if (lv_f < 16000) {
								procs[i].vars[j].dir = lv_f++;
							} else {
								alert("Out of memory!");
							}
							break;
						case 'string':
							if (lv_st < 18000) {
								procs[i].vars[j].dir = lv_st++;
							} else {
								alert("Out of memory!");
							}
							break;
						case 'bool':
							if (lv_bool < 19000) {
								procs[i].vars[j].dir = lv_bool++;
							} else {
								alert("Out of memory!");
							}
							break;
					}
				}
			}
		}
	}
	init_dirs();
}

function init_dirs() {
	dir_procs = 2000;

	gv_i = 5000;
	gv_f = 7000;
	gv_st = 9000;
	gv_bool = 11000;

	lv_i = 12000;
	lv_f = 14000;
	lv_st = 16000;
	lv_bool = 18000;

	tv_i = 19000;
	tv_f = 21000;
	tv_st = 23000;
	tv_bool = 25000;
}

function json_to_vars(text) {
	var var_json = '{"variables":['+text+']}';
 	return JSON.parse(var_json).variables;
}

if (typeof(window) !== 'undefined') {
	window.Raptor = Raptor;
} else {
	parser.Raptor = Raptor;
}
