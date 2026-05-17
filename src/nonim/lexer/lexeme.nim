#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Describes a Lexeme.
## Output from the lexing process.
## Input for the Tokenizer process of the target language.
#_______________________________________________________________|
import ./source


type LexemeId * = enum
  ident
  number
  colon       ## :
  eq          ## =
  star        ## *
  paren_L     ## (
  paren_R     ## )
  hash        ## #
  semicolon   ## ;
  quote_S     ## '  (single quote)
  quote_D     ## "  (double quote)
  quote_B     ## `  (backtick quote)
  brace_L     ## {
  brace_R     ## }
  bracket_L   ## [
  bracket_R   ## ]
  dot         ## .
  comma       ## ,
  plus        ## +
  dash        ## -
  slash_F     ## /  (forward slash)
  less        ## <
  more        ## >
  at          ## @
  dollar      ## $
  tilde       ## ~
  ampersand   ## &
  percent     ## %
  pipe        ## |
  excl        ## !
  question    ## ?
  caret       ## ^
  slash_B     ## \  (backward slash)
  space       ## ` `
  newline     ## \n
  tab         ## \t
  ret         ## \r
  EOF         ## 0x0

type Lexeme * = object
  loc * :Location
  id  * :LexemeId

func create *(id :LexemeId; location :Location) :Lexeme= Lexeme(id: id, loc: location)
func create *(id :LexemeId; start :Position; finish :Position) :Lexeme= Lexeme(id: id, loc: Location(start: start, `end`: finish))
func `from` *(lexeme :Lexeme; source :Code) :string= lexeme.loc.`from`(source)
