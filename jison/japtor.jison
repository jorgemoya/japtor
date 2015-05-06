/*****
	Japtor
	Developed by Jorge Moya
*****/

/**
	Lexical Rules
**/

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


/**
	Token to start program
**/

%start program

%%

program
	: EOF
				{return null;}
	| program_declaration program_block
	;

/**
	PRORGRAM
**/

program_declaration
	: PROGRAM ID ';'
				{
					var proc = new Proc("global", "void", dirProc(), [], [], null); // Creates global proc
					yy.procs.push(proc); // Pushes scope to procs
					scope.push("global"); // Makes global current scope
					yy.quads.push(["goto", null, null, null]); // Expects goto main
					jumps.push(yy.quads.length - 1); // Expects main return
				}
	;

program_block
	: vars functions
	;

/**
	VARS
**/

vars
	: VAR var_declaration vars ';' vars
	| ',' var_declaration vars
	|
	;

var_declaration
	: type ID var_array
				{
					var currentScope = scope.stackTop(); // Looks for scope (global, main, function1..)
					var proc = findProc(yy, currentScope); // Finds current process
					var variable = {
						dir: assignMemory($type, false, false, $var_array), // Assigns memory depending on type and if is an array
						id: $ID,
						type: $type,
						dim: $var_array // Array with dimensions of array or empty
					}
					proc.vars.push(variable); // Pushes to process
				}
	;

var_array
	: "[" I "]"
			{
				yy.consts.push([parseInt($I), assignMemory("int", false, true, [])]); // Adds I to constants

				// Pushes I to stacks
				types.push("int");
				ids.push(parseInt($I));

				$$ = [$I]; // Returns an array with I for var_declaration
			}
	| "[" I "]" "[" I "]"
			{
				yy.consts.push([parseInt($2), assignMemory("int", false, true, [])]); // Adds I to constants
				// Pushes I to stacks
				types.push("int");
				ids.push(parseInt($2)); // Returns an array with I for var_declaration

				yy.consts.push([parseInt($5), assignMemory("int", false, true, [])]); // Adds I to constants
				// Pushes I to stacks
				types.push("int");
				ids.push(parseInt($5)); // Returns an array with I for var_declaration
				$$ = [$2,$5];
			}
	|
			{
				$$ = []; // Returns an empty array
			}
	;

/**
	TYPE
**/

type
	: INT
	| FLOAT
	| STRING
	| BOOLEAN
	| VOID
	;

/**
	FUNCTION
**/

functions
	: FUNCTION funct functions
				{
					// After the creation of all functions, if no main was declared, return error.
					var main = findProc(yy, "main");
					if (main === "undefined") {
						throw new Error("NO MAIN DECLARED.");
					}
				}
	| EOF
	;

funct
	: function_declaration function_params function_block
				{
					// Functions always generate a return unless main
					if (scope.stackTop().id !== "main") { // Scope is a stack with functions
						yy.quads.push(["return", null, null, null]);
					}
				}
	;

function_declaration
	: type ID
				{
					var dir = dirProc(); // Returns the next avaiable Proc dir
					var proc = new Proc($ID, $type, dir, [], [], yy.quads.length); // Created a new Process with ID, type, and dir
					yy.procs.push(proc); // Pushes to procs array
					scope.push($ID); // Pushes to scope stack

					// If id == main, returns the position of the quads for the initial goto
					if ($ID === "main")	{
						var jump = jumps.pop();
						yy.quads[jump][3] = yy.quads.length;
					}
				}
	;

function_params
	: '(' vars_params ')'
	;

function_block
	:  '{' vars block '}'
				{
					// Main must be the last declared function. No other function will run after main.
					if (scope.pop() === "main") {
						return null;
					}
				}
	;

/**
	FUNCTION PARAMS
**/

vars_params
	: vars_params_declaration vars_params
	|
	;

