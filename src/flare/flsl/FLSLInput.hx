package flare.flsl;

/**
 * FLSLInput maps a vertex geometry attribute (position, normal, uv) to vertex shader inputs.
 */
class FLSLInput extends FLSL {
    public var attribute:String;
    public var format:String;

    public function new(name:String = null) {
        super(name);
    }

    public function clone():FLSLInput {
        var inp = new FLSLInput(name);
        inp.attribute = attribute;
        inp.format = format;
        inp.semantic = semantic;
        return inp;
    }
}
