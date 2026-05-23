- [ ] Statement comments are lost
  ```nim
  proc vec4_simd (V :ptr Vec4) :Vec4_SIMD {.inline.}= return V.data
    ## Converts the given Vector into its SIMD representation
  ```

