package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.system.*;

/**
 * @author Ariel Nehmad
 */
class Test39_Library3D extends Sprite 
{
	private var scene:Scene3D;
	private var library:Library3D;
	private var _isLoaded:Bool = false;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this);
		scene.autoResize = true;
		scene.camera.setPosition( 0, 480, -360 );
		scene.camera.lookAt( 0, 0, 0 );

		scene.lights.ambientColor.setTo( 0.38, 0.38, 0.38 );

		if (Std.isOfType(scene, Viewer3D)) {
			cast(scene, Viewer3D).syncOrbitFromCamera();
		}
		
		scene.addEventListener(Scene3D.POSTRENDER_EVENT, onPostRender);
		
		library = new Library3D( 10, false );
		libraryPushItem( new Flare3DLoader( "elsa.zf3d" ), "elsa" );
		libraryPushItem( new Flare3DLoader( "vaca.zf3d" ), "vaca" );
		libraryPushItem( new Flare3DLoader( "teapot2.zf3d" ), "teapot2" );
		libraryPushItem( new Flare3DLoader( "chess2.zf3d" ), "chess" );
		library.addEventListener( "progress", progressEvent );
		library.addEventListener( "complete", completeEvent );
		library.load();
	}
	
	private function libraryPushItem( item:ILibraryExternalItem, name:String ):Void 
	{
		if ( library.getItem( name ) == null ) {
			library.push( item );
			library.addItem( name, item );
		}
	}
	
	private function progressEvent(e:Event):Void 
	{
		trace( "progress", library.progress );
	}
	
	private function completeEvent(e:Event):Void 
	{
		var elsa:Pivot3D = cast(library.getItem( "elsa" ), Pivot3D);
		var vaca:Pivot3D = cast(library.getItem( "vaca" ), Pivot3D);
		var teapot2:Pivot3D = cast(library.getItem( "teapot2" ), Pivot3D);
		var chess:Pivot3D = cast(library.getItem( "chess" ), Pivot3D);

		if (elsa != null) scene.addChild(elsa);
		if (vaca != null) scene.addChild(vaca);
		if (teapot2 != null) scene.addChild(teapot2);
		if (teapot2 != null) {
			teapot2.forEach(function(p:Pivot3D):Void {
				if (Std.isOfType(p, Mesh3D)) {
					var mesh:Mesh3D = cast p;
					for (s in mesh.surfaces) {
						if (s.material != null) {
							s.material.twoSided = true;
							s.material.transparent = false;
						}
					}
				}
			});
		}

		if (chess != null) scene.addChild(chess);
		
		scene.camera.setPosition( 0, 480, -360 );
		scene.camera.lookAt( 0, 0, 0 );

		scene.lights.ambientColor.setTo( 0.38, 0.38, 0.38 );

		if (Std.isOfType(scene, Viewer3D)) {
			cast(scene, Viewer3D).syncOrbitFromCamera();
		}
		
		_isLoaded = true;
		trace( "complete" );
	}

	private function onPostRender(e:Event):Void 
	{
		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			if (_isLoaded) {
				_renderFrames++;
				if (_renderFrames == 1) {
					var pos = scene.camera.getPosition();
					var dir = scene.camera.getDir();
					trace("Camera pos: " + pos + ", dir: " + dir + ", fov: " + scene.camera.fov + ", fovMode: " + scene.camera.fovMode + ", aspect: " + scene.camera.aspectRatio);
					trace("Projection raw: " + [for (i in 0...16) scene.camera.projection.rawData[i]]);
					trace("ViewProjection raw: " + [for (i in 0...16) scene.camera.viewProjection.rawData[i]]);
					var p0 = scene.camera.project(new Vector3D(0, 0, 0));
					trace("Project (0, 0, 0) -> " + p0);
					var elsaItem:Pivot3D = cast(library.getItem("elsa"), Pivot3D);
					var vacaItem:Pivot3D = cast(library.getItem("vaca"), Pivot3D);
					var teapotItem:Pivot3D = cast(library.getItem("teapot2"), Pivot3D);
					var chessItem:Pivot3D = cast(library.getItem("chess"), Pivot3D);
					trace("Elsa pos: " + (elsaItem != null ? elsaItem.getPosition() : null));
					trace("Vaca pos: " + (vacaItem != null ? vacaItem.getPosition() : null));
					trace("Teapot pos: " + (teapotItem != null ? teapotItem.getPosition() : null));
					trace("Chess pos: " + (chessItem != null ? chessItem.getPosition() : null));
					if (chessItem != null) {
						for (c in chessItem.children) {
							if (c.name == "Desk" || c.name == "Line01") {
								trace("  Chess child " + c.name + " pos: " + c.getPosition() + " scale: " + [c.scaleX, c.scaleY, c.scaleZ]);
							}
						}
					}
					trace("Lights count: " + scene.lights.list.length);
					for (i in 0...scene.lights.list.length) {
						var l = scene.lights.list[i];
						trace("  Light " + i + ": " + l.name + " (" + l.type + ") pos: " + l.getPosition() + " col: " + l.color);
					}
				}
				if (_renderFrames == 15) {
					saveScreenshot("test39.png");
					Sys.exit(0);
				}
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
			var bmp = new openfl.display.BitmapData(w, h, false, 0x505050);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(bmp);
			}
			var pngBytes = bmp.encode(bmp.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("C:/Users/ISAMU/.gemini/antigravity/brain/89de7aff-2951-43d1-91cb-f8ef02f8709c/test39_rendered_current.png", pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}
}
