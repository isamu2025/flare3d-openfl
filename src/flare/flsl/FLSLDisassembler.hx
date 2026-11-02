package flare.flsl;

import openfl.utils.ByteArray;

/**
 * FLSLDisassembler translates compiled binary AGAL/FLSL bytecode back to human-readable assembly text.
 */
class FLSLDisassembler extends FLSL {
    public static function print(bytes:ByteArray):String {
        return "// AGAL Disassembly\n";
    }

    public static function printVertex(bytes:ByteArray):String {
        return "// Vertex AGAL\n";
    }

    public static function printFragment(bytes:ByteArray):String {
        return "// Fragment AGAL\n";
    }
}
