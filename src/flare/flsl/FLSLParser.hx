package flare.flsl;

/**
 * FLSLParser builds semantic AST and shader programs from token streams.
 */
class FLSLParser {
    public static inline var INCLUDE_NONE:Int = 0;
    public static inline var INCLUDE_ALL:Int = 1;
    public static inline var INCLUDE_TOPLEVEL:Int = 2;

    public function new() {}

    public function parse(tokens:Array<FLSLToken>):FLSLProgram {
        return new FLSLProgram();
    }
}
