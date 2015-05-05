%lex

%%
\s+								{/* ignore whitespace */;}
"program"						{return 'PROGRAM';}
"function"						{return 'FUNCTION';}
// "-"?[0-9]*"."[0-9]+			{return 'F';}
[0-9]*"."[0-9]+					{return 'F';}
// "-"?[0-9]+					{return 'I';}
[0-9]+							{return 'I';}
"true"|"false"					{return 'B';}
";"								{return ';';}
":"								{return ':';}
"{"								{return '{';}
"}"								{return '}';}
"("								{return '(';}
")"								{return ')';}
"["								{return '[';}
"]"								{return ']';}
"<"								{return '<';}
">"								{return '>';}
"!"								{return '!';}
"="								{return "=";}
"+"								{return "+";}
"-"								{return "-";}
"*"								{return '*';}
"/"								{return '/';}
","								{return ',';}
"&"								{return '&';}
"|"								{return "|";}
"var"							{return 'VAR';}
"int"							{return 'INT';}
"float"							{return 'FLOAT';}
"string"						{return 'STRING';}
"boolean"						{return 'BOOLEAN';}
"void"							{return 'VOID';}
"write"							{return 'WRITE';}
"if"							{return 'IF';}
"else"							{return 'ELSE';}
"while"							{return 'WHILE';}
"return"						{return 'RETURN';}
"assign"						{return 'ASSIGN';}
([a-zA-Z][a-zA-Z0-9]*)(-|_)*([a-zA-Z][a-zA-Z0-9]*)*	{return 'ID';}
\"[^\"]*\"|\'[^\']*\			{return 'S';} // "
<<EOF>>							{return 'EOF';}

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
	: type ID var_array
				{
					var currentScope = scope.stackTop();
					var proc = findProc(yy, currentScope);
					var variable = {
						dir: assignMemory($type, false, false, $var_array),
						id: $ID,
						type: $type,
						dim: $var_array
					}
					proc.vars.push(variable);
				}
	;

