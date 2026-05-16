#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from minibuild as B import build
const astTF = B.dependency("astTF", "https://codeberg.org/heysokam/astTF", path= "spec")
B.program("nonim/nimcheck.nim").build()
B.program("nonim.nim",
   deps = @[astTF],
  ).build(run=true)
