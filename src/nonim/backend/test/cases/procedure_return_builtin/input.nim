proc vec4_simd (V :ptr Vec4) : @Vector(4, vector.Float) {.inline.}= return V.data