vars_params_declaration
	: type ID var_array
				{
					var currentScope = scope.stackTop(); // Looks for scope (global, main, function1..)
					var proc = findProc(yy, currentScope); // Finds current process
					var variable = {
						dir: assignMemory($type, false, false, $var_array), // Assigns memory depending on type and if is an array
						id: $ID,
						type: $type,
						dim: $var_array // Array with dimensions of array or empty
					}
					proc.vars.push(variable); // Pushes to process vars
					proc.params.push(variable); // Pushes to params to know it is a param
				}
	| ',' type ID var_array
				{
					var currentScope = scope.stackTop(); // Looks for scope (global, main, function1..)
					var proc = findProc(yy, currentScope); // Finds current process
					var variable = {
						dir: assignMemory($type, false, false, $var_array), // Assigns memory depending on type and if is an array
						id: $ID,
						type: $type,
						dim: $var_array  // Array with dimensions of array or empty
					}
					proc.vars.push(variable); // Pushes to process vars
					proc.params.push(variable); // Pushes to params to know it is a param
				}
	;

/**
	BLOCK
**/

block
	: statutes
	;

/**
	STATUTES
**/

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

/**
	ASSIGNMENT
**/

assignment_statute
	: ASSIGN ID '=' expression ';'
				{
					var var1 = ids.pop(); // Pops from stack expression id
					var var1t = types.pop(); // Pops from stack expression type
					var id = $ID; // ID
					var idt = findTypeId(yy, $ID); //Type of ID
					if (var1t === idt || (var1t === "int" && idt === "float")) { // If equals types or int && float
						var op = yy.quads.push([$3, findDir(yy, var1), null, findDir(yy, id)]); // Creates quad and finds the dir of each of the vars
					} else {
						throw new Error("INCOMPATIBLE TYPES");
					}
				}
	| ASSIGN ID '[' expression ']' '=' expression ';'
				{
					var var1 = ids.pop(); // Pops from stack second expression id
					var var1t = types.pop(); // Pops from stack second expression type
					var var2 = ids.pop(); // Pops from stack first expression id
					var var2t = types.pop(); // Pops from stack first expression type
					var id = $ID; // ID
					var idt = findTypeId(yy, $ID); // Type of ID

					var dims = findDim(yy, id); // Returns the dimension of ID
					if (dims.length != 1) { // If Not ID[]
						throw new Error("INCORRECT ARRAY DIMENSION")
					}

					if (var2t != "int") { // Type of the first expression must be int
						throw new Error("ARRAY POINTERS ONLY HANDLE INTS");
					}

					yy.quads.push(["verify", findDir(yy, var2), 0, dims[0]-1]); // Adds verify to quads with dir of vars, and the limit from 0 to dim[0]
					yy.quads.push(["++", findDir(yy, id), findDir(yy, var2), "(" + findDir(yy, createTemp(yy, idt)) + ")"]); // DirBase + S1

					var pointer = ids.pop(); types.pop();

					if (var1t === idt || (var1t === "int" && idt === "float")) {
						var op = yy.quads.push([$6, findDir(yy, var1), null, findDir(yy, pointer)]); // Assign
					} else {
						throw new Error("INCOMPATIBLE TYPES");
					}
				}
	| ASSIGN ID '[' expression ']' '[' expression ']' '=' expression ';'
				{
					var var1 = ids.pop(); // Pops from stack third expression id
					var var1t = types.pop();// Pops from stack third expression type
					var var2 = ids.pop(); // Pops from stack second expression id
					var var2t = types.pop(); // Pops from stack second expression type
					var var3 = ids.pop(); // Pops from stack first expression id
					var var3t = types.pop(); // Pops from stack first expression type
					var id = $ID; // ID
					var idt = findTypeId(yy, $ID); // Type of ID

					var dims = findDim(yy, id); // Returns the dimension of ID
					if (dims.length != 2) { // If Not ID[][]
						throw new Error("INCORRECT ARRAY DIMENSION")
					}

					if (var2t != "int") { // Type of the second expression must be int
						throw new Error("ARRAY POINTERS ONLY HANDLE INTS");
					}

					yy.quads.push(["verify", findDir(yy, var3), 0, dims[0]-1]); // Adds verify to quads with dir of vars, and the limit from 0 to dim[0]
					yy.quads.push(["*", findDir(yy, var3), findDir(yy, parseInt(dims[0])), findDir(yy, createTemp(yy, var3t))]); // m1 * s1

					var multpointer = ids.pop();
					var multpointertype = types.pop();

					yy.quads.push(["verify", findDir(yy, var2), 0, dims[1]-1]); // Adds verify to quads with dir of vars, and the limit from 0 to dim[1]
					yy.quads.push(["+", findDir(yy, multpointer), findDir(yy, var2), findDir(yy, createTemp(yy, multpointertype))]); // (m1 * s1) + s2

					var sumpointer = ids.pop();
					var sumpointertype = types.pop();

					yy.quads.push(["++", findDir(yy, id), findDir(yy, sumpointer), "(" + findDir(yy, createTemp(yy, idt)) + ")"]); // DirBase + S

					var pointer = ids.pop(); types.pop();

					if (var1t === idt || (var1t === "int" && idt === "float")) {
						var op = yy.quads.push([$9, findDir(yy, var1), null, findDir(yy, pointer)]); // Assign
					} else {
						throw new Error("INCOMPATIBLE TYPES");
					}
				}
	;

