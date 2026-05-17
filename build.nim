#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from minibuild as B import build
const astTF     = B.dependency("astTF",     "https://codeberg.org/heysokam/astTF", path= "spec")
const minibuild = B.dependency("minibuild", "https://github.com/MechasNotBrains/minibuild")
B.program("nonim/nimcheck.nim").build()
B.program("nonim/nimgen.nim").build()
B.program("nonim/minc.nim", deps= @[astTF, minibuild]).build()
B.program("nonim.nim",      deps= @[astTF, minibuild]).build()
