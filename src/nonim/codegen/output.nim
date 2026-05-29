#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
# @deps nonim
import ../ast as astTF
import ../nimc/errors

type Target *{.pure.}= enum both, declaration, definition

type Module * = object
  path          *:string= ""
  declarations  *:string= ""
  definitions   *:string= ""

type Output * = object
  modules      *:seq[output.Module]= @[]
  parse_errors *:seq[ParseError]= @[]

func create *(_:typedesc[Output]) :Output= Output(modules: @[Module()])
func string *(
    Out    : var Output;
    module : astTF.Id;
    src    : string;
    target : output.Target;
  ) :void=
  if target in {both, declaration}: Out.modules[module].declarations.add(src)
  if target in {both, definition }: Out.modules[module].definitions.add(src)

