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
","											{return ',';}
"&"											{return '&';}
"|"											{return "|";}
"var"										{return 'VAR';}
"int"										{return 'INT';}
"float"									{return 'FLOAT';}
"string"								{return 'STRING';}
"boolean"								{return 'BOOL';}
"void"									{return 'VOID';}
"write"									{return 'WRITE';}
"if"										{return 'IF';}
"else"									{return 'ELSE';}
"while"									{return 'WHILE';}
[0-9]*"."[0-9]+					{return 'F';}
[0-9]+									{return 'I';}
"true"|"false"					{return 'B';}
([a-zA-Z][a-zA-Z0-9]*)(-|_)*([a-zA-Z][a-zA-Z0-9]*)*	{return 'ID';}
\"[^\"]*\"|\'[^\']*\		{return 'S';}
// """ hack
<<EOF>>									{return 'EOF';}

/lex

%start program

%%

program
	: EOF
				{return null;}
	| PROGRAM ID ';' program_init program_code
	;

program_init
	:
				{
					var proc = new Proc("global", "void", dirProc(), [], []);
					yy.procs.push(proc);
					// assignMemory(yy.procs);
					scope.push("global");
				}
	;

program_code
	: vars functions
	;

vars
	: VAR var_init vars ';' vars
	| ',' var_init vars
	|
	;

var_init
	: type ID
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
	;

vars_params
	: vars_params_init vars_params
	|
	;

vars_params_init
	: type ID
				{
					var currentScope = scope.stackTop();
					var proc = findProc(yy, currentScope);
					var variable = {
						dir: assignMemory($type, false),
						id: $ID,
						type: $type
					}
					proc.vars.push(variable);
					proc.params.push($type);
				}
	| ',' type ID
				{
					var currentScope = scope.stackTop();
					var proc = findProc(yy, currentScope);
					var variable = {
						dir: assignMemory($type, false),
						id: $ID,
						type: $type
					}
					proc.vars.push(variable);
					proc.params.push($type);
				}
	;

type
	: INT
	| FLOAT
	| STRING
	| BOOL
	| VOID
	;

functions
	: funct ';' functions
	| EOF
	;

funct
	: FUNCTION funct_init params
	|
	;

funct_init
	: type ID
				{
					var proc = new Proc($ID, $type, dirProc(), [], []);
					yy.procs.push(proc);
					scope.push($ID);
				}
	;

params
	: '(' vars_params ')' '{' vars funct_code
	;

funct_code
	:  block '}' funct_end
	;

funct_end
	:
				{
					scope.pop();
				}
	;

block
	: statutes
	;

statutes
	: statute statutes
	|
	;

statute
	: assignment
	| write
	| if_
	| while_
	;

assignment
	: ID '=' expression ';'
				{
					var var1 = ids.pop();
					var var1t = types.pop();
					var id = $ID;
					var idt = findTypeId(yy, id);
					if(var1t == idt || (var1t == "int" && idt == "float"))
						var op = yy.quads.push([$2, var1, "", id]);
					else
						alert("Error in semantics.");;
				}
	;

write
	: WRITE '(' expression ')' ';'
				{
					yy.quads.push(["write", "", "", ids.pop()]);
				}
	;

if_
	: IF if_condition '{' block '}' else_
	;

if_condition
	: '(' expression ')'
				{
					var type = types.pop();
					if(type == "boolean") {
						yy.quads.push(["gotof", ids.pop(), "", ""]);
						jumps.push(yy.quads.length - 1);
					} else {
						alert("Error!");
					}
				}
	;

else_
	: else_code '{' block '}' ';'
				{
					var jump = jumps.pop();
					yy.quads[jump][3] = yy.quads.length;
				}
 	| ';'
				{
					var jump = jumps.pop();
					yy.quads[jump][3] = yy.quads.length;
				}
	;

else_code
	: ELSE
				{
					var jump = jumps.pop();
					yy.quads.push(["goto", "", "", ""]);
					yy.quads[jump][3] = yy.quads.length;
					jumps.push(yy.quads.length - 1);
				}
	;

while_
	: WHILE while_condition '{' block '}' ';'
				{
					var jump = jumps.pop();
					yy.quads[jump][3] = yy.quads.length;
				}
	;

