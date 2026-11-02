package flare.flsl;

/**
 * FLSLTokenizer splits raw FLSL shader source text into tokens.
 */
class FLSLTokenizer {
    public var debug:Bool = false;
    public var dependences:Array<String>;

    public function new() {
        dependences = [];
    }

    public function tokenize(source:String):Array<FLSLToken> {
        var tokens = new Array<FLSLToken>();
        if (source == null || source == "") return tokens;

        var line = 1;
        var len = source.length;
        var i = 0;

        while (i < len) {
            var c = source.charAt(i);
            if (c == "\n") {
                line++;
                i++;
            } else if (c == " " || c == "\t" || c == "\r") {
                i++;
            } else if (c == "/" && i + 1 < len && source.charAt(i + 1) == "/") {
                // Single line comment
                var start = i;
                while (i < len && source.charAt(i) != "\n") i++;
                tokens.push(new FLSLToken(source.substring(start, i), FLSLToken.COMMENT, line, start));
            } else if (c == "#") {
                var start = i;
                while (i < len && source.charAt(i) != "\n") i++;
                tokens.push(new FLSLToken(source.substring(start, i), FLSLToken.PREPROCESOR, line, start));
            } else {
                var start = i;
                while (i < len && " \t\r\n;,(){}+-*/%<>=!&|^".indexOf(source.charAt(i)) == -1) i++;
                if (start == i) {
                    tokens.push(new FLSLToken(c, FLSLToken.OPERATOR, line, start));
                    i++;
                } else {
                    var word = source.substring(start, i);
                    tokens.push(new FLSLToken(word, FLSLToken.WORD, line, start));
                }
            }
        }
        return tokens;
    }
}
