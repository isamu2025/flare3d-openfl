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
	import flare.core.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.physics.colliders.*;
	import flare.primitives.*;
	import flare.system.*;
	import flare.utils.*;
	import openfl.display.*;
	import openfl.events.*;
	import openfl.geom.*;
	import openfl.utils.*;
	
	/**
	 * @author Ariel Nehmad
	 */
	class Test05_MeshCollision extends Sprite 
	{
		// [Embed metadata]
		private var Model:Class<Dynamic>;
		
		private var scene:Scene3D;
		private var spheres:MeshBatch3D;
		private var model:Pivot3D;
		private var player:Cube;
		private var batch:MeshBatch3D;
		
		public function new() 
		{
			super();
			scene = new Viewer3D( this, null, 0.4 );
			scene.autoResize = true;
			scene.allowImportSettings = true;
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			
			var mat:Shader3D = new Shader3D( "", [new NullFilter( 0x605060, 5 )] );
			
			var sphere:Sphere = new Sphere( "sphere", 7, 24, mat );
			sphere.collider = new SphereCollider( sphere.radius );
			batch = new MeshBatch3D( sphere );
			for (i in 0...200) createSphere();
			
			model = scene.addChildFromFile( Type.createInstance(Model, []));
		}
		
		private function completeEvent( e:Event ):Void 
		{
			var mat:Shader3D = new Shader3D( "", [new NullFilter( 0x405060, 5 )] );
			
			player = new Cube( "cube", 15, 15, 25, 1, mat );
			player.collider = new BoxCollider( player.width, player.height, player.depth );
			player.collider.isRigidBody = true;
			player.collider.friction = 1;
			player.collider.restitution = 0.1;
			player.collider.setMass( 10 );
			player.collider.constrainLocalRotation( 0, 0, 0 );
			player.x = 10;
			player.y = 7.5;
			player.z = -30;
			
			scene.addChild( batch );
			scene.addChild( player );
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );			
		}
		
		private function updateEvent(e:Event):Void 
		{
			// we can move the player as a kinematic moving and rotating it as usual....
			if ( Input3D.keyDown( Input3D.UP ) ) player.translateZ( 1.5 );
			if ( Input3D.keyDown( Input3D.DOWN ) ) player.translateZ( -1.5 );
			if ( Input3D.keyDown( Input3D.LEFT ) ) player.rotateY( -3 );
			if ( Input3D.keyDown( Input3D.RIGHT ) ) player.rotateY( 3 );
			// or as a rigid body, applaying forces and torques.
			if ( Input3D.keyDown( Input3D.SPACE ) ) {
				player.collider.awake();
				player.collider.applyImpulse( 0, 50, 0 );
			}
			if ( Input3D.keyDown( Input3D.R ) ) {
				player.setRotation( 0, 0, 0 );
				player.setPosition( 0, 10, 0 );
				player.collider.resetVelocities();
			}
			
			scene.physics.step( 3, 1 / 30 );
		}
		
		private function createSphere():Void
		{
			var collider:SphereCollider = new SphereCollider( 7 );
			collider.isRigidBody = true;
			collider.neverSleep = true;
			collider.position.x = Math.random() * 200 - 100;
			collider.position.z = Math.random() * 200 - 100;
			collider.position.y = Math.random() * 500 + 100;
			scene.physics.addCollider( collider );
			batch.addInstance( collider.position, collider.orientation );
		}		
	}
