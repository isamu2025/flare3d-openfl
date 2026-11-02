package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.display.Shape;
import openfl.display.BitmapData;
import flare.basic.*;
import flare.collisions.*;
import flare.core.*;
import flare.events.*;
import flare.materials.*;
import flare.materials.filters.*;

/**
 * Texture painting example.
 * 
 * @author Ariel Nehmad.
 */
class Test33_TexturePainting extends Sprite 
{
	private var scene:Scene3D;
	private var shape:Shape;
	private var texture:Texture3D;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this);
		scene.autoResize = true;
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addChildFromFile( "elsa.zf3d" );
		
		shape = new Shape();
		shape.graphics.beginFill( 0xff0000, 1 );
		shape.graphics.drawCircle( 0, 0, 10 );
	}
	
	private function completeEvent(e:Event):Void 
	{

		var mesh:Mesh3D = cast(scene.getChildByName( "elsa" ), Mesh3D);
		if (mesh == null) return;
		
		if (Std.isOfType(scene, Viewer3D)) {
			var viewer:Viewer3D = cast scene;
			viewer.target.setTo(0, 0, 0);
			scene.camera.setPosition(0, 50, -200);
			scene.camera.lookAt(0, 0, 0);
			viewer.syncOrbitFromCamera();
			flare.system.DebugLog.log("[Test33 Camera] pos=" + scene.camera.getPosition() + " target=" + viewer.target + " radius=" + viewer.radius);
		}
		
		// get the mesh material.
		var material:Shader3D = cast(mesh.getMaterialByName( "mElsa" ), Shader3D);
		if (material == null || material.filters == null || material.filters.length == 0) return;
		
		// get the texture associated and change the mip mode to not generate 
		// mip levels for the texture. this will increase performance.
		texture = (cast material.filters[0] : Dynamic).texture;
		if (texture != null) {
			texture.mipMode = Texture3D.MIP_NONE;
			texture.upload( scene );
		}
		
		// download the material because we changed the texture mip mode.
		// so, the shader should be reuploaded.
		material.download();
		
		mesh.addEventListener( MouseEvent3D.MOUSE_MOVE, mouseMoveEvent );
		mesh.addEventListener( MouseEvent3D.MOUSE_DOWN, mouseMoveEvent );
		mesh.useHandCursor = true;
	}
	
	private function mouseMoveEvent(e:MouseEvent3D):Void 
	{
		var info:CollisionInfo = e.info;
		if (info == null || texture == null || texture.bitmapData == null) return;
		
		var bitmapData:BitmapData = texture.bitmapData;
		
		var matrix:Matrix = new Matrix();
		matrix.tx = info.u * bitmapData.width;
		matrix.ty = info.v * bitmapData.height;
		
		bitmapData.draw( shape, matrix );
		
		// upload the texture to the graphics card again.
		if (scene != null) texture.uploadTexture();
	}
}
