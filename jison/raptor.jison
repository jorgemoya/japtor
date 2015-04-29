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
"<"											{return '<';}
">"											{return '>';}
"!"											{return '!';}
"="											{return "=";}
"+"											{return "+";}
"-"											{return "-";}
"*"											{return '*';}
"/"											{return '/';}
"&&"										{return '&&';}
"||"										{return "||";}
"var"										{return 'VAR';}
"int"										{return 'INT';}
"float"									{return 'FLOAT';}
"string"								{return 'STRING';}
"bool"									{return 'BOOL';}
[0-9]*"."[0-9]+					{return 'F';}
[0-9]+									{return 'I';}
([a-zA-Z][a-zA-Z0-9]*)(-|_)*([a-zA-Z][a-zA-Z0-9]*)*	{return 'ID';}
<<EOF>>									{return 'EOF';}

/lex

%start program

%%

program
	: EOF
				{return null;}
	| PROGRAM ID ';' program_init variables
	;

program_init
	:
				{
					var proc = new Proc("main", "void", dirProc(), [], []);
					yy.procs.push(proc);
					// assignMemory(yy.procs);
					scope.push("main");
				}
	;

variables
	: vars functions
	;

vars
	: VAR type ID ';' vars
				{
					var currentScope = scope.stackTop();
					var proc = findProc(yy, currentScope);
					var variable = {
						dir: assignMemory($type, false),
						id: $ID,
						type: $type
					}
					proc.vars.push(variable);
				}
	|
	;

type
	: INT
	| FLOAT
	| STRING
	| BOOL
	;

functions
	: funct block ';' EOF
	;

funct
	: FUNCTION type ID funct_init params
				{
					// var json;
					// if ($5 === "" || $7 === "")
					// 	json = $5 + $7;
					// else
					// 	json = $5 + "," + $7;
					//
					// var vars = json_to_vars($5);
					// var paramTypes = [];
					//
					// for(var i = 0; i < vars.length; i++) {
					// 	paramTypes.push(vars[i].type);
					// }
					//
					// var proc = new Proc($3, $2, dirProc(), paramTypes, json_to_vars(json));
					// yy.procs.push(proc);
				}
	|
	;

funct_init
	:
				{

				}
	;

params
	: '(' vars ')' vars block ';' funct
	;

block
	: '{' statutes '}'
	;

statutes
	: statute statutes
	|
	;

statute
	: assignment
	;

assignment
	: ID '=' expression ';'
				{
					yy.quads.push($2, ids.pop(), "", $1);
				}
	;

expression
	: exp
	| exp comparison
	;

comparison
	: '<' '=' exp
	| '>' '=' exp
	| '!' '=' exp
	| '=' '=' exp
	;

exp
	: term end_exp
	;

end_exp
	: validation_exp plusminus exp
	|	validation_exp
	;

validation_exp
	:
				{
					if (ops.stackTop() == "+" || ops.stackTop() == "-") {
						var var2 = ids.pop();
						var var2t = types.pop();
						var var1 = ids.pop();
						var var1t = types.pop();
						var op = ops.pop();
						var type = validateSem(op, var1t, var2t);
						if(type != "x")
							var op = [op, var1, var2, createTemp(yy, type)];
						else
							alert("Error in semantics.");;
						yy.quads.push(op);
					}
				}
	;

plusminus
	: '+'
				{
					ops.push($1);
				}
	| '-'
				{
					ops.push($1);
				}
	| '||'
	;

term
	: factor end_term
	;

end_term
	: validation_term multidivi term
	| validation_term
	;

validation_term
	:
				{
					if (ops.stackTop() == "*" || ops.stackTop() == "/") {
						var var2 = ids.pop();
						var var2t = types.pop();
						var var1 = ids.pop();
						var var1t = types.pop();
						var op = ops.pop();
						var type = validateSem(op, var1t, var2t);
						if(type != "x")
							var op = [op, var1, var2, createTemp(yy, type)];
						else
							alert("Error in semantics.");;
						yy.quads.push(op);
					}
				}
	;

multidivi
	: '*'
			{
				ops.push($1);
			}
	| '/'
			{
				ops.push($1);
			}
	| '&&'
	;

factor
	: value
				{
					ids.push($1);
				}
	| ID
				{
					ids.push($1);
					types.push(findTypeId($1));
				}
	;

value
	: I
				{
					types.push("i");
				}
	| F
				{
					types.push("f");
				}
	;

%%

var dirProcs;

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

initDirs();

var dataStructures = {
    stack : function() {
        var elements = [];

        this.push = function(element) {
            elements.push(element);
        }
        this.pop = function() {
            return elements.pop();
        }
        this.stackTop = function(element) {
            return elements[elements.length - 1];
        }
    }
}

