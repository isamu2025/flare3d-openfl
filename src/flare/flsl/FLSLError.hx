package flare.flsl;

import openfl.errors.Error;

/**
 * FLSLError represents compile-time syntax and semantic errors in FLSL shaders.
 */
class FLSLError extends Error {
    public var line:Int;
    public var pos:Int;

    public function new(message:Dynamic = "", line:Int = -1, pos:Int = -1) {
        super(Std.string(message));
        this.line = line;
        this.pos = pos;
    }
}
