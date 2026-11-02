package examples.physics;

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
	import flare.physics.colliders.*;
	import flare.primitives.*;
	import openfl.display.*;
	import openfl.events.*;
	
	/**
	 * Physics hello world!
	 * @author Ariel Nehmad
	 */
	class Test01_HelloPhysics extends Sprite 
	{
		private var scene:Scene3D;
		
		public function new() 
		{
			super();
			scene = new Viewer3D( this, "", 0.2 );
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
			scene.camera.setPosition( 20, 40, -60 );
			scene.camera.lookAt( 0, 0, 0 );
			
			var floor:Cube = new Cube( "floor", 100, 5, 100 );
			floor.collider = new BoxCollider( 100, 5, 100 );
			floor.collider.isStatic = true;
			
			var cube:Cube = new Cube( "cube" );
			cube.collider = new BoxCollider( 10, 10, 10 );
			cube.collider.isRigidBody = true;
			cube.setPosition( 0, 30, 0 );
			cube.rotateZ( 23 );
			
			scene.addChild( floor );
			scene.addChild( cube );
		}
		
		private function updateEvent(e:Event):Void 
		{
			scene.physics.step();
		}
	}
