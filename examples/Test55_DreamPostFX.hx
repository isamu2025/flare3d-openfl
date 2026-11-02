package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.utils.ByteArray;
import flare.basic.Scene3D;
import flare.basic.Viewer3D;
import flare.core.Texture3D;
import flare.flsl.FLSLMaterial;

/**
 * @author Ariel Nehmad
 */
class Test55_DreamPostFX extends Sprite 
{
	private var scene:Scene3D;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this );
		scene.skipFrames = false;
		scene.autoResize = true;
		scene.addChildFromFile( "planet.zf3d" );
		scene.targetTexture = new Texture3D( new Point( 1024, 512 ), true );
		
		var flslBytes:ByteArray = null;
		#if sys
		try {
			var bytes = sys.io.File.getBytes("assets/dream.flsl.compiled");
			flslBytes = ByteArray.fromBytes(bytes);
		} catch (e:Dynamic) {
			try {
				var bytes = sys.io.File.getBytes("dream.flsl.compiled");
				flslBytes = ByteArray.fromBytes(bytes);
			} catch (e:Dynamic) {}
		}
		#end
		
		scene.targetFilters.push( new FLSLMaterial( "dream", flslBytes ) );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}

	private var _fans:Array<flare.core.Pivot3D> = [];

	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
		if (scene != null && scene.camera != null) {
			scene.camera.setPosition(83.7196, 179.7592, -238.0426);
			scene.camera.lookAt(0, 0, 0);
			scene.camera.fieldOfView = 75;
			scene.camera.near = 1.0;
			scene.camera.far = 100000;
			if (Std.isOfType(scene, Viewer3D)) {
				var v:Viewer3D = cast scene;
				v.setTarget(0, 0, 0);
				v.syncOrbitFromCamera();
				v.updateCameraOrbit();
			}
		}
		_fans = [];
		collectFans(scene);
	}

	private function collectFans(node:flare.core.Pivot3D):Void 
	{
		if (node == null) return;
		if (node.name != null && node.name.toLowerCase().indexOf("fan") != -1) {
			_fans.push(node);
		}
		for (c in node.children) {
			collectFans(c);
		}
	}

	private function updateEvent(e:Event):Void 
	{
		for (f in _fans) {
			f.rotateY(2.0);
		}
	}

	private function postRenderEvent(e:Event):Void 
	{
		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames >= 20) {
				saveScreenshot("test55.png");
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
		} catch (e:Dynamic) {}
	}
}
