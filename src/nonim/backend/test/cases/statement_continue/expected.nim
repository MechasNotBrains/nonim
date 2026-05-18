proc skip_negatives (n :int)=
  var current :int= 0
  while current < n:
    current = current + 1
    if current < 0:
      continue

    discard current


