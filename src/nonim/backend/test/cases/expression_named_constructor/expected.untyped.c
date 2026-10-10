typedef struct Thing {
  int x;
  int y;
} Thing;
void foo () {
  Thing const t = (Thing){.x = 1, .y = 2};
}
