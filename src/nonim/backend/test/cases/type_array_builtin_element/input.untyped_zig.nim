proc roots (a :anytype) :array[2, @TypeOf(a)]=
  let result :array[2, @TypeOf(a)]= [a, a]
  return result
