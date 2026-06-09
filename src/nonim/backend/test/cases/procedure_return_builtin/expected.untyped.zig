pub inline fn vec4_simd (V :*const Vec4) @Vector(4, vector.Float) {
  return V.data;
}
