#:_________________________________________________________
#  nonim  |  Copyright (C) Ivan Mar (sOkam!)  |  MPL-2.0  :
#:_________________________________________________________
from minibuild as B import build
# Dependencies
const astTF     = B.dependency("astTF",     "https://codeberg.org/heysokam/astTF", path= "spec")
const minibuild = B.dependency("minibuild", "https://github.com/MechasNotBrains/minibuild")
# Tests
const minitest  = B.dependency("minitest",  "https://codeberg.org/heysokam/minitest")
B.unit_test("nonim/test.nim", deps= @[astTF, minibuild, minitest]).build(run=true)
# Binaries
B.program("nonim/nimcheck.nim").build()
B.program("nonim/nimgen.nim").build()
B.program("nonim/minc.nim", deps= @[astTF, minibuild]).build()
B.program("nonim/minz.nim", deps= @[astTF, minibuild]).build()
B.program("nonim.nim",      deps= @[astTF, minibuild]).build()
