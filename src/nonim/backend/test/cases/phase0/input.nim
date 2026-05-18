let max :int= 10
var count :int= 0
let step :int= 1

proc increment (value :int; amount :int) :int=
  return value + amount

proc accumulate (limit :int) :int=
  var total :int= 0
  var current :int= 0
  while current < limit:
    total = increment(total, step)
    current = current + 1
    if current == 5:
      discard increment(current, 0)
      continue
    if total > 100:
      break
  return total

proc run () :int=
  let output :int= accumulate(max)
  discard count
  return output
