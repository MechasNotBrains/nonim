const Bounds = @This().Type
const Type = block @struct:
  const Vector = f32

type aabb_CenterExtents = array[2, Bounds.Vector]

block test:
  echo("hello")
