#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Grammar Token type and TokenId enum.
## Output from the grammar tokenizer.
## Input for the grammar parser.
#_______________________________________________________________|
import ../lexer/source


type TokenId * = enum
  identifier
  number
  kw_grammar      ## grammar
  sp_assignment   ## =
  sp_argument     ## $
  sp_string       ## "
  sp_char         ## '
  sp_colon        ## :
  sp_semicolon    ## ;
  sp_comma        ## ,
  sp_dot          ## .
  sp_bracket_L    ## [
  sp_bracket_R    ## ]
  sp_brace_L      ## {
  sp_brace_R      ## }
  sp_paren_L      ## (
  sp_paren_R      ## )
  sp_hash         ## #
  sp_hash_double  ## ##
  sp_EOF          ## end

type Token * = object
  id  * :TokenId
  loc * :Location

func create *(id :TokenId; location :Location) :Token= Token(id: id, loc: location)
