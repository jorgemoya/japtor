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
"boolean"								{return 'BOOLEAN';}
"void"									{return 'VOID';}
"write"									{return 'WRITE';}
"if"										{return 'IF';}
"else"									{return 'ELSE';}
"while"									{return 'WHILE';}
"return"								{return 'RETURN';}
[0-9]*"."[0-9]+					{return 'F';}
[0-9]+									{return 'I';}
"true"|"false"					{return 'B';}
([a-zA-Z][a-zA-Z0-9]*)(-|_)*([a-zA-Z][a-zA-Z0-9]*)*	{return 'ID';}
\"[^\"]*\"|\'[^\']*\		{return 'S';} // null"
<<EOF>>									{return 'EOF';}

/lex

%start program

%%

program
	: EOF
				{return null;}
	| program_declaration program_block
	;

program_declaration
	: PROGRAM ID ';'
				{
					var proc = new Proc("global", "void", dirProc(), [], [], null);
					yy.procs.push(proc);
					scope.push("global");
					yy.quads.push(["goto", null, null, null]);
					jumps.push(yy.quads.length - 1);
				}
	;

program_block
	: vars functions
	;

vars
	: VAR var_declaration vars ';' vars
	| ',' var_declaration vars
	|
	;

var_declaration
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

type
	: INT
	| FLOAT
	| STRING
	| BOOLEAN
	| VOID
	;

functions
	: FUNCTION funct functions
	| EOF
	;

funct
	: function_declaration function_params function_block
	;

function_declaration
	: type ID
				{
					var proc = new Proc($ID, $type, dirProc(), [], [], yy.quads.length);
					yy.procs.push(proc);
					scope.push($ID);

					if($ID == "main")	{
						var jump = jumps.pop();
						yy.quads[jump][3] = yy.quads.length;
						yy.quads.push(["era", $ID, null, null]);
					}
				}
	;

function_params
	: '(' vars_params ')'
	;

function_block
	:  '{' vars block '}'
				{
					if(scope.pop() == "main")
					 	return null;
				}
	;

vars_params
	: vars_params_declaration vars_params
	|
	;

vars_params_declaration
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

block
	: statutes
	;

statutes
	: statute statutes
	|
	;

statute
	: assignment_statute
	| write_statute
	| if_statute
	| while_statute
	| return_statute
	;

assignment_statute
	: ID '=' expression ';'
				{
					var var1 = ids.pop();
					var var1t = types.pop();
					var id = $ID;
					var idt = findTypeId(yy, id);
					if(var1t == idt || (var1t == "int" && idt == "float"))
						var op = yy.quads.push([$2, var1, null, id]);
					else
						alert("Error in semantics.");;
				}
	;

write_statute
	: WRITE '(' expression ')' ';'
				{
					yy.quads.push(["write", null, null, ids.pop()]);
				}
	;

if_statute
	: IF if_condition if_block else_statute
	;

if_condition
	: '(' expression ')'
				{
					var type = types.pop();
					var id = ids.pop();
					if(type == "boolean") {
						yy.quads.push(["gotof", id, null, null]);
						jumps.push(yy.quads.length - 1);
					} else {
						alert("Error!");
					}
				}
	;

if_block
	: '{' block '}'
	;

else_statute
	: else_declaration else_block
 	|
				{
					var jump = jumps.pop();
					yy.quads[jump][3] = yy.quads.length;
				}
	;

else_declaration
	: ELSE
				{
					var jump = jumps.pop();
					yy.quads.push(["goto", null, null, null]);
					yy.quads[jump][3] = yy.quads.length;
					jumps.push(yy.quads.length - 1);
				}
	;

else_block
	: '{' block '}'
				{
					var jump = jumps.pop();
					yy.quads[jump][3] = yy.quads.length;
				}
	;

while_statute
	: WHILE while_condition while_block
				{
					var jump = jumps.pop();
					yy.quads[jump][3] = yy.quads.length;
				}
	;

while_condition
	: '(' expression ')'
				{
					var type = types.pop();
					var id = ids.pop();
					if(type == "boolean") {
						yy.quads.push(["gotof", id, null, null]);
						jumps.push(yy.quads.length - 1);
					} else {
						alert("Error!");
					}
				}
	;

while_block
	: '{' block '}'
	;

return_statute
	: RETURN expression ';'
				{
					proc = findProc(yy, scope.stackTop());
					var id = ids.pop();
					var type = types.pop();
					if (proc.type != "void" && proc.type == type)	{
						yy.quads.push(["return", null, null, id]);
					} else {
						alert("Error!");
					}
				}
	;

