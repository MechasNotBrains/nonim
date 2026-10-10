var other :int= 0
let thing1 :ptr int= addr other
let thing2 :ptr int= other.addr
let thing3 :ptr int= addr(other)