assignment_declaration
	: ASSIGN ID
				{
					ids.push($ID); // Pushes ID to stack
					types.push(findTypeId(yy, $ID)); // Pushes type to stack
				}
	;

/**
	WRITE
**/

write_statute
	: WRITE '(' expression ')' ';'
				{
					yy.quads.push(["write", null, null, findDir(yy, ids.pop())]); // Quad that prints the ID in dir
				}
	;

/**
	IF
**/

if_statute
	: IF if_condition if_block else_statute
	;

if_condition
	: '(' expression ')'
				{
					var type = types.pop(); // Pops from stack
					var id = ids.pop(); // Pops from stack
					if (type === "boolean") { // Verify expression is boolean
						yy.quads.push(["gotof", findDir(yy, id), null, null]); // GotoF
						jumps.push(yy.quads.length - 1); // Adds position to jump stack
					} else {
						throw new Error("INVALID IF STATEMENT");
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
					var jump = jumps.pop(); // Pops from stack
					yy.quads[jump][3] = yy.quads.length; // Adds position to jump value
				}
	;

else_declaration
	: ELSE
				{
					var jump = jumps.pop(); // Pops from stack
					yy.quads.push(["goto", null, null, null]);
					yy.quads[jump][3] = yy.quads.length; // Adds position to jump value
					jumps.push(yy.quads.length - 1);
				}
	;

else_block
	: '{' block '}'
				{
					var jump = jumps.pop(); // Pops from stack
					yy.quads[jump][3] = yy.quads.length;  // Adds position to jump value
				}
	;

while_statute
	: while_declaration while_condition while_block
				{
					var jump = jumps.pop(); // Pops from stack
					yy.quads[jump][3] = yy.quads.length; // Adds position to jump value
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
						throw new Error("INVALID WHILE STATEMENT");
					}
				}
	;

/**
	WHILE
**/

while_block
	: '{' block '}'
				{
					var jump = jumps.pop(); // Pops from stack
					yy.quads.push(["goto",null,null,jumps.pop()]); //Goto quad jump value
					jumps.push(jump); // Readds jump to stack
				}
	;

/**
	RETURN
**/

return_statute
	: RETURN expression ';'
				{
					proc = findProc(yy, scope.stackTop()); // Find proc being used (first in stack)
					var id = ids.pop(); // Pop from stack
					var type = types.pop(); // Pop from stack
					if (proc.type !== "void" && proc.type === type)	{ // If not void and if equal types
						yy.quads.push(["return", null, null, findDir(yy,id)]); // Return the result of te function to the dir of the id
					} else {
						throw new Error("EXPECTED RETURN");
					}
				}
	;

