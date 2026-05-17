#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Character identification tools.
#_______________________________________________________________|


const EOF_char * :char= '\0'
const digit * = {'0'..'9'}
const alphabetic * = {'A'..'Z', 'a'..'z'}
const alphanumeric * = digit + alphabetic
const hex * = digit + {'A'..'F', 'a'..'f'}
const numeric * = hex + {'x', 'b', 'o', 'u', 'i', 'f', 'd', '_'}
const whitespace * = {' ', '\t', '\n', '\r'}
const identifier * = {'_'} + alphanumeric
const quote * = {'\'', '"', '`'}
const parenthesis * = {'(', ')', '[', ']', '{', '}'}
const punctuation * = {':', ';', ',', '.'}
const operator_standard * = {'*', '+', '-', '/', '%', '<', '>', '&', '|', '!', '~', '^', '=', '$'}
const operator_special * = {':', '.', '@', '?', '\\'}
const operator * = operator_standard + operator_special
const context_change * = whitespace + quote + operator + parenthesis + punctuation + {'#'}

func is_eof *(character :char) :bool= character == EOF_char
func is_numeric *(character :char) :bool= character in numeric
func is_ident *(character :char) :bool= character in identifier
func is_operator *(character :char) :bool= character in operator
func is_quote *(character :char) :bool= character in quote
func is_parenthesis *(character :char) :bool= character in parenthesis
func is_punctuation *(character :char) :bool= character in punctuation
func is_context_change *(character :char) :bool= is_eof(character) or character in context_change
func is_semicolon *(character :char) :bool= character == ';'
func is_colon *(character :char) :bool= character == ':'
func is_dot *(character :char) :bool= character == '.'
func is_comma *(character :char) :bool= character == ','
func is_hash *(character :char) :bool= character == '#'
