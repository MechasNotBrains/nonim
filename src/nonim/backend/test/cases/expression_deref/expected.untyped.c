typedef struct Vec4 {
  float x;
} Vec4;
Vec4 deref (Vec4 const* const V) {
  return *V;
}