/**
	EXPRESSION
**/

expression_statute
	: expression ';'
	;

expression
	: comparison
	| comparison logical_ops comparison
				{
					var var2 = ids.pop(); // Pop comparison2 id
					var var2t = types.pop(); // Pop comparison2 type
					var var1 = ids.pop(); // Pop comparison1 id
					var var1t = types.pop(); // Pop comparison1 type
					var op = ops.pop(); // Pop op
					var type = validateSem(op, var1t, var2t); // Validates types are compatible
					if (type !== "x") { // If compatible
						var op = [op, findDir(yy, var1), findDir(yy, var2), findDir(yy, createTemp(yy, type))]; // Adds logical_ops quad
					} else {
						throw new Error("ILLOGICAL COMPARISON");
					}
					yy.quads.push(op);
				}
	;

logical_ops
	: '&' '&'
				{ops.push("&&");} // Pushes to stack
	| '|' '|'
				{ops.push("||");} // Pushes to stack
	;

comparison
	: exp
	| exp comparison_ops exp
				{
					var var2 = ids.pop(); // Pop exp2 id
					var var2t = types.pop(); // Pop exp2 type
					var var1 = ids.pop(); // Pop exp1 id
					var var1t = types.pop(); // Pop exp1 type
					var op = ops.pop(); // Pop op
					var type = validateSem(op, var1t, var2t); // Validates types are compatible
					if (type !== "x") { // If compatible
						var op = [op, findDir(yy, var1), findDir(yy, var2), findDir(yy, createTemp(yy, type))]; // Adds comparison quad
					} else {
						throw new Error("ILLOGICAL COMPARISON");
					}
					yy.quads.push(op);
				}
	;

comparison_ops
	: '<' '='
				{ops.push("<=");} // Pushes to stack
	| '>' '='
				{ops.push(">=");} // Pushes to stack
	| '!' '='
				{ops.push("!=");} // Pushes to stack
	| '=' '='
				{ops.push("==");} // Pushes to stack
	| '>'
				{ops.push(">");} // Pushes to stack
	| '<'
				{ops.push("<");} // Pushes to stack
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
					if (ops.stackTop() === "+" || ops.stackTop() === "-") { // If first from ops stack is + or -
						var var2 = ids.pop(); // Pop value2 id
						var var2t = types.pop(); // Pop value2 type
						var var1 = ids.pop(); // Pop value1 id
						var var1t = types.pop(); // Pop value1 type
						var op = ops.pop(); // Pop ops
						var type = validateSem(op, var1t, var2t); // Validates types are compatible
						if(type !== "x") {
							var op = [op, findDir(yy, var1), findDir(yy, var2), findDir(yy, createTemp(yy, type))];
						} else {
							throw new Error("INVALID TYPES");
						}
						yy.quads.push(op); // Adds + or - quad
					}
				}
	;

sum_or_minus
	: '+'
				{ops.push($1);} // Push to stack
	| '-'
				{ops.push($1);} // Push to stack
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
					if (ops.stackTop() === "*" || ops.stackTop() === "/") { // If first from ops stack is * or /
						var var2 = ids.pop(); // Pop value2 id
						var var2t = types.pop(); // Pop value2 type
						var var1 = ids.pop(); // Pop value1 id
						var var1t = types.pop(); // Pop value1 type
						var op = ops.pop(); // Pop ops
						var type = validateSem(op, var1t, var2t); // Validates types are compatible
						if (type !== "x") {
							var op = [op, findDir(yy, var1), findDir(yy, var2), findDir(yy, createTemp(yy, type))];
						} else {
							throw new Error("INVALID TYPES");
						}
						yy.quads.push(op); // Adds * or / quad
					}
				}
	;

mult_or_divi
	: '*'
			{ops.push($1);} // Push to stack
	| '/'
			{ops.push($1);} // Push to stack
	;

