proc main () :void=
  for fb* in mutable.data.buffer.items: fb.destroy(gpu.device.logical.addr, gpu.instance.addr)
