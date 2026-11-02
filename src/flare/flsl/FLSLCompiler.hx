package flare.flsl;

/**
 * FLSLCompiler compiles FLSL shader source code into AGAL or target GPU bytecode.
 */
class FLSLCompiler {
    public static var libs:Map<String, Dynamic> = new Map();

    public static function compile(source:String, target:String = "agal"):FLSLProgram {
        var tokenizer = new FLSLTokenizer();
        var tokens = tokenizer.tokenize(source);
        var parser = new FLSLParser();
        return parser.parse(tokens);
    }
}