factor
	: constant
	| id options
	| "(" add_closure expression end_closure")"
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
						throw new Error("NEED PARAMETERS");
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
					var id = ids.pop(); // Pop from stack
					var type = types.pop(); // Pop from stack
					if (paramTemp >= tempProc.numParams()) { // If the numbers of params is higher than what is expected
						throw new Error("INCORRECT PARAMETERS");
					}

					if (tempProc.params[paramTemp].type === type || (tempProc.params[paramTemp].type === "float" && type === "int") ) {
						if (tempProc.params[paramTemp].dim > 0) { // if there are many params
							yy.quads.push(["param", "(" + findDir(yy, id) + "," + tempProc.params[paramTemp].dim + ")", null, ++paramTemp]);
						} else {
							yy.quads.push(["param", findDir(yy, id), null, ++paramTemp]);
						}
					} else {
						throw new Error("INVALID TYPES");
					}
					// ops.pop();
				}
	;

/**
	ARRAY
**/

array
	: vector
	| matrix
	;

vector
	: "[" add_closure expression end_closure "]"
				{
					var id = ids.pop(); // Pop exp id
					var type = types.pop(); // Pop exp type
					var id_array = ids.pop();  // Pop array id
					var type_array = types.pop(); // Pop array type

					var dims = findDim(yy, id_array); // Find dim size
					if (dims.length == 2 || dims.length == 0) {
						throw new Error("INCORRECT ARRAY DIMENSION"); // Incorrect size
					}

					if (type != "int") { // Must be int
						throw new Error("ARRAY POINTERS ONLY HANDLE INTS");
					}

					yy.quads.push(["verify", findDir(yy, id), 0, dims[0]-1]); // Pushes verify to quad from 0 to dims[0]-1
					yy.quads.push(["++", findDir(yy, id_array), findDir(yy, id), "(" + findDir(yy, createTemp(yy, type_array)) + ")"]); // DirBase + s1
				}
	;

matrix
	: "[" add_closure expression end_closure "]" "[" add_closure expression end_closure"]"
				{
					var var1 = ids.pop(); // Pop exp2 id
					var var1t = types.pop(); // Pop exp2 type
					var var2 = ids.pop(); // Pop exp1 id
					var var2t = types.pop(); // Pop exp1 type
					var id = ids.pop(); // Pop array id
					var idt = types.pop();; // Pop array type

					var dims = findDim(yy, id); // Find dim size
					if (dims.length != 2) {
						throw new Error("INCORRECT ARRAY DIMENSION") // Incorrect size
					}

					if (var2t != "int") { // Must be int
						throw new Error("ARRAY POINTERS ONLY HANDLE INTS");
					}

					yy.quads.push(["verify", findDir(yy, var2), 0, dims[0]-1]);  // Pushes verify to quad from 0 to dims[0]-1
					yy.quads.push(["*", findDir(yy, var2), findDir(yy, parseInt(dims[0])), findDir(yy, createTemp(yy, var2t))]); // s1 * m1

					var multpointer = ids.pop();
					var multpointertype = types.pop();

					yy.quads.push(["verify", findDir(yy, var1), 0, dims[1]-1]);  // Pushes verify to quad from 0 to dims[1]-1
					yy.quads.push(["+", findDir(yy, multpointer), findDir(yy, var1), findDir(yy, createTemp(yy, multpointertype))]); // (s1 * m1) + s2

					var sumpointer = ids.pop();
					var sumpointertype = types.pop();

					yy.quads.push(["++", findDir(yy, id), findDir(yy, sumpointer), "(" + findDir(yy, createTemp(yy, idt)) + ")"]); // DirBase + s
				}
	;

add_closure
	:
				{ops.push("|");} // Adds fondo
	;

end_closure
	:
				{ops.pop();} // Removes fondo
	;

