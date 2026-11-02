package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Vector3D;
import flare.basic.Scene3D;
import flare.basic.Viewer3D;
import flare.core.Texture3D;
import flare.materials.Shader3D;
import flare.materials.filters.TextureMapFilter;
import flare.primitives.Cube;
import flare.utils.Vector3DUtils;
import flare.system.Device3D;

/**
 * @author Ariel Nehmad
 */
class Test57_CustomRender2 extends Sprite 
{
	private var scene:Scene3D;
	private var cube:Cube;
	private var list:Array<Dynamic> = new Array<Dynamic>();
	private var texFilter:TextureMapFilter;
	private var material:Shader3D;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.4 );
		scene.autoResize = true;
		scene.antialias = 2;
		scene.skipFrames = false;
		scene.camera.setPosition( 25, 50, -75 );
		scene.camera.lookAt( 0, 0, 0 );
		
		texFilter = new TextureMapFilter( new Texture3D( "tree.png" ) );
		material = new Shader3D( "mat", [ texFilter ] );
		cube = new Cube( "cube", 10, 10, 10, 1, material );
		cube.scene = scene;
		
		for (i in 0...100)
		{
			var pos:Vector3D = Vector3DUtils.random( -50, 50 );
			var speedX:Float = Math.random() * 0.1 - 0.05;
			var speedY:Float = Math.random() * 0.1 - 0.05;
			list.push( { pos:pos, offset:new Point(), speedX:speedX, speedY:speedY } );
		}
		
		scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function renderEvent(e:Event):Void 
	{
		var length:Int = list.length;
		for (i in 0...length)
		{
			var obj:Dynamic = list[i];
			obj.offset.x += obj.speedX;
			obj.offset.y += obj.speedY;
			texFilter.offsetX = obj.offset.x;
			texFilter.offsetY = obj.offset.y;
			cube.setPosition( obj.pos.x, obj.pos.y, obj.pos.z );
			Device3D.currentMesh = null;
			cube.draw( false );
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
			if (_renderFrames >= 20) {
				saveScreenshot("test57.png");
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
