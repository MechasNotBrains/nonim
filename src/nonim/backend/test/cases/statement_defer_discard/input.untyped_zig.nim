proc cleanup (f :i64) :i64=
  defer: discard close(f)
  return process(f)
