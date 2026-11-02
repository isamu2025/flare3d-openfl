package flare.flsl;

/**
 * FLSLToken represents a single lexical token in the FLSL shader parser.
 */
class FLSLToken {
    public static inline var WORD:String = "word";
    public static inline var RESERVED:String = "reserved";
    public static inline var KEYWORD:String = "keyw";
    public static inline var PREPROCESOR:String = "preproc";
    public static inline var COMMENT:String = "comment";
    public static inline var NUMBER:String = "number";
    public static inline var OPERATOR:String = "operator";
    public static inline var STRING:String = "string";

    public var text:String;
    public var type:String;
    public var line:Int;
    public var pos:Int;

    public function new(text:String = "", type:String = "", line:Int = 0, pos:Int = 0) {
        this.text = text;
        this.type = type;
        this.line = line;
        this.pos = pos;
    }
}
