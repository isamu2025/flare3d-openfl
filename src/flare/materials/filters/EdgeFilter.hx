package flare.materials.filters;

import openfl.Vector;

/**
 * EdgeFilter implements inverted hull silhouette outline rendering.
 * Extrudes vertices along vertex normal by `edge` units and renders solid `color` with front-face culling.
 * Corresponds to edgeFilter.flsl in Flare3D.
 */
class EdgeFilter extends Filter3D {
    public var edge:Float = 1.0;
    public var color:Vector<Float>;
    public var blendMode:Dynamic;

    public function new(edge:Float = 1.0, color:Dynamic = null, blendMode:Dynamic = null) {
        super("edgeFilter");
        this.edge = edge;
        this.blendMode = blendMode;
        if (color != null && Std.isOfType(color, Array)) {
            var arr:Array<Float> = cast color;
            this.color = new Vector<Float>(4);
            this.color[0] = arr.length > 0 ? arr[0] : 1.0;
            this.color[1] = arr.length > 1 ? arr[1] : 1.0;
            this.color[2] = arr.length > 2 ? arr[2] : 1.0;
            this.color[3] = arr.length > 3 ? arr[3] : 1.0;
        } else if (color != null && Std.isOfType(color, Int)) {
            var c:Int = cast color;
            this.color = new Vector<Float>(4);
            this.color[0] = ((c >> 16) & 0xFF) / 255.0;
            this.color[1] = ((c >> 8) & 0xFF) / 255.0;
            this.color[2] = (c & 0xFF) / 255.0;
            this.color[3] = 1.0;
        } else if (color != null) {
            this.color = cast color;
        } else {
            this.color = new Vector<Float>(4);
            this.color[0] = 1.0;
            this.color[1] = 1.0;
            this.color[2] = 1.0;
            this.color[3] = 1.0;
        }
    }

    public function clone():EdgeFilter {
        var copy = new EdgeFilter(edge, color, blendMode);
        return copy;
    }
}
