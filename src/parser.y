/*  parser.y - only version
 *      parses lexical tokens into an AST (abstract syntax tree)
 */
 
%locations
%defines
%define api.pure
%lex-param {yyscan_t lexer}
%parse-param {YYSTYPE *root}
%parse-param {int *error_count}
%parse-param {yyscan_t lexer}
%token-table

%{
    #include <stdio.h>

    #include "compiler.h"
    #include "node.h"

    #ifndef YY_TYPEDEF_YY_SCANNER_T
    #define YY_TYPEDEF_YY_SCANNER_T
    typedef void *yyscan_t;
    #endif

    #include "parser.tab.h"
    #include "lexer.yy.h"

    #define YYERROR_VERBOSE
    static void yyerror(YYLTYPE *loc, YYSTYPE *root,
                      int *error_count, yyscan_t scanner,
                      char const *s);
%}

/* Values */
%token IDENTIFIER_T
%token INTEGER_T
%token STRING_T

/* Keywords */
%token AND_T
%token BREAK_T
%token DO_T
%token ELSE_T
%token ELSEIF_T
%token END_T
%token FALSE_T
%token TRUE_T
%token FOR_T
%token FUNCTION_T
%token IF_T
%token IN_T
%token LOCAL_T
%token NIL_T
%token NOT_T
%token OR_T
%token REPEAT_T
%token RETURN_T
%token THEN_T
%token UNTIL_T
%token WHILE_T

/* Symbols */
%token PLUS_T/*             +     */         
%token MINUS_T/*            -     */
%token ASTERISK_T/*         *     */
%token SLASH_T/*            /     */
%token PERCENT_T/*          %     */
%token EQUAL_T/*            =     */
%token LEFT_PARAN_T/*       (     */
%token RIGHT_PARAN_T/*      )     */
%token CARROT_T/*           ^     */
%token GREATER_THAN_T/*     >     */
%token LESS_THAN_T/*        <     */
%token SQUIGGLE_T/*         ~     */
%token COLON_T/*            :     */
%token POUND_T/*            #     */
%token DOT_T/*              .     */
%token COMMA_T/*            ,     */

/* Complex symbols */
%token DOUBLE_EQUAL_T/*     ==    */
%token NOT_EQUAL_T/*        ~=    */
%token GREATER_EQUAL_T/*    >=    */
%token LESS_EQUAL_T/*       <=    */
%token CONCAT_T/*           ..    */
%token VARARG_T/*           ...   */

%start program

%%

binary_operation
  : expression PLUS_T expression
      { $$ = node_binary_operation(@2, BINOP_ADD, $1, $2); }
  | expression MINUS_T expression
      { $$ = node_binary_operation(@2, BINOP_SUB, $1, $2); }
  | expression ASTERISK_T expression
      { $$ = node_binary_operation(@2, BINOP_MUL, $1, $2); }
  | expression SLASH_T expression
      { $$ = node_binary_operation(@2, BINOP_DIV, $1, $2); }
  | expression CARROT_T expression
      { $$ = node_binary_operation(@2, BINOP_POW, $1, $2); }
  | expression PERCENT_T expression
      { $$ = node_binary_operation(@2, BINOP_MOD, $1, $2); }
  | expression CONCAT_T expression
      { $$ = node_binary_operation(@2, BINOP_CONCAT, $1, $2); }
  | expression LESS_THAN_T expression
      { $$ = node_binary_operation(@2, BINOP_LT, $1, $2); }
  | expression GREATER_THAN_T expression
      { $$ = node_binary_operation(@2, BINOP_GT, $1, $2); }
  | expression GREATER_EQUAL_T expression
      { $$ = node_binary_operation(@2, BINOP_GE, $1, $2); }
  | expression LESS_EQUAL_T expression
      { $$ = node_binary_operation(@2, BINOP_LE, $1, $2); }
  | expression NOT_EQUAL_T expression
      { $$ = node_binary_operation(@2, BINOP_NE, $1, $2); }
  | expression DOUBLE_EQUAL_T expression
      { $$ = node_binary_operation(@2, BINOP_EQ, $1, $2); }
;

unary_operation
  : MINUS_T expression
      { $$ = node_unary_operation(@$, UNOP_NEG, $1); }
  | NOT_T expression
      { $$ = node_unary_operation(@$, UNOP_NOT, $1); }
  | POUND_T expression
      { $$ = node_unary_operation(@$, UNOP_LEN, $1); }
;

expression_list 
    : expression
    | expression_list COMMA_T expression
        { $$ = node_expression_list(@$, $1, $3); }
;

variable 
    : IDENTIFIER_T
;

prefix_expression
    : variable
    | LEFT_PARAN_T expression RIGHT_PARAN_T
        { $$ = node_expression_group(@$, $2); }
;

arguments
    : LEFT_PARAN_T RIGHT_PARAN_T
    | LEFT_PARAN_T expression_list RIGHT_PARAN_T
    | STRING_T
;

call 
    : prefix_expression arguments
        { $$ = node_call(@$, $1, $2, false); }
    | prefix_expression COLON_T IDENTIFIER_T arguments
//      { $$ = node_call(@$, $1, $2, false); }
;

expression
  : NIL_T  | FALSE_T | TRUE_T | INTEGER_T | STRING_T | VARARG_T
  | binary_operation | unary_operation
;

program 
    : block
        { *root = $1; }
;

statement
    : call 
        { $$ = node_expression_statement(@$, $1); }
;

block 
    : statement
    | block statement
        {$$ = node_block(@$, $1, $2); }
;

%%

static void yyerror(YYLTYPE *loc,
                    YYSTYPE *root __attribute__((unused)),
                    int *error_count,
                    yyscan_t scanner __attribute__((unused)),
                    char const *s)
{
  compiler_error(*loc, s);
  (*error_count)++;
}

/*  parser_parse - creates a tree of nodes
 *      args: pointer to error count, lexer instance
 *      rets: token name
 */
struct node *parser_parse(int *error_count, yyscan_t lexer)
{
    struct node *tree;

    int result = yyparse(&tree, error_count, lexer);

    /* Handle any errors that came up in the pass */
    if (result == 1 || *error_count > 0) 
        return NULL;
    else if (result == 2) {
        printf("Parser ran out of memory. Try restarting the compiler.\n");
        return NULL;
    }

    return tree;
}

/*  token_to_string - converts the given token to it's corresponding string name
 *      args: token
 *      rets: token name
 */
const char *token_to_string(int token) 
{
    return yytname[token - 255];
}