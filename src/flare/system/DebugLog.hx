package flare.system;

class DebugLog {
    public static var logFile:String = null;
    public static var enableFileLog:Bool = false;

    public static function getLogFile():String {
        if (logFile != null) return logFile;
        #if sys
        try {
            var prog = Sys.programPath();
            if (prog != null && prog != "") {
                var pDir = haxe.io.Path.directory(prog);
                logFile = haxe.io.Path.join([pDir, "flare3d_debug.log"]);
                return logFile;
            }
        } catch (e:Dynamic) {}
        logFile = "flare3d_debug.log";
        return logFile;
        #else
        return "flare3d_debug.log";
        #end
    }

    public static function log(msg:String):Void {
        var stamped = "[" + Date.now().toString() + "] " + msg;
        #if sys
        try {
            Sys.println(stamped);
        } catch (e1:Dynamic) {}
        try {
            var filePath = getLogFile();
            if (!enableFileLog) return;
            var out = sys.io.File.append(filePath, false);
            out.writeString(stamped + "\n");
            out.close();
        } catch (eLocal:Dynamic) {}
        #else
        trace(stamped);
        #end
    }
}
