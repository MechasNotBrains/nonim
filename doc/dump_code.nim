proc roots (a :anytype) :array[2, @TypeOf(a)]=
  var result :array[2, @TypeOf(a)]= [a, a]
  return result
