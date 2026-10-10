#define debug_mode 1
#if debug_mode
  int const level = 2;
#else
  int const level = 0;
#endif
#if defined(linux)
  int const platform = 1;
  #if debug_mode
    int const verbose = 1;
  #endif
#endif
#if defined(__linux__)
  #define unix
#endif
#if defined(DEBUG)
  #define build_debug true
#else
  #define build_debug false
#endif
int trace () {
  #if debug_mode
  {
    int const depth = 3;
    return depth;
  }
  #endif
  return 0;
}
