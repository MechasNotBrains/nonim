# 3D math debug visualizer
const debug * = @This()
# @deps std
import @std
# @deps debug
from @minirender import Ui


#______________________________________
# @section Math Types
#____________________________
const vec4 = Vec4.create
from @minirender import Vec4
from @minirender import BiVec
from @minirender import Rotor
from @minirender import Mat4


#______________________________________
# @section Renderer
#____________________________
from @minirender import Color
from @minirender import Renderer
const create * = debug.Renderer.create;


#______________________________________
# @section Entry Point
#____________________________
proc main *() : !void=
  let render = try: debug.create(std.heap.page_allocator)
  defer: render.destroy()

  var ui = debug.Ui( .(
    .(name: "angle",    kind: .float, default_val: std.math.pi / 2.0,  min:  0.0, max: std.math.tau ),
    .(name: "velocity", kind: .vec3,  default_val: .( 2.0, 0.0, 0.5 ), min: -5.0, max: 5.0 ),
    .(name: "rotor",    kind: .bivec, default_val: .( 1.0, 0.0, 0.0 ), min: -1.0, max: 1.0 ),
  )).init();

  while not render.close():
    render.sync()
    render.clear(0.12, 0.1, 0.1)
    ui.update(render)

    render.begin()
    let vp      = render.camera.viewProjection(960.0 / 540.0)
    render.wvp  = vp.wvp
    render.view = vp.view
    render.grid(5.0, 1.0)
    render.axes(1.0)

    let velocity       = ui.getVec3("velocity")
    let rotation_plane = ui.getBivec("rotor")
    let rotation_angle = ui.getFloat("angle")

    let rot = Rotor.fromAnglePlane(rotation_angle, rotation_plane.normalize())
    render.rotor(rot, velocity, "velocity", Color.gray)
    render.rotor_basis(rot, velocity, Color.cyan_025, Color.magenta_025, Color.yellow_025)

    render.hud()
    render.end()

    ui.draw(render)
    render.present()

