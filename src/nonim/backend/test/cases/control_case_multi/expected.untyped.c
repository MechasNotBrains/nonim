int foo (int const x) {
  switch (x) {
    case 1: /* fall-through */
    case 2: {
      return 10;
    } break;
    case 3: {
      return 30;
    } break;
    default: {
      return 0;
    } break;
  }
}
