package flare.materials.filters;

/**
 * VertexColorFilter blends vertex colors from a geometry stream into surface shading.
 */
class VertexColorFilter extends Filter3D {
    public var channel:Int;
    public var blendMode:String;

    public function new(channel:Int = 0, blendMode:String = null) {
        super("vertexColor");
        this.channel = channel;
        this.blendMode = blendMode;
    }
}
