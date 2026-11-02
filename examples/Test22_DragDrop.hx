package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
import flare.basic.Scene3D;
import flare.core.Camera3D;
import flare.core.Mesh3D;
import flare.core.Pivot3D;
import flare.events.MouseEvent3D;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;
import flare.primitives.Plane;
import flare.primitives.Sphere;
import flare.system.Input3D;
import flare.utils.Vector3DUtils;

/**
 * Drag & Drop with 3D objects.
 * @author Ariel Nehmad
 */
class Test22_DragDrop extends Sprite 
{
	private var scene:Scene3D;
	private var draging:Pivot3D = null;
	
	public function new() 
	{
		super();
		scene = new Scene3D( this );
		scene.autoResize = true;
		scene.clearColor.setTo( 0.157, 0.157, 0.157 );
		scene.camera = new Camera3D();
		scene.camera.setPosition( 0, 100, -200 );
		scene.camera.lookAt( 0, 0, 0 );
		
		var mat:Shader3D = new Shader3D( "plane", [new ColorFilter(0x90f090)] );
		mat.twoSided = true;
			
		var sphere:Sphere = new Sphere( "sphere", 10 );
		var plane:Plane = new Plane( "", 40, 40, 1, mat );
		plane.parent = sphere;
				
		for (i in 0...20)
		{
			var object:Mesh3D = cast(sphere.clone(), Mesh3D);
			object.addEventListener( MouseEvent3D.MOUSE_DOWN, mouseDownEvent );
			object.x = Math.random() * 100 - 50;
			object.y = Math.random() * 100 - 50;
			object.z = Math.random() * 100 - 50;
			object.parent = scene;
		}
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		if ( draging == null && Input3D.mouseDown && Input3D.mouseMoved )
		{
			scene.camera.rotateY( Input3D.mouseXSpeed, false, Vector3DUtils.ZERO );
			scene.camera.rotateX( Input3D.mouseYSpeed, true, Vector3DUtils.ZERO );
		}
	}
	
	private function mouseDownEvent(e:MouseEvent3D):Void 
	{
		var target:Pivot3D = cast(e.target, Pivot3D);
		
		/* this drag relative to the camera orientation. */
		target.startDrag( true );
		
		/* this drag relative to the object plane orientation. */
		//target.startDrag( true, target.getDir(false) );
		
		draging = target;
		
		if (stage != null) {
			stage.addEventListener( MouseEvent.MOUSE_UP, mouseUpEvent );
		}
	}
	
	private function mouseUpEvent( e:MouseEvent ):Void 
	{
		if ( draging != null )
			draging.stopDrag();
		
		draging = null;
		
		if (stage != null) {
			stage.removeEventListener( MouseEvent.MOUSE_UP, mouseUpEvent );
		}
	}
}
