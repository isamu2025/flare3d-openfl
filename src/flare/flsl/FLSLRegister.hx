package flare.flsl;

/**
 * FLSLRegister manages Stage3D hardware register allocations (va, vc, vt, v, fs, fc, ft).
 */
class FLSLRegister {
    public var name:String;
    public var maxRegisters:Int;
    public var memory:Array<Dynamic>;

    public function new(name:String = "", maxRegisters:Int = 128) {
        this.name = name;
        this.maxRegisters = maxRegisters;
        this.memory = [];
    }

    public function reset():Void {
        memory = [];
    }
}
