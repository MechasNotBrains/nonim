typedef struct Data {
  int name;
  bool flag;
} Data;
void foo () {
  Data const x = (Data){.name = 42, .flag = true};
}
