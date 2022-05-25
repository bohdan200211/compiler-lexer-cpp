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
unsigned int comments_nested;
unsigned int string_length;

%}

/*
 * Define names for regular expressions here.
 */

/* Integers */
INTEGER		[0-9]+

/* Identifiers */
TYPE_ID		[A-Z][A-Za-z0-9_]*|SELF_TYPE
OBJECT_ID		[a-z][A-Za-z0-9_]*|self

/* Special Notation */
DARROW         	"=>"
ASSIGN			"<-"
LE			"<="

/* Strings */
DOUBLE_QUOTE		\"
NULL_CHAR		\0

/* Comments */
COMMENT_LINE		"--"
OPEN_COMMENT		"(*"
CLOSE_COMMENT		"*)"

/* Keywords */
CLASS			[cC][lL][aA][sS][sS]
ELSE			[eE][lL][sS][eE]
FALSE			f[aA][lL][sS][eE]
FI			[fF][iI]
IF			[iI][fF]
IN			[iI][nN]
INHERITS		[iI][nN][hH][eE][rR][iI][tT][sS]
ISVOID			[iI][sS][vV][oO][iI][dD]
LET			[lL][eE][tT]
LOOP			[lL][oO][oO][pP]
POOL			[pP][oO][oO][lL]
THEN			[tT][hH][eE][nN]
WHILE			[wW][hH][iI][lL][eE]
CASE			[cC][aA][sS][eE]
ESAC			[eE][sS][aA][cC]
NEW			[nN][eE][wW]
OF			[oO][fF]
NOT			[nN][oO][tT]
TRUE			t[rR][uU][eE]

/* Whitespace */
WHITE_SPACE		[ \f\r\t\v]
NEW_LINE		\n

/* Unrecognized/Invalid */
INVALID_CHAR		[>\?\[\]\|\\`!#$%&']

/* States (exclusive!!) */
%x COMMENT STRING

%%

<COMMENT>{OPEN_COMMENT}		{ comments_nested++; }
<COMMENT>{NEW_LINE}			{ curr_lineno++; }
<COMMENT>{CLOSE_COMMENT}	{
	if (comments_nested == 0) 
		BEGIN(INITIAL); 
	else 
		comments_nested--;
}
<COMMENT><<EOF>>	{
	BEGIN(INITIAL);
	cool_yylval.error_msg = "EOF in comment";
	return (ERROR);
}

<COMMENT>.	{ }

{COMMENT_LINE}.*	{ }
{OPEN_COMMENT}		{ 
	BEGIN(COMMENT);
	comments_nested = 0;
}
{CLOSE_COMMENT}		{
	cool_yylval.error_msg = "Unmatched *)";
	return (ERROR);
}


<STRING>\"			{ 
	BEGIN(INITIAL);
	if (string_length < MAX_STR_CONST) {
		cool_yylval.symbol = stringtable.add_string(string_buf, string_length);
		return (STR_CONST);
	} else {
		cool_yylval.error_msg = "String constant too long";
		return (ERROR);
	}
}

<STRING>"\\b"	{
	string_buf_ptr[0] = '\b';
	string_buf_ptr++;
	string_length++;
}
<STRING>"\\t"	{
	string_buf_ptr[0] = '\t';
	string_buf_ptr++;
	string_length++;
}
<STRING>"\\n"	{
	string_buf_ptr[0] = '\n';
	string_buf_ptr++;
	string_length++;
}
<STRING>"\\f"	{
	string_buf_ptr[0] = '\f';
	string_buf_ptr++;
	string_length++;
}

<STRING>\\.		{
	string_buf_ptr[0] = yytext[1];
	string_buf_ptr++;
	string_length++;
}

<STRING>"\\0"|{NULL_CHAR}	{
	BEGIN(INITIAL);
	cool_yylval.error_msg = "String contains null character";
	return (ERROR);
}

<STRING>{NEW_LINE}	{
	BEGIN(INITIAL);
	curr_lineno++;
	cool_yylval.error_msg = "Unterminated string constant";
	return (ERROR);
}

<STRING><<EOF>>		{
	BEGIN(INITIAL);
	cool_yylval.error_msg = "EOF in string constant";
	return (ERROR);
}

<STRING>.			{
	string_buf_ptr[0] = yytext[0];
	string_buf_ptr++;
	string_length++;
}

{DOUBLE_QUOTE}		{
	BEGIN(STRING);
	string_length = 0;
	string_buf_ptr = string_buf;
}

{DARROW}	{ return (DARROW); }
{ASSIGN}	{ return (ASSIGN); }
{LE}		{ return (LE); }

{CLASS}	{ return (CLASS); }
{ELSE}		{ return (ELSE); }
{FALSE}			{ 
	cool_yylval.boolean = false;
	return (BOOL_CONST);
}
{FI}		{ return (FI); }
{IF}		{ return (IF); }
{IN}		{ return (IN); }
{INHERITS}	{ return (INHERITS); }
{ISVOID}	{ return (ISVOID); }
{LET}		{ return (LET); }
{LOOP}		{ return (LOOP); }
{POOL}		{ return (POOL); }
{THEN}		{ return (THEN); }
{WHILE}	{ return (WHILE); }
{CASE}		{ return (CASE); }
{ESAC}		{ return (ESAC); }
{NEW}		{ return (NEW); }
{OF}		{ return (OF); }
{NOT}		{ return (NOT); }
{TRUE}		{
	cool_yylval.boolean = true;
	return (BOOL_CONST);
}

{INTEGER}		{
	cool_yylval.symbol = inttable.add_string(yytext);
	return (INT_CONST);
}

{TYPE_ID}		{
	cool_yylval.symbol = idtable.add_string(yytext);
	return (TYPEID);
}

{OBJECT_ID}		{
	cool_yylval.symbol = idtable.add_string(yytext);
	return (OBJECTID);
}

"{"		{ return '{'; }
"}"		{ return '}'; }
"("		{ return '('; }
")"		{ return ')'; }
":"		{ return ':'; }
";"		{ return ';'; }
"."		{ return '.'; }
","		{ return ','; }
"+"		{ return '+'; }
"-"		{ return '-'; }
"*"		{ return '*'; }
"/"		{ return '/'; }
"~"		{ return '~'; }
"<"		{ return '<'; }
"="		{ return '='; }
"@"		{ return '@'; }


{WHITE_SPACE}		{ }
{NEW_LINE}		{ curr_lineno++; }
{INVALID_CHAR}		{
	cool_yylval.error_msg = yytext;
	return (ERROR);
}

.			{
	cool_yylval.error_msg = yytext;
	return (ERROR);
}

%%