while_condition
	: '(' expression ')'
				{
					var type = types.pop();
					if(type == "boolean") {
						yy.quads.push(["gotof", ids.pop(), "", ""]);
						jumps.push(yy.quads.length - 1);
					} else {
						alert("Error!");
					}
				}
	;

expression
	: comp
	| comp logical_ops comp
				{
					var var2 = ids.pop();
					var var2t = types.pop();
					var var1 = ids.pop();
					var var1t = types.pop();
					var op = ops.pop();
					var type = validateSem(op, var1t, var2t);
					if(type != "x")
						var op = [op, var1, var2, createTemp(yy, type)];
					else
						alert("Error in semantics.");
					yy.quads.push(op);
				}
	;

logical_ops
	: '&' '&'
				{
					ops.push("&&");
				}
	| '|' '|'
				{
					ops.push("||");
				}
	;

comp
	: exp
	| exp comparison_ops exp
				{
					var var2 = ids.pop();
					var var2t = types.pop();
					var var1 = ids.pop();
					var var1t = types.pop();
					var op = ops.pop();
					var type = validateSem(op, var1t, var2t);
					if(type != "x")
						var op = [op, var1, var2, createTemp(yy, type)];
					else
						alert("Error in semantics.");
					yy.quads.push(op);
				}
	;

comparison_ops
	: '<' '='
				{
					ops.push("<=");
				}
	| '>' '='
				{
					ops.push(">=");
				}
	| '!' '='
				{
					ops.push("!=");
				}
	| '=' '='
				{
					ops.push("==");
				}
	| '>'
				{
					ops.push(">");
				}
	| '<'
				{
					ops.push("<");
				}
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
							alert("Error in semantics.");
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
	| ID params_exp
				{
					ids.push($1);
					types.push(findTypeId(yy, $1));
				}
	| "(" add_closure expression")"
				{
					ops.pop();
				}
	;

params_exp
	: "(" expression ")"
	|
	;

add_closure
	:
				{
					ops.push("|");
				}
	;


value
	: I
				{
					types.push("int");
					ids.push($I);
				}
	| F
				{
					types.push("float");
					ids.push($F);
				}
	| B
				{
					types.push("boolean");
					ids.push($B);
				}
	| S
				{
					types.push("string");
					ids.push($S);
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
var jumps = new dataStructures.stack()

// falta !=
var semanticCube = [
											["v",	"v",	"+",	"-",	"/",	"*",	"==",	"<",	"<=",	">",	">=",	"&&",	"||"],
										 	["int",	"int", 	"int", 	"int", 	"int", 	"int", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"x", 	"x"],
											["float", "float", 	"float", 	"float", 	"float", 	"float", 	"b", 	"b", 	"b", 	"b", 	"b", 	"x", 	"x"],
											["string", "string", 	"string", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["boolean", "boolean", 	"x", 	"x", 	"x", 	"x", 	"boolean", 	"x", 	"x", 	"x", 	"x", 	"boolean", 	"boolean"],
											["int", "float", 	"float", 	"float", 	"float", 	"float", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"x", 	"x"],
											["int", "string", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["int", "boolean", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["float", "int", 	"float", 	"float", 	"float", 	"float", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"x", 	"x"],
											["float", "string", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["float", "boolean", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["string", "int", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["string", "float", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["string", "boolean", 	"boolean", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["boolean", "int", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["boolean", "float", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
											["boolean", "string", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x"],
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
	if (scope.stackTop() == "global") {
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
			case 'boolean':
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
				case 'boolean':
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
				case 'boolean':
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

function findTypeId(yy, id) {
	var currentScope = scope.stackTop();
	var proc = findProc(yy, currentScope);
	for(var i = 0; i < proc.vars.length; i++)
		if(proc.vars[i].id == id)
			return proc.vars[i].type;

	proc = findProc(yy, "global");
	for(var i = 0; i < proc.vars.length; i++)
		if(proc.vars[i].id == id)
			return proc.vars[i].type;

	alert("ID not declared.");
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
		dir: assignMemory(type, true),
		name: "tmp__"+temp,
		type: type
	}

	ids.push(tmp.name);
	types.push(tmp.type);
	temp++;

	proc.vars.push(tmp);

	return tmp.name;
}

if (typeof(window) !== 'undefined') {
	window.Raptor = Raptor;
} else {
	parser.Raptor = Raptor;
}
