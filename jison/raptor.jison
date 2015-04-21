%lex

%%
\s+          						{/* ignore whitespace */;}
"program"								{return 'PROGRAM'}
";"											{return ';'}
":"											{return ':'}
"var"										{return 'VAR'}
"int"										{return 'INT';}
"float"									{return 'FLOAT';}
([a-zA-Z][a-zA-Z0-9]*)	{return 'ID';}
<<EOF>>									{return 'EOF';}

/lex

%start program

%%

program
	: EOF
				{return null;}
	| PROGRAM ID ';' vars EOF
				{
					var vars = yy.vars;
					yy.vars = [];
					return vars;
				}
	;

vars
	: VAR ID type
				{
					var variable = {
						id: $2,
						type: $3
					}
					$$ = yy.vars.length;
					yy.vars.push(variable);
				}
	|
	;

type
	: INT
	| FLOAT
	;

%%

var Raptor = function() {
	var raptorLexer = function () {};
	raptorLexer.prototype = parser.lexer;

	var raptorParser = function () {
		this.lexer = new raptorLexer();
		this.yy = {
			vars: [],
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
