proc cleanup (f :i64) :i64=
  defer:
    close(f)
    discard free(f)
  return process(f)