var_array
	: "[" I "]"
			{
				$$ = [$I];
			}
	| "[" I "]" "[" I "]"
			{
				$$ = [$2,$5];
			}
	|
			{
				$$ = [];
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
				{
					var main = findProc(yy, "main");
					if (main === "undefined") {
						throw new Error("No main declared. Please declare a void main function.");
						return;
					}
				}
	| EOF
	;

funct
	: function_declaration function_params function_block
				{
					if (scope.stackTop().id !== "main") {
						yy.quads.push(["return", null, null, null]);
					}
				}
	;

function_declaration
	: type ID
				{
					var dir = dirProc();
					var proc = new Proc($ID, $type, dir, [], [], yy.quads.length);
					yy.procs.push(proc);
					scope.push($ID);

					if ($ID === "main")	{
						var jump = jumps.pop();
						yy.quads[jump][3] = yy.quads.length;
						// yy.quads.push(["era", dir, null, null]);
					}
				}
	;

function_params
	: '(' vars_params ')'
	;

function_block
	:  '{' vars block '}'
				{
					if (scope.pop() === "main") {
						return null;
					}
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
						dir: assignMemory($type, false, false, []),
						id: $ID,
						type: $type
					}
					proc.vars.push(variable);
					proc.params.push(variable);
				}
	| ',' type ID
				{
					var currentScope = scope.stackTop();
					var proc = findProc(yy, currentScope);
					var variable = {
						dir: assignMemory($type, false, false, []),
						id: $ID,
						type: $type
					}
					proc.vars.push(variable);
					proc.params.push(variable);
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
	| expression_statute
	;

assignment_statute
	: ASSIGN ID '=' expression ';'
				{
					var var1 = ids.pop();
					var var1t = types.pop();
					var id = $ID;
					var idt = findTypeId(yy, id);
					if (var1t === idt || (var1t === "int" && idt === "float")) {
						var op = yy.quads.push([$3, findDir(yy, var1), null, findDir(yy, id)]);
					} else {
						throw new Error(var1 + " and " + id + " are incompatible types " + var1t + " and " + idt + " for assignment.");
						return;
					}
				}
	;

write_statute
	: WRITE '(' expression ')' ';'
				{
					yy.quads.push(["write", null, null, findDir(yy, ids.pop())]);
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
					if (type === "boolean") {
						yy.quads.push(["gotof", findDir(yy, id), null, null]);
						jumps.push(yy.quads.length - 1);
					} else {
						throw new Error("IF statements need a valid boolean condition.");
						return;
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
	: while_declaration while_condition while_block
				{
					var jump = jumps.pop();
					yy.quads[jump][3] = yy.quads.length;
				}
	;

while_declaration
	: WHILE
				{
					jumps.push(yy.quads.length);
				}
	;

while_condition
	: '(' expression ')'
				{
					var type = types.pop();
					var id = ids.pop();
					if(type === "boolean") {
						yy.quads.push(["gotof", findDir(yy,id), null, null]);
						jumps.push(yy.quads.length - 1);
					} else {
						throw new Error("WHILE statement needs a valid boolean condition.");
						return;
					}
				}
	;

while_block
	: '{' block '}'
				{
					var jump = jumps.pop();
					yy.quads.push(["goto",null,null,jumps.pop()]);
					jumps.push(jump);
				}
	;

return_statute
	: RETURN expression ';'
				{
					proc = findProc(yy, scope.stackTop());
					var id = ids.pop();
					var type = types.pop();
					if (proc.type !== "void" && proc.type === type)	{
						yy.quads.push(["return", null, null, findDir(yy,id)]);
					} else {
						alert("Error!");
					}
				}
	;

expression_statute
	: expression ';'
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
					if (type !== "x") {
						var op = [op, findDir(yy, var1), findDir(yy, var2), findDir(yy, createTemp(yy, type))];
					} else {
						throw new Error("Type " + var1t + " and type " + var2t + " can't be logically compared.");
						return;
					}
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
					if (type !== "x") {
						var op = [op, findDir(yy, var1), findDir(yy, var2), findDir(yy, createTemp(yy, type))];
					} else {
						throw new Error("Type " + var1t + " and type " + var2t + " can't be compared.");
						return;
					}
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
					if (ops.stackTop() === "+" || ops.stackTop() === "-") {
						var var2 = ids.pop();
						var var2t = types.pop();
						var var1 = ids.pop();
						var var1t = types.pop();
						var op = ops.pop();
						var type = validateSem(op, var1t, var2t);
						if(type !== "x") {
							var op = [op, findDir(yy, var1), findDir(yy, var2), findDir(yy, createTemp(yy, type))];
						} else {
							throw new Error("Type " + var1t + " and type " + var2t + " can't be sumed/substracted compared.");
							return;
						}
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
					if (ops.stackTop() === "*" || ops.stackTop() === "/") {
						var var2 = ids.pop();
						var var2t = types.pop();
						var var1 = ids.pop();
						var var1t = types.pop();
						var op = ops.pop();
						var type = validateSem(op, var1t, var2t);
						if (type !== "x") {
							var op = [op, findDir(yy, var1), findDir(yy, var2), findDir(yy, createTemp(yy, type))];
						} else {
							throw new Error("Type " + var1t + " and type " + var2t + " can't be multiplied/divided compared.");
							return;
						}
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
	| id options
	| "(" add_closure expression")"
				{ops.pop();}
	;

id
	: ID
				{
					var proc = findProc(yy, $ID);
					if (proc !== "undefined") {
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

options
	: params
	| array
	|
				{
					if (expectingParams) {
						throw new Error("Need paramters.");
						return;
					}
				}
	;

params
	: "(" find_proc params_input ")"
				{
					if (tempProc.type !== "void") {
						var temp = createTemp(yy, tempProc.type);
						yy.quads.push(["gosub",tempProc.init,null,findDir(yy,temp)]);
					} else {
						yy.quads.push(["gosub",tempProc.init,null,null]);
					}

					ops.pop();
					tempProc = null;
					expectingParams = false;
				}
	;

find_proc
	:
				{
						var id = ids.pop();
						tempProc = findProc(yy, id);
						yy.quads.push(["era",tempProc.dir,null,null]);
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
					if (paramTemp + 1 > tempProc.numParams() || paramTemp + 1 < tempProc.numParams()) {
						throw new Error("Missing parameters for function.");
						return;
					}

					if (tempProc.params[paramTemp].type === type || (tempProc.params[paramTemp].type === "float" && type === "int") ) {
						yy.quads.push(["param", findDir(yy, id), null, ++paramTemp]);
					} else {
						throw new Error("Incorrect parameter types.");
						return;
					}
					// ops.pop();
				}
	;

array
	: "[" expression "]"
	| "[" expression "]""[" expression "]"
	;

add_closure
	:
				{ops.push("|");}
	;


constant
	: I
				{
					yy.consts.push([parseInt($I), assignMemory("int", false, true, [])]);
					types.push("int");
					ids.push(parseInt($I));
				}
	| F
				{
					yy.consts.push([parseFloat($F), assignMemory("float", false, true, [])]);
					types.push("float");
					ids.push(parseFloat($F));
				}
	| B
				{
					yy.consts.push([$B, assignMemory("boolean", false, true, [])]);
					types.push("boolean");
					ids.push($B);
				}
	| S
				{
					yy.consts.push([$S, assignMemory("string", false, true, [])]);
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

var cv_i;
var cv_f;
var cv_st;
var cv_bool;

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

var semanticCube = [
	["v","v","+","-","/","*","==","<","<=",">",">=","&&","||","!="],
	["int","int","int","int","int","int","boolean","boolean","boolean","boolean","boolean","x","x","boolean"],
	["float","float","float","float","float","float","b","b","b","b","b","x","x","boolean"],
	["string","string","string","x","x","x","x","x","x","x","x","x","x","x"],
	["boolean","boolean","x","x","x","x","boolean","x","x","x","x","boolean","boolean","boolean"],
	["int","float","float","float","float","float","boolean","boolean","boolean","boolean","boolean","x","x","boolean"],
	["int","string","x","x","x","x","x","x","x","x","x","x","x","x"],
	["int","boolean","x","x","x","x","x","x","x","x","x","x","x","x"],
	["float","int","float","float","float","float","boolean","boolean","boolean","boolean","boolean","x","x","boolean"],
	["float","string","x","x","x","x","x","x","x","x","x","x","x","x"],
	["float","boolean","x","x","x","x","x","x","x","x","x","x","x","x"],
	["string","int","x","x","x","x","x","x","x","x","x","x","x","x"],
	["string","float","x","x","x","x","x","x","x","x","x","x","x","x"],
	["string","boolean","boolean","x","x","x","x","x","x","x","x","x","x","x"],
	["boolean","int","x","x","x","x","x","x","x","x","x","x","x","x"],
	["boolean","float","x","x","x","x","x","x","x","x","x","x","x","x"],
	["boolean","string","x","x","x","x","x","x","x","x","x","x","x","x"]
];

var temp = 1;
var paramTemp = 1;
var tempProc = null;
var expectingParams = false;

var Japtor = function() {
	var japtorLexer = function () {};
	japtorLexer.prototype = parser.lexer;
	initDirs();
	var japtorParser = function () {
		this.lexer = new japtorLexer();
		this.yy = {
			procs: [],
			quads: [],
			consts: []
			// parseError: function(msg, hash) {
			// 	this.done = true;
			// 	var result = new String();
			// 	result.html = '<pre>' + msg + '</pre>';
			// 	result.hash = hash;
			// 	return result;
			// }
		};
	};
	japtorParser.prototype = parser;
	var newParser = new japtorParser();
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
		var int = 0; var float = 0; var string = 0; var boolean = 0;
		var int_t = 0; var float_t = 0; var string_t = 0; var boolean_t = 0;
		for (var i = 0; i < this.vars.length; i++) {
			if (this.vars[i].id.indexOf("tmp__") > -1) {
				switch (this.vars[i].type) {
					case 'int':
						int_t++;
						break;
					case 'float':
						float_t++;
						break;
					case 'string':
						string_t++;
						break;
					case 'boolean':
						boolean_t++;
						break;
				}
			} else {
				switch (this.vars[i].type) {
					case 'int':
						int++;
						break;
					case 'float':
						float++;
						break;
					case 'string':
						string++;
						break;
					case 'boolean':
						boolean++;
						break;
				}
			}
		}
		return [int, float, string, boolean, int_t, float_t, string_t, boolean_t];
	},
	dirs : function() {
		var int = 0; var float = 0; var string = 0; var boolean = 0;
		var int_t = 0; var float_t = 0; var string_t = 0; var boolean_t = 0;
		for (var i = 0; i < this.vars.length; i++) {
			if (this.vars[i].id.indexOf("tmp__") > -1) {
				switch (this.vars[i].type) {
					case 'int':
						if(int_t === 0)
							int_t = this.vars[i].dir;
						break;
					case 'float':
						if(float_t === 0)
							float_t = this.vars[i].dir;
						break;
					case 'string':
						if(string_t === 0)
							string_t = this.vars[i].dir;
						break;
					case 'boolean':
						if(boolean_t === 0)
							boolean_t = this.vars[i].dir;
						break;
				}
			} else {
				switch (this.vars[i].type) {
					case 'int':
						if(int === 0)
							int = this.vars[i].dir;
						break;
					case 'float':
						if(float === 0)
							float = this.vars[i].dir;
						break;
					case 'string':
						if(string === 0)
							string = this.vars[i].dir;
						break;
					case 'boolean':
						if(boolean === 0)
							boolean = this.vars[i].dir;
						break;
				}
			}
		}
		return [int, float, string, boolean, int_t, float_t, string_t, boolean_t];
	},
	numParams : function() {
		return this.params.length;
	}
}

function dirProc() {
	if (dirProcs < 5000) {
		return dirProcs++;
	} else {
		alert("Out of memory.");
	}
}

function assignMemory(type, tmp, cons, dim) {

	var pointer = 1;
	var temp = null;

	var isGlobal = false;
	if (scope.stackTop() === "global") {
		isGlobal = true;
	}

	if (dim.length == 2) {
		pointer = parseInt(dim[0]) * parseInt(dim[1]);
	} else if (dim.length == 1) {
		pointer = parseInt(dim[0]);
	}

	if (tmp) {
		switch (type) {
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
	} else if (cons) {
		switch (type) {
			case 'int':
				if (cv_i < 28000) {
					return cv_i++;
				} else {
					alert("Out of memory!");
				}
				break;
			case 'float':
				if (cv_f < 30000) {
					return cv_f++;
				} else {
					alert("Out of memory!");
				}
				break;
			case 'string':
				if (cv_st < 32000) {
					return cv_st++;
				} else {
					alert("Out of memory!");
				}
				break;
			case 'boolean':
				if (cv_bool < 33000) {
					return cv_bool++;
				} else {
					alert("Out of memory!");
				}
				break;
		}
	} else {
		if (isGlobal) {
			switch (type) {
				case 'int':
					if (gv_i < 7000) {
						temp = gv_i;
						gv_i = gv_i + pointer;
						return temp;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'float':
					if (gv_f < 9000) {
						temp = gv_f;
						gv_f = gv_f + pointer;
						return temp;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'string':
					if (gv_st < 11000) {
						temp = gv_st;
						gv_st = gv_st + pointer;
						return temp;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'boolean':
					if (gv_bool < 12000) {
						temp = gv_bool;
						gv_bool = gv_bool + pointer;
						return temp;
					} else {
						alert("Out of memory!");
					}
					break;
			}
		} else {
			switch (type) {
				case 'int':
					if (lv_i < 14000) {
						temp = lv_i;
						lv_i = lv_i + pointer;
						return temp;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'float':
					if (lv_f < 16000) {
						temp = lv_f;
						lv_f = lv_f + pointer;
						return temp;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'string':
					if (lv_st < 18000) {
						temp = lv_st;
						lv_st = lv_st + pointer;
						return temp;
					} else {
						alert("Out of memory!");
					}
					break;
				case 'boolean':
					if (lv_bool < 19000) {
						temp = lv_bool;
						lv_bool = lv_bool + pointer;
						return temp;
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

	cv_i = 26000;
	cv_f = 28000;
	cv_st = 30000;
	cv_bool = 32000;
}

function validateSem(op, var1, var2) {
		for (var i = 0; i < semanticCube.length; i++) {
			if (semanticCube[i][0] === var1 && semanticCube[i][1] === var2) {
				for (var j = 0; j < semanticCube[0].length; j++) {
					if (semanticCube[0][j] === op)
						return semanticCube[i][j];
				}
			}
		}
}

function findTypeId(yy, id) {
	var currentScope = scope.stackTop();
	var proc = findProc(yy, currentScope);

	for (var i = 0; i < proc.vars.length; i++) {
		if (proc.vars[i].id === id) {
			return proc.vars[i].type;
		}
	}

	proc = findProc(yy, "global");
	for(var i = 0; i < proc.vars.length; i++) {
		if(proc.vars[i].id === id) {
			return proc.vars[i].type;
		}
	}

	alert("ID not declared.");
}

function findProc(yy, name) {
	for (var i = 0; i < yy.procs.length; i++) {
		if (yy.procs[i].name === name) {
			return yy.procs[i];
		}
	}

	return "undefined";
}

function createTemp(yy, type) {
	var currentScope = scope.stackTop();
	var proc = findProc(yy, currentScope);

	var tmp = {
		dir: assignMemory(type, true, false, []),
		id: "tmp__"+temp,
		type: type
	}

	ids.push(tmp.id);
	types.push(tmp.type);
	temp++;

	proc.vars.push(tmp);

	return tmp.id;
}

function findDir(yy, id) {
	// return id;
	var currentScope = scope.stackTop();
	var proc = findProc(yy, currentScope);

	for (var i = 0; i < proc.vars.length; i++) {
		if (proc.vars[i].id === id) {
			return proc.vars[i].dir;
		}
	}

	proc = findProc(yy, "global");
	for (var i = 0; i < proc.vars.length; i++) {
		if (proc.vars[i].id === id) {
			return proc.vars[i].dir;
		}
	}

	for (var i = 0; i < yy.consts.length; i++) {
		if(yy.consts[i][0] === id) {
			return yy.consts[i][1];
		}
	}

	alert("ID not declared.");
	return "undefined";
}

if (typeof(window) !== 'undefined') {
	window.Japtor = Japtor;
} else {
	parser.Japtor = Japtor;
}
