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
	import flare.primitives.*;
	import flare.system.*;
	import openfl.display.*;
	import openfl.events.*;
	import openfl.geom.*;
	
	// [SWF metadata]
	
	/**
	 * @author Ariel Nehmad
	 */
	class Test38_ShapeExample extends Sprite 
	{
		private var scene:Scene3D;
		private var value:Float = 0;
		private var cube:Cube;
		private var shape:Shape3D;
		
		public function new() 
		{
			super();
			scene = new Viewer3D(this);
			scene.autoResize = true;
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			scene.addChildFromFile( "shapes.zf3d" );
			
			cube = new Cube( "cube", 2, 2, 2 );
			scene.addChild( cube );
		}
		
		private function completeEvent(e:Event):Void 
		{
			shape = cast(scene.getChildByName( "Line001" ), Shape3D);
			
			scene.forEach( drawShapes, Shape3D );
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		}
		
		private function drawShapes( shape:Shape3D ):Void 
		{
			shape.addChild( new DebugShape( shape ) );
		}
		
		private function updateEvent(e:Event):Void 
		{
			value += 0.002;
			if ( value > 1 ) value -= 1;
			
			var pos:Vector3D = shape.getPoint( value );
			var dir:Vector3D = shape.getTangent( value );
			
			cube.setPosition( pos.x, pos.y, pos.z );
			cube.setOrientation( dir );
		}
	}
