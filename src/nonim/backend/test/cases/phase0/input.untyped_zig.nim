let max :isize= 10
var count :isize= 0
let step :isize= 1

proc increment (value :isize; amount :isize) :isize=
  return value + amount

proc accumulate (limit :isize) :isize=
  var total :isize= 0
  var current :isize= 0
  while current < limit:
    total = increment(total, step)
    current = current + 1
    if current == 5:
      discard increment(current, 0)
      continue
    if total > 100:
      break
  return total

proc run () :isize=
  let output :isize= accumulate(max)
  discard count
  return output