constant
	: I
				{
					// Add INT to constant
					yy.consts.push([parseInt($I), assignMemory("int", false, true, [])]);
					// Pushes to stack
					types.push("int");
					ids.push(parseInt($I));
				}
	| F
				{
					// Add FLOAT to constant
					yy.consts.push([parseFloat($F), assignMemory("float", false, true, [])]);
					types.push("float");
					ids.push(parseFloat($F));
				}
	| B
				{
					// Add BOOLEAN to constant
					yy.consts.push([$B, assignMemory("boolean", false, true, [])]);
					// Pushes to stack
					types.push("boolean");
					ids.push($B);
				}
	| S
				{
					// Add STRING to constant
					yy.consts.push([$S, assignMemory("string", false, true, [])]);
					// Pushes to stack
					types.push("string");
					ids.push($S);
				}
	;

%%

/**
	VARS
**/

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

/**
	Data Structures definiton that let me pop, push, and stackTop
**/

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

/**
	Create new data structures (stacks)
**/

var ids = new dataStructures.stack(); // Ids
var types = new dataStructures.stack(); // Types
var ops = new dataStructures.stack(); // Ops
var scope = new dataStructures.stack(); // Scope
var jumps = new dataStructures.stack() // Jumps

/**
	Semantic Cube
**/

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
	["string","boolean","x","x","x","x","x","x","x","x","x","x","x","x"],
	["boolean","int","x","x","x","x","x","x","x","x","x","x","x","x"],
	["boolean","float","x","x","x","x","x","x","x","x","x","x","x","x"],
	["boolean","string","x","x","x","x","x","x","x","x","x","x","x","x"]
];

/**
	Initialze variables.
**/

var temp = 1; // Temp var
var paramTemp = 1; // Temp parameter
var tempProc = null; // Temp proc
var expectingParams = false; // Epecting params

/**
	Japtor main definition. This is what is returned when parsed in the HTML.
**/

var Japtor = function() {
	var japtorLexer = function () {};
	japtorLexer.prototype = parser.lexer;
	initDirs();
	var japtorParser = function () {
		this.lexer = new japtorLexer();
		this.yy = {
			procs: [], // Procs
			quads: [], // Quads
			consts: [] // Consts
		};
	};
	japtorParser.prototype = parser;
	var newParser = new japtorParser();
	return newParser;
};

/**
	Proc definition. Each function has a proc, where it stores vars, params, etc..
**/

function Proc(name, type, dir, params, vars, init){
	this.name = name;
	this.type = type;
	this.dir = dir;
	this.params = params;
	this.vars = vars;
	this.init = init;
};

/**
	Extra proc definition
**/

