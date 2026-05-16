#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
import "$nim"/compiler/[ast, parser, idents, options, lineinfos, msgs, pathutils, syntaxes]
import std/paths
import ./errors


#_______________________________________
# @section Compile: from Code
#_____________________________
proc compile *(
    code : string;
    file : string = "";
  ) :ast.PNode=
  ## @descr Gets the AST of {@arg code}. The given {@arg file} path is used for error messages.
  var cache  = idents.newIdentCache()
  var config = options.newConfigRef()
  result = parser.parseString(
    s            = code,
    cache        = cache,
    config       = config,
    filename     = file,
    line         = 0,
    errorHandler = errorAST
    ) #:: parser.parseString( ... )


#_______________________________________
# @section Compile: from File
#_____________________________
proc readAST *(file :Path) :ast.PNode= Untyped.compile(file.string.readFile(), file.string)
  ## @descr Reads the AST of the given nim file.
#___________________
proc readASTall *(file :Path) :ast.PNode=
  ## @descr Alternative version of readAST using parser.parseAll()
  var conf    = options.newConfigRef()
  let fileIdx = msgs.fileInfoIdx(conf, pathutils.AbsoluteFile file.string)
  var pars :parser.Parser
  if syntaxes.setupParser(pars, fileIdx, idents.newIdentCache(), conf):
    result = parser.parseAll(pars)
    parser.closeParser(pars)

