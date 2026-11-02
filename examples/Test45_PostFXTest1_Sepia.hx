package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.Lib;
import openfl.Lib.getTimer;
import openfl.utils.ByteArray;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.materials.*;
import flare.flsl.*;

/**
 * @author Ariel Nehmad
 */
class Test45_PostFXTest1_Sepia extends Sprite 
{
	private static var sepiaData:ByteArray;
	private static var gammaData:ByteArray;
	
	private var scene:Viewer3D;
	private var filter:FLSLMaterial;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		#if sys
		try {
			var bytes = sys.io.File.getBytes("assets/colorMatrix.flsl.compiled");
			sepiaData = ByteArray.fromBytes(bytes);
		} catch (e:Dynamic) {
			try {
				var bytes = sys.io.File.getBytes("colorMatrix.flsl.compiled");
				sepiaData = ByteArray.fromBytes(bytes);
			} catch (e:Dynamic) {}
		}
		#end

		scene = new Viewer3D( this, null, 0.15, 0 );
		scene.autoResize = true;
		scene.antialias = 2;
		scene.skipFrames = false;
		scene.lights.ambientColor.setTo( 0.4, 0.3, 0.2 );
		
		// if a target texture is defined, flare will render the scene into the texture
		// instead to render into the back buffer.
		scene.targetTexture = new Texture3D( new Point( 1024, 512 ), true );
		scene.targetTexture.mipMode = Texture3D.MIP_NONE;
		
		filter = new FLSLMaterial( "sepia", sepiaData );
		
		// define the material to be used to render the target texture.
		scene.targetFilters.push( filter );
		
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );

		scene.registerClass( ZF3DLoader );
		scene.addChildFromFile( "chess2.zf3d" );
	}
	
	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
		setupCamera();
	}

	public function setupCamera(
		posX:Float = -514.10,
		posY:Float = 163.14,
		posZ:Float = -93.58,
		targetX:Float = -153.87,
		targetY:Float = 52.56,
		targetZ:Float = -35.17
	):Void {
		if (scene == null || scene.camera == null) return;
		scene.camera.fieldOfView = 79.69;
		scene.camera.near = 10;
		scene.camera.far = 4000;
		scene.camera.setPosition(posX, posY, posZ);
		scene.camera.lookAt(targetX, targetY, targetZ);
		scene.setTarget(targetX, targetY, targetZ);
		scene.syncOrbitFromCamera();
	}

	private function updateEvent(e:Event):Void 
	{
		var b = Math.cos( getTimer() / 500 ) * 0.5 + 0.5;
		filter.params.blendValue.value[0] = b;
	}

	private var _isAuto:Bool = false;
	private var _savedNormal:Bool = false;
	private var _savedSepia:Bool = false;

	private function postRenderEvent(e:Event):Void 
	{
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
		if (!_isLoaded && scene != null && scene.children.length > 0) {
			_isLoaded = true;
			setupCamera();
		}
		if (_isAuto && _isLoaded) {
			_renderFrames++;
			var currentBlend:Float = filter.params.blendValue.value[0];
			if (!_savedNormal && currentBlend >= 0.90) {
				_savedNormal = true;
				saveScreenshot("test45_normal.png");
			}
			if (!_savedSepia && currentBlend <= 0.10) {
				_savedSepia = true;
				saveScreenshot("test45_sepia.png");
			}
			if ((_savedNormal && _savedSepia) || _renderFrames >= 200) {
				saveScreenshot("test45.png");
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
				try { sys.io.File.saveBytes("../../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}
}
