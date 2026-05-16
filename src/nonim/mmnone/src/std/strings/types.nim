#:__________________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  GPL-3.0-or-later  :
#:__________________________________________________________________

#_______________________________________
# @section Implementations
#_____________________________
type Nim_char     {.magic: Char   .}
type char       * = Nim_char
type Nim_string   {.magic: String .}
type string     * = Nim_string
type Nim_cstring  {.magic: Cstring.}
type cstring    * = Nim_cstring
