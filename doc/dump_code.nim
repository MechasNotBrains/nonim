proc a () :void=
  defer: discard foo(x)
  defer: foo(x)
