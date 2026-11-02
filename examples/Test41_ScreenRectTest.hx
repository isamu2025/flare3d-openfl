package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.Lib;
import openfl.Lib.getTimer;
import openfl.net.URLRequest;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;
import flare.collisions.*;
import flare.loaders.*;
import flare.system.*;
import flare.events.*;
import flare.physics.*;
import flare.physics.colliders.*;
import flare.modifiers.*;
import flare.flsl.*;
import openfl.display.*;
import openfl.events.*;
import openfl.geom.*;

/**
 * @author Ariel Nehmad.
 */
class Test41_ScreenRectTest extends Sprite 
{
	private var scene:Scene3D;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this, null, 0.25, 1 );
		scene.autoResize = true;
		scene.antialias = 2;
		scene.backgroundColor = 0x404040;
		scene.camera.name = "customCamera";
		
		scene.registerClass( ZF3DLoader );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		var loader = scene.addChildFromFile( "test.zf3d" );
		if (loader != null) {
			loader.addEventListener( Event.COMPLETE, completeEvent );
			loader.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		}
		initCamera();
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function initCamera():Void 
	{
		scene.camera.name = "customCamera";
		scene.camera.fov = 45.0;
		scene.camera.fovMode = Camera3D.FOV_VERTICAL;
		if (Std.isOfType(scene, Viewer3D)) {
			var v:Viewer3D = cast scene;
			if (v.target == null) v.target = new Vector3D();
			v.target.setTo(8.6, 28.5, -5.8);
		}
		scene.camera.setPosition(49.8, 101.7, -167.5);
		scene.camera.lookAt(8.6, 28.5, -5.8);
		if (Std.isOfType(scene, Viewer3D)) {
			var v:Viewer3D = cast scene;
			v.syncOrbitFromCamera();
		}
		scene.camera.updateTransforms(true);
		scene.camera.updateProjection(scene.viewPort.width, scene.viewPort.height);
		scene.camera.updateViewProjection();
	}
	
	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
		scene.forEach(function(p:Pivot3D) {
			if (p.name.indexOf("Bip") != -1 || p.name.indexOf("rootJoint") != -1) {
				p.visible = false;
			}
		});
	}
	
	private function postRenderEvent(e:Event):Void 
	{
		graphics.clear();
		var r:Rectangle = new Rectangle();
		for (m in scene.renderList )
		{
			if (m.name.indexOf("Bip") != -1 || m.name.indexOf("rootJoint") != -1 || !m.visible) continue;

			// gets the screen object rectangle if it is in front of the camera.
			var hasRect = m.getScreenRect( r );
			if ( hasRect ) {
				graphics.beginFill( 0xff0000, 0.4 );
				graphics.drawRect( r.x, r.y, r.width, r.height );
			}
			
			// gets the 2D scaled object position.
			var coords:Vector3D = m.getScreenCoords();
			var screenRatio:Float = scene.viewPort.width / scene.camera.zoom;
			var scale:Float = 1;
			
			if (coords.w > 0.001) {
				var radius:Float = Math.max(4.0, Math.min(10.0, scale / coords.w * screenRatio));
				graphics.beginFill( 0x00ff00 );
				graphics.drawCircle( coords.x, coords.y, radius );
			}
		}

		#if sys
		var hasFlag = false;
		try {
			if (sys.FileSystem.exists("auto_exit.flag")) {
				hasFlag = true;
				sys.FileSystem.deleteFile("auto_exit.flag");
			}
		} catch (e:Dynamic) {}
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| hasFlag;
		if (isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames >= 25) {
				saveScreenshot("test41.png");
				Sys.exit(0);
			}
		}
		#end
	}

	private function saveScreenshot(filename:String):Void 
	{
		try {
			var w = stage != null ? stage.stageWidth : 1024;
			var h = stage != null ? stage.stageHeight : 525;
			if (w <= 0) w = 1024;
			if (h <= 0) h = 525;
			var b = new openfl.display.BitmapData(w, h, false, 0x404040);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(b);
			}
			b.draw(this);
			var pngBytes = b.encode(b.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("flare3d-openfl/" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}
}
