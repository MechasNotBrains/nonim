int foo (int const x, int const y) {
  switch (x) {
    case 1: {
      switch (y) {
        case 10: {
          return 100;
        } break;
        default: {
          return 0;
        } break;
      }
    } break;
    default: {
      return 0;
    } break;
  }
}
