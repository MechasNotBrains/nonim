proc foo (P :ptr Type) :void=
  P.value =
    try: store(P)
    except err: return
