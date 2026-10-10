int const* convert (void const* const value) {
  return (int const*)(value);
}
int widen (char const value) {
  return (int)(value);
}
void const* erase (int const* const value) {
  return (void const*)(value);
}
