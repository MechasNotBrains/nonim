#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Test runner: imports all test modules.
#_________________________________________|
# @section Lexer
import ./lexer/source_test
import ./lexer/lexeme_test
import ./lexer/char_test
import ./lexer/data_test
import ./lexer/whitespace_test
import ./lexer/symbols_test
import ./lexer/others_test
import ./lexer/test
# @section Grammar
import ./grammar/tokenizer_test
import ./grammar/parser_test
import ./grammar/test
# @section AST
import ./ast/json_test
# @section Codegen
import ./codegen/c_test
import ./codegen/zig_test
import ./codegen/nim_test
# @section Backend
import ./backend/test/cleanc
import ./backend/test/zig
import ./backend/test/minc
import ./backend/test/minz
import ./backend/test/nim
# @section CLI
import ./cli/test
import ./cli/minc_test
import ./cli/nonim_test
# @section Fuzzer
import ./fuzzer/generate_test
import ./fuzzer/generate/assignment_test
import ./fuzzer/generate/call_test
import ./fuzzer/generate/discard_test
import ./fuzzer/generate/expression_literal_test
import ./fuzzer/generate/identifier_test
import ./fuzzer/generate/module_test
import ./fuzzer/generate/procedure_test
import ./fuzzer/generate/statement_comment_test
import ./fuzzer/generate/statement_return_test
# import ./fuzzer/generate/variable_test

