type Vec4 = object
  x :float
proc deref (V :ptr Vec4) :Vec4= return V[]
