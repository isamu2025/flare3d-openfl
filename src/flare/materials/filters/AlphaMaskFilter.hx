package flare.materials.filters;

/**
 * AlphaMaskFilter discards fragments with alpha values below a given threshold.
 */
class AlphaMaskFilter extends Filter3D {
    public var threshold:Float;
    public var blendMode:String;
    public var techniqueName:String;

    public function new(threshold:Float = 0.5) {
        super("alphaMask");
        this.threshold = threshold;
    }
}
