package flare.flsl;

/**
 * Base class for all FLSL (Flare3D Shading Language) elements, variables, and scopes.
 */
class FLSL {
    public var name:String;
    public var semantic:String;
    public static var agalVersion:Int = 1;
    public var version:Int = 1;

    public function new(name:String = null) {
        this.name = name;
    }
}
