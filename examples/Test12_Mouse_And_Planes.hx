package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Vector3D;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;
import flare.events.*;
import examples.components.*;

/**
 * A bunch of planes textured with alpha mask and mouse events test.
 * 
 * @author Ariel Nehmad
 */
class Test12_Mouse_And_Planes extends Sprite 
{
	private var scene:Scene3D;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this);
		scene.autoResize = true;
		scene.camera.setPosition( 0, 0, -100 );
		scene.camera.lookAt( 0, 0, 0 );
		
		var texture:Texture3D = scene.addTextureFromFile( "tree.png" );
		var material:Shader3D = new Shader3D( "", null, false );
		material.filters.push( new TextureMapFilter( texture ) );
		material.filters.push( new AlphaMaskFilter( 0.5 ) );
		material.twoSided = true;
		material.build();
			
		var plane:Plane = new Plane( "sourcePlane", 10, 10, 1, material, "+xy" );
		
		for (i in 0...200)
		{
			var clone:Mesh3D = cast(plane.clone(), Mesh3D);
			clone.name = "plane" + i;
			clone.x = Math.random() * 100 - 50;
			clone.y = Math.random() * 100 - 50;
			clone.z = Math.random() * 100 - 50;
			
			clone.addEventListener( MouseEvent3D.MOUSE_OVER, mouseOverEvent );
			clone.addEventListener( MouseEvent3D.MOUSE_OUT, mouseOutEvent );
			clone.addEventListener( MouseEvent3D.MOUSE_MOVE, mouseMoveEvent );
			clone.addEventListener( MouseEvent3D.CLICK, clickMouseEvent );
			clone.useHandCursor = true;
			clone.addComponent( new SetOrientationComponent( scene.camera ) );
			scene.addChild( clone );
		}
	}
	
	private function mouseMoveEvent(e:MouseEvent3D):Void 
	{
		//
	}
	
	private function clickMouseEvent(e:MouseEvent3D):Void 
	{
		if (e.target != null && Std.isOfType(e.target, Mesh3D)) {
			var m:Mesh3D = cast e.target;
			m.parent = null;
		} else if (e.info != null && e.info.mesh != null) {
			e.info.mesh.parent = null;
		}
	}
	
	private function mouseOverEvent(e:MouseEvent3D):Void 
	{
		if (e.target != null && Std.isOfType(e.target, Mesh3D)) {
			var m:Mesh3D = cast e.target;
			m.setScale( 1.2, 1.2, 1.2 );
		}
	}
	
	private function mouseOutEvent(e:MouseEvent3D):Void 
	{
		if (e.target != null && Std.isOfType(e.target, Mesh3D)) {
			var m:Mesh3D = cast e.target;
			m.setScale( 1, 1, 1 );
		}
	}
}
