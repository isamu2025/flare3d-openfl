package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.utils.ByteArray;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.materials.*;
import flare.flsl.*;
import flare.primitives.*;

/**
 * @author Ariel Nehmad
 */
class Test46_PostFXTest2_Bloom extends Sprite 
{
	private static var bloomData:ByteArray;
	
	private var scene:Viewer3D;
	private var quad:Quad;
	private var bloomTexture:Texture3D;
	private var bloomMaterial:FLSLMaterial;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		#if sys
		try {
			var bytes = sys.io.File.getBytes("assets/bloom.flsl.compiled");
			bloomData = ByteArray.fromBytes(bytes);
		} catch (e:Dynamic) {
			try {
				var bytes = sys.io.File.getBytes("bloom.flsl.compiled");
				bloomData = ByteArray.fromBytes(bytes);
			} catch (e:Dynamic) {}
		}
		#end

		scene = new Viewer3D( this, null, 0.1 );
		scene.registerClass( ZF3DLoader );
		scene.autoResize = true;
		scene.skipFrames = false;
		scene.antialias = 2;
		scene.clearColor.setTo( 0.44, 0.44, 0.44 );
		
		scene.lights.defaultLight = null;
		scene.lights.ambientColor.setTo( 0.6, 0.6, 0.6 );
		
		bloomTexture = new Texture3D( new Point( 256, 256 ), true );
		
		bloomMaterial = new FLSLMaterial( "bloom", bloomData );
		bloomMaterial.params.bloomTexture.value = bloomTexture;
		bloomMaterial.params.intensity.value[0] = 3;
		bloomMaterial.params.power.value[0] = 2;
		
		quad = new Quad( "bloom", 0, 0, 0, 0, true, bloomMaterial );
		quad.scene = scene;
		
		scene.addChildFromFile( "chess.zf3d" );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
	}
	
	private var _isAuto:Bool = false;

	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
		if (scene != null && scene.camera != null) {
			scene.camera.fieldOfView = 75;
			scene.camera.near = 1;
			scene.camera.far = 100000;
			scene.camera.setPosition(77.56107330322266, 104.50699615478516, -188.580322265625);
			scene.camera.lookAt(0, 0, 0);
			scene.setTarget(0, 0, 0);
			scene.syncOrbitFromCamera();
		}
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function postRenderEvent(e:Event):Void 
	{
		scene.render( scene.camera, false, bloomTexture );
		quad.draw();

		#if sys
		if (!_isAuto) {
			for (flagPath in ["auto_exit.flag", "bin/neko/bin/auto_exit.flag", "../../auto_exit.flag", "../../../auto_exit.flag"]) {
				if (sys.FileSystem.exists(flagPath)) {
					_isAuto = true;
					try { sys.FileSystem.deleteFile(flagPath); } catch (e:Dynamic) {}
				}
			}
			if ((Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
				|| (Sys.args().indexOf("--auto-exit") != -1)
				|| (Sys.args().indexOf("auto") != -1)) {
				_isAuto = true;
			}
		}
		if (_isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames >= 20) {
				saveScreenshot("test46.png");
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
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}
}
