const vector = @This()

const (X, Y, Z, W) = (0, 1, 2, 3)

const Float = f32;
type Vec4 = object
  data    :array[4, vector.Float]
  create  {.alias: vector.vec4.}:proc
  add     {.alias: vector.vec4_add.}:proc

proc vec4 (x,y,z,w :f32) :Vec4= return (data: [x,y,z,w])
proc vec4_distance (V :ptr Vec4; other :Vec4) :Vec4 {.inline.}= return other.sub(V[]).len()

