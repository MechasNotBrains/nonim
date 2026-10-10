type Data = object
  name :int
  flag :bool
proc foo ()=
  let x :Data= (name: 42, flag: true)
