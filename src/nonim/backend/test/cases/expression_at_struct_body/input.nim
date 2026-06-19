proc Container (T :typedesc) :typedesc=
  return @struct:
    var items {.field.}:seq(T)
    var count {.field.}:u32
