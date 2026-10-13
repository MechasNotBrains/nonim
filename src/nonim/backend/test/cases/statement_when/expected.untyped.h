#ifndef H_input
#define H_input
#define debug_mode 1
#if debug_mode
  extern int const level;
#else
  extern int const level;
#endif
#if defined(linux)
  extern int const platform;
  #if debug_mode
    extern int const verbose;
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
int trace ();
#endif  // H_input
