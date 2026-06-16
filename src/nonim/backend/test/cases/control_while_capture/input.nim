proc process (pixels :Pixels) :void=
  while pixels.next() as pixel:
    discard pixel
