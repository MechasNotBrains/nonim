proc foo () :void=
  var file =
    try: download(mirror)
    except: continue
