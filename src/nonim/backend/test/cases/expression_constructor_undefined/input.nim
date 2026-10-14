type Thing = object
  value :int

proc thing_reset (thing :var ptr Thing) :void=
  thing[] = Thing(_)
