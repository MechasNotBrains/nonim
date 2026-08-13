proc thing (P :ptr Data): !void=
  if P.valid(): try P.one()
  try P.two()
