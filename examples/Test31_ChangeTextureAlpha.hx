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

import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.system.*;
import openfl.display.*;
import openfl.events.*;
import openfl.geom.*;
import openfl.utils.*;

/**
 * Animate texture alpha.
 * 
 * @author Ariel Nehmad
 */
class Test31_ChangeTextureAlpha extends Sprite 
{
	private var scene:Scene3D;
	private var material:Shader3D;
	private var elsa:Pivot3D;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this);
		scene.autoResize = true;
		scene.backgroundColor = 0x505050;
		scene.clearColor.setTo(80 / 255.0, 80 / 255.0, 80 / 255.0);
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addChildFromFile( "elsa.zf3d" );
	}
	
	private function completeEvent(e:Event):Void 
	{
		elsa = scene.getChildByName( "elsa" );
		
		var viewer = Std.isOfType(scene, Viewer3D) ? cast(scene, Viewer3D) : null;
		if (viewer != null) {
			viewer.target.setTo(0, 8, 0);
			viewer.radius = 100;
			viewer.updateCameraOrbit();
		}

		if (elsa != null) {
			// since we're going to change object alpha, we need to make sure to render it after other opaque objects.
			elsa.setLayer( 1 );
			
			// gets the reference to the material.
			material = cast(elsa.getMaterialByName( "mElsa" ), Shader3D);
			if (material != null && material.filters != null && material.filters.length > 0) {
				material.filters[0].alpha = 0.0;
				material.transparent = true;
			}
		}
		
		scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );

		#if sys
		var isTest = Sys.args().indexOf("--test") != -1;
		if (isTest) {
			var frameCount = 0;
			scene.addEventListener( Scene3D.POSTRENDER_EVENT, function(e:Event) {
				frameCount++;
				if (frameCount == 60 || frameCount == 180 || frameCount == 240 || frameCount == 280) {
					try {
						var bmd = new BitmapData(scene.viewWidth > 0 ? scene.viewWidth : 800, scene.viewHeight > 0 ? scene.viewHeight : 450, false, 0);
						scene.context.drawToBitmapData(bmd);
						var bytes = bmd.encode(bmd.rect, new openfl.display.PNGEncoderOptions());
						if (bytes != null) {
							var p = "test31_frame_" + frameCount + ".png";
							sys.io.File.saveBytes(p, bytes);
						}
					} catch (err:Dynamic) {}
				}
				if (frameCount >= 300) {
					Sys.exit(0);
				}
			});
		}
		#end
	}
	
	private function renderEvent(e:Event):Void 
	{
		// this is not really required, but it is an useful trick to enable better transparency on
		// complex object surfaces. drawing the object first without color, but storing its depth values
		// into the depth buffer, allows you to draw the transparency only on the nearest pixels to the camera.
		// try comment / uncomment these 3 lines to see the difference.
		if (scene.context != null && elsa != null) {
			scene.context.setColorMask( false, false, false, false );
			elsa.draw();
			scene.context.setColorMask( true, true, true, true );
		}
		
		// finally changes the texture alpha.
		if (material != null && material.filters != null && material.filters.length > 0) {
			var textureMap:TextureMapFilter = cast material.filters[0];
			textureMap.alpha = Math.sin( getTimer() / 1000 ) * 0.5 + 0.5;
		}
	}
}
