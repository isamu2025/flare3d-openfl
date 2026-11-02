package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import flare.basic.*;
import flare.core.*;
import flare.utils.*;

/**
 * Texture painting / Custom projection example.
 * 
 * @author Ariel Nehmad.
 */
class Test65_CustomProjection extends Sprite 
{
	private var scene:Scene3D;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this);
		scene.autoResize = true;
		scene.addChildFromFile( "elsa.zf3d" );
		
		// this is just to avoid the automatic set of the camera that comes with the model.
		scene.allowImportSettings = false;
		
		scene.camera = new Camera3D();
		scene.camera.orthographic = true;
		scene.camera.projection = Matrix3DUtils.buildOrthoProjection( -200, 200, -120, 120, 0, 1000 );
		scene.camera.z = -150;

		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}

	private function postRenderEvent(e:Event):Void 
	{
		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			_renderFrames++;
			if (_renderFrames >= 15) {
				saveScreenshot("test65.png");
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
			var b = new openfl.display.BitmapData(w, h, false, 0x505050);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(b);
			}
			var pngBytes = b.encode(b.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				#end
			}
		} catch (e:Dynamic) {
			trace("Error saving screenshot: " + e);
		}
	}
}
