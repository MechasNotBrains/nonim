#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
## Preprocessor for the untyped backends.
#________________________________________________________|
import ./includes

proc processIncludes *(source :string; inputPath :string) :string=
  includes.processIncludes(source, inputPath, includes.sourceExtensions)
