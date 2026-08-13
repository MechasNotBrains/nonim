proc thing (P :ptr Data) :void=
  if P.first() as tag:
    if P.second():
      P.one(tag)
  else:
    P.two()
