package flare.flsl;

/**
 * FLSLEngine tracks semantic bindings, global uniforms, and shader execution state.
 */
class FLSLEngine {
    public var semantics:Map<String, Dynamic>;
    public var defines:Map<String, Dynamic>;
    public var globals:Array<Dynamic>;

    public function new() {
        semantics = new Map<String, Dynamic>();
        defines = new Map<String, Dynamic>();
        globals = [];
    }
}
