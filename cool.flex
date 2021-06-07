/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

bool check_max_strlen();
int max_strlen_error();

int comment_level;

%}

/*
 * Define names for regular expressions here.
 */

ALPHA		[a-zA-Z]
DIGIT		[0-9]
WHITESPACE	[\n\t\f\r\v ]
DASHCOMMENT	"--".*
CLASS		(?i:class)
ELSE		(?i:else)
FI		(?i:fi)
IF		(?i:if)
IN		(?i:in)
INHERITS	(?i:inherits)
LET		(?i:let)
LOOP		(?i:loop)
POOL		(?i:pool)
THEN		(?i:then)
WHILE		(?i:while)
CASE		(?i:case)
ESAC		(?i:esac)
OF		(?i:of)
DARROW          =>
NEW		(?i:new)
ISVOID		(?i:isvoid)
STR_CONST	\".\"
INT_CONST	[0-9]+
TRUE		t[rR][uU][eE]
FALSE		f[aA][lL][sS][eE]
TYPEID		[A-Z]({ALPHA}|{DIGIT}|_)*
OBJECTID	[a-z]({ALPHA}|{DIGIT}|_)*
ASSIGN		<-
NOT		(?i:not)
LE		<=

%x COMMENT
%x STRING
%x INVALID

%%

 /*
  * Single-character operators.
  */

"."			{ return '.'; }
"@"			{ return '@'; }
"~"			{ return '~'; }
"*"			{ return '*'; }
"/"			{ return '/'; }
"+"			{ return '+'; }
"-"			{ return '-'; }
"<"			{ return '<'; }
"="			{ return '='; }
";"			{ return ';'; }
":"			{ return ':'; }
","			{ return ','; }
"{"			{ return '{'; }
"}"			{ return '}'; }
"("			{ return '('; }
")"			{ return ')'; }


 /*
  *  The multiple-character operators.
  */
{ASSIGN}		{ return (ASSIGN); }
{DARROW}		{ return (DARROW); }
{LE}			{ return (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}			{ return (CLASS); }
{ELSE}			{ return (ELSE);  }
{FI}			{ return (FI);  }
{IF}			{ return (IF); }
{IN}			{ return (IN); }
{INHERITS}		{ return (INHERITS); }
{LET}			{ return (LET); }
{LOOP}			{ return (LOOP); }
{POOL}			{ return (POOL); }
{THEN}			{ return (THEN); }
{WHILE}			{ return (WHILE); }
{CASE}			{ return (CASE); }
{ESAC}			{ return (ESAC); }
{OF}			{ return (OF); }
{NEW}			{ return (NEW); }
{ISVOID}		{ return (ISVOID); }
{NOT}			{ return (NOT); }

 /*
  * Boolean values.
  */

{TRUE}			{ cool_yylval.boolean = true;
			return (BOOL_CONST); }
{FALSE}			{ cool_yylval.boolean = false;
			return (BOOL_CONST); }

 /*
  * Integer constants.
  */

{INT_CONST}		{ cool_yylval.symbol = inttable.add_string(yytext);
			return (INT_CONST); }

 /*
  * Identifiers.
  */

{TYPEID}		{ cool_yylval.symbol = inttable.add_string(yytext);
			return (TYPEID); }
{OBJECTID}		{ cool_yylval.symbol = inttable.add_string(yytext);
			return (OBJECTID); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"			{ string_buf_ptr = string_buf;
			BEGIN(STRING); }
<STRING>\"		{ if (check_max_strlen()) return max_strlen_error();
			*string_buf_ptr = '\0';
			cool_yylval.symbol = stringtable.add_string(string_buf);
			BEGIN(INITIAL);
			return (STR_CONST); }
<STRING>\\\n		{ if (check_max_strlen()) return max_strlen_error();
			*string_buf_ptr++ = '\n';
			curr_lineno++; }
<STRING>\n		{ curr_lineno++; 
			cool_yylval.error_msg = "Unterminated string constant";
			BEGIN(INITIAL);
			return (ERROR); }
<STRING><<EOF>>		{ cool_yylval.error_msg = "EOF in comment";
			BEGIN(INITIAL);
			return (ERROR); }
<STRING>\\?\0		{ BEGIN(INVALID);
			cool_yylval.error_msg = "String contains null character"; 
			return (ERROR); }
<STRING>\\[^ntbf]	{ if (check_max_strlen()) return max_strlen_error();
			*string_buf_ptr++ = yytext[1]; }
<STRING>\\[n]		{ if (check_max_strlen()) return max_strlen_error();
			*string_buf_ptr++ = '\n'; }
<STRING>\\[t]		{ if (check_max_strlen()) return max_strlen_error();
			*string_buf_ptr++ = '\t'; }
<STRING>\\[b]		{ if (check_max_strlen()) return max_strlen_error();
			*string_buf_ptr++ = '\b'; }
<STRING>\\[f]		{ if (check_max_strlen()) return max_strlen_error();
			*string_buf_ptr++ = '\f'; }
<STRING>.		{ if (check_max_strlen()) return max_strlen_error();
			*string_buf_ptr++ = *yytext; }

<INVALID>\"		BEGIN(INITIAL);
<INVALID>\n		{ curr_lineno++;
			BEGIN(INITIAL); }
<INVALID>\\\n		curr_lineno++;
<INVALID>\\.		;
<INVALID>.		;

 /*
  *  Comments
  */

"*)"			{ cool_yylval.error_msg = "Unmatched *)"; 
			return (ERROR); }

{DASHCOMMENT}		;
"(*"			{ comment_level++;
			BEGIN(COMMENT); }
<COMMENT>"(*"		{ comment_level++;
			BEGIN(COMMENT); }
<COMMENT><<EOF>>	{ cool_yylval.error_msg = "EOF in comment";
			BEGIN(INITIAL);
			return (ERROR); }
<COMMENT>\\\n		curr_lineno++;
<COMMENT>\n		curr_lineno++;
<COMMENT>"*"+")"	{ if (--comment_level < 1) BEGIN(INITIAL); }
<COMMENT>.		;

 /*
  * White Space.
  */

\n			curr_lineno++;
{WHITESPACE}		;


 /*
  * General Error.
  */

.			{ cool_yylval.error_msg = yytext;
			return (ERROR); }

%%

bool check_max_strlen() {
    return (string_buf_ptr - string_buf) + 1 > MAX_STR_CONST;
}

int max_strlen_error() {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "String constant too long";
    return  (ERROR);
}
