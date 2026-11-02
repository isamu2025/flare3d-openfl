package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.ByteArray;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.flsl.*;

/**
 * @author Ariel Nehmad
 */
class Test43_FLSLMaterialTest extends Sprite 
{
	private static var data:ByteArray;
	
	private var scene:Scene3D;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		#if sys
		try {
			var bytes = sys.io.File.getBytes("assets/example16.flsl.compiled");
			data = ByteArray.fromBytes(bytes);
		} catch (e:Dynamic) {
			try {
				var bytes = sys.io.File.getBytes("example16.flsl.compiled");
				data = ByteArray.fromBytes(bytes);
			} catch (e:Dynamic) {}
		}
		#end

		scene = new Viewer3D( this, null, 0.2 );
		scene.autoResize = true;
		scene.antialias = 2;
		scene.skipFrames = false;
		scene.backgroundColor = 0x404040;
		scene.camera = new Camera3D();
		scene.camera.fov = 45.0;
		if (Std.isOfType(scene, Viewer3D)) {
			var v:Viewer3D = cast scene;
			v.setTarget(-4.5, 6.5, 0);
		}
		scene.camera.setPosition( 168.2, 62.2, 161.2 );
		scene.camera.lookAt( -4.5, 6.5, 0 );
		if (Std.isOfType(scene, Viewer3D)) {
			cast(scene, Viewer3D).syncOrbitFromCamera();
		}
		scene.registerClass( ZF3DLoader );
		scene.addChildFromFile( "teapot2.zf3d" );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
		var material:FLSLMaterial = new FLSLMaterial( "shader", data );
			
		if (scene.context != null) {
			try { scene.context.enableErrorChecking = true; } catch (err:Dynamic) {}
		}
		
		for (param in material.params ) trace( param, param.value );
		
		scene.setMaterial( material );
	}

	private function postRenderEvent(e:Event):Void 
	{
		#if sys
		var hasFlag = false;
		try {
			if (sys.FileSystem.exists("auto_exit.flag")) {
				hasFlag = true;
				sys.FileSystem.deleteFile("auto_exit.flag");
			} else if (sys.FileSystem.exists("../../auto_exit.flag")) {
				hasFlag = true;
				sys.FileSystem.deleteFile("../../auto_exit.flag");
			}
		} catch (e:Dynamic) {}
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| hasFlag;
		if (isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames >= 20) {
				saveScreenshot("test43.png");
				Sys.exit(0);
			}
		}
		#end
	}

	private function saveScreenshot(filename:String):Void 
	{
		try {
			var w = stage != null ? stage.stageWidth : 800;
			var h = stage != null ? stage.stageHeight : 450;
			if (w <= 0) w = 800;
			if (h <= 0) h = 450;
			var b = new openfl.display.BitmapData(w, h, false, 0x404040);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(b);
			}
			var pngBytes = b.encode(b.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}
}
