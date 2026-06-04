type Data     = ?var ptr anyopaque
type Callback = ?ptr proc (J :var ptr jera.Engine; G :jera.game.Data) :anyerror!void

# pub const Data = ?*anyopaque;
# pub const Callback = ?*const fn (J :*jera.Engine, G :jera.game.Data) anyerror!void;
