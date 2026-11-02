package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.primitives.*;

/**
 * Flare3D Example 37: Debug Primitives
 * Matches original ActionScript 3 Test37_DebugPrimitives
 */
class Test37_DebugPrimitives extends Sprite 
{
	private var scene:Scene3D;
	private var shapes:Pivot3D;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this, null, 0.4 );
		scene.autoResize = true;
		scene.antialias = 2;
		
		scene.camera = new Camera3D();
		scene.camera.far = 10000000;
		scene.camera.setPosition( 0, 10, 30 );
		scene.camera.lookAt( 0, 0, 0 );
		
		scene.clearColor.setTo( 64 / 255.0, 64 / 255.0, 64 / 255.0 );
		
		scene.addChild( new Radius( "radius", 5 ) );
		scene.addChild( new Dummy( "dummy", 8, 1, 0x8080ff ) ).x = -10;
		scene.addChild( new Dot( "point", 5, 0xffff00 ) ).x = 10;
		scene.addChild( new Cross( "cross", 10, 0x00ff00 ) ).z = -10;
		scene.addChild( new Quad( "quad", 30, 60, 120, 120 ) );
		
		var mesh:Mesh3D = new Cylinder( "cyl", 4, 10, 30 );
		mesh.setPosition( 0, -5, 10 );
		mesh.addChild( new DebugWireframe( mesh, 0xff0000 ) );
		mesh.parent = scene;
		
		var light:Light3D = new Light3D();
		light.infinite = false;
		light.radius = 5;
		light.setPosition( -10, 10, -10 );
		light.addChild( new DebugLight( light ) );
		light.parent = scene;
		
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addChildFromFile( "shapes.zf3d" );

		scene.addEventListener( Scene3D.POSTRENDER_EVENT, onPostRender );
	}

	private function onPostRender(e:Event):Void 
	{

		#if sys
		if (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1") {
			_renderFrames++;
			if (_renderFrames == 30) {
				saveScreenshot("test37_current.png");
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
			var bmp = new openfl.display.BitmapData(w, h, false, 0x404040);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(bmp);
			}
			var pngBytes = bmp.encode(bmp.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Error saving screenshot: " + e);
		}
	}
	
	private function completeEvent(e:Event):Void 
	{
		trace( "complete" );
		
		scene.forEach( drawShapes, Shape3D );
	}
	
	private function drawShapes( shape:Shape3D ):Void 
	{
		trace( "drawShapes: " + shape.name + ", splines=" + (shape.splines != null ? shape.splines.length : -1) + ", color=" + shape.color );
		shape.addChild( new DebugShape( shape ) );
	}
}