expression
	: comparison
	| comparison logical_ops comparison
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
				{ops.push("&&");}
	| '|' '|'
				{ops.push("||");}
	;

comparison
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
				{ops.push("<=");}
	| '>' '='
				{ops.push(">=");}
	| '!' '='
				{ops.push("!=");}
	| '=' '='
				{ops.push("==");}
	| '>'
				{ops.push(">");}
	| '<'
				{ops.push("<");}
	;

exp
	: term exp_exit
	;

exp_exit
	: exp_validation sum_or_minus exp
	|	exp_validation
	;

exp_validation
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

sum_or_minus
	: '+'
				{ops.push($1);}
	| '-'
				{ops.push($1);}
	;

term
	: factor term_exit
	;

term_exit
	: term_validation mult_or_divi term
	| term_validation
	;

term_validation
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

mult_or_divi
	: '*'
			{ops.push($1);}
	| '/'
			{ops.push($1);}
	;

factor
	: constant
	| id params
	| "(" add_closure expression")"
				{ops.pop();}
	;

id
	: ID
				{
					var proc = findProc(yy, $ID);
					if(proc !== "undefined") {
						ids.push($ID);
						types.push(proc.type);
						expectingParams = true;
					} else {
						ids.push($ID);
						types.push(findTypeId(yy, $ID));
						expectingParams = false;
					}
				}
	;

params
	: "(" find_proc params_input ")"
				{
					if (paramTemp > tempProc.numParams() || paramTemp < tempProc.numParams())
						alert("Not the correct number of params");

					if (tempProc.type != "void") {
						var temp = createTemp(yy, tempProc.type);
						yy.quads.push(["gosub",tempProc.name,null,temp]);
					} else {
						yy.quads.push(["gosub",tempProc.name,null,null]);
					}

					ops.pop();
					tempProc = null;
					expectingParams = false;
				}
	|
				{
					if(expectingParams)
						alert("Error expecting params");
				}
	;

find_proc
	:
				{
						var id = ids.pop();
						yy.quads.push(["era",id,null,null]);
						tempProc = findProc(yy, id);
						types.pop();
						ops.push("|");
						paramTemp = 0;
				}
	;

params_input
	: param_expression
	|	param_expression ',' params_input
	|
	;

param_expression
	: expression
				{
					var id = ids.pop();
					var type = types.pop();
					if(tempProc.params[paramTemp] == type || (tempProc.params[paramTemp] == "float" && type == "int") )
						yy.quads.push(["param", id, null, ++paramTemp]);
					else
						alert("Error in param");
					// ops.pop();
				}
	;

add_closure
	:
				{ops.push("|");}
	;


constant
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
											["v",	"v",	"+",	"-",	"/",	"*",	"==",	"<",	"<=",	">",	">=",	"&&",	"||", "!="],
										 	["int",	"int", 	"int", 	"int", 	"int", 	"int", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"x", 	"x", "boolean"],
											["float", "float", 	"float", 	"float", 	"float", 	"float", 	"b", 	"b", 	"b", 	"b", 	"b", 	"x", 	"x", "boolean"],
											["string", "string", 	"string", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["boolean", "boolean", 	"x", 	"x", 	"x", 	"x", 	"boolean", 	"x", 	"x", 	"x", 	"x", 	"boolean", 	"boolean", "boolean"],
											["int", "float", 	"float", 	"float", 	"float", 	"float", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"x", 	"x", "boolean"],
											["int", "string", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["int", "boolean", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["float", "int", 	"float", 	"float", 	"float", 	"float", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"boolean", 	"x", 	"x", "boolean"],
											["float", "string", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["float", "boolean", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["string", "int", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["string", "float", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["string", "boolean", 	"boolean", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["boolean", "int", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["boolean", "float", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
											["boolean", "string", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", 	"x", "x"],
										];

var temp = 1;
var paramTemp = 1;
var tempProc = null;
var expectingParams = false;

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

function Proc(name, type, dir, params, vars, init){
	this.name = name;
	this.type = type;
	this.dir = dir;
	this.params = params;
	this.vars = vars;
	this.init = init;
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
	// for(var i = 0; i < yy.procs.length; i++) {
	// 	if(id == yy.procs[i].name) {
	// 		yy.quads.push(["era", id,null,null]);
	// 		return yy.procs[i].type;
	// 	}
	// }

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

	return "undefined";
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
