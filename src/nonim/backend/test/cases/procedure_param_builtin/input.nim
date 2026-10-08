proc wait_eq (V :anytype; target : @TypeOf(V.raw)) :void=
  discard target
