#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Postprocessor for the untyped backends.
#__________________________________________|
import ./includes

proc processZigIncludes *(output :string; inputPath :string) :string=
  includes.processIncludes(output, inputPath)
