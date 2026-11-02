package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.ByteArray;
import openfl.Lib.getTimer;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;
import flare.flsl.*;

/**
 * @author Ariel Nehmad.
 */
class Test52_RotateTextureFilter extends Sprite 
{
	private var scene:Viewer3D;
	private var rtFilter:FLSLFilter;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.5 );
		scene.autoResize = true;
		scene.antialias = 2;
		scene.skipFrames = false;
		
		var flslBytes:ByteArray = null;
		#if sys
		try {
			var bytes = sys.io.File.getBytes("assets/rotateTextureFilter.flsl.compiled");
			flslBytes = ByteArray.fromBytes(bytes);
		} catch (e:Dynamic) {
			try {
				var bytes = sys.io.File.getBytes("rotateTextureFilter.flsl.compiled");
				flslBytes = ByteArray.fromBytes(bytes);
			} catch (e:Dynamic) {}
		}
		#end
		
		// initialize the filter and its params.
		rtFilter = new FLSLFilter( flslBytes );
		var tex = new Texture3D( "tree.png" );
		rtFilter.params.texture.value = tex;
		rtFilter.params.angles.value = [0.0, 0.0, 0.0];
		
		var customShader:Shader3D = new Shader3D( "material", [ rtFilter, new TextureMapFilter() ] );
		var cube:Cube = new Cube( "cube", 10, 10, 10, 1, customShader );
		
		scene.addChild( cube );
		scene.camera.setPosition( 10, 20, -20 );
		scene.camera.lookAt( 0, 0, 0 );
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		// calculate sin and cos values to avoid extra operations inside shader
		var angle:Float = ( getTimer() / 10 ) * Math.PI / 180;
		var arr:Array<Float> = cast rtFilter.params.angles.value;
		if (arr != null) {
			arr[0] = Math.cos( angle );
			arr[1] = Math.sin( angle );
			arr[2] = -Math.sin( angle );
		}
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
			if (_renderFrames <= 30) {
				var idxStr = (_renderFrames < 10 ? "0" : "") + _renderFrames;
				saveScreenshot("frame_" + idxStr + ".png");
			}
			if (_renderFrames == 20) {
				saveScreenshot("test52.png");
			}
			if (_renderFrames >= 30) {
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