var ids = new dataStructures.stack();
var types = new dataStructures.stack();
var ops = new dataStructures.stack();
var scope = new dataStructures.stack();

var semanticCube = [
											["v",	"v",	"+",	"-",	"/",	"*",	"==",	"<",	"<=",	">",	">=",	"&&",	"||"],
										 	["i",	"i", 	"i", 	"i", 	"i", 	"i", 	"b", 	"b", 	"b", 	"b", 	"b", 	"x", 	"x"],
											["f", "f", 	"f", 	"f", 	"f", 	"f", 	"b", 	"b", 	"b", 	"b", 	"b", 	"x", 	"x"],
											["s", "s", 	"s", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["b", "b", 	"x", 	"x", 	"x", 	"x", 	"b", 	"x", 	"x", 	"x", 	"x", 	"b", 	"b"],
											["i", "f", 	"f", 	"f", 	"f", 	"f", 	"b", 	"b", 	"b", 	"b", 	"b", 	"x", 	"x"],
											["i", "s", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["i", "b", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["f", "i", 	"f", 	"f", 	"f", 	"f", 	"b", 	"b", 	"b", 	"b", 	"b", 	"x", 	"x"],
											["f", "s", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["f", "b", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["s", "i", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["s", "f", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["s", "b", 	"b", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["b", "i", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["b", "f", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["b", "s", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
										];

var temp = 1;

var Raptor = function() {
	var raptorLexer = function () {};
	raptorLexer.prototype = parser.lexer;

	var raptorParser = function () {
		this.lexer = new raptorLexer();
		this.yy = {
			procs: [],
			quads: []
			// parseError: function(msg, hash) {
			// 	this.done = true;
			// 	var result = new String();
			// 	result.html = '<pre>' + msg + '</pre>';
			// 	result.hash = hash;
			// 	return result;
			// }
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
	},
	numParams : function() {
		return this.params.length;
	}
}

function dirProc() {
	if(dirProcs < 5000)
		return dirProcs++;
	else
		alert("Out of memory.");
}

function assignMemory(type, tmp) {

	var isGlobal = false;
	if (scope.stackTop() == "main") {
		isGlobal = true;
	}

	if (tmp) {
		switch(type) {
			case 'int':
				if (tv_i < 21000) {
					return tv_i++;
				} else {
					alert("Out of memory!");
				}
				break;
			case 'float':
				if (tv_f < 23000) {
					return tv_f++;
				} else {
					alert("Out of memory!");
				}
				break;
			case 'string':
				if (tv_st < 25000) {
					return tv_st++;
				} else {
					alert("Out of memory!");
				}
				break;
			case 'bool':
				if (tv_bool < 26000) {
					return tv_bool++;
				} else {
					alert("Out of memory!");
				}
				break;
		}
	} else {
		if(isGlobal) {
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
		} else {
			switch(type) {
				case 'int':
					if (lv_i < 14000) {
						return lv_i++;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'float':
					if (lv_f < 16000) {
						return lv_f++;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'string':
					if (lv_st < 18000) {
						return lv_st++;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'bool':
					if (lv_bool < 19000) {
						return lv_bool++;
					} else {
						alert("Out of memory!");
					}
					break;
			}
		}
	}
}

function initDirs() {
	dirProcs = 2000;

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

function validateSem(op, var1, var2) {
		for (var i = 0; i < semanticCube.length; i++) {
			if(semanticCube[i][0] == var1 && semanticCube[i][1] == var2) {
				for (var j = 0; j < semanticCube[0].length; j++) {
					if(semanticCube[0][j] == op)
						return semanticCube[i][j];
				}
			}
		}
}

function findTypeId(id) {

}

function findProc(yy, name) {
	for (var i = 0; i < yy.procs.length; i++) {
		if (yy.procs[i].name == name)
			return yy.procs[i];
	}
}

function createTemp(yy, type) {
	var currentScope = scope.stackTop();
	var proc = findProc(yy, currentScope);

	var tmp = {
		dir: 0,
		name: "tmp__"+temp,
		type: type
	}

	ids.push(tmp.name);
	types.push(tmp.type);
	temp++;

	if(tmp.type == "i")
		tmp.type = "int";
	else if (tmp.type == "f")
	tmp.type = "float";
	else if (tmp.type == "s")
	tmp.type = "string";
	else if (tmp.type == "b")
		tmp.type = "boolean";

	tmp.dir = assignMemory(tmp.type, true);

	proc.vars.push(tmp);

	return tmp.name;
}

if (typeof(window) !== 'undefined') {
	window.Raptor = Raptor;
} else {
	parser.Raptor = Raptor;
}
