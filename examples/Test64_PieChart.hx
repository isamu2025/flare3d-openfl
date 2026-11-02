package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Vector3D;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;

/**
 * @author Ariel Nehamd
 */
class Test64_PieChart extends Sprite
{
	private var scene:Scene3D;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		// creates a new 3d scene.
		scene = new Viewer3D( this, null, 0.2 );
		scene.lights.setGamma();
		scene.autoResize = true;
		scene.camera.setPosition( 20, 30, -40 );
		scene.camera.lookAt( 0, 0, 0 );
		trace('Test64 init camPos: ' + scene.camera.getPosition(false));
		
		var specular:SpecularFilter = new SpecularFilter();
		
		// PieChart source can be found in flare.primitives within the examples folder.
		scene.addChild( new PieChart3D( 0, 25, 20, 6, new Shader3D( "", [new ColorFilter(0x304050), specular] ) ) );
		scene.addChild( new PieChart3D( 25, 60, 20, 8, new Shader3D( "", [new ColorFilter(0x805010), specular] ) ) );
		scene.addChild( new PieChart3D( 60, 80, 20, 10, new Shader3D( "", [new ColorFilter(0x601020), specular] ) ) );
		scene.addChild( new PieChart3D( 80, 100, 20, 12, new Shader3D( "", [new ColorFilter(0x907060), specular] ) ) );

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
			if (_renderFrames == 10) {
				saveScreenshot("test64.png");
				saveScreenshot("test64_angle1.png");
				// Switch to side view matching Reference 2
				scene.camera.setPosition(-28, 4, 42);
				scene.camera.lookAt(0, 5, 0);
			} else if (_renderFrames == 20) {
				saveScreenshot("test64_angle2.png");
				// Switch to top-down view matching Reference 3
				scene.camera.setPosition(0, 52, -6);
				scene.camera.lookAt(0, 0, 0);
			} else if (_renderFrames == 30) {
				saveScreenshot("test64_angle3.png");
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
