#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
type TNodeKind* = enum
  # order is extremely important. ranges are used
  # nkNone,               # unknown node kind: indicates an error

  # nkEmpty,              # the node is empty
  # nkIdent,              # node is an identifier
  # nkSym,                # node is a symbol (compiler-internal)
  # nkType,               # node is used for its typ field (compiler-internal)

  # nkCharLit,            # a character literal ''
  # nkIntLit,             # an integer literal
  # nkInt8Lit,
  # nkInt16Lit,
  # nkInt32Lit,
  # nkInt64Lit,
  # nkUIntLit,            # an unsigned integer literal
  # nkUInt8Lit,
  # nkUInt16Lit,
  # nkUInt32Lit,
  # nkUInt64Lit,
  # nkFloatLit,           # a floating point literal
  # nkFloat32Lit,
  # nkFloat64Lit,
  # nkFloat128Lit,
  # nkStrLit,             # a string literal ""
  # nkRStrLit,            # a raw string literal r""
  # nkTripleStrLit,       # a triple string literal """
  # nkNilLit,             # the nil literal
  #                       # end of atoms
  # nkComesFrom,          # "comes from" template/macro information (compiler-internal)
  # nkDotCall,            # used to temporarily flag a nkCall node (compiler-internal)

  # nkCommand,            # a call like ``p 2, 4`` without parenthesis
  # nkCall,               # a call like p(x, y) or an operation like +(a, b)
  # nkCallStrLit,         # a call with a string literal
  # nkInfix,              # a call like (a + b)
  # nkPrefix,             # a call like !a
  # nkPostfix,            # export marker (*)
  # nkHiddenCallConv,     # an implicit type conversion via a type converter (compiler-internal)

  # nkExprEqExpr,         # a named parameter with equals: ''expr = expr''
  # nkExprColonExpr,      # a named parameter with colon: ''expr: expr''
  # nkIdentDefs,          # a definition like `a, b: typeDesc = expr`
  nkVarTuple,           # a ``var (a, b) = expr`` construct
  # nkPar,                # syntactic (); may be a tuple constructor
  # nkObjConstr,          # object constructor: T(a: 1, b: 2)
  # nkCurly,              # syntactic {}
  # nkCurlyExpr,          # an expression like a{i}
  # nkBracket,            # syntactic []
  # nkBracketExpr,        # an expression like a[i..j, k]
  # nkPragmaExpr,         # an expression like a{.pragmas.}
  # nkRange,              # an expression like i..j
  # nkDotExpr,            # a.b
  # nkCheckedFieldExpr,   # a.b, but b is a field that needs to be checked (compiler-internal)
  # nkDerefExpr,          # a^
  # nkIfExpr,             # if as an expression
  # nkElifExpr,           # (sub-node of nkIfExpr)
  # nkElseExpr,           # (sub-node of nkIfExpr)
  # nkLambda,             # lambda expression
  nkDo,                 # lambda block as trailing proc param (blocked: do_missing_space)
  # nkAccQuoted,          # `a` as a node

  # nkTableConstr,        # a table constructor {expr: expr}
  # nkBind,               # ``bind expr`` node
  # nkClosedSymChoice,    # symbol choice node: a list of nkSyms (compiler-internal)
  # nkOpenSymChoice,      # symbol choice node: a list of nkSyms (compiler-internal)
  # nkHiddenStdConv,      # an implicit standard type conversion (compiler-internal)
  # nkHiddenSubConv,      # an implicit type conversion from a subtype (compiler-internal)
  # nkConv,               # a type conversion
  # nkCast,               # a type cast
  # nkStaticExpr,         # a static expr
  # nkAddr,               # a addr expression
  # nkHiddenAddr,         # implicit address operator (compiler-internal)
  # nkHiddenDeref,        # implicit ^ operator (compiler-internal)
  # nkObjDownConv,        # down conversion between object types (compiler-internal)
  # nkObjUpConv,          # up conversion between object types (compiler-internal)
  # nkChckRangeF,         # range check for floats (compiler-internal)
  # nkChckRange64,        # range check for 64 bit ints (compiler-internal)
  # nkChckRange,          # range check for ints (compiler-internal)
  # nkStringToCString,    # string to cstring (compiler-internal)
  # nkCStringToString,    # cstring to string (compiler-internal)
                        # end of expressions

  # nkAsgn,               # a = b
  # nkFastAsgn,           # internal node for a fast ``a = b`` (compiler-internal)
  nkGenericParams,      # generic parameters
  # nkFormalParams,       # formal parameters
  nkOfInherit,          # inherited from symbol

  # nkImportAs,           # a 'as' b in an import statement
  # nkProcDef,            # a proc
  nkMethodDef,          # a method
  nkConverterDef,       # a converter
  nkMacroDef,           # a macro
  nkTemplateDef,        # a template
  nkIteratorDef,        # an iterator

  # nkOfBranch,           # used inside case statements (sub-node)
  # nkElifBranch,         # used in if statements (sub-node)
  # nkExceptBranch,       # an except section (sub-node)
  # nkElse,               # an else part (sub-node)
  nkAsmStmt,            # an assembler block
  nkPragma,             # a pragma statement (expression form done, statement form missing)
  nkPragmaBlock,        # a pragma with a block
  nkIfStmt,             # an if statement (expression form done)
  nkWhenStmt,           # a when statement (expression form done)
  nkForStmt,            # a for statement
  # nkParForStmt,         # a parallel for statement (compiler-internal)
  nkWhileStmt,          # a while statement
  nkCaseStmt,           # a case statement (expression form done)
  nkTypeSection,        # a type section (consists of type definitions)
  # nkVarSection,         # a var section
  # nkLetSection,         # a let section
  # nkConstSection,       # a const section
  # nkConstDef,           # a const definition
  nkTypeDef,            # a type definition
  nkYieldStmt,          # the yield statement as a tree
  nkDefer,              # the 'defer' statement
  nkTryStmt,            # a try statement (expression form done)
  # nkFinally,            # a finally section (sub-node)
  nkRaiseStmt,          # a raise statement
  nkReturnStmt,         # a return statement
  nkBreakStmt,          # a break statement
  nkContinueStmt,       # a continue statement
  nkBlockStmt,          # a block statement (expression form done)
  nkStaticStmt,         # a static statement
  # nkDiscardStmt,        # a discard statement
  # nkStmtList,           # a list of statements
  # nkImportStmt,         # an import statement
  # nkImportExceptStmt,   # an import x except a statement
  nkExportStmt,         # an export statement
  nkExportExceptStmt,   # an 'export except' statement
  # nkFromStmt,           # a from * import statement
  # nkIncludeStmt,        # an include statement
  nkBindStmt,           # a bind statement
  nkMixinStmt,          # a mixin statement
  nkUsingStmt,          # an using statement
  # nkCommentStmt,        # a comment statement
  nkStmtListExpr,       # a statement list followed by an expr (blocked: stmtlistexpr_nosemicolon)
  # nkBlockExpr,          # a statement block ending in an expr
  # nkStmtListType,       # a statement list ending in a type (compiler-internal)
  # nkBlockType,          # a statement block ending in a type (compiler-internal)

  nkWith,               # distinct with `foo`
  nkWithout,            # distinct without `foo`

  # nkTypeOfExpr,         # type(1+2)
  nkObjectTy,           # object body
  nkTupleTy,            # tuple body
  nkTupleClassTy,       # tuple type class
  nkTypeClassTy,        # user-defined type class
  nkStaticTy,           # ``static[T]``
  nkRecList,            # list of object parts
  nkRecCase,            # case section of object
  nkRecWhen,            # when section of object
  nkRefTy,              # ``ref T``
  nkPtrTy,              # ``ptr T``
  nkVarTy,              # ``var T``
  nkConstTy,            # ``const T``
  nkOutTy,              # ``out T``
  nkDistinctTy,         # distinct type
  nkProcTy,             # proc type
  nkIteratorTy,         # iterator type
  # nkSinkAsgn,           # '=sink(x, y)' (compiler-internal)
  nkEnumTy,             # enum body
  nkEnumFieldDef,       # `ident = expr` in an enumeration
  # nkArgList,            # argument list (compiler-internal)
  # nkPattern,            # a special pattern; used for matching (compiler-internal)
  # nkHiddenTryStmt,      # a hidden try statement (compiler-internal)
  # nkClosure,            # (prc, env)-pair (compiler-internal)
  # nkGotoState,          # used for the state machine (compiler-internal)
  # nkState,              # give a label to a code section (compiler-internal)
  # nkBreakState,         # special break statement for easier code generation (compiler-internal)
  nkFuncDef,            # a func
  # nkTupleConstr,        # a tuple constructor
  # nkError,              # erroneous AST node (compiler-internal)
  # nkModuleRef,          # for .rod file support (compiler-internal)
  # nkReplayAction,       # for .rod file support (compiler-internal)
  # nkNilRodNode,         # for .rod file support (compiler-internal)
  # nkOpenSym,            # container for captured sym (compiler-internal)

