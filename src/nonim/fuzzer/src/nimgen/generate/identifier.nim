#:____________________________________________________________________
#  nim.gen  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:____________________________________________________________________
# @deps compiler
import "$nim"/compiler/[ ast, idents, lineinfos, lexer ]
# @deps std
from std/sequtils import mapIt, toSeq
from std/strutils import nimIdentNormalize
# @deps nim.gen
import ../random as R
import ./shared
import ./characters


#_______________________________________
# @section Identifier Generation: Helpers
#_____________________________
func isKeyword *(name :string) :bool=  name.nimIdentNormalize in lexer.TokType.items.toSeq()[lexer.tokKeywordLow..lexer.tokKeywordHigh].mapIt($it)


#_______________________________________
# @section Identifier Generation: Name
#_____________________________
func name *(length :Positive= 8, underscore :bool= false) :string=
  ## Generates a random valid Nim identifier name
  ##
  ## The generated identifier follows Nim's identifier rules:
  ## * First character is a letter (or underscore if `underscore` is true)
  ## * Subsequent characters can be letters, digits, or underscores
  ## * Total length will be `length` characters (minimum 1)
  ##
  ## Parameters:
  ## * `length`     : (default:     8) The desired length of the identifier
  ## * `underscore` : (default: false) Whether Nim underscore rules should be applied or not
  ##
  ## Returns:
  ## * A string containing a valid Nim identifier
  ##
  #! IDENTIFIER = letter ( ['_'] (letter | digit) )*
  # First character must be a letter (or underscore if allowed)
  let firstCharSet =
    if underscore : characters.IdentifierFirst
    else          : characters.Letters
  result = $R.sample(firstCharSet)
  if length == 1: return

  # Remaining characters can be letters, digits, or underscores
  for id in 1..<max(1, length-2):
    let prevUnderscore = result[^1] == '_'
    let nextCharSet =
      if underscore and prevUnderscore : characters.Identifier
      else                             : characters.Letters + characters.Digits
    result.add $R.sample(nextCharSet)

  # Last character cannot be an underscore if not allowed
  let lastCharSet =
    if underscore : characters.Identifier
    else          : characters.Letters + characters.Digits
  result.add $R.sample(lastCharSet)

  # Fix edge case of the randomly generated name not having any invalid `_` when underscore is true
  if underscore and '_' notin result: result.insert("__", result.len div 2)
  # Fix edge case of the randomly generated name being a keyword  (eg: aS As AS A_S etc)
  if result.isKeyword(): result.add $R.sample(lastCharSet)


#_______________________________________
# @section Identifier Generation: Node
#_____________________________
func node *(info :TLineInfo; name :string) :PNode=
  result = newNode(nkIdent)
  {.cast(noSideEffect).}: # Access to gIdentCache is safe
    result.ident = gIdentCache.getIdent(name)
  result.info = info
#___________________
func exported *(info :TLineInfo; inner :PNode) :PNode=
  result = newNodeI(nkPostfix, info)
  result.add(identifier.node(info, "*"))
  result.add(inner)
#___________________
func node *(info :TLineInfo; name :string; public :bool) :PNode=
  result = identifier.node(info, name)
  if public: result = identifier.exported(info, result)
#___________________
func typ *(info :TLineInfo; T :string) :PNode=
  ## Generate a random type identifier node
  # FIX: Make it random
  result = identifier.node(info, T)
#___________________
func random *(
    info       : TLineInfo;
    public     : bool     = false;
    length     : Positive = R.integer(1..64);
    underscore : bool     = false
  ) :PNode=
  ## Generate a random identifier node
  # 1. Name
  let name_str  = identifier.name(length, underscore) # Generate random name
  let name_node = identifier.node(info, name_str)
  if not public: return name_node
  result = identifier.exported(info, name_node)

