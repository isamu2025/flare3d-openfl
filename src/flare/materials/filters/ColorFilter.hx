package flare.materials.filters;

/**
 * ColorFilter provides constant RGB color and alpha tinting to geometry.
 */
class ColorFilter extends Filter3D {
    public var color:Int;
    public var blendMode:String;

    public function new(color:Int = 0xffffff, alpha:Float = 1.0, blendMode:String = null) {
        super("color");
        this.alpha = alpha;
        this.blendMode = blendMode;
        setColor(color);
    }

    public function setColor(c:Int):Void {
        this.color = c;
        this.r = ((c >> 16) & 0xff) / 255.0;
        this.g = ((c >> 8) & 0xff) / 255.0;
        this.b = (c & 0xff) / 255.0;
    }
}
