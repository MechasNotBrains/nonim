proc thing (P :ptr Data) :void=
  if P.valid():
    P.one()
  elif P.stored() as fallback:
    P.two(fallback)
  else:
    P.three()