Proc.prototype = {
	size : function() { // Returns the size of the proc by counting vars
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
	dirs : function() { // Returns dir
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
	numParams : function() { // Returns number of params
		return this.params.length;
	}
}

/**
	Dir Proc
	Returns the next available proc.
**/

function dirProc() {
	if (dirProcs < 5000) {
		return dirProcs++;
	} else {
		throw new Error("OUT OF MEMORY");
	}
}

/**
	Assign Memory
	Assigns a var with a dir depending on type and it tmp or const or dim.
**/

function assignMemory(type, tmp, cons, dim) {

	var pointer = 1;
	var temp = null;

	// If global
	var isGlobal = false;
	if (scope.stackTop() === "global") {
		isGlobal = true;
	}

	//If Matrix
	if (dim.length == 2) {
		pointer = parseInt(dim[0]) * parseInt(dim[1]) + parseInt(dim[0]);
	//If Array
	} else if (dim.length == 1) {
		pointer = parseInt(dim[0]);
	}

	// If temporal
	if (tmp) {
		switch (type) {
			case 'int':
				if (tv_i < 21000) {
					return tv_i++;
				} else {
					throw new Error("OUT OF MEMORY");
				}
				break;
			case 'float':
				if (tv_f < 23000) {
					return tv_f++;
				} else {
					throw new Error("OUT OF MEMORY");
				}
				break;
			case 'string':
				if (tv_st < 25000) {
					return tv_st++;
				} else {
					throw new Error("OUT OF MEMORY");
				}
				break;
			case 'boolean':
				if (tv_bool < 26000) {
					return tv_bool++;
				} else {
					throw new Error("OUT OF MEMORY");
				}
				break;
		}
	} else if (cons) { // If constant
		switch (type) {
			case 'int':
				if (cv_i < 28000) {
					return cv_i++;
				} else {
					throw new Error("OUT OF MEMORY");
				}
				break;
			case 'float':
				if (cv_f < 30000) {
					return cv_f++;
				} else {
					throw new Error("OUT OF MEMORY");
				}
				break;
			case 'string':
				if (cv_st < 32000) {
					return cv_st++;
				} else {
					throw new Error("OUT OF MEMORY");
				}
				break;
			case 'boolean':
				if (cv_bool < 33000) {
					return cv_bool++;
				} else {
					throw new Error("OUT OF MEMORY");
				}
				break;
		}
	} else {
		if (isGlobal) { // If global
			switch (type) {
				case 'int':
					if (gv_i < 7000) {
						temp = gv_i;
						gv_i = gv_i + pointer;
						return temp;
					} else {
						throw new Error("OUT OF MEMORY");
					}
					break;
				case 'float':
					if (gv_f < 9000) {
						temp = gv_f;
						gv_f = gv_f + pointer;
						return temp;
					} else {
						throw new Error("OUT OF MEMORY");
					}
					break;
				case 'string':
					if (gv_st < 11000) {
						temp = gv_st;
						gv_st = gv_st + pointer;
						return temp;
					} else {
						throw new Error("OUT OF MEMORY");
					}
					break;
				case 'boolean':
					if (gv_bool < 12000) {
						temp = gv_bool;
						gv_bool = gv_bool + pointer;
						return temp;
					} else {
						throw new Error("OUT OF MEMORY");
					}
					break;
			}
		} else { // If local
			switch (type) {
				case 'int':
					if (lv_i < 14000) {
						temp = lv_i;
						lv_i = lv_i + pointer;
						return temp;
					} else {
						throw new Error("OUT OF MEMORY");
					}
					break;
				case 'float':
					if (lv_f < 16000) {
						temp = lv_f;
						lv_f = lv_f + pointer;
						return temp;
					} else {
						throw new Error("OUT OF MEMORY");
					}
					break;
				case 'string':
					if (lv_st < 18000) {
						temp = lv_st;
						lv_st = lv_st + pointer;
						return temp;
					} else {
						throw new Error("OUT OF MEMORY");
					}
					break;
				case 'boolean':
					if (lv_bool < 19000) {
						temp = lv_bool;
						lv_bool = lv_bool + pointer;
						return temp;
					} else {
						throw new Error("OUT OF MEMORY");
					}
					break;
			}
		}
	}
}

/**
	Initialize directories
**/

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

/**
	Validate Semantic
	Validates the types are compatible and returns type.
**/

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

/**
	Find Type By Id.
	Finds the type of an id in the given local scope, and if not found, global.
**/

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

	throw new Error("ID NOT DECLARED");
}

/**
	Find Proc
	Finds and returns the proc by id.
**/

function findProc(yy, name) {
	for (var i = 0; i < yy.procs.length; i++) {
		if (yy.procs[i].name === name) {
			return yy.procs[i];
		}
	}

	return "undefined";
}

/**
	Create Temp
	Creates a temp var dependant on type.
**/

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

/**
	Find dir
	Returns the dir of the id.
**/

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

	throw new Error("ID NOT DECLARED");
}

/**
	Find dim
	Returns the dim of the id
**/

function findDim(yy, id) {
	var currentScope = scope.stackTop();
	var proc = findProc(yy, currentScope);

	for (var i = 0; i < proc.vars.length; i++) {
		if (proc.vars[i].id === id) {
			return proc.vars[i].dim;
		}
	}

	proc = findProc(yy, "global");
	for (var i = 0; i < proc.vars.length; i++) {
		if (proc.vars[i].id === id) {
			return proc.vars[i].dim;
		}
	}
}

if (typeof(window) !== 'undefined') {
	window.Japtor = Japtor;
} else {
	parser.Japtor = Japtor;
}
