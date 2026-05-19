proc cleanup (f :int) :int=
  defer: close(f)
  return process(f)
