#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Invokes the Nim compiler as a library to obtain the typed AST.
## Registers sem + a custom collector pass that accumulates typed statements.
#_____________________________________________________________________________|
# @deps std
import std/compilesettings
# @deps nimc
import "$nim"/compiler/[
  ast, modules, options, llstream, condsyms,
  modulegraphs, idents, pathutils,
  passes, pipelines,
]


type CollectorContext = ref object of PPassContext
  statements :seq[PNode]

var collected_statements *:seq[PNode]

proc collector_open(graph :ModuleGraph; module :PSym; idgen :IdGenerator) :PPassContext=
  result = CollectorContext(statements: @[])

proc collector_process(context :PPassContext; node :PNode) :PNode=
  let collector = CollectorContext(context)
  if node != nil and node.kind != nkEmpty:
    collector.statements.add(node)
    collected_statements.add(node)
  return node

proc collector_close(graph :ModuleGraph; context :PPassContext; node :PNode) :PNode=
  return node

const collector_pass = makePass(collector_open, collector_process, collector_close)


type CompileResult * = object
  statements *:seq[PNode]


proc compile *(
    source   : string;
    filename : string = "input.nim";
  ) :CompileResult=
  collected_statements = @[]

  var conf = newConfigRef()
  var cache = newIdentCache()
  var graph = newModuleGraph(cache, conf)

  let stdlib = querySetting(SingleValueSetting.libPath)
  conf.searchPaths.add(AbsoluteDir stdlib)
  conf.libpath = AbsoluteDir stdlib

  initDefines(conf.symbols)
  defineSymbol(conf.symbols, "nimcheck")

  connectPipelineCallbacks(graph)
  registerPass(graph, semPass)
  registerPass(graph, collector_pass)
  setPipeLinePass(graph, SemPass)
  compilePipelineSystemModule(graph)

  collected_statements = @[]

  var module = graph.makeModule(filename)
  module.flags.incl sfMainModule
  var idgen = idGeneratorFromModule(module)

  let stream = llStreamOpen(source)
  processModule(graph, module, idgen, stream)

  result = CompileResult(statements: collected_statements)

